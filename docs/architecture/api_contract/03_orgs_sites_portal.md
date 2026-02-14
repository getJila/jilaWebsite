## Jila API Backend – API Contract (v1) — Orgs & sites (portal) (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

## 2. Organizations & sites (portal)

### 2.0a Account-first routing (portal) — canonical

Portal endpoints are **account-first** and are scoped via `/v1/accounts/{org_principal_id}/…`.

Notes:
- `org_principal_id` is the **organization principal id** for org portal flows (not `organizations.id`).
- Use `GET /v1/me` to discover org memberships and the corresponding `org_principal_id` values.
- Canonical routing is determined by the URL path (`org_principal_id`) plus the authenticated principal.

### 2.0 Org invite acceptance flow (end-to-end)

### 2.0b `GET /v1/me`

Returns identity and org memberships for the authenticated caller (portal bootstrap).

Auth:
- Requires `Authorization: Bearer <jwt>`.

Response `200 OK`:

```json
{
  "user": {
    "id": "uuid",
    "email": "user@org.com",
    "phone_e164": "+2449XXXXXXX",
    "status": "ACTIVE",
    "preferred_language": "pt"
  },
  "principal_id": "uuid",
  "org_memberships": [
    {
      "org_id": "uuid",
      "org_principal_id": "uuid",
      "role": "OWNER|MANAGER|VIEWER"
    }
  ],
  "default_org_id": "uuid|null"
}
```

Notes:
- `org_principal_id` is the org account id used for `/v1/accounts/{org_principal_id}/…` endpoints.

Errors:
- `401 UNAUTHORIZED`


This is the recommended end-to-end flow for **inviting an org user** and then **onboarding/activating** that user on the client.

Portal/admin (authenticated, org RBAC):
- `POST /v1/accounts/{org_principal_id}/members/invite` creates/reuses an invite token (`invite_token_id`, `expires_at`).
  - Emits outbox event `ORG_INVITE_SENT` (even if reusing an existing active invite) so a worker can attempt email delivery.
  - Email delivery is asynchronous/best-effort; `200 OK` means “token created/reused and queued”, not “email delivered”.
  - Invite emails should deep-link to the portal invite screen with the token in the URL fragment (to reduce accidental leakage via Referer):
    - `${FRONTEND_URL}/invite#invite_token_id={invite_token_id}`
  - Frontend should set `Referrer-Policy: no-referrer` on the invite page (and avoid third-party scripts) to further reduce token leakage risk.
- Optional management:
  - `GET /v1/accounts/{org_principal_id}/invites` lists pending invites (portal UI “invited users” screen).
  - `POST /v1/accounts/{org_principal_id}/invites/{invite_token_id}/revoke` cancels an invite token (idempotent).
  - `GET /v1/accounts/{org_principal_id}/members` lists active members (access management).

Invited user onboarding (public, no JWT):
- `POST /v1/org-invites/resolve` validates the token and returns onboarding prefill (`org_name`, invited `email`, `proposed_role`, `site_ids`, `expires_at`).
  - Recommended UX entrypoint before collecting password/phone (fail fast on `INVALID_INVITE` / `INVITE_EXPIRED`).
- `POST /v1/org-invites/accept` materializes org membership (`access_grants`) for the invited user and returns:
  - `email` must match the invite token target (anti-theft); clients should source it from `POST /v1/org-invites/resolve` and avoid free-form edits.
  - `status = ACTIVE`
  - `otp_sent_via = null` (invite token serves as email verification)
  - Emits `ORG_INVITE_ACCEPTED` when grants are materialized.
- Once `ACTIVE`, client logs in normally:
  - `POST /v1/auth/login` (anti-enumeration safe).

Notes / edge cases:
- `POST /v1/org-invites/accept` is idempotent for a given `invite_token_id` (safe to retry).
- If the invited email/phone is already owned by another `ACTIVE` user, accept returns `409 IDENTIFIER_ALREADY_IN_USE` (deterministic; no account takeover).
- If the invited user already exists and is `ACTIVE`, accept **does not** overwrite their password; they must log in with their existing credentials.
- Deployment requirement: invite emails and OTP delivery require a running worker (outbox consumers) and configured email/SMS providers; without it, invites/OTPs will be queued but not delivered.

### 2.1 `POST /v1/accounts`

Request:

```json
{
  "name": "Unitel",
  "legal_name": "Unitel SA",
  "country_code": "AO",
  "region": "Luanda",
  "city": "Luanda",
  "subscription": {
    "plan_id": "monitor",
    "billing_period": "MONTHLY",
    "trial_days": 14
  }
}
```

Response `200 OK`:

```json
{
  "org_principal_id": "uuid",
  "organization_id": "uuid"
}
```

Side effects:
- Creates org principal.
- Grants creator `OWNER` on `ORG:<org_id>` via `access_grants`.
- Initializes the org subscription (plan selection):
  - `subscription.plan_id ∈ {monitor, protect, pro}`.
  - Requires `subscription.billing_period ∈ {MONTHLY, YEARLY}`.
  - Optional `subscription.trial_days` is allowed in range `0..90` (default `14` when omitted).

### 2.2 `GET /v1/accounts/{org_principal_id}`

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

### 2.2.0 `GET /v1/accounts/{org_principal_id}/dashboard-stats`

Dashboard rollup stats for the portal (DECIDED, D-064).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have effective visibility into `ORG:<org_id>`.
- Stats must honor site-scoped grants and only count resources visible to the caller.

Response `200 OK`:

```json
{
  "org_id": "uuid",
  "snapshot_at": "2025-01-01T00:00:00Z",
  "reservoirs": {
    "total": 42,
    "by_level_state": { "FULL": 5, "NORMAL": 20, "LOW": 12, "CRITICAL": 5 },
    "by_connectivity_state": { "ONLINE": 35, "STALE": 5, "OFFLINE": 2 }
  },
  "devices": {
    "total": 38,
    "by_status": { "ONLINE": 30, "OFFLINE": 6, "MAINTENANCE": 2 },
    "battery_health": { "good_count": 25, "low_count": 10, "critical_count": 3 },
    "low_battery_count": 13
  },
  "alerts": {
    "unread_total": 15,
    "by_severity": { "CRITICAL": 3, "WARNING": 8, "INFO": 4 }
  },
  "sites": {
    "total": 12,
    "by_risk_level": { "CRITICAL": 1, "WARNING": 3, "STALE": 1, "GOOD": 7 }
  }
}
```

Notes:
- Device battery rollup shape is DECIDED in **D-065**:
  - `battery_health` provides the bounded severity distribution.
  - `low_battery_count` is a convenience scalar derived from `battery_health.low_count + battery_health.critical_count`.

### 2.2.0a `GET /v1/accounts/{org_principal_id}/dashboard-snapshot`

One-call org dashboard bootstrap payload combining:
- Existing dashboard rollups (`dashboard-stats` shape)
- Org analytics (`/v1/accounts/{org_principal_id}/analytics` shape)

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have effective visibility into `ORG:<org_id>`.
- Requires `analytics.view` entitlement for the org account.
- If `analytics.view` is not entitled, the endpoint fails as a whole with `403 FEATURE_GATE`.

Query params:
| Parameter | Type | Notes |
|----------|------|-------|
| `window` | string | optional: `24h|7d|30d` (default `24h`) |

Response `200 OK`:

```json
{
  "org_id": "uuid",
  "snapshot_at": "2026-02-14T12:00:00Z",
  "window_label": "24h",
  "dashboard_stats": {
    "org_id": "uuid",
    "snapshot_at": "2026-02-14T12:00:00Z",
    "reservoirs": {
      "total": 42,
      "by_level_state": { "FULL": 5, "NORMAL": 20, "LOW": 12, "CRITICAL": 5 },
      "by_connectivity_state": { "ONLINE": 35, "STALE": 5, "OFFLINE": 2 }
    },
    "devices": {
      "total": 38,
      "by_status": { "ONLINE": 30, "OFFLINE": 6, "MAINTENANCE": 2 },
      "battery_health": { "good_count": 25, "low_count": 10, "critical_count": 3 },
      "low_battery_count": 13
    },
    "alerts": {
      "unread_total": 15,
      "by_severity": { "CRITICAL": 3, "WARNING": 8, "INFO": 4 }
    },
    "sites": {
      "total": 12,
      "by_risk_level": { "CRITICAL": 1, "WARNING": 3, "STALE": 1, "GOOD": 7 }
    }
  },
  "org_analytics": {
    "snapshot_at": "2026-02-14T12:00:00Z",
    "window_label": "24h",
    "window_start": "2026-02-13T12:00:00Z",
    "window_end": "2026-02-14T12:00:00Z",
    "computed_at": "2026-02-14T12:00:00Z",
    "inputs_version": 1,
    "metric_version": 1,
    "data_gap_hours": 0.0,
    "confidence": "HIGH",
    "runout_hours": 48.0,
    "runout_prob": 0.0,
    "autonomy_days_est": 2.0,
    "supply_hours": 10.0,
    "supply_fragmentation_index": 0.2,
    "mean_supply_duration_hours": 2.5,
    "daily_supply_coverage": 0.42,
    "intermittence_severity_index": 0.1,
    "demand_liters": 1200.0,
    "elasticity_near_empty": 0.0,
    "suppressed_demand_index": 0.0,
    "deliveries_count": 0,
    "delivered_liters": 0.0,
    "liters_loaded": 0.0,
    "liters_per_km": null,
    "refill_time_minutes": 0.0,
    "refill_load_rate_l_per_min": null,
    "downtime_hours": 0.0,
    "mobile_nrw_liters": 0.0,
    "pipeflow_liters": 1200.0,
    "truckflow_liters": 0.0,
    "resilience_ratio": 1.0,
    "org_principal_id": "uuid"
  }
}
```

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN`
- `403 FEATURE_GATE` (`details.feature_key = "analytics.view"`)
- `404 RESOURCE_NOT_FOUND`
- `422 VALIDATION_ERROR`

### 2.2.1 `GET /v1/accounts/{org_principal_id}/profile`

Returns the organization’s shared profile surface (display identity surface) including its logo URI.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have an active org membership grant.

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

### 2.2.2 `PATCH /v1/accounts/{org_principal_id}/profile`

Partial update for the org’s shared profile surface.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have org role `OWNER|MANAGER`.

Request (partial):

```json
{ "org_name": "New organization name", "avatar_uri": "/v1/media/avatars/<org_principal_id>/<avatar_id>.png" }
```

Response `200 OK`: same shape as `GET /v1/accounts/{org_principal_id}/profile`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` when caller is not `OWNER|MANAGER`
- `422 INVALID_REQUEST` (no fields provided)

### 2.2.3 `POST /v1/accounts/{org_principal_id}/profile/avatar-upload`

Mints a short-lived per-blob SAS URL for uploading an org logo (stored as `avatar_uri` on the org principal profile).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have org role `OWNER|MANAGER`.

Request/response shapes match `POST /v1/me/profile/avatar-upload`.

### 2.3 `POST /v1/accounts/{org_principal_id}/sites`

Request:

```json
{
  "name": "Site A",
  "site_type": "WATER_TREATMENT",
  "country_code": "AO",
  "region": "Luanda",
  "city": "Luanda",
  "location": { "lat": -8.84, "lng": 13.23 },
  "zone_id": null
}
```

Response `200 OK`:

```json
{ "site_id": "uuid" }
```

### 2.4 `GET /v1/accounts/{org_principal_id}/sites`

Query params (optional; v1):
- `limit` (int, default: 50, max: 200)
- `cursor` (opaque string from a previous page)
- `site_type` (string enum; exact match)
- `country_code` (ISO 3166-1 alpha-2; exact match, case-insensitive)
- `region` (string; exact match, case-insensitive)
- `city` (string; exact match, case-insensitive)
- `has_reservoirs` (boolean; when true, only sites with at least one reservoir)

Response `200 OK`:

```json
{
  "items": [
    {
      "site_id": "uuid",
      "name": "Site A",
      "site_type": "WATER_TREATMENT",
      "country_code": "AO",
      "region": "Luanda",
      "city": "Luanda",
      "address": "123 Main St",
      "location": { "lat": -8.84, "lng": 13.23 },
      "status": "ACTIVE",
      "risk_level": "GOOD",
      "reservoir_count": 3,
      "device_count": 12,
      "active_alert_count": 2,
      "updated_at": "2025-01-01T00:00:00Z"
    }
  ],
  "next_cursor": "opaque|null"
}
```

