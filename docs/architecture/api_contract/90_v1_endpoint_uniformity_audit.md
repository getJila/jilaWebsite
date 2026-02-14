## Jila API Backend – V1 Endpoint Uniformity Audit (Working Document)

Date: 2026-01-18

Scope: `/v1/*` HTTP endpoints as implemented in `app/` and documented in `docs/architecture/api_contract/*`.

Goal: identify places where V1 offers multiple ways to achieve the same outcome (alias-like surfaces), and propose a more uniform “one canonical way” endpoint shape for each outcome.

Note: this document is advisory. It does not change the canonical contract by itself.

---

## 1) Inventory (current V1 surface)

Source: FastAPI route decorators in `app/` (105 endpoints).

Contract parity check (docs vs code):
- Canonical contract docs match the running code (no known drift).

Grouped by top-level resource:

- `health`
  - `GET /v1/health`

- `auth` / `setup`
  - `POST /v1/setup/bootstrap-admin`
  - `POST /v1/auth/register`
  - `POST /v1/auth/request-identifier-verification`
  - `POST /v1/auth/verify-identifier`
  - `POST /v1/auth/login`
  - `POST /v1/auth/refresh`
  - `POST /v1/auth/logout`
  - `POST /v1/auth/request-password-reset`
  - `POST /v1/auth/reset-password`
  - `POST /v1/auth/request-account-erasure`
  - `POST /v1/auth/confirm-account-erasure`
  - `POST /v1/auth/firebase/custom-token`

- `me` / `accounts`
  - `GET /v1/me`
  - `GET /v1/accounts/{account_id}/reservoirs`
  - `GET /v1/accounts/{account_id}/orders`
  - `GET /v1/me/profile`
  - `PATCH /v1/me/profile`
  - `POST /v1/me/profile/avatar-upload`

- `accounts` / membership / invites / portal surfaces
  - `POST /v1/accounts`
  - `GET /v1/accounts/{account_id}`
  - `GET /v1/accounts/{account_id}/dashboard-stats`
  - `GET /v1/accounts/{account_id}/members`
  - `POST /v1/accounts/{account_id}/members/invite`
  - `PATCH /v1/accounts/{account_id}/members/{user_id}`
  - `POST /v1/accounts/{account_id}/members/{user_id}/revoke`
  - `GET /v1/accounts/{account_id}/invites`
  - `POST /v1/accounts/{account_id}/invites/{invite_token_id}/revoke`
  - `POST /v1/org-invites/resolve`
  - `POST /v1/org-invites/accept`
  - `GET /v1/accounts/{account_id}/profile`
  - `PATCH /v1/accounts/{account_id}/profile`
  - `POST /v1/accounts/{account_id}/profile/avatar-upload`

- `sites`
  - `POST /v1/accounts/{account_id}/sites`
  - `GET /v1/accounts/{account_id}/sites`
  - `GET /v1/sites/{site_id}`
  - `PATCH /v1/sites/{site_id}`
  - `DELETE /v1/sites/{site_id}`

- `reservoirs` / reservoir invites
  - `POST /v1/accounts/{account_id}/reservoirs`
  - `GET /v1/reservoirs/{reservoir_id}`
  - `PATCH /v1/reservoirs/{reservoir_id}`
  - `DELETE /v1/reservoirs/{reservoir_id}`
  - `GET /v1/reservoirs/{reservoir_id}/readings`
  - `POST /v1/reservoirs/{reservoir_id}/manual-reading`
  - `POST /v1/reservoirs/{reservoir_id}/share`
  - `POST /v1/reservoir-invites/resolve`
  - `POST /v1/reservoir-invites/accept`

- `devices` / `firmware`
  - `GET /v1/accounts/{account_id}/devices`
  - `GET /v1/internal/devices/{device_id}/overview`
  - `PATCH /v1/accounts/{account_id}/devices/{device_id}`
  - `DELETE /v1/accounts/{account_id}/devices/{device_id}`
  - `POST /v1/internal/devices/{device_id}/register`
  - `POST /v1/accounts/{account_id}/devices/attach`
  - `POST /v1/accounts/{account_id}/devices/{device_id}/detach`
  - `GET /v1/accounts/{account_id}/devices/{device_id}/config`
  - `PUT /v1/accounts/{account_id}/devices/{device_id}/config`
  - `GET /v1/accounts/{account_id}/devices/{device_id}/telemetry/latest`
  - `GET /v1/firmware/releases`
  - `POST /v1/internal/firmware/releases`
  - `POST /v1/accounts/{account_id}/devices/{device_id}/firmware-update`

- `supply-points` (community discovery + ops moderation)
  - `GET /v1/supply-points` (public)
  - `GET /v1/supply-points/{supply_point_id}` (public)
  - `POST /v1/supply-points`
  - `PATCH /v1/supply-points/{supply_point_id}`
  - `POST /v1/supply-points/{supply_point_id}/verify`
  - `POST /v1/supply-points/{supply_point_id}/reject`
  - `POST /v1/supply-points/{supply_point_id}/decommission`

