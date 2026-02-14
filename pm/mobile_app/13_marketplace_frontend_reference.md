---
title: Jila Mobile App — Marketplace (Frontend Reference)
status: Draft (implementation-aligned)
last_updated: 2025-12-25
---

## Purpose
Provide a single, sendable reference for the **Marketplace** experience in v1: **what screens exist**, **what information is available**, and **how it is used** (without prescribing UI layout).

Note:
- Paths like `src/features/...` refer to the **mobile app repo** this document was originally authored against (not this web portal frontend repo).

Sources of truth:
- Navigation + screen set: `./04_information_architecture.md`, `./11_screen_inventory.md`
- Product decisions: `../../decision_registers/mobile_app_decision_register.md` (notably MA-028, MA-034)
- Backend contract: `docs/architecture/jila_api_backend_api_contract_v1.md`
- FE ↔ API checklist: `./12_frontend_api_handoff_checklist_v1.md`
- Localization baseline: `./09_localization_and_accessibility.md`

---

## Marketplace: primary use-cases (v1)
- **Discover water nearby** (no login required):
  - **Community supply points** (public sources)
  - **Sellers** (paid delivery listings)
- **Act on orders** (auth required):
  - Open **My orders** list
  - Create an order (online-only; retry-safe via idempotency)
- **Permission rule (critical)**:
  - A user may **have access to a reservoir** but still be **forbidden to order** for that reservoir.
  - Order creation uses `target_reservoir_id` and server-side RBAC checks.

---

## Screens in the Marketplace flow (v1)
This is the conceptual set (exact component names may differ per platform implementation).

### 1) Marketplace (Tab) — combined discovery hub
User toggles:
- **Segment**: Community vs Sellers (default = Community)
- **View**: List vs Map

Always-available entrypoint:
- **My orders** (auth-gated)

Data shown depends on segment/view (see “Data Dictionary” below).

### 2) SupplyPointDetail — community source detail
Opened from Marketplace (or Map tab) when a community item/marker is tapped.

Shows:
- identity (label/kind)
- status (availability + operational)
- trust signals (verification + evidence)
- location (lat/lng)
- authenticated action surface: “Report an update” (status update)

### 3) OrdersList — “My orders”
Opened from Marketplace via “My orders”.

Shows:
- list of orders visible to the user principal (buyer and/or seller)
- each item: id, status, created_at

### 4) OrderCreate (step-by-step)
Starts when a seller listing is tapped. Volume selection drives which listings and totals are shown.

### 5) OrderConfirm (review + confirm)
Shows:
- seller identity (id surface)
- requested volume
- estimated total + currency
- **target reservoir selection** (“Deliver to”)

On confirm:
- creates an order using `POST /v1/accounts/{account_id}/orders`

### 6) OrderDetail
Order status + timeline + state actions (accept/reject/cancel/confirm-delivery) depending on user role and current state.

---

## API surfaces used by Marketplace
### Public discovery (no JWT required)
- **Community supply points**: `GET /v1/supply-points`
- **Seller listings**: `GET /v1/marketplace/reservoir-listings`

### Auth-required
- **My orders**: `GET /v1/accounts/{account_id}/orders`
- **Create order**: `POST /v1/accounts/{account_id}/orders` (supports `Idempotency-Key`)
- **Order detail**: `GET /v1/accounts/{account_id}/orders/{order_id}`
- **Order actions**: `POST /v1/accounts/{account_id}/orders/{order_id}/accept|reject|cancel|confirm-delivery|dispute` (see contract for semantics)
- **Community contribution**: `PATCH /v1/supply-points/{supply_point_id}` (authenticated; partial update; use evidence rules)

---

## Data Dictionary (what fields exist + how to use them)

### A) Community supply point (list + map + detail)
Source of truth: `src/features/map/types.ts`

#### `SupplyPoint`
- **Identity**
  - `id: string`: unique identifier
  - `label: string | null`: name; may be null (use “Unnamed” fallback)
  - `kind: SupplyPointKind`: STANDPIPE | RIVER | BOREHOLE | KIOSK | DEPOT | OTHER
- **Location**
  - `location.lat: number`, `location.lng: number`: map marker coordinate
- **Trust + verification**
  - `verification_status: SupplyPointVerificationStatus`: PENDING_REVIEW | VERIFIED | REJECTED | DECOMMISSIONED
  - `verification_updated_at: string | null`: timestamp
- **Operational status**
  - `operational_status: SupplyPointOperationalStatus`: ACTIVE | INACTIVE | UNKNOWN
  - `operational_status_updated_at: string | null`
- **Availability status**
  - `availability_status: SupplyPointAvailabilityStatus`: AVAILABLE | LOW | NONE | CLOSED | UNKNOWN
  - `availability_evidence_type: SupplyPointEvidenceType | null`: REPORTED | VERIFIED | SENSOR_DERIVED
  - `availability_updated_at: string | null`: primary freshness signal for “has water”

