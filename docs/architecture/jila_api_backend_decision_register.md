## Jila API Backend — Decision Register (Anti-ambiguity) (v0.1)

Purpose: this document lists the **open decisions** (and their implications) across the current architecture docs so we can resolve them **one-by-one** and prevent drift.

Principle: once a decision is marked **DECIDED**, other docs must reference it and must not re-introduce alternate options.

---

## 0. Canonical “single source of truth” map (do not drift)

- Decision register index (platform split): `docs/decision_registers/00_index.md`
- **Database schema**: `docs/architecture/jila_api_backend_data_models.md`
- **HTTP API contract**: `docs/architecture/jila_api_backend_api_contract_v1.md`
- **v1 API reference (single entry point; index + pointers)**: `docs/architecture/jila_api_backend_api_reference_v1.md`
- **Event/outbox + payload schemas**: `docs/architecture/jila_api_backend_state_and_history_patterns.md`
- **Device protocol (MQTT topics + payload requirements)**: `docs/architecture/jila_api_backend_device_management.md`
- **Firestore mirror layout + Security Rules pattern**: `docs/architecture/jila_api_backend_firestore_mirroring.md`
- **Repo/module boundaries**: `docs/architecture/jila_api_backend_project_structure.md`
- **Subscriptions & billing decision register**: `docs/architecture/jila_api_backend_subscriptions_billing_decision_register.md`
- **Architecture narrative + invariants**: `docs/architecture/jila_api_backend_architecture_v_0 (3).md`
- **Execution roadmap**: `docs/architecture/jila_api_backend_implementation_plan.md`
- **ERD**: derived visualization only: `docs/architecture/jila_api_backend_erd.md`
- **Scope guardrails**: `docs/architecture/jila_value_proposition_review_notes_aligned.md`

---

## 1. Global decisions (block Phase 0 if unresolved)

### D-001 — Migration workflow (Alembic vs Atlas)
- **Status**: DECIDED
- **Decision**: **Option A — Atlas as canonical migration tool**
- **Decision date**: 2025-12-13
- **Why it matters**: determines how schema is reviewed, how drift is prevented, and how CI gates changes.
- **Justification**:
  - Atlas provides a clear, reviewable diff-driven workflow that directly targets drift prevention.
  - Keeps the “what will change” conversation centered on schema diffs (good fit for anti-ambiguity / anti-drift goals).
  - Simplifies CI gating around “schema diff is empty / approved” as a single canonical check.
- **Must specify**:
  - canonical workflow (local + CI)
  - how diffs are reviewed
  - what is authoritative (migrations vs models)

### D-002 — Background jobs framework (worker)
- **Status**: DECIDED
- **Decision**: **Option D — In-process async worker loops; outbox-driven work is event-driven (Postgres LISTEN/NOTIFY per D-027)**
- **Decision date**: 2025-12-13
- **Why it matters**: alerts, mirroring, analytics all depend on job execution + retry semantics.
- **Justification**:
  - Current expected load is low (<< 1 msg/sec). Baseline “always-on” infra dominates cost; avoiding a Redis-backed job queue + dedicated worker tier reduces steady-state Azure spend.
  - Prefer minimal always-on background execution until job semantics require a dedicated queue.
  - Preserve an escape hatch: if/when we require durable retries/queue semantics, revisit and adopt a broker-backed worker or Azure-native queue/workflow.
- **Must specify**:
  - retry/backoff policy
  - idempotency strategy per job
  - wake-up strategy for outbox-driven consumers (see **D-027**)

### D-003 — Plan gating HTTP semantics
- **Status**: DECIDED
- **Decision**: **Option B — `403 Forbidden` with `error_code = FEATURE_GATE`**
- **Decision date**: 2025-12-13
- **Why it matters**: clients need one consistent behavior for gated features.
- **Justification**:
  - We are not implementing payment/billing flows in v1; `403 FEATURE_GATE` cleanly expresses “authenticated but not entitled” without implying checkout.
  - Keeps client UX consistent today while remaining compatible with future monetization (entitlements can change later without changing HTTP semantics).
- **Must specify**:
  - single canonical status code
  - required `details.feature_key`

### D-004 — Auth identifiers + verification policy
- **Status**: DECIDED
- **Decision**: **Option C — Phone + Email both supported as first-class; `username` resolves to either**
- **Decision date**: 2025-12-13
- **Why it matters**: impacts user uniqueness constraints, OTP token types, and login UX.
- **Decision details (canonical)**:
  - **`username` meaning + parsing (deterministic)**:
    - `username` is **not** a separate handle. It is either a phone (E.164) or an email.
    - If `username` matches E.164 (`^\+[1-9]\d{7,14}$`) → treat as phone.
    - Else if `username` contains `@` → treat as email (case-insensitive; normalized via `citext`).
    - Else → `422 INVALID_USERNAME_FORMAT`.
    - The server must not “try both” (prevents ambiguity and reduces enumeration signal).
  - **Uniqueness rules**:
    - `users.phone_e164` is unique where not null.
    - `users.email` is unique where not null (case-insensitive).
    - **Identifier availability**: An identifier is considered "in use" only if owned by an `ACTIVE` user. `PENDING_VERIFICATION` accounts can be reclaimed (registration succeeds, allowing verification restart).
    - No identifier transfer between `ACTIVE` users in v1. Attempts to claim an identifier owned by an `ACTIVE` user return deterministic `409 IDENTIFIER_ALREADY_IN_USE`.
  - **Verification policy (login-eligible identifiers)**:
    - An identifier is login-eligible only if verified:
      - phone requires `phone_verified_at != null`
      - email requires `email_verified_at != null`
  - **Verification endpoints (v1 contract)**:
    - `POST /v1/auth/verify-identifier`
    - `POST /v1/auth/request-identifier-verification`
  - **Registration + verification priority (context-aware)**:
    - **Registration uses a single org-centric model (DECIDED: D-0XX)**:
      - `POST /v1/auth/register` creates the user in onboarding state.
      - The backend ensures a **personal default organization** (org principal) with `OWNER` membership
        when the user first becomes active in onboarding flows (including verify-identifier and
        newly-created invite-accept paths).
      - `users.metadata.activation_policy` remains to control verification strictness.
    - **Registration requirements**:
      - **`phone_e164` is required**; `email` is optional (both allowed).
      - OTP issuance priority (v1):
        - SMS OTP sent to `phone_e164` for phone verification.
        - If `email` is also provided, email verification follows after phone is verified.
      - Activation rule (v1):
        - Account becomes `ACTIVE` when **phone is verified** (email may remain unverified).
    - **Org invite acceptance** (`POST /v1/org-invites/accept`) remains supported:
      - It is a join-to-existing-org flow (membership is materialized via `access_grants`) and follows the same org-context activation policy (`users.metadata.activation_policy = ORG_EMAIL_ONLY`) without implying org creator intent.
      - Accepting an emailed invite token is treated as **email verification** for the invite target (sets `email_verified_at` during acceptance).
  - **Safe anti-enumeration patterns**:
    - Login returns generic `401 INVALID_CREDENTIALS` for “not found / wrong password / not-yet-eligible” (except `403 ACCOUNT_DISABLED` for `LOCKED|DISABLED`).
    - Password reset request is `200 OK` regardless; OTP is sent only when the identifier exists and is verified.
  - **Account state transitions (v1 simple)**:
    - `PENDING_VERIFICATION → ACTIVE` is system-driven when required verifications are satisfied (per context).
    - `ACTIVE ↔ LOCKED` is admin/support-only.
    - `ACTIVE|LOCKED → DISABLED` is admin/support-only (support action to block login without deleting the record).
    - Self-serve account erasure (see **D-019**) is a separate hard-delete flow (not a DISABLED transition).
    - Changing phone/email after verification is not supported as a self-serve flow in v1 (support/admin only).
- **Must specify**:
  - uniqueness rules
  - which identifiers require OTP verification
  - account state machine transitions and who can move states
- **Invariants (must always hold; enforce with DB constraints + service logic)**:
  - **Identifier uniqueness**: no two users share the same `phone_e164` or `email` (case-insensitive).
  - **No ambiguous username resolution**: `username` must resolve deterministically (E.164 → phone, contains `@` → email, else reject).
  - **Login eligibility**: a user may authenticate with an identifier only if that identifier is verified (and user is not `LOCKED|DISABLED`).
  - **No self-serve identifier changes in v1**: phone/email changes (or “transfer”) are admin/support-only actions.
  - **Org activation requirement**: org-context accounts require both phone + email at registration/onboarding, but become `ACTIVE` when **email** is verified; phone verification is deferred.
- **Contract tests (API behavior; add to CI early)**:
  - **Username parsing**:
    - `POST /v1/auth/login` with `username="not-a-phone-or-email"` → `422 INVALID_USERNAME_FORMAT`.
  - **Anti-enumeration**:
    - `POST /v1/auth/request-password-reset` for a non-existent username returns `200 OK` (and does not leak existence).
    - `POST /v1/auth/login` for non-existent username returns `401 INVALID_CREDENTIALS` (same as wrong password).
    - **Registration activation**:
      - User with both identifiers provided becomes `ACTIVE` after verifying phone; verifying email alone does not activate (v1).
      - Email-only user becomes `ACTIVE` after verifying email.
  - **Org invite acceptance**:
    - `POST /v1/org-invites/accept` rejects if `email` does not match invite token `target_identifier`.
    - Accepting an emailed invite token is treated as completing email verification for the invite target (sets `email_verified_at` during acceptance).
    - Invite acceptance must treat revoked/used tokens as terminal: `revoked_at`/`used_at` invites are invalid (`422 INVALID_INVITE`), regardless of identifier inputs.
    - Public invite acceptance must not overwrite credentials for an existing `ACTIVE` user.
  - **Uniqueness conflicts**:
    - Attempts to register/accept-invite with a phone/email already owned by an `ACTIVE` user return deterministic `409 IDENTIFIER_ALREADY_IN_USE`.
    - `PENDING_VERIFICATION` accounts can be reclaimed (registration succeeds, allowing verification restart).

### D-005 — JWT + session revocation strategy
- **Status**: DECIDED
- **Decision**: **Option B — refresh tokens + rotation + server-side session tracking**
- **Decision date**: 2025-12-13
- **Why it matters**: security posture and operational complexity.
- **Must specify**:
  - access TTL and refresh model
  - revocation semantics when user is locked/disabled
  - **Decision details (canonical)**:
  - **Access token (JWT)**:
    - TTL: **60 minutes**
    - Used for all API requests (`Authorization: Bearer <jwt>`).
  - **Refresh tokens (rotating) + sessions (DB)**:
    - Implement `POST /v1/auth/refresh` to mint a new access token and rotate refresh tokens.
    - Store refresh sessions server-side (hashed refresh token), enabling logout and selective revocation.
    - Session lifetime policy:
      - **Mobile app**: target “stay logged in for a month” via a **30-day sliding session** (refresh extends expiry).
      - **Web portal**: same model, but refresh is typically performed on page load (short-lived access token in memory; refresh token in HttpOnly cookie).
  - **Revocation semantics**:
    - `LOCKED|DISABLED`: requests must be rejected (`403 ACCOUNT_DISABLED`) regardless of token freshness; refresh must fail and sessions should be revoked.
    - Logout revokes the session immediately; access tokens expire naturally within 60 minutes.
    - Password reset / credential change revokes all sessions for the user (forces re-login on all devices).
  - **Storage requirements (web portal)**:
    - Refresh token must be stored in an **HttpOnly, Secure cookie** (avoid localStorage).
    - Access token should be kept **in memory**; refreshed on reload using `/v1/auth/refresh`.
- **Invariants (must always hold)**:
  - Refresh tokens are **single-use** (rotation). Reuse/replay of a refresh token revokes the session.
  - Server can revoke a single session (“logout this device”) without revoking all sessions.
  - A `LOCKED|DISABLED` user cannot use access or refresh tokens to access protected endpoints.
- **Contract tests (API behavior; add to CI early)**:
  - `POST /v1/auth/login` returns both access token and refresh token (or sets refresh cookie for web).
  - `POST /v1/auth/refresh` rotates refresh token and returns a new access token; using the old refresh token again fails and revokes session.
  - `POST /v1/auth/logout` revokes the current session; subsequent refresh fails.
  - After user status becomes `LOCKED|DISABLED`, all protected endpoints return `403 ACCOUNT_DISABLED` and refresh fails.

### D-006 — Geo storage choice (PostGIS geography vs numeric lat/lng)
- **Status**: DECIDED
- **Decision**: **Option A — PostGIS `geography(Point, 4326)`**
- **Decision date**: 2025-12-13
- **Why it matters**: radius queries, indexing strategy, and portability.
- **Must specify**:
  - radius query semantics and indexing
  - staleness policy for “discoverable location”
- **Decision details (canonical)**:
  - **Storage**:
    - All point locations are stored as PostGIS `geography(Point, 4326)` (meters-based distance semantics).
    - API surface continues to accept/return `{ "lat": number, "lng": number }`; conversion happens server-side using `ST_SetSRID(ST_MakePoint(lng, lat), 4326)::geography`.
  - **Radius query semantics (v1)**:
    - Canonical operator: `ST_DWithin(<geo_column>, <query_point>, <radius_meters>)` with **meters** as the unit.
    - Ordering (when needed): `ORDER BY ST_Distance(<geo_column>, <query_point>) ASC`.
    - Input validation:
      - `lat ∈ [-90, 90]`, `lng ∈ [-180, 180]`
  - `within_radius_km` is optional.
  - If omitted with `lat`/`lng`, backend defaults to 10km.
  - If provided and `<= 0`, backend treats geo radius filtering as disabled.
  - If provided and `> 0`, backend uses the provided value (no max cap, no 422 radius validation).
  - **Indexing (Postgres/PostGIS)**:
    - Use **GiST** indexes on `geography` columns that participate in `ST_DWithin`:
      - `supply_points(location)` GiST
      - `reservoirs(location)` GiST (partial where not null)
      - `sites(location)` GiST (partial where not null) if radius queries are added later
    - Prefer partial indexes for nullable geo columns to reduce index bloat.
  - **Discoverable location staleness policy (v1)**:
    - `location` is the single canonical coordinate for reservoirs.
    - `location_updated_at` is used for freshness (v1 default: treat as stale when older than 7 days).
    - Marketplace “listing is locatable” rule uses:
      - `location IS NOT NULL` **AND** `location_updated_at >= now() - interval '7 days'`.
