## Jila API Backend — Enum Catalog (v1) (Canonical)

Purpose: provide a single, client-facing **inventory** of all enums exposed by the v1 API, with a single
source-of-truth for enum values to prevent drift.

Anti-drift rule (single source of truth):
- This file MUST NOT restate enum value lists that already exist elsewhere.
- Enum values MUST be defined in exactly one canonical place:
  - DB-enforced enums → `docs/architecture/jila_api_backend_data_models.md` (and Postgres migrations).
  - HTTP/derived enums → the relevant `docs/architecture/api_contract/*.md` file.
- When an enum value is added/removed/renamed, update the canonical source above; this file only needs updates
  if the enum is added/removed/renamed at the inventory level.

---

## 0) Legend

- **Backend enum (ENFORCED)**: stored/enforced in Postgres (enum type + constraints).
- **Backend enum (CONTRACT)**: appears in API responses/requests; may be derived rather than stored.
- **UI-only enum (CLIENT)**: not part of backend contract; if stored at all, it is **non-authoritative metadata**.

## 0.1 Canonical enum value sources

- DB enums and DB-enforced “enum-like” constraints: `docs/architecture/jila_api_backend_data_models.md` (section **2. Enums**)
- HTTP contract: `docs/architecture/api_contract/*` (endpoint-specific “allowed values” sections)

---

## 1) Sites

### 1.1 `site_type` (Backend enum — ENFORCED)

Used by:
- `GET /v1/accounts/{account_id}/sites` (`site_type`)
- `GET /v1/sites/{site_id}` (`site_type`)
- `POST /v1/accounts/{account_id}/sites` (optional `site_type`; defaults server-side)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.3.1 `site_type`**

Notes:
- `site_type` is a **classification**, not a “status”.
- This does not imply anything about online/offline; connectivity is modeled at device/reservoir layers.

### 1.2 `site_risk_level` (Backend enum — CONTRACT)

Used by:
- `GET /v1/accounts/{account_id}/sites` (`risk_level`)
- `GET /v1/sites/{site_id}` (`risk_level`)

Canonical values:
- HTTP: `docs/architecture/api_contract/03_orgs_sites_portal.md` (site list/detail risk_level section)

### 1.3 Site “status” (Backend enum — CONTRACT)

Used by:
- `GET /v1/accounts/{account_id}/sites` (`status`)
- `GET /v1/sites/{site_id}` (`status`)

Canonical values:
- HTTP: `docs/architecture/api_contract/03_orgs_sites_portal.md` (site status section)

Notes:
- In v1, sites are not “offline”. Remove/avoid any client-side enum that treats a site as `OFFLINE`.
- “Offline-ness” is expressed via device status and/or reservoir connectivity freshness.

---

## 2) Reservoirs

### 2.1 `monitoring_mode` (Backend enum — ENFORCED)
Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.10 `monitoring_mode`**

Notes:
- Organization-owned reservoirs must be `DEVICE` (see Decision D-038).

### 2.2 `connectivity_state` (Backend enum — CONTRACT)

Used by:
- `GET /v1/accounts/{account_id}/reservoirs` (`connectivity_state`)

Canonical values:
- HTTP: `docs/architecture/api_contract/05_reservoirs_readings_location.md` (connectivity_state section)

### 2.3 `level_state` (Backend enum — CONTRACT)

Used by:
- `GET /v1/accounts/{account_id}/reservoirs` and `GET /v1/reservoirs/{reservoir_id}` (`level_state`)

Canonical values:
- HTTP: `docs/architecture/api_contract/05_reservoirs_readings_location.md` (level_state section)

### 2.4 `reservoir_type` (Backend enum — ENFORCED)

Used by:
- `POST /v1/reservoirs` (`reservoir_type`)
- `GET /v1/reservoirs/{reservoir_id}` (`reservoir_type`)
- `GET /v1/accounts/{account_id}/reservoirs` (`reservoir_type`)
Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.8 `reservoir_type`**

### 2.5 `reservoir_mobility` (Backend enum — ENFORCED)

Used by:
- `POST /v1/reservoirs` (`mobility`)
- `GET /v1/reservoirs/{reservoir_id}` (`mobility`)
- `GET /v1/accounts/{account_id}/reservoirs` (`mobility`)
Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.9 `reservoir_mobility`**

### 2.6 `reading_source` (Backend enum — ENFORCED)

Used by:
- `GET /v1/accounts/{account_id}/reservoirs` (`latest_reading.source`)
- `GET /v1/reservoirs/{reservoir_id}/readings` (`items[].source`)
Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.14 `reading_source`**

---

## 3) Devices

### 3.1 `device_type` (Backend enum — ENFORCED)

Used by:
- `GET /v1/accounts/{account_id}/devices` (`device_type`)
- `GET /v1/accounts/{account_id}/devices/{device_id}` (`device_type`)
- `POST /v1/internal/devices/{device_id}/register` (optional `device_type`; defaults server-side)
Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.13.1 `device_type`**

