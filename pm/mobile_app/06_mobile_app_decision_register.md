# Jila Mobile App — Decision Register (Anti-ambiguity) (v0.1)

Purpose: track the **open decisions** required to ship the mobile app v1 without drift, including forced choices on UX, assets, libraries, and any product/contract gaps.

Principle: once a decision is marked **DECIDED**, other docs/tickets must reference it and must not re-introduce alternate options.

---

## 0) Canonical “single source of truth” map (do not drift)
- Decision register index (platform split): `../../decision_registers/00_index.md`
- **Mobile PRD**: `./05_mobile_app_prd.md`
- **Mobile feature scope**: `./03_feature_requirements_document.md`
- **Journeys + guardrails**: `./02_user_journey_maps.md`
- **Offline baseline**: `./07_offline_mode_and_sync_specification.md`
- **Notifications baseline**: `./08_notification_and_alert_strategy.md`
- **Language/accessibility**: `./09_localization_and_accessibility.md`
- **Inclusive design addendum**: `./10_inclusive_design_guidelines.md`
- **Global UX guardrails index**: `../../ux/jila_application_ux_guidelines.md`
- **Backend HTTP contract (canonical)**: `../../architecture/jila_api_backend_api_contract_v1.md`
- **Scope guardrails (value prop)**: `../../architecture/jila_value_proposition_review_notes_aligned.md`
- **Design guide (canonical implementation guidance)**: `../../ux/jila_design_guide.md`

---

## 1) Product and UX decisions

### MA-001 — Default entry for unauthenticated users
- **Status**: DECIDED
- **Decision**: **Choose-path screen** as the default unauthenticated entry.
  - Primary options (v1): **Monitor my water**, **Sell water**, **Find water nearby**, **I have an invite**.
  - **No-login path**: “Find water nearby” goes straight to **Marketplace discovery** (Community default) without forcing auth or location permission.
  - **Override rules**:
    - Deep links (push/invite links) route directly to the target flow/screen.
    - If the user is already authenticated, skip the chooser and land in the role-adaptive tabs.
- **Why it matters**: preserves community/manual mode (no device) while avoiding a confusing map-first default for users who came to monitor/sell; reduces support burden by making the “what is this app for?” choice explicit.

### MA-002 — Community contributions (SupplyPoint status updates) in v1
- **Status**: DECIDED
- **Decision**: Enable **authenticated** SupplyPoint status updates in v1 (community “REPORTED” updates), with abuse controls.
- **Constraints (v1)**:
  - Requires auth; updates are **rate-limited** and may be rejected by the server.
  - Client must clearly label updates as **Reported** (vs Verified) and show **freshness** timestamps.
- **UX must-haves (v1)**:
  - SupplyPoint detail shows: current `availability_status`, evidence type (**Reported/Verified/Sensor-derived**), and `availability_updated_at`.
  - When a user submits an update, show **Saved offline → Pending sync → Synced** (or **Failed** with retry).
  - If the server rejects an update (4xx), show a clear error and keep the previous visible state (no silent drops).
- **Why it matters**: improves community usefulness while keeping spam/abuse manageable; requires explicit UI clarity to preserve trust.

### MA-003 — “Days remaining” estimation and confidence model
- **Status**: DECIDED
- **Decision (v1)**: “Days remaining” is a **risk-averse estimate** with **explicit confidence**, never false precision.
- **Minimum inputs (v1)**:
  - Reservoir: `capacity_liters`, `safety_margin_pct`, latest `level_pct` (manual or device)
  - Site: `household_size` (people served). If missing, use a conservative default and mark LOW confidence.
- **Computation (v1, conservative)**:
  - Usable liters = `capacity_liters * max(0, level_pct - safety_margin_pct) / 100`
  - Daily consumption:
    - If enough recent readings exist: derive a conservative trend (avoid optimistic extrapolation)
    - Else: use a conservative per-person/day default
  - Days remaining = `usable_liters / daily_consumption`, rounded **down** to whole days (or show “<1 day”)
