## Jila API Backend — v1 API Reference (Single Entry Point)

Purpose: this document is the **single entry point** for engineers/QA/frontend to find:
- The canonical **HTTP contract** (routes + request/response/error shapes)
- The canonical **global conventions** (auth, error envelope, pagination)
- The canonical **enum inventory**

Anti-drift rules:
- This file is an **index only**. It must not restate request/response JSON shapes, error envelopes, or error code lists.
- Canonical HTTP contract entry point:
  - `docs/architecture/jila_api_backend_api_contract_v1.md`
- Canonical contract files (domain-focused):
  - `docs/architecture/api_contract/*`
- Canonical enum inventory:
  - `docs/architecture/jila_api_backend_enums_v1.md`
- Canonical decisions (rationale; do not restate here):
  - `docs/architecture/jila_api_backend_decision_register.md`

---

## Quick links (canonical)

- **Contract index**: `docs/architecture/jila_api_backend_api_contract_v1.md`
- **Global conventions** (auth header, error shape, pagination, timestamps): `docs/architecture/api_contract/01_global_conventions.md`
- **Flow diagrams (explanatory)**: `docs/architecture/api_contract/99_flow_diagrams.md`

Domain contract files:
- **Auth & identity**: `docs/architecture/api_contract/02_auth_identity.md`
- **Orgs + sites (portal)**: `docs/architecture/api_contract/03_orgs_sites_portal.md`
- **Admin (internal ops)**: `docs/architecture/api_contract/04_admin_internal_ops.md`
- **Reservoirs, readings, location**: `docs/architecture/api_contract/05_reservoirs_readings_location.md`
- **Devices + firmware + telemetry notes**: `docs/architecture/api_contract/06_devices_firmware_telemetry.md`
- **Supply points**: `docs/architecture/api_contract/07_supply_points.md`
- **Marketplace listings**: `docs/architecture/api_contract/08_marketplace_listings.md`
- **Orders + reviews**: `docs/architecture/api_contract/09_orders_reviews.md`
- **Subscriptions**: `docs/architecture/api_contract/10_subscriptions.md`
- **Alerts**: `docs/architecture/api_contract/11_alerts.md`
- **Contract notes**: `docs/architecture/api_contract/12_contract_notes.md`

---

## How to find an endpoint quickly

- Search in `docs/architecture/api_contract/` for the literal string (example): `GET /v1/me`
- The endpoint will be defined exactly once in the domain file (request/response/error shapes).
