# Jila Mobile App (React Native) — Product Requirements Document (v1)

> **Status:** Draft (condensed / low-drift reference)<br>
> **Last updated:** 2025-12-20<br>
> **Decision register:** `../../decision_registers/mobile_app_decision_register.md`<br>
> **Canonical backend contract:** `../../architecture/jila_api_backend_api_contract_v1.md`

## 1) Purpose
Define a single, stable PRD for the **mobile app v1** that delivers Jila’s core value proposition (“days of autonomy”, marketplace ordering, and trust-first monitoring) using the supporting docs in this folder as sources of truth.

## 2) Sources of truth (do not drift)
- Personas + JTBD: `./01_user_personas_and_jtbd.md`
- Core journeys + guardrails: `./02_user_journey_maps.md`
- Feature scope/priorities: `./03_feature_requirements_document.md`
- Information architecture: `./04_information_architecture.md`
- Offline baseline: `./07_offline_mode_and_sync_specification.md`
- Notifications baseline: `./08_notification_and_alert_strategy.md`
- Language/accessibility/UI basics: `./09_localization_and_accessibility.md`
- Inclusive design addendum: `./10_inclusive_design_guidelines.md`
- Frontend ↔ API handoff checklist (screen→endpoint map): `./12_frontend_api_handoff_checklist_v1.md`
- Global UX guardrails index: `../../ux/jila_application_ux_guidelines.md`
- Value proposition guardrails: `../../architecture/jila_value_proposition_review_notes_aligned.md`
- Backend contract (endpoints/error semantics): `../../architecture/jila_api_backend_api_contract_v1.md`

## 3) Goals (v1)
- **Household reliability**: manual-first reservoir monitoring that makes “days remaining” understandable and safe.
- **Marketplace**: simple, transparent ordering and seller response flows that work under unreliable connectivity.
- **Community discovery**: map-first read-only discovery without forcing account creation.
- **Trust + safety**: freshness, source, and uncertainty are always visible; avoid harm from bad estimates.
- **Offline resilience**: cached reads are useful; supported writes are never silently lost.

## 4) Non-goals (v1)
- In-app payments, chat, live tracking maps, complex pricing tiers, heavy analytics UI, pixel-perfect scripted onboarding prose.
- “Utility-grade evidence packs” exports (Phase B), beyond keeping UX and data capture consistent with later readiness.

## 5) Target users (v1)
Aligned to `./01_user_personas_and_jtbd.md`:
- Household water manager (manual-first; device later).
- Seller (tanker/fixed) responding to nearby demand.
- Community user (read-only discovery; optional contribution with login).
- Org field operator (invited user; org-scoped quick updates).

## 6) Core journeys (v1)
These are the required end-to-end behaviors; details and failure modes live in `./02_user_journey_maps.md`.
- Maria: first value (add reservoir → see “days remaining”).
- Maria: daily check + quick update.
- Maria: place an order safely (idempotent retries; clear next state).
- Carlos: seller setup → receive order → accept/reject.
- Joana: find water nearby (no login).
- António: accept invite → org-scoped home → quick update.

## 7) Information architecture (v1)
Use `./04_information_architecture.md` as the stable navigation model: role-adaptive tabs (Home, Marketplace, Map, Profile) plus deep links from notifications.

## 8) Requirements (v1)
Priority semantics come from `./03_feature_requirements_document.md`. This PRD restates only what’s needed to turn the scope into buildable product work.

### 8.1 Authentication & sessions
- Register/login/logout; safe refresh handling (15-minute access TTL; refresh rotation).
- Org invite acceptance flow and post-accept verification UX.

### 8.2 Reservoirs & monitoring
- Create/list reservoirs; reservoir detail with latest reading and freshness.
- Manual reading submission (queueable offline).
- “Days remaining” presented as a **risk-averse estimate** with **explicit confidence tiers** and clear next steps when uncertain (see **MA-003**).

### 8.3 Community discovery (public read)
- Supply points map/list + detail that works without login.
- Optional authenticated status update contribution (rate-limited).

### 8.4 Seller mode + marketplace
- Seller profile create/update; availability toggle; simple price rules.
- Public discovery of seller listings; buyer volume selection and price transparency.

### 8.5 Orders
- Create order; list/detail; seller accept/reject; cancel (if supported); confirm delivery (idempotent).
- Clear “next state” after each action; safe retry semantics to prevent duplicates.

### 8.6 Alerts & notifications
- In-app alerts feed; mark read; deep links into relevant screens.
- Push/SMS strategy as defined in `./08_notification_and_alert_strategy.md` (subject to backend delivery decisions; tracked in the decision register).

### 8.7 Offline & sync (baseline)
As defined in `./07_offline_mode_and_sync_specification.md`:
- Read local-first with explicit stale UI.
- Queue low-risk writes (manual readings, some preference updates); sync on reconnect/foreground.
- Block connectivity-required flows (auth; time-sensitive seller accept/reject).

### 8.8 Localization & accessibility
As defined in `./09_localization_and_accessibility.md` and `./10_inclusive_design_guidelines.md`:
- Portuguese-first (pt-AO), English second; all strings externalized.
- **Body text**: WCAG 2.1 **AAA (≥ 7:1)** (outdoor readability), with **Solar Mode** high-contrast light theme support as specified in `./09_localization_and_accessibility.md`.
- **Other UI**: WCAG 2.1 **AA minimum**; 48×48dp targets; icon+label pairing for key actions; plain-language copy.

## 9) Non-functional requirements (v1)
- **State clarity**: saved/saving/pending sync/failed always visible where it matters.
- **Performance**: fast “glance” paths (home/orders) with cached data and progressive refresh.
- **Security**: protect tokens/PII in platform secure storage; avoid risky persistence patterns.
- **Ethics**: no dark patterns; no fake urgency; transparent pricing and uncertainty.

## 10) Success metrics (v1)
From the journeys, v1 is successful when:
- Time-to-first-value (Maria) < **4 minutes**.
- “Glance” status check < **10 seconds**; update reading < **30 seconds**.
- Seller setup < **5 minutes**; new order is hard to miss.
- “Find water nearby” works without login and without location permission (with graceful fallback).
- Low rate of “lost data” reports (offline/save clarity).

## 11) Open questions (tracked as decisions)
See `../../decision_registers/mobile_app_decision_register.md`.