Notes:
- UI may display richer labels; backend only guarantees these stable codes.

### 3.2 Portal device “status” (Backend enum — CONTRACT)

Used by:
- `GET /v1/accounts/{account_id}/devices` (`status`)
- `GET /v1/accounts/{account_id}/devices/{device_id}` (`status`)
Canonical values:
- HTTP: `docs/architecture/api_contract/06_devices_firmware_telemetry.md` (portal device status section)

---

## 4) Alerts

### 4.1 `alert_severity` (Backend enum — CONTRACT)

Canonical values:
- HTTP: `docs/architecture/api_contract/11_alerts.md` (severity section)

Notes:
- “Resolved” is not a severity. Resolution is a lifecycle state (alerts feed returns active alerts only in v1).

### 4.2 `context_type` (Backend enum — CONTRACT)

Canonical values:
- HTTP: `docs/architecture/api_contract/11_alerts.md` (context_type section)

---

## 5) Identity & Access

### 5.1 `org_role` (Backend enum — CONTRACT)

Used by:
- `GET /v1/accounts/{account_id}/members` (`role`)

Canonical values:
- HTTP: `docs/architecture/api_contract/03_orgs_sites_portal.md` (org member role section)

Notes:
- Client role labels like `admin/site_manager/technician` must not be treated as backend roles in v1.

### 5.2 `user_status` (Backend enum — ENFORCED)

Used by:
- `GET /v1/me` (`user.status`)
- `GET /v1/accounts/{account_id}/members` (`status`)
- Admin user management endpoints under `/v1/internal/users/*`

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.1 `user_status`**

Notes:
- `LOCKED|DISABLED` are the two “explicit deny” states; login returns `403 ACCOUNT_DISABLED` for locked/disabled per contract rules.

## 6) Admin + provisioning

### 6.1 `device_inventory_provisioning_status` (Backend enum — CONTRACT)

Used by:
- `POST /v1/internal/device-inventory/units/{device_id}`
- `GET /v1/internal/device-inventory/units`
- `GET /v1/internal/device-inventory/units/{device_id}`

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → inventory provisioning_status note (or migration check constraint)
- HTTP: `docs/architecture/api_contract/04_admin_internal_ops.md` (device-inventory endpoints)

### 6.2 `organization_status` (Backend enum — CONTRACT)

Used by:
- `GET /v1/internal/orgs` (`status`)

Canonical values:
- HTTP: `docs/architecture/api_contract/04_admin_internal_ops.md` (org status section)

Notes:
- In v1 this is stored as text (recommended enum later); treat values as contract-stable for admin tooling.

---

## 6.3 Subscriptions & billing

### 6.3.1 `billing_period` (Backend enum — CONTRACT)

