# Jila Mobile App — Contract / Docs / UX Compliance Audit
**Last updated:** 2025-12-24  
**Scope:** repo inspection only (no runtime verification)

This is a gap-focused review of the mobile app implementation vs:
- Canonical HTTP API contract: `docs/architecture/jila_api_backend_api_contract_v1.md`
- Single entry point (endpoint index + error codes + enums): `docs/architecture/jila_api_backend_api_reference_v1.md`
- Mobile PRD + decisions: `docs/pm/mobile_app/*`
- Implementable design guide: `docs/ux/jila_design_guide.md`

---

## Executive summary (high-impact gaps)

1) **API contract drift is widespread**: most feature `types.ts` shapes (and some implemented calls) do not match the canonical contract (naming, pagination, response envelopes, and required fields). This will break integration once the UI stops using placeholders.

2) **Session/token handling conflicts with MA-026**:
   - Decision says **do not persist access tokens**; current `tokenStorage` persists both access+refresh, and cold start does not refresh.

3) **Offline baseline (MA-025 / Offline spec) is not met**:
   - Reservoir reads are not persisted locally.
   - Manual readings show “Saved offline” UX, but there is **no durable offline queue**.

4) **Localization baseline is not met**:
   - Docs require pt-AO primary + externalized strings; current UI is hardcoded English and not externalized.

5) **Sensitive request logging risk**:
   - API client logs request bodies; auth calls include passwords/OTPs.

---

## API contract compliance gaps (vs `jila_api_backend_api_contract_v1.md`)

### A) Mismatched response envelopes and field names (systemic)
**Gap**
- Contract uses `items` arrays widely (e.g., `GET /v1/me/reservoirs`, `GET /v1/supply-points`, `GET /v1/accounts/{account_id}/alerts`).
- App feature types often use `{ <domain_plural>: [...] , total_count, offset }` and different id keys (`id` vs `*_id`) and location keys (`latitude/longitude` vs `lat/lng`).

**Evidence (examples)**
- Contract `GET /v1/me/reservoirs` returns `{ "items": [{ "reservoir_id": "...", "latest_reading": { "level_pct": ... } }] }`.
- `src/features/reservoirs/api/reservoirApi.ts` expects `{ items: ReservoirWithStatus[] }` and downstream UI reads `reservoir.id`, `reservoir.name`, `latest_reading.volume_liters`, etc.
- Contract `GET /v1/supply-points` returns `location: { lat, lng }` and `items`.
- `src/features/map/types.ts` expects `location: { latitude, longitude }` and `ListSupplyPointsResponse.supply_points`.

**Proposed amendments**
- Pick a single “contract boundary” approach and apply consistently:
  - **Option 1 (recommended):** align all `src/features/*/types.ts` API shapes to the contract exactly (including `items`, `*_id`, `lat/lng`), and map into UI-friendly internal models in a thin adapter layer per feature.
  - **Option 2:** update the canonical contract to match current app types. This is higher-risk because `docs/architecture/jila_api_backend_api_contract_v1.md` declares itself the single source of truth and is referenced by QA.
- Add a short “client mapping” section per endpoint (even just a table) in the app docs to prevent silent drift.

### B) Reservoirs: app requires fields not present in contract responses
**Gap**
- `ReservoirWithStatus` (used by `HomeScreen`) expects fields not present in the contract for list/detail (e.g., `name`, `reservoir_type`, `mobility`, `location`, reading `id`, `battery_pct`, etc).

**Evidence**
- Contract `GET /v1/reservoirs/{reservoir_id}` does not include `name`, `reservoir_type`, or `mobility` even though `docs/architecture/jila_api_backend_data_models.md` notes `name` is “present in API contract v1”.
- `src/features/reservoirs/screens/HomeScreen.tsx` renders `reservoir.name` and uses `latest_reading.volume_liters`.

**Proposed amendments**
- Decide whether mobile v1 needs these fields on list/detail:
  - If **yes**, update the canonical contract to include the display-critical fields (and keep `data_models.md` consistent).
  - If **no**, update app models to compute derived fields client-side where safe (e.g., `volume_liters = capacity_liters * level_pct`) and remove reliance on missing fields.
- Update `listMyReservoirs()` to map `reservoir_id → id` (or update UI to use `reservoir_id`) consistently.

### C) Alerts: app types don’t match contract, and UX requires more than contract provides
**Gap**
- Contract alerts feed is minimal (`alert_id`, `event_id`, `channel`, timestamps). App `src/features/alerts/types.ts` expects `event_type`, `title/message/icon`, counts, pagination, “resolved_at”, and preferences.

