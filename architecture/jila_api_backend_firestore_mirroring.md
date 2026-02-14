## Jila API Backend – Firestore Mirroring (Realtime Read Model) (v0.1)

Goal: allow mobile/web clients to receive **near real-time updates** for authorized data without polling the HTTP API.

Single source of truth note (anti-drift):
- This file is the only canonical definition of the **Firestore mirror layout** and **Security Rules pattern**.
- Other docs may reference it, but should not restate collection/document shapes verbatim.

This is achieved by:
- Keeping **Postgres as the canonical source of truth**.
- Mirroring a **read-optimized projection** of selected entities into **Firestore**.
- Securing Firestore reads with **Firestore Security Rules** based on backend-minted Firebase custom-token claims that reflect Jila’s RBAC (`principals`, `access_grants`).
- Having the **Jila API backend** (server-side) be the only writer to Firestore.

Companion docs:
- `docs/architecture/jila_api_backend_architecture_v_0 (3).md`
- `docs/architecture/jila_api_backend_data_models.md`
- `docs/architecture/jila_api_backend_api_contract_v1.md`
- `docs/architecture/jila_api_backend_state_and_history_patterns.md`

---

## 1. Non-negotiables (anti-drift)

- **Single source of truth**: Postgres remains authoritative. Firestore is a mirror for client UX only.
- **Write path**: clients never write directly to Firestore for domain state changes. All writes go through the Jila API.
- **Auth boundary**: Firestore clients do not use Firebase as an identity provider. Jila remains canonical:
  - Clients authenticate to **Jila API** and receive a Jila JWT.
  - The backend mints a Firebase **custom token** containing Jila-derived claims (for Firestore Security Rules).
  - Firestore Security Rules enforce access using those claims; there is no Firebase login/OAuth flow for Jila users.
- **RBAC parity**: Firestore mirrors must respect the same access decisions as the API (`access_grants`).

Public browsing note (important):
- Firestore is **not** used for unauthenticated browsing in v1.
- The “no account” experience (community SupplyPoints map, public seller listings discovery) is served by the **HTTP API public read endpoints** (see the API contract), not Firestore.

---

## 2. Authentication model (how clients get Firestore access)

### 2.1 Why we need a token exchange
Firestore Security Rules validate `request.auth` via Firebase-issued tokens; they do not validate arbitrary third-party JWTs directly.

We keep Jila as the canonical auth system and use a backend-minted Firebase custom token solely as a mechanism to carry Jila claims into Firestore Security Rules.

### 2.2 Canonical flow (recommended)
1. Client authenticates against Jila API as usual, receives Jila JWT (`Authorization: Bearer <jwt>`).
2. Client calls a Jila endpoint to request a Firebase token:
   - `POST /v1/auth/firebase/custom-token`
3. Backend verifies the Jila JWT, then mints a **Firebase Custom Token** with:
   - `uid = users.id` (stable)
   - custom claims:
     - `principal_id` (required)
      - `user_id` (optional convenience, equals `sub`)
      - `session_id` (required; binds Firestore access to the same server-side session as **D-005**)
4. Client exchanges the custom token for a token usable by Firestore via Firebase SDK, then opens Firestore listeners.
5. Firestore Security Rules authorize reads based on `principal_id`.

Cadence (per **D-013**):
- Clients request a new custom token **on-demand** when the Firebase token is missing/expired.
- The backend may cache/memoize custom tokens per `(session_id)` until near expiry to reduce churn.

Backend requirements:
- Use the Firebase Admin SDK (service account) to mint custom tokens.
- Rotate/secure the service account credentials (env/secret manager), never in repo.

---

## 3. What we mirror (scope)

Mirror all non-historical “latest/current state” that the API serves to authenticated clients (per **D-014**).

Narrative explanation:
The Firestore mirror exists to serve the same “current view” that the API would otherwise return repeatedly, but in a way that the client can keep open as a realtime listener. We still rely on the HTTP API for first-load and as the correctness fallback. Firestore is a fast, read-optimized mirror so the UI can render quickly and receive incremental updates without polling.

