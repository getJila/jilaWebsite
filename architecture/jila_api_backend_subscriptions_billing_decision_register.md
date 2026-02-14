## Jila API Backend — Subscriptions & Billing Decision Register (v0.1)

Purpose: track the **open and decided** items required to implement subscription plans, renewals, entitlements, and
auditable payment recording without turning Jila into a billing engine.

Principle: once a decision is marked **DECIDED**, other docs and code must reference it and must not re-introduce
alternate options.

---

## 0) Canonical “single source of truth” map (anti-drift)

- **HTTP API contract** (routes + shapes): `docs/architecture/jila_api_backend_api_contract_v1.md`
  - Subscriptions section: `docs/architecture/api_contract/10_subscriptions.md`
  - Global error conventions: `docs/architecture/api_contract/01_global_conventions.md`
- **Backend decision register** (global): `docs/architecture/jila_api_backend_decision_register.md`
  - Plan gating HTTP semantics: **D-003** (`403 FEATURE_GATE`)
  - Entitlement scope for alerts: **D-020** (owner principal pays)
  - Feature key namespace for alerts: **D-023** (`plans.config.features`)
- **Database schema source of truth**: `docs/architecture/jila_api_backend_data_models.md`
  - Tables: `plans`, `subscriptions`
- **Outbox / events contract**: `docs/architecture/jila_api_backend_state_and_history_patterns.md`

---

## 1) Minimum architecture (must implement, regardless of MVP variant)

### 1.1 Subscription Plan

Represents what can be purchased and what it unlocks.

Required conceptual fields:
- `price`
- `currency`
- `billing_period` (e.g. monthly)
- `limits` (quantitative caps where applicable)
- `features` (boolean gates; evaluated server-side; canonical location today is `plans.config.features`)
- `credit_policy` (credit-based entitlements; supports pay-as-you-go and/or “credits included per renewal”)
- `credit_policy` (credit-based entitlements, to support pay-as-you-go and/or “credits included per period”)

### 1.2 Subscription

Represents a customer/org’s active entitlement window.

Required conceptual fields:
- `account_principal_id` (customer/org container)
- `status`
- `current_period_start` / `current_period_end`
- `grace_until` (optional grace window after expiration)

### 1.3 Entitlements

The evaluated “what’s unlocked” view that services use.

Non-negotiables:
- Evaluated **server-side** (never trusted from clients).
- Gating response semantics follow **D-003** (`403 FEATURE_GATE` with `details.feature_key`).
- For resource-owned features (e.g., alerts), entitlement scope follows **D-020** (owner principal).

### 1.4 Payment Attempt

Auditable record of a payment/renewal action (even if entered manually).

Required conceptual fields:
- `provider` (nullable for manual entry MVP)
- `reference` (human/operator reference string; optional for manual entry)
- `status` (attempt lifecycle)
- `raw_payload` (e.g., webhook/callback payload; for manual entry MVP can store operator form payload)
- `idempotency_key` (to make “pay → extend” safe under retries)

---

## 2) Current state (as implemented / canonical today)

### 2.1 What exists today

- `plans` table exists with `config jsonb` and canonical `config.features` mapping `feature_key -> bool`.
- `subscriptions` table exists and links `account_principal_id` to `plan_id` and `status`, with optional `starts_at/ends_at`.
- User-facing endpoints exist for subscription summary and plan selection:
  - `GET /v1/accounts/{account_id}/subscription`
  - `PATCH /v1/accounts/{account_id}/subscription`

### 2.2 Gaps vs the minimum architecture

- Plan pricing/billing-period/limits are not modeled (only `config.features` is canonical).
- Subscription “current period” and “grace” semantics are not explicitly modeled.
- No payment attempt table exists.
- Outbox events for subscription changes are referenced in flow diagrams and event catalog
  (`SUBSCRIPTION_UPGRADED`, `SUBSCRIPTION_DOWNGRADED`) but must be verified/implemented consistently.

---

## 3) MVP goals (subscription billing foundation)

- Enforce plan limits reliably (server-side, deterministic).
- Support manual renewals: **pay → extend** (no provider integration initially).
- Keep it simple: few tables, few states, auditable changes (prefer outbox events for history).
- Preserve existing v1 posture: **no checkout UX** and **no payment provider coupling** in Phase A/B
  (see decision register + implementation plan scope guardrails).

---

## 4) Open decisions (must be resolved before implementation criteria are finalized)

### SB-001 — Where do plan economics live? (schema shape)
- **Status**: DECIDED
- **Decision needed**:
  - **Option A**: Add explicit columns on `plans` (e.g., `price`, `currency`, `billing_period`, `limits` JSONB), keep
    `config.features` for boolean gating.
  - **Option B**: Store economics + limits in `plans.config` (single JSON contract), validated in code on write and read.
  - **Option C**: Separate `subscription_plans` table (avoid overloading `plans`) and migrate consumers.
