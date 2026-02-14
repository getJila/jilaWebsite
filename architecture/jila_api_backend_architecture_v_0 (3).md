# Jila API Backend – Architecture Document (v0.3 – hardened & anti-drift)

This document defines the concrete architecture for the Jila API backend that powers:

- The mobile app (consumers, sellers, field operators).
- The web portal (multi-site organizations, utilities).
- Device and telemetry ingestion (Jila hardware and future sensors).

It is scoped strictly to capabilities required by the core value proposition: reservoir monitoring, marketplace matching, and analytics around water intermittence and refills.

**Companion docs (canonical):**
- **Project structure (repo/package layout, module boundaries, entrypoints):** `docs/architecture/jila_api_backend_project_structure.md`
- **ERD (schema view):** `docs/architecture/jila_api_backend_erd.md`
- **Implementation plan (phased roadmap):** `docs/architecture/jila_api_backend_implementation_plan.md`
- **Data models (tables/enums/constraints):** `docs/architecture/jila_api_backend_data_models.md`
- **API contract (endpoints + request/response models):** `docs/architecture/jila_api_backend_api_contract_v1.md`
- **State + history best practices (latest + historical records):** `docs/architecture/jila_api_backend_state_and_history_patterns.md`
- **Device management (firmware, config, telemetry/cellular):** `docs/architecture/jila_api_backend_device_management.md`
- **Firestore mirroring (realtime read model + security rules):** `docs/architecture/jila_api_backend_firestore_mirroring.md`

---

## 1. Goals and Scope

1. Provide a single, well-defined API surface for:
   - Managing users, organizations, sites, reservoirs, and devices.
   - Recording reservoir levels (manual and device-based).
   - Running the water marketplace (buyers, sellers, orders, reviews).
   - Generating and exposing alerts and key analytics.
2. Keep the backend as a **modular monolith** (one deployable, multiple internal modules) for v1.
3. Avoid non-essential components (no separate billing engine, no advanced observability stack, no separate microservices) until they are directly required by usage.
4. Produce **“utility-grade enough” evidence** for organizations, funders, and future utility pilots by:
   - Storing raw readings and derived events in a way that supports stable metric definitions.
   - Enabling exportable summaries (CSV, PDF/HTML) per reservoir, site, and zone.
   - Making data gaps and inference assumptions explicit in the analytics layer.

Out of scope for this document:

- Payment provider integration details (only assume we can mark orders as paid/unpaid).
- Third-party data products for utilities (only core analytics structures are defined).
- Internal IT/admin tooling beyond minimal admin endpoints.

---

## 2. High-Level Architecture

### 2.1 Architectural Style

- **Type:** Modular monolith backend.
- **Framework:** FastAPI (Python) for HTTP APIs.
- **Protocols:**
  - HTTPS/JSON for apps and portal.
  - Device telemetry is transported over MQTT (device → IoT gateway/broker) and forwarded into an Azure Event Hubs namespace; backend telemetry listeners consume from Event Hubs (not directly from MQTT).
- **Primary datastore:** Relational database (PostgreSQL) with a time-series–friendly schema for telemetry.
- **Asynchronous processing:** Async processors in the worker process. Outbox-driven consumers use Postgres `LISTEN/NOTIFY` wakeups (with fallback) per **D-027**; time-based work (e.g., due OTP retries) uses in-process adaptive sleeps (see **D-002**, **D-012**).

### 2.2 Logical Components

Within a single FastAPI project, the following modules are defined:

1. **Identity & Access Module**
   - Users, organizations, authentication, authorization.
2. **Core Water Module**
   - Reservoirs, sites, devices, telemetry (reservoir level readings and device status).
3. **Marketplace Module**
   - SupplyPoints (discovery), seller reservoirs, orders, reviews.
4. **Subscription Module**
   - Plans (`monitor`, `protect`, `pro`), account entitlements, and feature gating.
5. **Alerts & Events Module**
   - Event catalog, alert rules, and delivery via app/SMS/email.
6. **Analytics Module**
   - Aggregated metrics for sites, organizations, and zones.

All modules share the same database but are isolated at code level (separate packages, schemas, and service layers) to simplify future extraction into services if needed.

Realtime note (Firestore mirror):
- Firestore is used only as a realtime **read model** for clients.
- Jila remains the canonical authentication system; we do not use Firebase as an identity provider for Jila users.
- The backend mints Firebase custom tokens carrying Jila claims so Firestore Security Rules can enforce access.

**Implementation note (canonical):** the concrete repo/package layout, module boundaries, and runtime entrypoints are defined in:
- `docs/architecture/jila_api_backend_project_structure.md`

### 2.3 Environments

- **Production** – live customers and devices.
- **Staging** – mirrors the production schema and configuration for testing firmware and app releases.

No additional environments are defined at this stage to limit operational complexity.

### 2.4 Hardened data model principles (anti-drift guardrails)

This backend is **greenfield**. The primary hardening goal is to prevent schema and policy drift by centralizing cross-cutting concepts into a small set of primitives that every module reuses.

#### 2.4.1 Critical “value questions” (force unambiguous flows)

Before adding any new table, enum, or “shadow model”, answer:

1. **Is this concept state, or is it a record of something that happened?**
   - If it’s “something that happened”, prefer emitting an `events` row (stable payload contract) over creating a new history table.

2. **Is this ownership/container, or access control?**
   - Ownership/container must be a single FK to an owning `principal` (avoid scattered `user_id` + `organization_id` pairs).
   - Access control/sharing must be expressed as an `access_grants` row (avoid per-module *-access tables).

3. **Is this a one-time proof (OTP/invite/reset), or a persistent relationship?**
   - One-time proof → `tokens`.
   - Persistent relationship → `access_grants`.

4. **Can this be derived from canonical state + events, or does it need to be stored for latency/cost?**
   - If stored, document the canonical source and invalidation rules explicitly (to avoid “two sources of truth” drift).

5. **Will we need to query/filter/join this frequently at scale?**
   - If yes, model it relationally.
   - If no, JSONB may be acceptable but must be explicitly documented as non-authoritative.

#### 2.4.2 Single-source-of-truth primitives (must be reused)

- **Identity / ownership container**: `users`, `organizations`, `principals`
- **Authorization & sharing**: `access_grants`
- **OTPs, password resets, invites**: `tokens`
- **Audit + async processing contract**: `events` (transactional outbox)

---

## 3. Identity, Tenancy, and Access Control

### 3.1 Core Concepts

- **User** – person interacting with the system (seller, field operator, HQ staff).
- **Organization** – entity representing a multi-site customer (telco, bank, NGO, etc.).
- **Site** – physical location (branch, tower, hospital, etc.) grouping reservoirs.
- **SupplyPoint** – where water can be procured (informational/discovery surface; may exist without storage).
- **Reservoir** – what stores water (physical/measurable; fixed or mobile; where devices/subscriptions attach).

### 3.2 Authentication

The API backend is responsible for all authentication flows.

#### 3.2.1 Credentials and Identifiers

- **Household / small-seller users**
  - Identifiers: **phone number and/or email** (both supported; `username` resolves to either).
  - Credential: password (stored as a strong hash such as Argon2 or bcrypt).
  - Verification priority: **phone-first** (SMS). Account becomes fully active when **phone is verified** (email may be verified later).

