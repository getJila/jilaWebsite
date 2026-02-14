## Web Portal — Firebase Realtime Mirroring Guide (v1)

Audience: Frontend team integrating Firebase Firestore realtime mirrors.

Status: Frontend-facing reference.

Last updated: 2026-01-27

Canonical sources:
- Firestore mirror layout: `docs/architecture/jila_api_backend_firestore_mirroring.md`
- Auth + identity contract: `docs/architecture/api_contract/02_auth_identity.md`
- Firebase custom token: `POST /v1/auth/firebase/custom-token`

---

## 1) Purpose

The portal uses a dual-load strategy:
1) HTTP API for initial page load and correctness fallback.
2) Firestore realtime listeners to keep UI current and avoid polling.

Firestore mirrors are read-only, backend-written projections of canonical Postgres state.

Key principle (avoid confusion):
- **Firestore is principal-scoped.** All mirror paths are under `principals/{principal_id}/...`.
- **Account-first API routes use `account_id = org_principal_id`** for portal flows.
- There is **no canonical `/accounts/...` root in Firestore** for portal mirrors.

---

## 2) Authentication flow (required)

Firestore security rules allow reads only when the Firebase token contains the `principal_id` claim.

### 2.1 Token exchange flow
1) User authenticates with Jila API and receives a Jila JWT.
2) Client requests a Firebase custom token from Jila API:
   - `POST /v1/auth/firebase/custom-token`
3) Client exchanges the custom token for a Firebase ID token using the Firebase SDK.
4) Client opens Firestore listeners.

### 2.2 Required claims
The Firebase token must include:
- `principal_id`
- `session_id`

These are minted server-side via Firebase Admin SDK.

### 2.3 When to refresh token
- On app startup if Firebase auth state is missing.
- When Firebase ID token is expired/invalid.
- After re-login (new server session).

---

## 3) Security rules (enforced)

Current rules restrict access to per-principal subtrees only:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function principalId() {
      return request.auth.token.principal_id;
    }

    function hasPrincipalClaim() {
      return request.auth != null
        && (principalId() is string)
        && principalId().size() > 0;
    }

    // Default-deny
    match /{document=**} {
      allow read, write: if false;
    }

    // Per-principal materialized views (canonical mirror layout)
    match /principals/{pid}/{coll}/{docId} {
      allow read: if hasPrincipalClaim() && pid == principalId();
      allow write: if false; // Backend uses Admin SDK; clients never write mirrors
    }

    // Per-principal nested subcollections (e.g., orgs/{org_id}/members/{user_id})
    match /principals/{pid}/{coll}/{docId}/{subpath=**} {
      allow read: if hasPrincipalClaim() && pid == principalId();
      allow write: if false;
    }
  }
}
```

---

## 4) Mirror layout (per principal)

All data lives under `principals/{principal_id}/...` and is read-only from the client.

Important ID mapping:
- `principal_id`: the authenticated user's principal (from JWT and Firebase token)
- `org_principal_id`: the org principal ID returned by `GET /v1/me` (`org_memberships[*].org_principal_id`)
- `account_id` (portal APIs): **equals `org_principal_id`** for org-scoped portal flows
- `org_id`: the organization row ID (not used in Firestore paths)

Primary collections used by the portal:

### 4.1 Identity and profile
- `principals/{principal_id}/me/profile`
  - Mirrors `GET /v1/me/profile`
- `principals/{principal_id}/me/identity`
  - Mirrors `GET /v1/me`
  - Includes `user`, `org_memberships`, `default_org_id`, `is_internal_ops_admin`

### 4.2 Organization profile
- `principals/{principal_id}/orgs/{org_principal_id}`
  - Mirrors `GET /v1/accounts/{account_id}` + `/profile`
  - Includes org details + display name + avatar

### 4.3 Organization members
- `principals/{principal_id}/orgs/{org_principal_id}/members/{user_id}`
  - Mirrors `GET /v1/accounts/{account_id}/members` items

### 4.4 Notification preferences
- `principals/{principal_id}/accounts/{org_principal_id}/notification-preferences/preferences`
  - Mirrors `GET /v1/accounts/{account_id}/notification-preferences`

### 4.5 Organization-scoped lists
- `principals/{principal_id}/orgs/{org_principal_id}/sites/{site_id}`
  - Mirrors `GET /v1/accounts/{account_id}/sites` items
- `principals/{principal_id}/orgs/{org_principal_id}/reservoirs/{reservoir_id}`
  - Mirrors `GET /v1/accounts/{account_id}/reservoirs` items
- `principals/{principal_id}/orgs/{org_principal_id}/devices/{device_id}`
  - Mirrors `GET /v1/accounts/{account_id}/devices` items
- `principals/{principal_id}/orgs/{org_principal_id}/alerts/{alert_id}`
  - Mirrors `GET /v1/accounts/{account_id}/alerts` items

Non-canonical path (do not use):
- `accounts/{org_id}/notification-preferences/preferences` (wrong root and wrong ID)

---

## 5) Client integration pattern

### 5.1 Boot sequence (recommended)
1) API call(s) to render initial UI state.
2) Get Firebase custom token → sign in to Firebase.
3) Start Firestore listeners for all relevant docs/collections.
4) UI updates from Firestore override only the mirrored parts of the state.

### 5.2 Listener setup (examples)
- `me/profile`: document listener
- `me/identity`: document listener
- `orgs/{org_principal_id}`: document listener
- `orgs/{org_principal_id}/members`: collection listener
- `accounts/{org_principal_id}/notification-preferences/preferences`: document listener
- `orgs/{org_principal_id}/sites`: collection listener
- `orgs/{org_principal_id}/reservoirs`: collection listener
- `orgs/{org_principal_id}/devices`: collection listener
- `orgs/{org_principal_id}/alerts`: collection listener

Listener scoping rules:
- Always use **org_principal_id** for org-scoped listeners and cache keys.
- Do not mix `org_id` with `org_principal_id`.
- Collection queries (e.g., `orgs/{org_principal_id}/members`) are authorized by the
  document rules on their child docs; no separate collection rule is required.

### 5.3 Fallback behavior
- If Firestore is unavailable or missing a doc, use API responses.
- Do not attempt to write to Firestore.

---

## 6) Freshness and reconciliation

Every mirrored document includes:
- `updated_at` (server timestamp)
- `last_event_seq` and `last_event_type` (for debugging and ordering)

When access changes (org membership granted/revoked), the backend prunes and rebuilds the principal subtree.

Frontend should:
- Handle doc removal events (e.g., membership revoked).
- Treat missing docs as “no access” and fall back to API checks if needed.

---

## 7) Out of scope (must stay API-only)

These are not mirrored and should continue to use HTTP API:
- Avatar upload URLs (`/me/profile/avatar-upload`, `/accounts/{account_id}/profile/avatar-upload`)
- Media redirect (`/v1/media/avatars/...`)
- Historical/time-series lists (device telemetry history, reservoir readings history)

---

## 8) Troubleshooting checklist

If realtime updates are missing:
- Verify Firebase auth token includes `principal_id`.
- Confirm `principal_id` in token matches listener path.
- Check Firestore doc exists in the principal subtree.
- Ensure initial API load worked (Firestore is not canonical).