- **Why it matters**: impacts migrations, admin editing, validation, and how reliably we can enforce limits at runtime.
- **Decision**: **Option A** — economics are explicit queryable columns on `plans`, keep `plans.config.features` for gating.
- **Decision date**: 2026-01-07
- **Notes**:
  - This supports admin UI editing, reporting, and deterministic enforcement without relying on ad-hoc JSON parsing.

### SB-002 — Subscription period model (current_period vs starts/ends)
- **Status**: DECIDED
- **Decision needed**:
  - **Option A**: Treat `subscriptions.starts_at/ends_at` as the authoritative current period boundaries, and rename in docs
    only (no DB rename).
  - **Option B**: Add explicit `current_period_start/current_period_end` and keep `starts_at/ends_at` for historical
    semantics.
- **Why it matters**: determines how renewal extension is implemented and how “active now” is computed.
- **Decision**: **Option A** — reuse `subscriptions.starts_at/ends_at` as the authoritative current period boundaries.
- **Decision date**: 2026-01-07

### SB-003 — Grace semantics
- **Status**: DECIDED
- **Decision needed**:
  - **Option A**: Add `grace_until` (timestamptz) and treat subscription as entitled until `max(ends_at, grace_until)`.
  - **Option B**: No grace in v1; entitlement ends strictly at `ends_at`.
- **Why it matters**: UX and enforcement correctness during late/manual payment windows.
- **Decision**: **Option A** — add `grace_until` and treat entitlement as valid until `max(ends_at, grace_until)`.
- **Decision date**: 2026-01-07

### SB-004 — Payment attempt status enum (minimal states)
- **Status**: DECIDED
- **Decision needed** (suggested minimal):
  - `RECORDED` (manual entry accepted)
  - `APPLIED` (subscription period extended)
  - `VOIDED` (operator error reversal without deleting)
  - Future: `PENDING`, `FAILED` (for provider async flows)
- **Why it matters**: ensures auditability while keeping state machine small.
- **Decision**: Keep the minimal state set (`RECORDED`, `APPLIED`, `VOIDED`) and reserve `PENDING/FAILED` for provider flows.
- **Decision date**: 2026-01-07

### SB-005 — Idempotency key scope for “pay → extend”
- **Status**: DECIDED
- **Decision needed**:
  - **Option A**: Unique on `(account_principal_id, idempotency_key)`.
  - **Option B**: Unique on `idempotency_key` globally.
- **Why it matters**: prevents double-extension on retries; impacts admin tooling and provider webhooks later.
- **Decision**: **Option A** — uniqueness scoped to the account principal: `(account_principal_id, idempotency_key)`.
- **Decision date**: 2026-01-07

### SB-006 — How are limits expressed and enforced?
- **Status**: DECIDED
- **Decision needed**:
  - **Option A**: Limits live in plan config and are checked synchronously at write-time (preferred), with deterministic
    `403 FEATURE_GATE` (boolean gates) or `409 RESOURCE_CONFLICT` / `422 VALIDATION_ERROR` for quantitative limits.
  - **Option B**: Limits are “soft” and only displayed (not enforced) in v1.
- **Why it matters**: correctness + trust; “reliable enforcement” requires deterministic, server-side checks.
- **Decision**: **Option A** — hard enforce limits server-side (not “display-only”).
- **Decision date**: 2026-01-07

### SB-007 — Admin surface for manual renewals (API + UI scope)
- **Status**: DECIDED
- **Decision needed**:
  - **Option A**: Admin API supports manual renewals; admin UI supports it later (backend-only first).
  - **Option B**: Admin UI supports manual renewals in v1.
- **Why it matters**: scope and delivery sequencing.
- **Decision**: **Option B** — admin UI supports manual renewals in v1.
- **Decision date**: 2026-01-07

### SB-008 — Credit model (pay-as-you-go / credit-based payments)
- **Status**: DECIDED
- **Decision needed**:
  - **Option A**: Credit ledger (append-only) with a computed balance per `account_principal_id`.
  - **Option B**: Single balance column on a `account_credits` table (mutating), with audit-only via outbox events.
- **Why it matters**: affects auditability, reversals/voiding, and correctness under retries.
- **Decision**: **Option A** — use an append-only credit ledger with a computed balance per `account_principal_id`.
- **Decision date**: 2026-01-07

