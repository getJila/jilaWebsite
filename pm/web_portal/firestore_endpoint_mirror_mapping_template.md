## Portal — Endpoint → Firestore Mirror Mapping Template (v1) (AUTHORITATIVE)

Purpose: one-page template the frontend fills in so the backend can implement Firestore mirrors
that match portal API shapes without ambiguity (avoids key/ID mismatch and cache drift).

Canonical references:
- API contract: `docs/architecture/jila_api_backend_api_contract_v1.md` and `docs/architecture/api_contract/*`
- Firestore mirror model: `docs/architecture/jila_api_backend_firestore_mirroring.md`
- Firebase realtime guide: `docs/pm/web_portal/firebase_realtime_mirroring_guide.md`

---

## A) ID glossary (fill once; do not redefine per row)

- **principal_id**: authenticated user principal (Firebase token claim `principal_id`).
- **org_principal_id**: org account principal id from `GET /v1/me` (`org_memberships[*].org_principal_id`).
- **account_id (portal APIs)**: for portal org-scoped flows, `account_id == org_principal_id`.
- **org_id**: organization row id (`organizations.id`) — **never used in Firestore paths**.

---

## B) Mirror strategy (DECIDED for this mapping)

We will implement **per-principal org projections** for portal list surfaces:

- `principals/{principal_id}/orgs/{org_principal_id}/sites/{site_id}`
- `principals/{principal_id}/orgs/{org_principal_id}/reservoirs/{reservoir_id}`
- `principals/{principal_id}/orgs/{org_principal_id}/devices/{device_id}`
- `principals/{principal_id}/orgs/{org_principal_id}/alerts/{alert_id}` (org account feed)

Rationale:
- Security remains principal-scoped (rules enforce `pid == request.auth.token.principal_id`).
- Org switching becomes a path change, not a client-side filtering exercise.
- Cache keys can be keyed by `org_principal_id` (same identifier as API `account_id` for portal flows).

---

## C) Endpoint → Mirror mapping table (fill one row per UI-listener surface)

Guidance:
- For each row, the Firestore document MUST mirror the **API response shape** used by the UI for that surface.
- If Firestore includes additional metadata (recommended), list it under “Mirror metadata fields”.
- Cache keys should be based on **org_principal_id** (the portal `account_id`).

| UI surface name | API endpoint(s) used by UI | API scope key (what is `account_id` here?) | API response shape reference (link + notes) | TanStack Query cache key (exact) | Firestore path (exact) | Doc ID(s) | Listener type (doc / collection / query) | Required fields (mirror = API shape) | Mirror metadata fields (recommended) | Ordering / conflict rule | Update triggers (events / actions) | Reconcile scope name | Notes / edge cases |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Dashboard — Sites list | `GET /v1/accounts/{account_id}/sites` | `account_id == org_principal_id` | `docs/architecture/api_contract/03_orgs_sites_portal.md` §2.4 | `["sites","list",org_principal_id]` | `principals/{principal_id}/orgs/{org_principal_id}/sites/{site_id}` | `site_id` | collection | *(paste exact list item fields)* | `updated_at`, `last_event_seq`, `last_event_type` | prefer `last_event_seq` monotonic | `SITE_*`, access changes | `org_sites` | pagination: API has cursor; Firestore is full set |
| Dashboard — Reservoirs list | `GET /v1/accounts/{account_id}/reservoirs` | `account_id == org_principal_id` | `docs/architecture/api_contract/05_reservoirs_readings_location.md` (list section) | `["reservoirs","list",org_principal_id,<filters>]` | `principals/{principal_id}/orgs/{org_principal_id}/reservoirs/{reservoir_id}` | `reservoir_id` | collection | *(paste exact list item fields)* | `updated_at`, `last_event_seq`, `last_event_type` | prefer `last_event_seq` | `RESERVOIR_*`, device attach/detach | `org_reservoirs` | define filter normalization (no undefined drift) |
| Dashboard — Devices list | `GET /v1/accounts/{account_id}/devices` | `account_id == org_principal_id` | `docs/architecture/api_contract/06_devices_firmware_telemetry.md` §4.3a | `["devices","list",org_principal_id,<filters>]` | `principals/{principal_id}/orgs/{org_principal_id}/devices/{device_id}` | `device_id` | collection | *(paste exact list item fields used by UI)* | `updated_at`, `last_event_seq`, `last_event_type` | prefer `last_event_seq` monotonic | `DEVICE_*`, telemetry-derived fields | `org_devices` | include how filters map to queries (site_id/reservoir_id/status) |
| Alerts — Org feed | `GET /v1/accounts/{account_id}/alerts` | `account_id == org_principal_id` | `docs/architecture/api_contract/11_alerts.md` | `["alerts","list",org_principal_id,<filters>]` | `principals/{principal_id}/orgs/{org_principal_id}/alerts/{alert_id}` | `alert_id` | collection | *(paste exact alert item fields used by UI)* | `last_event_seq`, `last_event_type` | prefer `last_event_seq` | `ALERT_CREATED`, mark-read, auto-resolve | `org_alerts` | decide whether to mirror `stats` or keep stats API-only |

Add rows as needed:
- Site detail, reservoir detail, order status, etc. (only if you expect realtime updates for those screens).

---

## D) “Do not use” paths (to prevent drift)

- **Do not use** Firestore root `accounts/{org_id}/...` for portal mirrors.
  - `org_id` is a DB row id and is not the portal `account_id`.
  - Portal `account_id` is the **org principal id**.

---

## E) Acceptance checklist (backend + frontend)

- [ ] Every UI surface reads from one cache key that is scoped by `org_principal_id`.
- [ ] Firestore listeners write to the same cache key as the API fetch.
- [ ] Mirror doc fields match the API shape used by the UI (no missing fields).
- [ ] Mirror includes ordering metadata (`last_event_seq` preferred).
- [ ] Org switch unsubscribes listeners and prunes/corrects cache for the old org context.
- [ ] Reconcile scopes exist and prune orphan docs after membership revoke/role downgrade.

