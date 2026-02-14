## Jila API Backend – API Contract (v1) — Extracted section (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

## 0. Global conventions

### 0.1 Base URL and versioning
- All endpoints are under: `/v1`
- JSON request/response bodies.
- All server-generated timestamps are ISO8601 **UTC** (e.g. `2025-01-01T00:00:00Z`) (see decision **D-011**).

### 0.1.1 Health endpoint
- `GET /v1/health` (public, no auth) returns:
  - `200 OK` with `{ "status": "ok", "service": "jila-api" }`
  - Purpose: deployment liveness probe.

### 0.2 Authentication
- Most endpoints require: `Authorization: Bearer <jwt>`
- JWT claims (minimum):
  - `sub` = `users.id`
  - `principal_id` = authenticated user’s principal id
- Access token TTL: **60 minutes** (see decision **D-005**).
- Refresh tokens are supported via `POST /v1/auth/refresh` (see decision **D-005**).

Public endpoints (read-only, no JWT required) are explicitly marked in this document. v1 public surface:
- `GET /v1/supply-points` (community discovery)
- `GET /v1/marketplace/reservoir-listings` (public seller listings discovery)

### 0.2.1 Account-first routing (canonical)

V1 uses an **account-first** URL shape for any endpoint that must be scoped to an account container.

Definitions:
- `actor_principal_id`: the authenticated caller’s principal id (`jwt.principal_id`).
- `org_principal_id`: the **organization principal id** the caller is acting within.

Rules:
- Clients must not send `owner_principal_id` or other “actor mode” fields in request bodies.
- `org_principal_id` refers to an organization principal id; the caller must have org access.
- The caller must have an active org membership grant (`OWNER|MANAGER|VIEWER` depending on the endpoint).
- Internal ops admins bypass org membership checks and may access any account-scoped endpoint; feature gates still apply.

Scope:
- Account-scoped requests are fully scoped by the URL path (`org_principal_id`) and the bearer token; clients do not supply
  additional “which org/account” routing context outside those two inputs.

### 0.3 Seller endpoint requirements (no actor mode)

There is no actor-mode header or stateful buyer/seller session concept.

Rules:
- Any authenticated principal can call `/v1/accounts/{org_principal_id}/orders/*` endpoints (subject to RBAC on the referenced resources).
- Any `/v1/accounts/{org_principal_id}/seller/*` endpoint additionally requires the caller to have an `ACTIVE seller_profiles` row.

### 0.4 Standard error shape

All errors return:

```json
{
  "error_code": "STRING_ENUM",
  "message": "Human readable message",
  "details": {}
}
```

Guidelines:
- RBAC denials: `403 Forbidden`
- Feature gating (plan): `403 Forbidden` with `error_code = "FEATURE_GATE"` and required `details.feature_key`. (See decision **D-003**.)
- Deterministic conflict/state errors: `409 Conflict`
- Validation errors: `422 Unprocessable Entity`

### 0.5 Endpoint flow diagrams (requests + conditions)

The detailed Mermaid flow diagrams are maintained in: `./99_flow_diagrams.md`

Rationale: keeps global conventions concise while preserving the helpful end-to-end visuals.

### 0.6 List filtering (query params)

List endpoints may accept optional **query parameters** for filtering. Conventions:
- Query params are optional; omitting filters preserves existing behavior.
- Filter values are interpreted as exact matches unless explicitly documented otherwise.
- When multiple filters are provided, they are combined with logical AND.
- IDs are UUID strings unless otherwise noted.

### 0.7 Aggregated statistics (`include_stats`)

Some list endpoints support optional aggregated statistics.

Convention:
- `include_stats` (boolean, optional, default `false`)

When `include_stats=true`:
- The response includes a `stats` object with aggregated counts/distributions.
- `stats` must be computed across the **entire filtered result set** (not just the returned page).
- `stats` must honor the same RBAC/visibility rules as the corresponding list items.

Decision: **D-064**.

### 0.8 PATCH semantics (preferred over action endpoints)

V1 prefers standard PATCH semantics over action-based endpoints for state updates.

Convention:
- Use `PATCH /resource/{id}` with field updates in request body.
- Avoid action-based endpoints like `POST /resource/{id}/verify` with `{ action: "VERIFY" }`.
- PATCH requests with no fields provided return current state (read-only no-op).

Examples:
- ✓ `PATCH /v1/admin/sellers/{id}` with `{ verification_status: "VERIFIED" }`
- ✗ `POST /v1/admin/sellers/{id}/verification` with `{ action: "VERIFY" }`

Rationale:
- Standard CRUD verbs reduce surface area and cognitive overhead.
- PATCH semantics are well-understood and align with REST conventions.
- Field-based updates are more explicit than action parameters.

Exceptions:
- State machine transitions with side effects may use dedicated POST endpoints (e.g., order accept/reject).
- Endpoints that trigger workflows beyond simple field updates may use action verbs.

### 0.9 Analytics conventions

Analytics endpoints use bounded windows and reproducibility metadata.

Convention:
- `window` query param: `24h|7d|30d` (default `24h`) unless explicitly documented otherwise.

Required analytics response fields:
- `snapshot_at`
- `window_start`, `window_end`
- `inputs_version`, `metric_version`
- `data_gap_hours`
- `confidence` (`HIGH|MEDIUM|LOW`)

Feature gates:
- View surfaces: `analytics.view`
- Export surfaces: `analytics.export`

---
