## Jila API Backend – API Contract (v1) — Extracted section (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

## 9. Alerts (Account-scoped)

### 9.1 `GET /v1/accounts/{org_principal_id}/alerts`

`org_principal_id`:
- Must be an organization principal id.
- Caller must have an org role that grants access to that org account context.

Query params:
- `limit` (optional): 1–200 (default 50)
- `cursor` (optional): opaque cursor returned from a previous page
- `include_stats` (optional): boolean (default `false`); when true, include aggregate stats for the full filtered set (D-064)
- `include_resolved` (optional): boolean (default `false`); when true, include resolved alerts (those with `resolved_at` set)
- `site_id` (optional uuid)
- `reservoir_id` (optional uuid)
- `device_id` (optional uuid)
- `severity` (optional): `CRITICAL|WARNING|INFO`
- `status` (optional): `READ|UNREAD`

Response `200 OK`:

```json
{
  "items": [
    {
      "alert_id": "uuid",
      "event_id": "uuid",
      "event_type": "ORDER_CREATED",
      "subject_type": "ORDER",
      "subject_id": "uuid",
      "channel": "APP",
      "delivery_status": "SENT",
      "severity": "INFO",
      "context_type": "ORDER",
      "source_name": "Order ORD-7H3K2Q9D1FJJ2",
      "source_location": null,
      "created_at": "2025-01-01T00:00:00Z",
      "sent_at": "2025-01-01T00:00:00Z",
      "read_at": null,
      "message_key": "orders.created",
      "message_args": { "order_id": "uuid" },
      "rendered_title": "Order created",
      "rendered_message": "Order ORD-7H3K2Q9D1FJJ2 was created",
      "event_payload": {
        "order_code": "ORD-7H3K2Q9D1FJJ2",
        "site_id": "uuid",
        "reservoir_id": "uuid"
      },
      "data_snapshot": [
        { "label": "Order", "value": "ORD-7H3K2Q9D1FJJ2" }
      ],
      "deeplink": { "screen": "OrderDetail", "params": { "order_id": "uuid" } }
    }
  ],
  "next_cursor": "2025-01-01T00:00:00Z|uuid",
  "stats": {
    "unread_total": 23,
    "by_severity": { "CRITICAL": 5, "WARNING": 12, "INFO": 6 },
    "by_context_type": { "SITE": 4, "RESERVOIR": 10, "DEVICE": 6, "ORDER": 2, "SYSTEM": 1 }
  }
}
```

Notes:
- By default, this endpoint returns the **active alerts feed** (unresolved alerts). Alerts that have been
  automatically resolved/cleared by backend health state transitions are excluded unless
  `include_resolved=true` is provided. (Resolution is an internal lifecycle.)
- Alerts are scoped to the authenticated user within the requested account context (`alerts.user_id = caller user`).
- `stats` is included only when `include_stats=true` and is computed across the full filtered set (not the page). See **D-064**.
- **DECIDED**: Alerts always include both localization keys (`message_key/message_args`) and server-rendered strings (`rendered_title/rendered_message`) per **D-030**.
- **DECIDED**: The feed includes portal triage fields (`severity`, `context_type`, `source_*`, optional `data_snapshot`) per **D-031**.
- Enums (v1):
  - `severity`: `CRITICAL | WARNING | INFO`
  - `context_type`: `SITE | RESERVOIR | DEVICE | ORDER | SYSTEM`
- `message_args` must be a **flat** JSON object in v1 (no nested objects/arrays) to prevent divergent client formatting.
- `rendered_title` and `rendered_message` are non-empty strings rendered in the user’s preferred language.
- For non-`APP` channels (for example `SMS`, `EMAIL`, `PUSH`), `delivery_status` is asynchronous and typically progresses
  `PENDING -> SENT|FAILED` as background delivery workers process retries.