- **Confidence tiers (v1)**:
  - **HIGH**: device readings or frequent manual readings + household size known
  - **MEDIUM**: household size known but sparse readings
  - **LOW**: missing household size and/or stale reading (show range or “Unknown” + next step)
- **UX rules (v1)**:
  - Always show **last updated** timestamp + confidence label
  - If LOW confidence: show a **range** (e.g. “~1–2 days”) or “Unknown”, plus a clear prompt (“Add household size” / “Update level”)
- **Why it matters**: trust + safety; incorrect estimates can cause overspend or running out.

### MA-004 — “Replenishment as a Service” entrypoint (monitoring → ordering)
- **Status**: DECIDED
- **Decision (v1)**: When the household water level reaches **20%** (low-water zone), the app must surface a **Replenishment Card** on the monitoring experience that reduces ordering to a single primary decision: **Order refill** (pre-filled, no catalog browsing).
- **Behavior (v1)**:
  - **Trigger**: when `level_pct <= 20` for the currently viewed reservoir/site, show the Replenishment Card as a bottom sheet/card that “slides up” (non-blocking; user can dismiss).
  - **Prefill**:
    - **Suggested volume**: compute a default refill amount (e.g., “You need 5,000 L”) based on reservoir capacity and current level; keep it conservative and round to supported seller increments.
    - **Seller/vehicle**: choose a “best default” option when available (closest/most reliable/available) so the user does not need to browse; allow changing on the confirmation screen.
  - **One-tap meaning**: the primary CTA takes the user **directly to a pre-filled order confirmation** (not a catalog), where **total cost is shown clearly before final confirmation** (per Journey 3 guardrails).
  - **Failure modes**:
    - If no sellers are available: show a clear empty state and fall back to “Find nearby sellers / supply points” pathways.
    - If price/availability changes during confirm: show a clear update and require re-confirmation (no silent changes).
- **UI requirements (v1)**:
  - The card must be visually distinct and urgent without being manipulative (no fake countdowns).
  - Copy must remain minimal; rely on icons/illustrations (see UX-D-032 and design guide).
- **Canonical design**: `docs/ux/jila_design_decision_register.md` (Replenishment Card pattern decisions) and `docs/ux/jila_design_guide.md` (implementation guidance).
- **Why it matters**: reduces cognitive load in urgent moments and delivers the core value proposition: replenishment without friction.

### MA-005 — Offline-first monitoring (“no panic spinner”)
- **Status**: DECIDED
- **Decision (v1)**: Monitoring experiences must remain usable under unstable connectivity:
  - **Show last known state** when refresh fails (do not hide readings behind a spinner).
  - **Always show freshness** (timestamp) for critical readings so users can judge staleness.
  - **User-driven refresh** is the primary retry mechanism (explicit refresh control), avoiding endless background retry loops that feel like “it’s broken.”
- **Canonical design**: `docs/ux/jila_design_decision_register.md` (UX-D-036/037/038) and `docs/ux/jila_design_guide.md` (Offline-first Monitoring UI).
- **Why it matters**: prevents panic (“Is my tank empty?”) and increases trust in IoT under real network conditions.

### MA-006 — Streamlined first-run onboarding (hook early, don’t overwhelm)
- **Status**: DECIDED
- **Decision (v1)**: First-run onboarding must be **short, skippable, and illustration-led** to respect user patience, literacy, and device constraints.
- **Rules (v1)**:
  - Keep onboarding to **2–3 screens** max; each screen has **one idea** and minimal text.
  - Use the canonical illustration language (Blueprints of Life / semi-abstract iconography); avoid verbose scripted prose.
  - Always provide **Skip** and land the user in a usable state quickly (time-to-first-value focus).
- **Why it matters**: reduces churn caused by long onboarding and improves comprehension across languages.

### MA-007 — Adaptive registration stance (v1-safe)
- **Status**: DECIDED
- **Decision (v1)**: Do not force “heavy registration” before value.
  - **Public exploration remains available without login** where already decided/allowed (e.g., map-first discovery per MA-030 / Journey 5).
  - For authenticated areas, keep registration **minimal and phone-first** (OTP), aligned with feature scope and backend contract (no new social login providers committed in v1).
