# Frontend onboarding workflow (v1)

This document explains how the frontend should onboard a user and determine which step to show next.
It is aligned with the current v1 API contract and the single-org account model.

## Overview

**Onboarding is complete when:**
- The user is **verified** (OTP verified), **AND**
- The user has a **personal account (org)** and a **default org membership**, **AND**
- The user has a **principal profile** (display name + optional avatar).

The backend creates a personal org and grants membership when a user first becomes active in onboarding flows. Site creation is explicit via
`POST /v1/accounts/{org_principal_id}/sites` before creating reservoirs.

## Key endpoints (canonical)

**Registration & verification**
- `POST /v1/auth/register`
- `POST /v1/auth/verify-identifier`
- `POST /v1/auth/request-identifier-verification`
- `POST /v1/auth/login`

**Bootstrap (identity & memberships)**
- `GET /v1/me`

**User profile (principal profile)**
- `GET /v1/me/profile`
- `PATCH /v1/me/profile`
- `POST /v1/me/profile/avatar-upload`

**Account profile (org profile; optional at first-run)**
- `GET /v1/accounts/{org_principal_id}/profile`
- `PATCH /v1/accounts/{org_principal_id}/profile`
- `POST /v1/accounts/{org_principal_id}/profile/avatar-upload`

**Account creation (additional orgs)**
- `POST /v1/accounts`

**Subscription summary (implicit default)**
- No special call required for default plan; backend auto-creates **monitor** when first accessed.
- If needed: `GET /v1/accounts/{org_principal_id}/subscription` (org-principal only).

## Default plan behavior (v1)

- If no active subscription exists for an org principal, the backend creates **plan_id = "monitor"**, status **ACTIVE**.
- This happens on-demand (first access via subscription read flows).
- Treat this as the **default/free tier**. No explicit plan-selection step is required for onboarding.

## State model for onboarding

The frontend should derive the onboarding step from **server state**, not local flags.

**Inputs** (from backend):
- `GET /v1/me`:
  - `user.status`
  - `user.verification_state`
  - `org_memberships` (includes `org_principal_id`)
- `GET /v1/me/profile`:
  - `first_name`, `last_name`, `display_name`, `avatar_uri`

**Derived step**:
1. **REGISTER** → no account exists (user not registered yet)
2. **VERIFY_IDENTIFIER** → `user.status == PENDING_VERIFICATION`
3. **COMPLETE_PROFILE** → `user.status == ACTIVE` but `GET /v1/me/profile` has no `first_name` or `last_name`
4. **READY** → verified + profile complete

> Note: if the user is already ACTIVE but missing profile info, they must be routed to profile completion on next login.
> Email-only flows should also check `user.verification_state` and prompt email verification when needed.

## Recommended client flow (happy path)

### 1) Register
```
POST /v1/auth/register
{ phone_e164?, email?, password, preferred_language }
```
Response:
- `status = PENDING_VERIFICATION`
- `otp_sent_via = SMS|EMAIL`

### 2) Verify OTP
```
POST /v1/auth/verify-identifier
{ phone_e164 or email, otp }
```
Response:
- `status = ACTIVE`
- `principal_id` returned

At this point the backend also:
- Creates the user principal
- Creates a personal organization
- Grants OWNER on that org

### Invite-based onboarding (newly created user)
```
POST /v1/org-invites/resolve
POST /v1/org-invites/accept
POST /v1/auth/login
GET /v1/me
```

At invite acceptance time, for newly created users, the backend also:
- Creates a personal organization (using user-derived naming with fallback)
- Grants OWNER on that personal org
- Grants the invited role on the target organization

### 3) Login
```
POST /v1/auth/login
{ username, password }
```
Response:
- `access_token`, `refresh_token`, `principal_id`

### 4) Bootstrap state
```
GET /v1/me
```
Use:
- `org_memberships[0].org_principal_id` as `org_principal_id`
- `user.status` for verification state

### 5) Ensure profile is completed
```
GET /v1/me/profile
```
If `first_name` or `last_name` is empty or null:
```
PATCH /v1/me/profile
{ first_name, last_name, avatar_uri? }
```
(Optional) upload avatar:
```
POST /v1/me/profile/avatar-upload
```
Then upload via SAS URL and set `avatar_uri` in the profile patch.

### 6) Onboarding complete
Proceed to the main app only after profile is completed.

## Returning user flow

On every login:
1. `POST /v1/auth/login`
2. `GET /v1/me` → determine account_id and user status
3. `GET /v1/me/profile` → if missing first/last name, route to profile completion
4. Otherwise proceed

This ensures users who verified but skipped profile completion are correctly resumed.

## Error + edge cases

- **OTP resend:** use `POST /v1/auth/request-identifier-verification` (anti-enumeration safe).
- **Already ACTIVE at register:** `POST /v1/auth/register` returns `409 ACCOUNT_ALREADY_EXISTS`.
- **Multiple org memberships:** `GET /v1/me.default_org_id` may be null; prompt user to select an org.
- **Invite-based onboarding:** use `POST /v1/org-invites/resolve` → `POST /v1/org-invites/accept` → `POST /v1/auth/login` → `GET /v1/me`.

## Checklist for frontend implementation

- [ ] Implement register → verify → login → bootstrap → profile steps.
- [ ] Gate main app entry on `first_name` + `last_name` present.
- [ ] Cache `account_id` from `GET /v1/me` (org_principal_id).
- [ ] Handle `default_org_id` null (prompt org picker).
- [ ] Surface OTP resend + verification errors.
