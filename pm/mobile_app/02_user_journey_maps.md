# Jila Mobile App — Core User Journeys (Core)

> **Status:** Condensed / low-drift reference
> 
> **Last updated:** 2025-12-20

## Purpose
Define the **few journeys that must work end-to-end** for v1. This doc focuses on outcomes, success metrics, and failure modes—without screen-by-screen scripts.

## Non-negotiable UX guardrails (aligned to `docs/ux/jila_application_ux_guidelines.md`)
- **Days remaining is an estimate**: always show freshness + confidence/data gaps; never imply false precision.
- **Avoid harm from bad estimates**: when uncertain, use conservative defaults (risk-averse) and clearly explain uncertainty.
- **Low-connectivity reality**: offline reads remain useful; user-entered data is never silently lost.
- **Ethical by default**: no dark patterns, no fake urgency, no manipulation loops.
- **Marketplace decisions are money decisions**: pricing must be transparent and choices reversible (clear recovery when availability/price changes).
- **Just-in-time permissions**: ask only when needed and the benefit is obvious.
- **Ruthless simplicity (novice-first)**: prefer single-column layouts and **one primary action per screen**; avoid deep menu hierarchies; prefer step-by-step (“wizard”) flows for complex tasks.
- **Consistency & predictability**: repeated placement of navigation elements (e.g., persistent bottom navigation) + consistent icon meaning; every tap yields immediate, visible feedback (no “did it work?” ambiguity).

## Entry paths (onboarding decisions)
- **Monitor my water** → auth → add first reservoir → see “days remaining”
- **Sell water** → auth → seller setup → become available
- **Find water nearby** → Marketplace discovery (no login for read; Community default with Map/List toggle)
- **Org invite** → accept invite → org-scoped home

## Journey 1 — Maria: first value (manual monitoring)
- **Goal**: from install/open → see “days remaining” for first reservoir.
- **Success metrics**
  - Time-to-first-value: **< 4 minutes**
  - User can explain what “days remaining” means (basic comprehension)
- **Key failure modes**
  - Too much text or forced setup before value
  - Confusing capacity/level inputs
  - Unclear whether data is saved/synced

## Journey 2 — Maria: daily check + quick update
- **Goal**: open app → see status instantly → optionally update level in < 30 seconds.
- **Success metrics**
  - “Glance” path: **< 10 seconds**
  - Update path: **< 30 seconds**
- **Key failure modes**
  - Stale data not obvious
  - Update confirmation unclear

## Journey 3 — Maria: order water
- **Goal**: decide volume → pick seller → confirm order.
- **Success metrics**
  - User sees total cost clearly before confirming
  - Order creation is safe under retry (no accidental duplicates)
- **Key failure modes**
  - Seller availability changes mid-flow
  - Unclear next state after order

## Journey 4 — Carlos: seller setup → receive order → accept/reject
- **Goal**: become available with simple pricing; reliably receive/respond to orders.
- **Success metrics**
  - Setup in **< 5 minutes**
  - New order notification is hard to miss
- **Key failure modes**
  - Notifications disabled without clear consequence
  - Pricing too complex

## Journey 5 — Joana: find water nearby (no login)
- **Goal**: open map → find a viable supply point.
- **Success metrics**
  - Map renders quickly and communicates “freshness”
  - Directions is one tap
- **Key failure modes**
  - Location permission denial breaks experience
  - Outdated status not obvious

## Journey 6 — António: accept invite → see assigned sites → update
- **Goal**: join org via invite and perform quick field updates.
- **Success metrics**
  - Invite acceptance is straightforward
  - Updates are fast and attributable
- **Key failure modes**
  - Confusion between personal vs org scope

## Cross-cutting rules
- **Offline**: reads should be useful from cache; writes should queue when safe.
- **State clarity**: saved vs syncing vs failed must be obvious.
- **Accessibility**: touch targets and clear labels are required from the start.

## Validation (what to test)
- Household: add reservoir → interpret days remaining → update level.
- Buyer: place an order → interpret order status.
- Seller: receive order → accept/reject.
- Community: find water nearby (no login).
- Offline scenarios: cached reads + queued writes + reconnect sync.

## References
- Personas/JTBD: `./01_user_personas_and_jtbd.md`
- Feature scope/priorities: `./03_feature_requirements_document.md`
- Navigation/IA: `./04_information_architecture.md`
- Offline baseline: `./07_offline_mode_and_sync_specification.md`
- Notifications: `./08_notification_and_alert_strategy.md`
- Language/accessibility/UI basics: `./09_localization_and_accessibility.md`
- UX guidelines (broad): `../../ux/jila_application_ux_guidelines.md`
