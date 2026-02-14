## Jila API Backend – API Contract (v1) — Extracted section (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

## 5. SupplyPoints (discovery)

### 5.1 `GET /v1/supply-points`

Auth:
- Public (no JWT required)

Query params (all optional; v1):
- `lat`, `lng` (used for geo filtering when provided together)
- `within_radius_km`
- `kind` (optional)
- `operational_status` (optional)
- `availability_status` (optional)

Notes (geo semantics; see decision **D-006**):
- If `lat` and `lng` are provided (together), the server applies a geo filter using PostGIS `geography` distance semantics.
- If `within_radius_km` is omitted while `lat`/`lng` are provided, the server uses a default radius of **10km**.
- If `within_radius_km` is provided and is **<= 0**, the server treats the request as unfiltered by radius.
- If `within_radius_km` is provided and is **> 0**, the server uses the provided value (no backend max cap).
- If `lat`/`lng` are omitted, the server returns a recent slice (still limited to 200 results).

Response `200 OK`:

```json
{
  "items": [
    {
      "id": "uuid",
      "kind": "STANDPIPE",
      "label": "Standpipe A",
      "location": { "lat": -8.84, "lng": 13.23 },
      "verification_status": "PENDING_REVIEW",
      "verification_updated_at": "2025-01-01T00:00:00Z",
      "operational_status": "ACTIVE",
      "operational_status_updated_at": "2025-01-01T00:00:00Z",
      "availability_status": "AVAILABLE",
      "availability_evidence_type": "REPORTED",
      "availability_updated_at": "2025-01-01T00:00:00Z",
      "attributes": {},
      "enrichment": {
        "extraction_type": "TAP_STANDPIPE",
        "asset_status": "FUNCTIONAL",
        "operational_condition": "NORMAL",
        "availability_bucket": "H_6_TO_11",
        "payment_model": "FREE",
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
      }
    }
  ]
}
```

Notes:
- `enrichment` is optional and contains only public-safe normalized fields.
- Position objects in this surface remain canonical as `location: {lat, lng}` (and `source_location` when present).
- Enrichment fields are physically stored on `supply_points`; this route still exposes only the public-safe subset.

### 5.2 `POST /v1/supply-points` (community nomination)

Auth:
- Required (Bearer access token)

Request:

```json
{
  "kind": "STANDPIPE",
  "label": "Standpipe A",
  "location": { "lat": -8.84, "lng": 13.23 },
  "attributes": {}
}
```

Rules:
- Creates a new SupplyPoint nomination with `verification_status = PENDING_REVIEW`.
- The server is authoritative for lifecycle timestamps (`verification_updated_at`, `created_at`, `updated_at`) and cached status timestamps.
- Public discovery (`GET /v1/supply-points`) may include `PENDING_REVIEW` items, which must be clearly flagged via `verification_status`.

Response `200 OK`:

```json
{
  "id": "uuid",
  "kind": "STANDPIPE",
  "label": "Standpipe A",
  "location": { "lat": -8.84, "lng": 13.23 },
  "verification_status": "PENDING_REVIEW",
  "verification_updated_at": "2025-01-01T00:00:00Z",
  "operational_status": "UNKNOWN",
  "operational_status_updated_at": null,
  "availability_status": "UNKNOWN",
  "availability_evidence_type": null,
  "availability_updated_at": null,
  "attributes": {},
  "enrichment": null
}
```

### 5.3 `PATCH /v1/supply-points/{supply_point_id}` (status update)

Auth:
- Required (Bearer access token)

Request (partial; any subset):

```json
{
  "operational_status": "ACTIVE",
  "availability_status": "AVAILABLE",
  "availability_evidence_type": "REPORTED",
  "attributes": {}
}
```

Notes:
- This endpoint is **partial-update friendly**: callers may send only the fields they are updating.
- When `availability_status` is provided, `availability_evidence_type` is required.
- Enum values for SupplyPoint lifecycle/status fields are defined in `docs/architecture/jila_api_backend_data_models.md` (see enum catalog `docs/architecture/jila_api_backend_enums_v1.md`).

Rules:
- The server sets `operational_status_updated_at` and `availability_updated_at` as **service-generated UTC** timestamps when it accepts an update (clients do not set these cached timestamps).
- Authenticated users may submit `REPORTED` updates (rate-limited) for availability.
- Operator (via `operator_principal_id` or explicit `SUPPLY_POINT:<id>` grant) may submit operator-grade updates.
- Internal ops admin may submit operator-grade updates for support/admin tooling.
- Cached-state conflict resolution uses evidence priority for availability.

Response `200 OK`:

```json
{ "status": "OK" }
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` (RBAC for some update types / evidence levels)
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

### 5.4 Moderation endpoints (admin-only)

Moderation transitions are expressed as explicit endpoints (no action dispatcher).

Auth:
- Required (Bearer access token)
- RBAC required: admin-only for all moderation endpoints below.

Routes:
- `POST /v1/supply-points/{supply_point_id}/verify`
- `POST /v1/supply-points/{supply_point_id}/reject`
- `POST /v1/supply-points/{supply_point_id}/decommission`

Response `200 OK`:

```json
{ "status": "OK" }
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` (RBAC)
- `404 RESOURCE_NOT_FOUND`
- `409` (invalid transition)

---
