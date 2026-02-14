## Jila API Backend – Project Structure (v0.1)

This document defines the **concrete repo + package structure** for the Jila API backend described in:
- `docs/architecture/jila_api_backend_architecture_v_0 (3).md`

It exists to prevent implementation drift by making the modular-monolith architecture **physically obvious** in the codebase.

---

## 1. Goals (structure-level)

- **Make module boundaries enforceable**: each domain module lives in its own package with minimal, explicit interfaces.
- **Keep cross-cutting primitives centralized**: `principals`, `access_grants`, `tokens`, `events` are treated as platform primitives (not re-modeled per module).
- **Support 3 runtime entrypoints** from one codebase:
  - **API server** (FastAPI HTTP)
  - **Worker** (background jobs: alerts, aggregations, async processors)
  - **Telemetry listener** (Azure Event Hubs consumer; typically hosted with the worker)
- **Stay extraction-ready**: module code can be moved into services later without rewriting the internal architecture.

---

## 2. Top-level repository layout

Recommended repo layout (this repo *is* the backend; do not add an extra `backend/` nesting layer):

```text
JilaAPI/
  docs/
    architecture/
      jila_api_backend_architecture_v_0 (3).md
      jila_api_backend_project_structure.md
      jila_api_backend_erd.md
      jila_value_proposition_review_notes_aligned.md
  infra/
    terraform/
      ...
  certs/
    ...
  README.md
  pyproject.toml
  app/
    __init__.py
    main.py
    settings.py
    dependencies/
    api/
      v1/
        router.py
    db/
      base.py
      session.py
      migrations/
    common/
      errors.py
      time.py
      id.py
      pagination.py
    modules/
      identity_access/
      core_water/
      marketplace/
      subscriptions/
      alerts_events/
      analytics/
      portal_stats/
      admin_portal/
    workers/
      worker_main.py
      jobs/
    telemetry/
      event_hubs_listener.py
  tests/
    ...
  scripts/
    ...
  Dockerfile
  atlas.hcl
```

Notes:
- **`app/` is the only import root** for application code.
- `infra/` stays focused on provisioning (Terraform) and does not contain runtime app logic.

---

## 3. Runtime entrypoints (what starts, where)

- **API server**
  - **Entrypoint**: `app/main.py`
  - Responsibilities:
    - FastAPI app initialization
    - API routing (`/v1`)
    - request-scoped dependencies (auth, DB session, user context)

- **Worker**
  - **Entrypoint**: `app/workers/worker_main.py`
  - Responsibilities:
    - running background processors (alerts, retention, analytics aggregations)
    - running scheduled jobs (if used) in a controlled loop
  - Operational note:
    - Outbox-driven consumers are **event-driven** via Postgres `LISTEN/NOTIFY` (per **D-027**) with a periodic fallback wake.
    - Time-based work (e.g., OTP retries) uses adaptive sleeps based on DB due times (per **D-012**).
    - Downstream impact: `LISTEN/NOTIFY` consumes **one additional steady DB connection** per worker process (separate from the SQLAlchemy pool).
    - Shutdown behavior:
      - The LISTEN loop wakes at most ~1s to observe shutdown (select timeout).
      - Time-based loops may still be sleeping; keep max sleep bounded via settings (see `app/settings.py` worker knobs).

- **Telemetry listener**
  - **Entrypoint**: `app/telemetry/event_hubs_listener.py`
  - Responsibilities:
    - consume Azure Event Hubs telemetry
    - resolve `hardware_id -> device_id -> reservoir_id`
    - write `reservoir_readings` + emit `events` (or diagnostic `DEVICE_TELEMETRY_DROPPED_UNATTACHED`)

Best practice for deployment:
- Host the **telemetry listener inside the worker container** (same codebase, separate process) unless volume requires separation (per **D-016**).

---

## 4. Layering model (how code is organized inside a module)

Each module follows the same internal layout so patterns are predictable:

```text
modules/<module_name>/
  __init__.py
  api/
    router.py
    schemas.py         # Pydantic request/response models
    deps.py            # module-specific dependencies (optional)
  domain/
    models.py          # domain entities/types (not ORM; pure domain)
    policies.py        # permission + business policy helpers
  db/
    orm.py             # SQLAlchemy models for module tables
    repo.py            # DB operations (queries + writes)
  service/
    service.py         # orchestration + business logic; calls repos; emits events
  events/
    types.py           # event type constants/enums for this module
    payloads.py        # stable event payload schemas
```

Rule of thumb:
- **API layer**: validation + authz + call service.
- **Service layer**: business rules + transaction boundaries + emits `events`.
- **Repo layer**: persistence only, no business branching.
- **Domain**: small, stable nouns and policy helpers (keeps the service readable).

---

## 5. Cross-cutting packages (shared platform primitives)

Some concepts must stay unified to satisfy the anti-drift guardrails:

- **SQLAlchemy ORM naming footgun (reserved `metadata`)**
  - Declarative models must NOT declare a Python attribute named `metadata` because SQLAlchemy reserves it (`Base.metadata`).
  - If a table includes a Postgres column named `metadata`, map it using a different Python attribute name:
    - Example pattern: `user_metadata = mapped_column("metadata", JSONB, ...)` or `metadata_ = mapped_column("metadata", JSONB, ...)`.
  - This preserves the canonical DB schema (`metadata` column name) while keeping ORM imports safe.

- **Settings**
  - `app/settings.py`
  - Uses a single configuration object (environment-driven).

- **Database**
  - `app/db/session.py`: session/engine factory
  - `app/db/migrations/`: Atlas-managed migrations (canonical per **D-001**; versioned and CI-gated)
  - **Atlas tooling**
    - Config: `atlas.hcl` (repo root)
    - After adding/editing SQL migrations, refresh checksums:
      - `atlas migrate hash --dir file://app/db/migrations`
    - Single-source guidance for agents: (TBD — create `.cursor/rules/` migration guide if needed)

- **Authorization**
  - `app/dependencies/` and/or `app/common/`
  - Central `authorize(user_ctx, action, resource)` logic lives outside individual modules so enforcement is consistent.

- **Events (transactional outbox)**
  - `app/modules/alerts_events/` owns the `events` table contract and event emission helpers used by all modules.
  - All modules should emit events via a shared emitter interface to keep payload structure stable.

- **Error model**
  - `app/common/errors.py`
  - Defines consistent machine-readable error codes (e.g. `INVALID_ORDER_STATE`, `PRICE_RULE_OVERLAP`, `FEATURE_GATE`).

---

## 6. Module-by-module mapping (architecture → folders)

This is the physical mapping of the logical components defined in the architecture document.

### 6.1 Identity & Access Module → `modules/identity_access/`

Owns:
- `users`, `organizations`, `principals`
- authentication flows
- `access_grants` (RBAC relationships)
- `tokens` (OTP, password reset, invites)

Exports:
- User context resolution (`principal_id`, grants, etc.)
- authorization helpers (or delegates to centralized `authorize(...)`)

### 6.2 Core Water Module → `modules/core_water/`

Owns:
- `sites`, `reservoirs`, `devices`, `reservoir_readings`
- manual readings ingestion
- reservoir location updates (via `PATCH /v1/reservoirs/{reservoir_id}`)

Emits:
- `RESERVOIR_CREATED`
- `RESERVOIR_LEVEL_READING`
- `RESERVOIR_LOCATION_UPDATED`

### 6.3 Marketplace Module → `modules/marketplace/`

Owns:
- `supply_points`
- `seller_profiles`
- `reservoir_price_rules`
- `orders`, `reviews`

Emits:
- `SUPPLY_POINT_STATUS_UPDATED`
- order lifecycle events (`ORDER_CREATED`, `ORDER_ACCEPTED`, `ORDER_REJECTED`, `ORDER_CANCELLED`, `ORDER_DELIVERED`, `ORDER_DISPUTED`)
- `REVIEW_SUBMITTED`

### 6.4 Subscription Module → `modules/subscriptions/`

Owns:
- `plans`, `subscriptions`
- `FeatureGate` resolution (read `plans.config`)