- **Invariants (must always hold)**:
  - All geospatial distance calculations use PostGIS `geography` (no ad-hoc lat/lng math in application code).
  - All radius queries are index-backed (GiST present) for the relevant columns.
- **Contract tests (CI-facing)**:
  - SupplyPoint radius search returns correct inclusion/exclusion for known points at known distances.
  - Stale `location` does not qualify a reservoir listing as “locatable”.

### D-0XX — Single org-centric account model
- **Status**: DECIDED
- **Decision**: **Option A — All accounts are organization principals; plans/entitlements differentiate tiers**
- **Decision date**: 2026-01-20
- **Why it matters**: removes household/org branching, standardizes ownership, and makes plan gating the primary
  differentiation mechanism across the platform.
- **Decision details (canonical)**:
  - **Activation bootstrap** ensures each user has a personal default org principal and `OWNER` access
    when they first become active in onboarding flows.
  - **Ownership**: all account-scoped resources (sites, reservoirs, orders, subscriptions) are owned by org principals.
  - **Membership**: all access control is via org grants (RBAC), even for single-user accounts.
  - **Plans**: `monitor` is the free/default plan; `protect`/`pro` provide higher entitlements. No separate
    personal plan surface.
  - **Subscriptions**: subscriptions are **org-principal only**; user principals do not carry subscriptions.
  - **Trials**: trial periods are plan-agnostic and may be applied on any plan change (not only org onboarding).
- **Invariants (must always hold)**:
  - Every user has exactly one personal default org membership (`OWNER`) ensured during activation bootstrap.
  - Resource ownership and feature gating always resolve to an org principal.
  - RBAC remains mandatory for all org-scoped endpoints; plan gating remains a separate layer (D-003).

### D-007 — Telemetry idempotency key (canonical)
- **Status**: DECIDED
- **Decision**: **Option A — require device `seq` and dedupe on `(mqtt_client_id, seq)`**
- **Decision date**: 2025-12-13
- **Why it matters**: determines whether ingestion is safe under retries/duplicates.
- **Must specify**:
  - whether `seq` is **required** for v1 devices
  - exact fallback behavior if `seq` missing
- **Decision details (canonical)**:
  - **Identity assumption (confirmed)**:
    - `mqtt_client_id` is stable and unique per physical device (MAC-based) for v1.
    - The backend’s `devices.device_id` is the canonical MQTT topic identity (`devices/{device_id}/...`), so `(mqtt_client_id, seq)` remains safe as a canonical idempotency key (where `mqtt_client_id == device_id`).
  - **`seq` requirement (v1)**:
    - `seq` is **REQUIRED** for v1 device telemetry payloads.
    - `seq` must be a monotonic int64 per device publish and must not “reset to 0” on reboot (persist across reboots).
    - `seq` must not wrap in v1. If overflow is ever approached, the device must stop publishing and require reprovisioning/firmware update.
    - If a factory reset would reset `seq`, the device must be reprovisioned with a new `{device_id}` so dedupe keys do not collide.
  - **Canonical dedupe key**:
    - Raw telemetry messages dedupe on **`(mqtt_client_id, seq)`**.
    - Derived readings additionally store `device_seq` and enforce uniqueness on **`(device_id, device_seq)`** for device-sourced readings.
  - **Fallback behavior if `seq` missing (v1)**:
    - `seq` is required for v1 device telemetry. If `seq` is missing:
      - Emit `DEVICE_TELEMETRY_DROPPED_UNATTACHED` with `reason = MISSING_SEQ`.
      - Do **not** store a `device_telemetry_messages` row (our schema requires `seq NOT NULL`).
      - Do **not** derive `reservoir_readings` and do **not** trigger alerts/side effects.
- **Invariants (must always hold)**:
  - Ingestion is safe under duplicate delivery: replay of the same `(mqtt_client_id, seq)` produces no duplicate readings/events.
  - `seq` is treated as part of the protocol contract (required field) for v1 devices.
- **Contract tests (CI-facing)**:
  - Ingesting the same telemetry twice with identical `(mqtt_client_id, seq)` results in exactly one stored raw message and one derived reading.
  - Telemetry missing `seq` does not produce a derived reading and emits a diagnostic drop event.

### D-008 — Event payload contract validation (events.data schemas)
- **Status**: DECIDED
- **Decision**: **Option B — Pydantic models as the canonical schema**
- **Decision date**: 2025-12-13
- **Why it matters**: `events` is the integration/audit backbone; payload drift breaks mirroring, alerts, analytics, and future exports.
- **Must specify**:
  - where schemas live and how they are versioned
  - what is validated in CI vs runtime
  - event payload evolution rules
- **Decision details (canonical)**:
  - **Where schemas live**:
    - Define event envelope + per-event payload models as Pydantic models in code (planned location per project structure: `modules/*/events/payloads.py`).
    - Event type constants/enums live alongside (`modules/*/events/types.py`) and must match the canonical `event_type` list in the data models doc.
  - **Versioning**:
    - `events.data` must include `event_version`; payload changes require either:
      - additive changes within the same version, or
      - a new `event_version` with explicit upgrade handling in consumers.
  - **Validation**:
    - **Runtime**: event emission must construct/validate Pydantic models before inserting into `events`.
    - **CI**: add contract tests that validate:
      - envelope presence and `event_version`
      - required payload fields per event type (at least Phase A events)
  - **Compatibility rule (v1)**:
    - Allow additive fields only; never remove/rename required fields without bumping `event_version`.

### D-009 — Event consumption cursor semantics (partitioned inputs → ordered outbox)
- **Status**: DECIDED
- **Decision**: **Option A — Consumers checkpoint only `events.seq` (global outbox ordering)**
- **Decision date**: 2025-12-13
- **Why it matters**: telemetry comes from partitioned sources (Event Hubs), but downstream relies on ordered processing; we must avoid missed/replayed side effects.
- **Must specify**:
  - which components checkpoint which cursor(s)
  - failure/replay behavior and idempotency requirements per consumer
- **Decision details (canonical)**:
  - **What is ordered (and what is not)**:
    - Azure Event Hubs ingestion is partitioned and may deliver messages more than once.
    - The canonical ordering for downstream processing is **the order of committed `events` rows** in Postgres, represented by `events.seq`.
  - **Checkpointing model**:
    - Each consumer maintains a single cursor: `event_consumers.last_seq` for its `consumer_name`.
    - A consumer reads `events` where `seq > last_seq` in ascending `seq` order.
    - A consumer advances `last_seq` **only after** successfully completing its side effects for all events up to that `seq`.
  - **Concurrency / scaling rule (v1)**:
    - For a given `consumer_name`, only one active worker instance processes events at a time (use a DB lock/lease pattern so two workers do not race the same cursor).
  - **Failure + replay semantics**:
    - Consumers are **at-least-once**. If a consumer crashes, it will replay events after restart starting from its last committed `last_seq`.
    - Therefore, every consumer side effect must be idempotent (safe under replay).
- **Invariants (must always hold)**:
  - No consumer relies on `created_at` or upstream Event Hubs offsets for correctness; `events.seq` is the only canonical cursor.
  - Every consumer is safe under replay of the same event (idempotent writes / upserts / “apply if newer” rules).
- **Contract tests (CI-facing)**:
  - A consumer restart replays previously seen `events` rows without duplicating mirrored docs/alerts.

### D-010 — SupplyPoint status update route name (public API)
- **Status**: DECIDED
- **Decision**: **Option B — `PATCH /v1/supply-points/{supply_point_id}` (+ explicit moderation endpoints)**
- **Decision date**: 2026-02-01 (supersedes 2025-12-13)
- **Why it matters**: it’s a public endpoint; route churn creates client fragmentation.
- **Decision details (canonical)**:
  - **Route**:
    - Status updates: `PATCH /v1/supply-points/{supply_point_id}`
    - Moderation transitions (admin-only):
      - `POST /v1/supply-points/{supply_point_id}/verify`
      - `POST /v1/supply-points/{supply_point_id}/reject`
      - `POST /v1/supply-points/{supply_point_id}/decommission`
  - **Update semantics**:
    - The request is **partial-update friendly**: callers may send only the fields they intend to update.
    - The server applies evidence priority and field-level conflict rules (for example, a lower-evidence availability update does not overwrite higher-evidence cached availability).
  - **Timestamp semantics (UTC, server-authoritative)**:
    - The cached “current state” timestamps (`operational_status_updated_at`, `availability_updated_at`) are **service-generated UTC** timestamps representing when Jila accepted the update.
    - If we ever accept a client-reported “observed time” for UI, it must be stored separately as non-authoritative metadata and must not affect ordering/priority.
- **Invariants (must always hold)**:
  - Route name is stable once shipped.
  - Partial updates do not require clients to re-send unchanged fields.
  - Cached current-state timestamps for SupplyPoint status are service-generated and UTC.

### D-011 — Device timestamp / clock skew policy (`recorded_at` rules)
- **Status**: DECIDED
- **Decision**: **Option B — Always use server `received_at` for `recorded_at`**
- **Decision date**: 2025-12-13
- **Why it matters**: wrong device clocks can corrupt ordering, analytics, and “latest reading” semantics.
- **Must specify**:
  - allowed skew window and clamping behavior
  - what fields are stored (raw device time vs server time) and which is authoritative for ordering
- **Decision details (canonical)**:
  - **Authoritative timestamp for ordering/computation**:
    - `recorded_at` is derived from **server receive time** (`received_at`) for all device-ingested telemetry and derived readings.
    - Device-provided timestamps (e.g., `local_timestamp_ms`) are treated as **non-authoritative** and used only for UI display/diagnostics.
  - **UTC requirement (global)**:
    - All timestamps generated by Jila services (`created_at`, `updated_at`, `received_at`, `recorded_at`, lifecycle timestamps, etc.) are **UTC**.
    - API responses represent service-generated timestamps as **ISO8601 UTC** (e.g. `2025-01-01T00:00:00Z`).
- **Invariants (must always hold)**:
  - No service uses device-local timestamps to order, dedupe, or compute metrics.
  - Service-generated timestamps are UTC across all services/environments.
- **Contract tests (CI-facing)**:
  - A telemetry payload with a wildly incorrect `local_timestamp_ms` still produces `recorded_at == received_at` (within processing tolerance).
  - All API-returned timestamps produced by the server are in ISO8601 UTC (`Z`).

### D-012 — SMS + email delivery provider (OTP + alerts)
- **Status**: DECIDED
- **Why it matters**: affects reliability, cost, and operational alignment (Azure-first default).
- **Decision**: **Option B — AWS End User Messaging (SMS) + AWS SES (email)**
- **Decision date**: 2025-12-13
- **Decision details (canonical)**:
  - **Provider(s) + region(s)**:
    - Jila uses **AWS End User Messaging** (SMS APIs; `pinpoint-sms-voice-v2`) for SMS delivery and **AWS SES** for email delivery.
    - v1 uses **`eu-central-1`** for both to keep latency predictable and operations simple (override per environment if needed).
  - **Send semantics (idempotency + retries)**:
    - Every OTP is represented by a single row in `tokens` (as already documented), and **the OTP message send is tied to that token**.
    - The system must not send more than one “successful” OTP message per `(token_id, channel)` unless the token is explicitly revoked and re-issued (which creates a new token).
    - Transient delivery failures are retried with exponential backoff and jitter. Permanent failures stop retries and require a new OTP issuance.
  - **Execution model (v1)**:
    - OTP delivery is **outbox-driven (Option B)**:
      - API endpoints issue/reuse the OTP token and insert an outbox `events` row `OTP_DELIVERY_REQUESTED` in the same DB transaction.
      - A worker consumer (`consumer_name = otp_delivery`) processes the outbox and performs provider sends.
    - API responses that include `otp_sent_via` mean **“queued for delivery”**, not “provider delivered”.
    - Scheduling detail (v1 low-usage):
      - **Ingestion** (materializing `otp_deliveries` rows from `OTP_DELIVERY_REQUESTED`) is driven by outbox wakeups (LISTEN/NOTIFY) per **D-027**.
      - **Sending** is time-based: the worker attempts deliveries that are due (`next_attempt_at IS NULL OR next_attempt_at <= now()`),
        and then sleeps until the next due attempt (bounded) rather than polling every few seconds.
      - Retry timing is stored in Postgres (`otp_deliveries.next_attempt_at`) so restarts do not lose backoff state.
      - Runtime knobs (environment-driven; see `app/settings.py`):
        - `WORKER_OTP_INGEST_BATCH_SIZE`
        - `WORKER_OTP_PROCESS_LIMIT`
        - `WORKER_OTP_MAX_SLEEP_SECONDS`
        - `WORKER_OTP_MIN_SLEEP_SECONDS`
        - `WORKER_OTP_ERROR_SLEEP_SECONDS`
  - **OTP code handling (v1)**:
    - OTP codes are **deterministically derived** (HMAC-based) from `(token_id, token_type, target_identifier)` and a server secret.
    - OTP plaintext is **never stored** in Postgres, in `events`, or in logs.
  - **Delivery failure handling (UX + support)**:
    - OTP-related endpoints remain anti-enumeration safe: responses do not reveal whether the identifier exists or whether delivery succeeded.
    - The service emits an internal audit trail for support/debugging by writing an `events` row for each send attempt and outcome (success/failure), with all service-generated timestamps in **UTC**.
    - If SMS delivery is failing, the UI can guide users to try email (when available), but the API still follows the verification priority rules already defined in **D-004**.