Notes (DECIDED, D-032):
- This endpoint returns a portal-friendly “site summary” shape to avoid UI fabrication and N+1 fan-out.
- `location` may be `null` when coordinates are unknown; portal map pins must handle nulls gracefully.
- `status` is the operational state of the site container (not a freshness indicator).
- `risk_level` is a rollup for quick triage (v1):
  - `CRITICAL|WARNING` indicate the highest-severity active condition at the site.
  - `STALE` means “data is too old to trust” (distinct from water risk).
  - `GOOD` means no current high-risk signals.
- `reservoir_count`, `device_count`, `active_alert_count` are non-negative integers for the site scope visible to the org.
- `updated_at` is the list/map freshness anchor:
  - It reflects the most recent change to the site record *or* its rolled-up summary inputs (counts/risk), whichever is later.

### 2.4a `GET /v1/sites/{site_id}`

Returns a portal-friendly site detail view including lightweight summaries for reservoirs/devices/alerts (DECIDED, D-033).

Response `200 OK`:

```json
{
  "site_id": "uuid",
  "org_id": "uuid",
  "name": "Site A",
  "site_type": "WATER_TREATMENT",
  "description": "optional",
  "country_code": "AO",
  "region": "Luanda",
  "city": "Luanda",
  "address": "123 Main St",
  "location": { "lat": -8.84, "lng": 13.23 },
  "timezone": "Africa/Luanda",
  "status": "ACTIVE",
  "risk_level": "GOOD",
  "statistics": {
    "reservoir_count": 3,
    "device_count": 12,
    "active_alert_count": 2
  },
  "reservoirs": [
    {
      "reservoir_id": "uuid",
      "name": "Tank A",
      "level_state": "NORMAL",
      "level_pct": 75,
      "latest_recorded_at": "2025-01-01T00:00:00Z"
    }
  ],
  "devices": [
    {
      "device_id": "string",
      "serial_number": "JL-001234",
      "status": "ONLINE",
      "last_seen_at": "2025-01-01T00:00:00Z",
      "config_state": {
        "desired": [
          {
            "type": "operation",
            "config_version": 123,
            "mqtt_queue_id": "op-1",
            "updated_at": "2025-01-01T00:00:00Z",
            "state": "PENDING",
            "config": {
              "type": "operation",
              "sleep_duration_ms": 30000,
              "sleep_mode": "POWER_MANAGED",
              "battery_voltage_critical": 3200,
              "battery_voltage_low": 3500,
              "battery_voltage_normal": 3800,
              "samples_per_reading": 5,
              "reservoir_id": null
            }
          }
        ],
        "applied": [],
        "ack": []
      }
    }
  ],
  "active_alerts": [
    {
      "alert_id": "uuid",
      "severity": "WARNING",
      "rendered_title": "Battery low"
    }
  ],
  "created_at": "2025-01-01T00:00:00Z",
  "updated_at": "2025-01-01T00:00:00Z"
}
```

### 2.5 `PATCH /v1/sites/{site_id}`

Request (partial):

```json
{
  "name": "Site A",
  "country_code": "AO",
  "region": "Luanda",
  "city": "Luanda",
  "location": { "lat": -8.84, "lng": 13.23 },
  "zone_id": null
}
```

Response `200 OK`:

```json
{ "site_id": "uuid" }
```

Rules:
- Requires org role `OWNER|MANAGER` on the owning org principal.
- Soft-deleted sites return `404`.

### 2.6 `DELETE /v1/sites/{site_id}` (soft delete)

Response `200 OK`:

```json
{ "status": "OK" }
```

Rules:
- Soft delete: preserve rows; set `sites.deleted_at`.
- Idempotent: deleting an already-deleted site returns `200 OK`.
- Deleted sites are excluded from `/v1/accounts/{org_principal_id}/sites`.
- If the site has active reservoirs (`reservoirs.site_id = site_id` and `reservoirs.deleted_at IS NULL`), return `409 RESOURCE_CONFLICT`.

### 2.7 `POST /v1/accounts/{org_principal_id}/members/invite`

Creates an invite token which, when accepted, materializes `access_grants`.

Request:

```json
{
  "email": "user@org.com",
  "proposed_role": "MANAGER",
  "site_ids": ["uuid"]
}
```

Response `200 OK`:

```json
{
  "invite_token_id": "uuid",
  "expires_at": "2025-01-01T00:00:00Z"
}
```