- **Organization users**
  - Identifiers: **email + phone** (both required).
  - Primary identifier (UX): **email address** (portal-centric).
  - Credential: password (stored as a strong hash).
  - Verification priority: **email-first**; in v1, org-context accounts become `ACTIVE` when **email is verified** and phone verification is deferred (see Decision **D-004**).

Implementation detail (canonical API contract):
- Login and password-reset endpoints accept a single `username` field (rather than separate phone/email fields).
- The backend resolves `username` against the user’s **verified** identifiers (phone and/or email), so a user can log in with whichever identifier they have validated.

Third-party authentication (design requirement):
- The backend must support external identity providers (e.g., Google OAuth/OIDC) without introducing a separate IdP requirement for all users.
- Canonical approach:
  - Keep `users` as the account record.
  - Add a provider identity table (e.g., `user_auth_identities`) keyed by `(provider, provider_subject)` to link external identities to `users`.
  - Issue the same Jila JWTs after successful external authentication.

#### 3.2.2 Tokens

- The backend issues **JWT access tokens** and **refresh tokens** directly (see decision **D-005**).
- Token contents:
  - `sub` (user_id).
  - `principal_id` (the authenticated user’s principal).
- Do **not** embed org roles/permissions in JWTs (they change); resolve effective access via `access_grants` at request time.
- No “actor mode” header/claim is used.
- Seller-only capability is inferred by endpoint:
  - `/v1/accounts/{account_id}/seller/*` endpoints require an `ACTIVE seller_profiles` row for the caller principal (in addition to RBAC).
    - `/v1/accounts/{account_id}/orders/*` endpoints may be called by buyers or sellers; authorization rules apply per order side.
- Tokens are signed with a backend-managed secret; there is no external IdP.

#### 3.2.3 Flows

- **Registration**
  - Household / non-org: `POST /v1/auth/register` with phone/email and password.
  - Organization users: `POST /v1/org-invites/accept` (invite acceptance) with required email+phone+password.
  - Duplicate identifier handling (best-practice, explicit):
    - If no `users` row exists for the identifier: create `users` in `PENDING_VERIFICATION`.
    - If a `users` row exists with `status = PENDING_VERIFICATION`: treat as **idempotent** and resend OTP (do not create a second user).
    - If a `users` row exists with `status = ACTIVE`: return `409 ACCOUNT_ALREADY_EXISTS` (client should direct user to Login or Password Reset).
    - If a `users` row exists with `status = LOCKED|DISABLED`: return `403 ACCOUNT_DISABLED` (client should direct to support/recovery flow).
  - OTP issuance:
    - Create a `tokens` row (`type = VERIFY_PHONE|VERIFY_EMAIL`) and send via SMS/email using AWS services.
    - When resending, revoke any prior unused OTP tokens for the same identifier + type (so only the most recent OTP is valid).
  - Abuse prevention:
    - Rate limit by identifier + device + IP (and apply escalating cooldowns) to prevent OTP spam and brute force.

- **Verification**
  - `POST /v1/auth/verify-identifier` and `POST /v1/auth/verify-identifier` with OTP.
  - On success:
    - Mark the OTP `tokens` row as used (`used_at`).
    - Mark the corresponding user identifier verified (`phone_verified_at` or `email_verified_at`).
- If activation criteria are satisfied (per decision D-004), move the `users` row to `ACTIVE`, ensure a `principals` row exists for the user (`type = USER`, unique `user_id`), and create the default org if needed.

- **Login**
  - `POST /v1/auth/login` with `username` and password.
  - On success, the backend issues JWT access + refresh tokens (refresh is used to maintain long-lived sessions).

- **Refresh** (v1)
  - `POST /v1/auth/refresh` rotates refresh token and returns a new access token (and new refresh token).

- **Logout** (v1)
  - `POST /v1/auth/logout` revokes the refresh session; access token expires naturally.

- **Password reset** (v1 minimal)
  - `POST /v1/auth/request-password-reset` – sends OTP via SMS/email.
  - `POST /v1/auth/reset-password` – verifies OTP and updates the password hash.

All OTPs and password reset tokens are stored in a unified `tokens` table with strict expiry and one-time use semantics.

### 3.3 Authorization Model

Authorization is enforced at three levels:

1. **Principal (ownership container) level**
   - Every user has exactly one `principal` (type `USER`).
   - Organizations have exactly one `principal` (type `ORGANIZATION`).
   - Entitlements (subscription plan) are evaluated at the owning `principal` level.

2. **Org/Reservoir scope**
   - Each request is evaluated against the resource’s `owner_principal_id` (and optional container hierarchy such as org → site).
   - Sharing is explicit:
     - Household reservoirs can be shared via `tokens` (invite) → `access_grants` (persisted access).
     - Organizations assign users to orgs/sites via `access_grants`.

3. **Role-based permissions**
   - All roles are enforced via `access_grants` (ORG/SITE/RESERVOIR/SUPPLY_POINT) plus direct ownership via `owner_principal_id`.
   - **Sites ARE an RBAC boundary in v1** (for enterprise least-privilege): a `SITE:<site_id>` grant confers access to the site itself and, by propagation, to reservoirs under that site.

Authorization checks are implemented as reusable decorators or middleware around endpoint handlers.

### 3.4 Protected Resources and Scopes

Key resource types that require authorization:

- `Organization`
- `Site`
- `Reservoir`
- `Device`
- `SupplyPoint`
- `Order` / (delivery confirmation is an Order capability in v1)
- `Analytics` / export datasets

Each resource has:

- An owner container: `owner_principal_id` (user or organization).
- Optional hierarchy:
  - `Organization` → `Sites` → `Reservoirs` → `Devices`

RBAC decisions always start by resolving:

1. The resource type.
2. Its owner container (`owner_principal_id`) and any container context (e.g., org principal; site container when applicable).
3. The user’s relationship to that container (direct ownership + `access_grants`).

### 3.5 Role Systems

We use **one** role/permission system to avoid drift: **Access Grants**.

All permissioning and sharing (org membership, reservoir sharing, and any optional operator governance) is expressed as rows in a single table: `access_grants`.

#### 3.5.1 Roles (small, stable)

- Unified roles (apply to both organizations and reservoirs): `OWNER` | `MANAGER` | `VIEWER`
- Reservoir roles: `OWNER` | `MANAGER` | `VIEWER`

Roles are labels applied via `access_grants.role`. Their meaning is defined only in the canonical permission matrix (not scattered across modules).

#### 3.5.2 Scoping model (no per-module scope tables)

Scoping is expressed by the **resource you grant access to**:

- Org membership: grant on `ORG:<org_id>` with role `OWNER|MANAGER|VIEWER`
- Site membership (enterprise least-privilege): grant on `SITE:<site_id>` with role `OWNER|MANAGER|VIEWER`
- Reservoir sharing: grant on `RESERVOIR:<reservoir_id>` with role `OWNER|MANAGER|VIEWER`
- SupplyPoint operator (optional): grant on `SUPPLY_POINT:<id>` with role `OWNER|MANAGER|VIEWER` if needed beyond `operator_principal_id`

### 3.6 Precedence Rules

When deciding whether a user can perform an action on a resource, precedence is:

