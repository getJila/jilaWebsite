## Marketplace frontend integration guide (v1, self-contained)

This document is a **self-contained** source of truth for frontend/mobile clients implementing Marketplace and related discovery flows.
It is written to avoid ambiguity: **every endpoint** includes auth, request structure, response structure, and common errors.

---

### Global conventions (applies to all endpoints below)

#### Base path
All endpoints are under `/v1`.

#### Timestamps
All server-generated timestamps are ISO8601 **UTC** with `Z` suffix:

```json
"2026-02-01T18:07:00Z"
```

#### Auth header (for authenticated endpoints)

```http
Authorization: Bearer <access_token>
```

#### Standard error response shape
All errors return JSON in this shape:

```json
{
  "error_code": "FORBIDDEN",
  "message": "Access denied",
  "details": { "reason": "..." }
}
```

Common status codes:
- `401`: unauthenticated (missing/invalid bearer token)
- `403`: authenticated but not authorized
- `404`: resource not found
- `409`: deterministic conflict (state machine / overlap / idempotency conflict)
- `422`: validation error

#### Internal ops admin (support tooling)
Some endpoints below note: “internal ops admin may bypass account scoping”.

This means:
- The server allows access even if the caller does not have normal org-role grants on the `account_id`.
- `account_id` must still refer to an **organization account principal**.
- This is intended for admin portal/support tooling only.

---

### Concepts (what the marketplace UI configures)

#### Reservoir (core object)
A physical tank/water container. Location is stored as a single unified field:
- `location` (lat/lng)
- `location_updated_at` (server timestamp)

#### Seller profile (seller-mode switch)
Enables seller mode for an account and gates seller endpoints:
- Stored in `seller_profiles` (`principal_id`, `status`)
- Shared display identity is in `principal_profiles` (`display_name`, `avatar_uri`)

#### Seller reservoir + price rules
Marketplace configuration for an existing reservoir:
- Seller availability (`seller_availability_status`) is stored on the reservoir
- Pricing bands are stored in `reservoir_price_rules`

#### Marketplace listing (public)
Buyer-facing public discovery. A reservoir can appear in listings when:
- seller profile is `ACTIVE`
- seller availability is `AVAILABLE`
- reservoir has `location`
- price rules are optional for appearing, but required for server-side price quoting for a `(currency, volume)` pair

---

## 1) Public discovery (no auth)

### 1.1 `GET /v1/supply-points`
Community supply points discovery (public).

**Auth**: Public

**Query params (all optional)**:
- `lat` (float)
- `lng` (float)
- `within_radius_km` (float)
- `kind` (`STANDPIPE|RIVER|BOREHOLE|KIOSK|DEPOT|OTHER`)
- `operational_status` (`ACTIVE|INACTIVE|UNKNOWN`)
- `availability_status` (`AVAILABLE|LOW|NONE|CLOSED|UNKNOWN`)

**Geo behavior**:
- Geo filter applies only when both `lat` and `lng` are provided.
- If `within_radius_km` omitted, default is `10`.
- Radius is clamped to max `10` km.

**Response `200`**:

```json
{
  "items": [
    {
      "id": "uuid",
      "kind": "STANDPIPE",
      "label": "Standpipe A",
      "location": { "lat": -8.84, "lng": 13.23 },
      "verification_status": "PENDING_REVIEW",
      "verification_updated_at": "2026-02-01T18:07:00Z",
      "operational_status": "ACTIVE",
      "operational_status_updated_at": "2026-02-01T18:07:00Z",
      "availability_status": "AVAILABLE",
      "availability_evidence_type": "REPORTED",
      "availability_updated_at": "2026-02-01T18:07:00Z",
      "attributes": {}
    }
  ]
}
```

---

### 1.2 `GET /v1/supply-points/{supply_point_id}`
Community supply point details (public).

**Auth**: Public

**Response `200`**:

```json
{
  "id": "uuid",
  "kind": "STANDPIPE",
  "label": "Standpipe A",
  "location": { "lat": -8.84, "lng": 13.23 },
  "verification_status": "VERIFIED",
  "verification_updated_at": "2026-02-01T18:07:00Z",
  "operational_status": "ACTIVE",
  "operational_status_updated_at": "2026-02-01T18:07:00Z",
  "availability_status": "AVAILABLE",
  "availability_evidence_type": "REPORTED",
  "availability_updated_at": "2026-02-01T18:07:00Z",
  "attributes": {}
}
```

