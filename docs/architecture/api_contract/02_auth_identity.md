## Jila API Backend – API Contract (v1) — Extracted section (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

## 1. Auth & identity

### 1.0a `POST /v1/setup/bootstrap-admin` (single-use, turnkey installs)

Bootstraps the initial platform admin set for a self-hosted tenant.

This endpoint exists to avoid relying on environment variables for production admin membership while still preventing
“first caller becomes admin” vulnerabilities (see decision **D-063**).

Constraints:
- The created admin user must have an email on the allowed admin domain (v1: `@jila.ai`).
- The bootstrap secret is single-use: once bootstrap completes, it cannot be replayed.

Auth:
- Public (no JWT). Protected by the bootstrap secret.

Request:

```json
{
  "bootstrap_secret": "string",
  "email": "admin@jila.ai",
  "phone_e164": "+2449XXXXXXX",  // optional
  "password": "plaintext",
  "preferred_language": "pt"
}
```

Response `200 OK`:

```json
{
  "status": "OK",
  "user_id": "uuid",
  "principal_id": "uuid",
  "internal_ops_org_id": "uuid",
  "internal_ops_org_principal_id": "uuid",
  "bootstrap_used_at": "2025-01-01T00:00:00Z"
}
```

Errors:
- `403 FORBIDDEN` (`error_code = FORBIDDEN`) when:
  - bootstrap secret is invalid (`details.reason = INVALID_BOOTSTRAP_SECRET`), or
  - email is not on the required domain (`details.reason = ADMIN_EMAIL_DOMAIN_REQUIRED`, `details.required_domain = "jila.ai"`).
- `409 RESOURCE_CONFLICT` (`error_code = RESOURCE_CONFLICT`) when:
  - bootstrap already completed (`details.reason = BOOTSTRAP_ALREADY_USED`), or
  - bootstrap secret was not configured for this tenant (`details.reason = BOOTSTRAP_SECRET_NOT_CONFIGURED`).
- `422 VALIDATION_ERROR` for invalid request fields.

### 1.1 `POST /v1/auth/register`

Registers a user in `PENDING_VERIFICATION` and queues an OTP delivery for verification.

All accounts use a single org-centric model. Users may still join an existing org via
`POST /v1/org-invites/accept`.

### 1.6 `GET /v1/me`

Returns identity context for the authenticated caller.

Auth:
- Requires `Authorization: Bearer <jwt>`.

Response `200 OK`:

```json
{
  "user": {
    "id": "uuid",
    "email": "user@org.com",
    "phone_e164": "+2449XXXXXXX",
    "last_login_at": "2026-02-13T10:30:00Z",
    "status": "ACTIVE",
    "preferred_language": "pt",
    "verification_state": "PHONE_VERIFIED"
  },
  "principal_id": "uuid",
  "org_memberships": [
    {
      "org_id": "uuid",
      "org_principal_id": "uuid",
      "role": "OWNER",
      "org_name": "Luanda Water Utility",
      "display_name": "Luanda Water Utility",
      "avatar_uri": "/v1/media/avatars/<org_principal_id>/<avatar_id>.png"
    }
  ],
  "default_org_id": "uuid|null"
}
```

Notes:
- `default_org_id` follows Option 3b semantics:
  - When `org_memberships.length == 1`, `default_org_id` is that membership’s `org_id`.
  - When `org_memberships.length != 1` (0 or >1), `default_org_id = null`.
- `org_memberships[*].org_name`, `display_name`, and `avatar_uri` are additive profile fields to avoid
  client-side org profile fan-out calls. They may be `null`.
- `user.verification_state` values: `UNVERIFIED`, `PHONE_VERIFIED`, `EMAIL_VERIFIED`, `PHONE_AND_EMAIL_VERIFIED`.
- Clients should use `verification_state` to gate email-only experiences (e.g., email notifications, email login).


Request:

```json
{
  "phone_e164": "+2449XXXXXXX",
  "email": null,
  "password": "plaintext",
  "preferred_language": "pt"
}
```

Notes:
- **`phone_e164` is required**; `email` is optional (both allowed).
- OTP issuance priority (v1):
  - phone-first (SMS) when `phone_e164` is present and unverified; otherwise email (email-only users verify via email).
- `otp_sent_via` means the OTP is **queued for delivery** by the worker (outbox-driven), not “provider delivered”.
  - The worker is woken by outbox events (Postgres `LISTEN/NOTIFY` + fallback) and retries are scheduled via `otp_deliveries.next_attempt_at` (D-012, D-027).