- **Invariants (must always hold)**:
  - OTP delivery attempts are idempotent per `(token_id, channel)` and do not spam recipients on retries.
  - Provider integration failures never leak account existence; user-visible behavior stays consistent.
  - Any service-generated timestamp associated with notification delivery and OTP lifecycle is **UTC**.
- **Contract tests (CI-facing)**:
  - Re-sending an OTP tied to the same `token_id` does not result in multiple provider sends for the same `(token_id, channel)` unless the token is re-issued.
  - OTP endpoints return the same success-shaped response for existing vs non-existing identifiers (anti-enumeration).
  - Notification/audit `events` written by the service contain ISO8601 UTC timestamps (`Z`).

### D-027 — Outbox consumer wake-ups (LISTEN/NOTIFY) to reduce polling
- **Status**: DECIDED
- **Decision**: **Use Postgres `LISTEN/NOTIFY` as a best-effort wake-up signal for outbox-driven consumers, with a periodic fallback wake**
- **Decision date**: 2025-12-16
- **Why it matters**: keeps v1 “always-on” costs low and avoids exhausting managed Postgres connection limits due to frequent polling across multiple processes.
- **Decision details (canonical)**:
  - Producers issue `NOTIFY <channel>` whenever inserting an `events` row (still within the same transaction as the canonical state write).
  - Workers hold a dedicated `LISTEN <channel>` connection and, when signaled, drain consumers by reading `events.seq > last_seq` (per **D-009**).
  - `NOTIFY` is best-effort (not durable). Therefore workers must also perform a periodic fallback wake to guarantee progress if notifications are missed.
  - The wake-up signal must never break event emission: if `NOTIFY` fails, the outbox insert still succeeds and consumers will catch up on the next fallback wake.
- **Downstream impacts (MUST understand before scaling)**:
  - **DB connection footprint increases by 1 per worker process**:
    - Each worker process holds one long-lived connection for `LISTEN` in addition to its SQLAlchemy pool.
    - This is intentional; it trades many periodic “poll queries” for one steady connection.
  - **Connection exhaustion failure mode changes**:
    - If the database is at/near its usable connection limit, the worker may fail to establish the LISTEN connection.
    - Behavior must degrade safely to fallback polling (higher latency + more DB queries; no correctness loss).
  - **Notification delivery is best-effort**:
    - `NOTIFY` can be missed during disconnects/restarts; the fallback wake is required to guarantee progress.
  - **Burst behavior changes**:
    - A single outbox commit can wake multiple consumers; workers must coalesce wakeups and bound “drain rounds” to avoid runaway loops under backlog.
  - **Operational hygiene becomes critical on small Postgres SKUs**:
    - GUI tools (Azure Data Studio/psql clients) may open many idle sessions and consume all non-reserved slots.
    - You must use `application_name` + `pg_stat_activity` attribution to diagnose and terminate idle sessions when needed.
- **Operational notes / mitigations**:
  - **Always set `application_name`** for every DB connection (API, worker, telemetry, listener) so connection owners are visible.
  - **Keep pools small on low-tier Postgres**: per-process `DB_POOL_SIZE` and `DB_MAX_OVERFLOW` must be tuned to your SKU.
  - **Controls (environment-driven; see `app/settings.py`)**:
    - `WORKER_OUTBOX_NOTIFY_CHANNEL`
    - `WORKER_OUTBOX_USE_LISTEN_NOTIFY`
    - `WORKER_OUTBOX_FALLBACK_WAKE_SECONDS`
    - `WORKER_OUTBOX_DRAIN_MAX_ROUNDS`
  - **Runbook snippet (when “reserved connection slots” happens)**:
    - Identify top holders via `pg_stat_activity` grouped by `application_name` and `client_addr`.
    - Terminate only safe idle sessions (e.g., GUI idle sessions with empty `application_name`) rather than restarting the DB.
    - Prefer prevention: keep app pools small and avoid GUI clients opening many idle sessions on low-tier Postgres.

### D-028 — Idempotency-Key header standard for retry-safe command endpoints
- **Status**: DECIDED
- **Decision**: **Use `Idempotency-Key` header for client retry safety; reuse with different request returns `409 IDEMPOTENCY_KEY_CONFLICT`.**
- **Decision date**: 2025-12-24
- **Why it matters**: mobile offline queues and flaky networks require safe retries without creating duplicates (manual readings, orders).
- **Decision details (canonical)**:
  - **Header**: clients MAY send `Idempotency-Key: <string>` on supported endpoints.
  - **Semantics**:
    - Same key + same request payload → return the same success response (safe retry; no duplicate side effects).
    - Same key + different payload → deterministic `409 IDEMPOTENCY_KEY_CONFLICT`.
  - **DB implementation**:
    - Persist `client_idempotency_key` and a stable `idempotency_request_hash` on the target table, enforced by a unique index scoped to the actor/resource.
  - **v1 endpoints using this**:
    - `POST /v1/accounts/{org_principal_id}/orders` (already in contract)
    - `POST /v1/reservoirs/{reservoir_id}/manual-reading` (offline queue safety)
- **Invariants (must always hold)**:
  - Idempotency keys are scoped so two different actors can use the same key without colliding.
  - Conflicts are deterministic and do not create partial duplicates.

### D-029 — Invite codes (human-readable) + deprecate org invite onboarding for the mobile app
- **Status**: DECIDED
- **Why it matters**: the mobile app is moving to a two-step entry flow (**Explore vs Setup**) and needs an invite shortcut that reduces user input burden without introducing organization scope into the app.
- **Context / current state**:
  - The v1 API contract currently includes org onboarding invites:
    - `POST /v1/org-invites/accept` (accept invite + onboard user)
    - `POST /v1/accounts/{org_principal_id}/members/invite` (create org invite)
  - The mobile app no longer treats organizations as in-scope. The invite path must support onboarding (including the ability to surface pre-attached context during setup).
- **Decision**: **Option B — Extend reservoir share invites to support human-readable invite codes**.
- **Decision date**: 2026-01-02
- **Decision details (canonical)**:
  - Invites are always “share existing reservoir/site access” in v1; we do not introduce new invite endpoints.
  - Add a human-readable code layer to reservoir share invites:
    - `POST /v1/reservoir-invites/resolve` (public) accepts `invite_code` and returns prefill contact details.
    - `POST /v1/reservoir-invites/accept` (auth) accepts either `invite_token_id` or `invite_code`.
  - Invites are **targeted**:
    - The inviting user supplies at least one target identifier at invite creation:
      - `invite_target_phone_e164` and/or `invite_target_email`.
    - Resolve returns these identifiers so onboarding can be prefilled.
    - Accept is protected by anti-theft rules: only an authenticated user whose **verified** phone/email matches the invite target can redeem.
- **Invite code format (must be single-valued)**:
  - Human-readable, speakable format: **`ABCD-EFGH`**
  - Normalization: store and compare codes as uppercase; accept user input case-insensitively.
  - Alphabet constraints: **exclude confusing characters** (`I`, `O`, `0`, `1`).
- **Lifecycle semantics (must be explicit)**:
  - **Invalidate after first successful accept** (one-time use).
  - **May be reused after use**: the system may recycle codes, but only after the previous invite is in a terminal state (`USED|REVOKED|EXPIRED`) and the code has been returned to an “available pool” (server-owned).
- **Security / abuse constraints (non-negotiables)**:
  - Codes are guessable if too short; therefore:
    - Add server-side rate limiting for resolve/accept by IP and device fingerprint (where available). (**TODO** in implementation; must be addressed before production exposure.)
    - Resolve is allowed to return the invite target phone/email to accelerate registration (these identifiers are the intended onboarding inputs).
  - Maintain deterministic error shapes (`422 INVALID_INVITE`, `409 INVITE_EXPIRED`) without revealing whether a specific user exists beyond “invite valid/invalid”.
- **Client UX implications (mobile app)**:
  - Unauthenticated user enters invite code → sees a minimal preview (if supported by resolve) → continues to **AuthRegister**.
  - After login/activation, the app redeems the invite to link resources and finish setup.
- **Backend implementation notes (to avoid drift)**:
  - If resolve is public, ensure it is safe under enumeration (no PII, coarse-grained data only).
  - Persist invite consumption idempotently (repeat accept should be safe and return the same result).
  - Emit outbox events for `INVITE_RESOLVED` (optional) and `INVITE_ACCEPTED` (required) so mirroring/alerts/audit are consistent.

### D-030 — Alerts content strategy (message keys vs server-rendered strings)
- **Status**: DECIDED
- **Decision date**: 2026-01-03
- **Decision**: Alerts include **both** localization keys/args **and** server-rendered convenience strings.
- **Canonical contract**: `docs/architecture/jila_api_backend_api_contract_v1.md` §9.1 (`GET /v1/accounts/{org_principal_id}/alerts`).
- **Why it matters**: mobile/push must remain key-driven for deterministic localization, while the portal needs fast, readable alerts without duplicating message catalogs and formatting rules.
- **Invariants (must always hold)**:
  - `message_key` is non-empty and stable; `message_args` is a flat JSON object (no nested objects/arrays in v1).
  - `rendered_title` and `rendered_message` are non-empty strings rendered in the user’s `preferred_language`.
  - `message_key/message_args` remain canonical for mobile push payloads and for any client that prefers local rendering.
- **Use-case (portal)**:
  - HQ triage: scan 30+ alerts quickly with human-readable strings, while still supporting deterministic deep links and mobile’s key-based push contract.

### D-031 — Alerts feed enrichment for portal-grade triage (severity + context + snapshot)
- **Status**: DECIDED
- **Decision date**: 2026-01-03
- **Decision**: Enrich `GET /v1/accounts/{org_principal_id}/alerts` with portal triage fields (single endpoint, additive).
- **Canonical contract**: `docs/architecture/jila_api_backend_api_contract_v1.md` §9.1 (`GET /v1/accounts/{org_principal_id}/alerts`).
- **Why it matters**: enables fast triage without N+1 lookups (portal) while keeping the same feed endpoint usable on mobile.
- **Invariants (must always hold)**:
  - `severity` and `context_type` are present and use the enums defined in the canonical contract.
  - `source_name` is present and safe for display (avoid secrets/PII).
  - `data_snapshot` is bounded (recommend ≤ 8 items) and values are display-ready strings (not raw numbers).
  - Existing fields (`event_type`, `subject_type`, `subject_id`, `message_key`, `message_args`, `deeplink`) remain stable.
- **Use-case (portal)**:
  - An operator immediately understands urgency + target (“Critical – Tank A at 12%”) without fetching reservoir/site records just to render the alerts list.

### D-032 — Org sites list: “portal-friendly summaries” (counts + risk + location)
- **Status**: DECIDED
- **Decision date**: 2026-01-03
- **Decision**: Enrich `GET /v1/accounts/{org_principal_id}/sites` with a portal-friendly “site summary” shape (counts + risk + location) to avoid UI fabrication and N+1 fan-out.
- **Canonical contract**: `docs/architecture/jila_api_backend_api_contract_v1.md` §2.4 (`GET /v1/accounts/{org_principal_id}/sites`).
- **Why it matters**: the portal Sites list + map needs location, risk, and counts to support triage and mapping without extra calls.
- **Invariants (must always hold)**:
  - Every item includes enough fields for list rendering and, when available, map placement.
  - `risk_level` is a rollup that can represent “data too old to trust” (STALE) distinctly from water risk.
  - `updated_at` is a freshness anchor for the list/map UI (see contract for exact semantics).
- **Use-case (portal)**:
  - An HQ manager filters Sites by “High risk” and sees counts and freshness instantly; the map can place pins without extra calls.

### D-033 — Site detail retrieval (`GET /v1/sites/{site_id}`): embed lightweight related summaries
- **Status**: DECIDED
- **Decision date**: 2026-01-03
- **Decision**: Add `GET /v1/sites/{site_id}` returning site metadata plus **lightweight related summaries** (reservoirs/devices/active alerts) to avoid fan-out.
- **Canonical contract**: `docs/architecture/jila_api_backend_api_contract_v1.md` §2.4a (`GET /v1/sites/{site_id}`).
- **Why it matters**: the portal Site detail page requires an “at a glance” view that remains usable under poor connectivity.
- **Invariants (must always hold)**:
  - The response includes stable site identity + location + status/risk + timestamps, plus bounded summary arrays for related entities.
  - The shape is “summary-first”: it must be safe and fast to render without requiring follow-up calls for names/ids.
- **Use-case (portal)**:
  - A field operator clicks a site and immediately sees which reservoir is critical and which device is offline without waiting for multiple requests.

### D-034 — Devices list endpoint (`GET /v1/accounts/{org_principal_id}/devices`) for the web portal
- **Status**: DECIDED
- **Decision date**: 2026-01-03
- **Decision**: Add `GET /v1/accounts/{org_principal_id}/devices` (list) and `GET /v1/accounts/{org_principal_id}/devices/{device_id}` (detail metadata) for portal device UX.
- **Canonical contract**:
  - `docs/architecture/jila_api_backend_api_contract_v1.md` §4.3a (`GET /v1/accounts/{org_principal_id}/devices`)
  - `docs/architecture/jila_api_backend_api_contract_v1.md` §4.3b (`GET /v1/accounts/{org_principal_id}/devices/{device_id}`)
