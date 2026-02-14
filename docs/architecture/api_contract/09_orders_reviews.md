## Jila API Backend – API Contract (v1) — Extracted section (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

## 7. Orders & reviews

### 7.1 `POST /v1/accounts/{org_principal_id}/orders`

`org_principal_id`:
- Organization principal: caller must have an org role (`OWNER|MANAGER|VIEWER`) on that organization.

Auth (support tooling):
- Internal ops admin may bypass account scoping for support/admin tooling.

Request:

Optional headers:
- `Idempotency-Key: <string>` — enables safe client retries. If the same key is reused with a different
  request payload, the API returns a deterministic `409 IDEMPOTENCY_KEY_CONFLICT`.

```json
{
  "target_reservoir_id": "uuid",
  "requested_fill_mode": "FILL_TO_FULL|VOLUME_LITERS",
  "requested_volume_liters": 500,
  "seller_reservoir_id": "uuid",
  "currency": "AOA"
}
```

Rules:
- In v1, `seller_reservoir_id` is required.
- `DAYS_OF_AUTONOMY` is a UI-only helper: clients compute liters locally and submit
  `requested_fill_mode = VOLUME_LITERS` with `requested_volume_liters`.
- Consumption model inputs that influence “days remaining” (e.g., household size) are modeled **per site**
  (Postgres table `site_consumption_profiles` keyed by `sites.id`). This data is not currently exposed by a
  dedicated v1 HTTP endpoint; clients should treat autonomy as an approximation and avoid assuming server-side
  shared state unless/until an explicit API route is added.
- For `requested_fill_mode = VOLUME_LITERS`, `requested_volume_liters` is required.
- Backend must match exactly one price rule; otherwise fail deterministically.
- Stores price snapshot on the order.

Response `200 OK`:

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

Errors:
- `422 NO_PRICE_RULE_MATCH`
- `409 PRICE_RULE_OVERLAP`
- `409 IDEMPOTENCY_KEY_CONFLICT` (same `Idempotency-Key` reused with a different request)

### 7.2 `GET /v1/accounts/{org_principal_id}/orders`

List orders visible to the referenced account principal.

Auth (support tooling):
- Internal ops admin may bypass account scoping for support/admin tooling.

Query params:
- `view` (optional): `all|buyer|seller` (default `all`)
- `limit` (optional): 1–200 (default 50)
- `cursor` (optional): opaque cursor returned from a previous page

Response `200 OK`:

```json
{
  "items": [
    {
      "order_id": "uuid",
      "order_code": "ORD-7H3K2Q9D1FJ2",
      "status": "CREATED",
      "created_at": "2025-01-01T00:00:00Z",
      "updated_at": "2025-01-01T00:00:00Z",
      "delivered_at": null,
      "requested_volume_liters": 500,
      "price_quote_total": 1500,
      "currency": "AOA",
      "seller_reservoir_id": "uuid",
      "target_reservoir_id": "uuid",
      "seller_profile": {
        "principal_id": "uuid",
        "seller_display_name": "Seller A",
        "avatar_uri": null,
        "verification_status": "VERIFIED",
        "average_rating": 4.8,
        "review_count": 12
      }
    }
  ],
  "next_cursor": "opaque"
}
```

### 7.3 `GET /v1/accounts/{org_principal_id}/orders/{order_id}`

Response `200 OK`: order details.

Auth (support tooling):
- Internal ops admin may bypass account scoping for support/admin tooling.

```json
{
  "order_id": "uuid",
  "order_code": "ORD-7H3K2Q9D1FJ2",
  "status": "ACCEPTED",
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:05:00Z",
  "accepted_at": "2025-01-01T00:05:00Z",
  "cancelled_at": null,
  "delivered_at": null,
  "buyer_principal_id": "uuid",
  "seller_reservoir_id": "uuid",
  "target_reservoir_id": "uuid",
  "requested_volume_liters": 500,
  "price_quote_total": 1500,
  "currency": "AOA",
  "seller_profile": {
    "principal_id": "uuid",
    "seller_display_name": "Seller A",
    "avatar_uri": null,
    "verification_status": "VERIFIED",
    "average_rating": 4.8,
    "review_count": 12
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

### 7.4 Order state transition endpoints (no action dispatcher)

Order state changes are expressed as explicit endpoints (standard REST/RPC hybrid; no `action` field).

Auth:
- Required (Bearer access token)
- Internal ops admin may bypass account scoping for support/admin tooling.

Routes:
- `POST /v1/accounts/{org_principal_id}/orders/{order_id}/accept` (seller)
- `POST /v1/accounts/{org_principal_id}/orders/{order_id}/reject` (seller)
- `POST /v1/accounts/{org_principal_id}/orders/{order_id}/cancel` (buyer)
- `POST /v1/accounts/{org_principal_id}/orders/{order_id}/dispute` (buyer)

Delivery confirmation:
- `POST /v1/accounts/{org_principal_id}/orders/{order_id}/confirm-delivery`

Request (confirm delivery only):

```json
{
  "confirmed_delivery_at": "2025-01-01T00:00:00Z (optional; client-asserted)",
  "confirmed_volume_liters": 500,
  "note": "optional"
}
```

Response `200 OK`:

```json
{ "order_id": "uuid", "order_code": "ORD-7H3K2Q9D1FJ2", "status": "..." }
```

Rules:
- `confirmed_delivery_at` is **client-asserted** (optional) and may reflect offline confirmation time.
- Server records its own authoritative timestamp for auditing and state transitions.
- Calls are retry-safe when the same actor repeats the same request.

Errors (common):
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` (actor not authorized for the transition)
- `404 RESOURCE_NOT_FOUND`
- `409 INVALID_ORDER_STATE`

### 7.5 `POST /v1/accounts/{org_principal_id}/orders/{order_id}/reviews`

Request:

```json
{ "rating": 5, "comment": "Great" }
```

Response `200 OK`:

```json
{ "review_id": "uuid" }
```

Errors:
- `409 REVIEW_ALREADY_EXISTS`

### 7.5a `GET /v1/accounts/{org_principal_id}/orders/{order_id}/reviews`

Auth:
- Required (Bearer access token)

Response `200 OK`:

```json
{
  "items": [
    {
      "review_id": "uuid",
      "rating": 5,
      "comment": "Great",
      "created_at": "2025-01-01T00:00:00Z"
    }
  ]
}
```

---