1. **Direct access to the resource**
   - If there is an `access_grants` row on the specific resource (e.g. `RESERVOIR:<id>`), it applies directly.

2. **Site container access (when applicable)**
   - If the resource is attached to a site (`reservoirs.site_id`), `access_grants` on `SITE:<site_id>` apply to the site and propagate to resources under that site.

3. **Org container access**
   - If the resource is owned by an organization principal, `access_grants` on `ORG:<org_id>` apply.

4. **Direct ownership**
   - If the resource has `owner_principal_id == user_ctx.principal_id`, allow owner capabilities regardless of additional grants.

5. **Order-specific composite rules**
   - Buyer side: allow if `buyer_principal_id == user_ctx.principal_id` or the user has access to `target_reservoir_id` via grants (when provided).
   - Seller side: allow if the user is authorized on `seller_reservoir_id` via ownership (`reservoirs.owner_principal_id`) or an `access_grants` row on `RESERVOIR:<id>`.

These rules must be encoded explicitly in the authorization layer to avoid ambiguity.

### 3.7 Authorization Function Pattern

All API endpoints delegate access checks to a single authorization function:

```python
authorize(user_ctx, action="reservoir.view", resource=reservoir)
```

Where:

- `user_ctx` contains:
  - `principal_id` (resolved from the authenticated user)
  - list of `access_grants` for this principal (org/site/reservoir/supply point)
  - evaluated subscription features (separate from RBAC)
- `action` is a normalized permission string (examples: `org.manage_users`, `reservoir.view`, `reservoir.configure`, `reservoir.share`, `order.create`, `order.manage`, `analytics.export`).
- `resource` is the fully-resolved domain object (not just an ID).

The authorize function performs:

1. **Scope resolution**
   - Determine `owner_principal_id`, and any container scope (`org_id`, `site_id`) for the resource.

2. **Role aggregation**
   - Derive effective roles from `access_grants` on the relevant containers/resources (ORG, SITE, RESERVOIR, SUPPLY_POINT).

3. **Policy evaluation**
   - Map effective role + resource type + action to allow/deny via a small static permission matrix.

#### 3.7.1 Permission Matrix (canonical, small, stable)

Organization-level actions:

- `org.view` → `OWNER`, `MANAGER`, `VIEWER`
- `org.manage_users` → `OWNER`, `MANAGER`
- `org.manage_billing` → `OWNER`

Reservoir-level actions:

- `reservoir.view` → org `OWNER`/`MANAGER`/`VIEWER`, reservoir `OWNER`/`MANAGER`/`VIEWER`
- `reservoir.configure` → org `OWNER`/`MANAGER`, reservoir `OWNER`/`MANAGER`
- `reservoir.share` → org `OWNER`/`MANAGER`, reservoir `OWNER`
- `reservoir.order` → org `OWNER`/`MANAGER`, reservoir `OWNER`/`MANAGER`

Order-level actions:

- `order.view` → buyer side (buyer principal, or access to `target_reservoir_id` via grants) OR seller side (authorized on `seller_reservoir_id`)
- `order.manage` → seller side (authorized on `seller_reservoir_id`) for transitions like `ACCEPT`, `REJECT`, delivery confirmation, and exceptional override where permitted
 - `order.manage` → seller side (authorized on `seller_reservoir_id`) for transitions like `ACCEPT`, `REJECT`, and delivery confirmation

Analytics/export actions:

- `analytics.view` → `OWNER`, `MANAGER`, `VIEWER` within scope
- `analytics.export` → `OWNER`, `MANAGER` within scope (and additionally gated by subscription entitlements)

Policy rules should remain small and stable; new product features should map to existing actions where possible.

#### 3.7.2 Interaction with subscriptions (RBAC vs plan entitlements)

RBAC and subscriptions are deliberately separate layers:

- RBAC decides **if** the user can act on a resource.
- The subscription system decides **what** features are available.

Examples:

- A `VIEWER` with access to a reservoir cannot export analytics even if the plan allows exports, because they lack the `analytics.export` permission.
- A `MANAGER` with `analytics.export` permission still cannot export if their subscription features have `analytics.export_csv = false`.

Recommended flow:

1. `authorize(user_ctx, action, resource)` → if denied, return `403 Forbidden`.
2. If allowed, check `user_ctx.subscription_features` for feature-specific gates (history length, analytics level, export flags, alert channels, auto-refill flags, etc.).

This keeps RBAC stable even if plan definitions change over time.

#### 3.7.3 Response semantics (clients stay predictable)

- **RBAC denials**: always return `403 Forbidden`.
- **Subscription/plan denials** (feature gating):
  - Use the canonical error semantics and error shape defined in: `docs/architecture/jila_api_backend_api_contract_v1.md` (avoid duplicating the error contract here).

All endpoints must follow these semantics consistently.

---

## 4. Domain Model (Backend-Centric)

The backend’s domain model follows the core entities: `User`, `Organization`, `Site`, `SupplyPoint`, `Reservoir`, `Device`, `Order`, `Review`, `Event`, and `Subscription`.

Anti-drift rule (schema source of truth):
- **Do not** treat this section as a second schema definition.
- The canonical database schema (tables/enums/constraints) lives only in: `docs/architecture/jila_api_backend_data_models.md`
- This section describes **behavioral meaning and invariants** and may reference tables by name without restating full column lists.

### 4.1 Users and Organizations

#### 4.1.1 User (table: `users`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`users`).

Profile semantics (v1):
- `users` is the canonical record for authentication identifiers, account status, and security-relevant preferences.
- All ownership/access decisions do **not** use `users.id` directly; they use the user’s `principal_id`.
  - UX-facing “display identity” (e.g., display name and avatar) is modeled canonically in `principal_profiles` (see `docs/architecture/jila_api_backend_data_models.md`) and served via `GET /v1/me/profile`.

#### 4.1.2 Organization (table: `organizations`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`organizations`).

#### 4.1.3 Principal (table: `principals`)

One canonical “owner container / actor” identifier to avoid repeated `user_id` + `organization_id` patterns across tables.

Schema: see `docs/architecture/jila_api_backend_data_models.md` (`principals`).

#### 4.1.4 AccessGrant (table: `access_grants`)

Single RBAC/sharing table for *all* access relationships (org membership, reservoir sharing, supply point operators).

Schema: see `docs/architecture/jila_api_backend_data_models.md` (`access_grants`).

#### 4.1.5 Token (table: `tokens`)

Unified OTP + invite + password reset table (one-time/short-lived secrets).

Schema: see `docs/architecture/jila_api_backend_data_models.md` (`tokens`).

Invite acceptance binding (anti-theft, v1):

- If an invite token has `target_identifier` set:
  - For flows where the caller is already authenticated: acceptance must require an authenticated user whose **verified** phone/email matches `target_identifier`.
  - For org user onboarding (public invite acceptance): acceptance must require the provided `email` to match `target_identifier`, and the user must verify that email before the account becomes `ACTIVE`.

---

### 4.2 Reservoirs and Sites

#### 4.2.1 Site (table: `sites`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`sites`).

#### 4.2.2 Reservoir (table: `reservoirs`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`reservoirs`).

Notes:

- Ownership is always expressed via `owner_principal_id` (prevents drift and simplifies authorization).
- Metering/levels come from manual input or device readings, never from `SupplyPoint`.
- Location signals (v1):
  - `location` is the single canonical location signal, updated via `PATCH /v1/reservoirs/{reservoir_id}`.
- Marketplace visibility rule (v1):
  - A reservoir can be shown as a public seller listing only when:
    1) its owner has an `ACTIVE seller_profiles` row
    2) it has at least one `reservoir_price_rules` row
    3) it has a discoverable `location` (not stale; see D-006)
    4) `seller_availability_status = AVAILABLE`

#### 4.2.3 Reservoir sharing and delegated access

Reservoir sharing is expressed as `access_grants` rows on `RESERVOIR:<reservoir_id>`.

---

### 4.3 Devices and Telemetry

#### 4.3.1 Device (table: `devices`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`devices`).

Invariants (v1):
- Device↔reservoir pairing is 1:1 and must be enforced deterministically (detach-first; no silent reassignment).

#### 4.3.2 ReservoirReading (table: `reservoir_readings`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`reservoir_readings`).

---

### 4.4 SupplyPoints (Discovery) and Reservoir-based Selling

#### 4.4.1 SupplyPoint (table: `supply_points`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`supply_points`).

#### 4.4.2 ReservoirPriceRule (table: `reservoir_price_rules`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`reservoir_price_rules`).

Constraints / invariants (anti-ambiguity; enforced server-side even if UI fails):

- For a given (`reservoir_id`, `currency`), price rules must be **non-overlapping** across the applicable volume ranges.
- If a create/update would create an overlap, the API must reject it (e.g. `409 PRICE_RULE_OVERLAP`).
- If a buyer order would match **zero** rules or **more than one** rule, order creation must fail deterministically (e.g. `422 NO_PRICE_RULE_MATCH` or `409 PRICE_RULE_OVERLAP`).

Implementation note (PostgreSQL):

- Prefer a DB-level exclusion constraint on a computed numeric range (for example `numrange(min_volume_liters, max_volume_liters, '[]')`) scoped by `reservoir_id` and `currency`, to make overlaps impossible even under concurrency.

#### 4.4.3 SellerProfile (table: `seller_profiles`)

Defines whether a principal can operate in “seller mode” and expose reservoirs as public listings.

Schema: see `docs/architecture/jila_api_backend_data_models.md` (`seller_profiles`).

Notes:

- A principal is a seller if and only if it has an `ACTIVE` `seller_profiles` row.
- Seller-set prices come from `reservoir_price_rules` on reservoirs owned by that principal.

#### 4.4.4 SupplyPoint status history (no dedicated table in v1)

To avoid drift, we do **not** add a separate `supply_point_status_updates` history table at v1.

- Every status update emits an `events` row (e.g. `SUPPLY_POINT_STATUS_UPDATED`) with a stable payload.
- `supply_points.operational_status*` and `supply_points.availability_status*` are the cached current state for fast queries.
- The API enforces rate limiting per `supply_point_id` and (when applicable) the acting principal.

Conflict resolution (cached current state):

- Evidence priority: `SENSOR_DERIVED` > `VERIFIED` > `REPORTED`.
- Availability conflict resolution uses evidence priority:
  - A new update replaces `supply_points.availability_status*` if:
    - its `availability_evidence_type` has higher priority than the currently stored evidence, OR
    - it has the same evidence priority and a newer `availability_updated_at`.
  - Lower-evidence availability updates must not overwrite higher-evidence cached availability (they are still recorded in `events`).

- Operational status is treated as a separate, explicit field:
  - v1 default: only operator/admin updates may change `operational_status` (still recorded in `events`).

---

### 4.5 Orders and Reviews

#### 4.5.1 Order (table: `orders`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`orders`).

Delivery confirmation (buyer + seller acknowledgement; no separate Delivery resource in v1):

- `buyer_confirmed_delivery_at` (timestamp, nullable)
- `seller_confirmed_delivery_at` (timestamp, nullable)
- `buyer_confirmed_volume_liters` (numeric, nullable)
- `seller_confirmed_volume_liters` (numeric, nullable)
- `buyer_delivery_note` (text, nullable)
- `seller_delivery_note` (text, nullable)
- `delivered_at` (timestamp, nullable; set when delivery is considered complete)

Rule:

- `status` transitions to `DELIVERED` **only** when both buyer and seller confirmations are present.
- Pricing snapshot rule (anti-dispute):
  - On `ORDER_CREATED`, the backend computes and stores a **price snapshot** in `orders.price_quote_total` + `orders.currency`.
  - This snapshot is the single source of truth for the order and does **not** change even if `reservoir_price_rules` change later.

Strict transitions (anti-race; v1):

- The backend must enforce an explicit state machine; invalid transitions return `409 INVALID_ORDER_STATE`.

Order state machine (v1, strict + retry-safe):

| From status | Action (endpoint) | Actor | Preconditions | Writes | To status | Emits |
|---|---|---|---|---|---|---|
| (none) | `POST /v1/accounts/{account_id}/orders` | buyer | `seller_reservoir_id` required; buyer authorized; seller listing eligible; exactly one price rule matches | create `orders` row | `CREATED` | `ORDER_CREATED` |
| `CREATED` | `POST /v1/accounts/{account_id}/orders/{order_id}/accept` | seller | seller authorized on `seller_reservoir_id` | set `accepted_at` | `ACCEPTED` | `ORDER_ACCEPTED` |
| `CREATED` | `POST /v1/accounts/{account_id}/orders/{order_id}/reject` | seller | seller authorized on `seller_reservoir_id` |  | `REJECTED` | `ORDER_REJECTED` |
| `CREATED` | `POST /v1/accounts/{account_id}/orders/{order_id}/cancel` | buyer | `buyer_principal_id == caller.principal_id` | set `cancelled_at` | `CANCELLED` | `ORDER_CANCELLED` |
| `ACCEPTED` | `POST /v1/accounts/{account_id}/orders/{order_id}/confirm-delivery` (seller) | seller | seller authorized; seller confirmation not yet present | set `seller_confirmed_*` fields | `ACCEPTED` (until both) | (no status change) |
| `ACCEPTED` | `POST /v1/accounts/{account_id}/orders/{order_id}/confirm-delivery` (buyer) | buyer | buyer authorized; buyer confirmation not yet present | set `buyer_confirmed_*` fields | `ACCEPTED` (until both) | (no status change) |
| `ACCEPTED` | (internal) | system | both confirmations present | set `delivered_at` | `DELIVERED` | `ORDER_DELIVERED` |
| `ACCEPTED` | `POST /v1/accounts/{account_id}/orders/{order_id}/dispute` | buyer | buyer authorized |  | `DISPUTED` | `ORDER_DISPUTED` |
| `DELIVERED` | `POST /v1/accounts/{account_id}/orders/{order_id}/dispute` | buyer | buyer authorized |  | `DISPUTED` | `ORDER_DISPUTED` |
| `DELIVERED` | `POST /v1/accounts/{account_id}/orders/{order_id}/reviews` | buyer | buyer authorized; at most one review per order | create `reviews` row | `DELIVERED` | `REVIEW_SUBMITTED` |

Idempotency and concurrency rules (v1):

