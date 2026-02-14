## Jila API Backend – Implementation Plan (Phased) (v0.1)

This document is the execution roadmap for implementing the backend described in:
- `docs/architecture/jila_api_backend_architecture_v_0 (3).md`
- `docs/architecture/jila_api_backend_project_structure.md`
- `docs/architecture/jila_api_backend_erd.md`
- Decisions are locked in `docs/architecture/jila_api_backend_decision_register.md`. This plan is not standalone; implementers must follow the decision register and the canonical docs listed here.

It is intentionally phased to preserve scope guardrails:
- **Phase A** delivers the core value proposition (reliability + marketplace) without turning the backend into billing/utility enterprise software.
- **Phase B** adds “utility-grade enough” evidence exports and aggregates using the Phase A data model.
- **Phase C** is optional and only pursued with a ready integration partner.

---

## 0. Guiding principles (non-negotiable)

- **Modular monolith**: one deployable, multiple internal modules.
- **Anti-drift primitives**: reuse `principals`, `access_grants`, `tokens`, `events` across modules.
- **Events-first for “history”**: if it’s “something that happened”, prefer `events` over new history tables.
- **Realtime mirrors (Firestore)**: use Firestore as a read-optimized mirror for UI realtime; Postgres remains canonical; Firestore writes are backend-only and driven by the outbox (`events`).
- **Strict state machines** for lifecycle entities (e.g., `orders`) with idempotent endpoints.
- **RBAC and subscription gating are separate layers**:
  - RBAC decides *if* an action is allowed.
  - Plan entitlements decide *what features* are enabled.

---

## 1. Phasing overview (what ships when)

### Phase 0 — Foundations (Engineering & Platform)
Goal: create the scaffold that makes Phase A safe and fast to implement.

### Phase A — Core reliability + marketplace (v1)
Goal: manual + device monitoring, supply point discovery, seller listings, orders, and alerting fundamentals.

### Phase B — Evidence packs & exports
Goal: stable derived metrics, clear data gap semantics, and exports suitable for org/funder reporting.

### Phase C — Optional utility integration track
Goal: integrations only when justified; avoid expanding Phase A/B scope.

---

## 2. Phase 0 — Foundations (Engineering & Platform)

### 2.1 Scope
- Establish the backend codebase structure and runtime entrypoints.
- Establish the DB migration workflow and schema baselines aligned to the ERD.
- Establish auth primitives and a consistent error model.
- Establish “event emission” as a first-class pattern (transactional outbox).

### 2.2 Deliverables
- **Repo structure** created per `jila_api_backend_project_structure.md`:
  - `app/main.py` (API server entrypoint)
  - `app/workers/worker_main.py` (worker entrypoint)
  - `app/telemetry/event_hubs_listener.py` (telemetry entrypoint)
- **Firestore mirror foundation** (for realtime UI; implemented early to avoid churn, and available for clients to use when desired):
  - Firebase Admin SDK integration (service account via secrets)
  - a single endpoint to mint a Firebase custom token for authenticated Jila users (`POST /v1/auth/firebase/custom-token`)
  - an event-consumer job that updates per-principal Firestore mirror docs from the `events` outbox
  - token exchange behavior is session-derived and on-demand (per **D-013**), and the mirror target is “latest/current state” (per **D-014**)
- **Configuration system**:
  - environment-driven settings (dev/staging/prod)
  - secrets handling guidance (do not hardcode)
- **Database layer**:
  - Postgres connectivity
  - migrations (Atlas-managed per **D-001**; must be versioned and CI-gated)
  - initial tables aligned to the ERD
- **Infrastructure provisioning (Terraform)**:
  - Use `infra/terraform` as the provisioning source for the v1 runtime baseline, including:
    - Azure Container Apps + ACR (compute + image registry)
    - Azure PostgreSQL Flexible Server with PostGIS enabled
    - Azure Event Grid Namespace (MQTT broker) routing to Azure Event Hubs
    - Azure Storage (Blob) for firmware binaries and operational containers
    - Azure Cache for Redis
- **Boundary enforcement (CI)**:
  - enforce module import boundaries in CI (per **D-015**) so cross-module ORM/repo/service imports fail the build