Explicit exclusions (must not mirror):
- High-volume history/time-series (for example: `reservoir_readings` history pages).
- Raw telemetry payload streams (for example: `device_telemetry_messages.payload`).
- The centralized `events` outbox stream itself (it is an internal integration mechanism, not a client read model).
- Any secrets or one-time tokens (OTPs, password reset tokens, refresh token material).

---

## 4. Firestore data model (recommended layout)

We model Firestore as **per-principal materialized views** to keep Security Rules simple and to support efficient “list + listen” UX.

### 4.1 Canonical collections

#### `principals/{principal_id}/reservoirs/{reservoir_id}`
Read-optimized “reservoir summary” document for a principal who has access to that reservoir.

Fields (recommended, minimal):
- `reservoir_id` (string)
- `site_id` (string|null)
- `owner_principal_id` (string)
- `name` (string|null)  # if/when we add it
- `monitoring_mode` (string)  # `MANUAL|DEVICE`
- `capacity_liters` (number)
- `capacity_source` (string)  # `REPORTED|DERIVED_FROM_GEOMETRY|ADMIN_OVERRIDE`
- `level_pct` (number|null)
- `volume_liters` (number|null)
- `recorded_at` (timestamp|null)
- `updated_at` (timestamp|null)
- `device` (map|null):
  - `device_id` (string)
  - `status` (string)
  - `last_seen_at` (timestamp|null)
  - `last_battery_pct` (number|null)

Notes:
- This doc is the “live card” the UI listens to.
- It is a **projection**; deeper details still come from the HTTP API when needed.

#### `principals/{principal_id}/alerts/{alert_id}`
Alert documents for realtime badges/feeds.

#### `principals/{principal_id}/orders/{order_id}`
Order status mirroring for buyer/seller UIs.
Includes `updated_at` (timestamp) from the canonical order state.

#### `principals/{principal_id}/supply_points/{supply_point_id}`
SupplyPoint current state mirroring for map and seller/buyer UX (included per **D-014**).
Includes `updated_at` (timestamp) for freshness reconciliation.

#### `principals/{principal_id}/sites/{site_id}`
Site current state mirroring (included per **D-014**).
Includes `updated_at` (timestamp) derived from effective site activity.

#### `principals/{principal_id}/me/profile`
Minimal “current user” profile document to avoid repeated API reads (included per **D-014**).

#### `principals/{principal_id}/me/identity`
Full identity context mirror matching `GET /v1/me` (user, memberships, subscription state).

Fields (mirrors API shape, plus metadata):
- `user` (map):
  - `id` (string)
  - `phone_e164` (string|null)
  - `email` (string|null)
  - `last_login_at` (timestamp|null)
  - `status` (string)
  - `preferred_language` (string)
  - `verification_state` (string)
- `principal_id` (string)
- `org_memberships` (array of maps):
  - `org_id` (string)
  - `org_principal_id` (string)
  - `role` (string)
  - `subscription` (map: `plan_id`, `status`)
- `default_org_id` (string|null)
- `is_internal_ops_admin` (boolean)
- `updated_at` (timestamp|null)

#### `principals/{principal_id}/orgs/{org_principal_id}`
Organization profile mirror matching `GET /v1/accounts/{account_id}/profile`.

Fields (mirrors org details + profile, plus metadata):
- `org_id` (string)
- `org_principal_id` (string)
- `name` (string|null)
- `country_code` (string|null)
- `region` (string|null)
- `city` (string|null)
- `display_name` (string|null)
- `avatar_uri` (string|null)
- `updated_at` (timestamp|null)

#### `principals/{principal_id}/orgs/{org_principal_id}/members/{user_id}`
Organization member list mirror matching `GET /v1/accounts/{account_id}/members` items.

Fields (mirrors API shape, plus metadata):
- `user_id` (string)
- `email` (string|null)
- `display_name` (string|null)
- `role` (string)
- `status` (string)
- `last_login_at` (timestamp|null)
- `joined_at` (timestamp|null)