- Endpoints must be safe under client retries.
- If an action is re-submitted and the order is already in the *resulting* state, return `200` with the current order (idempotent no-op).
- If an action is submitted but the order is in a different state (a conflicting transition already happened), return `409 INVALID_ORDER_STATE`.
- `confirm-delivery` is **first-write-wins** per party:
  - If the same party re-submits identical confirmation payload, return `200` (no-op).
  - If the same party tries to change their confirmation payload after submitting, return `409 DELIVERY_CONFIRMATION_ALREADY_SET`.
- To prevent races, implement transitions using conditional updates (for example: `UPDATE orders SET ... WHERE id = :id AND status = :expected_status`); if 0 rows updated, treat as `409 INVALID_ORDER_STATE`.

#### 4.5.2 Review (table: `reviews`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`reviews`).

---

### 4.6 Events and Alerts

#### 4.6.1 Event (table: `events`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`events`, `event_type`, `event_subject_type`).

#### 4.6.2 Alert (table: `alerts`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`alerts`).

---

#### 4.6.3 Alert Intents (event → intended user action)

The “intent” is part of the contract: for every **alert-worthy** `events.type`, there is a defined intended user action (by audience). If an event type is **informational only** (not alert-worthy), it has no intent.

Alert-worthy event types and intents (1:1 list):

- `LOW_LEVEL_ALERT`
  - Household: Tap to order water now, or plan a refill.
  - Enterprise operator: Review at-risk reservoirs and plan refills.

- `EMPTY_RESERVOIR_ALERT`
  - Household: You are out of water. Order a refill now (or switch to backup source).
  - Enterprise operator: Escalate to critical list; ensure site has contingency supply.

- `SUPPLY_ON`
  - Household: Utility is on; fill now if possible.
  - Enterprise operator: Opportunity window; schedule refills while network is available.

- `SUPPLY_OFF`
  - Household: Utility appears off; conserve remaining water.
  - Enterprise operator: Review outage windows and adjust operations (e.g. tanker routing).

- `REFILL_DETECTED`
  - Household: Informational; your reservoir was refilled.
  - Enterprise operator: Confirm delivery effectiveness; review time-to-empty trend.

- `LEAK_SUSPECTED`
  - Household: Check for leaks; consider contacting a plumber.
  - Enterprise operator: Flag for maintenance team; mark as potential loss point.

- `DEVICE_OFFLINE`
  - Household: Device not reporting; check power/signal or contact support.
  - Enterprise operator: Add device to maintenance queue; verify site reachability.

- `DEVICE_ONLINE`
  - Household / Enterprise: Informational; monitoring has resumed.

- `DEVICE_BATTERY_LOW`
  - Household / Enterprise: Plan maintenance visit; device may stop reporting soon.

- `DEVICE_BATTERY_CRITICAL`
  - Household / Enterprise: Urgent maintenance; device may stop reporting at any time.

- `FIRMWARE_UPDATE_AVAILABLE` (optional)
  - Household / Enterprise: Schedule update (or allow auto-update) to maintain reliability.

- `FIRMWARE_UPDATE_APPLIED` (optional)
  - Household / Enterprise: Informational; update applied.

- `ORDER_CREATED`
  - Seller: Review new order and accept or reject.

- `ORDER_ACCEPTED`
  - Buyer: Track incoming delivery and prepare for arrival.

- `ORDER_REJECTED`
  - Buyer: Choose an alternative seller or adjust order parameters.

- `ORDER_CANCELLED`
  - Buyer/Seller: Update expectations; this delivery will not happen.

- `ORDER_DELIVERED`
  - Buyer: Confirm delivery and optionally leave a review.

- `ORDER_DISPUTED`
  - Buyer/Seller: Resolve dispute via support/internal workflow.

- `REVIEW_SUBMITTED`
  - Seller: Informational; a buyer left a review.

Subscription and sharing events may optionally generate notifications (typically email/app) but are not required to be alert-worthy in v1.

#### 4.6.4 Emission Rules (Implementation Guideline)

For each domain state change:

- Always write the domain row first (for example, `reservoir_readings`, `orders`, `subscriptions`).
- Then emit exactly one `events` row with:
  - `type` from the inline `events.type` enum above.
  - `subject_type` and `subject_id` as defined per event family.
  - `data` containing a stable JSON structure (including version and key IDs).

For alert-worthy events:

- The Alerts module decides, per plan and per user, whether to create `alerts` rows and on which channels.
- Mobile and portal clients read alerts and may use these intents as baseline copy / calls-to-action.

---

### 4.7 Subscriptions and Plans

#### 4.7.1 Subscription (table: `subscriptions`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`subscriptions`).

#### 4.7.2 Plan (table: `plans`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`plans`).

At runtime, entitlement checks use `plans.config` rather than hard-coded plan logic.

---

### 4.8 Zones and Aggregation Tags

To support later zone-level evidence without introducing a heavy GIS layer in v1:

#### 4.8.1 Zone (table: `zones`)
Schema: see `docs/architecture/jila_api_backend_data_models.md` (`zones`).

`sites.zone_id` and `supply_points.zone_id` are nullable FKs → `zones.id`.

---

## 5. API Surface (Modules and Key Endpoints)

All endpoints are versioned under `/v1`.

### 5.1 Identity, Auth, and Accounts

Authentication endpoints:

- `POST /v1/auth/register` – register a user and create the default org container.
- `POST /v1/auth/verify-identifier` and `POST /v1/auth/verify-identifier` – verify OTP for email/phone.
- `POST /v1/auth/login` – obtain JWT access + refresh tokens (see D-005).
- `POST /v1/auth/refresh` – rotate refresh token and mint a new access token (see D-005).
- `POST /v1/auth/logout` – revoke refresh session (see D-005).
- `POST /v1/auth/request-password-reset` – trigger OTP for password reset.
- `POST /v1/auth/reset-password` – reset password using OTP.

Identity/account endpoints:

- `GET /v1/me` – return current user profile and effective subscription.
- `GET /v1/accounts/{account_id}/reservoirs` – list reservoirs the caller can access.
- `GET /v1/accounts/{account_id}/orders` – list orders visible to the account principal.

Organization management (portal only, restricted roles):

- `POST /v1/accounts` – create organization (self-serve onboarding after verification; may be restricted by allowlist/policy in production).
- `GET /v1/accounts/{account_id}` – organization details.
- `POST /v1/accounts/{account_id}/sites` – create site.
- `GET /v1/accounts/{account_id}/sites` – list sites.
- `POST /v1/accounts/{account_id}/members/invite` – create an `INVITE` token for the user (email) and proposed grants (role + optional site scope); acceptance materializes `access_grants`.
- `POST /v1/org-invites/accept` – accept org invite (public), onboard/link user, and trigger required identifier verification (email-first; requires both email+phone).

### 5.2 Reservoirs, Sites, Devices

Reservoirs:

- `POST /v1/accounts/{account_id}/reservoirs` – create reservoir (org-owned; assigns site and owner).
- `GET /v1/reservoirs/{reservoir_id}` – reservoir details plus latest reading.
- `PATCH /v1/reservoirs/{reservoir_id}` – update capacity, safety margin, monitoring/location settings, and other attributes.
- `GET /v1/reservoirs/{reservoir_id}/readings` – paginated time series (with plan-based history limit).
- `PATCH /v1/reservoirs/{reservoir_id}` – update reservoir attributes including `location` (emits `RESERVOIR_LOCATION_UPDATED`).