- **Notes (v1)**:
  - “Guest monitoring with local-only data” is a potential enhancement but requires explicit v2 decision (do not imply it exists in v1).
- **Why it matters**: reduces drop-off from form friction while staying aligned to the current v1 auth contract.

### MA-008 — Progressive disclosure + education (retention)
- **Status**: DECIDED
- **Decision (v1)**: Teach by showing and introduce complexity only after early success.
- **Rules (v1)**:
  - Prefer illustrated micro-help (tooltips/coach marks) over long help text.
  - Default empty states should explain “what to do next” with minimal text + visuals (no blank screens).
  - Core navigation, labels, and icon meanings should remain stable across updates (avoid “surprise” churn).
- **Canonical design**: `docs/ux/jila_design_guide.md` (Onboarding & education patterns) and `docs/ux/jila_design_decision_register.md` (UX-D-032/044/047/048).
- **Why it matters**: early confidence builds habit; predictable UX reduces churn over time.

---

## 2) Platforms and release decisions

### MA-010 — Target platforms for v1
- **Status**: DECIDED
- **Decision**:
  - Ship mobile v1 on **Android + iOS**.
  - Minimum OS:
    - **Android**: 9.0+ (API 28)
    - **iOS**: 14+
- **Why it matters**: aligns with push notifications (FCM), reduces platform fragmentation while keeping coverage high, and avoids shipping a “split experience” where one platform misses critical order/water alerts.

### MA-011 — App distribution approach
- **Status**: DECIDED
- **Decision**: Ship directly to **Google Play Store** and **Apple App Store**.
- **Release guardrails (v1)**:
  - Use staged rollout / phased release where available to reduce blast radius.
  - Hold or roll back releases on severe crash spikes or auth/payment-blocking issues.

---

## 3) Technical/library choices (React Native)

### MA-020 — React Native framework
- **Status**: DECIDED
- **Decision**: React Native CLI (bare).
- **Why it matters**: build pipeline, native module access, and delivery speed.

### MA-021 — Navigation library
- **Status**: DECIDED
- **Decision**: React Navigation.

### MA-022 — UI/component system
- **Status**: DECIDED
- **Decision**: React Native Paper.
- **Why it matters**: accessibility defaults, theming, and consistent touch targets.

### MA-023 — Data fetching + caching
- **Status**: DECIDED
- **Decision**: TanStack React Query.
- **Why it matters**: retries, cache invalidation, and offline “stale/fresh” semantics.
- **Notes**:
  - This pairs cleanly with **Zustand** (no Redux requirement) for v1.
  - Use TanStack Query for **server-state reads** (cache + freshness UI) and keep **offline write queue** as a separate, explicit mechanism.

### MA-024 — Forms + validation
- **Status**: DECIDED
- **Decision**: **React Hook Form + Zod**.
- **v1 rules**:
  - Use Zod schemas as the single source of truth for client-side validation; keep rules aligned with the backend API contract.
  - Map backend `422 VALIDATION_ERROR` responses to **field-level** errors where possible (and show a deterministic form-level error otherwise).
  - Preserve user input on submit errors; never clear a form on failure.
  - For offline-queueable writes, show submit state as **Saved offline → Pending sync → Synced/Failed** (no silent drops).

### MA-025 — Local persistence + offline queue
- **Status**: DECIDED
- **Decision**:
  - Storage choice: MMKV for local persistence.
  - Offline queue semantics (v1):
    - **Queueable offline**:
      - Manual reservoir readings
      - Notification preferences updates
      - Non-critical profile edits (e.g., display name/avatar)
      - Supply point status updates *(only if MA-002 is enabled; still subject to rate limits and possible server rejection)*
    - **Not queueable / requires connectivity**:
      - Auth flows: registration / OTP / login / refresh
      - Order state transitions: seller accept/reject; buyer cancel; delivery confirmation
      - Seller availability/pricing changes (unless explicitly decided later)
  - UX must-haves (v1):
    - Every queued action shows **Saved offline → Pending sync → Synced** (or **Failed** with retry)
    - Sync triggers: app foreground, connectivity restored, explicit pull-to-refresh
    - Error handling: 4xx requires user action; 5xx/network retries with backoff (no spam)