#### `principals/{principal_id}/orgs/{org_principal_id}/sites/{site_id}`
Organization-scoped site list mirror matching `GET /v1/accounts/{account_id}/sites` items.
Includes `updated_at` (timestamp) aligned to the API list item.

#### `principals/{principal_id}/orgs/{org_principal_id}/reservoirs/{reservoir_id}`
Organization-scoped reservoir list mirror matching `GET /v1/accounts/{account_id}/reservoirs` items.
Includes `updated_at` (timestamp) aligned to the API list item.

#### `principals/{principal_id}/orgs/{org_principal_id}/devices/{device_id}`
Organization-scoped device list mirror matching `GET /v1/accounts/{account_id}/devices` items.
Includes `updated_at` (timestamp) aligned to the API list item.

Config note:
- Device configs may include secrets (WiFi passwords, MQTT passwords, GSM passwords, SAS URLs).
- Firestore mirrors must not expose secrets. The device mirror therefore includes a **sanitized** `config`
  view with safe fields only (e.g., `operation.sleep_duration_ms`, `operation.sleep_mode`, etc.), and omits
  credential material and download URLs.
- The mirror includes `config.ack` per type with last known ACK status (sanitized).
- The mirror also includes API-aligned `config_state` (lists + derived `PENDING|APPLIED|FAILED`) for one-to-one
  mapping with `GET /v1/accounts/{account_id}/devices` and `GET /v1/accounts/{account_id}/devices/{device_id}`.

#### `principals/{principal_id}/orgs/{org_principal_id}/alerts/{alert_id}`
Organization-scoped alert list mirror matching `GET /v1/accounts/{account_id}/alerts` items.

#### `principals/{principal_id}/accounts/{org_principal_id}/notification-preferences/preferences`
Notification preferences mirror matching `GET /v1/accounts/{account_id}/notification-preferences`.

Fields (mirrors API shape, plus metadata):
- `account_principal_id` (string)
- `events` (map)
- `updated_at` (timestamp|null)

Notes:
- These are **read models**, not 1:1 table mirrors. Each document shape should match what the UI needs for “latest view” rendering.
- Keep mirrored documents minimal and stable; treat every field as a contract.
- When the canonical source exposes `updated_at`, mirrors should include it as an ISO8601 UTC `Z`
  string so clients can reconcile API vs Firestore freshness.

### 4.2 How we keep access in sync
Whenever access changes (grant/revoke), the backend must:
- create/update/delete the corresponding per-principal mirror docs, so the principal’s Firestore view matches `access_grants`.

This is intentionally **denormalized** because it yields:
- simple Security Rules (path-based)
- simple client queries (`principals/{principal_id}/orgs/{org_principal_id}/reservoirs` collection listener)

---

## 5. Security Rules (canonical patterns)

### 5.1 Required token claims
All authenticated Firestore reads require:
- `request.auth != null`
- `request.auth.token.principal_id` exists

