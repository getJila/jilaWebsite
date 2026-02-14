## Jila API Backend – API Contract (v1) — Extracted section (Canonical)

This file is part of the canonical HTTP contract. Start from the index: `../jila_api_backend_api_contract_v1.md`.

## 10. Contract notes (kept short; decisions are in the decision register)

1. **SupplyPoint actions route**
   - **DECIDED (D-010)**: status updates use `PATCH /v1/supply-points/{supply_point_id}`; moderation uses explicit endpoints (`/verify`, `/reject`, `/decommission`)

2. **Refresh tokens**
   - **DECIDED (D-005)**: refresh tokens are implemented with rotation + server-side session tracking.
   - Contracts are defined in this document: `POST /v1/auth/refresh` and `POST /v1/auth/logout`.
