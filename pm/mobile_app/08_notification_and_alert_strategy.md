# Jila Mobile App — Notifications & Alerts (Core)

> **Status:** Condensed / low-drift reference
> 
> **Last updated:** 2025-12-20

## Purpose
Define **what we notify**, **who we notify**, and **how we avoid spam**.

## Principles
- Notifications must be **actionable** and reduce emergencies.
- Default to **quiet** except for truly time-sensitive cases.
- Respect **user preferences** and debouncing.

## Channels (v1)
- **Push**: time-sensitive notifications.
- **In-app feed**: always available as a record.
- **SMS**: only for critical alerts and only when explicitly enabled (and plan allows).

## What we notify about (v1)
- **Orders (P0)**
  - New order for seller
  - Order accepted/rejected
  - Delivery confirmed
- **Water risk (P1 unless explicitly promoted to P0)**
  - Low and critical water alerts (debounced)
  - “Update level” reminder when very stale

## Defaults (v1)
- Push: **on** for orders.
- Water critical: **on** (P0); water low: **push opt-in** (P1; in-app on by default) — see **MA-032**.
- Quiet hours: **off by default**.

## Debounce rules (high level)
- Water alerts: avoid repeats within a day unless state worsens.
- Order-related: deliver promptly; for seller, make “new order” hard to miss.

## Non-goals
- Platform payload examples (APNs/FCM).
- Full analytics event taxonomy.

## Push payload contract (v1)

The backend sends pushes via FCM using a **stable data contract** (localization happens client-side).

Note (web portal alignment):
- The in-app alerts feed (`GET /v1/accounts/{account_id}/alerts`) includes **server-rendered convenience strings**
  (`rendered_title`, `rendered_message`) for portal readability, but `message_key` + `message_args` remain the canonical,
  cross-platform representation (see backend decision **D-030**).

- **Required `data` keys**:
  - `push_version`: `"1"`
  - `alert_id`: UUID string
  - `event_id`: UUID string
  - `event_type`: string (e.g. `ORDER_CREATED`)
  - `subject_type`: string
  - `subject_id`: string
  - `message_key`: stable string (e.g. `orders.created`)
  - `message_args`: JSON string (object) for client interpolation
  - `deeplink`: JSON string of `{ "screen": "<ScreenId>", "params": { ... } }`

- **Allowed `ScreenId` (v1)**:
  - `AlertsInbox`
  - `OrderDetail` (`params.order_id`)
  - `ReservoirDetail` (`params.reservoir_id`)
  - *(No `DeviceDetail` in v1 — device-risk notifications route to `AlertsInbox` when not tied to a reservoir.)*

## References
- Personas/JTBD: `./01_user_personas_and_jtbd.md`
- Feature scope: `./03_feature_requirements_document.md`
- UX guidelines: `../../ux/jila_application_ux_guidelines.md`
