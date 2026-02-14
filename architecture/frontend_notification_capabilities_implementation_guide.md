## Frontend Implementation Guide — Notification Capabilities

Purpose: provide a single, practical guide for frontend implementation of notification settings with plan-aware gating and prerequisite-aware UX.

This guide describes how to use the capabilities endpoint as a **dynamic source-of-truth** so users do not configure channels/features that cannot deliver.

---

## 1) Product goal

When a user opens notification settings, the UI should:

- Show current preference values.
- Disable toggles that are not actionable.
- Explain why each blocked toggle is blocked.
- Offer an upgrade prompt when blocked by plan.
- Offer verification / device setup prompts when blocked by prerequisites.

When a user navigates other feature surfaces (for example analytics export), the UI should also read entitlement status from the same endpoint.

Backend still enforces delivery at fanout time. This endpoint is the frontend contract to make UX deterministic before save.

---

## 2) Endpoints to use

### Required

- GET `/v1/accounts/{org_principal_id}/notification-capabilities`
- PATCH `/v1/accounts/{org_principal_id}/notification-preferences`
- POST `/v1/accounts/{org_principal_id}/push-tokens`
- DELETE `/v1/accounts/{org_principal_id}/push-tokens/{push_token_id}`

### Optional (for upgrade UI and plan page)

- GET `/v1/plans`
- GET `/v1/accounts/{org_principal_id}/subscription`

Note: `notification-capabilities` already includes plan snapshot + entitlements and is sufficient for runtime UI gating.

---

## 3) Capabilities response shape

Example:

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
    "limits": { "max_members": 2, "max_sites": 1 }
  },
  "entitlements": {
    "features": {
      "alerts.orders.APP": { "plan_enabled": true, "effective_enabled": true, "reasons": [] },
      "alerts.orders.PUSH": { "plan_enabled": false, "effective_enabled": false, "reasons": ["PLAN_FEATURE_DISABLED", "MISSING_PUSH_TOKEN"] },
      "analytics.view": { "plan_enabled": true, "effective_enabled": true, "reasons": [] },
      "analytics.export": { "plan_enabled": false, "effective_enabled": false, "reasons": ["PLAN_FEATURE_DISABLED"] }
    },
    "limits": { "max_members": 2, "max_sites": 1 }
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

Semantics:

- `value`: current stored preference.
- `editable`: whether user can modify this toggle now.
- `reasons`: why it is blocked.
- `plan.features`: full configured plan feature map.
- `entitlements.features`: evaluated per-feature state for frontend gating across all surfaces.
- `entitlements.limits`: quantitative limits for account-level UX messaging.

Reason codes:

- `PLAN_FEATURE_DISABLED`
- `MISSING_PUSH_TOKEN`
- `PHONE_NOT_VERIFIED`
- `EMAIL_NOT_VERIFIED`

---

## 4) UI behavior contract

### 4.1 Notification toggles

For each toggle:

1. Render switch using `value`.
2. If `editable == false`, disable switch.
3. Show helper text based on `reasons`.
4. If reasons contains `PLAN_FEATURE_DISABLED`, show upgrade CTA.
5. If reasons contains prerequisite reasons, show setup CTA:
   - `MISSING_PUSH_TOKEN` -> register push token flow
   - `PHONE_NOT_VERIFIED` -> phone verification flow
   - `EMAIL_NOT_VERIFIED` -> email verification flow

If multiple reasons exist, render a priority order:

1. `PLAN_FEATURE_DISABLED`
2. `MISSING_PUSH_TOKEN`
3. `PHONE_NOT_VERIFIED`
4. `EMAIL_NOT_VERIFIED`

Recommended copy style:

- Plan: “Available on Protect or Pro.”
- Push token: “Enable push on this device to receive push alerts.”
- Phone: “Verify your phone number to receive SMS alerts.”
- Email: “Verify your email to receive email alerts.”

---

### 4.2 Non-notification features (e.g. analytics)

- For any feature key, evaluate `entitlements.features[feature_key]`.
- If `effective_enabled=false`, disable/guard entry points and show reason-driven UX.
- Example:
  - `analytics.view`
  - `analytics.export`

## 5) Frontend flow

### On settings screen load

1. Resolve selected org account context (`org_principal_id`) from app state.
2. GET notification capabilities.
3. Bind `events` to notification toggles.
4. Bind `entitlements.features` to all feature guards (including analytics screens/actions).

### On user toggles an editable switch

1. Build minimal PATCH payload for changed fields only.
2. PATCH notification preferences.
3. Re-fetch capabilities and rebind UI.

### On user taps blocked push toggle helper CTA

1. Trigger OS permission flow.
2. On success, POST push token.
3. Re-fetch capabilities.
4. Toggle becomes editable if plan allows push.

### On logout / device revoke

1. DELETE push token for current device.
2. Re-fetch capabilities (or clear local state).

---

## 6) Mapping for settings sections

Use these event groups and channels exactly:

- `orders.channels.{app,push,sms,email}`
- `water_risk.channels.{app,push,sms,email}`
- `water_risk.reservoir_level_state.{full,normal,low,critical}`
- `device_risk.channels.{app,push,sms,email}`

Important: `reservoir_level_state` are preference values; channel editability still comes from `channels` capability flags.

---

## 7) Error handling

- `401`: clear session and return to auth flow.
- `403`: user lacks account access; show account access error and account switch option.
- `422` on PATCH: keep current UI state, show inline error, then refresh capabilities to recover.

---

## 8) Acceptance checklist for frontend

- Settings page never shows actionable toggles when `editable=false`.
- Blocked toggles always display at least one reason.
- Upgrade CTA shown when `PLAN_FEATURE_DISABLED` present.
- Push token registration path can unblock push toggles without app restart.
- After any PATCH, page re-syncs from capabilities endpoint.
- No feature enablement logic is hard-coded by plan in frontend.
- Analytics/UI feature availability is driven from `entitlements.features`.

---

## 9) Source references

- API route implementation: `app/modules/identity_access/api/router.py`
- Capability derivation service: `app/modules/identity_access/service/service.py`
- Push-token persistence helper: `app/modules/identity_access/db/repo.py`
- Canonical API contract section: `docs/architecture/api_contract/02_auth_identity.md`
