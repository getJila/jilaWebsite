---
title: Jila Mobile App — HTML Drafts ↔ API Contract Gap Overlay (v1)
status: Draft (API augmentation proposal)
last_updated: 2025-12-31
sources:
  - drafts/home.html
  - drafts/marketplace.html
  - drafts/supply-point-detail.html
  - drafts/seller-detail.html
  - drafts/order-review.html
  - drafts/orders.html
  - drafts/order-detail.html
  - drafts/order-detail-delivered.html
  - docs/architecture/jila_api_backend_api_contract_v1.md
  - docs/architecture/jila_api_backend_data_models.md
  - docs/pm/mobile_app/12_frontend_api_handoff_checklist_v1.md
---

## Purpose
Create a concrete “diff overlay” between what the HTML drafts implicitly require and what the v1 backend contract currently exposes, so FE/BE can negotiate a minimal and safe set of additions (fields and/or endpoints).

Note:
- Paths like `drafts/*.html` refer to a **frontend repo** this document was originally authored against (not this backend repo).

Scope:
- **In scope UI**: `drafts/*.html` (mobile conceptual implementation).
- **In scope backend**: `docs/architecture/jila_api_backend_api_contract_v1.md` (canonical HTTP contract) + related model notes.
- **Out of scope**: portal/website specs (these drafts are mobile-first).

---

## What the current v1 contract already covers (quick inventory)

Monitoring (tank):
- `GET /v1/me/reservoirs` includes `capacity_liters`, `monitoring_mode`, `latest_reading.{level_pct,volume_liters,recorded_at,source}`, `level_state` + timestamps.
- `GET /v1/reservoirs/{reservoir_id}` provides reservoir detail, capacity, thresholds, locations, and `latest_reading`.
- `GET /v1/reservoirs/{reservoir_id}/readings` provides time-series points needed for charts and client-derived estimates.

Community discovery:
- `GET /v1/supply-points` returns `id`, `kind`, `label`, `location`, `verification_status`, `operational_status`, `availability_status` (+ timestamps).

Marketplace sellers (public discovery):
- `GET /v1/marketplace/reservoir-listings` returns `seller_reservoir_id`, `seller_principal_id`, `location`, currency, and `estimated_total` for a request.

Orders:
- `POST /v1/accounts/{account_id}/orders` creates an order and returns `requested_volume_liters`, `price_quote_total`, `currency`, `status`.
- `GET /v1/accounts/{account_id}/orders` returns only `{order_id,status,created_at}` today.
- `GET /v1/accounts/{account_id}/orders/{order_id}` exists but its response schema is not specified yet in the contract.
- Confirm delivery + reviews endpoints exist via `POST /v1/accounts/{account_id}/orders/{order_id}/confirm-delivery` and `POST /v1/accounts/{account_id}/orders/{order_id}/reviews` with `{rating,comment}`.

Known gaps already acknowledged in canon:
- Driver identity/tracking is not guaranteed by v1 (mobile handoff checklist).
- `site_consumption_profiles` exists in data models but has no v1 HTTP endpoint (days-of-autonomy inputs remain client-only unless we add a route).

---

## Draft screens → data requirements → contract coverage

### 1) `drafts/home.html` (Tank Home / “digital twin”)

UI fields implied by the draft:
- Reservoir display identity: tank name + a human-readable “site/area label”.
- Capacity, volume, percent full, “last updated”.
- “Days remaining”, “avg usage (L/day)”, “% vs last week”, and a small 7-day trend chart.
- A simple flow status (“Idle/Filling”) for the scene (can be derived client-side from recent readings; no backend requirement).

Current contract coverage:
- Tank identity, capacity, latest reading, last updated: covered by `GET /v1/me/reservoirs` and `GET /v1/reservoirs/{id}`.
- Time-series chart points: covered by `GET /v1/reservoirs/{id}/readings`.

Gaps / friction:
- `GET /v1/me/reservoirs` includes `site_id` but not **site name/label**, so the Home header’s “Fazenda Norte - Sector A” cannot be rendered without extra calls.
- “Days remaining / avg usage / deltas” can be client-derived from readings, but many UIs prefer a backend-provided summary for consistency and low-connectivity performance.

---

### 2) `drafts/marketplace.html` (Discovery hub: Community + Sellers)

Community list card needs (examples appear in the HTML):
- Label/title, kind/subtitle, verification badge, operational state (flowing/maintenance/outage), availability info (“Open until …”, “Open 24/7”), safety/water quality hint (“Safe to drink”, “Last test: …”), distance, and an image.

Seller list card needs (as encoded in `data-*` attributes):
- Seller id (public), seller name, verified badge, operational state, distance, headline pricing (rate), min order, delivery fee, “available volume today”, and an availability cue (“Available now/Restocking”, “Next slot …”).

Current contract coverage:
- Community list: only the canonical status + verification + lat/lng (no extended attributes) via `GET /v1/supply-points`.
- Seller list: only location + `estimated_total` quote via `GET /v1/marketplace/reservoir-listings`.

