## Jila API Backend – API Contract (v1) — Extracted section (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

## 4. Devices

### 4.0 `POST /v1/internal/device-inventory/units/{device_id}`

Create or update a physical inventory unit record (admin/provisioning).

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must be an internal ops admin (DB-backed; no restarts):
  - `platform_settings.internal_ops_org_id` must be configured (preferred).
  - Alternate configuration source: `settings.INTERNAL_OPS_ORG_ID` (env) may be used if DB settings are not configured.
  - Caller must have an ACTIVE `access_grants` row on `ORG:<internal_ops_org_id>` with role `OWNER|MANAGER`.

Request:

```json
{
  "serial_number": "JL-AB12CD",
  "cert_thumbprint_sha1": "7A8E8B469B9B67A5C460221553C22EDAC1428B81",
  "provisioning_status": "PENDING|PROVISIONED|DISABLED",
  "metadata": {}
}
```

Rules (v1):
- `serial_number` is normalized to uppercase (trim + uppercase) and must match `^JL-[A-Z0-9]{6}$` (D-057).
- `device_id` is provided in the path; it is normalized to uppercase; in v1 it is MAC-derived and immutable (D-053).
- `cert_thumbprint_sha1` is optional unless `provisioning_status = PROVISIONED`.
- Idempotent upsert keyed by `serial_number` and `device_id` (must not allow one serial to map to multiple device_ids).
- If `provisioning_status = DISABLED`, the backend will:
  - mark the corresponding `devices` row (if any) as `INACTIVE`, and
  - force-detach it from any reservoir (sets `devices.reservoir_id = NULL`), reverting the reservoir to `monitoring_mode = MANUAL`.
- If `provisioning_status = PROVISIONED`, the backend attempts to create/update the Azure Event Grid Namespace MQTT client
  (`authenticationName = device_id`) using `cert_thumbprint_sha1`.
  - On Azure provisioning failure, the server returns `503 SERVICE_UNAVAILABLE` and records `last_provision_error_*` in Postgres.

Response `200 OK`:

```json
{ "device_id": "B43A4536C83C" }
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `422 VALIDATION_ERROR`
- `409 RESOURCE_CONFLICT` (mapping conflict)
- `503 SERVICE_UNAVAILABLE` (Azure provisioning failure / disabled)

### 4.0a `GET /v1/internal/device-inventory/units`

List inventory units for internal ops (admin-only).

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
| `include_stats` | boolean | optional (default false); when true, include aggregate stats for the full filtered set (D-064) |

Response `200 OK`:

```json
{
  "items": [
    {
"id": "uuid",
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

Notes:
- `stats` is included only when `include_stats=true` and is computed across the full filtered set (not the page). See **D-064**.

### 4.0b `GET /v1/internal/device-inventory/units/{device_id}`

Get an inventory unit detail for internal ops (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Response `200 OK`:

```json
{
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
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

### 4.0c `GET /v1/internal/devices/{device_id}/overview`

Get an admin device overview by `device_id` (inventory + operational context).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `telemetry_window_hours` | int | optional (default 24, max 168) |
| `include_events` | boolean | optional (default true) |
| `events_limit` | int | optional (default 20, max 200) |

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
    "desired": {
      "config_version": 3,
      "config": {},
      "mqtt_queue_id": "string-or-null",
      "updated_at": "2025-01-01T00:00:00Z"
    },
    "applied": { "applied_config_version": 2, "applied_at": "2025-01-01T00:00:00Z" }
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

Notes:
- The endpoint may return `inventory_unit` without `operational_device` if the physical inventory unit exists but the operational `devices` row has not been created yet.
- `status` is the portal-friendly derived status (based on `raw_status` + `last_seen_at`), consistent with `GET /v1/accounts/{org_principal_id}/devices`.
- Telemetry stats are summarized (no raw payloads).

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

### 4.1 `POST /v1/internal/devices/{device_id}/register`

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must be an internal ops admin and `org_principal_id` must equal the authenticated admin principal id (D-059).

Request:

```json
{
  "device_type": "LEVEL_SENSOR",
  "firmware_version": "1.0.0",
  "imei": "string",
  "iccid": "string"
}
```

Response `200 OK`:

```json
{ "device_id": "string" }
```

Notes (DECIDED, D-055):
- This endpoint is provisioning-only (internal ops admin only; D-059).
- It must not allow arbitrary creation of devices by end-users.
- It may only create/refresh an operational `devices` row when a matching inventory unit exists in `device_inventory_units`.

### 4.2 `POST /v1/accounts/{org_principal_id}/devices/attach`

Request:

```json
{
  "serial_number": "JL-AB12CD",
  "reservoir_id": "uuid"
}
```

Response `200 OK`:

```json
{ "status": "OK", "device_id": "B43A4536C83C" }
```

Errors:
- `409 DEVICE_ALREADY_PAIRED`
- `409 RESOURCE_CONFLICT` (generic; must not leak serial existence/ownership)
- `409 RESOURCE_CONFLICT` when device is inactive (`details.reason = DEVICE_INACTIVE`)

### 4.3 `POST /v1/accounts/{org_principal_id}/devices/{device_id}/detach`

Response `200 OK`:

```json
{ "status": "OK" }
```

Notes:
- If the device is inactive, the server returns `409 RESOURCE_CONFLICT` (`details.reason = DEVICE_INACTIVE`).

### 4.3a `GET /v1/accounts/{org_principal_id}/devices`

Lists devices for portal operational visibility (DECIDED, D-034).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `site_id` | uuid | optional |
| `reservoir_id` | uuid | optional |
| `status` | string | optional: `ONLINE|OFFLINE|MAINTENANCE` |
| `cursor` | string | optional |
| `limit` | int | optional (default 50, max 200) |
| `include_stats` | boolean | optional (default false); when true, include aggregate stats for the full filtered set (D-064) |

Response `200 OK`:

```json
{
  "items": [
    {
      "device_id": "string",
      "serial_number": "JL-001234",
      "name": "Tank A sensor",
      "device_type": "LEVEL_SENSOR",
      "firmware_version": "2.1.0",
      "status": "ONLINE",
      "battery_pct": 85,
      "signal_strength_dbm": -65,
      "last_seen_at": "2025-01-01T00:00:00Z",
      "last_reading_at": "2025-01-01T00:00:00Z",
      "reservoir": { "reservoir_id": "uuid", "name": "Tank A" },
      "site": { "site_id": "uuid", "name": "Site A" },
      "alerts": { "active_count": 1, "highest_severity": "WARNING" },
      "registered_at": "2025-01-01T00:00:00Z"
    }
  ],
  "next_cursor": "opaque",
  "total_count": 42,
  "stats": {
    "by_status": { "ONLINE": 30, "OFFLINE": 10, "MAINTENANCE": 2 },
    "battery_health": { "good_count": 25, "low_count": 10, "critical_count": 3 },
    "firmware_versions": { "2.1.0": 20, "2.0.5": 12, "1.9.0": 6 }
  }
}
```

Notes:
- `device_id` is the MQTT identity (topic segment) for v1 devices.
- `battery_pct` and `signal_strength_dbm` may be `null` if the backend has not observed telemetry for the device yet.
- `firmware_version` is the last observed firmware version (from device telemetry `system.firmware_version` when available), and may be `null` for newly registered devices.
- `total_count` is provided for portal UX; if omitted in future for performance reasons, clients must rely on cursor pagination.
- `stats` is included only when `include_stats=true` and is computed across the full filtered set (not the page). See **D-064**.
- `stats.firmware_versions` is bounded to the top 20 versions by descending count (ties broken lexicographically); other versions are omitted (D-067).

### 4.3b `GET /v1/accounts/{org_principal_id}/devices/{device_id}`

Returns portal-friendly device detail metadata (distinct from config) (DECIDED, D-034).

Response `200 OK`:

```json
{
  "device_id": "string",
  "serial_number": "JL-001234",
  "name": "Tank A sensor",
  "device_type": "LEVEL_SENSOR",
  "firmware_version": "2.1.0",
  "status": "ONLINE",
  "battery_pct": 85,
  "signal_strength_dbm": -65,
  "last_seen_at": "2025-01-01T00:00:00Z",
  "attached_reservoir": { "reservoir_id": "uuid", "name": "Tank A" },
  "attached_site": { "site_id": "uuid", "name": "Site A" },
  "registered_at": "2025-01-01T00:00:00Z"
}
```

---

### 4.3c `PATCH /v1/accounts/{org_principal_id}/devices/{device_id}`

Patch portal-facing device metadata (v1).

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must be `OWNER|MANAGER` of the containing org/site/reservoir (or explicit `DEVICE` grant).

Request (at least one field required):

```json
{ "name": "Tank A sensor" }
```

Rules:
- `name` must be a non-empty string when provided.
- Decommissioned devices cannot be patched (`409 RESOURCE_CONFLICT`, `details.reason = DEVICE_DECOMMISSIONED`).

Response `200 OK`:

```json
{ "device_id": "string" }
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR` (no fields / invalid `name`)
- `409 RESOURCE_CONFLICT` (decommissioned)

### 4.3d `GET /v1/accounts/{org_principal_id}/devices/{device_id}/telemetry/latest`

Get the latest stored raw telemetry message for a device.

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must have access to the device (explicit `DEVICE` grant or container RBAC when attached).

Response `200 OK`:

```json
{
  "device_id": "string",
  "latest": {
    "telemetry_message_id": 123,
    "mqtt_client_id": "B43A4536C83C",
    "schema_version": 1,
    "seq": 456,
    "recorded_at": "2025-01-01T00:00:00Z",
    "received_at": "2025-01-01T00:00:00Z",
    "payload": {}
  }
}
```

Notes:
- If no telemetry has been stored for the device yet, `latest` is `null`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

### 4.3e `DELETE /v1/accounts/{org_principal_id}/devices/{device_id}`

Decommission a device (soft delete).

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must be `OWNER|MANAGER` of the containing org/site/reservoir (or explicit `DEVICE` grant).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `confirm` | boolean | required; must be `true` |

Rules:
- If `confirm != true`, return `409 RESOURCE_CONFLICT` with `details.reason = CONFIRMATION_REQUIRED` and a human-readable warning in `message`/`details`.
- The backend sets `devices.status = DECOMMISSIONED`.
- If the device is attached, the backend force-detaches it and reverts the reservoir to `monitoring_mode = MANUAL`.
- Idempotent: deleting an already decommissioned device returns `200 OK`.

Response `200 OK`:

```json
{ "status": "OK" }
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `409 RESOURCE_CONFLICT` (confirmation required)

## 4.4 Device configuration (desired state)

### 4.4.1 `GET /v1/accounts/{org_principal_id}/devices/{device_id}/config`

Returns desired + applied config state.

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must have access to the device (org RBAC or explicit grant).

Response `200 OK`:

```json
{
  "device_id": "string",
  "desired": { "config_version": 3, "config": {} },
  "applied": { "applied_config_version": 2, "applied_at": "2025-01-01T00:00:00Z" }
}
```

Notes:
- If the device has never reported an applied config, `applied` is `null`.
- If no desired config has ever been set, the server returns `desired.config_version = 0` and `desired.config = {}`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

### 4.4.1a Internal ops bypass (v1)

Internal ops admins call `GET /v1/internal/devices/{device_id}/config`. When the caller is an internal ops admin (D-059),
the backend applies internal ops bypass rules.

### 4.4.2 `PUT /v1/accounts/{org_principal_id}/devices/{device_id}/config`

Sets the desired config (JSON, evolving).

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must be `OWNER|MANAGER` of the containing org/site/reservoir.

Request:

```json
{
  "config_version": 3,
  "config": {
    "type": "operations",
    "sleep_seconds": 300,
    "gps_enabled": true
  }
}
```

Rules:
- Server enforces monotonic `config_version` per device.
- `config.type` is required and must be a non-empty string (used for MQTT topic routing: `devices/{device_id}/config/{type}`).
- Worker publishes the config via MQTT immediately upon receipt (via outbox event `DEVICE_CONFIG_UPDATED`).
- If device activity is observed before a config status ACK with `success=true` is received, the backend retries publishing the desired config (throttled to once per 60 seconds per device).
- The backend generates a non-empty `mqtt_queue_id` for correlation; device must ACK with this ID.

Response `200 OK`:

```json
{ "status": "OK", "mqtt_queue_id": "string" }
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `409 DEVICE_CONFIG_VERSION_CONFLICT`

### 4.4.2a Internal ops bypass (v1)

Internal ops admins call `PUT /v1/internal/devices/{device_id}/config`. When the caller is an internal ops admin (D-059),
the backend applies internal ops bypass rules.

---

## 4.5 Firmware management

### 4.5.0 `POST /v1/internal/firmware/upload` (admin-only)

Upload a firmware binary to blob storage and register a firmware release.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin (D-059).

Notes:
- This endpoint handles the blob upload server-side; clients do not upload directly to blob storage.
- The blob URI returned is used as the device download URL in firmware updates.

Request (`multipart/form-data`):

Form fields:
- `device_type` (string, required)
- `version` (string, required)
- `notes` (string, optional)
- `file` (binary, required)

Response `200 OK`:

```json
{
  "firmware_release_id": "uuid",
  "device_type": "DISTANCE_SENSOR",
  "version": "1.2.3",
  "blob_uri": "https://storage.blob.core.windows.net/firmware/...",
  "sha256_hex": "64-hex",
  "size_bytes": 123456
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `409 RESOURCE_CONFLICT` (version already exists)
- `422 VALIDATION_ERROR`
- `503 SERVICE_UNAVAILABLE` (storage not configured or upload failed)

### 4.5.0a Compatibility alias (admin-only)

`POST /v1/firmware/upload` is an admin-only alias of `/v1/internal/firmware/upload` for legacy tooling.

### 4.5.1 `POST /v1/internal/firmware/releases`

Creates firmware release metadata referencing blob storage.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin, and `org_principal_id` must match the authenticated admin principal id.

Request:

```json
{
  "version": "1.2.3",
  "blob_uri": "blob://bucket/key",
  "sha256_hex": "64-hex",
  "size_bytes": 123456,
  "notes": "optional"
}
```

Response `200 OK`:

```json
{ "firmware_release_id": "uuid" }
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `422 VALIDATION_ERROR`

### 4.5.2 `GET /v1/firmware/releases`

List available firmware releases.

Auth:
- Requires `Authorization: Bearer <jwt>`.

Response `200 OK`:

```json
{ "items": [{ "id": "uuid", "version": "1.2.3" }] }
```

Errors:
- `401 UNAUTHORIZED`

### 4.5.3 `POST /v1/accounts/{org_principal_id}/devices/{device_id}/firmware-update`

Request OTA firmware update for a device.

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must be `OWNER|MANAGER` of the containing org/site/reservoir.

Request:

```json
{
  "firmware_release_id": "uuid",
  "config_version": 1
}
```

Response `200 OK`:

```json
{
  "job_id": "uuid",
  "status": "PENDING",
  "mqtt_queue_id": "string",
  "config_version": 1
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

### 4.5.3a Internal ops bypass (v1)

Internal ops admins call `POST /v1/internal/devices/{device_id}/firmware-update`. When the caller is an internal ops admin
(D-059), the backend applies internal ops bypass rules.

---

## 11. Telemetry ingestion payload notes (device-connected reservoirs)

Device telemetry is JSON and may include multiple categories:
- sensor readings (reservoir level, etc.)
- battery
- cellular network info (IMEI/ICCID and radio metrics)

Storage strategy (canonical):
- Extract typed fields used for product logic (e.g., reservoir level) into typed tables (`reservoir_readings`).
- Store the raw payload for audit/debugging into `device_telemetry_messages.payload` (JSONB).

Device MQTT protocol (canonical):
- See `docs/architecture/jila_api_backend_device_management.md` for MQTT topics and payload requirements.

Backend ingestion note:
- The Event Hubs message is expected to carry the original MQTT topic (so `{device_id}` can be resolved) plus the JSON payload.

---
