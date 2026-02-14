# Org Portal — Alerts Handling Guide (v1)

> **Audience:** Frontend team building the Org Portal
> 
> **Status:** Draft (frontend-facing reference)
> 
> **Last updated:** 2026-01-27

## Canonical sources (do not drift)
- Alerts API contract: `docs/architecture/api_contract/11_alerts.md`
- Global API conventions (errors, timestamps): `docs/architecture/api_contract/01_global_conventions.md`
- Orgs/sites portal scoping (`org_principal_id`): `docs/architecture/api_contract/03_orgs_sites_portal.md`
- Reservoir + device context: `docs/architecture/api_contract/05_reservoirs_readings_location.md`, `docs/architecture/api_contract/06_devices_firmware_telemetry.md`
- Alert rendering + message keys: `app/common/alerts_rendering.py`

## Mental model
- Alerts are **account-scoped** and **active-only by default** (use `include_resolved=true` for history).
- Portal uses **org account context**: `org_principal_id` is the org principal id from `GET /v1/me`.
- The same feed powers **general alerts** and **contextual alerts** (site/reservoir/device) via filters.
- Handling actions are **mark-read only**; resolution is an internal backend lifecycle.

## Endpoints
### `GET /v1/accounts/{org_principal_id}/alerts`
**Purpose:** Active alerts feed for an account.

Query params (v1):
- `limit` (1–200, default 50)
- `cursor` (opaque, from `next_cursor`)
- `include_stats` (bool, default false)
- `include_resolved` (bool, default false)
- `site_id` (uuid)
- `reservoir_id` (uuid)
- `device_id` (uuid)
- `severity` (`CRITICAL|WARNING|INFO`)
- `status` (`READ|UNREAD`)

Notes:
- `items` includes **server-rendered strings** (`rendered_title`, `rendered_message`) plus **localization keys** (`message_key`, `message_args`).
- `stats` (when `include_stats=true`) is computed across the **full filtered set** (not just the page).
- Only **unresolved** alerts are returned unless `include_resolved=true`.

### `POST /v1/accounts/{org_principal_id}/alerts/{alert_id}/mark-read`
**Purpose:** Mark an alert as read (idempotent).

Response:
```json
{ "status": "OK" }
```

## Retrieval patterns by context
### 1) General alerts section (org-wide)
- Call `GET /v1/accounts/{org_principal_id}/alerts` with no scope filters.
- Use `include_stats=true` to power top-level badges and filters.
- Use `include_resolved=true` for full history views.

### 2) Site-level alerts
- Call `GET /v1/accounts/{org_principal_id}/alerts?site_id=<site_id>`.
- Use `include_stats=true` for site-specific badges.
- For site lists, prefer `active_alert_count` from `GET /v1/accounts/{org_principal_id}/sites` for quick badges.

### 3) Reservoir-level alerts
- Call `GET /v1/accounts/{org_principal_id}/alerts?reservoir_id=<reservoir_id>`.
- For reservoir summaries, prefer `active_alerts` from `GET /v1/sites/{site_id}` when available.

### 4) Device-level alerts
- Call `GET /v1/accounts/{org_principal_id}/alerts?device_id=<device_id>`.
- Device list entries already include `alerts.active_count` and `alerts.highest_severity`.

## Alert item fields: UI usage
| Field | Meaning | Recommended UI usage |
|---|---|---|
| `alert_id` | Stable alert UUID | List key and dedupe anchor |
| `event_type` | Trigger event | Map to intent + localization key table below |
| `subject_type` / `subject_id` | Domain target | Derive context (site/reservoir/device/order) |
| `severity` | `CRITICAL|WARNING|INFO` | Triage color/badge |
| `context_type` | `SITE|RESERVOIR|DEVICE|ORDER|SYSTEM` | Grouping + filters |
| `status` (derived from `read_at`) | `READ|UNREAD` | Unread styling + counts |
| `source_name` | Display label for source | Row subtitle / context label |
| `source_location` | Optional `{lat,lng}` | Map pin or location chip (nullable) |
| `event_payload` | Extracted trigger event data (e.g. `new_state`, `level_percent`) | Detail panels, contextual info display |
| `data_snapshot` | Optional key/value hints | Compact “why it fired” context panel |
| `message_key` + `message_args` | Canonical localization | Preferred render path |
| `rendered_title` / `rendered_message` | Server convenience strings | Fallback if client catalog missing |
| `deeplink` | `{screen, params}` | Navigation target |
| `channel` / `delivery_status` | `APP|PUSH|SMS|EMAIL`, `PENDING|SENT|FAILED` | Optional channel filter/labeling |
| `created_at` / `sent_at` / `read_at` | ISO8601 UTC (`Z`) | Timeline ordering + state |