Used by:
- `POST /v1/accounts` (`subscription.billing_period`)
- `POST /v1/internal/billing/payments` (`billing_period`)
- `GET /v1/internal/orgs` (`subscription.billing_period`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.24.1 `billing_period`**

### 6.3.2 `subscription_payment_attempt_status` (Backend enum — CONTRACT)

Used by:
- Manual payment records (auditable renewal entries; provider callbacks later)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.24.2 `subscription_payment_attempt_status`**

Notes:
- Future provider integration may add `PENDING|FAILED`, but v1 manual flow uses the minimal set above.

### 6.3.3 `plan_id` (Backend enum — ENFORCED)

Used by:
- `GET /v1/me` (`subscription.plan_id`, `org_memberships[].subscription.plan_id`)
- `GET /v1/accounts/{account_id}/subscription` (`plan_id`)
- `POST /v1/accounts` (`subscription.plan_id`)
- `GET /v1/internal/orgs` (`subscription.plan_id`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.25 `plan_id`**

Notes:
- Org subscriptions must be `protect|pro` (never `monitor`) per the onboarding contract rules.

### 6.3.4 `subscription_status` (Backend enum — ENFORCED)

Used by:
- `GET /v1/me` (`subscription.status`, `org_memberships[].subscription.status`)
- `GET /v1/accounts/{account_id}/subscription` (`status`)
- `GET /v1/internal/orgs` (`subscription.status`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.24 `subscription_status`**

---

## 7) SupplyPoints

### 7.1 `supply_point_kind` (Backend enum — ENFORCED)

Used by:
- `GET /v1/supply-points` (`kind`)
- `POST /v1/supply-points` (`kind`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.15 `supply_point_kind`**

### 7.2 `supply_point_verification_status` (Backend enum — ENFORCED)

Used by:
- `GET /v1/supply-points` (`verification_status`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.17 `supply_point_verification_status`**

### 7.3 `supply_point_operational_status` (Backend enum — ENFORCED)

Used by:
- `GET /v1/supply-points` (`operational_status`)
- `PATCH /v1/supply-points/{supply_point_id}` (`operational_status`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.18 `supply_point_operational_status`**

### 7.4 `supply_point_availability_status` (Backend enum — ENFORCED)

Used by:
- `GET /v1/supply-points` (`availability_status`)
- `PATCH /v1/supply-points/{supply_point_id}` (`availability_status`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.19 `supply_point_availability_status`**

### 7.5 `evidence_type` (Backend enum — ENFORCED)

Used by:
- `PATCH /v1/supply-points/{supply_point_id}` (`availability_evidence_type`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.16 `evidence_type`**

### 7.6 `supply_point_enrichment_asset_status` (Backend enum — ENFORCED)

Used by:
- `GET /v1/supply-points` (`items[].enrichment.asset_status`)
- `GET /v1/supply-points/{supply_point_id}` (`enrichment.asset_status`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.31 `supply_point_enrichment_asset_status`**

### 7.7 `supply_point_enrichment_operational_condition` (Backend enum — ENFORCED)

Used by:
- `GET /v1/supply-points` (`items[].enrichment.operational_condition`)
- `GET /v1/supply-points/{supply_point_id}` (`enrichment.operational_condition`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.32 `supply_point_enrichment_operational_condition`**

### 7.8 `supply_point_enrichment_availability_bucket` (Backend enum — ENFORCED)

Used by:
- `GET /v1/supply-points` (`items[].enrichment.availability_bucket`)
- `GET /v1/supply-points/{supply_point_id}` (`enrichment.availability_bucket`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.39 `supply_point_enrichment_availability_bucket`**

### 7.9 `supply_point_enrichment_paid_free_sometimes_unknown` (Backend enum — ENFORCED)

Used by:
- `GET /v1/supply-points` (`items[].enrichment.payment_model`)
- `GET /v1/supply-points/{supply_point_id}` (`enrichment.payment_model`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.34 `supply_point_enrichment_paid_free_sometimes_unknown`**

---

## 8) Orders & marketplace

### 8.1 `order_status` (Backend enum — ENFORCED)

Used by:
- `POST /v1/accounts/{account_id}/orders` and `GET /v1/accounts/{account_id}/orders/{order_id}` (`status`)
- `GET /v1/accounts/{account_id}/orders` (`status`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.20 `order_status`**

### 8.2 `seller_availability_status` (Backend enum — ENFORCED)

Used by:
- `PATCH /v1/reservoirs/{reservoir_id}` (`seller_availability_status`)
- `GET /v1/accounts/{account_id}/seller/reservoirs` (`seller_availability_status`)
- `PATCH /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}` (`seller_availability_status`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.12 `seller_availability_status`**

### 8.3 `seller_profile_status` (Backend enum — ENFORCED)

Used by:
- `POST /v1/accounts/{account_id}/seller-profile` and `PATCH /v1/accounts/{account_id}/seller-profile` (`status`)

Canonical values:
- DB: `docs/architecture/jila_api_backend_data_models.md` → **2.21 `seller_profile_status`**

### 8.4 `requested_fill_mode` (Backend enum — CONTRACT)

Used by:
- `POST /v1/accounts/{account_id}/orders` (`requested_fill_mode`)
Canonical values:
- HTTP: `docs/architecture/api_contract/09_orders_reviews.md` (requested_fill_mode section)

---

## 9) Error codes

### 9.1 `error_code` (Backend enum — CONTRACT)

Used by:
- Every endpoint error response (`error_code` in standard error envelope)

Canonical values:
- Code: `app/common/errors.py` (`ErrorCode`)
- HTTP: `docs/architecture/api_contract/01_global_conventions.md` (error shape + status mapping)

---

## 10) UI-only enums and metadata storage (non-authoritative)

These enums are commonly present in portal UI code but are **not** part of the v1 backend contract. To avoid
breaking changes when we later introduce first-class endpoints, we reserve stable metadata keys.

Important:
- These metadata values are **non-authoritative**; they must never be used for permissions/RBAC or billing/entitlements.
- Unless an explicit endpoint exists, clients should treat these as **UI-local** and not assume persistence.

### 10.1 Organization preferences (suggested metadata keys; UI-only)

Table: `organizations.metadata` (JSONB; non-authoritative)
- `units_preference`: `METRIC|IMPERIAL`
- `industry`: `WATER_INFRASTRUCTURE|AGRICULTURE|MINING|MUNICIPAL|OTHER`
- `timezone_preference`: IANA TZ string (e.g., `Africa/Luanda`)

### 10.2 UI theme (client-only)

- `theme_preference`: `LIGHT|DARK|SYSTEM`
- Stored client-side only (not a backend concern in v1).

### 10.3 Language codes (mapping note)

Backend field: `users.preferred_language` (v1 codes: `en|pt`)
- Portal UI may use locale codes (`en-US`, `pt-AO`); clients must map these to v1 language codes.
