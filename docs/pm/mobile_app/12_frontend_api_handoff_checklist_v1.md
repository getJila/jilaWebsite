---
title: Jila Mobile App — Frontend ↔ API Handoff Checklist (v1)
status: Draft (anti-drift)
last_updated: 2025-12-22
---

## Purpose
Provide a single, practical checklist for the **frontend team** to implement screens against the **canonical backend API contract** without inventing fields or drifting on error/offline semantics.

This document **does not restate** full request/response schemas. For exact payloads and error codes, always consult:
- `docs/architecture/jila_api_backend_api_contract_v1.md`

Related mobile canon:
- Screen inventory: `./11_screen_inventory.md`
- Product decisions: `../../decision_registers/mobile_app_decision_register.md`
- Offline baseline: `./07_offline_mode_and_sync_specification.md`
- Notifications/push contract: `./08_notification_and_alert_strategy.md`
- UX patterns: `docs/design/jila_design_decision_register.md` + `docs/ux/jila_design_guide.md`

## Global implementation rules (v1)
- **Auth**: Most endpoints require `Authorization: Bearer <jwt>`; only explicitly marked routes are public.
- **Idempotency**: `POST /v1/accounts/{account_id}/orders` supports `Idempotency-Key` and deterministic `409 IDEMPOTENCY_KEY_CONFLICT` on payload mismatch.
- **Timestamps**: server-generated timestamps are UTC with `Z` suffix.
- **Offline**:
  - Reads: cache-first; show freshness (“Last updated”) and ghost states where needed (MA-005).
  - Writes: only queue writes explicitly allowed by `07_offline_mode_and_sync_specification.md`.
- **Errors**: show standard error shape; map `422` to field errors when possible; keep deterministic `409` messages clear.
- **Push deep links**: only `AlertsInbox`, `OrderDetail`, `ReservoirDetail` are valid push ScreenIds in v1.

---

## Screen-by-screen checklist (v1)

### ChoosePath (unauthenticated entry)
- **API**: none required.
- **Notes**: routes into public Map discovery or auth-required flows.

### AuthRegister / AuthLogin / AuthVerify
- **API**: `/v1/auth/*` per contract.
- **FE must handle**:
  - Anti-enumeration semantics (e.g., password reset always 200).
  - `401 INVALID_CREDENTIALS` vs `403 ACCOUNT_DISABLED` vs `422 INVALID_USERNAME_FORMAT`.
- **Offline**: not queueable; must require connectivity.

### Home / ReservoirList (authenticated)
- **API**: `GET /v1/me/reservoirs`
- **UI requires (minimum fields)**:
  - `capacity_liters`, `monitoring_mode`
  - `latest_reading.level_pct`, `latest_reading.recorded_at`, `latest_reading.source`
- **Offline**: must render from cache with “Last updated” and Ghost rules (MA-005 / UX-D-036).

### ReservoirDetail
- **API**:
  - `GET /v1/reservoirs/{reservoir_id}`
  - (optional) `GET /v1/reservoirs/{reservoir_id}/readings` for history
- **UI requires**:
  - `latest_reading.level_pct`, `latest_reading.volume_liters`, `latest_reading.recorded_at`, `latest_reading.source`
  - `capacity_liters`, `safety_margin_pct` (if used in UI computation)
  - `level_state` + `level_state_updated_at` when present
- **Offline**: Ghost + timestamp anchor + explicit Refresh control.
- **Notes**:
  - “Days remaining” is client-derived; treat as approximation (contract explicitly notes no dedicated v1 endpoint for `site_consumption_profiles`).

### ReservoirUpdateLevel (manual reading)
- **API**: `POST /v1/reservoirs/{reservoir_id}/manual-reading`
- **Offline**: queueable (per offline baseline). Must show `Saved offline → Pending sync → Synced/Failed`.
- **Error handling**: show `422` validation issues; deterministic conflicts as `409` if applicable.

### OrdersList (My orders entrypoint from Marketplace)
- **API**: `GET /v1/accounts/{account_id}/orders` (support `view`, pagination cursor)
- **Offline**: cached list/detail must remain useful with freshness shown.

