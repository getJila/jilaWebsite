# Buyer/Seller Context Handling (Jila API v1)

Date: 2026-01-02  
Repo: `JilaAPI`

This document explains how the API currently handles “buyer vs seller mode” and what, if anything, changes at the HTTP endpoint level when a user switches modes in a client (e.g., mobile app).

## 1) The core idea: context is the JWT `principal_id` (not a “mode” flag)

For authenticated HTTP requests, the backend derives request context from the `Authorization: Bearer <access_token>` header.

- `app/dependencies/auth.py` decodes the JWT and builds an `AuthContext` containing:
  - `user_id`
  - `principal_id`
  - `session_id`
- That `principal_id` is the primary “who is calling” identifier used across modules for authorization and scoping.

There is **no API-level “buyer mode” or “seller mode” selector** (no `X-Context` header, no “current_mode” stored on the session).

Instead, “buyer vs seller” is handled as:

1. **A client-side UI concept** (which screens the user sees).
2. **A per-request server-side authorization decision** based on:
   - which endpoint is called, and
   - whether the caller’s `principal_id` matches the role required by the underlying data (order row / reservoir ownership / access grants).

## 2) What “switching modes” means in practice

When the user switches from a buyer-oriented screen to a seller-oriented screen, the client typically:

- keeps using the same access token (same `principal_id`), and
- starts calling a different set of endpoints (seller-oriented endpoints),
  or calls shared endpoints with a different filter (e.g. `/me/orders?view=seller`).

## 3) User journeys (narrative use cases)

### Use case A: User logs in and uses core water monitoring

1. User logs in:
   - `POST /v1/auth/login` → `access_token` + `refresh_token`
   - The access token includes `principal_id` (minted at login).
2. App loads “who am I” / subscription:
   - `GET /v1/me` returns the current `principal_id` (and org memberships, if any).
3. App loads identity surface (shared profile):
   - `GET /v1/me/profile`
   - Optional: set profile photo
     - `POST /v1/me/profile/avatar-upload` (mint upload URL)
     - upload bytes to the returned `upload_url`
     - `PATCH /v1/me/profile` with the returned `avatar_uri`
4. App loads reservoirs the principal can see:
   - `GET /v1/accounts/{account_id}/reservoirs`
5. App reads/updates reservoir information (RBAC scoped by `principal_id`):
   - `GET /v1/reservoirs/{reservoir_id}`
   - `GET /v1/reservoirs/{reservoir_id}/readings`
   - `PATCH /v1/reservoirs/{reservoir_id}` (includes general settings; also includes `seller_availability_status`, which is seller-relevant but lives on the canonical reservoir record)

Nothing about this flow sets a “mode”. It’s just the principal calling core-water endpoints.

### Use case B: Same user switches to “buyer context” (marketplace buying)

The user is still the same `principal_id`. The only thing that changes is which marketplace endpoints the app calls.

1. App shows marketplace browse:
   - `GET /v1/marketplace/reservoir-listings` (public; no auth required)
   - Optionally: `GET /v1/supply-points` (public; no auth required)
2. App creates an order:
   - `POST /v1/accounts/{account_id}/orders`
   - The backend binds the order’s buyer identity to the caller via:
     - `buyer_principal_id = auth.principal_id`
   - (Optional but recommended for mobile/offline safety) supply `Idempotency-Key` header.
3. App shows “my orders (buyer)”:
   - `GET /v1/accounts/{account_id}/orders?view=buyer`
4. App opens a specific order:
   - `GET /v1/accounts/{account_id}/orders/{order_id}` (shared: buyer or seller can fetch if authorized)
5. Buyer-only mutation example:
   - `POST /v1/accounts/{account_id}/orders/{order_id}/cancel` is enforced as buyer-only by checking `order.buyer_principal_id == auth.principal_id`.

In short: “buyer context” is implicit in the fact the caller is creating/managing orders where they are the buyer principal.

### Use case C: Same user switches to “seller mode” (marketplace selling)