Errors:
- `404 RESOURCE_NOT_FOUND`

---

### 1.3 `GET /v1/marketplace/reservoir-listings`
Public marketplace discovery surface for buyer clients.

**Auth**: Public

**Query params (all optional)**:
- `lat` (float)
- `lng` (float)
- `within_radius_km` (float)
- `requested_volume_liters` (float)
- `currency` (string, 3-letter code)

**Geo behavior**:
- Geo filter applies only when both `lat` and `lng` are provided.
- If `within_radius_km` omitted, default is `10`.
- Radius is clamped to max `10` km.

**Quoting behavior**:
- If both `requested_volume_liters > 0` and `currency` is a valid 3-letter code, the server attempts to match a price rule:
  - If a rule matches, `currency` and `estimated_total` are populated.
  - Otherwise, behavior is deterministic (listing may be excluded from quote results depending on rule match).
- If quoting inputs are omitted/invalid, the server returns listings without quotes:
  - `currency` and `estimated_total` are `null`.

**Response `200`**:

```json
{
  "items": [
    {
      "seller_reservoir_id": "uuid",
      "seller_principal_id": "uuid",
      "location": { "lat": -8.84, "lng": 13.23 },
      "seller_availability_updated_at": "2026-02-01T18:07:00Z",
      "location_updated_at": "2026-02-01T18:07:00Z",
      "currency": "AOA",
      "estimated_total": 1500
    }
  ]
}
```

---

## 2) Supply points (authenticated nomination + status update + admin moderation)

### 2.1 `POST /v1/supply-points` (community nomination)
**Auth**: Bearer required

**Request**:

```json
{
  "kind": "STANDPIPE",
  "label": "Standpipe A",
  "location": { "lat": -8.84, "lng": 13.23 },
  "attributes": {}
}
```

Fields:
- `kind` (required): `STANDPIPE|RIVER|BOREHOLE|KIOSK|DEPOT|OTHER`
- `location` (required): `{ "lat": float, "lng": float }`
- `label` (optional string)
- `attributes` (optional object)

**Response `200`**:

```json
{
  "id": "uuid",
  "kind": "STANDPIPE",
  "label": "Standpipe A",
  "location": { "lat": -8.84, "lng": 13.23 },
  "verification_status": "PENDING_REVIEW",
  "verification_updated_at": "2026-02-01T18:07:00Z",
  "operational_status": "UNKNOWN",
  "operational_status_updated_at": null,
  "availability_status": "UNKNOWN",
  "availability_evidence_type": null,
  "availability_updated_at": null,
  "attributes": {}
}
```

---

### 2.2 `PATCH /v1/supply-points/{supply_point_id}` (status update)
**Auth**: Bearer required

**Request** (any subset, but at least one field must be present):

```json
{
  "operational_status": "ACTIVE",
  "availability_status": "AVAILABLE",
  "availability_evidence_type": "REPORTED",
  "attributes": {}
}
```

Fields:
- `operational_status` (optional): `ACTIVE|INACTIVE|UNKNOWN`
- `availability_status` (optional): `AVAILABLE|LOW|NONE|CLOSED|UNKNOWN`
- `availability_evidence_type` (optional): `REPORTED|VERIFIED|SENSOR_DERIVED`
  - Required when `availability_status` is provided
- `attributes` (optional object)

Permissions (v1):
- Some updates require operator-grade permission.
- Internal ops admins may bypass operator gating for support tooling.

**Response `200`**:

```json
{ "status": "OK" }
```

Errors:
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

---

### 2.3 Internal ops admin moderation endpoints
Admin-only moderation transitions:
- `POST /v1/supply-points/{supply_point_id}/verify`
- `POST /v1/supply-points/{supply_point_id}/reject`
- `POST /v1/supply-points/{supply_point_id}/decommission`

**Auth**: Bearer required + internal ops admin

**Request**: empty body

**Response `200`**:

```json
{ "status": "OK" }
```

---

## 3) Reservoirs (authenticated; used by sellers for location + selection)

### 3.1 `GET /v1/accounts/{account_id}/reservoirs`
**Auth**: Bearer required

**Response `200`**:

```json
{
  "items": [
    {
      "reservoir_id": "uuid",
      "site_id": "uuid",
      "owner_principal_id": "uuid",
      "name": "Home tank",
      "reservoir_type": "TANK",
      "mobility": "FIXED",
      "capacity_liters": 1000,
      "safety_margin_pct": 20,
      "monitoring_mode": "MANUAL",
      "location": { "lat": -8.84, "lng": 13.23 },
      "location_updated_at": "2026-02-01T18:07:00Z",
      "thresholds": {
        "full_threshold_pct": null,
        "low_threshold_pct": null,
        "critical_threshold_pct": null
      },
      "level_state": null,
      "level_state_updated_at": null,
      "connectivity_state": "OFFLINE",
      "last_reading_age_seconds": null,
      "device": null,
      "latest_reading": null
    }
  ]
}
```

---

### 3.2 `GET /v1/reservoirs/{reservoir_id}`
**Auth**: Bearer required

**Response `200`**:

```json
{
  "reservoir_id": "uuid",
  "site_id": "uuid",
  "owner_principal_id": "uuid",
  "name": "Home tank",
  "reservoir_type": "TANK",
  "mobility": "FIXED",
  "capacity_liters": 1000,
  "safety_margin_pct": 20,
  "monitoring_mode": "MANUAL",
  "location": { "lat": -8.84, "lng": 13.23 },
  "location_updated_at": "2026-02-01T18:07:00Z",
  "height_mm": null,
  "sensor_empty_distance_mm": null,
  "sensor_full_distance_mm": null,
  "full_threshold_pct": null,
  "low_threshold_pct": null,
  "critical_threshold_pct": null,
  "level_state": null,
  "level_state_updated_at": null,
  "latest_reading": null
}
```

---

### 3.3 `PATCH /v1/reservoirs/{reservoir_id}`
**Auth**: Bearer required

**Request** (partial; any subset, but at least one field must be present):

```json
{
  "location": { "lat": -8.123, "lng": 13.123 }
}
```

Supported fields (all optional):
- `capacity_liters` (float)
- `safety_margin_pct` (float)
- `seller_availability_status` (`AVAILABLE|UNAVAILABLE|UNKNOWN`)
- `location` (`{lat,lng}`)
- `height_mm` (int)
- `sensor_empty_distance_mm` (int)
- `sensor_full_distance_mm` (int)
- `full_threshold_pct` (float 0–100)
- `low_threshold_pct` (float 0–100)
- `critical_threshold_pct` (float 0–100)

**Response `200`**: updated reservoir (same shape as `GET /v1/reservoirs/{reservoir_id}`).

Errors:
- `422 VALIDATION_ERROR` (e.g. invalid lat/lng)

---

## 4) Seller mode (authenticated; required before seller listing endpoints)

### 4.1 `GET /v1/accounts/{account_id}/seller-profile`
**Auth**: Bearer required  
**Support tooling**: internal ops admin may bypass account scoping

**Response `200`**:

```json
{
  "principal_id": "uuid",
  "status": "ACTIVE",
  "display_name": "Seller A"
}
```

Errors:
- `404 RESOURCE_NOT_FOUND` (seller profile not created yet)

---

### 4.2 `POST /v1/accounts/{account_id}/seller-profile`
**Auth**: Bearer required  
**Support tooling**: internal ops admin may bypass account scoping

**Request**:

```json
{ "status": "ACTIVE", "display_name": "Seller A" }
```

Fields:
- `status` (required): `ACTIVE|INACTIVE`
- `display_name` (optional string)

**Response `200`**:

```json
{ "principal_id": "uuid", "status": "ACTIVE", "display_name": "Seller A" }
```

Errors:
- `409 RESOURCE_CONFLICT` (already exists)

---

### 4.3 `PATCH /v1/accounts/{account_id}/seller-profile`
**Auth**: Bearer required  
**Support tooling**: internal ops admin may bypass account scoping

