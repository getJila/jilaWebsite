# Aggregated statistics endpoints (v1) — DECIDED

Status: DECIDED (see Decision D-064)

## 1. Goal

Reduce portal/mobile UI complexity and prevent N+1 call patterns by providing **aggregated counts** (and small distributions) directly from the API.

This spec intentionally focuses on **bounded rollups** (counts and small enum distributions) and avoids time-series analytics.

## 2. Definitions

- **Aggregated stats**: counts/distributions over a filtered set of resources (e.g., alerts by severity) computed by the API.
- **Snapshot**: stats are computed against the database at request time and returned with a server timestamp (`snapshot_at`).
  - The snapshot is best-effort and not guaranteed to be fully transactional across multiple tables.

## 3. Cross-cutting contract rules

### 3.1 `include_stats`

Selected list endpoints add an optional query param:

- `include_stats` (boolean, optional, default `false`)

When `include_stats=true`, the response includes a `stats` object.

Rationale: makes additional aggregate work opt-in and keeps the baseline list fast.

### 3.2 Stats must match list filters

If a list endpoint supports filters (e.g., `org_id`, `status`, geo radius), the corresponding `stats` must:

- Use the **same filter semantics** as the list query
- Represent the **entire filtered set**, not the current page

### 3.3 RBAC must be honored

Stats must honor the same authorization constraints as the list items:

- Org membership requirements
- Site-scoped grants and per-object access grants

### 3.4 Response stability

- Adding `stats` (or other additive fields) is a non-breaking response change.
- No existing response fields are removed or renamed.

## 4. New endpoint: org dashboard rollup

### 4.1 `GET /v1/accounts/{org_principal_id}/dashboard-stats`

Purpose: Provide a single-call rollup for dashboard badges and summary panels.

Auth:
- Requires `Authorization: Bearer <jwt>`
- Caller must have effective visibility into the target org principal (and stats must honor site-scoped grants)

Response `200 OK`:

```json
{
  "org_id": "uuid",
  "snapshot_at": "2025-01-01T00:00:00Z",
  "reservoirs": {
    "total": 42,
    "by_level_state": { "FULL": 5, "NORMAL": 20, "LOW": 12, "CRITICAL": 5 },
    "by_connectivity_state": { "ONLINE": 35, "STALE": 5, "OFFLINE": 2 }
  },
  "devices": {
    "total": 38,
    "by_status": { "ONLINE": 30, "OFFLINE": 6, "MAINTENANCE": 2 },
    "battery_health": { "good_count": 25, "low_count": 10, "critical_count": 3 },
    "low_battery_count": 13
  },
  "alerts": {
    "unread_total": 15,
    "by_severity": { "CRITICAL": 3, "WARNING": 8, "INFO": 4 }
  },
  "sites": {
    "total": 12,
    "by_risk_level": { "CRITICAL": 1, "WARNING": 3, "STALE": 1, "GOOD": 7 }
  }
}
```

Notes:
- This endpoint is intentionally “stats-only” (no `items`).
- `snapshot_at` is server-generated UTC.
- Enum keys must match the canonical API enums.
- Device battery rollup shape is DECIDED in **D-065**:
  - `low_battery_count = battery_health.low_count + battery_health.critical_count`.

### 4.2 `GET /v1/accounts/{org_principal_id}/dashboard-snapshot`

Purpose: provide a one-call dashboard bootstrap payload that reduces frontend fan-out on first load.

Auth:
- Requires `Authorization: Bearer <jwt>`
- Caller must have effective org visibility (same rules as `dashboard-stats`)
- Requires `analytics.view`; if not entitled the request fails as a whole (`403 FEATURE_GATE`)

Serving model:
- Synchronous read-through in v1 (no precomputed cache layer)

Response `200 OK`:

```json
{
  "org_id": "uuid",
  "snapshot_at": "2026-02-14T12:00:00Z",
  "window_label": "24h",
  "dashboard_stats": { "...": "same shape as /dashboard-stats" },
  "org_analytics": { "...": "same shape as /accounts/{org_principal_id}/analytics" }
}
```

Notes:
- This endpoint is a fan-out reduction layer only; existing detailed endpoints stay canonical for drill-down.
- Frontend first-load pattern:
  - Call `GET /dashboard-snapshot?window=24h`
  - Use existing list/detail endpoints only after user drill-down actions.

## 5. Enriched list endpoints (opt-in stats)

### 5.1 `GET /v1/accounts/{account_id}/alerts`

