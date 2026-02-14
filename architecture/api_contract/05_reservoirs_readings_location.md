## Jila API Backend – API Contract (v1) — Extracted section (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

## 3. Reservoirs, readings, location

### 3.1 `POST /v1/accounts/{org_principal_id}/reservoirs`

`org_principal_id`:
- Organization principal: caller must have an org role (`OWNER|MANAGER|VIEWER`) on that organization.
- ORGANIZATION principal: caller must have org role (`OWNER|MANAGER`) and must provide `site_id` belonging to that org.

Request (single-org example):

```json
{
  "site_id": "uuid",
  "name": "Home tank",
  "reservoir_type": "TANK",
  "mobility": "FIXED",
  "is_pipe_connected": false,
  "capacity_liters": 1000,
  "safety_margin_pct": 20,
  "monitoring_mode": "MANUAL",
  "location": { "lat": -8.84, "lng": 13.23 }
}
```

Rules:
- Client does not provide `owner_principal_id`.
- `site_id` is required and must refer to a site owned by the target principal.
- Server derives ownership from the site.
- **Device monitoring calibration (v1)**:
  - If `monitoring_mode = DEVICE`, calibration is required, but may be provided in one of two ways:
    - Explicit calibration:
      - `sensor_empty_distance_mm` (positive int)
      - `sensor_full_distance_mm` (non-negative int; `0` is allowed as a baseline)
      - Additionally: `sensor_empty_distance_mm` **must be greater than** `sensor_full_distance_mm`.
    - Default calibration derived from reservoir height:
      - `height_mm` (positive int)
      - If both `sensor_empty_distance_mm` and `sensor_full_distance_mm` are omitted, the backend derives defaults:
        - `sensor_empty_distance_mm = height_mm`
        - `sensor_full_distance_mm = 0`
  - If one calibration field is provided, the other must also be provided (even when `monitoring_mode = MANUAL`).
  - Rationale: device-derived readings require calibration; missing both explicit calibration and `height_mm` will cause telemetry to be ingested but no readings to be produced (backend diagnostic: `CALIBRATION_MISSING`).
- **Hierarchy invariant (v1)**:
  - A reservoir is always persisted with a non-null `site_id`.
  - `site_id` is required in the request for all actors.
  - `reservoirs.owner_principal_id` is derived from `sites.owner_principal_id` (client never sets ownership).
- **Pipe connectivity (v1)**:
  - `is_pipe_connected` defaults to `false` when omitted.
  - Intermittence / piped-network supply metrics only apply when `is_pipe_connected = true` and `mobility = FIXED`.

Response `200 OK`:

```json
{ "reservoir_id": "uuid" }
```

### 3.1a `GET /v1/accounts/{org_principal_id}/reservoirs`

Lists reservoirs owned by the account principal (user or organization). See `docs/architecture/api_contract/02_auth_identity.md` for account scoping rules.

Query params (optional; v1):
- `site_id` (uuid; filter to a single site)
- `reservoir_type` (`TANK|TRUCK_TANK|BUFFER_TANK|OTHER`)
- `monitoring_mode` (`MANUAL|DEVICE`)
- `level_state` (`FULL|NORMAL|LOW|CRITICAL`)
- `has_device` (boolean; when true, only reservoirs with an attached device)

Response `200 OK`:

```json
{
  "items": [
    {
      "reservoir_id": "uuid",
      "site_id": "uuid",
      "owner_principal_id": "uuid",
      "name": "Home tank",
      "reservoir_type": "TANK",
      "mobility": "FIXED",
      "is_pipe_connected": false,
      "capacity_liters": 1000,
      "safety_margin_pct": 20,
      "monitoring_mode": "MANUAL",
      "location": { "lat": -8.84, "lng": 13.23 },
      "location_updated_at": "2025-01-01T00:00:00Z",
      "thresholds": {
        "full_threshold_pct": null,
        "low_threshold_pct": null,
        "critical_threshold_pct": null
      },
      "level_state": "LOW",
      "level_state_updated_at": "2025-01-01T00:00:00Z",
      "connectivity_state": "OFFLINE",
      "last_reading_age_seconds": null,
      "device": null,
      "latest_reading": null
    }
  ]
}
```

### 3.2 `GET /v1/reservoirs/{reservoir_id}`

Response `200 OK`:

```json
{
  "reservoir_id": "uuid",
  "site_id": "uuid",
  "owner_principal_id": "uuid",
  "name": "Home tank",
  "reservoir_type": "TANK",
  "mobility": "FIXED",
  "is_pipe_connected": false,
  "capacity_liters": 1000,
  "safety_margin_pct": 20,
  "monitoring_mode": "MANUAL",
  "location": { "lat": -8.84, "lng": 13.23 },
  "location_updated_at": "2025-01-01T00:00:00Z",
  "height_mm": null,
  "sensor_empty_distance_mm": null,
  "sensor_full_distance_mm": null,
  "full_threshold_pct": null,
  "low_threshold_pct": null,
  "critical_threshold_pct": null,
  "level_state": "LOW",
  "level_state_updated_at": "2025-01-01T00:00:00Z",
  "latest_reading": {
    "level_pct": 40,
    "volume_liters": 400,
    "battery_pct": null,
    "recorded_at": "2025-01-01T00:00:00Z",
    "source": "MANUAL"
  }
}
```

### 3.3 `PATCH /v1/reservoirs/{reservoir_id}`