- **Why it matters**: the portal needs operational visibility (status/battery/firmware/ownership context) without inventing fields or relying on N+1 joins.
- **Invariants (must always hold)**:
  - The list surface is filterable by org context and includes minimal site/reservoir identity for human scanning.
  - Device config remains a separate concern (`GET /v1/accounts/{org_principal_id}/devices/{device_id}/config` stays authoritative for desired/applied config state).

### D-035 — Org access surfaces: list members and list pending invites
- **Status**: DECIDED
- **Decision date**: 2026-01-03
- **Decision**: Add two explicit endpoints for portal access management:
  - `GET /v1/accounts/{org_principal_id}/members`
  - `GET /v1/accounts/{org_principal_id}/invites`
- **Canonical contract**:
  - `docs/architecture/jila_api_backend_api_contract_v1.md` §2.7a (`GET /v1/accounts/{org_principal_id}/members`)
  - `docs/architecture/jila_api_backend_api_contract_v1.md` §2.7b (`GET /v1/accounts/{org_principal_id}/invites`)
- **Why it matters**: the portal must be able to audit current access and pending invites without blind UX.
- **Invariants (must always hold)**:
  - Member listing includes role + status + timestamps needed for auditability (see contract for exact fields).
  - Invite listing includes expiry and role so owners can manage outstanding invites safely.

### D-036 — Reservoir list enrichment (`GET /v1/accounts/{org_principal_id}/reservoirs`) for thresholds + connectivity + device context
- **Status**: DECIDED
- **Decision date**: 2026-01-03
- **Decision**: Enrich `GET /v1/accounts/{org_principal_id}/reservoirs` with thresholds + connectivity + device summary (additive).
- **Canonical contract**: `docs/architecture/jila_api_backend_api_contract_v1.md` §1.9 (`GET /v1/accounts/{org_principal_id}/reservoirs`).
- **Why it matters**: portal + mobile need trust signals and operational context without UI fabrication.
- **Invariants (must always hold)**:
  - Thresholds and connectivity fields, when present, must be consistent with backend state machine and freshness rules.
  - Device summary is nullable and must never leak secrets; it exists for operational context only.

### D-037 — Reservoir “status semantics” (operational vs connectivity vs monitoring mode)
- **Status**: DECIDED
- **Decision date**: 2026-01-04
- **Why it matters**: the portal needs consistent “what does Online/Offline mean” and a separate “is this tank intentionally in maintenance/inactive” concept, without conflating it with telemetry freshness.
- **Context (what exists already)**:
  - `GET /v1/accounts/{org_principal_id}/reservoirs` includes:
    - `monitoring_mode` (`MANUAL|DEVICE`)
    - `connectivity_state` (`ONLINE|STALE|OFFLINE`) (backend-derived freshness classification)
    - `device.status` (device operational status)
- **Decision to make**: define and standardize 3 distinct concepts:
  1) **Monitoring mode** (how readings are produced): `MANUAL|DEVICE`
  2) **Connectivity state** (freshness/telemetry trust): `ONLINE|STALE|OFFLINE`
  3) **Operational status** (user/operator intent): `ACTIVE|INACTIVE|MAINTENANCE` (or similar)
- **Options**:
  - **Option A (recommended)**: keep `connectivity_state` as-is; add `operational_status` to reservoir surfaces that need it (at minimum `GET /v1/reservoirs/{reservoir_id}` and list surfaces), and never use `operational_status` as a freshness indicator.
  - **Option B**: overload `device.status` to represent both “maintenance” and “offline/online”, and do not introduce a reservoir-level operational status (risk: device-centric; breaks “inactive reservoir with a healthy device”).
  - **Option C**: add a single `reservoir_status` enum that mixes “ONLINE/OFFLINE/MAINTENANCE/INACTIVE” (risk: conflates orthogonal concerns; harder analytics and UI).
- **Recommendation**: **Option A** (separation of concerns; easiest UI + avoids drift).
- **Decision**: **Option A**.
- **Notes (v1 scope discipline)**:
  - v1 keeps `monitoring_mode` and `connectivity_state` as the authoritative “how” and “freshness” signals.
  - `operational_status` is reserved for a later additive contract change when the portal introduces explicit maintenance/inactive workflows.
- **Use-cases**:
  - A site is healthy but one reservoir is **intentionally under maintenance** → should not be labeled “offline”.
  - A reservoir is **inactive** (deliberate) while its device still reports → UI should show “Inactive (device online)”.

### D-038 — Org reservoirs must be device-backed; user-owned reservoirs may be manual-only
- **Status**: DECIDED
- **Decision date**: 2026-01-04
- **Why it matters**: portal scope is ORG-only; showing reservoirs without devices undermines “monitoring” expectations. Household tanks can be manual-only and still valid.
- **Decision to make**: enforce invariants tying owner scope to monitoring/device attachment.
- **Options**:
  - **Option A (recommended)**: **Invariant enforcement**
    - If `owner_principal_id` is an **org principal**:
      - `monitoring_mode` must be `DEVICE`
      - Manual monitoring is **not allowed** (no org reservoir is ever `MANUAL`).
      - Manual readings are **not allowed** for org reservoirs (`POST /v1/reservoirs/{reservoir_id}/manual-reading` must reject for org-owned reservoirs).
      - `device` must be non-null for “portal-grade monitored assets” surfaces (do not present manual-only org reservoirs in the portal).
      - `connectivity_state` derived from device telemetry freshness
      - reservoirs without devices are excluded from portal list surfaces (or returned but flagged as invalid—choose one).
      - Site container is mandatory:
        - org reservoirs must have a non-null `site_id`
        - reservoir ownership is derived from the site owner (`reservoirs.owner_principal_id == sites.owner_principal_id`)
- If `owner_principal_id` is a **user principal**:
      - `monitoring_mode` may be `MANUAL` and `device` may be null.
  - **Option B**: allow org reservoirs with `MANUAL` mode (risk: contradicts “org tanks always have devices”; portal must then support manual reading flows for orgs).
  - **Option C**: allow org reservoirs without devices temporarily but show them as “Needs device” (risk: policy drift; portal clutter).
- **Decision**: **Option A**.
- **Canonical stance (confirmed)**:
  - Organization reservoirs are always **device-backed**. No organization is allowed to use manual monitoring for any of its tanks.
- **Use-cases**:
  - Portal should list only “real monitored org assets” (device-backed).
- Mobile user can track a tank manually before buying a device.

### D-039 — Site detail reservoir summaries: include connectivity/device context without N+1
- **Status**: DECIDED
- **Decision date**: 2026-01-04
- **Why it matters**: the Site detail UI currently wants “reservoir online/offline + capacity” but `GET /v1/sites/{site_id}` reservoir summaries currently only include `level_state/level_pct/latest_recorded_at`.
- **Options considered**:
  - **Option A**: enrich `GET /v1/sites/{site_id}` `reservoirs[]` with:
    - `connectivity_state`
    - `capacity_liters`
    - optional `device: { device_id, status, last_seen_at, battery_pct? }`
  - **Option B**: require clients to call `GET /v1/accounts/{org_principal_id}/reservoirs` and filter by `site_id` (works today; risk: extra client logic and larger payload).
  - **Option C**: add a dedicated `GET /v1/sites/{site_id}/reservoirs` endpoint returning the richer reservoir list (more endpoints; explicit).
- **Decision**: **Option B** (v1 pragmatic; avoids redundancy in response shapes).
- **Rationale (anti-redundancy)**:
  - Portal dashboards already compose from multiple endpoints; `GET /v1/accounts/{org_principal_id}/reservoirs` is the canonical “reservoir summary with connectivity + device context” surface.
  - Site detail remains lightweight and stable; clients that need richer reservoir context can reuse the same reservoir list shape and filter by `site_id`.
- **Use-case**:
  - Site page must immediately show which reservoirs are offline and their capacities without additional calls.

### D-040 — Sites list optional pagination metadata (keep current shape; enable cursor when requested)
- **Status**: DECIDED
- **Decision date**: 2026-01-04
- **Why it matters**: portal may need server-side pagination for large orgs, but we want to keep the current structure stable.
- **Options**:
  - **Option A (recommended)**: add optional query params `limit` and `cursor`, and return `next_cursor` when paginating:
    - If no `limit/cursor`, keep current response shape and semantics.
    - If `limit` is provided, include `next_cursor` (and optionally `total` only if cheap).
  - **Option B**: always paginate (breaking change for some clients).
- **Decision**: **Option A**.
- **Anti-ambiguity rule**:
  - When pagination is used, ordering MUST be deterministic and cursor-based; the cursor is opaque to clients.
- **Use-case**:
  - Org with 10k sites: portal needs fast incremental loading and stable ordering without loading everything at once.

### D-041 — Site KPIs on Site detail page (API enrichment vs separate analytics endpoint)
- **Status**: DECIDED
- **Decision date**: 2026-01-04
- **Why it matters**: current portal UI includes KPIs (total volume, flow rate, trends) that are not present in `GET /v1/sites/{site_id}`.
- **Options considered**:
  - **Option A**: enrich `GET /v1/sites/{site_id}` with a `kpis` object (risk: endpoint grows; must remain fast).
  - **Option B**: add `GET /v1/sites/{site_id}/kpis` (or `/analytics`) with caching semantics and clear SLA.
  - **Option C**: keep KPIs as “coming soon” UI and remove from v1.
- **Decision**: **Option C** (v1: KPIs are computed client-side from existing endpoints; no dedicated KPIs API yet).
- **Rationale (scope + redundancy control)**:
  - KPIs/trends tend to expand quickly and require caching/SLA commitments; v1 avoids introducing an analytics surface without a clear contract.
  - Portal dashboard can compose “at risk / stale / offline” counts from existing endpoints (`/v1/accounts/{org_principal_id}/sites`, `/v1/accounts/{org_principal_id}/devices`, `/v1/accounts/{org_principal_id}/alerts`).
- **Use-case**:
  - Managers need weekly trends without forcing the “site metadata” endpoint to compute heavy aggregates.

### D-042 — Site create/edit writable fields: `site_type`, `description`, `address`, `zone_id`
- **Status**: DECIDED
- **Decision date**: 2026-01-04
- **Why it matters**: the portal UI includes fields that are either not writable in the contract or use placeholders.
- **Questions to resolve**:
  - Should `site_type` be set on create? editable later? immutable?
  - Should `description` be writable via `POST/PATCH`?
  - Should `address` be writable, or always server-derived (reverse geocode) from `location`?
  - How does the portal choose `zone_id` (needs a zones list endpoint)?
- **Options considered**:
  - **Option A**: make `site_type` writable on create (immutable thereafter); add `description` to POST/PATCH; keep `address` server-derived from `location` (but allow override if needed); add `GET /v1/zones` for `zone_id` selection.
  - **Option B**: keep `site_type` derived/hidden and remove it from portal UI (risk: less explicit classification and filtering).
- **Decision**: **Option B** (v1 contract stays minimal; avoid expanding site mutation surface).
- **Rationale (anti-redundancy + avoid premature schema/provider choices)**:
  - v1 avoids committing to a geocoding provider and avoids introducing new mutable “site classification” surfaces that would require new enums, migrations, and portal workflows.
  - `zone_id` remains the only optional structured classification field on site create/update in v1 (already in contract and DB).
- **Use-cases**:
  - `site_type` enables filtering and operational workflows (“treatment plant” vs “distribution node”).
  - `zone_id` supports regional reporting and access assignment.

### D-013 — Firestore token exchange policy (custom token cadence)
- **Status**: DECIDED
- **Decision**: **JWT-driven Firestore access: custom-token mint is derived from the same Jila session**
- **Decision date**: 2025-12-13
- **Why it matters**: Firestore cannot validate arbitrary third-party JWTs directly; we need a practical way to make Firestore access feel like “the same session” as the API without introducing a second identity system.
- **Decision details (canonical)**:
  - **What “use the JWT for Firestore” means in practice**:
    - Firestore Security Rules only accept Firebase-issued auth tokens. Therefore, a Jila JWT cannot be used directly as a Firestore token.
    - Instead, Jila treats the API JWT session as canonical and mints a Firebase custom token **only as a transport** for Jila claims into Firestore.
  - **Canonical flow (single session, no separate login)**:
    - Client logs into the API and obtains access/refresh tokens per **D-005**.
    - Client calls `POST /v1/auth/firebase/custom-token` using the API access token.
    - The backend verifies the API session, then mints a Firebase custom token with claims that bind Firestore access to the same Jila session, including:
      - `principal_id` (required)
      - `user_id` (optional convenience)
      - `session_id` (required; maps to `user_sessions.id` so Firestore access can be revoked by ending the Jila session)
    - Client exchanges the custom token via Firebase SDK and uses the resulting Firebase token to read Firestore mirrors.
  - **Cadence**:
    - The client requests a new Firebase custom token **on-demand** when the Firebase token is missing/expired (not on every app start).
    - The backend may cache/memoize the custom token per `(session_id)` until near expiry to reduce churn.
  - **Revocation alignment**:
    - Logging out (session revoked per **D-005**) must also remove Firestore access for that session (the claims are session-bound).
    - Firestore is a UX cache; if Firestore auth expires while the API session is still valid, the client simply repeats the token exchange and continues.
- **Invariants (must always hold)**:
  - A Firestore session cannot outlive the corresponding API session: Firestore access is always derived from a valid Jila session.
  - There is no “Firebase login” concept for Jila users; Firebase is only used to secure reads of mirrored documents.
  - All service-generated timestamps involved in token issuance and session lifecycle are **UTC**.