**Request**:

```json
{ "status": "INACTIVE" }
```

Fields:
- `status` (optional): `ACTIVE|INACTIVE`
  - If omitted (e.g. `{}`), the server returns the current seller profile without changing state.

**Response `200`**:

```json
{ "principal_id": "uuid", "status": "INACTIVE", "display_name": "Seller A" }
```

---

## 5) Seller listings (authenticated; gated by seller profile ACTIVE)

### 5.1 `GET /v1/accounts/{account_id}/seller/reservoirs`
**Auth**: Bearer required  
**Support tooling**: internal ops admin may bypass account scoping

Prerequisite:
- Seller profile must exist and be `ACTIVE`, otherwise:
  - `403 FORBIDDEN` with message `Seller profile not active`

**Response `200`**:

```json
{
  "items": [
    {
      "reservoir_id": "uuid",
      "seller_availability_status": "AVAILABLE",
      "name": "Home tank",
      "location": { "lat": -8.84, "lng": 13.23 },
      "location_updated_at": "2026-02-01T18:07:00Z"
    }
  ]
}
```

Important:
- This endpoint is seller listing configuration and includes `name`/`location` as convenience fields for seller UIs.
- For full reservoir details (calibration, readings, thresholds, etc.), use:
  - `GET /v1/accounts/{account_id}/reservoirs` (preferred for list screens)
  - `GET /v1/reservoirs/{reservoir_id}` (preferred for detail screens)

---

### 5.2 `PATCH /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}`
**Auth**: Bearer required  
**Support tooling**: internal ops admin may bypass account scoping

**Request**:

```json
{ "seller_availability_status": "AVAILABLE" }
```

Fields:
- `seller_availability_status` (required): `AVAILABLE|UNAVAILABLE`

**Response `200`**:

```json
{ "reservoir_id": "uuid", "seller_availability_status": "AVAILABLE" }
```

---

## 6) Price rules (authenticated; seller config)

### 6.1 `GET /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules`
**Auth**: Bearer required  
**Support tooling**: internal ops admin may bypass account scoping

**Response `200`**:

```json
{
  "items": [
    {
      "price_rule_id": "uuid",
      "currency": "AOA",
      "min_volume_liters": 0,
      "max_volume_liters": 1000,
      "base_price_per_liter": 0.05,
      "delivery_fee_flat": 100,
      "created_at": "2026-02-01T18:07:00Z"
    }
  ]
}
```

---

### 6.2 `POST /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules`
**Auth**: Bearer required  
**Support tooling**: internal ops admin may bypass account scoping

**Request**:

```json
{
  "currency": "AOA",
  "min_volume_liters": 0,
  "max_volume_liters": 1000,
  "base_price_per_liter": 0.05,
  "delivery_fee_flat": 100
}
```

Fields:
- `currency` (required, 3 letters)
- `min_volume_liters` (required, >= 0)
- `max_volume_liters` (required, > 0 and >= min)
- `base_price_per_liter` (required, > 0)
- `delivery_fee_flat` (optional, >= 0)

**Response `200`**:

```json
{ "price_rule_id": "uuid" }
```

Errors:
- `409 PRICE_RULE_OVERLAP`

---

## 7) Orders + reviews (authenticated; account-scoped)

### 7.1 `POST /v1/accounts/{account_id}/orders`
**Auth**: Bearer required  
**Support tooling**: internal ops admin may bypass account scoping

**Optional header**:
- `Idempotency-Key: <string>`

**Request**:

```json
{
  "target_reservoir_id": "uuid",
  "requested_fill_mode": "VOLUME_LITERS",
  "requested_volume_liters": 500,
  "seller_reservoir_id": "uuid",
  "currency": "AOA"
}
```

Rules:
- `seller_reservoir_id` is required.
- `requested_fill_mode` is required:
  - `FILL_TO_FULL` or `VOLUME_LITERS`
- If `requested_fill_mode = VOLUME_LITERS`, `requested_volume_liters` is required.
- A matching price rule must exist for the `(seller_reservoir_id, currency, requested_volume_liters)` range.

**Response `200`**:

```json
{
  "order_id": "uuid",
  "order_code": "ORD-7H3K2Q9D1FJ2",
  "status": "CREATED",
  "requested_volume_liters": 500,
  "price_quote_total": 1500,
  "currency": "AOA"
}
```

Common errors:
- `422 NO_PRICE_RULE_MATCH`
- `409 PRICE_RULE_OVERLAP`
- `409 IDEMPOTENCY_KEY_CONFLICT`

---

### 7.2 `GET /v1/accounts/{account_id}/orders`
**Auth**: Bearer required  
**Support tooling**: internal ops admin may bypass account scoping

**Query params (optional)**:
- `view`: `all|buyer|seller` (default `all`)
- `limit`: `1..200` (default `50`)
- `cursor`: opaque cursor

**Response `200`**:

```json
{
  "items": [
    {
      "order_id": "uuid",
      "order_code": "ORD-7H3K2Q9D1FJ2",
      "status": "CREATED",
      "created_at": "2026-02-01T18:07:00Z",
      "updated_at": "2026-02-01T18:07:00Z",
      "delivered_at": null,
      "requested_volume_liters": 500,
      "price_quote_total": 1500,
      "currency": "AOA",
      "seller_reservoir_id": "uuid",
      "target_reservoir_id": null,
      "seller_profile": {
        "principal_id": "uuid",
        "display_name": "Seller A",
        "avatar_uri": null
      }
    }
  ],
  "next_cursor": null
}
```

---

### 7.3 `GET /v1/accounts/{account_id}/orders/{order_id}`
**Auth**: Bearer required  
**Support tooling**: internal ops admin may bypass account scoping

**Response `200`**:

```json
{
  "order_id": "uuid",
  "order_code": "ORD-7H3K2Q9D1FJ2",
  "status": "ACCEPTED",
  "created_at": "2026-02-01T18:07:00Z",
  "updated_at": "2026-02-01T18:07:00Z",
  "accepted_at": "2026-02-01T18:07:00Z",
  "cancelled_at": null,
  "delivered_at": null,
  "buyer_principal_id": "uuid",
  "seller_reservoir_id": "uuid",
  "target_reservoir_id": null,
  "requested_volume_liters": 500,
  "price_quote_total": 1500,
  "currency": "AOA",
  "seller_profile": {
    "principal_id": "uuid",
    "display_name": "Seller A",
    "avatar_uri": null
  },
  "buyer_confirmation": {
    "confirmed_delivery_at": null,
    "confirmed_delivery_at_client": null,
    "confirmed_volume_liters": null,
    "note": null
  },
  "seller_confirmation": {
    "confirmed_delivery_at": null,
    "confirmed_delivery_at_client": null,
    "confirmed_volume_liters": null,
    "note": null
  },
  "review": null
}
```

---

### 7.4 Order transition endpoints (explicit; no action dispatcher)
All are:
- **Auth**: Bearer required  
- **Support tooling**: internal ops admin may bypass account scoping

**Response `200`**:

```json
{ "order_id": "uuid", "order_code": "ORD-7H3K2Q9D1FJ2", "status": "..." }
```

Endpoints (empty body):
- `POST /v1/accounts/{account_id}/orders/{order_id}/accept`
- `POST /v1/accounts/{account_id}/orders/{order_id}/reject`
- `POST /v1/accounts/{account_id}/orders/{order_id}/cancel`
- `POST /v1/accounts/{account_id}/orders/{order_id}/dispute`

#### 7.4a `POST /v1/accounts/{account_id}/orders/{order_id}/confirm-delivery`
**Request**:

```json
{
  "confirmed_delivery_at": "2026-02-01T18:07:00Z",
  "confirmed_volume_liters": 500,
  "note": "optional"
}
```

Fields:
- `confirmed_volume_liters` (required, > 0)
- `confirmed_delivery_at` (optional, client-asserted timestamp)
- `note` (optional)

Common errors:
- `409 INVALID_ORDER_STATE`

---

### 7.5 Reviews

#### 7.5a `POST /v1/accounts/{account_id}/orders/{order_id}/reviews`
**Auth**: Bearer required  
**Support tooling**: internal ops admin may bypass account scoping

**Request**:

```json
{ "rating": 5, "comment": "Great" }
```

**Response `200`**:

```json
{ "review_id": "uuid" }
```

Errors:
- `409 REVIEW_ALREADY_EXISTS`

#### 7.5b `GET /v1/accounts/{account_id}/orders/{order_id}/reviews`
**Auth**: Bearer required  
**Support tooling**: internal ops admin may bypass account scoping

**Response `200`**:

```json
{
  "items": [
    {
      "review_id": "uuid",
      "rating": 5,
      "comment": "Great",
      "created_at": "2026-02-01T18:07:00Z"
    }
  ]
}
```

---

## Required sequences (the exact order a client should follow)

### A) Seller “set pricing” screen (must show existing location + existing price rules)
1. `GET /v1/accounts/{account_id}/seller-profile`
   - If `404`: `POST /v1/accounts/{account_id}/seller-profile` with `{ "status": "ACTIVE" }`
   - If `status != ACTIVE`: `PATCH /v1/accounts/{account_id}/seller-profile` with `{ "status": "ACTIVE" }`
2. `GET /v1/accounts/{account_id}/reservoirs`
   - Use `location` and `location_updated_at` to display current reservoir location
3. For selected `reservoir_id`:
   - If location missing: `PATCH /v1/reservoirs/{reservoir_id}` with `{ "location": { "lat": ..., "lng": ... } }`
   - Load existing rules: `GET /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules`
   - Add rules: `POST /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules`

### B) Seller “make my reservoir appear in public listings”
1. Ensure seller profile is ACTIVE (same as above)
2. Ensure reservoir has location:
   - `PATCH /v1/reservoirs/{reservoir_id}` with `{ "location": { "lat": ..., "lng": ... } }`
3. Ensure seller availability is AVAILABLE:
   - `PATCH /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}` with `{ "seller_availability_status": "AVAILABLE" }`
4. Optional: create price rules for quoting
5. Buyer can discover via:
   - `GET /v1/marketplace/reservoir-listings`

## Marketplace frontend integration guide (v1, canonical for client sequencing)

This doc is written for frontend/mobile clients integrating the **Marketplace** surfaces.

It answers, unambiguously:
- What must exist **before** a reservoir can appear as a marketplace listing
- What endpoints the client must call (and in what order) to create and maintain seller listings
- What parameters are required vs optional (and what happens when omitted)
- Which flows require **internal ops admin** vs normal users

Canonical contract references (routes + shapes):
- `docs/architecture/jila_api_backend_api_contract_v1.md`
- `docs/architecture/api_contract/07_supply_points.md`
- `docs/architecture/api_contract/08_marketplace_listings.md`
- `docs/architecture/api_contract/09_orders_reviews.md`
- `docs/architecture/api_contract/05_reservoirs_readings_location.md`

---

### Concepts and data model (what you’re configuring)

#### Reservoir (core object)
- **Meaning**: a physical tank / water container.
- **Canonical storage**: `reservoirs` table (plus `reservoir_readings`, `devices`, etc.)
- **Canonical location fields**: `reservoirs.location` and `reservoirs.location_updated_at` (single unified location).

#### Seller profile (seller-mode switch)
- **Meaning**: enables “seller mode” for an organization account and gates seller endpoints.
- **Canonical storage**: `seller_profiles` table (`principal_id`, `status`).
- **Display identity**: shared identity fields (e.g. `display_name`, `avatar_uri`) live in `principal_profiles` (not seller-only).

#### Seller reservoir (marketplace configuration for an existing reservoir)
- **Meaning**: the same reservoir, but viewed through marketplace configuration (e.g. availability to sell).
- **Canonical storage**: still `reservoirs`, using seller-related columns (e.g. `seller_availability_status`).

#### Price rules (seller pricing configuration)
- **Meaning**: pricing bands per reservoir + currency + volume range.
- **Canonical storage**: `reservoir_price_rules` table.

#### Marketplace listing (buyer-facing discovery)
- **Meaning**: a reservoir that is eligible to appear in public marketplace results.
- **Eligibility in v1 (server-side)**:
  - Seller profile is **ACTIVE**
  - Reservoir is **AVAILABLE** for selling (`reservoirs.seller_availability_status = 'AVAILABLE'`)
  - Reservoir has a non-null location (`reservoirs.location IS NOT NULL`)
  - Price rules are not required to appear, but they are required to show a quote for a given `(currency, volume)` pair

