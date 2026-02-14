## Jila API Backend – API Contract (v1) — Extracted section (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

## 12. Analytics (intelligence layer)

### 12.1 Window semantics

Analytics endpoints use bounded windows:
- `window=24h|7d|30d` (default `24h`)

Response fields:
- `snapshot_at`: server UTC timestamp for the read
- `window_start` / `window_end`: UTC bounds
- `inputs_version` / `metric_version`: deterministic computation versioning
- `data_gap_hours`: estimated missing-observation time in the window
- `confidence`: `HIGH|MEDIUM|LOW`

### 12.2 Feature gating

Analytics surfaces are feature-gated:
- View APIs require `analytics.view`
- Export API requires `analytics.export`

On denial:
- `403 FORBIDDEN`
- `error_code = FEATURE_GATE`
- `details.feature_key` is required

### 12.3 `GET /v1/reservoirs/{reservoir_id}/analytics`

Return windowed analytics metrics for one reservoir.

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must have reservoir access via existing reservoir RBAC.

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `window` | string | optional: `24h|7d|30d` (default `24h`) |

Response `200 OK`:

```json
{
  "snapshot_at": "2026-02-11T00:00:00Z",
  "window_label": "24h",
  "window_start": "2026-02-10T00:00:00Z",
  "window_end": "2026-02-11T00:00:00Z",
  "computed_at": "2026-02-11T00:00:00Z",
  "inputs_version": 1,
  "metric_version": 1,
  "data_gap_hours": 1.0,
  "confidence": "HIGH",
  "runout_hours": 2.0,
  "runout_prob": 0.0833,
  "autonomy_days_est": 1.7,
  "supply_hours": 5.0,
  "supply_fragmentation_index": 0.6,
  "mean_supply_duration_hours": 1.7,
  "daily_supply_coverage": 0.2083,
  "intermittence_severity_index": 0.5,
  "demand_liters": 460.0,
  "elasticity_near_empty": 0.42,
  "suppressed_demand_index": 0.18,
  "deliveries_count": 0,
  "delivered_liters": 0,
  "liters_loaded": 0,
  "liters_per_km": null,
  "refill_time_minutes": 0,
  "refill_load_rate_l_per_min": null,
  "downtime_hours": 0,
  "mobile_nrw_liters": 0,
  "pipeflow_liters": 780,
  "truckflow_liters": 0,
  "resilience_ratio": 1.0,
  "reservoir_id": "uuid"
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` / `403 FEATURE_GATE`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

### 12.4 `GET /v1/sites/{site_id}/analytics`

Return windowed analytics metrics aggregated for one site.

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must have site access via existing site RBAC.

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `window` | string | optional: `24h|7d|30d` (default `24h`) |

Response `200 OK`: same shape as 12.3, with `site_id`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` / `403 FEATURE_GATE`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

### 12.5 `GET /v1/accounts/{org_principal_id}/analytics`

Return windowed analytics metrics aggregated for an organization account.

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must have org role `OWNER|MANAGER|VIEWER` on the target org account.

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `window` | string | optional: `24h|7d|30d` (default `24h`) |

Response `200 OK`: same shape as 12.3, with `org_principal_id`.

Cross-reference:
- The same org analytics payload shape is embedded in
  `GET /v1/accounts/{org_principal_id}/dashboard-snapshot` as `org_analytics`
  for one-call dashboard bootstrap.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` / `403 FEATURE_GATE`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

### 12.6 `GET /v1/zones/{zone_id}/analytics`

Return integrated ecosystem analytics for one zone.

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Internal ops admins are allowed.
- Non-admin callers must have org access in the zone (derived from site ownership + org grants).

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `window` | string | optional: `24h|7d|30d` (default `24h`) |

Response `200 OK`: same shape as 12.3, with `zone_id`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` / `403 FEATURE_GATE`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

### 12.7 `GET /v1/devices/{device_id}/mobile/stops`

Return classified mobile stop episodes for one device.

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must have device access via existing device RBAC.

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `window` | string | optional: `24h|7d|30d` (default `24h`) |

Response `200 OK`:

```json
{
  "device_id": "B43A4536C83C",
  "window_label": "24h",
  "window_start": "2026-02-10T00:00:00Z",
  "window_end": "2026-02-11T00:00:00Z",
  "items": [
    {
      "id": 123,
      "device_uuid": "uuid",
      "start_at": "2026-02-10T11:30:00Z",
      "end_at": "2026-02-10T11:48:00Z",
      "duration_seconds": 1080,
      "centroid_lat": -8.84,
      "centroid_lng": 13.23,
      "zone_id": "uuid",
      "volume_delta_liters": -250.0,
      "event_type": "DELIVERY",
      "confidence": "HIGH",
      "inputs_version": 1
    }
  ]
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` / `403 FEATURE_GATE`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

### 12.8 `GET /v1/devices/{device_id}/mobile/places`

Return significant place clusters for one device.

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Caller must have device access via existing device RBAC.

Response `200 OK`:

```json
{
  "device_id": "B43A4536C83C",
  "items": [
    {
      "place_id": "uuid",
      "device_uuid": "uuid",
      "centroid_lat": -8.84,
      "centroid_lng": 13.23,
      "zone_id": "uuid",
      "place_type": "REFILL_DEPOT",
      "first_seen_at": "2026-02-01T00:00:00Z",
      "last_seen_at": "2026-02-11T00:00:00Z",
      "inputs_version": 1
    }
  ]
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` / `403 FEATURE_GATE`
- `404 RESOURCE_NOT_FOUND`

### 12.9 `POST /v1/analytics/exports`

Create a synchronous analytics export payload for a scoped entity.

Auth:
- Requires `Authorization: Bearer <jwt>`.
- Scope RBAC must pass for the referenced scope id.

Request:

```json
{
  "scope": "reservoir|site|org|zone",
  "format": "CSV|PDF|HTML",
  "window": "24h|7d|30d",
  "reservoir_id": "uuid-or-null",
  "site_id": "uuid-or-null",
  "org_principal_id": "uuid-or-null",
  "zone_id": "uuid-or-null"
}
```

Rules:
- The id field matching `scope` is required.
- `analytics.export` entitlement is required.

Response `200 OK`:

```json
{
  "export_id": "uuid",
  "scope": "org",
  "scope_id": "uuid",
  "format": "CSV",
  "window_label": "30d",
  "generated_at": "2026-02-11T00:00:00Z",
  "content": "..."
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` / `403 FEATURE_GATE`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

### 12.10 `GET /v1/internal/diagnostics/analytics`

Return analytics consumer lag + latest compute timestamp (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be internal ops admin.

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

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