- **Error contract**:
  - consistent machine-readable error codes (e.g., `ACCOUNT_ALREADY_EXISTS`, `INVALID_ORDER_STATE`, `FEATURE_GATE`)
- **Observability basics** (minimal, v1):
  - structured logging with request correlation
  - “diagnostic events” via `events` table for ingestion failures (per architecture)

### 2.3 Acceptance criteria
- API server starts and serves `/v1` routes (even if minimal placeholders).
- Worker starts and can execute a simple scheduled job.
- Telemetry listener starts and can consume a test message shape (even if stubbed).
- DB migration can be applied idempotently in a clean environment.
- A single, documented error response shape exists and is used consistently.
- CI includes contract tests that enforce:
  - the canonical API error envelope shape (`error_code`, `message`, `details`), and
  - event payload schemas (at least envelope + key Phase A events) (D-008).

### 2.4 Risks / mitigations
- **Migration workflow**:
  - Mitigation: **DECIDED (D-001)**: Atlas is canonical; ensure schema diffs are reviewed and CI-gated.
- **Module boundary drift**:
  - Mitigation: enforce import boundaries (see project structure doc) and keep shared primitives centralized.

---

## 3. Phase A — Core reliability + marketplace (v1)

### 3.1 Scope (must-have)
Implements the core Phase A product from the value proposition, aligned to what is currently implemented in `/v1`:
- **Identity + access control**: users, orgs, principals, access grants, sessions, OTP-based verification, password reset, self-serve account erasure.
- **User/profile surfaces**: `/v1/me`, `/v1/me/profile` (including avatar upload), notification preferences, push token registration.
- **Org onboarding + RBAC management**: org creation, org invites (resolve + accept), org member listing/invites listing, org member revocation.
- **Sites + reservoirs**: reservoirs CRUD, manual readings, readings list, location pings, reservoir sharing invites (resolve + accept), org sites CRUD.
- **Devices + device ops**: device registration, attach/detach, attach-by-serial, device list/detail/patch/delete, device config GET/PUT, firmware releases + firmware update requests, and bounded device inventory surfaces.
- **Telemetry ingestion**: Event Hubs listener consumes MQTT CloudEvents and ingests device telemetry into Postgres (`device_telemetry_messages` + derived `reservoir_readings`), with diagnostic event emission for dropped payloads.
- **Supply points (discovery + governance)**: discovery/search, community nominations, status updates, and admin verify/reject/decommission flows.
- **Seller mode + listings**: seller profile, seller reservoir listing/availability updates, price rules, marketplace listing search.
- **Orders + reviews**: order creation + strict transitions, buyer/seller views, delivery confirmation, dispute, reviews.
- **Alerts**: list + mark-read surfaces plus worker-driven processing/fanout.
- **Subscriptions / feature gating surfaces**: get current subscription and change plan (upgrade/downgrade).
- **Portal + internal ops**: portal bootstrap (`/v1/me`), org dashboard stats (`/v1/accounts/{account_id}/dashboard-stats`), and internal ops endpoints under `/v1/accounts/{account_id}/*` for operations, diagnostics, and billing administration.

V1 scope snapshot (implementation-aligned):