**Proposed amendments**
- Clarify the intended v1 alerts feed:
  - If the feed must be richly-rendered client-side, the contract likely needs to expose enough information to derive UI (at least `event_type`, `subject_type`, `subject_id`, and localization keys/args per the push payload strategy doc).
  - Otherwise, adjust the app’s `AlertWithDetails` to be client-enriched from a minimal contract shape.

### D) Orders + marketplace: request/response shape and idempotency drift
**Gap**
- Contract uses:
  - `GET /v1/marketplace/reservoir-listings` → `{ items: [...] }` with `seller_reservoir_id`, `estimated_total`, etc.
  - Order creation idempotency via `Idempotency-Key` header.
- App marketplace/order types expect different payloads (e.g., embedded `price_rules`, `total_count`/`offset`, and an `idempotency_key` request field).

**Proposed amendments**
- Align order idempotency to the contract header (or amend the contract to accept body idempotency keys, but pick one).
- Implement a single “orders API” module that mirrors the contract to reduce future drift.

### E) Org invite acceptance: app types don’t match contract
**Gap**
- Contract `POST /v1/org-invites/accept` uses `invite_token_id` and returns `{ user_id, status, org_id, org_principal_id, otp_sent_via }`.
- `src/features/org/types.ts` uses `invite_token` and different response fields.

**Proposed amendments**
- Update org invite types to match the contract, and keep mobile scope aligned with MA-031 (beyond invite accept is out of scope for v1 mobile unless explicitly expanded).

---

## Documentation alignment gaps

### A) Root README is not app-specific
**Gap**
- `README.md` is the default RN template; it does not document Jila-specific setup (API base URL, dev env, required fonts/assets, doc pointers).

**Proposed amendments**
- Replace with a JilaApp README that includes:
  - What the app is (roles, core journeys)
  - How to configure `apiBaseUrl` for local/dev/staging
  - Where the canonical product/contract docs live (link to `docs/pm/mobile_app/*` + API contract)

### B) Decision register vs code drift (explicit “DECIDED” items)
**Gaps**
- MA-024 (React Hook Form + Zod) not implemented (and deps are absent).
- MA-025 (MMKV + offline queue) not implemented (and deps are absent).
- MA-026 says **access token is memory-only**; app currently persists access tokens in keychain.

**Proposed amendments**
- Either:
  - update implementation to comply, or
  - explicitly revise the decision register (with rationale) so engineers don’t build on incorrect assumptions.

### C) In-code “aligned with API contract” references point to data models
**Gap**
- Several `src/features/*/types.ts` files claim alignment with the API contract but link to `docs/architecture/jila_api_backend_data_models.md`.

**Proposed amendments**
- Update comments to reference the canonical contract for HTTP shapes, and reserve `data_models.md` references for domain semantics only.

---

## UX compliance gaps (vs design guide + mobile baseline docs)

### A) Placeholder screens across major journeys
**Gap**
- Many screens are `PlaceholderScreen` stubs (alerts, map, marketplace, orders, profile settings, org flows, reservoir detail/list).

**Proposed amendments**
- Track placeholders explicitly (e.g., a checklist section in `docs/qa/e2e.md` or a dedicated “screen implementation status” doc) so “done” isn’t confused with “stubbed”.

### B) Offline baseline not implemented end-to-end
**Gap**
- Manual reading UI shows pending/offline states but does not persist a queue item.
- Reservoir data is not cached locally; offline “read local first” baseline is not met.

**Proposed amendments**
- Implement a durable queue and cached reads per `docs/pm/mobile_app/07_offline_mode_and_sync_specification.md`.
- Ensure queueable actions are explicitly blocked/allowed per the spec (auth and time-sensitive order transitions require connectivity).

### C) Localization + accessibility baseline not met
**Gap**
- Hardcoded English strings across screens; no string externalization, no locale-aware formatting.

**Proposed amendments**
- Introduce a string catalog + locale selection (pt-AO primary), and start by externalizing the core journeys’ screens (Auth + Home + UpdateLevel).

### D) Monitoring loading state uses a full-screen spinner
**Gap**
- `HomeScreen` shows a centered `ActivityIndicator` when loading with no cached data; design guidance prefers avoiding “panic spinners” on monitoring surfaces.

**Proposed amendments**
- Replace first-load full-screen spinner with a lightweight skeleton / placeholder tank with an inline “Refreshing…” indicator, while keeping the UI stable.

### E) OTP resend UX assumes delivery
**Gap**
- Contract notes anti-enumeration and cooldown behaviors for OTP request endpoints (`otp_sent_via` can be `null`); current UX treats resend as always successful.