### D-014 — Firestore mirroring scope for Phase A
- **Status**: DECIDED
- **Decision**: **Mirror all non-historical “latest/current state” that the API serves to authenticated clients**
- **Decision date**: 2025-12-13
- **Why it matters**: the mirror is a UI read model. If the UI can read the “latest view” from Firestore, we reduce repeated API reads and preserve flexibility to shift more screens to realtime without redesigning the mirror later.
- **Decision details (canonical)**:
  - **Scope principle**:
    - If the API serves a “latest/current state” view of something to an authenticated client, we mirror an equivalent read-optimized document shape into Firestore.
    - We do not mirror historical/time-series streams (raw telemetry, reading history series, or the `events` outbox).
  - **What is explicitly excluded**:
    - Secrets/one-time tokens and sensitive internals are never mirrored (e.g., OTP tokens, password reset tokens, refresh token material).
    - High-volume historical tables are not mirrored (e.g., `device_telemetry_messages`, `reservoir_readings` history pages).
  - **Operational contract (staleness + fallback)**:
    - Firestore is an optimization. The HTTP API remains functional as the fallback for first-load and degraded conditions.
    - If a mirror is stale or missing, the client uses the API for correctness; Firestore listeners provide incremental updates where available.
  - **Canonical list lives here**:
    - The authoritative list of mirrored collections/doc shapes is defined in `docs/architecture/jila_api_backend_firestore_mirroring.md` and must be kept single-valued.

### D-015 — Module boundary enforcement mechanism
- **Status**: DECIDED
- **Decision**: **Option B — Enforced import rules in CI + conventions**
- **Decision date**: 2025-12-13
- **Why it matters**: a modular monolith only stays modular if we prevent “quick shortcuts” where one module reaches into another module’s internals. Without guardrails, the codebase turns into a tangle and later extraction becomes painful.
- **Decision details (canonical)**:
  - **What a “module boundary” means**:
    - A module is the folder `app/modules/<module_name>/`.
    - Another module must not import this module’s internals (for example: `db/orm.py`, `db/repo.py`, `service/service.py`, internal helpers).
  - **Allowed cross-module interaction patterns**:
    - **Preferred**: emit/consume domain events via the centralized `events` outbox pattern (per **D-017**) using stable payload schemas (per **D-008**).
    - **Allowed-by-design**: import a small, explicit **public surface** from another module (for example: `modules/<x>/api/schemas.py` for shared DTOs, or `modules/<x>/public.py` if we add one later).
    - **Shared primitives** (always allowed): `app/common/*`, `app/db/*` (session + base), and the canonical event emission helpers owned by the alerts/events module.
  - **Enforcement mechanism (CI)**:
    - CI runs an import-boundary checker that fails the build when forbidden imports are introduced.
    - v1 rule-set is intentionally small and focuses on the most damaging shortcuts:
      - “No cross-module ORM imports”
      - “No cross-module repo imports”
      - “No cross-module service imports”
  - **Exceptions policy**:
    - Any exception must be explicitly listed in the boundary checker config with a written rationale (so exceptions do not become silent drift).
  - **Anti-drift rule for shared concepts**:
    - If a concept is genuinely cross-cutting, it must live in an explicit shared primitive (for example `common/`), not be duplicated across modules.
- **Invariants (must always hold)**:
  - No module imports another module’s ORM models directly.
  - No module imports another module’s repo/service internals directly.
  - Any allowed cross-module dependency is intentional, visible, and enforced by CI.
- **Contract tests (CI-facing)**:
  - CI fails on a change that introduces an import from `modules/<A>/db/orm.py` into `modules/<B>/...`.
  - CI fails on a change that introduces an import from `modules/<A>/service/...` into `modules/<B>/...`.

### D-016 — Telemetry listener deployment model (process topology)
- **Status**: DECIDED
- **Decision**: **Option A — Telemetry listener runs as a separate process inside the worker container**
- **Decision date**: 2025-12-13
- **Why it matters**: v1 load is modest, and operability is simpler when we have fewer deployment units; we can still isolate runtime concerns by running the listener as a separate process.
- **Decision details (canonical)**:
  - **Process topology**:
    - The worker deployment hosts two processes: (1) the background processors/scheduler loop and (2) the telemetry listener.
    - They share the same codebase and environment configuration but run as separate processes for independent restarts.
  - **Scaling rule (v1)**:
    - Scale the worker container replica count carefully so the telemetry listener’s consumer group behavior remains correct (do not create duplicate consumers unintentionally).
    - If isolation/scaling needs grow, we revisit and split into a separate deployment unit later.
  - **Failure handling**:
    - If the telemetry listener crashes, it is restarted without taking down the API server.
    - Duplicate delivery is expected upstream; ingestion correctness relies on idempotency per **D-007**.

### D-017 — History storage strategy (current vs audit vs analytics)
- **Status**: DECIDED
- **Decision**: **Centralized `events` outbox for audit/integration + typed history tables for high-volume analytics**
- **Decision date**: 2025-12-13
- **Why it matters**: UI needs fast “latest”, mirrors need a reliable trigger, and analytics needs queryable history—without drifting into per-entity bespoke patterns.
- **Decision details (canonical)**:
  - **Current/latest state (canonical for reads)**:
    - Lives on the entity tables (e.g., `reservoirs`, `orders`, `devices`, `supply_points`).
    - Firestore mirrors are read-optimized projections of this current state for realtime UX.
  - **Audit + cross-module integration (canonical)**:
    - Every meaningful “something happened” emits exactly one row in the centralized `events` table (transactional outbox).
    - Consumers (Firestore mirror, alerts, analytics) read `events` in `events.seq` order and checkpoint progress.
  - **High-volume/analytics history (typed)**:
    - Use dedicated typed history tables only where query volume/shape demands it (e.g., `reservoir_readings`, `device_telemetry_messages`).
    - Even when a typed history table exists, still emit an `events` row for audit/integration (do not create parallel per-entity “event tables”).
- **Invariants (must always hold)**:
  - No per-entity “event tables” are created in v1; the outbox/audit stream is the centralized `events` table.
  - Any new typed history table must document why `events` alone is insufficient (query patterns, retention, indexing).

### D-018 — Password hashing algorithm (bcrypt vs argon2)
- **Status**: DECIDED
- **Decision**: **Option A — Argon2id (via `passlib[argon2]`)**
- **Decision date**: 2025-12-15
- **Why it matters**: password hashing is a core security primitive; drift here breaks login and creates high-risk auth failures.
- **Justification**:
  - bcrypt has a hard **72-byte input limit** and we observed real library interoperability issues (`passlib`↔`bcrypt`) that can prevent hashing in practice.
  - Argon2id is a modern, memory-hard password hash and avoids the bcrypt 72-byte trap.
  - Keeps auth behavior stable across environments while maintaining strong security properties.
- **Implementation constraints**:
  - Use `passlib.context.CryptContext(schemes=["argon2"], deprecated="auto")`.
  - Do not introduce bcrypt dependencies or bcrypt-based password hashing in v1.
  - Store the full encoded Argon2 hash string in `users.password_hash`.

### D-019 — Self-serve GDPR-style account erasure (v1)
- **Status**: DECIDED
- **Decision**: **Self-serve erasure is supported via an OTP-confirmed flow; execution hard-deletes the user record and dependent data.**
- **Decision date**: 2025-12-15
- **Why it matters**: deletion/erasure touches security, identifier uniqueness, and future compliance workflows.
- **Decision details (canonical)**:
  - **Endpoints**:
    - `POST /v1/auth/request-account-erasure` (authenticated)
    - `POST /v1/auth/confirm-account-erasure` (authenticated; requires OTP)
  - **Confirmation mechanism**:
    - An OTP is issued with `token_type = ACCOUNT_ERASURE` and delivered via the existing outbox-driven OTP delivery pipeline (**D-012**).
    - The OTP is sent to the verified primary contact for the user:
      - `phone_e164` verified → SMS.
      - else `email` verified → EMAIL.
  - **Execution semantics** (what “erasure” means in v1):
    - Delete the `users` row (hard delete). Dependent rows are removed via FK cascades:
      - sessions (`user_sessions`)
      - principals (`principals`) and grants (`access_grants`)
      - user-owned resources that are keyed by the user principal (e.g., seller profile, buyer orders) where those tables use `ON DELETE CASCADE` on the principal FK
    - Delete tokens that still contain identifier PII in `tokens.target_identifier` for the erased identifiers (verification OTPs, password reset, invites).
    - Preserve non-PII auditability via `events` (emit `ACCOUNT_ERASURE_REQUESTED` and `ACCOUNT_ERASURE_COMPLETED`).
  - **Organization erasure is separate**:
    - Self-serve user erasure does **not** delete organizations or org principals.
    - Admin-gated organization hard erasure is handled via `POST /v1/accounts/{org_principal_id}/erase` and emits `ORG_ERASURE_REQUESTED` / `ORG_ERASURE_COMPLETED`.
  - **Identifier reuse after erasure**:
    - Identifiers (phone/email) may be reused for a new registration **only after** they have been erased from the previous account.
    - This does not introduce “identifier transfer” between active accounts; uniqueness still holds for non-erased accounts.
- **Invariants (must always hold)**:
  - Erasure requires explicit OTP confirmation (no single-call irreversible erasure).
  - Erasure removes the `users` row; subsequent authenticated requests must fail (`401 UNAUTHORIZED`) because the user/session no longer exists.
  - Outbox events for erasure must not contain raw phone/email values (avoid PII in `events`).

### D-020 — Alerts entitlement scope (who pays for what)
- **Status**: DECIDED
- **Decision**: **Option A — Alert entitlements are determined by the reservoir’s owner account principal**
- **Decision date**: 2025-12-15
- **Why it matters**: alerts are a cross-cutting “notification feature” and must be gated consistently, especially for org/shared reservoirs.
- **Decision details (canonical)**:
  - Entitlement checks for “which alert types/channels are allowed” use the **owner account principal**:
    - For user-owned reservoirs: `reservoirs.owner_principal_id` is the user principal.
    - For org-owned reservoirs: `reservoirs.owner_principal_id` is the org principal.
  - Implementation note: entitlement resolution uses `subscriptions(account_principal_id)` + `plans.config` for the owner principal.
  - Per-recipient delivery still respects per-user preferences and verified identifiers (phone/email), but **subscription entitlement is evaluated on the owner account**.
- **Invariants (must always hold)**:
  - A user receiving a shared/org reservoir alert does not “downgrade” or “upgrade” the reservoir’s alert capabilities based on their personal plan; ownership governs entitlements.

### D-021 — Reservoir level state transitions + event contract (anti-spam)
- **Status**: DECIDED
- **Decision**: **Emit a dedicated transition event and alert only on state changes**
- **Decision date**: 2025-12-15
- **Why it matters**: prevents spamming users on every reading and makes alert generation deterministic under retries/replays.
- **Decision details (canonical)**:
  - The reservoir level state machine has four states: `FULL`, `NORMAL`, `LOW`, `CRITICAL`.
  - The backend must compute the state from `level_pct` using user-configured thresholds (stored on the reservoir) and apply **hysteresis** (see D-022).
  - When a new reading is ingested (manual or device) and the computed state differs from the persisted `reservoirs.level_state`, the service:
    1) updates `reservoirs.level_state` and `reservoirs.level_state_updated_at`, and
    2) emits exactly one outbox event: `RESERVOIR_LEVEL_STATE_CHANGED`.
  - Consumers (alerts, Firestore mirror later) rely on `RESERVOIR_LEVEL_STATE_CHANGED` rather than re-deriving transitions from raw reading events.
- **Event type**:
  - `events.type = RESERVOIR_LEVEL_STATE_CHANGED`
  - `events.subject_type = RESERVOIR`
  - `events.subject_id = <reservoir_id>`

### D-022 — Level threshold hysteresis (flap prevention)
- **Status**: DECIDED
- **Decision**: **Use per-threshold hysteresis to avoid boundary flapping**
- **Decision date**: 2025-12-15
- **Why it matters**: without hysteresis, noisy readings near thresholds can cause rapid toggling and alert spam.
- **Decision details (canonical)**:
  - Hysteresis is applied asymmetrically on “exit” from a state:
    - Enter `LOW` when `level_pct <= low_threshold_pct`.
    - Exit `LOW` to `NORMAL` only when `level_pct >= low_threshold_pct + hysteresis_pct`.
    - Enter `CRITICAL` when `level_pct <= critical_threshold_pct`.
    - Exit `CRITICAL` to `LOW` only when `level_pct >= critical_threshold_pct + hysteresis_pct`.
    - Enter `FULL` when `level_pct >= full_threshold_pct`.
    - Exit `FULL` to `NORMAL` only when `level_pct <= full_threshold_pct - hysteresis_pct`.
  - v1 uses a single configured `hysteresis_pct` default (to be defined in code/settings) unless/until we make it user-configurable.