Again, the `principal_id` in the token does not change. Seller mode is enabled by (a) having a seller profile and (b) having management access over reservoirs that can receive orders.

1. App enables seller mode (one-time):
   - `POST /v1/accounts/{account_id}/seller-profile`
   - Seller-profile dependent endpoints require the seller profile to be `ACTIVE`.
2. App loads “seller reservoirs I can manage”:
   - `GET /v1/accounts/{account_id}/seller/reservoirs`
   - This is based on:
     - reservoir ownership (`reservoirs.owner_principal_id`), and/or
     - access grants (`access_grants` role `OWNER`/`MANAGER` on `RESERVOIR`, `SITE`, or `ORG`).
3. App updates seller listing availability for a reservoir:
   - `PATCH /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}` (seller-focused convenience endpoint)
   - Or alternatively uses the canonical reservoir patch endpoint:
     - `PATCH /v1/reservoirs/{reservoir_id}` with `seller_availability_status`
4. App sets pricing rules:
   - `POST /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules`
5. App shows “my orders (seller)”:
   - `GET /v1/accounts/{account_id}/orders?view=seller`
6. Seller-only mutations (authorization is reservoir-manage access):
   - `POST /v1/accounts/{account_id}/orders/{order_id}/accept`
   - `POST /v1/accounts/{account_id}/orders/{order_id}/reject`

Shared mutation example:
- `POST /v1/accounts/{account_id}/orders/{order_id}/confirm-delivery` is allowed for both sides:
  - If `auth.principal_id == order.buyer_principal_id`, the backend treats it as buyer confirmation.
  - Otherwise the backend requires reservoir manage access and treats it as seller confirmation.

## 4) Which endpoints are “shared” vs “context-specific”

### Shared (same endpoint, role determined by data / query params)

- `GET /v1/accounts/{account_id}/orders` (filter via `view=buyer|seller|all`)
- `GET /v1/accounts/{account_id}/orders/{order_id}` (buyer or seller visibility)
- `POST /v1/accounts/{account_id}/orders/{order_id}/confirm-delivery` (buyer or seller; side inferred)
- `POST /v1/accounts/{account_id}/orders/{order_id}/dispute` (shared visibility; behavior depends on authorization checks in service)
- `POST /v1/accounts/{account_id}/orders/{order_id}/reviews` (shared visibility; behavior depends on authorization checks in service)
- Core water reservoir endpoints (`/v1/accounts/{account_id}/reservoirs`, `/v1/reservoirs/...`) are not “buyer vs seller” by path; they’re RBAC-scoped to the principal and include a few seller-related fields on the canonical reservoir record.

### Buyer-oriented (primarily used from buyer screens)

- `GET /v1/marketplace/reservoir-listings` (public discovery)
- `POST /v1/accounts/{account_id}/orders` (creates orders; binds buyer to `auth.principal_id`)
- `POST /v1/accounts/{account_id}/orders/{order_id}/cancel` (buyer-only)

### Seller-oriented (primarily used from seller screens)

- `POST /v1/accounts/{account_id}/seller-profile`, `PATCH /v1/accounts/{account_id}/seller-profile`
- `GET /v1/accounts/{account_id}/seller/reservoirs`
- `PATCH /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}`
- `POST /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules`
- `POST /v1/accounts/{account_id}/orders/{order_id}/accept`, `POST /v1/accounts/{account_id}/orders/{order_id}/reject` (seller-side order state transitions)

## 5) Firestore/Firebase note (mobile “contextual piping”)

If the mobile client reads via Firestore, the same concept applies:

- `POST /v1/auth/firebase/custom-token` mints a Firebase custom token with the same `principal_id` claim as the Jila access token.
- Firestore data is organized per principal (e.g. `principals/{principal_id}/...`).

So switching between buyer and seller screens generally does **not** require a different Firebase token. It requires reading different collections/documents under the **same** `principal_id` subtree (e.g., orders list vs seller-managed reservoirs), as long as the backend mirror is writing those documents for that principal.