Request (partial):

```json
{
  "capacity_liters": 1200,
  "safety_margin_pct": 25,
  "seller_availability_status": "UNAVAILABLE",
  "location": { "lat": -8.84, "lng": 13.23 },
  "is_pipe_connected": true,
  "height_mm": 1200,
  "sensor_empty_distance_mm": 100,
  "sensor_full_distance_mm": 0,
  "full_threshold_pct": 90,
  "low_threshold_pct": 30,
  "critical_threshold_pct": 15
}
```

Response `200 OK`: updated reservoir.

### 3.4 `DELETE /v1/reservoirs/{reservoir_id}` (soft delete)

Response `200 OK`:

```json
{ "status": "OK" }
```

Rules:
- Soft delete: preserve rows; set `reservoirs.deleted_at`.
- Idempotent: deleting an already-deleted reservoir returns `200 OK`.
- After deletion:
  - `GET /v1/reservoirs/{reservoir_id}` returns `404`
  - list endpoints exclude deleted reservoirs
- If a device is attached (`devices.reservoir_id = reservoir_id`), return `409 RESOURCE_CONFLICT`.

### 3.5 `GET /v1/reservoirs/{reservoir_id}/readings`

Query params:
- `limit` (default 100)
- `cursor` (optional)

Response `200 OK`:

```json
{
  "items": [
    {
      "recorded_at": "2025-01-01T00:00:00Z",
      "level_pct": 40,
      "volume_liters": 400,
      "source": "MANUAL"
    }
  ],
  "next_cursor": null
}
```

### 3.6 `POST /v1/reservoirs/{reservoir_id}/manual-reading`

Request:

Optional headers:
- `Idempotency-Key: <string>` — enables safe client retries (offline queue). If the same key is reused with a different
  request payload, the API returns a deterministic `409 IDEMPOTENCY_KEY_CONFLICT`.

```json
{
  "level_pct": 40,
  "recorded_at": "2025-01-01T00:00:00Z",
  "note": "optional"
}
```

Response `200 OK`:

```json
{ "reading_id": 123 }
```

Rules:
- Household-only: manual readings are **not allowed** for organization-owned reservoirs (Decision **D-038**).

Errors:
- `403 FORBIDDEN` (`error_code = FORBIDDEN`) when the reservoir is owned by an organization principal (manual monitoring not allowed)

### 3.7 `POST /v1/reservoirs/{reservoir_id}/share`

Create a share invite token for a reservoir. Clients share the returned `invite_token_id`
out-of-band via WhatsApp/SMS/email using the OS share sheet.

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must have manage access to the reservoir (owner / `OWNER|MANAGER` grant via org/site/reservoir scope).

Request (optional):

```json
{
  "invite_target_phone_e164": "+2449XXXXXXX",
  "invite_target_email": "user@example.com"
}
```

Notes:
- Request body is optional. When provided, at least one target identifier is required.
- Target identifiers are used for prefill and anti-theft verification.

Response `200 OK`:

```json
{
  "invite_token_id": "uuid",
  "invite_code": "ABCD-EFGH",
  "expires_at": "2025-01-08T00:00:00Z",
  "invite_target_phone_e164": "+2449XXXXXXX|null",
  "invite_target_email": "user@example.com|null"
}
```

Semantics (idempotent):
- If the caller already has an unexpired, unused share token for this reservoir, the API may return the existing token to avoid spam on retries.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` (`error_code = FORBIDDEN`) when caller lacks manage access
- `404 RESOURCE_NOT_FOUND` when `reservoir_id` does not exist
- `422 INVALID_REQUEST` when ids are not valid UUIDs

### 3.8 `POST /v1/reservoir-invites/accept`

Accept a reservoir share invite token and materialize a `RESERVOIR` `access_grants` row for the caller.

Auth:
- Requires `Authorization: Bearer <jwt>`.

Request (one-of; v1):

```json
{ "invite_token_id": "uuid" }
```

or

```json
{ "invite_code": "ABCD-EFGH" }
```

Response `200 OK`:

```json
{ "status": "OK" }
```

Semantics (idempotent):
- Validates invite token (`type = INVITE`, `object_type = RESERVOIR`, not expired, not used/revoked).
- Creates/ensures `access_grants` for `object_type = RESERVOIR` / `object_id = reservoir_id` for the caller principal.
- Emits `FIRESTORE_MIRROR_RECONCILE_REQUESTED` for the caller principal so mirrors are pruned/backfilled.

Errors:
- `401 UNAUTHORIZED`
- `409 INVITE_EXPIRED` when invite is expired
- `422 INVALID_INVITE` when invite token is invalid/used/revoked
- `422 INVALID_REQUEST` when ids are not valid UUIDs

#### 0.5.24c `POST /v1/reservoir-invites/resolve` (public)

Resolve a reservoir invite code and return onboarding prefill details.

Auth:
- Public (no JWT).

Request:

```json
{ "invite_code": "ABCD-EFGH" }
```

Response `200 OK`:

```json
{
  "invite_code": "ABCD-EFGH",
  "expires_at": "2025-01-08T00:00:00Z",
  "invite_target_phone_e164": "+2449XXXXXXX",
  "invite_target_email": "user@example.com"
}
```

Notes:
- TODO(rate_limit): this endpoint MUST be rate-limited in production (Decision D-029).

Errors:
- `409 INVITE_EXPIRED`
- `422 INVALID_INVITE`

---