| Area | Status | Notes |
|---|---|---|
| Identity + sessions (OTP verification, refresh/logout, password reset, account erasure) | **Implemented** | Implemented in `/v1/auth/*` plus supporting worker delivery jobs. |
| Firebase custom token (Firestore auth bridge) | **Implemented** | `POST /v1/auth/firebase/custom-token` exists; Firestore mirror processing is worker-driven. |
| Me/profile/media + notifications + push tokens | **Implemented** | `/v1/me`, `/v1/me/profile`, avatar upload/media GET, notification preferences, push token register/delete. |
| Org onboarding + invites + member management | **Implemented** | Org create/get, invite resolve/accept, member list/invites list, revoke. |
| Sites + reservoirs + sharing + org sites | **Implemented** | Reservoir CRUD + readings/manual + location pings + reservoir invite flows; org sites CRUD. |
| Reservoir capacity-source + geometry modeling | **Partial** | DB fields exist and capacity updates emit events; broader geometry-driven derivation remains a Phase A goal. |
| Device registry + pairing + portal device surfaces | **Implemented** | Device register/attach/detach/attach-by-serial, device list/detail/patch/delete, latest telemetry. |
| Device config + firmware mgmt | **Implemented** | Config GET/PUT + firmware releases/update requests (including admin variants). |
| Telemetry ingestion (Event Hubs listener → Postgres) | **Implemented** | CloudEvent subject is canonical topic; idempotency + missing-`seq` behavior aligns to device protocol doc. |
| Supply points discovery + nomination + governance | **Implemented** | Search + nomination + status updates + admin verify/reject/decommission exist. |
| Supply point update rate limiting / cooldowns | **Deferred** | Still planned (abuse prevention), but not yet enforced in the marketplace module implementation. |
| Seller mode + listings + price rules | **Implemented** | Seller profile + seller reservoirs + price rules + marketplace search exist. |
| Orders + delivery confirmation + disputes + reviews | **Implemented** | Order create/get/list + transitions + confirm delivery + dispute + reviews exist. |
| Alerts | **Implemented** | List/mark-read + fanout consumers (reservoir level, device health, orders) + processor + push delivery. |
| Subscriptions (feature-gating surface) | **Implemented** | `/v1/accounts/{account_id}/subscription` (GET/PATCH); billing automation remains ops/admin-driven. |
| Portal stats + internal ops/admin endpoints | **Implemented** | `/v1/accounts/{account_id}/dashboard-stats` plus `/v1/accounts/{account_id}/*` operational surfaces exist. |

Scope guardrail:
- See `docs/architecture/jila_value_proposition_review_notes_aligned.md` (“Phase A non-goals”) to prevent scope creep.

### 3.2 Phase A sequencing (recommended)

#### A1 — Identity & Access (foundation for everything else)
Deliver:
- Auth + sessions:
  - `POST /v1/auth/register`
- `POST /v1/auth/request-identifier-verification`
- `POST /v1/auth/verify-identifier`
  - `POST /v1/auth/login`, `POST /v1/auth/refresh`, `POST /v1/auth/logout`
  - `POST /v1/auth/request-password-reset`, `POST /v1/auth/reset-password`
  - `POST /v1/auth/request-account-erasure`, `POST /v1/auth/confirm-account-erasure`
- Organization registration uses the same auth flows:
- `POST /v1/auth/register` uses the single org-centric flow.
  - `POST /v1/org-invites/accept` supports “join existing org” onboarding; it sets org-context activation
    (`users.metadata.activation_policy = ORG_EMAIL_ONLY`) without implying org creator intent.
- `users`, `principals`, `tokens` (OTP), and minimal `access_grants`
- `user_sessions` (refresh token sessions; rotation + logout semantics)
- Me/profile + media + notifications:
  - `GET /v1/me`
  - `GET /v1/me/profile`, `PATCH /v1/me/profile`
  - `POST /v1/me/profile/avatar-upload`, `GET /v1/media/avatars/{principal_id}/{avatar_id}`
  - `GET /v1/accounts/{account_id}/notification-preferences`, `PATCH /v1/accounts/{account_id}/notification-preferences`
  - `POST /v1/accounts/{account_id}/push-tokens`, `DELETE /v1/accounts/{account_id}/push-tokens/{push_token_id}`
- Firebase bridge (Firestore auth):
  - `POST /v1/auth/firebase/custom-token`
- Org onboarding + RBAC management surfaces:
  - `POST /v1/org-invites/resolve`, `POST /v1/org-invites/accept`
  - `POST /v1/accounts`, `GET /v1/accounts/{account_id}`
  - `POST /v1/accounts/{account_id}/members/invite`
  - `GET /v1/accounts/{account_id}/members`, `GET /v1/accounts/{account_id}/invites`
  - `POST /v1/accounts/{account_id}/members/{user_id}/revoke`
- Portal bootstrap:
  - `GET /v1/me`
- Internal ops bootstrap + destructive admin actions (privileged; not a public client surface):
  - `POST /v1/setup/bootstrap-admin`
  - `POST /v1/accounts/{account_id}/erase`