Rules / notes:
- Requires org role `OWNER|MANAGER` on the owning org for the referenced `org_principal_id`.
- Role hierarchy is strict: only `OWNER` may invite with `proposed_role = OWNER`; `MANAGER` may invite only `MANAGER|VIEWER`.
- The server emits an outbox event `ORG_INVITE_SENT` (even when reusing an existing active invite token) so a worker can attempt email delivery.
- Email delivery is asynchronous and best-effort (D-012); `200 OK` means “invite token created/reused and queued for delivery”, not “email delivered”.

### 2.7a `GET /v1/accounts/{org_principal_id}/members`

Lists organization members for portal access management (DECIDED, D-035).

Query params:
- `limit` (optional): 1–200 (default 50)
- `cursor` (optional): opaque cursor returned from a previous page
- `include_stats` (optional): boolean (default `false`); when true, include aggregate stats for the full filtered set (D-064)
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
      "role": "OWNER|MANAGER|VIEWER",
      "status": "ACTIVE|PENDING_VERIFICATION|LOCKED|DISABLED",
      "last_login_at": "2025-01-01T00:00:00Z",
      "joined_at": "2025-01-01T00:00:00Z"
    }
  ],
  "next_cursor": "opaque",
  "stats": {
    "total_count": 25,
    "by_role": { "OWNER": 1, "MANAGER": 8, "VIEWER": 16 },
    "by_status": { "ACTIVE": 22, "PENDING_VERIFICATION": 2, "LOCKED": 1 }
  }
}
```

Notes:
- This endpoint is paginated; `next_cursor = null` means no more results.
- `status` is the user account status (not "membership status"): `ACTIVE|PENDING_VERIFICATION|LOCKED|DISABLED`.
- `last_login_at` may be `null` for users who have never successfully logged in.
- `stats` is included only when `include_stats=true` and is computed across the full filtered set (not the page). See **D-064**.

### 2.7b `GET /v1/accounts/{org_principal_id}/invites`

Lists pending invites for portal access management (DECIDED, D-035).

Query params:
- `limit` (optional): 1–200 (default 50)
- `cursor` (optional): opaque cursor returned from a previous page
- `include_stats` (optional): boolean (default `false`); when true, include aggregate stats for the full filtered set (D-064)
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
  "next_cursor": "opaque",
  "stats": {
    "total_pending": 8,
    "expiring_within_24h": 2,
    "by_proposed_role": { "MANAGER": 5, "VIEWER": 3 }
  }
}
```

Notes:
- `invite_token_id` matches the identifier returned by `POST /v1/accounts/{org_principal_id}/members/invite`.
- `status` is currently `PENDING` for all returned items in v1 (this endpoint lists pending invites).
- This endpoint is paginated; `next_cursor = null` means no more results.
- `stats` is included only when `include_stats=true` and is computed across the full filtered set (not the page). See **D-064**.

### 2.7c `POST /v1/accounts/{org_principal_id}/invites/{invite_token_id}/revoke`

Revoke (cancel) a pending org invite token for portal access management.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have org RBAC (`OWNER|MANAGER`).

Request:
- Empty body.

Response `200 OK`:

```json
{ "status": "OK" }
```

Semantics (idempotent):
- If the invite token exists, belongs to the org, and is still active, the server sets `tokens.revoked_at`.
- Revoking an already-revoked token returns `200 OK`.
- Revoking a token that has already been accepted (used) returns `200 OK` (no-op).

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` when caller is not `OWNER|MANAGER` for the org
- `404 RESOURCE_NOT_FOUND` when the invite token does not exist for that org
- `422 VALIDATION_ERROR` when ids are not valid UUIDs

### 2.8 `POST /v1/org-invites/accept`

Accepts an organization invite and onboards (or links) the invited user.

Auth:
- Public (no JWT) — this is the entrypoint for first-time org users.

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

Rules (v1, robust + simple; see decision **D-004**):
- `email` must match the invite token’s `target_identifier` (anti-theft).
- Both `email` and `phone_e164` are required for org users.
- Invite acceptance via the emailed invite token is treated as **email verification**:
  - If `email_verified_at` is null, the server sets it during invite acceptance.
  - Phone verification is deferred to a later authenticated UX prompt.
- The user becomes `ACTIVE` immediately after accepting the invite (email verified via token).

Response `200 OK` (idempotent if called again with the same invite token id):

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
- Validates invite token (`type = INVITE`, not expired, not used/revoked).
- Creates or links a `users` row by `email` (subject to uniqueness constraints).
- Creates an org membership grant and any scoped site grants described by the invite.
- Emits `ORG_INVITE_ACCEPTED` when grants are materialized.
- Does not send a verification OTP; the invite token serves as the email verification proof.

Errors:
- `403 ACCOUNT_DISABLED` when the matched user is `LOCKED|DISABLED`
- `409 INVITE_EXPIRED` when invite is expired
- `409 IDENTIFIER_ALREADY_IN_USE` when `email` or `phone_e164` is already owned by another `ACTIVE` user
- `422 INVALID_INVITE` when invite token is invalid/used/revoked, or email does not match the invite target
- `422 VALIDATION_ERROR` when request fields are invalid (e.g., invalid `phone_e164`)

### 2.8a `POST /v1/org-invites/resolve` (public)

Resolve an org invite token and return onboarding prefill details (recommended UX entrypoint before calling accept).

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
  "proposed_role": "OWNER|MANAGER|VIEWER",
  "site_ids": ["uuid"],
  "expires_at": "2025-01-08T00:00:00Z"
}
```

