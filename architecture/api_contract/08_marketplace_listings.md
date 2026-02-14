## Jila API Backend – API Contract (v1) — Extracted section (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

## 6. Seller mode & marketplace listings

### 6.1 `POST /v1/accounts/{org_principal_id}/seller-profile`

Auth:
- Required (Bearer access token)
- Account-scoped (org): caller must have org role (`OWNER|MANAGER`) for the referenced account
- Internal ops admin may bypass account scoping for support/admin tooling

Request:

```json
{ "status": "ACTIVE", "display_name": "Seller A" }
```

Response `200 OK`:

```json
{ "principal_id": "uuid", "status": "ACTIVE", "display_name": "Seller A" }
```

Notes (standardization; avoid “two sources of truth”):
- `display_name` is the principal’s **shared profile display name**, derived from `users.first_name` + `users.last_name`.
- Clients should treat `GET /v1/me/profile` as the canonical “who am I / how should I be displayed” surface,
  and use `PATCH /v1/me/profile` to update name fields (and `avatar_uri`).
  - For avatars/logos, clients should mint upload URLs via `POST /v1/me/profile/avatar-upload` and then
    set `avatar_uri` to the returned API URL (do not construct blob URLs directly).
- `POST /v1/accounts/{org_principal_id}/seller-profile` exists to enable seller-mode and may accept `display_name` as a convenience for
  initial onboarding, but it does not introduce a separate seller-only identity.

### 6.2 `PATCH /v1/accounts/{org_principal_id}/seller-profile`

Auth:
- Required (Bearer access token)
- Account-scoped (org): caller must have org role (`OWNER|MANAGER`) for the referenced account
- Internal ops admin may bypass account scoping for support/admin tooling

Request:

```json
{ "status": "INACTIVE" }
```

Response `200 OK`: updated seller profile.

```json
{ "principal_id": "uuid", "status": "INACTIVE", "display_name": "Seller A" }
```

Notes:
- This endpoint is also used as a “read my seller profile” call: if no updatable fields are provided
  (e.g., `{}`), the server returns the current seller profile without changing state.

### 6.3 `GET /v1/accounts/{org_principal_id}/seller/reservoirs`

Auth:
- Required (Bearer access token)
- Account-scoped (org): caller must have org role (`OWNER|MANAGER`) for the referenced account
- Internal ops admin may bypass account scoping for support/admin tooling

Query params (optional; v1):
- `site_id` (uuid; filter to a single site)
- `seller_availability_status` (`AVAILABLE|UNAVAILABLE|UNKNOWN`)
- `monitoring_mode` (`MANUAL|DEVICE`)

Response `200 OK`:

```json
{
  "items": [
    {
      "reservoir_id": "uuid",
      "seller_availability_status": "AVAILABLE",
      "name": "Seller Tank A",
      "location": { "lat": -8.84, "lng": 13.23 },
      "location_updated_at": "2026-02-12T00:00:00Z",
      "price_rules": [
        {
          "price_rule_id": "uuid",
          "currency": "AOA",
          "min_volume_liters": 0,
          "max_volume_liters": 1000,
          "base_price_per_liter": 0.05,
          "delivery_fee_flat": 100,
          "created_at": "2026-02-12T00:00:00Z"
        }
      ]
    }
  ]
}
```

Notes:
- `price_rules` is always present; empty list when a reservoir has no configured rules.
- `GET /v1/accounts/{org_principal_id}/seller/reservoirs/{reservoir_id}/price-rules` remains available for
  backward compatibility and direct rule management.

### 6.4 `PATCH /v1/accounts/{org_principal_id}/seller/reservoirs/{reservoir_id}`

Auth:
- Required (Bearer access token)
- Account-scoped (org): caller must have org role (`OWNER|MANAGER`) for the referenced account
- Internal ops admin may bypass account scoping for support/admin tooling

Request:

```json
{ "seller_availability_status": "AVAILABLE" }
```

Response `200 OK`:

```json
{ "reservoir_id": "uuid", "seller_availability_status": "AVAILABLE" }
```

### 6.5 `POST /v1/accounts/{org_principal_id}/seller/reservoirs/{reservoir_id}/price-rules`

Auth:
- Required (Bearer access token)
- Account-scoped (org): caller must have org role (`OWNER|MANAGER`) for the referenced account
- Internal ops admin may bypass account scoping for support/admin tooling


### 6.5a `GET /v1/accounts/{org_principal_id}/seller/reservoirs/{reservoir_id}/price-rules`

Auth:
- Required (Bearer access token)
- Account-scoped (org): caller must have org role (`OWNER|MANAGER`) for the referenced account
- Internal ops admin may bypass account scoping for support/admin tooling

Response `200 OK`:

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
      "created_at": "2025-01-01T00:00:00Z"
    }
  ]
}
```


Request:

```json
{
  "currency": "AOA",
  "min_volume_liters": 0,
  "max_volume_liters": 1000,
  "base_price_per_liter": 0.05,
  "delivery_fee_flat": 100
}
```

Response `200 OK`:

```json
{ "price_rule_id": "uuid" }
```

Errors:
- `409 PRICE_RULE_OVERLAP`

### 6.6 `GET /v1/marketplace/reservoir-listings`

Auth:
- Public (no JWT required)

Query params (all optional):
- `lat`, `lng`, `within_radius_km`
- `requested_volume_liters`, `currency`

Notes (geo semantics; see decision **D-006**):
- If `lat` and `lng` are provided (together), the server applies a geo filter.
- If `within_radius_km` is omitted while `lat`/`lng` are provided, the server uses a default radius of **10km**.
- If `within_radius_km` is provided and is **<= 0**, the server treats the request as unfiltered by radius.
- If `within_radius_km` is provided and is **> 0**, the server uses the provided value (no backend max cap).
- Price quoting is optional:
  - When both `requested_volume_liters > 0` and a valid 3-letter `currency` are provided, `currency` and `estimated_total` are populated.
  - Otherwise, listings are returned without price quotes (`currency` and `estimated_total` are null).

Response `200 OK`:

```json
{
  "items": [
    {
      "seller_reservoir_id": "uuid",
      "seller_principal_id": "uuid",
      "location": { "lat": -8.84, "lng": 13.23 },
      "seller_availability_updated_at": "2025-01-01T00:00:00Z",
      "location_updated_at": "2025-01-01T00:00:00Z",
      "currency": "AOA",
      "estimated_total": 1500
    },
    {
      "seller_reservoir_id": "uuid",
      "seller_principal_id": "uuid",
      "location": { "lat": -8.84, "lng": 13.23 },
      "seller_availability_updated_at": "2025-01-01T00:00:00Z",
      "location_updated_at": "2025-01-01T00:00:00Z",
      "currency": null,
      "estimated_total": null
    }
  ]
}
```

---