Acceptance criteria:
- Registration is idempotent for `PENDING_VERIFICATION` identifiers; returns correct errors for `ACTIVE` and `LOCKED|DISABLED`.
- OTP resend revokes previous unused OTP tokens as described in the architecture.
- JWT includes `sub` + `principal_id`; org roles not embedded.
- OTP delivery is **outbox-driven** (decision D-012): API enqueues `OTP_DELIVERY_REQUESTED`; worker sends and enforces idempotency per `(token_id, channel)`. `otp_sent_via` means queued.
- Account erasure is self-serve and OTP-confirmed (decision D-019): after completion, the `users` row is hard-deleted (and dependent rows cascade), so the same phone/email can be re-registered.

#### A2 — Sites & Reservoirs (manual mode v1 baseline)
Deliver:
- Reservoirs:
  - `POST /v1/accounts/{org_principal_id}/reservoirs`, `GET /v1/reservoirs/{id}`, `PATCH /v1/reservoirs/{id}`, `DELETE /v1/reservoirs/{id}`
  - `GET /v1/accounts/{org_principal_id}/reservoirs`
- `POST /v1/reservoirs/{id}/manual-reading`
  - `GET /v1/reservoirs/{id}/readings`
- Location + sharing:
  - `PATCH /v1/reservoirs/{id}`
  - `POST /v1/reservoirs/{id}/share` (invite)
  - `POST /v1/reservoir-invites/resolve`, `POST /v1/reservoir-invites/accept`
- Org sites (portal/org workflows):
  - `POST /v1/accounts/{org_principal_id}/sites`, `GET /v1/accounts/{org_principal_id}/sites`
  - `GET /v1/sites/{site_id}`, `PATCH /v1/sites/{site_id}`, `DELETE /v1/sites/{site_id}`

Acceptance criteria:
- Ownership binding follows the anti-ambiguity rules (client cannot set `owner_principal_id`).
- Manual reading creates `reservoir_readings` with `source = MANUAL` and emits `RESERVOIR_LEVEL_READING`.
Note: geometry/capacity-source modeling is still a Phase A goal, but the current implementation focuses on
capacity + calibration/threshold fields and can be expanded without breaking core flows.

#### A3 — Devices & Telemetry ingestion (device mode capability)
Deliver:
- `POST /v1/internal/devices/{device_id}/register`
- `POST /v1/accounts/{org_principal_id}/devices/attach` and `/devices/{device_id}/detach` with 1:1 pairing enforcement
- `GET /v1/accounts/{org_principal_id}/devices`, `GET /v1/accounts/{org_principal_id}/devices/{device_id}`, `PATCH /v1/accounts/{org_principal_id}/devices/{device_id}`, `DELETE /v1/accounts/{org_principal_id}/devices/{device_id}`
- `GET /v1/accounts/{org_principal_id}/devices/{device_id}/telemetry/latest`
- Admin-facing device inventory ingestion:
  - `POST /v1/internal/device-inventory/units/{device_id}`
- Telemetry listener:
  - derive device identity from the MQTT topic path (`devices/{device_id}/telemetry`) carried through the MQTT broker → Event Hubs CloudEvent envelope
  - resolve `device_id` → `devices.device_id` → `devices.id` → attached `reservoir_id`
  - write raw telemetry to `device_telemetry_messages` (JSONB payload history)
  - derive a typed `reservoir_readings` row and link it back via `telemetry_message_id`
  - compute and store derived stats for device-sourced readings:
    - `raw_sample_count`, `raw_mean`, `raw_stddev` (mm)
    - `level_pct` + `volume_liters`
  - emit `RESERVOIR_LEVEL_READING`
  - discard unattached telemetry and emit `DEVICE_TELEMETRY_DROPPED_UNATTACHED`
  - consumer scaling and checkpointing follow the Event Hubs model provisioned in `infra/terraform` (consumer group + blob checkpoint container)

Acceptance criteria:
- Attach attempts violating 1:1 return deterministic `409 DEVICE_ALREADY_PAIRED`.
- Telemetry ingestion is safe under duplication (idempotency strategy locked; see D-007):
  - `seq` is required for v1 devices
  - dedupe uses `(mqtt_client_id, seq)` for raw payloads and `(device_id, device_seq)` for device-sourced readings
