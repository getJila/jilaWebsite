## Firestore Mirror Parity — Profiles (v1)

Goal: map profile-related UI surfaces to their API sources, compare to current Firestore mirror data,
and define a concrete plan to achieve exact mirroring for realtime UI refresh.

Canonical sources:
- Firestore mirror spec: `docs/architecture/jila_api_backend_firestore_mirroring.md`
- Auth + identity contract: `docs/architecture/api_contract/02_auth_identity.md`
- Orgs + sites portal contract: `docs/architecture/api_contract/03_orgs_sites_portal.md`
- Firestore mirror implementation: `app/modules/alerts_events/service/mirror_consumer.py`

---

## 1. Current Firestore profile mirror scope

Firestore mirrors only the principal profile document:

- Path: `principals/{principal_id}/me/profile`
- Fields (current):
  - `principal_id`
  - `display_name`
  - `avatar_uri`
  - `updated_at`
  - `last_event_seq`
  - `last_event_type`

This is derived from the canonical identity sources (users first/last name or organizations.name)
plus `principal_profiles.avatar_uri`, and updated by
`PRINCIPAL_UPDATED` and `FIRESTORE_MIRROR_RECONCILE_REQUESTED` events.

---

## 2. UI surfaces that depend on profile data

### 2.1 User profile surface (self)
Primary UI screens:
- User profile settings
- Avatar update flow
- Account switcher identity header

API sources:
- `GET /v1/me` (identity context, org memberships)
- `GET /v1/me/profile` (display identity derived from first/last name)
- `PATCH /v1/me/profile` (update first/last name / avatar)
- `POST /v1/me/profile/avatar-upload` (upload URL + avatar_uri)
- `GET /v1/media/avatars/{principal_id}/{avatar_id}` (image redirect)

Firestore mirror status:
- Partial parity: `me/profile` exists and is aligned with `GET /v1/me/profile`.
- Gaps: no mirror for `GET /v1/me` identity context, no avatar upload metadata, no media redirect.

### 2.1a Notification preferences surface
Primary UI screens:
- Notification preferences (per org account)
- Push notification enable/disable and per-channel toggles

API sources:
- `GET /v1/accounts/{org_principal_id}/notification-preferences`
- `PATCH /v1/accounts/{org_principal_id}/notification-preferences`
- `POST /v1/accounts/{org_principal_id}/push-tokens` (registration)
- `DELETE /v1/accounts/{org_principal_id}/push-tokens/{push_token_id}` (disable)

Firestore mirror status:
- No parity: notification preferences are not mirrored in Firestore today.

### 2.2 Organization profile surface (org account)
Primary UI screens:
- Org settings summary header (name, location)
- Org context selector / header

API sources:
- `GET /v1/accounts/{org_principal_id}` (org details)
- `GET /v1/accounts/{org_principal_id}/profile` (org name + avatar)
- `GET /v1/me` (to discover org memberships and `org_principal_id`)

Firestore mirror status:
- No parity: org details are not mirrored in Firestore today.

### 2.3 Organization members surface
Primary UI screens:
- Org members list and role management
- Invite flow (read-only list refresh)

API sources:
- `GET /v1/accounts/{org_principal_id}/members` (members list)
- `POST /v1/accounts/{org_principal_id}/members/invite` (invite)

Firestore mirror status:
- No parity: org membership list is not mirrored in Firestore today.

---

## 3. Gap analysis by endpoint

### 3.1 `GET /v1/me/profile`
Parity: YES (Firestore mirrors this shape).

Notes:
- Firestore includes `updated_at`, which is not part of the API response but is useful for freshness.

### 3.2 `GET /v1/me`
Parity: NO.

Missing in Firestore:
- `is_internal_ops_admin`
- `user` block (id, email, phone_e164, status, preferred_language, verification_state)
- `org_memberships` list (org_id, org_principal_id, role, subscription)
- `default_org_id`

### 3.3 `GET /v1/accounts/{org_principal_id}` and `/profile` (org profile)
Parity: NO.

Missing in Firestore:
- Org details (`name`, `country_code`, `region`, `city`)
- Org profile (`display_name`, `avatar_uri`)

### 3.4 `GET /v1/accounts/{org_principal_id}/members`
Parity: NO.

Missing in Firestore:
- Members list (user identity, role, status, last_login_at, joined_at)

### 3.5 Avatar upload and media
Parity: NO (not mirrored by design).

Notes:
- Upload URL (`avatar-upload`) is intentionally short-lived and should stay API-only.
- Media avatar redirect is API-only and should remain API-only.