Manual mode readings:

- `POST /v1/reservoirs/{reservoir_id}/manual-reading` – submit manual level (0–100%) and optional refill note.

Devices (internal/admin + pairing flow):

- `POST /v1/accounts/{account_id}/devices/register` – register device with metadata.
- `POST /v1/accounts/{account_id}/devices/attach` – attach device to reservoir by serial.
- `POST /v1/accounts/{account_id}/devices/{device_id}/detach` – detach device from reservoir.

Pairing rule (v1, 1:1):

- A device may be attached to at most one reservoir, and a reservoir may have at most one device.
- If an attach is attempted but the device is already attached to a different reservoir (or the reservoir already has a different device), return `409 DEVICE_ALREADY_PAIRED` and require an explicit detach first.

Telemetry ingestion (Event Hubs listener):

- A telemetry listener (running in the worker process) consumes messages from an Azure Event Hubs consumer group.
- Messages arrive as CloudEvents v1.0 (see `jila_api_backend_device_management.md` for the canonical protocol mapping):
  - `type = MQTT.EventPublished`
  - `subject = devices/{device_id}/telemetry` (topic string; canonical device identity)
  - `data_base64` (base64 of MQTT publish payload; UTF-8 JSON)
- The listener resolves `device_id` from the topic and checks whether the device is attached:
  - If the device is not registered, or the device is registered but currently unattached (`devices.reservoir_id is null`), the listener **discards** the telemetry (no `device_telemetry_messages` row and no `reservoir_readings` row) and emits `DEVICE_TELEMETRY_DROPPED_UNATTACHED` for audit/observability.
  - Otherwise it stores raw telemetry (`device_telemetry_messages`, deduped on `(mqtt_client_id, seq)`), creates a `reservoir_readings` row, and emits a `RESERVOIR_LEVEL_READING` event.

### 5.3 Marketplace: SupplyPoints, Seller Listings, Orders

SupplyPoints (discovery surface):

- `GET /v1/supply-points` – search by location and radius; supports filters:
  - `kind`
  - `status`
  - `within_radius_km`

Seller mode + listings (reservoir-based):

- `POST /v1/accounts/{account_id}/seller-profile` – create/activate seller profile for the current principal.
- `PATCH /v1/accounts/{account_id}/seller-profile` – update seller profile status/metadata.
- `GET /v1/accounts/{account_id}/seller/reservoirs` – list reservoirs owned by the principal (seller-mode view).
- `PATCH /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}` – set `seller_availability_status` and listing metadata (location is never manually set; it is device/app-derived).
- `POST /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules` – add/update `reservoir_price_rules`.
- `GET /v1/marketplace/reservoir-listings` – public search of seller reservoir listings (filters by geo + volume + availability).

Orders:

- `POST /v1/accounts/{account_id}/orders`
  - Body includes:
    - `target_reservoir_id` (optional).
    - `requested_fill_mode` (enum: `FILL_TO_FULL` | `VOLUME_LITERS`).
    - `seller_reservoir_id` (required in v1; buyer must select a seller listing).
  - `requested_volume_liters` handling:
    - For `FILL_TO_FULL`, backend derives liters from the target reservoir’s latest `level_pct` and capacity.
    - For `VOLUME_LITERS`, client sends `requested_volume_liters` directly (including any UI-only helpers like
      “days of autonomy”, which must be converted to liters client-side).
    - Consumption-model inputs (e.g., household size) are modeled per-site (not per-user) via
      `site_consumption_profiles` keyed by `sites.id` to support household and multi-site org workflows.
  - Resolves price using the seller’s `reservoir_price_rules`.

- `GET /v1/accounts/{account_id}/orders/{order_id}` – order details.
- `POST /v1/accounts/{account_id}/orders/{order_id}/accept|reject|cancel` – explicit order state transitions.
- Seller must use `reject` rather than `cancel` to preserve audit semantics (buyer vs seller initiated).
- `POST /v1/accounts/{account_id}/orders/{order_id}/confirm-delivery` – buyer or seller submits their delivery confirmation (client-asserted
  timestamp + volume + optional note). The server also records its own authoritative timestamp. Identical retries are
  treated as a no-op and return `200`.
- `POST /v1/accounts/{account_id}/orders/{order_id}/dispute` – buyer disputes the order (allowed when `status = ACCEPTED` or `DELIVERED`).

Reviews:

- `POST /v1/accounts/{account_id}/orders/{order_id}/reviews` – buyer submits review after delivery.

### 5.4 Subscriptions and Entitlements

- `GET /v1/accounts/{account_id}/subscription` – current plan for an account.
- `PATCH /v1/accounts/{account_id}/subscription` – change plan selection for an account.

The billing action (charging money) is external; this API updates the `subscriptions` table based on webhooks or admin calls.

Entitlement checks are implemented via a utility that answers:

- Is alert sending enabled?
- Which channels are allowed (APP/SMS/EMAIL)?
- How many days of history can be queried?
- Is auto-refill enabled for this reservoir or account?

### 5.5 Alerts and Events

Alerts API (for app/portal):

- `GET /v1/accounts/{account_id}/alerts` – list alerts for the current user.
- `POST /v1/accounts/{account_id}/alerts/{alert_id}/mark-read` – mark as read.

Background worker responsibilities:

- Generate alerts based on rules and subscription entitlements.
- Deliver SMS/email via external providers.

### 5.6 Analytics and Reporting

For v1, analytics is limited to directly supporting Jila’s value proposition and preparing for Phase B evidence packs:

- **Per reservoir/site:**
  - Consumption estimates over time.
  - Refill frequency and derived `REFILL_DETECTED` events.
  - Intermittence indicators (time below threshold, outage periods inferred, with confidence flags).

- **Per organization/zone:**
  - Number of reservoirs at risk in the next 24–48 hours.
  - Aggregate intermittence index per region/zone.
  - Basic tanker reliance proxies (delivered volume vs. network-only periods where inferable).

Derived events (stored in `events.data`) may include confidence metadata.

#### 5.6.1 Event Payload Schemas (JSON)
Canonical derived-event payload envelope and versioning rules are defined in:
- `docs/architecture/jila_api_backend_state_and_history_patterns.md`

---

## 6. Key Functional Flows

This section describes the main user and system flows at a product level. Technical sequence diagrams can be derived from these.

### 6.1 Onboarding Ladder

1. **App install (no account)**

   - User opens the app without registering.
   - Available actions (read-only):
     - View community `SupplyPoints` on a map (served by the **public HTTP API**; Firestore is auth-only).
     - View high-level information about availability (from `supply_points.availability_status*`).
     - View seller-set prices **only when available from public seller `Reservoir` listings** (derived from `reservoir_price_rules`).
   - No personalized reservoirs, alerts, or order placement.

   Pricing note (important):
   - `SupplyPoints` are not monetized and do not carry price rules.
   - Pricing exists only for sellers: a user/org becomes a seller by creating a Seller Profile and listing at least one `Reservoir` publicly for sale (see Marketplace module), backed by `reservoir_price_rules`.
   - A reservoir does **not** need to be associated to a `SupplyPoint` for v1.
   - A reservoir is only visible as a public listing when the seller toggles it to `seller_availability_status = AVAILABLE`.