- **Why it matters**: “never lose input” requirement and sync reliability.

### MA-026 — Secure storage for tokens
- **Status**: DECIDED
- **Decision**:
  - Use OS secure storage via `react-native-keychain` (iOS Keychain, Android Keystore-backed) for **refresh token + minimal session metadata**.
  - **Access token is memory-only** (never persisted).
  - **MMKV is not used for secrets** (only non-sensitive cached UI state).
- **v1 rules**:
  - Persist: refresh token.
  - Do not persist: access token (in-memory only).
  - Logout: delete refresh token from secure storage and clear in-memory access token.
  - Cold start: if refresh token exists → call refresh → hydrate in-memory access token.
  - iOS: Keychain accessibility `AFTER_FIRST_UNLOCK_THIS_DEVICE_ONLY`.
- **Why it matters**: reduces blast radius of token theft while preserving fast, reliable sessions.

### MA-027 — Push notifications stack
- **Status**: DECIDED
- **Decision**:
  - Client-side vendor: Firebase Cloud Messaging on device.
  - Categories are aligned to preference groups: `orders`, `water_risk`, `device_risk`.
  - Deep links use the v1 push payload contract (see `./08_notification_and_alert_strategy.md`).
- **Why it matters**: seller reliability and time-sensitive workflows.

### MA-029 — Alerts inbox surface (dedicated screen vs nested in Profile)
- **Status**: DECIDED
- **Decision (v1)**: Add a dedicated **`AlertsInbox`** screen in the navigation stack, but **do not add a 5th tab**.
  - Accessible from **Profile** (e.g., “Alerts” row) and via a **bell icon** entry on key screens (Home/Orders).
  - Push deep links route to `AlertsInbox` (and then to the target detail when applicable).
- **Why it matters**: makes notifications auditable and easy to find without bloating primary navigation; ensures deep links always have a stable landing surface.

### MA-030 — Community mode onboarding (map-only)
- **Status**: DECIDED
- **Decision (v1)**: “Find water nearby” is **zero-onboarding** → immediate Marketplace discovery with **Community** as the default segment.
  - Show a lightweight, dismissible hint (non-blocking) explaining:
    - the map works without location permission
    - “Use current location” is optional and requested just-in-time
- **Why it matters**: maximizes time-to-value and aligns with low-connectivity + permission-denial realities while preserving clarity.

### MA-034 — Marketplace discovery hub (Community + Sellers) and orders entrypoint
- **Status**: DECIDED
- **Decision (v1)**: Marketplace is a **combined discovery hub** that can be used without login for browsing:
  - **Segments**: Community supply points vs Sellers (default = Community).
  - **Map/List toggle** for nearby results (per MA-028 location rules).
  - **Orders**: “My orders” is accessible from Marketplace (top/header entrypoint), rather than requiring a dedicated Orders tab entry.
  - **Purchasing**:
    - Requires authentication.
    - Uses backend RBAC on `POST /v1/accounts/{account_id}/orders` with `target_reservoir_id` (an authenticated user may still be forbidden to order for a reservoir they can view).
- **Why it matters**: aligns with common marketplace patterns while preserving a strong no-login discovery path and protecting order actions behind explicit permission checks.

### MA-031 — Org functionality scope in v1 mobile
- **Status**: DECIDED
- **Decision (v1)**: Org functionality is **out of scope** for mobile v1 beyond **invite acceptance** (if/when used).
- **Why it matters**: keeps v1 mobile focused on household/seller/community value and avoids expanding permissions + navigation complexity.

### MA-032 — Water risk notifications priority (v1)
- **Status**: DECIDED
- **Decision (v1)**:
  - **CRITICAL water risk**: **P0** (push **on by default**, debounced).
  - **LOW water risk**: **P1** (in-app **on by default**; push is **opt-in**, not default).
- **Why it matters**: balances safety (critical) with notification fatigue (low), and sets stable defaults for preferences/subscription messaging.