### 3.6 `GET /v1/accounts/{account_id}/notification-preferences`
Parity: NO.

Missing in Firestore:
- Full preferences object:
  - `events.orders.channels` (`app`, `push`, `sms`, `email`)
  - `events.water_risk.channels` (`app`, `push`, `sms`, `email`)
  - `events.water_risk.reservoir_level_state` (`full`, `normal`, `low`, `critical`)
  - `events.device_risk.channels` (`app`, `push`, `sms`, `email`)

### 3.7 Push tokens (`POST` / `DELETE`)
Parity: NO (not mirrored by design).

Notes:
- Push tokens are sensitive; the API never returns raw tokens after registration.
- The UI does not need tokens for realtime preferences display, only the preferences state.

---

## 4. Plan to make Firestore mirroring exact for profile surfaces

### 4.1 Extend Firestore mirror scope (new documents)

Add the following per-principal documents under `principals/{principal_id}`:

1) `me/identity`
- Mirrors `GET /v1/me` response.
- Fields:
  - `is_internal_ops_admin`
  - `user` object (id, email, phone_e164, status, preferred_language, verification_state)
  - `principal_id`
  - `org_memberships` (array of {org_id, org_principal_id, role, subscription})
  - `default_org_id` (or null when ambiguous)
  - `updated_at` (server timestamp)

2) `orgs/{org_principal_id}`
- Mirrors `GET /v1/accounts/{account_id}` and `/profile` responses.
- Fields:
  - `org_id`
  - `org_principal_id`
  - `name`
  - `country_code`
  - `region`
  - `city`
  - `display_name`
  - `avatar_uri`
  - `updated_at`

3) `orgs/{org_principal_id}/members/{member_user_id}`
- Mirrors `GET /v1/accounts/{account_id}/members` items.
- Fields:
  - `user_id`
  - `email`
  - `display_name`
  - `role`
  - `status`
  - `last_login_at`
  - `joined_at`
  - `updated_at`

4) `accounts/{org_principal_id}/notification-preferences/preferences`
- Mirrors `GET /v1/accounts/{account_id}/notification-preferences`.
- Fields:
  - `events.orders.channels` (`app`, `push`, `sms`, `email`)
  - `events.water_risk.channels` (`app`, `push`, `sms`, `email`)
  - `events.water_risk.reservoir_level_state` (`full`, `normal`, `low`, `critical`)
  - `events.device_risk.channels` (`app`, `push`, `sms`, `email`)
  - `updated_at`

### 4.2 Event triggers and reconciliation

Update the Firestore mirror consumer to emit these documents on:
- `PRINCIPAL_UPDATED` (refresh `me/profile` and `me/identity`)
- `ORG_UPDATED` (refresh org profile docs for all members)
- `ACCESS_GRANT_*` related to org membership (refresh `me/identity` and org member docs)
- `USER_UPDATED` (refresh member list entries for relevant orgs)
- `NOTIFICATION_PREFERENCES_UPDATED` (refresh notification preferences for the account)

Ensure `FIRESTORE_MIRROR_RECONCILE_REQUESTED` can rebuild:
- `me_identity`
- `orgs`
- `org_members`
- `notification_preferences`

### 4.3 Contract alignment

Because Firestore mirrors are part of the frontend contract:
- Update `docs/architecture/jila_api_backend_firestore_mirroring.md` with new collections and field shapes.
- Keep API contract unchanged; Firestore mirrors must match those shapes exactly.

### 4.4 Frontend usage guidance

Define a strict client loading strategy:
- Initial load uses API.
- Realtime updates use Firestore mirrors if:
  - `me/profile` -> `me/profile`
  - `me` -> `me/identity`
  - `org profile` -> `orgs/{org_principal_id}`
  - `org members` -> `orgs/{org_principal_id}/members`
  - `notification preferences` -> `accounts/{org_principal_id}/notification-preferences`

---

## 5. Open items for implementation

1) Confirm naming for org document IDs:
- Use `org_principal_id` as the Firestore doc ID to match RBAC scoping.

2) Confirm whether `GET /v1/me` should be mirrored for UI realtime:
- If not, limit Firestore scope to `me/profile` and org profile summaries only.

3) Confirm if org member list requires realtime updates:
- If not, keep as API-only to reduce Firestore volume.

---

## 6. Summary

Today, Firestore only mirrors the shared principal profile. All other profile surfaces
depend on API reads. To make Firebase mirroring exact for profile-related UI, we should add
explicit mirrors for identity context, organization profile data, and org membership lists,
with consistent event-driven updates and reconciliation support.