- `marketplace` / `seller` / `orders`
  - `GET /v1/marketplace/reservoir-listings` (public)
  - `GET /v1/accounts/{account_id}/seller-profile`
  - `POST /v1/accounts/{account_id}/seller-profile`
  - `PATCH /v1/accounts/{account_id}/seller-profile`
  - `GET /v1/accounts/{account_id}/seller/reservoirs`
  - `PATCH /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}`
  - `POST /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules`
  - `GET /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules`
  - `POST /v1/accounts/{account_id}/orders`
  - `GET /v1/accounts/{account_id}/orders/{order_id}`
  - `POST /v1/accounts/{account_id}/orders/{order_id}/accept`
  - `POST /v1/accounts/{account_id}/orders/{order_id}/reject`
  - `POST /v1/accounts/{account_id}/orders/{order_id}/cancel`
  - `POST /v1/accounts/{account_id}/orders/{order_id}/confirm-delivery`
  - `POST /v1/accounts/{account_id}/orders/{order_id}/dispute`
  - `POST /v1/accounts/{account_id}/orders/{order_id}/reviews`
  - `GET /v1/accounts/{account_id}/orders/{order_id}/reviews`

- `subscriptions`
  - `GET /v1/accounts/{account_id}/subscription`
  - `PATCH /v1/accounts/{account_id}/subscription`

- `alerts`
  - `GET /v1/accounts/{account_id}/alerts`
  - `POST /v1/accounts/{account_id}/alerts/{alert_id}/mark-read`
  - `GET /v1/accounts/{account_id}/events`
  - `GET /v1/accounts/{account_id}/events/{event_id}`

- `notifications` / `media`
  - `GET /v1/accounts/{account_id}/notification-preferences`
  - `PATCH /v1/accounts/{account_id}/notification-preferences`
  - `POST /v1/accounts/{account_id}/push-tokens`
  - `GET /v1/accounts/{account_id}/push-tokens`
  - `DELETE /v1/accounts/{account_id}/push-tokens/{push_token_id}`
  - `GET /v1/media/avatars/{principal_id}/{avatar_id}`

- `admin` (internal ops)
  - `GET /v1/internal/me`
  - `GET /v1/internal/health`
  - `GET /v1/internal/stats`
  - `GET /v1/internal/users`
  - `GET /v1/internal/users/{user_id}`
  - `POST /v1/internal/users/{user_id}/lock`
  - `POST /v1/internal/users/{user_id}/unlock`
  - `POST /v1/internal/users/{user_id}/disable`
  - `POST /v1/internal/users/{user_id}/enable`
  - `POST /v1/internal/users/{user_id}/sessions/revoke`
  - `GET /v1/internal/orgs`
  - `POST /v1/internal/billing/payments`
  - `POST /v1/internal/members/grant`
  - `POST /v1/internal/members/revoke`
  - `POST /v1/accounts/{account_id}/erase`
  - `GET /v1/internal/diagnostics/events`
  - `GET /v1/internal/diagnostics/firestore`
  - `GET /v1/internal/diagnostics/telemetry`
  - `GET /v1/internal/device-inventory/units`
  - `GET /v1/internal/device-inventory/units/{device_id}`
  - `POST /v1/internal/device-inventory/units/{device_id}`
  - `GET /v1/internal/devices/{device_id}/overview`

---

## 2) Where V1 currently behaves “alias-like” (multiple ways to achieve the same outcome)

### 2.1 Device attachment (unified)

Outcomes:
- Attach a device to a reservoir.

Current way:
- `POST /v1/accounts/{account_id}/devices/attach` with `serial_number` (no `device_id` in request)

Notes:
- The attach surface is now unified and no longer duplicated.

### 2.2 Subscriptions: single plan change endpoint

Outcomes:
- Change the plan id of the caller’s subscription.

Current way:
- `PATCH /v1/accounts/{account_id}/subscription` with `{ "plan_id": "..." }`

Notes:
- Plan changes are performed via this single plan change surface.

### 2.3 Session bootstrap: `GET /v1/me` only

Outcomes:
- Return current identity + org memberships + subscription state.

Current way:
- `GET /v1/me`

Notes:
- Portal bootstrap should rely on `GET /v1/me` rather than a separate portal-only alias endpoint.

### 2.4 Account membership revocation has two shapes (admin vs org-RBAC)

Outcomes:
- Revoke a user's membership/access in an account.

Current ways:
- RBAC surface: `POST /v1/accounts/{account_id}/members/{user_id}/revoke`
- Admin surface: `POST /v1/internal/members/revoke` with `{ "org_principal_id": "...", "user_id": "..." }`