Add query param:
- `include_stats` (optional, default false)

When `include_stats=true`, response adds:

```json
{
  "stats": {
    "unread_total": 23,
    "by_severity": { "CRITICAL": 5, "WARNING": 12, "INFO": 6 },
    "by_context_type": { "RESERVOIR": 15, "DEVICE": 5, "ORDER": 3 }
  }
}
```

### 5.2 `GET /v1/accounts/{account_id}/orders`

Add query param:
- `include_stats` (optional, default false)

When `include_stats=true`:

```json
{
  "stats": {
    "as_buyer": {
      "pending_count": 2,
      "in_progress_count": 1,
      "completed_count": 15
    },
    "as_seller": {
      "pending_count": 5,
      "accepted_count": 3,
      "delivered_count": 45,
      "disputed_count": 1
    }
  }
}
```

Notes:
- Stats should respect the `view` filter:
  - `view=buyer` returns `stats.as_buyer` only.
  - `view=seller` returns `stats.as_seller` only.
  - `view=all` returns both.

### 5.3 `GET /v1/accounts/{account_id}/reservoirs` (optional)

This endpoint is currently non-paginated; adding stats is still useful for UI simplicity, but does not reduce payload.

Proposed additive fields:

```json
{
  "stats": {
    "total": 42,
    "by_level_state": { "FULL": 5, "NORMAL": 20, "LOW": 12, "CRITICAL": 5 },
    "by_monitoring_mode": { "DEVICE": 30, "MANUAL": 12 },
    "by_connectivity_state": { "ONLINE": 35, "STALE": 5, "OFFLINE": 2 }
  }
}
```

### 5.4 `GET /v1/accounts/{account_id}/members`

Add `include_stats` (optional, default false).

When `include_stats=true`:

```json
{
  "stats": {
    "total_count": 25,
    "by_role": { "OWNER": 1, "MANAGER": 8, "VIEWER": 16 },
    "by_status": { "ACTIVE": 22, "PENDING_VERIFICATION": 2, "LOCKED": 1 }
  }
}
```

### 5.5 `GET /v1/accounts/{account_id}/invites`

Add `include_stats` (optional, default false).

When `include_stats=true`:

```json
{
  "stats": {
    "total_pending": 8,
    "expiring_within_24h": 2,
    "by_proposed_role": { "MANAGER": 5, "VIEWER": 3 }
  }
}
```

### 5.6 `GET /v1/accounts/{account_id}/devices`

This endpoint already returns `total_count`.

Add `include_stats` (optional, default false). When `include_stats=true`:

```json
{
  "stats": {
    "by_status": { "ONLINE": 30, "OFFLINE": 6, "MAINTENANCE": 2 },
    "battery_health": {
      "good_count": 25,
      "low_count": 10,
      "critical_count": 3
    },
    "firmware_versions": {
      "2.1.0": 20,
      "2.0.5": 12,
      "1.9.0": 6
    }
  }
}
```

Notes:
- `firmware_versions` is bounded (DECIDED, D-067): the map includes only the **top 20** firmware versions by count; other
  versions are omitted in v1.

### 5.7 `GET /v1/supply-points` (public)

Add `include_stats` (optional, default false). When `include_stats=true`:

```json
{
  "stats": {
    "total_in_radius": 15,
    "by_availability_status": { "AVAILABLE": 10, "LOW": 3, "CLOSED": 2 }
  }
}
```

Note:
- Keys must match the response enums for `availability_status`.

### 5.8 `GET /v1/marketplace/reservoir-listings` (public)

Add `include_stats` (optional, default false). When `include_stats=true`:

```json
{
  "stats": {
    "total_in_radius": 8,
    "price_range": {
      "min_estimated_total": 1200,
      "max_estimated_total": 3500,
      "currency": "AOA"
    }
  }
}
```

## 6. Out-of-scope (v1)

- Seller performance analytics (`GET /v1/accounts/{account_id}/seller/stats`) unless separately approved and budgeted.
- Historical reservoir trend stats embedded in `GET /v1/reservoirs/{reservoir_id}` (needs explicit data/retention decisions).

## 7. Next steps to ship

1) Flip D-064 to DECIDED (choose Option A / confirm endpoint list).
2) Update canonical API contract docs under `docs/architecture/api_contract/`.
3) Implement endpoints and add targeted tests for:
   - RBAC correctness
   - stats correctness under filters
   - regression checks for response shape
