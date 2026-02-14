# Jila Web Portal (React) — Product Requirements Document (Phase A / v1)

> **Status:** Draft (condensed / low-drift reference)<br>
> **Last updated:** 2025-12-20<br>
> **Decision register:** `../../decision_registers/web_portal_decision_register.md`<br>
> **Canonical backend contract:** `../../architecture/jila_api_backend_api_contract_v1.md`

## 1) Purpose
Deliver the portal portion of Jila’s value proposition: **multi-site monitoring + operational clarity** for organizations (HQ + field operators), aligned to:
- Scope guardrails: `../../architecture/jila_value_proposition_review_notes_aligned.md`
- Global UX guardrails: `../../ux/jila_application_ux_guidelines.md`
- Mobile v1 product foundations (shared concepts + vocabulary): `../mobile_app/*`

## 2) Goals (Phase A / v1)
- **Org visibility**: an org can see all its sites/reservoirs, spot risk quickly, and act.
- **Operational workflow**: invite users, assign site scope, and support auditable updates (manual readings).
- **Device + health awareness**: view pairing status and basic device config state for org reservoirs.
- **Trust-first UX**: freshness/uncertainty is always visible; no false precision; no dark patterns.

## 3) Non-goals (Phase A / v1)
- **Evidence packs / exports / advanced analytics** (Phase B; keep “export readiness” in data + UI structure only).
- **In-app payments, billing UI, or checkout flows** (subscription updates are backend-driven).
- **Real-time tracking maps, chat, or dispatch/routing** for sellers.
- **Full admin console** (beyond minimal “org bootstrap” by allowed users).

## 4) Target users (portal primary)
Portal maps to backend RBAC (`OWNER|MANAGER|VIEWER`) and scoped grants (org/site/reservoir) as defined in the backend docs/contract.

### 4.1 Personas (portal)
- **Org Owner / Manager (HQ)**: set up org, sites, reservoirs; invite staff; monitor risk; review alerts.
- **Field operator**: see assigned sites; submit quick, attributable updates; work under intermittent connectivity.
- **Viewer (stakeholder)**: read-only visibility into status and alerts.

### 4.2 Shared vocabulary (do not drift)
Use the controlled terms from `../mobile_app/09_localization_and_accessibility.md` (e.g., “Reservatório”, “Dias restantes”, “Encomenda”) and keep portal copy consistent with mobile.

## 5) Core journeys (Phase A / v1)
These are outcomes and failure modes, not screen-by-screen scripts.

### Journey A — Org bootstrap (Owner)
Goal: create an org and first site/reservoir, then invite a user.
- Success: Owner reaches a meaningful dashboard in **< 10 minutes**.
- Failure modes: unclear scope/roles; invite acceptance confusion; “did it save?” ambiguity.

### Journey B — Multi-site overview (HQ)
Goal: quickly see what’s at risk and what’s stale, and drill into a site/reservoir.
- Success: “glance” path **< 15 seconds** to find at-risk reservoirs.
- Failure modes: stale data not obvious; false precision (“days remaining” treated as exact).

### Journey C — Field update (Operator)
Goal: find an assigned reservoir and submit a manual reading fast.
- Success: submit reading in **< 60 seconds** after navigation.
- Failure modes: accidental data loss on connectivity issues; confusing confirmation/next state.

### Journey D — Device status check (Owner/Manager)
Goal: see which reservoirs have devices attached and whether config is applied.
- Success: pairing/config state is understandable without backend jargon.
- Failure modes: unclear detach/attach rules; ambiguous errors.

### Journey E — Alerts review (All)
Goal: read alerts, understand why they fired, and mark as read.
- Success: alerts are actionable, low-noise, and include a clear target (site/reservoir/order where applicable).
- Failure modes: alert spam; unclear call-to-action; missing context.

## 6) Information architecture (portal)
Proposed left-nav (final structure is a decision):
- **Overview** (org-level risk + freshness)
- **Sites** (list + detail)
- **Reservoirs** (list + detail + readings)
- **Devices** (pairing + config visibility)
- **Alerts** (feed)
- **Users & access** (invites, revoke, scopes)
- **Settings** (profile, language, notification preferences; subscription view-only)

## 7) Requirements
Priority definitions match mobile PM docs (`P0` must-have, `P1` quality/safety, `P2+` future).

