# Jila Mobile App — Information Architecture (Core)

> **Status:** Condensed / low-drift reference
> 
> **Last updated:** 2025-12-20

## Purpose
Define the **top-level navigation model** and the small set of screens that must exist for v1. This doc avoids exhaustive screen trees and wireframe prose.

## Navigation model (v1)
- **Primary pattern**: bottom tabs (4 items) + standard push navigation.
- **Principle**: critical actions should be reachable in **≤ 3 taps**.

### Tabs (role-adaptive)
- **Home**
  - Household: reservoirs overview
  - Seller: seller dashboard (availability + orders)
  - Org operator: assigned sites/reservoirs view
- **Marketplace**
  - Combined discovery hub (community supply points + sellers), with Map/List toggle and filtering.
  - **Orders entrypoint**: “My orders” is accessible from Marketplace (common marketplace pattern).
- **Map**
  - Supply points discovery (public read)
- **Profile**
  - Account + preferences (including notifications)

*(Exact role detection and UI switching are implementation details; keep the conceptual model stable.)*

## Screen set (v1 “must exist”)
- **Auth**: register, OTP verify, login, logout (plus invite acceptance if used)
- **Home**: reservoir cards list + reservoir detail
- **Update level**: a quick “manual reading” interaction
- **Order flow**: select volume, select seller, review/confirm
- **Orders**: list + detail with state-based actions (accessed from Marketplace)
- **Map**: supply points map/list + supply point detail
- **Profile**: notification settings + basic account info
- **AlertsInbox**: dedicated alerts feed (deep link landing surface; see MA-029)

For the canonical screen inventory (stable ScreenIds + purpose + auth/offline notes), see:
- `./11_screen_inventory.md`

## Deep links (optional but recommended)
- **From push notifications (v1)**: only ScreenIds allowed by the push payload contract in `./08_notification_and_alert_strategy.md`:
  - `AlertsInbox`, `OrderDetail`, `ReservoirDetail`
- **Internal deep links (in-app)** may route to other screens (e.g., supply point detail), but must not be treated as push ScreenIds unless the contract is updated.

## Non-goals
- Full exhaustive screen trees and component inventories.
- Platform-specific navigation implementation guidance.

## Open questions
- Should “Map” be the default first tab for unauthenticated users (community mode)? **Decided in MA-001**: unauthenticated users see a choose-path entry, with “Find water nearby” going straight to Marketplace discovery (Community default).
- Do we need a dedicated “Alerts” screen in v1, or is in-app feed inside Profile sufficient? **Decided in MA-029**: dedicated `AlertsInbox` (not a tab).

## References
- Core flows: `./02_user_journey_maps.md`
- Feature scope/priorities: `./03_feature_requirements_document.md`
- UX guidelines: `../../ux/jila_application_ux_guidelines.md`
