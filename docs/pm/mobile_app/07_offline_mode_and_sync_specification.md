# Jila Mobile App — Offline & Sync (Core)

> **Status:** Condensed / low-drift reference
> 
> **Last updated:** 2025-12-20

## Purpose
Define the **offline baseline** required for Jila’s target environment, while avoiding implementation-specific queue schemas and library choices.

## Core rules
- **Read local first** (cache), then refresh when online.
- **Never lose user input**: for supported actions, write locally immediately and sync later.
- **Make sync state obvious**: **Saved offline → Pending sync → Synced** (or **Failed** with retry).
- **Block only truly real-time operations** (e.g., seller accept/reject if required by business rules).

## Offline capability (v1 baseline)
- **Works offline (read)**
  - Reservoir list/detail (cached)
  - Orders list/detail (cached)
  - Supply points map/detail (cached)
- **Works offline (write via queue)**
  - Manual level reading
  - Notification preferences updates
  - Non-critical profile edits (e.g., display name/avatar)
  - Supply point status update *(authenticated; rate-limited; may be rejected by server)*
- **Requires connectivity**
  - Auth flows: registration / OTP / login / refresh
  - Order state transitions: seller accept/reject; buyer cancel; delivery confirmation (server-authoritative + time-sensitive)
  - Seller availability/pricing changes (unless explicitly decided later)

## Sync behavior
- **When to sync**: app foreground, connectivity restored, explicit pull-to-refresh.
- **Priority**: readings and orders before low-risk preferences.
- **Failures**
  - 4xx: show user and require action where meaningful.
  - 5xx/network: retry with backoff; don’t spam the user.
- **Conflicts**: prefer server-authoritative resolution; avoid complex client-side merging for v1.

## UX must-haves (v1)
- **Immediate acknowledgement**: when offline, accepted writes must show “Saved offline” immediately.
- **Per-item state**: each queued write surfaces state: Pending sync / Synced / Failed.
- **Retry control**: Failed items must offer a retry affordance and/or “Try again” on refresh.
- **No silent drops**: the app must never accept input offline and then discard it without user-visible failure.
 - **Community trust signals** (SupplyPoints):
  - Always display availability **evidence type** (Reported/Verified/Sensor-derived) and freshness timestamp.
  - If a queued status update is rejected (4xx), show the rejection and keep the previous visible state.

## Data freshness
- Always show “last updated” (or cached timestamp) for critical numbers.

## Non-goals
- Detailed queue item schemas and pseudo-code.
- Choosing specific local storage libraries.

## References
- UX guidelines (offline and state clarity): `../../ux/jila_application_ux_guidelines.md`
- Journeys: `./02_user_journey_maps.md`
- UI basics (language/accessibility/state clarity): `./09_localization_and_accessibility.md`