- Clients should not persist a “preferred identifier” for login; login uses `username`.
- Password is hashed server-side.

### 1.1a `POST /v1/me/identifiers/email`

Add or update the authenticated user’s email, then issue an OTP to verify it.

Auth:
- Requires `Authorization: Bearer <jwt>`.

Request:

```json
{ "email": "user@org.com" }
```

Response `200 OK`:

```json
{
  "email": "user@org.com",
  "verification_state": "EMAIL_VERIFIED|PHONE_VERIFIED|PHONE_AND_EMAIL_VERIFIED|UNVERIFIED",
  "otp_sent_via": "EMAIL|null"
}
```

Notes:
- Updating email resets `email_verified_at` and requires verification before email-based login or notifications.
- Anti-enumeration: if the email is not eligible for verification, this returns `200` with `otp_sent_via = null`.

Responses:
- `200 OK` (idempotent for `PENDING_VERIFICATION`)

```json
{
  "user_id": "uuid",
  "status": "PENDING_VERIFICATION",
  "otp_sent_via": "SMS"
}
```

Errors:
- `409 ACCOUNT_ALREADY_EXISTS` (if user exists and `ACTIVE`)
- `403 ACCOUNT_DISABLED` (if user is not eligible to login; see enum `user_status` in `docs/architecture/jila_api_backend_enums_v1.md`)

### 1.2 `POST /v1/auth/verify-identifier`

Verifies an email or phone OTP.

Request (email):

```json
{
  "email": "user@org.com",
  "otp": "123456"
}
```

Request (phone):

```json
{
  "phone_e164": "+2449XXXXXXX",
  "otp": "123456"
}
```

Response `200 OK`:

```json
{
  "user_id": "uuid",
  "status": "ACTIVE",
  "principal_id": "uuid|null",
  "verified_identifier": "EMAIL|PHONE"
}
```

Side effects:
- Marks OTP token as used.
- If activation criteria are satisfied, transitions user to `ACTIVE`, ensures a `principals` row exists for the user,
  creates a personal default org and grants `OWNER` on that org.

Errors:
- `422 INVALID_OTP`
- `409 OTP_EXPIRED`

### 1.2.1 `POST /v1/auth/request-identifier-verification`

Requests an OTP to verify an identifier.

Auth:
- Public (no JWT) — used for onboarding and for later verification prompts.

Request:

```json
{ "email": "user@org.com" }
```

or

```json
{ "phone_e164": "+2449XXXXXXX" }
```

Response `200 OK`:

```json
{ "otp_sent_via": "EMAIL|SMS" }
```

Notes:
- Anti-enumeration: if the identifier is not eligible for verification (not found, already verified, locked/disabled), this returns `200` with `otp_sent_via = null`.
- Rate limiting / cooldown: repeated requests for the same identifier may return `200` but not enqueue a new OTP send when within the resend buffer (see `Settings.VERIFICATION_RESEND_MIN_BUFFER_SECONDS`).

### 1.3 `POST /v1/auth/firebase/custom-token`

Mints a **Firebase custom token** so the client can authenticate to Firestore for realtime listeners.

Auth:
- Requires `Authorization: Bearer <jwt>` (Jila API JWT).

Request (v1 targeted invite; Decision D-029):

```json
{
  "invite_target_phone_e164": "+2449XXXXXXX",
  "invite_target_email": "user@example.com"
}
```

Notes:
- At least one of `invite_target_phone_e164` or `invite_target_email` is required.
- These identifiers are used to prefill onboarding and to prevent invite theft: only a user who verifies the target identifier(s) can redeem.

Response `200 OK`:

```json
{
  "firebase_custom_token": "string",
  "principal_id": "uuid",
  "expires_in_seconds": 3600
}
```

Notes:
- Jila remains the canonical authentication system; we are **not** using Firebase as an identity provider (no Firebase login/OAuth flows for Jila users).
- The backend verifies the Jila JWT and issues a Firebase custom token with custom claims:
  - `principal_id` (required for Firestore Security Rules)
  - `user_id` (optional convenience)
-  - `session_id` (required; binds Firestore access to the same server-side session as **D-005** and token policy **D-013**)
- The client exchanges the custom token using Firebase SDK and then listens to:
  - `principals/{principal_id}/...` mirror collections (see Firestore mirroring doc).
 - Token cadence (per **D-013**): clients request this token **on-demand** when Firestore auth is missing/expired; there is no separate “Firebase login” session distinct from the Jila API session.

Errors:
- `401 UNAUTHORIZED` (missing/invalid JWT)

