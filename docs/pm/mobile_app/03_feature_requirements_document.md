# Jila Mobile App — Feature Requirements (Core)

> **Status:** Condensed / low-drift reference
> 
> **Last updated:** 2025-12-20
> 
> **Canonical backend contract:** `../../architecture/jila_api_backend_api_contract_v1.md`

## Purpose
Define **v1 mobile scope** and priorities at a level that stays stable while designs and tickets evolve.

## Scope
- **In scope (v1 mobile)**: Household monitoring, seller mode, community discovery, basic org operator view, orders + notifications, offline basics.
- **Out of scope (v1 mobile)**: In-app payments, real-time order tracking map, chat, complex pricing tiers, heavy analytics instrumentation specs, pixel-perfect UI scripts.

## Priority Definitions
- **P0**: Must have for v1 to deliver core value.
- **P1**: Should have for v1 quality/safety.
- **P2**: Nice-to-have.
- **P3**: Future / explicitly not v1.

## Feature Set (by area)

### Authentication & sessions
- **P0**
  - Register (phone-first)
  - Verify phone/email via OTP where required
  - Login
  - Refresh session (access token rotation handled by backend; client must refresh safely)
  - Logout
- **P1**
  - Password reset (anti-enumeration preserved)
  - Account deletion / erasure request (if included in API contract)
  - Basic profile view

**Source of truth:** use the v1 API contract for routes, request/response shapes, and error codes.

### Reservoirs & monitoring (household + org operator)
- **P0**
  - Create reservoir (manual mode supported)
  - List my reservoirs (cached)
  - Manual level reading
  - “Days remaining” shown as **approximate** with last-updated + confidence indicator
  - Level state indicators (normal/low/critical)
- **P1**
  - Reservoir edit (name/capacity/safety margin)
  - Reading history (lightweight; no time-series heavy UI required)

### Community supply points (public read)
- **P0**
  - View supply points on map/list (read-only)
  - Supply point detail
- **P1**
  - Report supply point status (requires auth; rate-limited; clearly labeled as Reported vs Verified with freshness)

### Seller mode
- **P0**
  - Create seller profile
  - Seller availability toggle
  - Set simple pricing (single “base price per liter” + optional flat delivery fee)
  - View incoming orders and act on them

### Marketplace (buyer)
- **P0**
  - Browse listings near a location
  - Estimate total price for a requested volume

### Orders (buyer + seller)
- **P0**
  - Create order
  - View my orders (buyer/seller views)
  - Accept / reject order (seller)
  - Confirm delivery (buyer + seller; idempotent)
- **P1**
  - Cancel order (buyer) if supported by contract
  - Review/rating (optional UX; do not block completion)

### Notifications & alerts
- **P0**
  - Push notifications for order updates (seller + buyer)
  - In-app alerts feed (basic list)
- **P1**
  - Low/critical water alerts (debounced)
  - Notification preferences

### Offline (v1 baseline)
- **P0**
  - Read: reservoirs/orders/supply points from cache with clear “stale” UI
  - Write: queue manual readings and other low-risk writes; sync on reconnect
- **P1**
  - Conflict handling: prefer deterministic last-write-wins except for order state (server authoritative)

## Non-functional requirements (v1)
- **Clarity**: state is always obvious (saved/saving/pending sync/failed).
- **Connectivity**: core read experiences work offline; user-entered data is not lost.
- **Accessibility**: minimum touch targets and basic screen reader support.
- **Localization**: Portuguese-first.
- **Ethics**: no dark patterns; do not gate the core “avoid running out” loop behind paywalls.

## Acceptance criteria style (how we avoid drift)
- This doc defines **scope and priorities** only.
- Acceptance criteria belong in tickets, but must align to:
  - Personas/JTBD (`01_user_personas_and_jtbd.md`)
  - Key flows (`02_user_journey_maps.md`)
  - API contract (`../../architecture/jila_api_backend_api_contract_v1.md`)

## Open questions
- Community (map-only) onboarding default: **DECIDED** — MA-001 + MA-030 (choose-path entry; “Find water nearby” is zero-onboarding).
- Org flows scope: **DECIDED** — MA-031 (mobile v1 beyond invite acceptance is out of scope).
- Notifications priority beyond orders: **DECIDED** — MA-032 (critical water risk P0; low water risk P1).

### Scope note (v1)
- The backend contract includes SupplyPoint nomination and moderation endpoints; mobile v1 scope currently requires:
  - Public discovery + detail
  - Authenticated status updates (P1)
  - A nomination UI is optional and must be explicitly prioritized before the frontend team implements it.

## References
- Personas/JTBD: `./01_user_personas_and_jtbd.md`
- Core flows: `./02_user_journey_maps.md`
- Navigation/IA: `./04_information_architecture.md`
- Offline baseline: `./07_offline_mode_and_sync_specification.md`
- Notifications: `./08_notification_and_alert_strategy.md`
- Backend API contract (canonical): `../../architecture/jila_api_backend_api_contract_v1.md`