- Reservoir level derivation is reproducible:
  - raw payload is retained (`device_telemetry_messages.payload`)
  - derived reading references the raw payload (`reservoir_readings.telemetry_message_id`)

#### A3.1 — Device configuration + firmware management (minimal)
Deliver:
- Device config endpoints:
  - `GET /v1/accounts/{account_id}/devices/{device_id}/config`
  - `PUT /v1/accounts/{account_id}/devices/{device_id}/config`
- Admin bypass:
  - Internal ops admins use `/v1/internal/devices/{device_id}/config`.
- Firmware endpoints:
  - `POST /v1/internal/firmware/releases`, `GET /v1/firmware/releases`
  - `POST /v1/accounts/{account_id}/devices/{device_id}/firmware-update`
- Admin bypass:
  - Internal ops admins use `POST /v1/internal/devices/{device_id}/firmware-update`.
- Firmware binaries are stored in blob storage (as provisioned in `infra/terraform`).

Acceptance criteria:
- Device config updates are audit-friendly (emit a stable event) and are safe under retries (idempotency documented).
- Firmware release metadata references blob storage, not DB blobs.

#### A4 — SupplyPoints (discovery + availability/operational updates)
Deliver:
- `GET /v1/supply-points` with geo/radius and basic filters:
  - `kind`
  - `operational_status`
  - `availability_status`
- Community nomination + governance (v1 implementation adaptation):
  - `POST /v1/supply-points` (nominate)
  - `PATCH /v1/supply-points/{supply_point_id}` (status update)
  - `POST /v1/supply-points/{supply_point_id}/verify` (admin-only)
  - `POST /v1/supply-points/{supply_point_id}/reject` (admin-only)
  - `POST /v1/supply-points/{supply_point_id}/decommission` (admin-only)
- cached current state in `supply_points.operational_status*` + `supply_points.availability_status*` + history via `events` (`SUPPLY_POINT_STATUS_UPDATED`)
- evidence priority conflict rules enforced (`SENSOR_DERIVED` > `VERIFIED` > `REPORTED`)

Acceptance criteria:
- Rate limiting exists for user-reported updates (policy + storage approach defined).
- Lower evidence does not overwrite higher-evidence cached availability state.

#### A5 — Seller mode + listings
Deliver:
- `POST /v1/accounts/{account_id}/seller-profile`, `PATCH /v1/accounts/{account_id}/seller-profile`
- `POST /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules`
- Public search: `GET /v1/marketplace/reservoir-listings`
- Listing eligibility enforcement:
  - active seller profile
  - >=1 price rule
  - discoverable location (`location`)
  - `seller_availability_status = AVAILABLE`

Acceptance criteria:
- Price rule overlap prevention is enforced deterministically (DB constraint preferred where possible; otherwise transaction-safe logic).
- Search results only return eligible listings (no “almost eligible” leakage).

#### A6 — Orders + delivery confirmation + review
Deliver:
- `POST /v1/accounts/{account_id}/orders`
- `GET /v1/accounts/{account_id}/orders`
- `GET /v1/accounts/{account_id}/orders/{order_id}`
- `POST /v1/accounts/{account_id}/orders/{order_id}/accept|reject|cancel|confirm-delivery|dispute`
- `POST /v1/accounts/{account_id}/orders/{order_id}/reviews`
- Strict state transitions and idempotency as specified.

Acceptance criteria:
- Price is snapshotted at order creation (`price_quote_total`, `currency`) and never changes.
- Confirm-delivery is first-write-wins per party; attempts to change payload after submitting return `409 DELIVERY_CONFIRMATION_ALREADY_SET`.
- Delivery completes only when both confirmations exist; emits `ORDER_DELIVERED`.

#### A7 — Alerts & plan-based gating (minimum viable)
Deliver:
- `GET /v1/accounts/{account_id}/alerts`, `POST /v1/accounts/{account_id}/alerts/{id}/mark-read`
- Worker job that:
  - evaluates alert-worthy events
  - creates `alerts` rows based on entitlement config (channels)