Gaps / friction:
- SupplyPoint: contract does not return `attributes` (even though nomination supports them), nor any public “details” route; the draft’s copy-heavy detail page cannot be backed.
- Marketplace seller listing: missing seller display identity, base pricing breakdown (rate, fee, min), availability volume, rating/reviews, and any “slots/ETA” hints.
- Filters in the draft (“verified”, “operational”, “available now”) require explicit booleans or statuses for sellers; v1 only has `seller_profile.status` and reservoir `seller_availability_status` (not exposed in public listing response).

---

### 3) `drafts/supply-point-detail.html` (Community supply point detail)

UI fields implied:
- Description, “open until …” hours, pricing copy, water quality status + “last tested …”, photos, and a “report update” action.

Current contract coverage:
- Only discovery list shape exists. There is no `GET /v1/supply-points/{supply_point_id}`.
- Status update route exists (`PATCH /v1/supply-points/{supply_point_id}`) but does not address read-side detail needs.

Primary gap:
- A **detail read model** for supply points (either as explicit fields or an `attributes` object) is missing.

---

### 4) `drafts/seller-detail.html` (Seller detail)

UI fields implied:
- Seller identity: display name + public id; verification badge; rating average + review count; “years active”.
- Delivery + payment capabilities (chips), pricing breakdown (rate/min/fee).
- “Available volume today”.
- Water quality/certification with a “certificate link”.
- Service area text + delivery radius.
- Next available delivery slots.

Current contract coverage:
- Seller profile exists for the current authenticated seller (`POST/PATCH /v1/accounts/{account_id}/seller-profile`), but it’s not a public read model.
- Pricing rules exist, but there is no public endpoint to fetch them as display-ready data.
- Public marketplace listing response does not include seller identity metadata.

Primary gap:
- A public “seller listing + detail” read model (even if minimal) is missing.

---

### 5) Orders: `drafts/order-review.html`, `drafts/orders.html`, `drafts/order-detail.html`, `drafts/order-detail-delivered.html`

UI fields implied across these screens:
- A human-friendly order number (`ORD-3920`), seller display name, volume, delivery mode, totals, timestamps, and a stable status label.
- Order detail: delivery destination (reservoir identity + address-ish string), map link, a multi-step timeline with timestamps, and an ETA/progress hint.
- Post-delivery: a “rate driver” UX with tags + comment (and a driver identity card).

Current contract coverage:
- Create order: returns price + volume; OK.
- Orders list: insufficient (`GET /v1/accounts/{account_id}/orders` currently returns only `{order_id,status,created_at}`).
- Order detail response schema is unspecified in the contract (blocking).
- Reviews endpoint exists but is seller/order-scoped (`{rating,comment}`); “driver tags” do not exist, and driver identity is explicitly not guaranteed by v1.

Primary gaps:
- Define the `GET /v1/accounts/{account_id}/orders/{order_id}` response schema (and ideally expand `GET /v1/accounts/{account_id}/orders` for list rendering).
- Decide whether we are reviewing the **seller/order** (v1) or a **driver** (requires new assignment model and endpoints).

---

## Proposed contract overlay (options)

The goal is to offer **negotiable options**, from minimal viable additions (FE can ship) to richer product parity with the drafts.

### Option A — Minimal additions (unblock FE with minimal BE work)

1) Expand `GET /v1/accounts/{account_id}/orders` list items to avoid N+1 calls
- Add: `requested_volume_liters`, `currency`, `price_quote_total`, `updated_at`, `delivered_at` (nullable), `seller_reservoir_id`, `target_reservoir_id`.
- Add seller identity summary: `seller_display_name` (from seller principal profile) for list rendering.
- Add `order_code` (human-friendly string) to match UI.

2) Define `GET /v1/accounts/{account_id}/orders/{order_id}` response schema (no new “dispatch” states required)
- Include: core order fields + timestamps already present in the data model (`created_at`, `accepted_at`, `cancelled_at`, `delivered_at`, `buyer_confirmed_*`, `seller_confirmed_*`).
- Include seller + target reservoir display summaries so Order Detail can render without extra calls.

3) Add site name into reservoir list responses
- Extend `GET /v1/me/reservoirs.items[*]` with `site_name` (or `site: {site_id,name}`).

4) Keep “driver identity”, “ETA/progress”, “time slots”, and “water quality certificate” as v1 UI fallbacks
- FE uses seller identity fallback (per canonical checklist).
- FE computes distance, basic trend stats, and “days remaining” client-side.

---

### Option B — Add a read model for supply points and sellers (align with drafts)

Supply points:
1) Add `GET /v1/supply-points/{supply_point_id}` returning a richer “detail” payload:
- `id`, `kind`, `label`, `location`, verification + status (same as list)
- `description` (nullable)
- `opening_hours` (nullable; structured)
- `pricing` (nullable; structured)
- `water_quality` (nullable; structured)
- `photo_uris` (nullable; array)