### 7.1 Authentication & session handling
- **P0**
  - Login, refresh, logout using backend semantics (15-minute access TTL; refresh rotation).
  - Support org invite acceptance entry flow (public) and subsequent verification UX.
  - Show clear, safe error states using the backend error contract (`error_code`, `message`).
- **P1**
  - “Session expired” recovery UX (no data loss; return user to intended route after refresh).

### 7.2 Org, sites, and access management
- **P0**
  - Create org (policy-gated as needed by backend).
  - Create/list/edit/delete sites (respect conflict errors when sites have reservoirs).
  - Invite users with role + optional site scoping; show invite expiry.
  - Revoke user access (idempotent).
- **P1**
  - Display effective scope (which sites/reservoirs a user can access) in a human-readable way.

### 7.3 Reservoir monitoring and manual readings
- **P0**
  - List reservoirs visible to the user (across scopes).
  - Reservoir detail: capacity, monitoring mode, thresholds, latest reading, and freshness.
  - Submit manual readings; show confirmation and “pending/saved/failed” clearly.
  - Readings history (paginated) for basic trend review.
- **P1**
  - Edit reservoir attributes (name/capacity/safety margin) with safe validation.

### 7.4 Device pairing and configuration visibility
- **P0**
  - View device attachment state per reservoir (where available via API).
  - Support attach/detach flows and surface `409` conflicts clearly (paired rules).
  - View desired/applied device config state.
- **P1**
  - Safe UI for setting desired config (behind role gates), if required for Phase A operations.

### 7.5 Alerts (in-app feed)
- **P0**
  - List alerts and mark-read.
  - Deep link from an alert to the relevant portal context (reservoir/site/order where applicable).
- **P1**
  - Notification preferences UI (client-side only reflects server capabilities/entitlements).

### 7.6 UX guardrails (non-negotiable)
Aligned to `../../ux/jila_application_ux_guidelines.md` and mobile core docs:
- **“Days remaining” is an estimate**: always show freshness + confidence/data gaps; avoid false precision.
- **Avoid harm from bad estimates**: conservative defaults when uncertain; clearly explain uncertainty.
- **State clarity**: saved/saving/pending sync/failed is always visible where it matters.
- **Ethical by default**: no manipulation loops, fake urgency, or hidden costs.
- **Money decisions are money decisions**: pricing transparency and reversible choices in any ordering UX.
- **Just-in-time permissions**: ask only when benefit is obvious (e.g., location for map).

### 7.7 Localization & accessibility
- **P0**
  - Portuguese (pt-AO) first; English second; all strings externalized.
  - WCAG 2.1 AA baseline for core portal UI; do not rely on color alone.
  - Plain-language copy and icon+label pairing for key actions (inclusive design addendum).
- **P1**
  - High-contrast mode and broader inclusive design enhancements (decision + design system dependent).

## 8) Dependencies (Phase A / v1)
- Backend endpoints and semantics are defined in `../../architecture/jila_api_backend_api_contract_v1.md` (do not re-state payloads here).
- Portal scope is constrained by Phase A guardrails in `../../architecture/jila_value_proposition_review_notes_aligned.md`.
- Design system and assets are pending decisions (see `../../decision_registers/web_portal_decision_register.md`).

### 8.1 Known contract gaps (must resolve or de-scope)
Portal UX needs a few “list/detail” surfaces that must be explicit in the v1 contract (not invented by the UI).

Status:
- **Org members + invites listing**: **DECIDED** (D-035; see API contract).
- **Site detail retrieval**: **DECIDED** (D-033; see API contract).
- **Reservoir list display fields + trust signals**: **DECIDED** (D-036; see API contract).

Canonical tracking: `../../decision_registers/web_portal_decision_register.md` (WP-070/071/072) and the backend contract `docs/architecture/jila_api_backend_api_contract_v1.md`.

## 9) Success metrics (v1)
- Time-to-first-org-dashboard (Owner) < **10 minutes**.
- “Find at-risk reservoir” (HQ) < **15 seconds** in usability test.
- “Submit manual reading” (Operator) < **60 seconds** end-to-end.
- Support burden: low rate of “where did my data go?” reports (state clarity / sync clarity).

## 10) Open questions (tracked as decisions)
See `../../decision_registers/web_portal_decision_register.md` for the canonical list of gaps/choices (scope, UI system, auth storage, maps/charts, offline strategy, and exports readiness).