### D-023 — Plan feature keys for alerts (subscription gating contract)
- **Status**: DECIDED
- **Decision**: **Use stable `feature_key` strings of the form `alerts.<alert_kind>.<channel>`**
- **Decision date**: 2025-12-15
- **Why it matters**: subscription gating must be consistent across API errors (`403 FEATURE_GATE`), background alert generation, and future UI behavior.
- **Decision details (canonical)**:
  - **Where keys live**:
    - `plans.config` contains a `features` object that maps `feature_key` → boolean.
    - Missing keys are treated as `false`.
  - **Namespace**:
    - `feature_key := "alerts." + <alert_kind> + "." + <channel>`
    - `<channel> ∈ {APP, SMS, EMAIL, PUSH}`
  - **v1 alert kinds (stable strings; used in `feature_key`)**:
    - `reservoir_level_state`
    - `device_health`
    - `orders`
  - **v1 preference groups (stable strings; user-facing UI grouping)**:
    - `orders` → gates order lifecycle notifications (`feature_key` uses `alerts.orders.<channel>`)
    - `water_risk` → groups reservoir level risk notifications (`feature_key` uses `alerts.reservoir_level_state.<channel>`)
    - `device_risk` → groups device health notifications (`feature_key` uses `alerts.device_health.<channel>`)
  - **Push notifications (v1)**:
    - Push delivery is **in scope for v1** and is implemented via **Firebase Cloud Messaging (FCM)** using Firebase Admin SDK credentials from `FIREBASE_CREDENTIALS_JSON`.
    - Push delivery requires a registered client token (device token); lack of a token suppresses push delivery for that user but does not affect `APP` channel delivery.
  - **SMS notifications (v1)**:
    - SMS delivery is implemented via **AWS End User Messaging** (`pinpoint-sms-voice-v2`) by the `alert_sms_delivery` worker consumer.
    - Retry/backoff state is persisted in `alert_sms_deliveries.next_attempt_at` so restarts do not lose retry timing.
  - **Email notifications (v1)**:
    - Alert email delivery is implemented via **AWS SES** by the `alert_email_delivery` worker consumer.
    - Retry/backoff state is persisted in `alert_email_deliveries.next_attempt_at` so restarts do not lose retry timing.
  - **Evaluation order (effective allow)**:
    1) subscription entitlement for the reservoir owner account (see **D-020**),
    2) recipient user’s stored preferences,
    3) recipient’s verified identifiers (SMS requires verified phone; EMAIL requires verified email),
    4) for `PUSH`: recipient has at least one active registered push token.
- **Invariants (must always hold)**:
  - All plan gating uses these stable keys; do not invent ad-hoc feature names in services.
  - Any `403 FEATURE_GATE` response uses `details.feature_key` that matches a key in this namespace.

### D-024 — Alerts fanout execution model (outbox-driven)
- **Status**: DECIDED
- **Decision**: **Alert intent is generated by an outbox consumer (`alerts_fanout`) that emits `ALERT_CREATED`**
- **Decision date**: 2025-12-15
- **Why it matters**: keeps “when to alert” logic replayable/idempotent and avoids coupling alert delivery to telemetry ingestion transaction boundaries.
- **Decision details (canonical)**:
  - The `alerts_fanout` consumer reads `events` in `events.seq` order (D-009) and processes:
    - `RESERVOIR_LEVEL_STATE_CHANGED` → emits one or more `ALERT_CREATED` events (per user/channel).
  - Idempotency:
    - `alerts_fanout` derives a deterministic `alert_id` per `(trigger_event_id, user_id, channel, alert_kind, state)` and emits it in the payload.
    - `alerts_processor` materializes `alerts` rows idempotently using `alerts.id = alert_id`.

### D-025 — OAuth/OIDC endpoints scope for v1
- **Status**: DECIDED
- **Decision**: **OAuth/OIDC endpoints are out of scope for v1**
- **Decision date**: 2025-12-16
- **Why it matters**: prevents contract drift and avoids shipping partially supported auth flows.
- **Decision details (canonical)**:
  - The v1 API contract does **not** include:
    - `GET /v1/auth/oauth/{provider}/start`
    - `POST /v1/auth/oauth/{provider}/exchange`
  - Third-party identity provider support may be introduced in a later version with explicit contract + decisions.

### D-026 — MQTT backend client, auth, and QoS choices (config/firmware)
- **Status**: DECIDED
- **Decision**: **MQTT v5 with mTLS, QoS1/no-retain, `paho-mqtt` client, idempotent on `(mqtt_queue_id, topic)`**
- **Decision date**: 2025-12-16
- **Why it matters**: backend → device command delivery and device → backend ACK handling must be consistent and secure; diverging clients/auth/QoS would break correlation and SLAs.
- **Decision details (canonical)**:
  - MQTT version: v5 for backend publishes and ACK ingestion.
  - Broker: Azure Event Grid Namespace MQTT endpoint (TLS 8883).
  - Auth: mTLS (X.509). SAS/JWT tokens are not used for devices or backend in v1; any dev-only SAS toggle must be disabled in prod.
  - Client library: Python `paho-mqtt` (TLS, QoS1) wrapped in the worker; no per-service bespoke clients.
  - QoS/retain: QoS 1, retain = false for config/firmware commands and status topics.
  - Topics: commands `devices/{device_id}/config/{type}` (including `type = firmware`), status/ACK `devices/{device_id}/config/status/{type}`.
  - Correlation/idempotency: include `mqtt_queue_id` on every backend-initiated command; retries are idempotent on `(mqtt_queue_id, topic)`.
  - Connection policy: TLS required; hostname verification on; keepalive 60s; exponential backoff with jitter on reconnect.
  - Observability/alerts: structured logs for connect/publish/ACK failures (no secrets/PII); metrics for connect success/fail and publish retries; alert when publish failures or missing ACKs breach SLA.
  - Secrets handling: cert/key supplied via settings (`MQTT_CERT_CONTENT_B64`/`MQTT_KEY_CONTENT_B64` or file paths); never log or echo credentials.

---

## 2. Per-document decision backlogs (what to rationalize)

### 2.1 `jila_api_backend_architecture_v_0 (3).md` — narrative architecture + invariants
Open items to lock:
- **D-002** worker framework (**DECIDED**: in-process async worker loops; outbox-driven wakeups via Postgres LISTEN/NOTIFY per D-027).
- **D-003** plan gating status code (**DECIDED**: Option B — `403 FEATURE_GATE`).
- **D-007** telemetry idempotency key (**DECIDED**: Option A — `(mqtt_client_id, seq)`; required `seq` + missing-seq fallback).

### 2.2 `jila_api_backend_data_models.md` — database schema canon
Open items to lock:
- **D-006** geo storage (**DECIDED**: Option A — PostGIS `geography`).
- **D-007** exact uniqueness constraints for telemetry idempotency and alert dedupe (**DECIDED**: unique `(mqtt_client_id, seq)` and `(device_id, device_seq)` for device readings).
- Add/confirm DB constraints for:
  - device↔reservoir 1:1 pairing enforcement
  - “delivery confirmation first-write-wins” enforcement keys

### 2.3 `jila_api_backend_api_contract_v1.md` — HTTP contract canon
Open items to lock:
- **D-003** choose 402 vs 403 and make it single-valued across the doc (**DECIDED**: Option B — `403 FEATURE_GATE`).
- **D-004** define canonical login identifier rules (phone/email/both) and ensure endpoints match (**DECIDED**: Option C — both first-class).
- Standardize idempotency contract for command endpoints:
  - whether you rely on conditional updates only
  - whether you also accept an `Idempotency-Key` header

### 2.4 `jila_api_backend_state_and_history_patterns.md` — outbox + event payload canon
Open items to lock:
- Event payload schema validation (**DECIDED** in **D-008**: Pydantic models as canonical schema + CI contract tests).
- Consumer cursor semantics (**DECIDED** in **D-009**: checkpoint only `events.seq`).

### 2.5 `jila_api_backend_device_management.md` — device protocol canon
Open items to lock:
- **D-007** make `seq` required vs optional (**DECIDED**: `seq` required; monotonic and persistent across reboots).
- Define clock skew behavior (when device timestamps are wrong):
  - store raw device timestamp, store server receive time, choose `recorded_at` rules.
- Define provisioning mapping:
  - how `{device_id}` is provisioned onto the device and maps to DB `devices.id` (and therefore MQTT topic paths).

### 2.6 `jila_api_backend_firestore_mirroring.md` — Firestore mirror canon
Open items to lock:
- Token exchange policy (**DECIDED** in **D-013**: JWT-driven, on-demand custom token mint bound to the same Jila session).
- Scope of mirroring (**DECIDED** in **D-014**: mirror all non-historical “latest/current state” served to authenticated clients).

### 2.7 `jila_api_backend_project_structure.md` — module boundaries
Open items to lock:
- Boundary enforcement mechanism (**DECIDED** in **D-015**: enforced import boundary rules in CI + conventions).
- Deployment process model (**DECIDED** in **D-016**: telemetry listener runs as a separate process inside the worker container).

### 2.8 `jila_api_backend_implementation_plan.md` — execution roadmap
Open items to lock:
- All Global Decisions D-001…D-007 must be explicitly resolved before Phase 0 begins.
- ✅ Implemented: implementation plan now explicitly requires API error envelope and event payload schema contract tests (see `jila_api_backend_implementation_plan.md`).

### 2.9 `jila_api_backend_erd.md` — derived visualization
Open items to lock:
- None (derived). Only action: keep updated when relationships change.

### 2.10 `jila_value_proposition_review_notes_aligned.md` — scope guardrails
Open items to lock:
- ✅ Implemented: “Phase A non-goals” list exists and is linked from the implementation plan.

---

## 2.11 Frontend Enum Alignment Discrepancies (2026-01-04)

The following discrepancies were identified during frontend-backend enum alignment and require decisions before the portal can fully adopt backend contract enums.

### D-043 — Technician role mapping (frontend has 4 roles, backend has 3)
- **Status**: DECIDED
- **Decision date**: 2026-01-04
- **Why it matters**: Frontend uses `admin|site_manager|technician|viewer`; backend uses `OWNER|MANAGER|VIEWER`. The `technician` role has no backend equivalent.
- **Options**:
  - **Option A**: Map `technician` → `VIEWER` (read-only; loses operational distinction)
  - **Option B**: Map `technician` → `MANAGER` (gains write access; may over-grant)
  - **Option C**: Add `TECHNICIAN` to backend `org_role` enum (schema change)
  - **Option D**: Keep `technician` as UI-only display label; store as `VIEWER` but show "Technician" in UI
- **Decision**: **Option D** (avoids schema change; preserves UI distinction while keeping backend RBAC unambiguous)
- **Impact**: `src/features/usersAccess/types.ts`, member display components

### D-044 — Monitoring mode semantic mismatch (frequency vs source)
- **Status**: DECIDED
- **Decision date**: 2026-01-04
- **Why it matters**: Frontend `monitoring_mode` means sampling frequency (`realtime|hourly|daily`); backend means data source (`MANUAL|DEVICE`). These are orthogonal concepts.
- **Options**:
  - **Option A**: Rename frontend field to `sampling_frequency` and add separate `monitoring_mode` field for backend enum
  - **Option B**: Map all frequency values to `DEVICE` for backend (since frequency implies device monitoring)
  - **Option C**: Backend adds `sampling_frequency` field to reservoir config (schema change)
- **Decision**: **Option A** (frontend-only change; clearest separation of concerns; no backend schema/contract change in v1)
- **Impact**: `src/features/reservoirs/types.ts`, reservoir forms, reservoir detail page

### D-045 — Device pairing state (frontend enum not in backend contract)
- **Status**: DECIDED
- **Decision date**: 2026-01-04
- **Why it matters**: Frontend uses `paired|unpaired|warning|error` for device pairing state; backend has attach/detach endpoints but no explicit pairing state enum.
- **Options**:
  - **Option A**: Keep as UI-only derived state (derive from `attached_reservoir_id` null/non-null + device status)
  - **Option B**: Request backend add `pairing_state` enum to device endpoints
  - **Option C**: Remove pairing state from frontend; use device status + attachment context only
- **Decision**: **Option A** (derive from existing backend fields; pairing state is not a backend-stored enum in v1)
- **Impact**: `src/features/devices/types.ts`, device list/detail components

### D-046 — Alert status (frontend has ack/snooze, backend only has read_at)
- **Status**: DECIDED
- **Decision date**: 2026-01-04
- **Why it matters**: Frontend uses `unread|read|acknowledged|snoozed`; backend only has `read_at` timestamp. Acknowledge and snooze are not in v1 contract.
- **Options**:
  - **Option A**: Remove `acknowledged|snoozed` from frontend; simplify to `unread|read` based on `read_at`
  - **Option B**: Keep as UI-only local state (not persisted to backend in v1)
  - **Option C**: Request backend add acknowledge/snooze endpoints for v1
- **Decision**: **Option A** (align with v1 contract; ack/snooze are out of scope for v1 and should not be represented as backend state)
- **Impact**: `src/features/alerts/types.ts`, alerts inbox page, alert filters

### D-047 — Site status (frontend has offline/maintenance, backend only has ACTIVE)
- **Status**: DECIDED
- **Decision**: **Option A — Remove `offline` and `maintenance` from site status; use `ACTIVE` only**
- **Decision date**: 2026-01-04
- **Why it matters**: Backend contract states: "In v1, sites are not 'offline'. Remove/avoid any client-side enum that treats a site as OFFLINE."
- **Rationale**: Sites are containers, not connectivity endpoints. Connectivity is expressed via device/reservoir status. Maintenance state should be at the device or reservoir level, not site level.
- **Impact**: `src/features/sites/types.ts`, site list/detail components, status badges

### D-048 — Firmware update status (frontend enum not in backend contract)
- **Status**: DECIDED
- **Decision date**: 2026-01-04
- **Why it matters**: Frontend uses `up_to_date|pending|in_progress|failed` for firmware status; backend firmware lifecycle not fully represented in v1 contract.
- **Options**:
  - **Option A**: Keep as UI-only derived state (derive from device config fields)
  - **Option B**: Request backend add firmware update status to device config response
  - **Option C**: Remove from UI until backend support is added
- **Decision**: **Option A** (v1 scope; derive from existing fields; do not invent a backend firmware-status enum in v1)
- **Impact**: `src/features/devices/types.ts`, device config components

### D-049 — Invite status `viewed` (not a backend state)
- **Status**: DECIDED
- **Decision**: **Option A — Remove `viewed` from invite status enum**
- **Decision date**: 2026-01-04
- **Why it matters**: Backend contract has `PENDING|ACCEPTED|EXPIRED|REVOKED`. The `viewed` state is not persisted.
- **Rationale**: `viewed` would require tracking email/link opens, which is not in v1 scope. If needed later, can derive from analytics or add explicit endpoint.
- **Impact**: `src/features/usersAccess/types.ts`, invite management components