### SB-009 — Billing period options (monthly/yearly vs pay-as-you-go)
- **Status**: DECIDED
- **Decision needed**:
  - **Option A**: Plans can be `MONTHLY` or `YEARLY`; pay-as-you-go is modeled as “credit top-ups” (not a plan).
  - **Option B**: Plans can be `MONTHLY`, `YEARLY`, or `PAYG_CREDITS` (a plan whose “renewal” is only credit top-ups).
  - **Option C**: Plans stay as they are (`monitor/protect/pro`) and billing cadence is configured per subscription, not plan.
- **Why it matters**: determines how to reason about “subscription is paid in principle” while still supporting credit usage.
- **Decision**: **Option A** — subscriptions are `MONTHLY` or `YEARLY`; pay-as-you-go is modeled via credit top-ups (not a plan).
- **Decision date**: 2026-01-07
- **Implementation note (anti-ambiguity)**:
  - v1 `plan_id` is currently fixed (`monitor|protect|pro`). To support monthly vs yearly without multiplying plan ids,
    store both monthly and yearly plan economics (price/credit grant) on the plan row, and store the chosen billing period
    on the subscription.

### SB-010 — Manual payment application semantics (what “pay” does)
- **Status**: DECIDED
- **Decision**: A manual payment entry **extends the subscription period and grants credits** in the same operation.
- **Decision date**: 2026-01-07

### SB-011 — Credit grant amount per payment (how many credits are added)
- **Status**: DECIDED
- **Decision needed**:
  - **Option A**: Credits granted are defined by the plan + billing period (e.g., `credits_per_month`, `credits_per_year`).
  - **Option B**: Admin enters the credit grant amount explicitly per payment (free-form).
  - **Option C**: Both: default from plan, with an optional admin override (override is auditable).
- **Why it matters**: avoids ambiguity around “pay extends + adds credit” and prevents inconsistent operator behavior.
- **Decision**: **Option C** — default credits are defined by plan + billing period, with an optional auditable admin override.
- **Decision date**: 2026-01-07

### SB-012 — Credit unit + currency constraints
- **Status**: DECIDED
- **Decision needed**:
  - **Option A**: Credits are monetary and stored in the plan currency minor units (single-currency per tenant).
  - **Option B**: Credits are “abstract units” not tied to currency (requires separate pricing policy).
- **Why it matters**: affects reporting, reconciliation, and future provider integration.
- **Decision**: **Option B** — credits are abstract units not tied to currency.
- **Decision date**: 2026-01-07

### SB-013 — Credit balance underflow policy
- **Status**: DECIDED
- **Decision**: Credits must **never** go negative. Any debit that would underflow is rejected deterministically.
- **Decision date**: 2026-01-07
- **Why it matters**: avoids debt/collections semantics in v1 and keeps enforcement simple and reliable.

### SB-014 — Default subscription policy (single org model)
- **Status**: DECIDED
- **Decision**:
  - All org principals default to `monitor` (baseline plan) when their subscription is first materialized.
  - Upgrades select `protect` or `pro`.
- **Decision date**: 2026-01-07
- **Implementation note (anti-ambiguity)**:
  - Subscriptions are org-principal only; user principals do not carry subscriptions.

### SB-015 — Onboarding plan selection
- **Status**: DECIDED
- **Decision**: Onboarding supports `plan_id ∈ {monitor, protect, pro}` and `billing_period ∈ {MONTHLY, YEARLY}`.
- **Decision date**: 2026-01-07
- **Notes**:
  - Trial windows are plan-agnostic.

### SB-016 — Business trial policy (admin override)
- **Status**: DECIDED
- **Decision**: Business subscriptions may have a trial window, and the **admin UI can override** the trial length per org.
- **Decision date**: 2026-01-07
- **Why it matters**: supports sales/support workflows without requiring billing provider integration.

### SB-017 — Default business trial length (days)
- **Status**: DECIDED
- **Decision needed**:
  - Choose a tenant default (e.g., 0 / 7 / 14 / 30 days).
  - Confirm allowed override bounds (min/max days) to keep admin actions safe and deterministic.
- **Why it matters**: required for consistent onboarding behavior when no explicit override is provided.
- **Decision**: Default business trial is **14 days**, and admin UI can override within **0–90 days** (inclusive).
- **Decision date**: 2026-01-07

---

## 5) Non-negotiable invariants (must be enforced by DB constraints + service logic)

- Entitlement evaluation is server-side; clients never provide “is_entitled”.
- Feature-gated endpoints return `403 FEATURE_GATE` with `details.feature_key` (D-003).
- Subscription period extension is idempotent (no double-extension on retries).
- All meaningful subscription state changes emit exactly one outbox event in the same transaction (D-017).
- No secrets in logs; raw payloads are stored in DB for audit only and never echoed to clients.