2. **Account creation**

- User registers (phone/email; verification follows D-004).
   - Verification via OTP (SMS/email).
   - Minimal profile is created (`users`) and a canonical actor container is created (`principals`).
   - Organization users (self-serve path, v1):
     - After verification, the creator may create an org via `POST /v1/accounts`.
     - The backend creates the org `principals` row and an initial `access_grants` row granting the creator `OWNER` on `ORG:<org_id>`.
- For new users, create the default org and its default `sites` row (so reservoirs can consistently attach without special-casing).
   - New capabilities:
     - Create `Reservoirs` (manual mode) and submit manual readings (`reservoir_readings`).
     - See nearby public seller `Reservoir` listings (if location permission granted).
     - Place orders for manual reservoirs using capacity + `safety_margin_pct` logic.

3. **Reservoir creation (manual mode)**

   - Flow:
     - User provides reservoir label/name, capacity, mobility, and location (optional).
     - Ownership + site binding (anti-ambiguity rule):
       - The API does **not** accept `owner_principal_id` from the client.
       - Household: server uses the user’s single default `sites` row and sets `reservoirs.site_id` to that site; `reservoirs.owner_principal_id` is derived from `sites.owner_principal_id`.
       - Organization: client provides a `site_id`; server loads `sites.owner_principal_id` and derives `reservoirs.owner_principal_id` from it (authorization is checked against that org principal via `access_grants`).
    - System creates `reservoirs` (defaults: `monitoring_mode = MANUAL`) and emits `RESERVOIR_CREATED`.
   - Capabilities:
     - User can submit manual level readings.
     - System computes basic analytics (approximate consumption trend, refill intervals) within plan limits.

4. **Device upsell and connection**

   - Triggers (examples):
     - N manual readings recorded.
     - First low/empty condition detected.
   - Flow:
     - App shows device value proposition (reliable alerts, better estimation, automation readiness).
     - User scans device QR or enters hardware ID.
     - User selects an existing reservoir or creates a new one and links the device.
     - Backend registers/attaches the device and starts ingesting telemetry.
   - Result:
     - Reservoir displays near real-time level and device status.
     - User can enable more accurate order calculations (fill-to-full, X days autonomy) depending on plan.

5. **Marketplace use**

   - For manual reservoirs:
     - User selects a target reservoir.
     - System estimates required volume using reservoir capacity and `safety_margin_pct`.
     - User selects a public seller reservoir listing and places an order.

   - For device-connected reservoirs:
     - User selects a mode:
       - Fill to full.
       - Add a specific volume.
       - Add enough water for X days (based on recent consumption).
     - System calculates required volume from latest `reservoir_readings`.

6. **Delivery confirmation, review, and repeat**

   - Orders progress through lifecycle.
   - Delivery is confirmed by **both buyer and seller** via separate confirmations.
   - After the order reaches `DELIVERED`, app prompts buyer review.
   - Reviews affect seller rankings and recommendations.

---

### 6.2 Seller Flows

Seller flows are implemented via **seller profiles + reservoir-based listings**.

Core tables:

- `seller_profiles` (enables seller mode for a principal)
- `reservoirs` (the asset being listed; fixed or mobile)
- `reservoir_price_rules` (seller-set pricing)

#### 6.2.1 Become a seller (enable seller mode)

- User/org creates a seller profile:
  - System creates/updates `seller_profiles` with `status = ACTIVE`.
- Seller accesses `/v1/accounts/{account_id}/seller/*` endpoints when they have an `ACTIVE seller_profiles` row (plus RBAC).

#### 6.2.2 Create/manage listings (reservoir-based)

- Seller chooses one of their reservoirs (owned via `reservoirs.owner_principal_id`) and configures listing:
  - Set seller availability toggle: `reservoirs.seller_availability_status = AVAILABLE|UNAVAILABLE`
  - Ensure listing has at least one `reservoir_price_rules` row
  - Ensure listing is locatable (non-null `location` within staleness window)
- Public listing eligibility is the 4-condition rule defined in the Reservoir notes (seller profile + price rules + location + availability toggle).

#### 6.2.3 Mobile sellers (truck reservoir)

- Modeled as `reservoirs.mobility = MOBILE`, with `location` updated by device/app flows.
- Public listing visibility still requires explicit `seller_availability_status = AVAILABLE`.

---

### 6.3 Order and Negotiation Flows

#### 6.3.1 Instant Order Flow (v1)

- Buyer selects a public seller reservoir listing and sets volume/fill mode.
- Backend creates `orders` with `status = CREATED`.
- Seller can:
  - Accept → `status = ACCEPTED`.
  - Reject → `status = REJECTED`.
- Buyer may cancel **only while `status = CREATED`** → `status = CANCELLED`.
- Delivery completion:
  - Seller submits delivery confirmation (`seller_confirmed_delivery_at`, optional volume/note).
  - Buyer submits delivery confirmation (`buyer_confirmed_delivery_at`, optional volume/note).
  - When both are present, backend sets `delivered_at`, transitions `status = DELIVERED`, and emits `ORDER_DELIVERED`.
- If buyer disputes → `status = DISPUTED`.

#### 6.3.2 Request Offers Flow (future)

Not implemented in v1. When introduced, it requires:

- An `offers` table (and potentially an `offer_requests` table).
- Broadcast routing to candidate sellers.
- Offer expiry and selection logic.

The v1 API should avoid hard dependencies on offers; new capabilities should map onto existing actions where possible.

---

### 6.4 Enterprise / Multi-Site Flows (for example, Unitel)

#### 6.4.1 Organization Setup

- Self-serve onboarding (v1) is supported:
- Org creation happens via `POST /v1/accounts`; registration always creates the default org.
    - Organization accounts require **both** phone + email and become `ACTIVE` when **email** is verified; phone verification is deferred (see D-004).
  - The creator calls `POST /v1/accounts` to create an `Organization`.
  - The backend creates the org `principals` row and grants the creator `OWNER` on `ORG:<org_id>` via `access_grants`.
  - The creator then creates sites via `POST /v1/accounts/{account_id}/sites` and invites other users as needed.
- Enterprise subscription assignment is handled separately via `subscriptions` after the org exists.

#### 6.4.2 Sites, Reservoirs, and Devices

- Enterprise can:
  - Create Sites and Reservoirs in the portal.
  - (Optional) use a bulk import process (CSV/Excel) that calls the same create endpoints; the import tooling itself is not part of v1 API scope.
- Devices are assigned to reservoirs via attach/detach.

#### 6.4.3 Role Assignment

- HQ assigns:
  - Organization `MANAGER`s and `VIEWER`s via `access_grants` on the org.
- RBAC ensures users only see allowed orgs/sites/reservoirs.

#### 6.4.4 Monitoring and Analytics

- Org dashboard:
  - Map/list of sites with current risk status.
  - KPIs: reservoirs below threshold, estimated autonomy days, consumption trends (within plan).
- Site dashboard:
  - List of reservoirs with latest levels.
  - Alerts and history.
- Device inventory:
  - Firmware version, assignment, last seen, and battery status.

#### 6.4.5 Integrations (future)

- Webhooks for critical events and API keys are not part of v1. If added later, they should sit behind RBAC (`org.manage_integrations`) plus subscription gating.