### MA-033 — Design guide ownership (fill `docs/ux/jila_design_guide.md`)
### MA-033 — Design decisions document (separate register)
- **Status**: DECIDED
- **Decision**: Track design-system choices in a dedicated decision register: `docs/ux/jila_design_decision_register.md`.
- **Why it matters**: keeps the mobile decision register product-focused while preventing UI drift via explicit, reviewable design decisions.

### MA-028 — Maps and geolocation
- **Status**: DECIDED
- **Decision**:
  - Use **Mapbox Mobile SDK** for map rendering (React Native).
  - Use **Mapbox Search / Geocoding APIs** for address/place search (forward + reverse geocoding).
- **Location permission UX (v1)**:
  - Do **not** request location permission on first open.
  - Map discovery works without permission: default center to **Luanda** (or last-used location) and provide search/manual location.
  - Ask for permission **just-in-time** only when the user taps “Use current location”.
  - If denied, keep discovery fully usable (manual search; no blocked flows).
- **Why it matters**: community discovery + seller listing discovery are core; Mapbox across platforms enables consistent styling + interaction patterns while preserving a resilient permission UX.

- **React Native implementation options (reasoned; pick one)**:
  - **Option A (recommended)**: `@rnmapbox/maps` (Mapbox Maps SDK v10+ wrapper).
    - Pros: closest to Mapbox-native feature set (styles, vector rendering, camera controls), best chance of web↔mobile parity.
    - Cons: native setup complexity, larger binary size, Mapbox account/token configuration required.
  - **Option B**: Custom native modules wrapping Mapbox iOS/Android SDKs.
    - Pros: maximum control, smallest exposed surface area.
    - Cons: highest maintenance cost; slower iteration; requires strong native expertise.
  - **Option C (not recommended for the “consistent experience” goal)**: keep `react-native-maps` and use Mapbox tiles.
    - Pros: simpler baseline setup.
    - Cons: does **not** provide Mapbox SDK rendering parity (style layers, symbol behavior, performance characteristics).

- **Offline maps options (reasoned; decide explicitly per v1)**:
  - **Option 1 (recommended for v1)**: No offline packs; rely on standard OS/network caching; always keep list views functional.
  - **Option 2**: Limited offline packs (Luanda + last-used region), user-controlled download; adds storage + UX complexity.
  - **Option 3**: Fully offline-first maps; highest complexity, likely out of scope for v1.

- **Token + style source of truth (non-negotiable)**:
  - Use a **public Mapbox access token** restricted to the mobile app’s bundle IDs / package names.
  - Styles must be Mapbox Studio style URLs with light + dark variants shared with the web portal.

---

## 4) Backend contract alignment (mobile blockers)

### MA-040 — Push notifications delivery in v1 (product vs contract conflict)
- **Status**: DECIDED
- **Decision**: Push notifications are **in scope** for v1 and are sent server-side for action-required events, with user preferences allowing multiple channels per event (gated by subscription).
- **Why it matters**: seller flow reliability and core marketplace UX.

### MA-041 — Data needed for “trust UI” (freshness, source, confidence)
- **Status**: DECIDED
- **Decision (v1)**: Trust UI uses **API-provided freshness/source fields** where available; “confidence” is primarily **client-derived** (per MA-003), and the UI must never imply false precision.
- **Reservoirs**
  - **Freshness**: `latest_reading.recorded_at` (plus general `level_state_updated_at` when applicable)
  - **Source**: `latest_reading.source` (`MANUAL|DEVICE`)
  - **Confidence**: computed on-device (MA-003) using freshness + input completeness (household size, reading cadence)
- **SupplyPoints**
  - **Freshness**: `availability_updated_at`, `operational_status_updated_at`, `verification_updated_at`
  - **Source**: `availability_evidence_type` (`REPORTED|VERIFIED|SENSOR_DERIVED`) + `verification_status`
- **Marketplace listings**
  - **Freshness**: `seller_availability_updated_at` (and `location_updated_at` when location is dynamic)
  - **Source**: implied seller-declared availability (seller profile + availability), with timestamps used to communicate recency
- **Why it matters**: non-negotiable UX guardrails require these signals to be visible to avoid harm from stale/low-trust data.