### D-050 — Device type labels (frontend labels don't map to backend codes)
- **Status**: DECIDED
- **Decision date**: 2026-01-04
- **Why it matters**: Frontend uses labels like `Sensor Type A`, `Flow Meter X`; backend uses stable codes `LEVEL_SENSOR`, `FLOW_METER`, etc.
- **Options**:
  - **Option A**: Update frontend to use backend codes; keep labels as display-only
  - **Option B**: Create a device label → code lookup maintained by frontend
  - **Option C**: Request backend add `display_name` field to device type metadata
- **Decision**: **Option A** (frontend uses backend `device_type` codes; any labels are display-only). See: `docs/architecture/jila_api_backend_enums_v1.md`.
- **Impact**: `src/features/devices/types.ts`, device forms, device list

---

## 4. Device inventory + provisioning decisions (Phase A extension)

### D-051 — Device identity model (MQTT identity vs human serial)
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Option B — Dual identifiers**
  - `devices.device_id` is the **MQTT identity** (topic segment; matches Azure Event Grid Namespace client `authenticationName`).
  - `device_inventory_units.serial_number` is the **human-entered identifier** (printed on device / sales paperwork).
- **Why it matters**: serials are user-facing; MQTT identities must remain stable for telemetry dedupe and device protocol semantics (see D-007).
- **Invariants (must always hold)**:
  - Telemetry identity is derived from MQTT topic `devices/{device_id}/...` (device protocol doc); payload `device_id` is ignored.
  - Serial numbers are never used as dedupe keys; dedupe remains `(mqtt_client_id, seq)` (D-007).

### D-052 — Global “owned devices” registry structure (inventory vs operational devices)
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Option B — Separate inventory units + operational devices**
  - Add a new canonical table: `device_inventory_units` (all physical units Jila owns/sells).
  - Keep `devices` as the **operational** table used for telemetry ingestion, pairing (`devices.reservoir_id`), config, firmware, and portal operational UX.
- **Why it matters**: prevents conflating “catalog/sales/provisioning” state with “attached + reporting” operational state, and enables pre-sale inventory reconciliation.
- **Impacted docs (must be updated before implementation)**:
  - `docs/architecture/jila_api_backend_data_models.md` (new table + constraints; new FK from `devices`)
  - `docs/architecture/jila_api_backend_api_contract_v1.md` (device claim/attach-by-serial semantics; see D-055)
  - `docs/architecture/jila_api_backend_device_management.md` (provisioning mapping narrative; see D-053)

### D-053 — Provisioning source of truth + mapping (inventory ↔ Azure MQTT client ↔ device_id)
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Option A — Backend-driven provisioning pipeline (admin-only)**
- **Clarifications (confirmed)**:
  - `device_id` is derived from the device’s **MAC address** (v1) and is immutable.
  - `device_id` is the MQTT topic identity: `devices/{device_id}/...` and is also the Azure Event Grid Namespace MQTT client `authenticationName`.
- **Why it matters**: defines how we guarantee that a “known” inventory unit corresponds to a configured Azure MQTT client identity, and prevents “phantom devices” from entering telemetry.
- **Options**:
  - **Option A (recommended)**: provisioning pipeline (admin-only) creates:
    - `device_inventory_units` row (serial + model/capabilities)
    - Azure MQTT client (`authenticationName = device_id`) + certificate/thumbprint configuration
    - operational `devices` row linked to inventory
  - **Option B**: operational `devices` row is created automatically on first telemetry if a matching inventory unit exists (must remain idempotent and safe under at-least-once delivery).
  - **Option C**: allow end-users/org admins to create inventory units (high-risk; encourages serial enumeration and inconsistent provisioning).
- **Must specify**:
  - whether `device_id` is assigned at manufacturing, at provisioning time, or derived from hardware (e.g., MAC)
  - certificate strategy: per-device cert vs shared cert (security impact; also influences infra workflow)
 - **Decision details (canonical)**:
  - Provisioning is performed by an **admin-only API** (future portal UI will call this).
  - Provisioning must be **idempotent**:
    - re-provisioning the same `(device_id)` must not create duplicates
    - certificate/thumbprint updates must be safe under retries
  - Provisioning must keep Postgres canonical:
    - A device must not be considered “registered/operational” until the `devices` row exists (telemetry ingestion already drops `UNREGISTERED_DEVICE`).

### D-054 — Device claim anti-theft strategy (what does the user enter)
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Option A — Serial number only (v1), with tightened anti-enumeration**
- **Why it matters**: serial numbers can be guessable; in v1 we accept serial-only but must not leak existence/ownership via error details.
- **Non-negotiables (v1)**:
  - “Attach by serial” endpoints MUST NOT reveal whether a serial exists, is provisioned, or is owned/claimed by someone else.
  - Enforce rate limiting/cooldowns on serial attach attempts (abuse prevention; consistent with OTP endpoint guidance).
- **Upgrade path**:
  - v2 may adopt **Option B** (serial + claim secret) without breaking the MQTT identity model (D-051).

### D-055 — API semantics for “attach by serial” vs existing `/v1/internal/devices/{device_id}/register`
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Option A — `/v1/internal/devices/{device_id}/register` becomes provisioning-only + add user attach-by-serial (contract change)**
- **Why it matters**: `/v1/internal/devices/{device_id}/register` cannot remain user-creatable if inventory is canonical (D-052).
- **Decision details (canonical)**:
  - Keep `POST /v1/internal/devices/{device_id}/register` in the contract, but restrict it to **privileged provisioning actors** (admin/service principal allowlist).
    - It may create/refresh the operational `devices` row **only when** a matching `device_inventory_units` exists.
    - It must not mint end-user ownership/grants except as part of controlled provisioning workflows.
  - Add a new authenticated endpoint: `POST /v1/accounts/{org_principal_id}/devices/attach`.
    - Request includes `serial_number` and `reservoir_id`.
    - Server resolves to an operational `device_id` and then performs the existing attach semantics (v1 1:1).
  - **Anti-enumeration (required; D-054)**:
    - For valid-looking serials, failures must return a single deterministic error that does not reveal whether the serial exists or is owned.
    - Only format errors may be `422` (safe).

### D-056 — Terraform vs runtime provisioning for per-device Azure MQTT client resources
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Option B — Backend provisioning for per-device clients; Terraform for shared infra**
- **Why it matters**: per-device client resources are high-churn; Terraform state becomes an operational bottleneck as the fleet grows.
- **Decision details (canonical)**:
  - Terraform continues to manage:
    - Event Grid Namespace, topic spaces, permission bindings, CA certs (shared)
    - Event Hubs routing + consumption infra
  - Backend provisioning (admin-only API) manages:
    - per-device MQTT clients (`authenticationName = device_id`)
    - per-device thumbprints/cert settings required by Azure

### D-057 — Inventory serial number format + normalization
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Serial format is `JL-` + 6 alphanumeric characters**
- **Canonical format**:
  - Regex: `^JL-[A-Z0-9]{6}$`
  - Normalization: trim + uppercase before storage and comparison.
- **Why it matters**: enables deterministic validation and prevents drift between printed serials, sales workflows, and attach-by-serial flows.

### D-058 — Sales/catalog hooks storage for inventory units (v1)
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Store sales-related fields inside `device_inventory_units.metadata` (JSONB)**
- **Why it matters**: pricing/capabilities are still evolving; we avoid schema churn and duplicated fields across per-unit rows in v1.
- **Constraints (v1)**:
  - Metadata must not contain secrets (cert material, keys) and must remain bounded in size.
  - If/when sales fields stabilize, we will extract a dedicated `device_models`/catalog table and migrate non-volatile fields out of JSONB.

### D-059 — Platform admin authorization model (Option A: global power only via explicit admin endpoints)
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Option A — platform admin power is exercised via explicit internal-ops endpoints**
  - “Platform admin” actions must be implemented as explicit `/v1/accounts/{org_principal_id}/*` endpoints, where `org_principal_id`
    is the internal ops admin principal id and must match the caller.
  - Standard end-user endpoints remain strictly RBAC-protected; admins do **not** bypass RBAC everywhere by default.
- **Why it matters**:
  - Lower blast radius (a leaked admin token is still catastrophic, but the set of affected endpoints is smaller and more auditable).
  - Clearer mental model for developers and operators: global operations live behind explicit admin gates.
- **Membership mechanics (no restarts)**:
  - Configure a single **DB-backed** internal ops org id for the tenant (preferred) via `platform_settings.internal_ops_org_id`.
    - Alternate configuration source: `INTERNAL_OPS_ORG_ID` env var may be used if DB settings are not configured.
  - Admin membership is DB-backed: a principal is an admin when it has an ACTIVE `access_grants` row on:
    - `object_type='ORG', object_id=<internal_ops_org_id>`, role `OWNER|MANAGER`.
  - Adding/removing admins is done by granting/revoking membership in that org (no API restart required).
- **No static allowlists**:
  - There is **no** principal allowlist fallback for platform admin/provisioning operations.
  - If the internal ops org is not configured, privileged endpoints must fail closed with `403` until bootstrap is completed.

### D-063 — Turnkey platform admin bootstrap (DB-backed settings + single-use secret)
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Option A extension — move internal ops org id into Postgres (`platform_settings`) and bootstrap once via a single-use secret**
  - Introduce a singleton table `platform_settings` with:
    - `internal_ops_org_id` (uuid) — the tenant’s internal ops org container id (preferred source for D-059).
    - `allowed_admin_email_domain` (text) — default `jila.ai` (platform admins must be on this domain).
    - `bootstrap_secret_hash` + `bootstrap_used_at` — one-time setup guardrails.
  - Add `POST /v1/setup/bootstrap-admin`:
    - Requires a bootstrap secret (provisioned via Terraform/secret manager; stored hashed in DB).
    - Creates the internal ops org (if missing), creates/activates an admin user, grants OWNER on the internal ops org.
    - Marks bootstrap used and clears the stored secret hash (single-use).
- **Why it matters**:
  - Supports “turnkey” self-hosted tenant installs without relying on mutable env vars for admin membership.
  - Prevents the “first caller becomes admin” vulnerability via a bootstrap secret.
  - Enforces organizational control: platform admins are constrained to `@jila.ai` accounts.
  - Avoids an extra “am I admin?” network call: `GET /v1/me` includes `is_internal_ops_admin` for portal UX branching.

### D-064 — Aggregated statistics surfaces (dashboard + list stats)
- **Status**: DECIDED
- **Decision date**: 2026-01-07
- **Why it matters**: The portal/mobile currently must compose dashboard-grade counts from multiple endpoints, which increases UI complexity and encourages N+1 patterns.

- **Decision (DECIDED; canonical)**:
  - Adopt an **opt-in list stats pattern**: selected list endpoints accept `include_stats=true` and, when present, return a `stats` object computed across the **full filtered set** (independent of pagination).
  - Add **`GET /v1/accounts/{org_principal_id}/dashboard-stats`** as a **stats-only** rollup endpoint for the portal dashboard (`org_principal_id` is org principal id).

Decision details (canonical):
- `include_stats` is optional and defaults to `false`.
- When `include_stats=true`, `stats` is included in the response; otherwise `stats` is omitted.
- `stats` must be computed using the **same filters** as the list query and represent the **entire matching set**, not the current page.
- RBAC scope: dashboard/list stats must honor the caller’s effective visibility (org membership + any site-scoped grants).
- `snapshot_at` (ISO8601 UTC `Z`) is required on dashboard rollups.
- Performance: stats must be computable via a bounded number of index-backed aggregate queries.

Impacted endpoints (v1; canonical):
- New: `GET /v1/accounts/{org_principal_id}/dashboard-stats`
- Enrich (opt-in stats): `GET /v1/accounts/{org_principal_id}/alerts`, `GET /v1/accounts/{org_principal_id}/orders`, `GET /v1/accounts/{org_principal_id}/members`, `GET /v1/accounts/{org_principal_id}/invites`, `GET /v1/accounts/{org_principal_id}/devices`, `GET /v1/supply-points`, `GET /v1/marketplace/reservoir-listings`, `GET /v1/accounts/{org_principal_id}/reservoirs`

Non-goals (v1; canonical):
- Time-series analytics (trends, consumption forecasting) beyond simple rollups.
- Materialized/async precomputation and caching semantics.

Spec reference:
- `docs/architecture/design/aggregated_statistics_endpoints_v1.md`

### D-065 — Org dashboard stats: device battery rollup shape (`low_battery_count` vs `battery_health`)
- **Status**: DECIDED
- **Decision date**: 2026-01-07
- **Decision**: **Option C — include both `battery_health` and `low_battery_count`**
- **Why it matters**: the portal dashboard needs a stable, low-churn device battery signal; contract ambiguity here will
  cause either UI drift or repeated backend changes.

Use-case narrative:
- The portal dashboard (and potentially mobile) needs to show a “fleet health” summary at a glance:
  - a quick badge for “how many devices need attention due to battery”
  - optionally a small breakdown to support “what’s the severity” without extra calls

Problem statement (current drift):
- `docs/architecture/api_contract/03_orgs_sites_portal.md` shows `devices.low_battery_count`.
- `docs/architecture/design/aggregated_statistics_endpoints_v1.md` shows `devices.battery_health` buckets:
  `{ good_count, low_count, critical_count }`.

Options:
- **Option A**: Keep only `devices.low_battery_count` in the dashboard response (single integer).
- **Option B**: Keep only `devices.battery_health` buckets in the dashboard response (more informative, still bounded).
- **Option C**: Include **both**:
  - `devices.battery_health` buckets as the canonical distribution
  - `devices.low_battery_count` as a convenience scalar derived from the buckets

