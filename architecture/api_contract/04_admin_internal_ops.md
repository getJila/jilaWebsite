## Jila API Backend – API Contract (v1) — Admin management (internal ops) (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

This section is extracted from section 2 of the index file and contains internal ops (admin) endpoints plus
non-normative admin portal notes.

Canonical v1 routing is **internal ops**:
- Internal ops admin portal endpoints are under: `/v1/internal/*`
- Organization-scoped admin actions accept the target org principal id in the request body.

### 2.9 `POST /v1/accounts/{account_id}/erase` (admin-only, hard delete)

Hard-erases an organization container and cascades deletion of org-owned resources.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin.

Internal ops admin is a **separate** permission surface from "org admin" (org RBAC):
- Org RBAC (e.g. `OWNER|MANAGER`) applies within a specific organization container.
- Internal ops admin applies to platform-level administrative tooling (e.g. `/v1/internal/*`) and is gated by the internal ops org.

Internal ops admin gating:
- Preferred: tenant config is DB-backed via `platform_settings.internal_ops_org_id` (turnkey installs).
- Alternate configuration source: `settings.INTERNAL_OPS_ORG_ID` (env) may be used if DB settings are not configured.
- Caller must have an ACTIVE `access_grants` row on `ORG:<internal_ops_org_id>` with role `OWNER|MANAGER`.
- Additional guardrail (D-063): the caller must be a user principal with `users.email` ending in `@<allowed_admin_email_domain>`
  where `allowed_admin_email_domain` is tenant-configured via `platform_settings` (default `jila.ai`).

Request:
- Empty body.

Response `200 OK`:

```json
{ "status": "OK" }
```