---

### Auth and “internal ops admin” (support tooling)

Most marketplace endpoints are account-scoped and normally require org roles on the referenced account.

In v1, **internal ops admins may bypass account scoping** for support/admin tooling:
- Seller profile endpoints (`/seller-profile`)
- Seller reservoir endpoints (`/seller/reservoirs...`)
- Orders endpoints (`/orders...`)

Important:
- `account_id` must still refer to an **organization account principal** (UUID).
- When an internal ops admin uses an account-scoped marketplace endpoint, the request acts on the **account principal**.

Internal ops admin is a special backend-defined role (DB-backed); clients should treat it as “admin portal / support tooling only”.

---

### Public discovery flows (no auth required)

#### A) Community supply points (public)

##### `GET /v1/supply-points`
- **Auth**: Public
- **Optional query params**:
  - `lat`, `lng`: optional; geo filtering only applied when **both provided**
  - `within_radius_km`: optional; when geo filtering is active
  - `kind`, `operational_status`, `availability_status`: optional filters
- **Server behavior**:
  - If `lat`/`lng` omitted: returns a recent slice (limit 200)
  - If `lat`/`lng` provided but `within_radius_km` omitted: defaults to **10km**
  - If `within_radius_km` > 10km: clamps to **10km**

This endpoint is the “marketplace” client’s way to show **community-based water points**.

#### B) Marketplace reservoir listings (public)

##### `GET /v1/marketplace/reservoir-listings`
- **Auth**: Public
- **Optional query params**:
  - `lat`, `lng`, `within_radius_km`: optional geo filter (same default/clamp semantics as above)
  - `requested_volume_liters`: optional
  - `currency`: optional 3-letter currency code
- **Price quoting behavior**:
  - If both `requested_volume_liters > 0` and a valid 3-letter `currency` are provided, the server attempts to match a price rule and returns `currency` + `estimated_total`.
  - Otherwise, it returns listings without a quote (`currency` and `estimated_total` are `null`).

---

### Seller onboarding & listing setup (authenticated)

The seller experience typically needs these screens:
- “Enable seller mode”
- “Select reservoir to sell from”
- “Ensure reservoir location”
- “Set seller availability”
- “Configure price rules”

Below is a recommended sequence that avoids the confusion we’ve seen in logs.

#### 0) Check / enable seller mode (required before seller endpoints)

##### Check seller profile exists
- `GET /v1/accounts/{account_id}/seller-profile`
  - `200`: seller profile exists
  - `404`: seller profile does not exist

##### Create seller profile (first-time)
- `POST /v1/accounts/{account_id}/seller-profile`
- **Body (required)**:
  - `status`: `ACTIVE|INACTIVE`
- **Body (optional)**:
  - `display_name` (stored in `principal_profiles.display_name`)

##### Activate/deactivate seller profile
- `PATCH /v1/accounts/{account_id}/seller-profile`
- **Body (optional)**:
  - `status`: `ACTIVE|INACTIVE`

If seller profile is missing or not ACTIVE, many seller-mode endpoints will return:
- `403 FORBIDDEN` with message **“Seller profile not active”**

#### 1) Load reservoirs owned by the account (for the seller to choose from)

##### `GET /v1/accounts/{account_id}/reservoirs`
- **Auth**: Bearer token required
- **Response includes**: `location` and `location_updated_at` per reservoir item (if present)

If the seller needs full details for a single reservoir:
- `GET /v1/reservoirs/{reservoir_id}`

#### 2) Ensure the reservoir has a location (required for marketplace discoverability)

##### Read current location
- `GET /v1/reservoirs/{reservoir_id}`

##### Update location (unified; no ping endpoint)
- `PATCH /v1/reservoirs/{reservoir_id}`
- **Body (partial)**:
  - `location` (required if updating location):
    - `{ "lat": <float>, "lng": <float> }`
- Notes:
  - Clients do **not** send `location_updated_at`
  - Do **not** rely on extra fields like `source` in the request; the server derives event metadata