### 5.2 Canonical rules (path-based authorization)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function principalId() {
      return request.auth.token.principal_id;
    }

    function isSignedIn() {
      return request.auth != null && principalId() is string;
    }

    // Per-principal materialized views (documents)
    match /principals/{pid}/{coll}/{docId} {
      allow read: if isSignedIn() && pid == principalId();
      // Clients never write mirrors. Backend writes using Admin SDK (bypasses rules).
      allow write: if false;
    }

    // Per-principal nested subcollections (e.g., org-scoped lists)
    match /principals/{pid}/{coll}/{docId}/{subpath=**} {
      allow read: if isSignedIn() && pid == principalId();
      allow write: if false;
    }
  }
}
```

Why this works:
- Authorization is “baked into the path”: a principal can only read within their own subtree.
- No complex cross-document checks required in rules.

---

## 6. Backend mirroring mechanics (how we write Firestore safely)

### 6.1 Use the transactional outbox (`events`) as the mirror trigger
Canonical pattern:
1. Write canonical DB state in Postgres transaction.
2. Insert an `events` row describing what changed.
3. A background processor (worker async loop) consumes events and updates Firestore mirrors.

This avoids “double-write” inconsistency (DB commit succeeds but Firestore write fails).

Narrative explanation:
Firestore is used only to serve the UI quickly. The backend does not “stream telemetry directly” to Firestore. Instead, the backend first stores telemetry-derived state in Postgres (for example a new `reservoir_readings` row and updated `devices.last_seen_at`), then emits one `events` row describing the change, and only then does a background processor mirror the new “latest view” into Firestore. This structure ensures that Firestore can always be rebuilt from Postgres plus the outbox stream, and it keeps the UI fast without making Firestore the source of truth.

### 6.2 Idempotency and ordering
Firestore writes should be idempotent:
- Use stable doc IDs (e.g., reservoir_id) within the principal subtree.
- Include `updated_at`/`recorded_at` timestamps and only apply updates if newer when needed.

Deletion / orphan-prevention requirement:
- Mirrors must not retain documents that the principal no longer has access to. When access is revoked,
  or an object is deleted, the backend must delete or prune mirror docs to avoid orphan state.

Recommended mechanism (Phase A):
- Emit a `FIRESTORE_MIRROR_RECONCILE_REQUESTED` event (subject: `PRINCIPAL`) whenever `access_grants`
  change for a principal. The Firestore mirror consumer rebuilds and prunes the principal subtree
  for the requested scopes (e.g., `orders`, `me_profile`).

Bootstrap note (UX hardening):
- Firestore reads do not fail when a document is missing; clients simply observe empty snapshots.
  Because Firestore is a read model (not the source of truth), the backend may also emit a
  throttled `FIRESTORE_MIRROR_RECONCILE_REQUESTED` during Firebase token mint (`POST /v1/auth/firebase/custom-token`)
  to ensure mirrors converge after manual wipes or missed events, without requiring operator intervention.

Recommended `scopes` values (Phase A):
- `me_profile`
- `orders`
- `reservoirs`
- `sites`
- `supply_points`
- `alerts`
- `org_sites`
- `org_reservoirs`
- `org_devices`
- `org_alerts`

Notes:
- `alerts` reconciliation is also used to converge `read_at` / `resolved_at` changes, since those are
  written as canonical state updates on `alerts` rows and must still flow through the outbox-driven
  mirror pipeline (clients never write Firestore mirrors).

### 6.3 What to mirror on key events (examples)
- `RESERVOIR_LEVEL_READING`:
  - update `principals/{pid}/reservoirs/{reservoir_id}` for all principals with access
- `DEVICE_ATTACHED|DEVICE_DETACHED`:
  - update the `device` sub-map
- `ALERT_CREATED`:
  - insert into `principals/{pid}/alerts/{alert_id}` and `principals/{pid}/orgs/{org_principal_id}/alerts/{alert_id}`
- `ORDER_*`:
  - upsert into `principals/{pid}/orders/{order_id}`
- `ACCESS_GRANT_*`:
  - create/delete (or reconcile) the per-principal mirror documents accordingly
- `USER_UPDATED` (including successful `/v1/auth/login`):
  - refresh `principals/{principal_id}/me/identity`
  - refresh `principals/{principal_id}/orgs/{org_principal_id}/members/{user_id}` so `last_login_at` stays current

Implementation note (Phase A):
- The Firestore mirror consumer supports both:
  - incremental upserts on domain events (e.g., `RESERVOIR_*`, `SITE_*`, `SUPPLY_POINT_STATUS_UPDATED`, `ORDER_*`)
  - explicit prune/backfill via `FIRESTORE_MIRROR_RECONCILE_REQUESTED` for orphan prevention under RBAC changes.

---

## 7. Operational notes

- Firestore is a UX cache: if Firestore is down, the app must still be functional via HTTP API (degraded realtime only).
- Keep mirrored docs small and stable. Add fields deliberately; every field is a contract.
- Do not mirror secrets (tokens, OTPs, PII beyond what is necessary for UI).