### OrderCreate / OrderConfirm (buyer)
- **API**:
  - Public discovery: `GET /v1/marketplace/reservoir-listings` (public, no JWT)
  - Create: `POST /v1/accounts/{account_id}/orders` (auth required; supports `Idempotency-Key`)
- **FE must ensure**:
  - Client submits liters: `requested_fill_mode = VOLUME_LITERS` with `requested_volume_liters` (days-of-autonomy is UI-only).
  - Total cost is shown before final confirm (Journey 3 guardrail).
  - **Order destination**: client submits `target_reservoir_id` (contract field). Backend may return `403 FORBIDDEN`
    if the user is authenticated but lacks ordering rights for that reservoir.
- **Offline**: order creation requires connectivity; do not queue.
- **Common errors**:
  - `422 NO_PRICE_RULE_MATCH`
  - `409 IDEMPOTENCY_KEY_CONFLICT`

### OrderDetail
- **API**:
  - `GET /v1/accounts/{account_id}/orders/{order_id}`
  - State transitions: `POST /v1/accounts/{account_id}/orders/{order_id}/accept|reject|cancel|confirm-delivery|dispute` and `POST /v1/accounts/{account_id}/orders/{order_id}/reviews` as applicable
- **Offline**:
  - Reads cached; actions that change order state require connectivity (except delivery confirmation timestamp may be client-asserted per contract).
- **Trust UI note**:
  - Driver identity card is shown only if the API provides assignment fields; otherwise show seller identity as the accountable party (design guide “Delivery identity fallback”).

### AlertsInbox
- **API**:
  - `GET /v1/accounts/{account_id}/alerts`
  - `POST /v1/accounts/{account_id}/alerts/{alert_id}/mark-read`
- **Push**: only valid push landing screen besides OrderDetail/ReservoirDetail.
- **Notes**:
  - `message_key` + `message_args` are canonical; the feed includes `rendered_title/rendered_message` and portal-triage fields
    (severity/context/source labels, optional snapshot) which mobile can ignore (backend decisions D-030/D-031).

### NotificationPreferences (Profile)
- **API**:
  - `GET /v1/accounts/{account_id}/notification-preferences`
  - `PATCH /v1/accounts/{account_id}/notification-preferences`
  - `POST /v1/accounts/{account_id}/push-tokens` (register device token)
  - `DELETE /v1/accounts/{account_id}/push-tokens/{push_token_id}` (disable)
- **Offline**: preference updates may be queueable only if explicitly allowed (see offline baseline); otherwise require connectivity.

### SupplyPointsMap / SupplyPointDetail (public discovery)
- **API**: `GET /v1/supply-points` (public)
- **FE must handle**:
  - `verification_status` flags (PENDING_REVIEW must be clearly labeled)
  - `within_radius_km (optional)` cap (10km) → `422 VALIDATION_ERROR`
- **Offline**: cache map/list and show freshness.

### SupplyPointStatusUpdate (authenticated action surface)
- **API**: `PATCH /v1/supply-points/{supply_point_id}` (status update; partial)
- **Offline**: queueable per offline baseline, but may be rejected; surface rejection explicitly.

### Profile (basic)
- **API**:
  - `GET /v1/me`
  - `GET /v1/me/profile` + `PATCH /v1/me/profile`
  - `GET /v1/accounts/{account_id}/subscription` (feature gating surfaces)

### SellerSetup / SellerAvailability / SellerPricing
- **API**:
- `POST /v1/accounts/{account_id}/seller-profile` (create/update/read current profile)
- `GET /v1/accounts/{account_id}/seller/reservoirs`
- `PATCH /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}` (availability)
- `POST /v1/accounts/{account_id}/seller/reservoirs/{reservoir_id}/price-rules`
- **Offline**: seller availability/pricing changes require connectivity (offline baseline).

---

## Known v1 gaps (do not invent)
- **Driver identity / dispatch**: not guaranteed by v1 contract; use seller identity fallback unless API adds explicit fields.
- **Consumption profile inputs (`site_consumption_profiles`)**: referenced in value prop and contract notes but not exposed by a dedicated v1 endpoint; keep autonomy estimates client-side.