Exports:
- entitlement evaluation utilities consumed by API + worker

### 6.5 Alerts & Events Module → `modules/alerts_events/`

Owns:
- `events` (transactional outbox)
- `alerts`
- alert rule evaluation and delivery plumbing interfaces

Exports:
- event emission API (stable payload envelopes)
- alert generation pipeline (worker)

### 6.6 Analytics Module → `modules/analytics/`

Owns:
- query/services that compute:
  - per reservoir/site indicators
  - org/zone aggregates
  - export generation (CSV/PDF/HTML) when enabled

Implemented surfaces (post-v1):
- Outbox consumer (`analytics_consumer`) listening to `RESERVOIR_LEVEL_READING` for near-real-time updates.
- Typed analytics read models:
  - `device_location_points`, `mobile_stop_episodes`, `mobile_places`
  - `stationary_hourly_series`, `stationary_supply_events`
  - `reservoir_metrics_windows`, `site_metrics_windows`, `org_metrics_windows`, `zone_metrics_windows`
- API endpoints:
  - `/v1/reservoirs/{reservoir_id}/analytics`
  - `/v1/sites/{site_id}/analytics`
  - `/v1/accounts/{org_principal_id}/analytics`
  - `/v1/zones/{zone_id}/analytics`
  - `/v1/devices/{device_id}/mobile/stops`
  - `/v1/devices/{device_id}/mobile/places`
  - `/v1/analytics/exports`
  - `/v1/internal/diagnostics/analytics`

Implementation notes:
- Keep heavy analytics isolated so compute/storage can be extracted later without rewriting domain modules.
- Keep cross-module interactions at public surfaces and shared primitives (`events`, `access_grants`, `subscriptions.public`).

### 6.7 Portal Stats Module → `modules/portal_stats/` (read-only)

Status: DECIDED (D-068).

Purpose:
- Provide a small set of **read-only, cross-domain rollups** needed by portal/mobile dashboards without expanding the
  scope of existing domain modules.

Owns:
- No new tables in v1.

Implements:
- `GET /v1/accounts/{org_principal_id}/dashboard-stats` (cross-domain rollup; v1; `org_principal_id` is org principal id).

Rules (anti-drift, boundaries):
- Prefer raw SQL in the module’s own repo layer to avoid importing another module’s `.db.*` or `.service.*` internals.
- Keep queries bounded and index-backed (aligned with D-064).
- This module must not become a “misc blob”: only approved rollups live here; per-endpoint `include_stats` logic stays in
  the owning module of that endpoint.

---

## 7. Import boundaries (anti-drift / anti-tangle rules)

These rules are structural guardrails:

Enforcement note (per **D-015**):
- These boundaries are enforced in CI using an import-boundary checker so violations are caught mechanically, not by convention alone.

1. **Modules do not import each other’s ORM models directly.**
   - If cross-module data is required, fetch via:
     - a small service interface, or
     - a repo method that returns a **minimal projection** (IDs + fields needed), or
     - shared primitives (e.g., `access_grants`, `events`) by contract.

2. **`events` is the default cross-module integration mechanism** for “something that happened”.
   - Avoid per-module history tables unless necessary for frequent joins/filtering.

3. **Authorization is centralized.**
   - Modules provide resource loaders, but enforcement policy stays consistent.

4. **Transaction boundaries live in services.**
   - API handlers should not orchestrate multi-repo writes directly.

---

## 8. Testing structure

Recommended test layout:

```text
tests/
  unit/
    modules/
      identity_access/
      core_water/
      marketplace/
      subscriptions/
      alerts_events/
      analytics/
  integration/
    api/
    db/
    telemetry/
```

Principles:
- Unit tests: service/policy logic with repo fakes.
- Integration tests: real DB + migrations + HTTP layer where valuable.

---

## 9. Documentation rules for new code

When implementing new endpoints/services:
- Every new cross-cutting abstraction must be documented in this file (or explicitly rejected with rationale).
- Event types must be added once and referenced consistently (avoid duplicate enums per module).