### 1.4 `POST /v1/auth/login`

Request:

```json
{
  "username": "+2449XXXXXXX",
  "password": "plaintext"
}
```

Response `200 OK`:

```json
{
  "access_token": "jwt",
  "refresh_token": "opaque",
  "token_type": "Bearer",
  "expires_in_seconds": 3600
}
```

Notes:
- `username` can be either a verified phone (E.164) or a verified email (case-insensitive). The server resolves deterministically (see decision **D-004**).
- For safe anti-enumeration, the server returns `401 INVALID_CREDENTIALS` for “not found”, “wrong password”, and “not yet eligible (still PENDING_VERIFICATION)”. Disabled accounts return `403 ACCOUNT_DISABLED`.
- Successful login updates `users.last_login_at` (UTC `Z`) and emits `USER_UPDATED` for mirror refresh; refresh-token rotation does not update this field.

### 1.4.1 `POST /v1/auth/refresh`

Rotates a refresh token and returns a new access token.

Request:

```json
{ "refresh_token": "opaque" }
```

Response `200 OK`:

```json
{
  "access_token": "jwt",
  "refresh_token": "opaque",
  "token_type": "Bearer",
  "expires_in_seconds": 3600
}
```

Notes (D-005):
- Refresh tokens are **single-use** and must be rotated on every refresh.
- For the web portal, the refresh token should be stored in an HttpOnly cookie in implementation; this body field exists for mobile clients.

### 1.4.2 `POST /v1/auth/logout`

Revokes the current refresh session.

Auth:
- No JWT required (logout is performed by presenting the `refresh_token`).

Request:

```json
{ "refresh_token": "opaque" }
```

Response `200 OK`:

```json
{ "status": "OK" }
```

### 1.5 `POST /v1/auth/request-password-reset`

Request:

```json
{
  "username": "+2449XXXXXXX"
}
```

Response `200 OK`:

```json
{ "otp_sent_via": "SMS" }
```

Notes:
- Always returns `200 OK` regardless of whether the user exists (anti-enumeration).
- The server only sends an OTP when the identifier exists and is verified.
- Rate limiting / cooldown: repeated requests for the same identifier may return `200` but not enqueue a new OTP send when within the resend buffer (see `Settings.VERIFICATION_RESEND_MIN_BUFFER_SECONDS`).

### 1.6 `POST /v1/auth/reset-password`

Request:

```json
{
  "username": "+2449XXXXXXX",
  "otp": "123456",
  "new_password": "plaintext"
}
```

Notes:
- On success, the backend **asynchronously** sends a best-effort **password reset confirmation email** to the user **when a verified email address exists**. This does not change the HTTP response shape.

Response `200 OK`:

```json
{ "status": "OK" }
```

### 1.6.1 `POST /v1/auth/request-account-erasure`

Requests a **GDPR-style account erasure** flow for the authenticated user. This is a two-step process:
1) request erasure (issue OTP + queue delivery)
2) confirm erasure (validate OTP and execute hard-delete erasure)

Auth:
- Requires `Authorization: Bearer <jwt>`

Request:
- Empty body.

Response `200 OK`:

```json
{ "otp_sent_via": "SMS" }
```

Notes (D-019):
- The OTP is delivered via the outbox-driven OTP pipeline (queued, not guaranteed delivered).
- Rate limiting / cooldown: repeated requests may return `200` but not enqueue a new OTP send when within the resend buffer (see `Settings.VERIFICATION_RESEND_MIN_BUFFER_SECONDS`).
- OTP is sent to the authenticated user’s primary verified identifier:
  - If `phone_e164` is present and verified → `SMS`.
  - Else if `email` is present and verified → `EMAIL`.
- `otp_sent_via` is deterministic based on the verified identifier.
- If the required primary contact is not verified, return `409 RESOURCE_CONFLICT` with:
  - `details.reason = "PRIMARY_CONTACT_NOT_VERIFIED"`

Errors:
- `401 UNAUTHORIZED`
- `409 RESOURCE_CONFLICT` (required primary contact not verified; `details.reason = "PRIMARY_CONTACT_NOT_VERIFIED"`)

### 1.6.2 `POST /v1/auth/confirm-account-erasure`

Confirms account erasure by validating the OTP and executing erasure.

Auth:
- Requires `Authorization: Bearer <jwt>`

Request:

```json
{ "otp": "123456" }
```

Response `200 OK`:

```json
{ "status": "OK" }
```