- `event_payload` is the extracted payload from the triggering event (e.g., for `RESERVOIR_LEVEL_STATE_CHANGED`: `new_state`, `old_state`, `level_percent`). Always present (empty `{}` if unavailable).
- `data_snapshot` is optional and intended for “why this fired” context without extra calls:
  - bounded (recommended ≤ 8 items)
  - `value` is a display-ready string (not a raw numeric payload)

### 9.2 `POST /v1/accounts/{org_principal_id}/alerts/{alert_id}/mark-read`

Behavior:
- Marks the alert as read for the whole account feed (principal-owned alerts).
- Records the acting user for audit (server-side only; not returned in v1 responses).

Response `200 OK`:

```json
{ "status": "OK" }
```

### 9.3 `GET /v1/accounts/{org_principal_id}/events`

List account-scoped outbox events for client history/diagnostics.

`org_principal_id`:
- Must be an organization principal id.
- Caller must have an org role that grants access to that org account context.

Query params:
- `event_type` (optional string)
- `subject_type` (optional): `ORG|SITE|RESERVOIR|DEVICE`
- `subject_id` (optional uuid)
- `cursor` (optional): opaque cursor from previous page (`<seq>|<event_id>`)
- `limit` (optional): `1..200` (default `50`)

Response `200 OK`:

```json
{
  "items": [
    {
      "seq": 123,
      "event_id": "uuid",
      "event_type": "DEVICE_SEEN",
      "subject_type": "DEVICE",
      "subject_id": "uuid",
      "created_at": "2025-01-01T00:00:00Z"
    }
  ],
  "next_cursor": "123|uuid"
}
```

Scoping rules (v1):
- Only subject types `ORG|SITE|RESERVOIR|DEVICE` are in scope.
- `ORG`: only events where `events.subject_id` equals this account’s `org_id`.
- `SITE`: only events where `sites.id = events.subject_id` and `sites.owner_principal_id = account_principal_id`.
- `RESERVOIR`: only events where `reservoirs.id = events.subject_id` and `reservoirs.owner_principal_id = account_principal_id`.
- `DEVICE`: only events where `devices.id = events.subject_id` and the attached reservoir owner is `account_principal_id`.
- Other subject types are excluded from this endpoint in v1.
- Viewer callers are additionally restricted to a viewer-safe event type set (operational + marketplace/order activity).
- High-level organizational/admin event types (for example membership/invite/governance events) are excluded for viewer.
- Marketplace governance/admin-style events (for example seller verification/profile administration and pricing policy updates) are excluded for viewer.
- For viewer callers, an `event_type` query value outside the viewer-safe set returns an empty page (`items=[]`).

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `422 VALIDATION_ERROR`

### 9.4 `GET /v1/accounts/{org_principal_id}/events/{event_id}`

Get one account-scoped outbox event detail with full payload.

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must have org access in the `org_principal_id` account context.

Path params:
- `event_id` (uuid, required)

Response `200 OK`:

```json
{
  "seq": 123,
  "event_id": "uuid",
  "event_type": "RESERVOIR_LEVEL_READING",
  "subject_type": "DEVICE",
  "subject_id": "uuid",
  "created_at": "2025-01-01T00:00:00Z",
  "event_version": 1,
  "envelope": {
    "reservoir_id": "uuid-or-null",
    "site_id": "uuid-or-null",
    "zone_id": "uuid-or-null",
    "source": "DEVICE|MANUAL|MIXED|null"
  },
  "payload": {},
  "linked_telemetry": {
    "telemetry_message_id": 456,
    "mqtt_client_id": "B43A4536C83C",
    "schema_version": 1,
    "seq": 789,
    "recorded_at": "2025-01-01T00:00:00Z",
    "received_at": "2025-01-01T00:00:00Z",
    "payload": {}
  }
}
```

Notes:
- `linked_telemetry` is `null` when the event payload has no valid `telemetry_message_id` or the row does not exist.
- For viewer callers, detail requests for excluded event types return `404 RESOURCE_NOT_FOUND` (same anti-enumeration semantics as out-of-scope).
- If the event does not exist or is out of account scope, the server returns `404 RESOURCE_NOT_FOUND`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

---
