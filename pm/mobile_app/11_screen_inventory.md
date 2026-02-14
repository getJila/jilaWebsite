---
title: Jila Mobile App — Screen Inventory (v1)
status: Draft (low-drift reference)
last_updated: 2025-12-22
---

## Purpose
Define the **canonical screen set** for mobile v1 in a way that stays stable as designs evolve.

This document complements (does not replace):
- Top-level navigation model: `./04_information_architecture.md`
- Core journeys + guardrails: `./02_user_journey_maps.md`
- Product decisions: `../../decision_registers/mobile_app_decision_register.md`
- Notifications + deep link contract: `./08_notification_and_alert_strategy.md`

## Rules (anti-drift)
- **ScreenId names are stable** and should not be renamed casually (deep links/analytics depend on them).
- **Do not add new push deep link ScreenIds** without updating `./08_notification_and_alert_strategy.md`.
- **Offline-first**: monitoring/order history surfaces must have useful cached reads and clear freshness UI (MA-005).
- **Ruthless simplicity**: one primary action per screen; prefer step-by-step flows for complex tasks (UX-D-047/048).

## Screen set (v1)
Notes:
- “Deep link” here refers to internal navigation; push deep link ScreenIds remain constrained by the push contract.
- Auth requirements follow the v1 product model (community map read can be unauthenticated).

### Entry + onboarding
- **ChoosePath**
  - **Purpose**: default unauthenticated entry (MA-001).
  - **Auth**: no.
  - **Primary action**: choose: Explore / Set up (create account). Secondary: I have an invite code.

- **FirstRunTutorial** *(optional, skippable)*  
  - **Purpose**: 2–3 illustration-led panels (MA-006).
  - **Auth**: no.
  - **Notes**: never blocks entry; must be vector-first and minimal copy.

### Authentication
- **AuthRegister**
- **AuthLogin**
- **AuthVerifyPhone**
- **AuthVerifyEmail** *(if used)*
- **AuthLogout** *(action surface, not necessarily a screen)*

### Home (role-adaptive tab)
- **Home**
  - **Purpose**: role-adaptive overview (household reservoirs / seller dashboard / org assigned sites).

#### Household monitoring
- **ReservoirList** *(may be part of Home)*  
- **ReservoirDetail** *(push deep link allowed)*  
  - **Purpose**: tank “digital twin” + last updated + health indicators + Replenishment Card (MA-004, UX-D-040, UX-D-038).
  - **Offline**: must show last known state (ghost) + timestamp (MA-005).

- **ReservoirUpdateLevel**
  - **Purpose**: quick manual reading (queueable offline per MA-025).

- **ReservoirHowItWorks** *(optional)*
  - **Purpose**: x-ray/cutaway education and calibration explanations (Blueprints of Life).

#### Seller
- **SellerSetup**
- **SellerAvailability**
- **SellerPricing**

### Marketplace + ordering
- **Marketplace** *(tab; public discovery hub)*  
  - **Purpose**: combined discovery surface showing **Community supply points** and **Sellers** with clear segmentation and filtering.
  - **Auth**: no (view). Order creation and “My orders” require auth.
  - **UI**:
    - **Default segmentation**: Community vs Sellers (community first).
    - **Map/List toggle**: switch between map and list representations of nearby results (MA-028).
    - **Tags/filters**: kind/status for community points; availability/volume/cost for sellers.
    - **Orders entrypoint**: “My orders” is accessible from Marketplace header/top area (common marketplace pattern).
  - **API**:
    - Community: `GET /v1/supply-points` (public)
    - Sellers: `GET /v1/marketplace/reservoir-listings` (public)
    - Ordering: `POST /v1/accounts/{account_id}/orders` (auth)

- **MarketplaceListings** *(public discovery; no JWT required)*  
  - **Purpose**: seller discovery sub-surface (may be used as a dedicated list view within Marketplace).
  - **Auth**: no (view). **Yes** for order creation.
- **OrderCreate** *(step-by-step)*  
  - **Purpose**: volume → seller/vehicle → review/confirm (may be prefilled from Replenishment Card).
  - **Rule**: “one-tap” means one-tap into a prefilled confirmation, not silent purchase (MA-004).

- **OrderConfirm** *(review + total cost visible)*
- **OrderDetail** *(push deep link allowed)*

### Orders (accessed from Marketplace)
- **OrdersList**
- **OrderDetail** *(shared with deep link)*

### Map tab (community discovery)
- **SupplyPointsMap**
- **SupplyPointDetail**

### Alerts
- **AlertsInbox** *(push deep link allowed)*  
  - **Purpose**: stable landing for pushes + auditable alert history (MA-029).

### Profile tab
- **Profile**
- **NotificationPreferences**
- **LanguageSettings**
- **AccessibilitySettings** *(includes Solar Mode override where applicable)*

### Invite / org
- **InviteAccept**
- **OrgHome** *(if org operator is in scope beyond invite acceptance; otherwise link to assigned-sites view in Home)*

### Help / diagnostics (lightweight)
- **DiagnosticsTips** *(optional)*
  - **Purpose**: short illustrated help tied to diagnostic gallery (UX-D-039); no long text.