**Proposed amendments**
- Show a neutral confirmation (“If eligible, we sent a code”) and only reset cooldown when the API indicates a send was queued.

---

## Quick “next steps” (recommended sequence)

1) **Decide the source of truth for HTTP shapes**: contract vs current app types, then align one way end-to-end.
2) Fix **token/session handling** to comply with MA-026 (refresh token persisted; access token memory-only; cold start refresh).
3) Implement the **offline queue + cached reads** baseline for Reservoirs (and ensure UX states are truthful).
4) Add **localization scaffolding** and remove hardcoded strings from the first shipped journey.
5) Implement the **AlertsInbox** minimal experience (feed + mark read) and wire up the bell entry/badge.

---

## Addendum (UI team handoff) — Seller Mode (Buyer ↔ Seller switch) (Drafts-driven)

This addendum is **not** a full redesign request. It is a targeted extension to the existing HTML mocks under `drafts/` so the UI team can add the missing **seller** surfaces in a consistent way.

### A) Product rule (non-negotiable)
- The app operates in a **single active marketplace context** at a time:
  - **Buyer mode**: discover sellers, place orders, cancel buyer orders.
  - **Seller mode**: manage availability/pricing, view incoming orders, accept/reject orders.
- A user **cannot be buyer and seller at the same time**. They must **switch modes**.

### B) Where the mode switch lives (starting point)
- The **Profile screen** is the primary entry point for switching contexts.
- UI requirement: add a **Buyer ↔ Seller toggle** in Profile settings (a single switch is acceptable).
- Switching to Seller should clearly warn: “You can accept/manage orders, but you cannot place orders until you switch back.”

Reference (implemented in-app):
- The Profile settings now include a mode switch and Seller mode routes the Marketplace tab to a seller dashboard.

### C) Draft assets to add (incremental, do not rewrite existing mocks)
Using the existing buyer-focused mocks as the baseline (`drafts/marketplace.html`, `drafts/orders.html`, `drafts/order-detail*.html`, `drafts/profile.html`), please add:

1) **Profile — Mode toggle**
- Update `drafts/profile.html` to include:
  - a “Marketplace mode” row
  - right-side switch + state label (Buyer/Seller)
  - microcopy indicating mutual exclusivity

2) **Seller Dashboard (Marketplace tab in Seller mode)** *(new file recommended)*
- Add `drafts/seller-dashboard.html` (or equivalent) with sections:
  - **Seller status** (Active / Needs setup)
  - **Availability** quick action
  - **Pricing** quick action
  - **Orders** entrypoint (seller view)
  - Hint to switch back via Profile to place orders as buyer

3) **Seller availability** *(new file or extend existing patterns)*
- Add `drafts/seller-availability.html`:
  - list of reservoirs the seller can serve
  - per-reservoir availability toggle (Available / Unavailable)
  - “Saved / Saving / Failed” state placement

4) **Seller pricing** *(new file)*
- Add `drafts/seller-pricing.html`:
  - pricing rules UI (keep it simple; presets + editable fields)
  - error states + confirmation state

5) **Seller orders list** *(either a new file OR a seller-state variant of existing)*
- Add `drafts/seller-orders.html` OR extend `drafts/orders.html` with a clear “Seller mode” variant:
  - list of orders that require action (CREATED) at the top
  - status chips consistent with existing visual language
  - each order has a clear “Review” entrypoint

6) **Seller order detail (accept/reject)** *(extend existing order detail mock)*
- Extend `drafts/order-detail.html` (or create `drafts/seller-order-detail.html`) to include:
  - seller action panel when status is CREATED: **Accept** + **Reject**
  - clear disabled state when already acted upon

### D) Key UX states to show in the drafts (so engineering can build safely)
- **Mode gating**:
  - If user is in Seller mode and taps “Order water”: show a blocking message and a CTA to go to Profile and switch to Buyer.
  - If user is in Buyer mode and taps seller tools: show a blocking message and a CTA to go to Profile and switch to Seller.
- **Order action gating**:
  - **Accept/Reject** only in **Seller mode**
  - **Create/Cancel** only in **Buyer mode**
- **Seller setup gating**:
  - If user switches to Seller mode without an active seller profile, show “Complete setup” and route to seller setup flow.

### E) Asset/UI questions for the UI team (answering now reduces churn)
- What visual treatment distinguishes **Buyer vs Seller mode** (badge in header? chip in Marketplace tab?) without adding clutter?
- For seller orders: do we need a dedicated “New” queue section (CREATED) separate from “Active”?
- For pricing: are we designing **flat per-liter pricing**, **tiers**, or **fixed fee + per-liter** for v1 mocks?