Why this is alias-like:
- Both reach the same end state (membership revoked) with different path shapes and request payload conventions.

Suggested canonical target:
- Prefer one canonical revoke shape (either path-param or body), and rely on RBAC/admin-bypass rules rather than separate URL shapes for the same operation.

---

## 3) Inconsistencies that increase cognitive load (even if not true aliases)

### 3.1 Membership nouns are consistent (keep it that way)

Current (implemented) account-first shapes:
- Read: `GET /v1/accounts/{account_id}/members`
- Mutate: `POST /v1/accounts/{account_id}/members/invite`, `POST /v1/accounts/{account_id}/members/{user_id}/revoke`

Doc drift to fix:
- None currently identified for membership nouns (account-first `.../members/*` is consistently implemented).

### 3.2 “Verb-in-path” action endpoints are not uniform

Examples:
- Order and SupplyPoint state transitions are expressed as explicit endpoints.
- Remaining verb-in-path endpoints include:
  - `POST /v1/reservoirs/{reservoir_id}/manual-reading`
  - `POST /v1/accounts/{account_id}/devices/{device_id}/detach`
  - `POST /v1/accounts/{account_id}/devices/{device_id}/firmware-update`
  - `POST /v1/accounts/{account_id}/alerts/{alert_id}/mark-read`

Suggestion:
- Pick one action convention for state transitions that do not naturally map to CRUD.
  - Option A (recommended for new work): explicit endpoints (e.g., `POST /v1/<resource>/{id}/accept`, `.../cancel`, `.../confirm-delivery`).
  - Option B: `POST /v1/<resource>/{id}:<action>` (compact but less common across tooling).
  - Option C (CRUD refactor): convert into subresources where possible (e.g. readings as `POST /reservoirs/{id}/readings`).

The key is not which option you pick, but that you pick one and stop adding new one-off verbs.

### 3.3 “Create” verbs appear in paths for some resources

Examples:
- `POST /v1/internal/devices/{device_id}/register` (vs a typical `POST /v1/accounts/{account_id}/devices`)

Suggestion:
- Prefer resource creation via `POST /v1/<resource>` unless there is a strong reason to expose a separate verb (and if so, keep the verb consistently applied across similar flows).

### 3.4 List filtering is inconsistent across account-scoped lists

Observation:
- Some list endpoints expose filters (e.g., devices), while others rely on client-side filtering.

Suggestion:
- Adopt a uniform query-parameter filtering convention for account-scoped list endpoints.
- Keep filters optional and additive, with defaults preserving existing behavior.

### 3.5 `/admin/*` surface is implemented across multiple modules

Examples:
- `/v1/internal/device-inventory/*` GETs are in `admin_portal`, while the POST upsert is in `core_water`.
- `/v1/internal/devices/{device_id}/overview` lives in `admin_portal`, while `/v1/internal/devices/{device_id}/register` and firmware releases live in `core_water`.

Suggestion:
- Consider a single “owner” module for `/admin/*` endpoints to prevent fragmentation and reduce perceived aliasing (“where do I go to do admin device things?”).

---

## 4) Recommended “one way” uniformity targets (proposal)

This is a proposal for where the API could land (post-deprecation) to minimize “same effect, different verbs” complexity.

- Subscriptions:
- Canonical: `PATCH /v1/accounts/{account_id}/subscription { plan_id }`

- Devices:
  - Canonical create: `POST /v1/accounts/{account_id}/devices` (or keep `register` but apply consistently across other “create-like” flows)
  - Canonical attach: `POST /v1/accounts/{account_id}/devices/attach { serial_number, reservoir_id } -> { status, device_id }`
  - Consider converging remaining device verbs into the same convention:
    - Option A: explicit endpoints (e.g., `POST /v1/accounts/{account_id}/devices/{device_id}/detach`)
    - Option B: a single attachment subresource (`PUT/DELETE /v1/accounts/{account_id}/devices/{device_id}/attachment`)

- Account membership management:
  - Canonical noun: choose `members` (or `users`) and align reads+writes.
  - Prefer `DELETE` for revocation where feasible (idempotent deletes are easy to reason about).

- Alerts:
  - Canonical mark-read: keep the account-scoped surface but standardize shape:
    - Option A: explicit endpoint (current): `POST /v1/accounts/{account_id}/alerts/{alert_id}/mark-read`
    - Option B: `PATCH /v1/accounts/{account_id}/alerts/{alert_id} { read_at }`

- Contract doc hygiene (high leverage):
  - Update flow diagrams and any notes referencing:
    - Any non-canonical endpoint variants that are not present in code

---

## 5) Change policy (single canonical way)

- Ship one canonical endpoint shape per outcome; avoid alias-like alternatives.
- When an endpoint shape changes, update the canonical contract and the implementation in lockstep.