2) Add `attributes` to the list endpoint response (`GET /v1/supply-points`)
- Either return a constrained `attributes` object or promote stable fields (preferred for FE safety).

Sellers / marketplace:
1) Expand `GET /v1/marketplace/reservoir-listings.items[*]` with display-ready info:
- `seller_profile`: `{ display_name, avatar_uri }`
- `verification_status` (if seller verification is in scope)
- `pricing_breakdown`: `{ base_price_per_liter, delivery_fee_flat, min_volume_liters, max_volume_liters }`
- `seller_availability_status` (and optionally `seller_available_volume_liters`)
- `rating_summary` (optional): `{ avg, count }`

2) Add a public seller detail endpoint (optional but matches drafts):
- `GET /v1/marketplace/sellers/{seller_principal_id}` (or by a public seller id) returning the richer seller profile fields used in `drafts/seller-detail.html`:
  - service area, delivery radius, certification link, next slots (if supported)

---

### Option C — Full operational tracking (ETA/progress/driver assignment)

If we want `drafts/order-detail.html` to be “real” (not mocked), v1 needs a delivery/dispatch concept:
- Add a `driver_assignments` (or `deliveries`) model and expose it via `GET /v1/accounts/{account_id}/orders/{order_id}`:
  - `tracking`: `{ status, eta_minutes, progress_pct, location, location_updated_at }`
  - `driver`: `{ display_name, avatar_uri, phone_e164? }`
  - `timeline`: explicit events with timestamps (dispatch, en route, arrived, delivered)

This option also requires revisiting `order_status` (currently only `CREATED|ACCEPTED|REJECTED|CANCELLED|DELIVERED|DISPUTED`) or adding a separate `delivery_status` state machine.

---

## Concrete “diff overlay” suggestions (field-level)

These are intentionally phrased as “additive-only” changes where possible.

### A) `GET /v1/me/reservoirs` (add site name)
Add to each item:
- `site`: `{ "site_id": "uuid", "name": "string" }`

Rationale:
- Unblocks Home header and other surfaces that show “where this tank is” without a follow-up site fetch.

---

### B) `GET /v1/accounts/{account_id}/orders` (expand list shape)
Current response is insufficient for `drafts/orders.html`.

Add to each `items[*]`:
- `order_code` (string, e.g. `ORD-3920`)
- `requested_volume_liters`, `currency`, `price_quote_total`
- `seller_reservoir_id`, `target_reservoir_id`
- `seller_display_name` (string; seller principal profile)
- `updated_at`, `delivered_at` (nullable)

---

### C) `GET /v1/accounts/{account_id}/orders/{order_id}` (specify response schema)
Define a stable response that can render `drafts/order-detail*.html` without extra calls:
- Core: ids, status, volume, price quote, currency, `created_at`, `updated_at`
- Lifecycle timestamps: `accepted_at`, `cancelled_at`, `delivered_at`, buyer/seller confirmations
- Seller summary: `{ seller_principal_id, display_name, avatar_uri }`
- Destination summary: `{ target_reservoir_id, name, site_name?, location? }`
- Optional: `review` summary (if exists) to support post-delivery UI

---

### D) `GET /v1/supply-points` + `GET /v1/supply-points/{supply_point_id}` (detail reads)
Add either:
- A constrained `attributes` object returned on read, or
- Promote stable fields needed by the drafts:
  - `description`
  - `photo_uri`/`photo_uris`
  - `opening_hours`
  - `water_quality` (including `is_potable` and `last_tested_at`)
  - `pricing` (free/paid + limits text)

---

### E) `GET /v1/marketplace/reservoir-listings` (seller identity + pricing breakdown)
Today it returns totals only. For the seller cards and seller detail, add:
- `seller_profile`: `{ display_name, avatar_uri }`
- `pricing_breakdown`: `{ base_price_per_liter, delivery_fee_flat, min_volume_liters, max_volume_liters }`
- `seller_availability_status` (and optionally `seller_available_volume_liters`)
- Optional: `rating_summary`: `{ avg, count }`

---

## FE fallback guidance (if BE stays strict v1)

If we do not expand the contract:
- Seller “verified” + rating + slots are **not renderable** from v1 API; FE should remove those badges in v1 and keep only “Estimated total” from the listings endpoint.
- Supply point “open hours”, “safe to drink”, “last tested”, and descriptions are **not renderable**; FE should show only verification + operational/availability from the contract.
- Orders list can only show order id + status + created time (no seller name/price) unless FE does multiple detail calls.

---

## Recommendation (suggested negotiation baseline)

Recommend adopting **Option A + the Marketplace/SupplyPoint read-model parts of Option B**:
- It preserves the v1 simplicity decisions (no dispatch/driver requirements), but still unblocks the drafts’ UX by adding read-side fields where the product clearly expects them.
- It keeps the schema additive and allows future evolution (e.g., if we later add delivery tracking, it can live under an optional `tracking` object).
