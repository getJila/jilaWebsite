## Jila API Backend – API Contract (v1) (Canonical) — Index

This document is the canonical entry point for the Jila HTTP API contract. To avoid a single growing monolith, the contract is split into focused files under `docs/architecture/api_contract/`.

Single source of truth note (anti-drift):
- The files linked below are the only canonical definition of **HTTP routes** and **HTTP request/response/error shapes**.
- Other docs may describe flows and behavior, but should not restate endpoint contracts verbatim.

Canonical references (do not duplicate here):
- Enum catalog (client-facing, anti-reinvention): `docs/architecture/jila_api_backend_enums_v1.md`
- Data models: `docs/architecture/jila_api_backend_data_models.md`
- Decisions: `docs/architecture/jila_api_backend_decision_register.md`

---

### Contract files (canonical)

- `./api_contract/01_global_conventions.md`: Base URL, auth header conventions, error shape, pagination, timestamps.
- `./api_contract/99_flow_diagrams.md`: Mermaid endpoint flow diagrams (explanatory).
- `./api_contract/02_auth_identity.md`: `/v1/auth/*` + canonical `/v1/me` identity bootstrap shape.
- `./api_contract/03_orgs_sites_portal.md`: Org + site endpoints for the portal surface (non-admin).
  - Includes dashboard rollup bootstrap endpoints:
    - `GET /v1/accounts/{org_principal_id}/dashboard-stats`
    - `GET /v1/accounts/{org_principal_id}/dashboard-snapshot`
- `./api_contract/04_admin_internal_ops.md`: Internal ops (admin) endpoints (account-first) + admin portal notes (non-normative section 2.14).
  - Admin portal convenience endpoints are under `/v1/accounts/{account_id}/*` (see D-066).
  - Includes cross-org aggregate list endpoints: `/v1/internal/reservoirs|sites|devices|orders` (see D-070).
  - Includes single-order admin lookup: `/v1/internal/orders/{order_id}`.
- `./api_contract/05_reservoirs_readings_location.md`: Reservoirs, readings, and location.
- `./api_contract/06_devices_firmware_telemetry.md`: Devices, device config, firmware management, telemetry ingestion notes.
- `./api_contract/07_supply_points.md`: Public supply points discovery.
- `./api_contract/08_marketplace_listings.md`: Seller mode + marketplace listings (including embedded price rules on seller reservoirs list).
- `./api_contract/09_orders_reviews.md`: Orders + reviews.
- `./api_contract/10_subscriptions.md`: Subscriptions.
- `./api_contract/11_alerts.md`: Alerts.
- `./api_contract/12_contract_notes.md`: Short contract notes (keep decisions in decision register).
- `./api_contract/13_analytics.md`: Intelligence layer analytics (stationary + mobile + integrated + exports).