Side effects (D-019):
- Deletes the `users` row (hard delete) and cascades dependent rows (sessions, principals, grants, user-owned resources).
- Deletes any OTP/invite/reset tokens that still carry erased identifier values in `tokens.target_identifier`.

Errors:
- `401 UNAUTHORIZED`
- `422 INVALID_OTP`
- `409 OTP_EXPIRED`

---

### 1.8 `GET /v1/me`

Response `200 OK`:

```json
{
  "is_internal_ops_admin": false,
  "user": {
    "id": "uuid",
    "phone_e164": "+2449XXXXXXX",
    "email": null,
    "last_login_at": "2026-02-13T10:30:00Z",
    "status": "ACTIVE",
    "preferred_language": "pt"
  },
  "principal_id": "uuid",
  "org_memberships": [
    {
      "org_id": "uuid",
      "org_principal_id": "uuid",
      "role": "OWNER|MANAGER|VIEWER",
      "org_name": "Luanda Water Utility",
      "display_name": "Luanda Water Utility",
      "avatar_uri": "/v1/media/avatars/<org_principal_id>/<avatar_id>.png",
      "subscription": { "plan_id": "monitor", "status": "ACTIVE" }
    }
  ]
}
```

Notes:
- `org_memberships[*].subscription` is the subscription for the **organization principal**; all feature gating uses the
  owner org principal for the resource being accessed.
- `org_memberships[*].org_name`, `display_name`, and `avatar_uri` are additive profile hints for bootstrap UIs.
  They are nullable and do not change authz semantics.
- `is_internal_ops_admin` is a UX helper that indicates whether the caller is a platform/internal-ops admin (D-059/D-063). It is derived from:
  - membership grant on the tenant’s internal ops org, and
  - email domain constraint configured via `platform_settings.allowed_admin_email_domain` (default `jila.ai`).
- `user.last_login_at` is nullable for never-logged-in users and uses server UTC ISO8601 with `Z`.

### 1.9 `GET /v1/accounts/{org_principal_id}/reservoirs`

Lists reservoirs owned by the account principal.

Rules:
- `org_principal_id` is always an organization principal id; caller must have an org membership role
  (`OWNER|MANAGER|VIEWER`) in that organization.

Query params (optional; v1):
- `site_id` (uuid; filter to a single site)
- `reservoir_type` (`TANK|TRUCK_TANK|BUFFER_TANK|OTHER`)
- `monitoring_mode` (`MANUAL|DEVICE`)
- `level_state` (`FULL|NORMAL|LOW|CRITICAL`)
- `has_device` (boolean; when true, only reservoirs with an attached device)