Semantics:
- Deletes the `organizations` row (hard delete).
- Cascades deletion of the org principal and org-owned resources (e.g., org sites, org reservoirs, seller price rules, seller orders) via DB FKs.
- Revokes all org membership access grants (users remain but lose access to the org).
- Devices are **not** hard-deleted by org erasure; if devices were attached to org-owned reservoirs, reservoir deletion detaches them (`devices.reservoir_id` becomes null).

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` (`error_code = FORBIDDEN`) when caller is not internal ops admin
- `404 RESOURCE_NOT_FOUND` when the target organization does not exist

---

### 2.10 `GET /v1/internal/users`

List users for internal ops user management (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `q` | string | optional; substring match across `email` and `phone_e164` (case-insensitive) |
| `status` | string | optional: `PENDING_VERIFICATION|ACTIVE|LOCKED|DISABLED` |
| `cursor` | string | optional; opaque |
| `limit` | int | optional (default 50, max 200) |

Response `200 OK`:

```json
{
  "items": [
    {
      "user_id": "uuid",
      "principal_id": "uuid",
      "phone_e164": "+2449XXXXXXX",
      "email": "user@example.com",
      "status": "ACTIVE",
      "preferred_language": "pt",
      "phone_verified_at": "2025-01-01T00:00:00Z",
      "email_verified_at": "2025-01-01T00:00:00Z",
      "last_login_at": "2025-01-01T00:00:00Z",
      "created_at": "2025-01-01T00:00:00Z"
    }
  ],
  "next_cursor": "opaque"
}
```

Notes:
- This endpoint is paginated; `next_cursor = null` means no more results.
- This endpoint is for internal ops tooling and may return PII; clients must treat it as sensitive.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

### 2.10a `GET /v1/internal/users/{user_id}`

Get a user detail view for internal ops (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Response `200 OK`:

```json
{
  "user_id": "uuid",
  "principal_id": "uuid",
  "phone_e164": "+2449XXXXXXX",
  "email": "user@example.com",
  "status": "ACTIVE",
  "preferred_language": "pt",
  "phone_verified_at": "2025-01-01T00:00:00Z",
  "email_verified_at": "2025-01-01T00:00:00Z",
  "last_login_at": "2025-01-01T00:00:00Z",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

### 2.10b `POST /v1/internal/users/{user_id}/lock`

Lock a user account (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Request:
- Empty body.

Response `200 OK`:

```json
{ "status": "OK" }
```

Semantics (idempotent):
- Sets `users.status = LOCKED` unless the user is already `LOCKED` or `DISABLED`.
- If the user is `DISABLED`, returns `409 RESOURCE_CONFLICT`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `409 RESOURCE_CONFLICT`

### 2.10c `POST /v1/internal/users/{user_id}/unlock`

Unlock a user account (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Request:
- Empty body.

Response `200 OK`:

```json
{ "status": "OK" }
```

Semantics (idempotent):
- If `users.status = LOCKED`, set `users.status = ACTIVE`.
- If `users.status = ACTIVE`, return `200 OK` (no-op).
- If `users.status = DISABLED`, returns `409 RESOURCE_CONFLICT`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `409 RESOURCE_CONFLICT`

### 2.10d `POST /v1/internal/users/{user_id}/disable`

Disable a user account (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Request:
- Empty body.

Response `200 OK`:

```json
{ "status": "OK" }
```

Semantics (idempotent):
- Sets `users.status = DISABLED` (no-op if already disabled).

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

### 2.10e `POST /v1/internal/users/{user_id}/enable`

Re-enable a previously disabled user account (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Request:
- Empty body.

Response `200 OK`:

```json
{ "status": "OK" }
```

Semantics (idempotent):
- If `users.status = DISABLED`, set `users.status = ACTIVE`.
- If `users.status = ACTIVE`, return `200 OK` (no-op).
- If `users.status = LOCKED`, returns `409 RESOURCE_CONFLICT` (unlock required).

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `409 RESOURCE_CONFLICT`

### 2.10f `POST /v1/internal/users/{user_id}/sessions/revoke`

Revoke all active sessions for a user (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Request:
- Empty body.

Response `200 OK`:

```json
{ "status": "OK" }
```

Semantics (idempotent):
- Sets `user_sessions.revoked_at = now()` for all sessions for the user where `revoked_at IS NULL`.
- Does not return session details or token material.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

### 2.11 `GET /v1/internal/orgs`

List organizations for internal ops (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `q` | string | optional; substring match on org name (case-insensitive) |
| `country_code` | string | optional; 2-letter country code |
| `plan_id` | string | optional; filter by current org subscription plan (enum `plan_id`; see `docs/architecture/jila_api_backend_enums_v1.md`) |
| `cursor` | string | optional; opaque |
| `limit` | int | optional (default 50, max 200) |

Response `200 OK`:

```json
{
  "items": [
    {
      "org_id": "uuid",
      "org_principal_id": "uuid",
      "name": "Org Name",
      "legal_name": "Legal Name",
      "country_code": "AO",
      "region": "Luanda",
      "city": "Luanda",
      "status": "ACTIVE",
      "subscription": { "plan_id": "protect", "status": "ACTIVE", "billing_period": "MONTHLY" },
      "member_count": 12,
      "device_count": 31,
      "created_at": "2025-01-01T00:00:00Z",
      "updated_at": "2025-01-01T00:00:00Z"
    }
  ],
  "next_cursor": "opaque"
}
```

Notes:
- `member_count` counts active user principals with ACTIVE org grants (`object_type=ORG`, `revoked_at IS NULL`).
- `device_count` counts attached devices through non-deleted org-owned reservoirs.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

### 2.11a Org detail (v1)

Org detail is accessed via `GET /v1/internal/orgs` (filter and select by `org_id` or `org_principal_id`).

---

### 2.11b `POST /v1/internal/billing/payments` (manual Pay & Renew)

Record a manual payment for an organization and apply it (extend subscription period **and** grant credits).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Request:

```json
{
  "org_principal_id": "uuid",
  "plan_id": "protect",
  "billing_period": "MONTHLY",
  "trial_days_override": 14,
  "credits_override": 1000,
  "reference": "Bank transfer #12345",
  "idempotency_key": "pay_2026_01_07_org_<uuid>_001"
}
```

Rules:
- `plan_id` is enum `plan_id` (see `docs/architecture/jila_api_backend_enums_v1.md`), but **for orgs** must be `protect|pro` (never `monitor`).
- `billing_period` is enum `billing_period` (see `docs/architecture/jila_api_backend_enums_v1.md`).
- `trial_days_override` is optional; when provided must be in range `0..90` (inclusive).
- `credits_override` is optional; when omitted, credits granted default from the plan + billing period (SB-011).
- Credits are **abstract units** and must never go negative (SB-012/SB-013).
- Operation is idempotent per `(org_principal_id, idempotency_key)` (SB-005).

Response `200 OK`:

```json
{
  "status": "OK",
  "subscription": {
    "plan_id": "protect",
    "billing_period": "MONTHLY",
    "status": "ACTIVE",
    "current_period_start": "2026-01-07T00:00:00Z",
    "current_period_end": "2026-02-07T00:00:00Z",
    "grace_until": "2026-02-14T00:00:00Z"
  },
  "credits": {
    "balance": 1000,
    "granted": 1000
  }
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR` (invalid plan_id/billing_period/idempotency_key/trial_days_override)
- `409 RESOURCE_CONFLICT` (idempotency conflict or credit underflow attempt)

### 2.11c `GET /v1/internal/reservoirs`

List cross-org reservoirs for internal ops (admin-only), replacing org fan-out reads.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `q` | string | optional; case-insensitive name contains |
| `org_id` | uuid | optional; seller/owner organization id filter |
| `level_state` | string | optional: `FULL|NORMAL|LOW|CRITICAL` |
| `monitoring_mode` | string | optional: `MANUAL|DEVICE` |
| `sort` | string | optional: `updated_at|name|level_state` (default `updated_at`) |
| `order` | string | optional: `asc|desc` (default `desc`) |
| `cursor` | string | optional; opaque base64url cursor bound to endpoint + sort/order |
| `limit` | int | optional (default 50, max 100) |

Response `200 OK`:

```json
{
  "items": [
    {
      "reservoir_id": "uuid",
      "site_id": "uuid",
      "owner_principal_id": "uuid",
      "org_id": "uuid",
      "org_principal_id": "uuid",
      "org_name": "Org Name",
      "name": "Reservoir A",
      "reservoir_type": "TANK",
      "mobility": "FIXED",
      "capacity_liters": 1000,
      "safety_margin_pct": 20,
      "monitoring_mode": "DEVICE",
      "location": { "lat": -8.84, "lng": 13.23 },
      "location_updated_at": "2026-02-12T00:00:00Z",
      "thresholds": { "full_threshold_pct": 90, "low_threshold_pct": 30, "critical_threshold_pct": 15 },
      "level_state": "NORMAL",
      "level_state_updated_at": "2026-02-12T00:00:00Z",
      "connectivity_state": "ONLINE",
      "last_reading_age_seconds": 60,
      "device": { "device_id": "B43A...", "serial_number": "JL-AB12CD", "status": "ONLINE" },
      "latest_reading": { "level_pct": 72, "volume_liters": 720, "recorded_at": "2026-02-12T00:00:00Z", "source": "DEVICE" }
    }
  ],
  "next_cursor": "opaque",
  "total_count": 342
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `422 VALIDATION_ERROR` (invalid `limit/cursor/order/sort/org_id` or enum filters)

### 2.11d `GET /v1/internal/sites`

List cross-org sites for internal ops (admin-only), replacing org fan-out reads.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `q` | string | optional; search `name|city|region` (contains, case-insensitive) |
| `org_id` | uuid | optional organization id filter |
| `site_type` | string | optional; backend enum (`WATER_TREATMENT|...|OTHER`) |
| `country_code` | string | optional; 2-letter ISO code |
| `risk_level` | string | optional: `CRITICAL|WARNING|STALE|GOOD` |
| `sort` | string | optional: `updated_at|name|reservoir_count|risk_level` (default `updated_at`) |
| `order` | string | optional: `asc|desc` (default `desc`) |
| `cursor` | string | optional; opaque base64url cursor bound to endpoint + sort/order |
| `limit` | int | optional (default 50, max 100) |

Response `200 OK`:

```json
{
  "items": [
    {
      "site_id": "uuid",
      "org_id": "uuid",
      "org_principal_id": "uuid",
      "org_name": "Org Name",
      "name": "Site A",
      "site_type": "WATER_TREATMENT",
      "country_code": "AO",
      "region": "Luanda",
      "city": "Luanda",
      "location": { "lat": -8.84, "lng": 13.23 },
      "status": "ACTIVE",
      "risk_level": "GOOD",
      "reservoir_count": 4,
      "device_count": 3,
      "active_alert_count": 1,
      "updated_at": "2026-02-12T00:00:00Z"
    }
  ],
  "next_cursor": "opaque",
  "total_count": 87
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `422 VALIDATION_ERROR` (invalid `limit/cursor/order/sort/org_id/country_code` or enum filters)

### 2.11e `GET /v1/internal/devices`

List cross-org attached devices for internal ops (admin-only), replacing org fan-out reads.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `q` | string | optional; search `serial_number|device_id|name` (contains, case-insensitive) |
| `org_id` | uuid | optional organization id filter |
| `status` | string | optional: `ONLINE|OFFLINE|MAINTENANCE` (derived status) |
| `sort` | string | optional: `last_seen_at|serial_number|status|battery_pct` (default `last_seen_at`) |
| `order` | string | optional: `asc|desc` (default `desc`) |
| `cursor` | string | optional; opaque base64url cursor bound to endpoint + sort/order |
| `limit` | int | optional (default 50, max 100) |

Response `200 OK`:

```json
{
  "items": [
    {
      "device_id": "B43A4536C83C",
      "org_id": "uuid",
      "org_principal_id": "uuid",
      "org_name": "Org Name",
      "serial_number": "JL-AB12CD",
      "name": "Tank Sensor",
      "device_type": "LEVEL_SENSOR",
      "firmware_version": "1.2.3",
      "status": "ONLINE",
      "battery_pct": 87,
      "signal_strength_dbm": -65,
      "last_seen_at": "2026-02-12T00:00:00Z",
      "last_reading_at": "2026-02-12T00:00:00Z",
      "reservoir": { "reservoir_id": "uuid", "name": "Reservoir A" },
      "site": { "site_id": "uuid", "name": "Site A" },
      "alerts": { "active_count": 0, "highest_severity": null },
      "registered_at": "2026-01-01T00:00:00Z"
    }
  ],
  "next_cursor": "opaque",
  "total_count": 156
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `422 VALIDATION_ERROR` (invalid `limit/cursor/order/sort/org_id` or enum filters)

### 2.11f `GET /v1/internal/orders`

List cross-org orders with seller-org context for internal ops (admin-only), replacing org fan-out reads.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `org_id` | uuid | optional seller organization id filter |
| `status` | string | optional: `CREATED|ACCEPTED|REJECTED|CANCELLED|DELIVERED|DISPUTED` |
| `sort` | string | optional: `created_at|status|requested_volume_liters` (default `created_at`) |
| `order` | string | optional: `asc|desc` (default `desc`) |
| `cursor` | string | optional; opaque base64url cursor bound to endpoint + sort/order |
| `limit` | int | optional (default 50, max 100) |

Response `200 OK`:

```json
{
  "items": [
    {
      "order_id": "uuid",
      "org_id": "uuid",
      "org_principal_id": "uuid",
      "org_name": "Seller Org",
      "order_code": "ORD-ABC123",
      "status": "DELIVERED",
      "created_at": "2026-02-12T00:00:00Z",
      "updated_at": "2026-02-12T00:00:00Z",
      "delivered_at": "2026-02-12T01:00:00Z",
      "requested_volume_liters": 5000,
      "price_quote_total": 100000,
      "currency": "AOA",
      "seller_reservoir_id": "uuid",
      "target_reservoir_id": "uuid",
      "seller_profile": {
        "principal_id": "uuid",
        "seller_display_name": "Seller",
        "avatar_uri": null,
        "verification_status": "VERIFIED",
        "average_rating": 4.8,
        "review_count": 42
      },
      "buyer_profile": { "principal_id": "uuid", "display_name": "Buyer Name" }
    }
  ],
  "next_cursor": "opaque",
  "total_count": 423
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `422 VALIDATION_ERROR` (invalid `limit/cursor/order/sort/org_id` or enum filters)

### 2.11g `GET /v1/internal/orders/{order_id}`

Get cross-org order detail with seller-org context for internal ops (admin-only), replacing per-org
scan patterns in admin/BFF flows.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Path params:
| Parameter | Type | Notes |
|----------|------|-------|
| `order_id` | uuid | required order id |

Response `200 OK`:

```json
{
  "order_id": "uuid",
  "org_id": "uuid",
  "org_principal_id": "uuid",
  "org_name": "Seller Org",
  "order_code": "ORD-ABC123",
  "status": "DELIVERED",
  "created_at": "2026-02-12T00:00:00Z",
  "updated_at": "2026-02-12T00:00:00Z",
  "accepted_at": "2026-02-12T00:10:00Z",
  "cancelled_at": null,
  "delivered_at": "2026-02-12T01:00:00Z",
  "buyer_principal_id": "uuid",
  "seller_reservoir_id": "uuid",
  "target_reservoir_id": "uuid",
  "requested_volume_liters": 5000,
  "price_quote_total": 100000,
  "currency": "AOA",
  "seller_profile": {
    "principal_id": "uuid",
    "seller_display_name": "Seller",
    "avatar_uri": null,
    "verification_status": "VERIFIED",
    "average_rating": 4.8,
    "review_count": 42
  },
  "buyer_profile": { "principal_id": "uuid", "display_name": "Buyer Name" },
  "buyer_confirmation": {
    "confirmed_delivery_at": "2026-02-12T01:00:00Z",
    "confirmed_delivery_at_client": "2026-02-12T00:59:30Z",
    "confirmed_volume_liters": 5000,
    "note": "Received"
  },
  "seller_confirmation": {
    "confirmed_delivery_at": "2026-02-12T01:00:00Z",
    "confirmed_delivery_at_client": "2026-02-12T00:59:20Z",
    "confirmed_volume_liters": 5000,
    "note": "Delivered"
  },
  "review": {
    "review_id": "uuid",
    "reviewer_principal_id": "uuid",
    "rating": 5,
    "comment": "Great service",
    "created_at": "2026-02-12T02:00:00Z"
  }
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND` (unknown `order_id`)
- `422 VALIDATION_ERROR` (invalid `order_id` UUID)

### 2.12 Org membership admin surfaces (v1)

Admin tooling should use the internal ops org membership endpoints:
- `POST /v1/internal/members/grant`
- `POST /v1/internal/members/revoke`

### 2.12a `POST /v1/internal/members/grant`

Grant or update a user's org membership role (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Request:

```json
{ "org_principal_id": "uuid", "user_id": "uuid", "role": "OWNER" }
```

Response `200 OK`:

```json
{ "status": "OK" }
```

Semantics (idempotent):
- Ensures an ACTIVE `access_grants` row exists for the user's principal on the owning org with the given role.
- If a row exists with a different role, updates it to the requested role.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

### 2.12b `POST /v1/internal/members/revoke`

Revoke a user's org membership (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Request:

```json
{ "org_principal_id": "uuid", "user_id": "uuid" }
```

Response `200 OK`:

```json
{ "status": "OK" }
```

Semantics (idempotent):
- Revokes the user's `access_grants` for:
  - `object_type = ORG` / `object_id = org_id`
  - any `SITE` grants for sites owned by the org principal
  - any `RESERVOIR` grants for reservoirs owned by the org principal

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

### 2.13 `GET /v1/internal/diagnostics/events`

Query the outbox events stream for diagnostics (admin-only).

Note:
- Client-facing account-scoped event history is exposed separately at:
  - `GET /v1/accounts/{org_principal_id}/events`
  - `GET /v1/accounts/{org_principal_id}/events/{event_id}`

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `event_type` | string | optional |
| `subject_type` | string | optional |
| `subject_id` | uuid | optional |
| `cursor` | string | optional; opaque |
| `limit` | int | optional (default 50, max 200) |

Response `200 OK`:

```json
{
  "items": [
    {
      "seq": 123,
      "event_id": "uuid",
      "event_type": "STRING",
      "subject_type": "STRING",
      "subject_id": "uuid",
      "created_at": "2025-01-01T00:00:00Z"
    }
  ],
  "next_cursor": "opaque"
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

### 2.13.1 `GET /v1/internal/diagnostics/events/{event_id}`

Get full event detail with payload and linked telemetry (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Path params:
| Parameter | Type | Notes |
|----------|------|-------|
| `event_id` | uuid | required |

Response `200 OK`:

```json
{
  "seq": 123,
  "event_id": "uuid",
  "event_type": "STRING",
  "subject_type": "STRING",
  "subject_id": "uuid",
  "created_at": "2025-01-01T00:00:00Z",
  "event_version": 1,
  "envelope": {
    "reservoir_id": "uuid or null",
    "site_id": "uuid or null",
    "zone_id": "uuid or null",
    "source": "DEVICE|MANUAL|MIXED or null"
  },
  "payload": {},
  "payload_truncated": false,
  "linked_telemetry": {
    "telemetry_message_id": 456,
    "mqtt_client_id": "B43A4536C83C",
    "schema_version": 1,
    "seq": 789,
    "recorded_at": "2025-01-01T00:00:00Z",
    "received_at": "2025-01-01T00:00:00Z",
    "payload": {},
    "payload_truncated": false
  }
}
```

Notes:
- `payload` contains event-type-specific data (see event payload schemas in `app/modules/alerts_events/events/payloads.py`).
- `linked_telemetry` is `null` if the event payload does not contain a `telemetry_message_id` or if the telemetry message was not found.
- For events like `RESERVOIR_LEVEL_READING` and `TELEMETRY_INGESTION_ERROR`, `linked_telemetry` provides the raw device telemetry message that triggered the event.
- Payload bounding: `payload_truncated` / `linked_telemetry.payload_truncated` indicate that the server truncated large JSON payloads to keep response sizes bounded for admin tooling.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND` (event not found)

### 2.13a `GET /v1/internal/diagnostics/firestore`

Return Firestore mirror consumer health (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Response `200 OK`:

```json
{
  "consumer_name": "firestore_mirror",
  "last_seq": 123,
  "updated_at": "2025-01-01T00:00:00Z",
  "latest_events_seq": 456,
  "lag": 333
}
```

Notes:
- `lag` is computed as `latest_events_seq - last_seq` (best-effort).

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

### 2.13b `GET /v1/internal/diagnostics/telemetry`

Return basic telemetry ingestion stats (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `mqtt_client_id` | string | optional |
| `window_hours` | int | optional (default 24, max 168) |

Response `200 OK`:

```json
{
  "mqtt_client_id": "devices/B43A4536C83C",
  "window_hours": 24,
  "message_count": 123,
  "latest_received_at": "2025-01-01T00:00:00Z",
  "latest_recorded_at": "2025-01-01T00:00:00Z"
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

### 2.13c `GET /v1/internal/me`

Admin identity + capability entrypoint for the admin portal (admin-only) (DECIDED, D-066).

Rationale:
- Allows the portal to deterministically confirm “am I an admin?” without probing random admin endpoints and interpreting
  `403`s.
- Provides a stable place for small, explicit admin-only UX toggles (additive fields only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Response `200 OK`:

```json
{
  "admin_role": "INTERNAL_OPS",
  "user_id": "uuid",
  "principal_id": "uuid"
}
```

Notes:
- `admin_role` is intentionally coarse in v1; fine-grained permissions are out of scope.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

### 2.13d `GET /v1/internal/health`

Bounded system health view for internal ops (admin-only) (DECIDED, D-066).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Response `200 OK`:

```json
{
  "snapshot_at": "2025-01-01T00:00:00Z",
  "components": {
    "events_outbox": { "status": "OK" },
    "firestore_mirror": { "status": "OK", "lag": 333 },
    "telemetry_ingestion": { "status": "OK" }
  }
}
```

Notes:
- `components.*.status` is a coarse health indicator in v1: `OK|DEGRADED|DOWN`.
- `firestore_mirror.lag` follows the semantics of `GET /v1/internal/diagnostics/firestore` and may be omitted when Firestore
  mirroring is not configured.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

### 2.13e `GET /v1/internal/stats`

Single-call internal ops dashboard rollups (admin-only) (DECIDED, D-066).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Response `200 OK`:

```json
{
  "snapshot_at": "2025-01-01T00:00:00Z",
  "users": {
    "total": 123,
    "by_status": { "PENDING_VERIFICATION": 5, "ACTIVE": 110, "LOCKED": 3, "DISABLED": 5 }
  },
  "orgs": {
    "total": 42,
    "by_status": { "ACTIVE": 40, "INACTIVE": 2 }
  }
}
```

Notes:
- This endpoint is intentionally bounded. Additions must be explicit and justified to avoid becoming an unversioned
  “misc blob”.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

### 2.13f `GET /v1/internal/device-inventory/units`

List device inventory units for internal ops (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `serial_number` | string | optional; normalized to uppercase |
| `device_id` | string | optional; normalized to uppercase |
| `provisioning_status` | string | optional: `PENDING|PROVISIONED|DISABLED` |
| `cursor` | string | optional; opaque |
| `limit` | int | optional (default 50, max 200) |
| `include_stats` | boolean | optional (default false); include aggregate stats for full filtered set (D-064) |

Response `200 OK`:

```json
{
  "items": [
    {
      "inventory_unit_id": "uuid",
      "serial_number": "JL-AB12CD",
      "device_id": "B43A4536C83C",
      "provisioning_status": "PENDING|PROVISIONED|DISABLED",
      "cert_thumbprint_sha1": "40-hex-or-null",
      "provisioned_at": "2025-01-01T00:00:00Z",
      "last_provision_error_code": "STRING-or-null",
      "last_provision_error_message": "STRING-or-null",
      "created_at": "2025-01-01T00:00:00Z",
      "updated_at": "2025-01-01T00:00:00Z"
    }
  ],
  "next_cursor": "opaque",
  "stats": {
    "total_count": 123,
    "by_provisioning_status": { "PENDING": 5, "PROVISIONED": 110, "DISABLED": 8 }
  }
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

### 2.13g `GET /v1/internal/device-inventory/units/{device_id}`

Notes:
- `device_id` is the canonical identifier for inventory unit detail retrieval in v1; `inventory_unit_id` remains an internal UUID that may appear in responses.

Get device inventory unit detail for internal ops (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Response `200 OK`:

```json
{
  "inventory_unit_id": "uuid",
  "serial_number": "JL-AB12CD",
  "device_id": "B43A4536C83C",
  "provisioning_status": "PENDING",
  "cert_thumbprint_sha1": "40-hex-or-null",
  "provisioned_at": "2025-01-01T00:00:00Z",
  "last_provision_error_code": "STRING-or-null",
  "last_provision_error_message": "STRING-or-null",
  "metadata": {},
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

### 2.13h `GET /v1/internal/devices/{device_id}/overview`

Get device overview for internal ops (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Response `200 OK`:

```json
{
  "device_id": "B43A4536C83C",
  "inventory_unit": {
    "inventory_unit_id": "uuid",
    "serial_number": "JL-AB12CD",
    "device_id": "B43A4536C83C",
    "provisioning_status": "PENDING|PROVISIONED|DISABLED",
    "cert_thumbprint_sha1": "40-hex-or-null",
    "provisioned_at": "2025-01-01T00:00:00Z",
    "last_provision_error_code": "STRING-or-null",
    "last_provision_error_message": "STRING-or-null",
    "metadata": {},
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-01T00:00:00Z"
  },
  "operational_device": {
    "device_uuid": "uuid",
    "device_id": "B43A4536C83C",
    "serial_number": "JL-AB12CD",
    "device_type": "LEVEL_SENSOR",
    "firmware_version": "2.1.0",
    "raw_status": "ACTIVE|INACTIVE|DECOMMISSIONED",
    "status": "ONLINE|OFFLINE|MAINTENANCE",
    "battery_pct": 85,
    "signal_strength_dbm": -65,
    "last_seen_at": "2025-01-01T00:00:00Z",
    "last_reading_at": "2025-01-01T00:00:00Z",
    "registered_at": "2025-01-01T00:00:00Z"
  },
  "attachment": {
    "reservoir_id": "uuid-or-null",
    "reservoir_name": "Tank A",
    "site_id": "uuid-or-null",
    "site_name": "Site A",
    "owner_principal_id": "uuid-or-null",
    "owner_principal_type": "ORG|USER|UNKNOWN",
    "org_id": "uuid-or-null",
    "org_name": "Org A"
  },
  "alerts": { "active_count": 1, "highest_severity": "CRITICAL|WARNING|INFO|null" },
  "latest_reading": {
    "recorded_at": "2025-01-01T00:00:00Z",
    "source": "MANUAL|DEVICE",
    "level_pct": 50,
    "volume_liters": 100,
    "battery_pct": 85
  },
  "telemetry": {
    "mqtt_client_id": "B43A4536C83C",
    "window_hours": 24,
    "message_count": 123,
    "latest_received_at": "2025-01-01T00:00:00Z",
    "latest_recorded_at": "2025-01-01T00:00:00Z",
    "latest_seq": 456,
    "latest_schema_version": 1
  },
  "config": {
    "device_id": "B43A4536C83C",
    "desired": [
      {
        "type": "operation",
        "config_version": 123,
        "mqtt_queue_id": "op-1",
        "updated_at": "2025-01-01T00:00:00Z",
        "config": {
          "type": "operation",
          "sleep_duration_ms": 30000,
          "sleep_mode": "POWER_MANAGED",
          "battery_voltage_critical": 3200,
          "battery_voltage_low": 3500,
          "battery_voltage_normal": 3800,
          "samples_per_reading": 5,
          "reservoir_id": null
        }
      }
    ],
    "applied": [
      { "type": "operation", "applied_config_version": 123, "applied_at": "2025-01-01T00:00:00Z", "mqtt_queue_id": "op-1" }
    ]
  },
  "firmware_latest_job": {
    "job_id": "uuid",
    "status": "PENDING|PUBLISHED|APPLIED|FAILED|CANCELLED",
    "mqtt_queue_id": "string",
    "requested_at": "2025-01-01T00:00:00Z",
    "firmware_release_id": "uuid-or-null",
    "firmware_release_version": "1.2.3-or-null",
    "published_at": "2025-01-01T00:00:00Z",
    "applied_at": "2025-01-01T00:00:00Z",
    "failed_at": "2025-01-01T00:00:00Z",
    "failure_reason": "STRING-or-null"
  },
  "recent_events": [
    {
      "seq": 123,
      "event_id": "uuid",
      "event_type": "DEVICE_SEEN",
      "subject_type": "DEVICE",
      "subject_id": "uuid",
      "created_at": "2025-01-01T00:00:00Z"
    }
  ]
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

### 2.13i `GET /v1/admin/sellers`

List seller profiles for internal ops / marketplace moderation (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have supply-point moderation admin permissions.

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `status` | string | optional: `ACTIVE|INACTIVE` |
| `verification_status` | string | optional: `PENDING_REVIEW|VERIFIED|REJECTED` |
| `cursor` | string | optional; opaque |
| `limit` | int | optional (default 50, max 100) |

Response `200 OK`:

```json
{
  "items": [
    {
      "principal_id": "uuid",
      "seller_display_name": "Water Depot",
      "status": "ACTIVE",
      "verification_status": "PENDING_REVIEW",
      "verification_updated_at": "2025-01-01T00:00:00Z",
      "average_rating": 4.5,
      "review_count": 10,
      "created_at": "2025-01-01T00:00:00Z",
      "updated_at": "2025-01-01T00:00:00Z"
    }
  ],
  "next_cursor": "opaque"
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

### 2.13j `GET /v1/sellers/{seller_principal_id}`

Get public seller profile by principal ID.

Auth:
- Public (no JWT required)

Response `200 OK`:

```json
{
  "principal_id": "uuid",
  "seller_display_name": "Water Depot",
  "verification_status": "VERIFIED",
  "average_rating": 4.5,
  "review_count": 10,
  "is_available_now": true,
  "operating_times": {
    "monday": { "open": "08:00", "close": "18:00" },
    "tuesday": { "open": "08:00", "close": "18:00" }
  }
}
```

Notes:
- `is_available_now` is computed server-side based on `operating_times` and server time.
- Returns only publicly visible seller information.

Errors:
- `404 RESOURCE_NOT_FOUND`

### 2.13k `PATCH /v1/admin/sellers/{seller_principal_id}`

Update seller profile fields (admin PATCH).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have supply-point moderation admin permissions.

Request:

```json
{
  "verification_status": "VERIFIED"
}
```

Or for rejection:

```json
{
  "verification_status": "REJECTED",
  "rejection_reason": "Incomplete business documentation"
}
```

Response `200 OK`: updated seller profile.

```json
{
  "principal_id": "uuid",
  "status": "ACTIVE",
  "seller_display_name": "Water Depot",
  "verification_status": "VERIFIED",
  "verification_updated_at": "2025-01-01T00:00:00Z",
  "rejection_reason": null,
  "average_rating": 4.5,
  "review_count": 10,
  "operating_times": null,
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

Notes:
- Uses standard PATCH semantics; omitted fields are not modified.
- `verification_status` can be set to `VERIFIED` or `REJECTED`.
- `rejection_reason` is required when setting `verification_status` to `REJECTED`.
- `rejection_reason` must not be provided when setting `verification_status` to `VERIFIED`.
- If no fields are provided, returns current state (read-only PATCH no-op).

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR` (e.g., `rejection_reason` missing for `REJECTED`)

### 2.13l `GET /v1/admin/supply-points/{supply_point_id}/enrichment`

Get full supply-point enrichment payload (public normalized + admin raw fields).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have supply-point moderation admin permissions.

Response `200 OK`:

```json
{
  "supply_point_id": "uuid",
  "enrichment": {
    "extraction_type": "TAP_STANDPIPE",
    "asset_status": "FUNCTIONAL",
    "operational_condition": "NORMAL",
    "availability_bucket": "H_6_TO_11",
    "survey_year": 2016,
    "province": "Luanda",
    "municipality": "Viana",
    "commune": "Viana",
    "source_location": { "lat": -8.84, "lng": 13.23 },
    "source_location_precision_m": 8.0,
    "source_location_altitude_m": 1219.1,
    "normalization_version": "supply_point_enrichment_v1.0",
    "source_dataset": "pontos_de_agua.csv",
    "source_record_id": "2016|49/AD/07|luanda|viana|viana|-8.840000|13.230000"
  },
  "admin_enrichment": {
    "raw_record": {},
    "failure_type_other_text_raw": null,
    "notes_raw": null,
    "community_response_raw": null,
    "interviewer_name": null,
    "caretaker_name": null,
    "caretaker_phone": null,
    "coordinator_name": null,
    "coordinator_phone": null,
    "funder_raw": null,
    "implementer_raw": null,
    "normalization_notes": null,
    "created_at": "2025-01-01T00:00:00Z",
    "updated_at": "2025-01-01T00:00:00Z"
  }
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

Notes:
- Enrichment fields are physically stored on `supply_points`; admin RBAC controls access to raw/PII fields.

### 2.13m `GET /v1/internal/diagnostics/analytics`

Return analytics pipeline diagnostics (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Response `200 OK`:

```json
{
  "consumer_name": "analytics_consumer",
  "last_seq": 123,
  "latest_events_seq": 130,
  "lag": 7,
  "latest_metrics_computed_at": "2026-02-11T00:00:00Z"
}
```

Notes:
- `lag` is computed as `latest_events_seq - last_seq` (best-effort).
- `latest_metrics_computed_at` is the newest `computed_at` across analytics metrics windows.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

### 2.14 Admin Portal (UI) notes + proposed additions (non-normative)

This section exists to prevent “wishlist drift” across separate documents. It is **not** part of the canonical contract unless an endpoint/field is explicitly defined elsewhere in this file.

Rules:
- **V1 (contract-aligned)**: Admin portal v1 should use only endpoints and shapes already defined in this contract.
- **V1 candidate additions (optional)**: low-disruption additions that improve admin UX and developer experience; these do not block v1 launch.
- **V2 optional**: larger additions that are explicitly out of v1 scope until agreed.

Portal UX note (v1):
- Admin sessions may not have any “site setup” state. The portal should branch using the `is_internal_ops_admin` field
  returned by `GET /v1/me` (defined in `docs/architecture/api_contract/02_auth_identity.md`) rather than calling an
  additional admin endpoint just to detect admin capability (DECIDED, D-069).

Decision table (tracking only; non-normative):

| Candidate | Type | Benefit | Cost / risk | Owner | Target version |
|----------|------|---------|-------------|-------|----------------|
| Org support tools (`reconcile`, `reset-keys`, `audit`, `suspend/unsuspend`) | Endpoints | Support workflows + incident response tooling. | Side-effecting operations require strict authorization, auditability, and consistent enforcement across APIs (e.g., suspend must actually block access). | Backend + Product | V2 optional |
| Inventory expansion beyond provisioning (assignment, last_seen, cert lifecycle, bulk import UI flows) | Fields + endpoints | Admins can manage fleet assignment/visibility rather than only provisioning. | Cross-domain modeling risk (provisioning vs fleet vs org ownership) and permission boundary complexity. | Backend + Product | V2 optional |
| Diagnostics “advanced” tooling (error drilldowns, retry/dead-letter ops, queue depth metrics) | Endpoints | Faster incident triage + remediation actions. | High blast radius if misused; needs guardrails + idempotency + strong RBAC. | Backend + Ops | V2 optional |
| Firmware portal binary upload (multipart upload + scanning + approval workflow) | Endpoint + infra | Allows admins to publish releases from UI. | Requires blob storage integration, malware scanning, checksum validation, and possibly approvals; high security surface area. | Backend + Ops | V2 optional |

---  # end admin management