---

### 6.5 Sharing and Viral Features

#### 6.5.1 Reservoir sharing (v1)

- User shares reservoir access:
  - System creates a `tokens` row of type `INVITE` targeting `RESERVOIR:<reservoir_id>` + proposed role (and emits `RESERVOIR_SHARE_INVITED`).
  - A share token/link is sent via WhatsApp/SMS/email.
  - Recipient accepts → system creates/updates an `access_grants` row on `RESERVOIR:<reservoir_id>` (emit `RESERVOIR_SHARE_ACCEPTED`).

Implementation note:

- v1 does not need a dedicated `reservoir_invites` table; invites are unified in `tokens` (expiry + one-time use + audit via events).

#### 6.5.2 Referrals (future)

- Referral links and conversion tracking are not part of v1. If introduced, implement as a separate invitation/referral model that does not affect core RBAC.


## 7. Core Processes and Flows

### 7.1 Manual Monitoring Flow

1. User creates a reservoir and sets `monitoring_mode = MANUAL`.
2. User periodically submits readings via `POST /v1/reservoirs/{reservoir_id}/manual-reading`.
3. Backend stores the reading and emits a `RESERVOIR_LEVEL_READING` event.
4. The alert worker evaluates low-level rules depending on subscription.

Note (v1, anti-ambiguity):
- Manual monitoring is limited to user-owned reservoirs; org-owned reservoirs are device-backed (Decision D-038).

### 7.2 Device Monitoring Flow

1. Device measures level and battery.
2. Device publishes telemetry to the upstream IoT pipeline, which forwards messages into Azure Event Hubs.
3. The telemetry listener resolves `device_id` and `reservoir_id`:
   - If the device is unattached, the telemetry is discarded (no `reservoir_readings` row) and a diagnostic event is emitted.
   - Otherwise it stores the reading and emits `RESERVOIR_LEVEL_READING`.
4. The rule engine evaluates thresholds and trend rules (refill detection, leak suspicion, intermittence inference).
5. Alerts and derived metrics are produced according to the subscription.

### 7.3 Community SupplyPoint Status Flow

1. User/operator submits a status update for a SupplyPoint.
2. Permission and evidence rules (anti-ambiguity):
   - Any authenticated user may submit a community update (rate-limited).
   - If `supply_points.operator_principal_id` is set, that operator (or an explicit `SUPPLY_POINT:<id>` grant) may submit “operator updates”.
   - Operator updates may be recorded with stronger `availability_evidence_type` (for example `VERIFIED`), while community updates default to `REPORTED`.
3. Backend rate-limits user-reported updates.
3. Backend emits an `events` row (e.g. `SUPPLY_POINT_STATUS_UPDATED`) and updates cached fields on `supply_points`.

### 7.4 Marketplace Order Flow

1. Buyer selects a target reservoir (optional) and a seller reservoir listing.
2. Backend creates `orders` row with `status = CREATED` and emits `ORDER_CREATED`.
3. Seller accepts or rejects.
4. Buyer and seller each confirm delivery via `POST /v1/accounts/{account_id}/orders/{order_id}/confirm-delivery`.
5. When both confirmations are present, backend sets `delivered_at`, transitions `status = DELIVERED`, and emits `ORDER_DELIVERED`.
6. Buyer optionally submits a review.

Auto-refill:
  - Not in v1. If introduced later, specify an `auto_refill_rules` table + safety constraints and treat it as a separate flow to avoid scope creep/drift.

---

## 8. Plan-Based Feature Gating

Feature gating is implemented centrally in a `FeatureGate` service that resolves the effective plan and reads `plans.config`.

Examples:

- When fetching reservoir readings, queries are constrained to `NOW() - history_days`.
- Background retention jobs purge or downsample `reservoir_readings` beyond `telemetry_retention_days`.
- When generating alerts, the worker uses stable feature keys (decision **D-023**) to decide which channels are allowed:
  - `alerts.reservoir_level_state.APP|SMS|EMAIL`
  - `alerts.device_offline.APP|SMS|EMAIL` (and similar)
  - Entitlements are evaluated on the reservoir owner account (decision **D-020**).
- (Future) When creating an auto-refill rule, the API rejects the request if the plan does not allow it.

---

## 9. Deployment and Integration

### 9.1 Deployment Units

- **Compute (deployment target):** Azure **Container Apps** (Terraform-provisioned).
- **API Server:** FastAPI app running inside the Container App with external ingress enabled.
- **Worker:** Background processors running from the same codebase/image.
- **Telemetry Listener:** Long-lived consumer for Azure Event Hubs, hosted as a separate process inside the worker deployment (per **D-016**).
- **Database:** Azure PostgreSQL **Flexible Server** (Terraform-provisioned) with PostGIS enabled.
- **Cache:** Azure Cache for Redis (Terraform-provisioned).
- **Storage:** Azure Storage Account (Blob) for firmware binaries and operational blob containers (Terraform-provisioned).
- **Scheduler:** v1 does not require a separate managed scheduler for outbox-driven work. Wakeups are driven by Postgres `LISTEN/NOTIFY` (per **D-027**) with periodic fallback; remaining time-based loops are in-process (per **D-002**, **D-012**).

**Cost-saving single-Container-App mode (allowed in v1):**
- To minimize Azure resources early on, the API server, worker, and telemetry listener MAY be co-hosted in a single Container App **as separate OS processes** (single image, one container command).
- **Non-negotiable**: telemetry ingestion must not stop due to scaling. Therefore **scale-to-zero is forbidden** in this mode; configure the Container App with `min_replicas >= 1` (and for manual-only scaling, set `min_replicas == max_replicas`).
- Trade-off: scaling is coupled (you cannot scale API separately from telemetry/worker).

### 9.2 External Integrations (Minimal Set)

- **Azure Container Registry (ACR)** – image registry for Container Apps (Terraform-provisioned).
- **Azure Event Grid Namespace (MQTT broker)** – device MQTT broker (Terraform-provisioned) routing device messages into Event Hubs.
- **Azure Event Hubs** – telemetry ingestion pipeline and consumer scaling trigger (Terraform-provisioned).
- **Azure Storage (Blob)** – firmware container and Event Hub checkpoint container used for scaling/checkpointing support (Terraform-provisioned).
- **Azure Cache for Redis** – caching/rate-limiting primitives (Terraform-provisioned; not used as a job queue in v1).
- **AWS Pinpoint (SMS)** – OTP delivery and SMS alerts (per **D-012**).
- **AWS SES (email)** – OTP delivery and transactional emails (per **D-012**).

All integrations are encapsulated behind interfaces so they can be swapped without changing core modules.

---

## 10. Evolution Considerations

Future changes are expected in the following areas but do not affect v1 design decisions:

- Extracting the device ingestion path into a dedicated microservice if traffic warrants it.
- Introducing a separate analytics store if queries on `reservoir_readings` and `events` become too heavy.
- Adding richer marketplace features as separate modules.
- Extending evidence exports into utility-facing dashboards that consume the same aggregated indicators.

The architecture is intentionally minimal while covering all flows required to deliver Jila’s core value: reliable reservoir monitoring, transparent water ordering, and actionable, exportable analytics on water intermittence and refills.