Rules:
- Validates invite token (`type = INVITE`, `object_type = ORG`, not expired, not used/revoked).
- `email` is sourced from `tokens.target_identifier` and should be used to prefill the accept form.

Errors:
- `409 INVITE_EXPIRED` when invite is expired
- `422 INVALID_INVITE` when invite token is invalid/used/revoked

### 2.8.1 `PATCH /v1/accounts/{org_principal_id}/members/{user_id}`

Update an org member's role.

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have org RBAC (`OWNER|MANAGER`).

Request:

```json
{ "role": "OWNER|MANAGER|VIEWER" }
```

Response `200 OK`:

```json
{ "status": "OK" }
```

Semantics (idempotent):
- Updates the `access_grants.role` for the user's org membership when it exists and is `ACTIVE`.
- No changes are made when the requested role matches the existing role.
- Role hierarchy is strict:
  - only `OWNER` may set `role = OWNER`
  - `MANAGER` cannot modify a member whose current role is `OWNER`
- Owner-floor invariant: a role change that would remove the last active `OWNER` returns `409 RESOURCE_CONFLICT`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` (`error_code = FORBIDDEN`) when caller is not `OWNER|MANAGER` for the org
- `403 FORBIDDEN` (`error_code = FORBIDDEN`) on role-hierarchy violations (e.g., manager assigning `OWNER`)
- `409 RESOURCE_CONFLICT` when the change would remove the last active `OWNER`
- `404 RESOURCE_NOT_FOUND` when `org_id` or `user_id` does not exist, or the user is not a member
- `422 VALIDATION_ERROR` when ids are not valid UUIDs or role is invalid

### 2.8.2 `POST /v1/accounts/{org_principal_id}/members/{user_id}/revoke`

Revokes a user's access to an organization (membership + scoped site/reservoir grants).

Auth:
- Requires `Authorization: Bearer <jwt>` and caller must have org RBAC (`OWNER|MANAGER`).

Request:
- Empty body.

Response `200 OK`:

```json
{ "status": "OK" }
```

Semantics (idempotent):
- Revokes the user's `access_grants` for:
  - `object_type = ORG` / `object_id = org_id`
  - any `SITE` grants for sites owned by the org principal
  - any `RESERVOIR` grants for reservoirs owned by the org principal
- The user remains in the system, but loses access to org resources.
- Emits `FIRESTORE_MIRROR_RECONCILE_REQUESTED` for the revoked user's principal to prune Firestore mirrors.
- Role hierarchy is strict: `MANAGER` cannot revoke a member whose current role is `OWNER`.
- Owner-floor invariant: revoking an `OWNER` that would leave zero active owners returns `409 RESOURCE_CONFLICT`.

Errors:
- `401 UNAUTHORIZED`
- `403 FORBIDDEN` (`error_code = FORBIDDEN`) when caller is not `OWNER|MANAGER` for the org
- `403 FORBIDDEN` (`error_code = FORBIDDEN`) when a manager tries to revoke an owner
- `409 RESOURCE_CONFLICT` when revoke would remove the last active `OWNER`
- `404 RESOURCE_NOT_FOUND` when `org_id` or `user_id` does not exist
- `422 VALIDATION_ERROR` when ids are not valid UUIDs