**Important:** `message_args` is **flat JSON only** (no arrays/objects). Treat nested values as strings.

## Handling procedure (v1)
1. **Fetch** alerts with appropriate scope filter (`site_id`, `reservoir_id`, `device_id`) or none for global feed.
2. **Render** using `message_key` + `message_args` (preferred); fallback to `rendered_title/message`.
3. **Navigate** using `deeplink`:
   - `AlertsInbox` (no params)
   - `OrderDetail` (`order_id`)
   - `ReservoirDetail` (`reservoir_id`)
4. **Mark read** on user action via `POST /mark-read` (optimistic UI update allowed; idempotent).
5. **Do not implement “resolve”** actions in the UI; backend resolves alerts automatically and they disappear from the feed.

## Metadata-driven UI use cases
- **`source_name`**: header label for alert cards (ex: “Reservoir Tank A”, “Order ORD-7H3K2Q9D1FJJ2”).
- **`source_location`**: optional map pin or location badge; may be `null`.
- **`event_payload`**: raw event data for detailed context (e.g., `new_state`, `old_state`, `level_percent`, thresholds). Use for detail panels or when richer context is needed beyond `data_snapshot`.
- **`data_snapshot`**: use for a compact details panel (max ~8 rows recommended by contract).
- **`message_key/message_args`**: use for localization and consistent cross-platform phrasing.

## Event types and intent (localization map)
This reflects current server mappings in `app/common/alerts_rendering.py` and fanout consumers.

| Event type | Intent / when it fires | Message key | Deeplink | Notes |
|---|---|---|---|---|
| `RESERVOIR_LEVEL_STATE_CHANGED` | Water level state transitioned | `water_risk.level_state.critical` / `water_risk.level_state.low` / `water_risk.level_state.changed` | `ReservoirDetail(reservoir_id)` | Uses payload `new_state` to select key |
| `ORDER_CREATED` | New order created | `orders.created` | `OrderDetail(order_id)` | Seller-side alert |
| `ORDER_ACCEPTED` | Order accepted | `orders.accepted` | `OrderDetail(order_id)` | Buyer-side alert |
| `ORDER_REJECTED` | Order rejected | `orders.rejected` | `OrderDetail(order_id)` | Buyer-side alert |
| `ORDER_CANCELLED` | Order cancelled | `orders.cancelled` | `OrderDetail(order_id)` | Buyer-side alert |
| `ORDER_DELIVERED` | Order delivered | `orders.delivered` | `OrderDetail(order_id)` | Buyer + seller alert |
| `ORDER_DISPUTED` | Order disputed | `orders.disputed` | `OrderDetail(order_id)` | Buyer + seller alert |
| `TELEMETRY_INGESTION_ERROR` | Device telemetry issue (device health) | `device_risk.needs_attention` | `ReservoirDetail(reservoir_id)` if available, else `AlertsInbox` | Device health alerts auto-resolve when device recovers |
| *(fallback)* | Unknown/other | `alerts.generic` | `AlertsInbox` | Should be rare; log + surface safely |

## Error handling (alerts endpoints)
- `401 UNAUTHORIZED` — missing/invalid auth
- `403 FORBIDDEN` — org RBAC / account mismatch
- `404 RESOURCE_NOT_FOUND` — invalid `alert_id` on mark-read
- `422 VALIDATION_ERROR` — invalid UUIDs, invalid `severity` or `status`, invalid cursor

## Implementation notes
- The feed includes **active alerts only** (`resolved_at IS NULL`). Expect alerts to disappear after backend resolution.
- Use `include_stats=true` sparingly (badges and filters), since it aggregates across the full filtered set.
- Channel entitlements and user preferences gate which alerts exist; do not assume alerts for every event.