#### 3) Ensure seller availability is set (controls whether listing can appear)

##### List seller reservoirs (seller-mode view)
- `GET /v1/accounts/{account_id}/seller/reservoirs`
- **Auth**: Bearer token required
- **What it returns**: seller listing state (e.g. `seller_availability_status`), not full reservoir details.

##### Update seller availability for a reservoir
- `PATCH /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}`
- **Body (required)**:
  - `{ "seller_availability_status": "AVAILABLE" | "UNAVAILABLE" }`

#### 4) Configure price rules (required for quotes, optional for being listed)

##### List existing price rules for a reservoir
- `GET /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules`

##### Create a new price rule
- `POST /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules`
- **Body (required)**:
  - `currency` (3 letters)
  - `min_volume_liters` (>= 0)
  - `max_volume_liters` (> 0 and must be >= min)
  - `base_price_per_liter` (> 0)
- **Body (optional)**:
  - `delivery_fee_flat` (>= 0)

Common deterministic error:
- `409 PRICE_RULE_OVERLAP` when ranges overlap for the same reservoir/currency.

---

### Buyer ordering flow (authenticated)

#### 1) Create order (requires a price rule match)
- `POST /v1/accounts/{account_id}/orders`
- **Header (optional)**: `Idempotency-Key`
- **Body**:
  - `seller_reservoir_id` (**required**)
  - `target_reservoir_id` (optional)
  - `requested_fill_mode` (**required**): `FILL_TO_FULL|VOLUME_LITERS`
  - `requested_volume_liters` (**required when** fill mode = `VOLUME_LITERS`)
  - `currency` (**required**, 3 letters)

#### 2) View orders
- `GET /v1/accounts/{account_id}/orders`
- `GET /v1/accounts/{account_id}/orders/{order_id}`

#### 3) Order transitions (explicit endpoints)
- `POST /v1/accounts/{account_id}/orders/{order_id}/accept` (seller)
- `POST /v1/accounts/{account_id}/orders/{order_id}/reject` (seller)
- `POST /v1/accounts/{account_id}/orders/{order_id}/cancel` (buyer)
- `POST /v1/accounts/{account_id}/orders/{order_id}/confirm-delivery` (buyer or seller)
- `POST /v1/accounts/{account_id}/orders/{order_id}/dispute` (buyer)

#### 4) Reviews
- Create: `POST /v1/accounts/{account_id}/orders/{order_id}/reviews`
- List: `GET /v1/accounts/{account_id}/orders/{order_id}/reviews`

---

### SupplyPoint nomination & moderation (mix of public + admin)

#### Nominate (authenticated user)
- `POST /v1/supply-points`

#### Moderation (internal ops admin only)
- `POST /v1/supply-points/{supply_point_id}/verify`
- `POST /v1/supply-points/{supply_point_id}/reject`
- `POST /v1/supply-points/{supply_point_id}/decommission`

#### Operational status updates (authenticated; operator-grade)
- `PATCH /v1/supply-points/{supply_point_id}`
- Notes:
  - Some update types require operator-grade permission.
  - Internal ops admins may bypass operator gating for support/admin tooling.

---

### Minimal “happy path” sequences (copy/paste checklist)

#### Seller: make a reservoir show up in public listings
1. `GET /v1/accounts/{account_id}/seller-profile`
2. If missing: `POST /v1/accounts/{account_id}/seller-profile` with `{ "status": "ACTIVE" }`
3. `GET /v1/accounts/{account_id}/reservoirs` (pick `reservoir_id`)
4. `PATCH /v1/reservoirs/{reservoir_id}` with `{ "location": { "lat": ..., "lng": ... } }`
5. `PATCH /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}` with `{ "seller_availability_status": "AVAILABLE" }`
6. Optional (for quotes): create price rules via `/price-rules`
7. Buyer can now call `GET /v1/marketplace/reservoir-listings`

#### Seller: configure pricing (and see what’s already there)
1. `GET /v1/accounts/{account_id}/reservoirs` (read current `location`)
2. `GET /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules` (read existing rules)
3. `POST /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules` (add/adjust rules)

