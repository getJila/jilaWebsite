## Jila API Backend – API Contract (v1) — Subscriptions (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

## 10. Subscriptions

### 10.0 `GET /v1/plans`

List the canonical v1 plans (for plan selection UI).

Auth:
- Requires `Authorization: Bearer <jwt>`.

Response `200 OK`:

```json
{
  "items": [
    {
      "plan_id": "monitor",
      "name": "Monitor",
      "description": "Base monitoring plan (v1)",
      "currency": "AOA",
      "monthly_price": 0,
      "yearly_price": 0,
      "monthly_credits_grant": 0,
      "yearly_credits_grant": 0,
      "features": {
        "alerts.reservoir_level_state.APP": true,
        "alerts.device_health.APP": true,
        "alerts.orders.APP": true,
        "analytics.view": true
      },
      "limits": {
        "max_members": 2,
        "max_sites": 1
      }
    }
  ]
}
```

Notes:
- Pricing fields are **display-only** in v1; payment flows are out of scope.
- Entitlements are derived from `plans.config.features` (missing keys are treated as `false`).
- V1 tiers differentiate between `Monitor` (Basic/Free), `Protect` (Paid), and `Pro` (Premium/Fleet) entitlements.

### 10.0a `GET /v1/plans/{plan_id}`

Get a single plan by id.

Auth:
- Requires `Authorization: Bearer <jwt>`.

Response `200 OK`: returns one plan object (same shape as `items[*]` above).

### 10.1 `GET /v1/accounts/{org_principal_id}/subscription`

Get current subscription details for the referenced account principal.

`org_principal_id`:
- Organization principal: caller must have an org role (`OWNER|MANAGER|VIEWER`) on that organization.

Auth:
- Requires `Authorization: Bearer <jwt>`.

Response `200 OK`:

```json
{
  "plan_id": "monitor",
  "status": "ACTIVE",
  "billing_period": "MONTHLY",
  "current_period_start": "2026-01-01T00:00:00Z",
  "current_period_end": "2026-02-01T00:00:00Z",
  "grace_until": null
}
```

Notes:
- `plan_id` is enum `plan_id` and `status` is enum `subscription_status` (see `docs/architecture/jila_api_backend_enums_v1.md`).
- `billing_period` is enum `billing_period` (see `docs/architecture/jila_api_backend_enums_v1.md`).
- Period timestamps are server-authored ISO8601 UTC with `Z` suffix.

Errors:
- `401 UNAUTHORIZED`

### 10.2 `PATCH /v1/accounts/{org_principal_id}/subscription`

Change the subscription plan for the referenced account principal.

`org_principal_id`:
- Organization principal: caller must have `OWNER` on that organization.

Auth:
- Requires `Authorization: Bearer <jwt>`.

Request:

```json
{ "plan_id": "pro" }
```

Response `200 OK`:

```json
{ }
```

Errors:
- `401 UNAUTHORIZED`
- `422 VALIDATION_ERROR`

---