- Subscription “feature gate” integration points (even if plans are static in v1 A; must be structured for Phase B)
Additional v1 implementation surfaces that support alerts delivery:
- Push token registration and notification preferences (see A1).
- Worker-driven push delivery fanout/processing.

Acceptance criteria:
- RBAC denials are `403`; plan gating returns `403 FEATURE_GATE` with required `details.feature_key` per decision **D-003**.
- Alerts are created deterministically and not duplicated under retries (idempotency documented).

### 3.3 Phase A “Definition of Done”
- All endpoints described above exist and are documented (OpenAPI).
- RBAC enforcement exists for all protected resources in the architecture.
- Core flows can be exercised end-to-end:
-   - register  verify  create reservoir  read/manual update
-   - create seller profile  price rules  listing search  order  accept  confirm delivery  review
-   - telemetry ingestion updates reservoir readings
- Key invariants are protected by DB constraints where appropriate (uniques, FKs, pairing rules, overlap prevention).
- Internal operations and portal flows are supported via `/v1/accounts/{account_id}/*` and `GET /v1/me`, without becoming required dependencies for the mobile client.

---

## 4. Phase B — Evidence packs & exports (utility-grade enough)

### 4.1 Scope
- Derived events with stable definitions (refill detection, outage windows where inferable, availability %).
- Explicit data gap semantics in analytics responses.
- Export formats:
  - CSV exports (readings, derived events, metadata)
  - PDF/HTML summaries per reservoir/site for a period (monthly default)
- Zone-level aggregation readiness:
  - zone tagging and aggregate indicators for organizations/funders.

### 4.2 Deliverables
- Analytics module services to compute:
  - per reservoir/site: refill frequency, time-below-threshold, inferred outages (with confidence)
  - per org/zone: intermittence index, at-risk counts, tanker reliance proxies
- Evidence pack generation:
  - repeatable reports with a metric dictionary reference
  - clear indication of missing telemetry periods
- Export endpoints (plan-gated):
  - `analytics.view` for viewers
  - `analytics.export` for owners/managers (plus plan entitlements)

### 4.3 Acceptance criteria
- All derived event payloads are versioned (`event_version`) and stable.
- Reports explicitly mark:
  - offline periods
  - inference assumptions
  - confidence flags
- Export reproducibility:
  - same inputs + same time window yields identical output (except “generated_at” metadata).

---

## 5. Phase C — Optional utility integration track

### 5.1 Scope guardrail
Phase C is only started with a concrete integration partner and a signed scope. It must not compromise Phase A/B stability or turn the backend into a billing system.

### 5.2 Potential deliverables (examples; not commitments)
- Metering/billing *adjacent* integrations (read-only ingestion or reconciliation helpers), not a billing engine.
- Data sharing pipelines (aggregated, anonymized zone-level exports).
- Utility pilot dashboards consuming the same Phase B indicators.

### 5.3 Acceptance criteria
- Integration adds no new “shadow RBAC system”; uses `access_grants`.
- Integration adds no new “shadow history tables” unless justified and documented (events preferred).
- SLAs, retention, and privacy constraints are documented and enforced.

---

## 6. Cross-cutting workstreams (run throughout)

### 6.1 Security & abuse prevention
- OTP and auth endpoints rate limiting and cooldown escalation.
- SupplyPoint status update rate limiting.
- Auditability via `events`.

### 6.2 Data integrity & constraints
- Enforce invariants in the DB where possible:
  - device/reservoir 1:1 pairing
  - unique access grants
  - price rule non-overlap (prefer exclusion constraint)
  - order transition conditional updates

### 6.3 Testing strategy (minimum)
- Unit tests per module service/policy logic.
- Integration tests:
  - auth flows (including idempotency)
  - order state machine
  - telemetry ingestion “unattached discard” behavior
- Contract tests for event payload shapes (versioned).

---

## 7. Recommended milestone artifacts

Each phase should produce:
- A changelog entry (what shipped and why).
- Updated OpenAPI docs (endpoints + error codes).
- A short “how to run” note for API + worker + telemetry listener.
- A migration review summary for any schema changes.