#### Example `SupplyPoint` (ready for mocks)
```json
{
  "id": "sp_4f3b2c2a-1c0d-4a83-9b3a-2c8b7f6a1d9e",
  "kind": "STANDPIPE",
  "label": "Chafariz do Bairro Azul",
  "location": { "lat": -8.8383, "lng": 13.2344 },
  "verification_status": "PENDING_REVIEW",
  "verification_updated_at": "2025-12-24T09:15:00Z",
  "operational_status": "ACTIVE",
  "operational_status_updated_at": "2025-12-25T07:35:00Z",
  "availability_status": "LOW",
  "availability_evidence_type": "REPORTED",
  "availability_updated_at": "2025-12-25T07:40:00Z"
}
```

#### “Report an update” payload (authenticated)
Source of truth: `src/features/map/types.ts`

- `availability_status?: AVAILABLE|LOW|NONE|CLOSED|UNKNOWN`
- `operational_status?: ACTIVE|INACTIVE|UNKNOWN`
- `availability_evidence_type?: REPORTED|VERIFIED|SENSOR_DERIVED`

In v1 client UX, updates are submitted as **Reported**.

---

### B) Seller marketplace listing (list + map marker)
Source of truth: `src/features/marketplace/types.ts`

#### `MarketplaceReservoirListing`
- `seller_reservoir_id: string`: primary key for ordering (used to start `OrderCreate`)
- `seller_principal_id: string`: seller identity surface (currently shown as short id)
- `location.lat/lng: number`: marker coordinate and “nearby” semantics
- `seller_availability_updated_at: string`: freshness for seller availability
- `location_updated_at: string`: freshness for seller location
- `currency: string`: e.g., "AOA"
- `estimated_total: number`: quote for the currently selected `requested_volume_liters`

#### Example listing (ready for mocks)
```json
{
  "seller_reservoir_id": "res_9b7c1a2d-3f44-4e2d-9a5c-1e1f0b9c2d11",
  "seller_principal_id": "pr_1f2e3d4c-5b6a-7980-9abc-def012345678",
  "location": { "lat": -8.8451, "lng": 13.2389 },
  "seller_availability_updated_at": "2025-12-25T06:10:00Z",
  "location_updated_at": "2025-12-25T06:12:30Z",
  "currency": "AOA",
  "estimated_total": 1500
}
```

---

### C) Orders (create, list, detail)
Source of truth: `src/features/marketplace/types.ts` and backend contract.

#### Create order request (frontend shape)
Source of truth: `src/features/marketplace/types.ts`

- `target_reservoir_id?: string` (**required by backend contract for real ordering; UI must select a reservoir**)
- `seller_reservoir_id: string`
- `requested_volume_liters: number`
- `currency: string`

Backend contract request includes:
- `requested_fill_mode` (client uses VOLUME_LITERS)
- `Idempotency-Key` header is supported for retry safety.

#### Create order response (minimum)
- `order_id: string`
- `status: "CREATED"`
- `requested_volume_liters: number`
- `price_quote_total: number`
- `currency: string`

#### My orders list item (minimum)
- `order_id: string`
- `status: CREATED|ACCEPTED|REJECTED|CANCELLED|DELIVERED|DISPUTED`
- `created_at: string`

---

## Marketplace map/list behaviors (data-driven, not visual)
- **Community/List**
  - Filters available: `kind` and `availability_status`
  - List item fields: label (or unnamed), kind label, availability icon, pending review tag when `verification_status = PENDING_REVIEW`
- **Community/Map**
  - Markers: each `SupplyPoint.location`
  - Tap marker → open `SupplyPointDetail`
- **Sellers/List**
  - Buyer selects `requested_volume_liters` (presets); results return `estimated_total` per listing for that volume
  - List item fields: seller identity (id surface), estimated total + currency
  - Tap listing → start `OrderCreate` (prefilled volume + seller_reservoir_id)
- **Sellers/Map**
  - Markers: each `MarketplaceReservoirListing.location`
  - Tap marker → start `OrderCreate`

---

## Key constraints for implementation (to inform UX states)
- **Authentication**
  - Discovery is public; **My orders** and ordering are authenticated.
- **Ordering rights**
  - Even authenticated users may receive `403 FORBIDDEN` from `POST /v1/accounts/{account_id}/orders` for a selected `target_reservoir_id`.
  - UX should communicate this clearly and allow choosing a different reservoir.
- **Offline**
  - Discovery should be cache-friendly where possible; explicit refresh is preferred.
  - **Order creation is online-only** (do not queue).
- **Maps**
  - MA-028: use Mapbox Mobile SDK (React Native) for rendering.
  - Address/place search uses Mapbox Search / Geocoding.
  - Requires a public Mapbox access token (restricted to app bundle IDs / package names) + Mapbox Studio style URLs (light/dark).