Decision details (canonical):
- Include `devices.battery_health` with:
  - `good_count`: `battery_pct > 50`
  - `low_count`: `20 <= battery_pct <= 50`
  - `critical_count`: `battery_pct < 20`
- Include `devices.low_battery_count` as a convenience scalar:
  - `low_battery_count = battery_health.low_count + battery_health.critical_count`

Impacted docs (must be updated once decided):
- `docs/architecture/api_contract/03_orgs_sites_portal.md`
- `docs/architecture/design/aggregated_statistics_endpoints_v1.md` (ensure examples and notes match)

### D-066 — Canonical status of admin convenience endpoints (`/v1/accounts/{org_principal_id}/me|health|stats`)
- **Status**: DECIDED
- **Decision date**: 2026-01-07
- **Decision**: **Option B — promote and implement admin convenience endpoints**
- **Why it matters**: these routes currently create contract↔implementation drift and block a clean “contract is canon”
  posture for internal-ops `/v1/accounts/{org_principal_id}/*` surfaces.

Use-case narrative:
- Admin portal often needs:
  - a cheap “am I authenticated as an admin?” call
  - a small “system health” call for operators (outbox/telemetry/mirror)
  - a one-call dashboard summary for operator triage
  - a cheap “service is reachable” check (can be satisfied by `GET /v1/accounts/{org_principal_id}/me`)

Current state:
- Canonical admin contract doc contains entries for:
  - `GET /v1/accounts/{org_principal_id}/me`
  - `GET /v1/accounts/{org_principal_id}/stats`
  - `GET /v1/accounts/{org_principal_id}/health`
  and they must remain implemented (contract is canon).

Options:
- **Option A**: Keep v1 minimal:
  - Treat `GET /v1/accounts/{org_principal_id}/me|health|stats` as **V2/non-normative** and remove them from the canonical v1 contract surface.
- **Option B**: Promote and implement:
  - Add `GET /v1/accounts/{org_principal_id}/me|health|stats` as canonical v1 endpoints with explicit semantics and tests.

Decision details (canonical):
- `GET /v1/accounts/{org_principal_id}/me` is a canonical v1 endpoint used for:
  - explicit admin gating (single call)
  - delivering a small, stable set of admin capability metadata needed by the admin portal
- `GET /v1/accounts/{org_principal_id}/health` is a canonical v1 endpoint used for:
  - bounded operational health signals derived from existing diagnostics sources (outbox + telemetry + mirror)
- `GET /v1/accounts/{org_principal_id}/stats` is a canonical v1 endpoint used for:
  - bounded, high-level dashboard rollups for internal ops (not a dumping ground; additions must be approved)

Non-goals (v1; D-066 scope):
- Do not add a dedicated admin “ping” endpoint; smoke-testing can use `GET /v1/accounts/{org_principal_id}/me` or another internal ops endpoint.

Impacted docs (must be updated once decided):
- `docs/architecture/api_contract/04_admin_internal_ops.md`
- `docs/architecture/jila_api_backend_api_contract_v1.md` (index pointers, if applicable)

### D-067 — `include_stats` distributions must be bounded (firmware versions map)
- **Status**: DECIDED
- **Decision date**: 2026-01-07
- **Decision**: **Option B — return bounded top-N map; omit the rest**
- **Why it matters**: some stats are potentially unbounded (notably firmware versions), risking large payloads and
  inconsistent client behavior.

Use-case narrative:
- The portal wants “what versions are out there?” to inform ops.
- We need the response to remain stable as fleet size and firmware diversity grows.

Options:
- **Option A**: Return the full `firmware_versions` map (exact counts for all observed versions).
- **Option B**: Return a bounded top-N map (e.g., top 20) and omit the rest.
- **Option C**: Return a bounded top-N map plus an `OTHER` bucket for the remainder.

Decision details (canonical):
- `stats.firmware_versions` is capped to **top 20** versions by descending count (ties broken lexicographically).
- Versions outside the top 20 are omitted and have no explicit “other” bucket in v1.

Impacted docs (must be updated once decided):
- `docs/architecture/api_contract/06_devices_firmware_telemetry.md`
- `docs/architecture/design/aggregated_statistics_endpoints_v1.md`

### D-068 — Ownership of cross-domain dashboard stats (`GET /v1/accounts/{org_principal_id}/dashboard-stats`)
- **Status**: DECIDED
- **Decision date**: 2026-01-07
- **Decision**: **Option B — dedicated read-only “portal stats” module**
- **Why it matters**: dashboard stats span multiple domains (sites, reservoirs, devices, alerts). Without an explicit
  “owner” module, the implementation risks architectural drift (cross-module coupling) and unclear transaction/query
  boundaries.

Use-case narrative:
- The portal dashboard wants a single “org snapshot” call that includes small rollups for:
  - reservoirs (level + connectivity)
  - devices (status + battery health)
  - alerts (unread + severity)
  - sites (risk level)

Options:
- **Option A**: Implement inside `core_water` (treat dashboard stats as “portal operational” like sites/devices lists).
- **Option B**: Create a dedicated “portal stats” module that is explicitly read-only and aggregates across tables.
- **Option C**: Implement inside `admin_portal` (treat as an operator surface, even though it is org-member-facing).

Decision details (canonical):
- Create a dedicated `portal_stats` module that:
  - is **read-only** (no new tables in v1; no writes)
  - computes cross-domain rollups using bounded aggregate queries
  - avoids cross-module imports of service/db internals (prefer raw SQL in its own repo layer)
- Keep per-endpoint `include_stats` logic within the owning module of each endpoint (no central “stats god service”).

Impacted docs (must be updated once decided):
- `docs/architecture/jila_api_backend_project_structure.md`
- `docs/architecture/jila_api_backend_api_contract_v1.md` (module ownership notes, if present)

### D-069 — Admin branching signal is a `GET /v1/me` field (not a standalone endpoint)
- **Status**: DECIDED
- **Decision date**: 2026-01-07
- **Decision**: **Option A — keep `is_internal_ops_admin` as a field on `GET /v1/me`**
- **Why it matters**: the contract currently contains a reference that reads like an endpoint, but the code implements
  the signal as a field on `GET /v1/me`. This ambiguity causes client drift and “phantom endpoints”.

Use-case narrative:
- The portal needs to branch UX (admin vs non-admin) without forcing the client to probe privileged endpoints and
  interpret 403s.

Options:
- **Option A**: Keep `is_internal_ops_admin: bool` as a field on `GET /v1/me` (single call), and remove any endpoint-style
  references to `GET /v1/me.is_internal_ops_admin`.
- **Option B**: Add an explicit endpoint `GET /v1/me.is_internal_ops_admin` returning a tiny response.

Decision details (canonical):
- `GET /v1/me` remains the canonical branching surface for “is admin?” checks in v1.
- No new endpoint `GET /v1/me.is_internal_ops_admin` is added.

Impacted docs (must be updated once decided):
- `docs/architecture/api_contract/04_admin_internal_ops.md`
- `docs/architecture/api_contract/02_auth_identity.md` (if it documents `/v1/me` fields)

### D-060 — Admin user account status management semantics (lock/disable)
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Option A — simple, deterministic state transitions**
  - Admin endpoints mutate `users.status` only (no new tables).
  - Idempotent semantics:
    - `lock`: `ACTIVE|PENDING_VERIFICATION → LOCKED`; no-op if already `LOCKED`; **409** if `DISABLED`.
    - `unlock`: `LOCKED → ACTIVE`; no-op if already `ACTIVE`; **409** if `DISABLED`.
    - `disable`: `* → DISABLED`; no-op if already `DISABLED`.
    - `enable`: `DISABLED → ACTIVE`; no-op if already `ACTIVE`; **409** if `LOCKED` (requires explicit `unlock`).
- **Why it matters**: gives support teams predictable outcomes and keeps retries safe.
- **Impacted**: `docs/architecture/jila_api_backend_api_contract_v1.md` (admin user endpoints + error semantics)

### D-061 — Admin session revocation semantics
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Option A — revoke by setting `user_sessions.revoked_at`**
  - `POST /v1/internal/users/{user_id}/sessions/revoke` sets `revoked_at = now()` for all sessions with `revoked_at IS NULL` (admin-only).
  - Access token invalidation relies on session checks (`session_id` claim) per D-005 (server-tracked sessions).
  - Endpoint is idempotent and does not return any token material.
- **Why it matters**: immediate support response to compromised sessions without schema changes.

### D-062 — Admin org membership grant/revoke semantics
- **Status**: DECIDED
- **Decision date**: 2026-01-05
- **Decision**: **Option A — manage membership via `access_grants` on ORG**
  - `grant`: ensure an ACTIVE `access_grants` row exists for the user's principal on `ORG:<org_id>` with role `OWNER|MANAGER|VIEWER`; update role if different.
  - `revoke`: revoke membership grant and any scoped `SITE`/`RESERVOIR` grants under the org (mirrors `/v1/accounts/{org_principal_id}/members/{user_id}/revoke` semantics).
  - Endpoints are idempotent and return deterministic `404` for unknown `user_id`/`org_id`.
- **Why it matters**: supports internal ops user management without needing impersonation or cross-endpoint RBAC bypass.

### D-070 — Cross-org internal asset aggregate lists replace admin fan-out
- **Status**: DECIDED
- **Decision date**: 2026-02-12
- **Decision**: **Option B — additive `/v1/internal/*` aggregate list endpoints with cursor pagination**
  - Add admin-only endpoints:
    - `GET /v1/internal/reservoirs`
    - `GET /v1/internal/sites`
    - `GET /v1/internal/devices`
    - `GET /v1/internal/orders`
  - Keep existing `/v1/internal/orgs` and account-scoped endpoints unchanged.
  - Each endpoint returns cross-org rows with org context, `next_cursor`, and `total_count`.
  - Each endpoint uses bounded page size (`limit <= 100`) and opaque cursor tied to endpoint + sort/order.
- **Why it matters**: admin dashboard login currently triggers `1 + N` fan-out requests (org list + per-org asset calls), which causes DB pool contention and avoidable 500s under concurrency.
- **Implementation notes**:
  - Server-side filtering/sorting replaces client fan-out filtering.
  - Query design remains single-statement per endpoint (filtered CTE + `COUNT(*) OVER()` + paged slice).
  - Devices scope is attached devices only (devices linked to org-owned reservoirs).
- **Impacted docs**:
  - `docs/architecture/api_contract/04_admin_internal_ops.md`
  - `docs/architecture/jila_api_backend_api_contract_v1.md`
  - `docs/qa/e2e.md`

### D-071 — Supply-point survey enrichment storage and precedence
- **Status**: DECIDED
- **Decision date**: 2026-02-14
- **Decision**: **Option A — single-table enrichment on `supply_points` with logical public/admin exposure split**
  - Store both normalized public-safe and admin raw/PII enrichment columns directly on `supply_points`.
  - Keep exposure split at API/RBAC layer: public routes return only safe normalized fields; admin route returns raw/PII fields.
  - Import pipeline is CLI-first (dry-run + apply), not an ingestion HTTP endpoint in v1.
  - New imported rows are `VERIFIED`.
  - Survey imports may set baseline `supply_points` status only when current state is unknown/unset; stronger later evidence is not overwritten.
  - `ABANDONED_LONG_TERM` is folded into `ABANDONED`.
  - Location object naming must remain consistent: coordinates are represented as `{lat,lng}` (`location` / `source_location`).
- **Why it matters**: prevents PII leakage, keeps imports idempotent, and avoids survey snapshots corrupting live operational status.
- **Impacted docs**:
  - `docs/architecture/supply_point_enrichment_and_enum_dictionary_v1.md`
  - `docs/architecture/jila_api_backend_data_models.md`
  - `docs/architecture/jila_api_backend_enums_v1.md`
  - `docs/architecture/api_contract/07_supply_points.md`
  - `docs/architecture/api_contract/04_admin_internal_ops.md`

### D-072 — Org dashboard snapshot endpoint for first-load fan-out reduction
- **Status**: DECIDED
- **Decision date**: 2026-02-14
- **Decision**: **Add `GET /v1/accounts/{org_principal_id}/dashboard-snapshot` in `portal_stats` as a synchronous read-through aggregator**
  - The endpoint returns one envelope combining:
    - existing dashboard rollups (`dashboard-stats` payload)
    - org analytics metrics (`/accounts/{org_principal_id}/analytics` payload) for the requested window (`24h|7d|30d`, default `24h`)
  - No new cache or precomputed materialization is introduced in v1.
  - Existing endpoints remain canonical for drill-down and detailed pages.
- **Why it matters**: portal first-load currently requires multiple API calls for summary + analytics cards; this endpoint provides one-call bootstrap and reduces avoidable backend request fan-out.
- **Entitlement behavior (strict, canonical)**:
  - Snapshot endpoint requires `analytics.view`.
  - If analytics entitlement is missing, the whole request fails with `403 FEATURE_GATE` and `details.feature_key = "analytics.view"`.
- **Architecture boundary decision**:
  - Endpoint ownership stays in `portal_stats` (cross-domain read module per D-068).
  - `portal_stats` integrates analytics via explicit `app.modules.analytics.public` helpers (no cross-module service/db internal imports).
- **Impacted docs**:
  - `docs/architecture/api_contract/03_orgs_sites_portal.md`
  - `docs/architecture/api_contract/13_analytics.md`
  - `docs/architecture/design/aggregated_statistics_endpoints_v1.md`
  - `docs/architecture/jila_api_backend_api_contract_v1.md`

---

## 3. Working method (how we'll resolve)

For each decision D-XXX, we will:
1) Mark it **DECIDED** and write the chosen option.
2) Add a short justification (1–3 bullets).
3) Update the relevant canonical docs to reference the decision (and remove alternative options).