Response `200 OK`:

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
      "thresholds": {
        "full_threshold_pct": 90,
        "low_threshold_pct": 30,
        "critical_threshold_pct": 15
      },
      "level_state": "LOW",
      "level_state_updated_at": "2025-01-01T00:00:00Z",
      "connectivity_state": "ONLINE",
      "last_reading_age_seconds": 3600,
      "device": {
        "device_id": "string",
        "serial_number": "JL-001234",
        "status": "ONLINE",
        "battery_pct": 85,
        "last_seen_at": "2025-01-01T00:00:00Z"
      },
      "latest_reading": {
        "level_pct": 40,
        "volume_liters": 400,
        "battery_pct": null,
        "recorded_at": "2025-01-01T00:00:00Z",
        "source": "MANUAL"
      }
    }
  ]
}
```

Notes (DECIDED, D-036):
- `thresholds` reflects the configured threshold pct values used by the backend level state machine:
  - `full_threshold_pct` corresponds to `full_threshold_pct` on reservoir detail.
  - `low_threshold_pct` corresponds to `low_threshold_pct` on reservoir detail.
  - `critical_threshold_pct` corresponds to `critical_threshold_pct` on reservoir detail.
- `connectivity_state` is a backend-derived freshness classification:
  - `ONLINE`: recent readings are arriving within the expected window
  - `STALE`: readings exist but are older than the "trust" window
  - `OFFLINE`: no recent readings / device not seen within the expected window
- `last_reading_age_seconds` is derived from server time and the latest reading timestamp; it is used for UI freshness.
- `device` is a nullable summary object:
  - `device_id` is the MQTT identity (same type as devices endpoints).
  - When no device is attached, `device = null`.
  - The summary is for operational context only (no secrets).

### 1.10 `GET /v1/me/profile`

Returns the caller's shared principal profile (display identity surface).

Response `200 OK`:

```json
{
  "principal_id": "uuid",
  "first_name": "Optional first name (or null)",
  "last_name": "Optional last name (or null)",
  "display_name": "Derived from first_name + last_name (or null)",
  "avatar_uri": "/v1/media/avatars/{principal_id}/{avatar_id}.jpg (or null)"
}
```

Notes:
- `avatar_uri` is an **opaque API URL** intended for frontend `<img src="...">`.
  - The backend may redirect this URL to a short-lived signed blob URL.
  - Clients should not attempt to construct blob storage URLs directly.

Errors:
- `401 UNAUTHORIZED`

### 1.10.1 `PATCH /v1/me/profile`

Partial update for the caller's shared principal profile.

Request (partial):

```json
{ "first_name": "New", "last_name": "Name", "avatar_uri": "/v1/media/avatars/<principal_id>/<avatar_id>.jpg" }
```

Response `200 OK`:

```json
{
  "principal_id": "uuid",
  "first_name": "New",
  "last_name": "Name",
  "display_name": "New Name",
  "avatar_uri": "/v1/media/avatars/<principal_id>/<avatar_id>.jpg"
}
```

Errors:
- `401 UNAUTHORIZED`
- `422 INVALID_REQUEST` (no fields provided)

### 1.10.2 `POST /v1/me/profile/avatar-upload`

Mints a **short-lived per-blob SAS URL** for uploading a profile photo (avatar) for the caller’s principal.

Auth:
- Requires `Authorization: Bearer <jwt>`.

Request:

```json
{
  "content_type": "image/jpeg",
  "size_bytes": 123456
}
```

Response `200 OK`:

```json
{
  "upload_url": "https://<account>.blob.core.windows.net/media/avatars/<principal_id>/<avatar_id>.jpg?<sas>",
  "avatar_uri": "/v1/media/avatars/<principal_id>/<avatar_id>.jpg",
  "expires_at": "2025-01-01T00:00:00Z"
}
```

Flow:
1) Client uploads bytes to `upload_url` (HTTP PUT).
2) Client sets the profile field via `PATCH /v1/me/profile` with `{ "avatar_uri": "<avatar_uri>" }`.

Errors:
- `401 UNAUTHORIZED`
- `422 VALIDATION_ERROR` (unsupported `content_type`, invalid `size_bytes`)
- `503 SERVICE_UNAVAILABLE` when blob storage is not configured (`details.reason = AZURE_STORAGE_NOT_CONFIGURED`)

### 1.10.3 `GET /v1/media/avatars/{principal_id}/{avatar_id}`

Returns the avatar/logo image as a redirect to a short-lived signed blob URL.

Auth:
- Requires `Authorization: Bearer <jwt>`.

Response:
- `302 Found` redirect to a signed blob URL.

Notes:
- The `media` container remains private; clients never receive storage account keys.

### 1.11 `GET /v1/accounts/{org_principal_id}/notification-preferences`

Response `200 OK`:

```json
{
  "events": {
    "orders": { "channels": { "app": true, "push": true, "sms": false, "email": false } },
    "water_risk": {
      "channels": { "app": true, "push": true, "sms": false, "email": false },
      "reservoir_level_state": { "full": false, "normal": false, "low": true, "critical": true }
    },
    "device_risk": { "channels": { "app": true, "push": false, "sms": false, "email": false } }
  }
}
```

Notes:
- This endpoint returns the caller’s saved preferences only.
- Delivery still depends on subscription entitlements (D-020/D-023) and verified identifiers.
- Push notifications are in scope for v1 (D-023) and require a registered push token.

### 1.12 `PATCH /v1/accounts/{org_principal_id}/notification-preferences`

Request (partial):

```json
{
  "events": {
    "orders": { "channels": { "push": false } },
    "water_risk": { "channels": { "sms": true }, "reservoir_level_state": { "full": true } }
  }
}
```

Response `200 OK`: updated preferences (same shape as `GET`).

### 1.12c `GET /v1/accounts/{org_principal_id}/notification-capabilities`

Returns effective per-toggle capability for the authenticated caller, including whether each toggle is editable and why it may be blocked.

Auth:
- Requires `Authorization: Bearer <jwt>`.

Response `200 OK`:

```json
{
  "plan_id": "monitor",
  "plan": {
    "plan_id": "monitor",
    "name": "Monitor",
    "description": "Basic visibility for 1 site with APP-only alerts.",
    "features": {
      "alerts.orders.APP": true,
      "alerts.orders.PUSH": false,
      "analytics.view": true,
      "analytics.export": false
    },
    "limits": {
      "max_members": 2,
      "max_sites": 1
    }
  },
  "entitlements": {
    "features": {
      "alerts.orders.APP": { "plan_enabled": true, "effective_enabled": true, "reasons": [] },
      "alerts.orders.PUSH": { "plan_enabled": false, "effective_enabled": false, "reasons": ["PLAN_FEATURE_DISABLED", "MISSING_PUSH_TOKEN"] },
      "analytics.view": { "plan_enabled": true, "effective_enabled": true, "reasons": [] },
      "analytics.export": { "plan_enabled": false, "effective_enabled": false, "reasons": ["PLAN_FEATURE_DISABLED"] }
    },
    "limits": {
      "max_members": 2,
      "max_sites": 1
    }
  },
  "events": {
    "orders": {
      "channels": {
        "app": { "value": true, "editable": true, "reasons": [] },
        "push": { "value": true, "editable": false, "reasons": ["PLAN_FEATURE_DISABLED", "MISSING_PUSH_TOKEN"] },
        "sms": { "value": false, "editable": false, "reasons": ["PLAN_FEATURE_DISABLED", "PHONE_NOT_VERIFIED"] },
        "email": { "value": false, "editable": false, "reasons": ["PLAN_FEATURE_DISABLED", "EMAIL_NOT_VERIFIED"] }
      }
    },
    "water_risk": {
      "channels": {
        "app": { "value": true, "editable": true, "reasons": [] },
        "push": { "value": true, "editable": false, "reasons": ["PLAN_FEATURE_DISABLED", "MISSING_PUSH_TOKEN"] },
        "sms": { "value": false, "editable": false, "reasons": ["PLAN_FEATURE_DISABLED", "PHONE_NOT_VERIFIED"] },
        "email": { "value": false, "editable": false, "reasons": ["PLAN_FEATURE_DISABLED", "EMAIL_NOT_VERIFIED"] }
      },
      "reservoir_level_state": { "full": false, "normal": false, "low": true, "critical": true }
    },
    "device_risk": {
      "channels": {
        "app": { "value": true, "editable": true, "reasons": [] },
        "push": { "value": false, "editable": false, "reasons": ["PLAN_FEATURE_DISABLED", "MISSING_PUSH_TOKEN"] },
        "sms": { "value": false, "editable": false, "reasons": ["PLAN_FEATURE_DISABLED", "PHONE_NOT_VERIFIED"] },
        "email": { "value": false, "editable": false, "reasons": ["PLAN_FEATURE_DISABLED", "EMAIL_NOT_VERIFIED"] }
      }
    }
  },
  "user_prerequisites": {
    "has_push_token": false,
    "phone_verified": false,
    "email_verified": false
  }
}
```

Notes:
- This endpoint is the canonical frontend source for **complete plan functionality mapping** in v1.
- Frontends should consume `plan.features` / `entitlements.features` directly instead of hard-coding plan rules.
- `entitlements.features` includes all configured feature keys (e.g., analytics and alert channels).
- `value` is the currently saved user preference.
- `editable=false` means UI should disable the toggle and may show upgrade/prerequisite guidance.
- Reasons:
  - `PLAN_FEATURE_DISABLED`
  - `MISSING_PUSH_TOKEN`
  - `PHONE_NOT_VERIFIED`
  - `EMAIL_NOT_VERIFIED`
- This endpoint is advisory for UX; delivery is still enforced server-side at fanout time.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

### 1.12a `POST /v1/accounts/{org_principal_id}/push-tokens`

Registers a device push token for the authenticated user (FCM).

Auth:
- Requires `Authorization: Bearer <jwt>`.

Request:

```json
{
  "platform": "ANDROID",
  "token": "string"
}
```

Response `200 OK`:

```json
{ "push_token_id": "uuid", "status": "ACTIVE" }
```

Notes:
- Idempotent: registering the same `token` again returns `200 OK` and re-activates it if previously disabled.
- The server never returns the raw token after registration.

Errors:
- `401 UNAUTHORIZED`
- `422 INVALID_REQUEST`

### 1.12b `DELETE /v1/accounts/{org_principal_id}/push-tokens/{push_token_id}`

Disables (soft-revokes) a previously registered push token for the authenticated user (idempotent).

Auth:
- Requires `Authorization: Bearer <jwt>`.

Response `200 OK`:

```json
{ "status": "OK" }
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` (token does not belong to caller)
- `404 RESOURCE_NOT_FOUND`

### 1.13 Organization Management Endpoints

#### 1.13.1 `POST /v1/accounts`

Create a new organization.

Auth:
- Requires `Authorization: Bearer <jwt>`.

Request:

```json
{
  "name": "Unitel",
  "legal_name": "Unitel SA",
  "country_code": "AO",
  "region": "Luanda",
  "city": "Luanda",
  "subscription": {
    "plan_id": "protect",
    "billing_period": "MONTHLY",
    "trial_days": 14
  }
}
```

Response `200 OK`:

```json
{
  "org_id": "uuid",
  "org_principal_id": "uuid"
}
```

Errors:
- `401 UNAUTHORIZED`

#### 1.13.2 `GET /v1/accounts/{org_principal_id}`

Get organization details.

Auth:
- Requires `Authorization: Bearer <jwt>` and active org membership.

Response `200 OK`:

```json
{
  "id": "uuid",
  "name": "Unitel",
  "country_code": "AO",
  "region": "Luanda",
  "city": "Luanda"
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

#### 1.13.3 `POST /v1/accounts/{org_principal_id}/members/invite`

Invite a user to the organization.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have org role `OWNER|MANAGER`.

Request:

```json
{
  "email": "user@org.com",
  "proposed_role": "VIEWER",
  "site_ids": ["uuid"]
}
```

Notes:
- `proposed_role` defaults to `"VIEWER"` when omitted.
- `site_ids` is optional.
- Role hierarchy is strict: only `OWNER` may invite with `proposed_role = OWNER`; `MANAGER` may invite only `MANAGER|VIEWER`.

Response `200 OK`:

```json
{
  "invite_token_id": "uuid",
  "expires_at": "2025-01-01T00:00:00Z"
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

#### 1.13.4 `GET /v1/accounts/{org_principal_id}/members`

List organization members.

Auth:
- Requires `Authorization: Bearer <jwt>` and active org membership.

Query params:
- `limit` (optional): 1–200 (default 50)
- `cursor` (optional): opaque cursor
- `include_stats` (optional): boolean (default `false`)
- `role` (optional): `OWNER|MANAGER|VIEWER`
- `status` (optional): `ACTIVE|PENDING_VERIFICATION|LOCKED|DISABLED`

Response `200 OK`:

```json
{
  "items": [
    {
      "user_id": "uuid",
      "email": "user@org.com",
      "display_name": "Derived from first_name + last_name (or null)",
      "role": "OWNER",
      "status": "ACTIVE",
      "last_login_at": "2025-01-01T00:00:00Z",
      "joined_at": "2025-01-01T00:00:00Z"
    }
  ],
  "next_cursor": "opaque"
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

#### 1.13.5 Account-first org member listing

V1 is strict account-first. Clients should:
- Call `GET /v1/me` to discover org memberships and `org_principal_id` values.
- Call `GET /v1/accounts/{org_principal_id}/members` for membership listing.

#### 1.13.6 `GET /v1/accounts/{org_principal_id}/invites`

List pending organization invites.

Auth:
- Requires `Authorization: Bearer <jwt>` and active org membership.

Query params:
- `limit` (optional): 1–200 (default 50)
- `cursor` (optional): opaque cursor
- `include_stats` (optional): boolean (default `false`)
- `proposed_role` (optional): `OWNER|MANAGER|VIEWER`

Response `200 OK`:

```json
{
  "items": [
    {
      "invite_token_id": "uuid",
      "email": "newuser@org.com",
      "proposed_role": "MANAGER",
      "status": "PENDING",
      "created_at": "2025-01-01T00:00:00Z",
      "expires_at": "2025-01-08T00:00:00Z"
    }
  ],
  "next_cursor": "opaque"
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

#### 1.13.7 Account-first org invites listing

Use `GET /v1/me` + `GET /v1/accounts/{org_principal_id}/invites`.

#### 1.13.8 `POST /v1/accounts/{org_principal_id}/invites/{invite_token_id}/revoke`

Revoke a pending invite.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have org role `OWNER|MANAGER`.

Request:
- Empty body.

Response `200 OK`:

```json
{ "status": "OK" }
```

Rules:
- Role hierarchy is strict:
  - only `OWNER` may set `role = OWNER`
  - `MANAGER` cannot modify a member whose current role is `OWNER`
- Owner-floor invariant: changes that would remove the last active `OWNER` return `409 RESOURCE_CONFLICT`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `409 RESOURCE_CONFLICT`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

#### 1.13.9 `POST /v1/org-invites/resolve` (Public)

Resolve an organization invite token and return onboarding details.

Auth:
- Public (no JWT).

Request:

```json
{ "invite_token_id": "uuid" }
```

Response `200 OK`:

```json
{
  "invite_token_id": "uuid",
  "org_id": "uuid",
  "org_name": "Optional org name (or null)",
  "email": "user@org.com",
  "proposed_role": "VIEWER",
  "site_ids": ["uuid"],
  "expires_at": "2025-01-08T00:00:00Z"
}
```

Errors:
- `409 INVITE_EXPIRED`
- `422 INVALID_INVITE`

#### 1.13.10 `POST /v1/org-invites/accept` (Public)

Accept an organization invite.

Auth:
- Public (no JWT).

Request:

```json
{
  "invite_token_id": "uuid",
  "email": "user@org.com",
  "phone_e164": "+2449XXXXXXX",
  "password": "plaintext",
  "preferred_language": "pt"
}
```

Response `200 OK`:

```json
{
  "user_id": "uuid",
  "status": "ACTIVE",
  "org_id": "uuid",
  "org_principal_id": "uuid",
  "otp_sent_via": null
}
```

Side effects:
- On first invite acceptance, email is considered verified for the invite target and account status may transition to `ACTIVE`.
- For newly created users in this flow, the backend also ensures a personal default organization (name inherits from user naming with fallback) and grants `OWNER` on that personal org.
- The invite membership grant for the target organization is materialized idempotently.

Errors:
- `403 ACCOUNT_DISABLED`
- `409 INVITE_EXPIRED`
- `409 IDENTIFIER_ALREADY_IN_USE`
- `422 INVALID_INVITE`
- `422 VALIDATION_ERROR`

#### 1.13.11 `PATCH /v1/accounts/{org_principal_id}/members/{user_id}`

Update an org member's role.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have org role `OWNER|MANAGER`.

Request:

```json
{ "role": "OWNER|MANAGER|VIEWER" }
```

Response `200 OK`:

```json
{ "status": "OK" }
```

Rules:
- Role hierarchy is strict: `MANAGER` cannot revoke a member whose current role is `OWNER`.
- Owner-floor invariant: revoking an owner that would remove the last active `OWNER` returns `409 RESOURCE_CONFLICT`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `409 RESOURCE_CONFLICT`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

#### 1.13.12 `POST /v1/accounts/{org_principal_id}/members/{user_id}/revoke`

Revoke user's access to organization.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have org role `OWNER|MANAGER`.

Request:
- Empty body.

Response `200 OK`:

```json
{ "status": "OK" }
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

#### 1.13.13 `GET /v1/accounts/{org_principal_id}/profile`

Get organization profile.

Auth:
- Requires `Authorization: Bearer <jwt>` and active org membership.

Response `200 OK`:

```json
{
  "org_id": "uuid",
  "org_principal_id": "uuid",
  "org_name": "Organization name (or null)",
  "display_name": "Organization name (or null)",
  "avatar_uri": "/v1/media/avatars/<org_principal_id>/<avatar_id>.png (or null)"
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`

#### 1.13.14 `PATCH /v1/accounts/{org_principal_id}/profile`

Update organization profile.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have org role `OWNER|MANAGER`.

Request (partial):

```json
{ "org_name": "New organization name", "avatar_uri": "/v1/media/avatars/<org_principal_id>/<avatar_id>.png" }
```

Response `200 OK`: same as `GET /v1/accounts/{org_principal_id}/profile`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `422 INVALID_REQUEST`

#### 1.13.15 `POST /v1/accounts/{org_principal_id}/profile/avatar-upload`

Request presigned URL for org avatar upload.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have org role `OWNER|MANAGER`.

Request:

```json
{
  "content_type": "image/jpeg",
  "size_bytes": 123456
}
```

Response `200 OK`:

```json
{
  "upload_url": "https://<account>.blob.core.windows.net/media/avatars/<org_principal_id>/<avatar_id>.jpg?<sas>",
  "avatar_uri": "/v1/media/avatars/<org_principal_id>/<avatar_id>.jpg",
  "expires_at": "2025-01-01T00:00:00Z"
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `422 VALIDATION_ERROR`
- `503 SERVICE_UNAVAILABLE`

#### 1.13.16 `GET /v1/me` (portal bootstrap)

The portal bootstrap endpoint is `GET /v1/me`.

#### 1.13.17 `POST /v1/accounts/{org_principal_id}/erase`

Hard-delete an organization (admin-only).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must be an internal ops admin.

Request:
- Empty body.

Response `200 OK`:

```json
{ "status": "OK" }
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `404 RESOURCE_NOT_FOUND`

---
