## Jila API Backend – State + History Patterns (Best Practices) (v0.1)

This document defines **how we store “latest/current” state and “historical” records** without drift, across all modules.

It is a companion to:
- `docs/architecture/jila_api_backend_architecture_v_0 (3).md`
- `docs/architecture/jila_api_backend_data_models.md`

---

## 1. The core pattern (recommended default)

For most domain concepts we maintain **two representations**:

1) **Current state (canonical for reads)**  
   Stored on the entity table itself (fast to query and filter).

2) **History (append-only log of changes)**  
   Stored as immutable records that can be audited, replayed, and aggregated.

In Jila, the default “history” primitive is:
- **`events`** (transactional outbox + audit stream), with a versioned payload contract.

Decision note:
- The canonical “current vs audit vs analytics” structure is locked in decision **D-017** (hybrid: current on entity tables + centralized `events` + typed history where needed).

Narrative explanation:
When a device sends telemetry, we store the “latest” values that the UI needs (for example the most recent level and battery) in fast-to-read places, and we store the full historical trail in append-only tables so that we can audit what happened later. The centralized `events` table is not meant to replace time-series storage; it exists to record that “something happened” in a stable, replayable way so downstream consumers (Firestore mirroring, alerts, exports) can react reliably without each module inventing its own integration mechanism.

Infrastructure note (telemetry ingress):
Device telemetry arrives through an Azure-managed ingestion pipeline (MQTT broker → Event Hubs). Event Hubs delivery can be at-least-once and may replay messages. For correctness, we rely on the idempotency rules locked in **D-007**, and we rely on `events.seq` for downstream ordering (per **D-009**), not on upstream offsets.

Single source of truth note (anti-drift):
- This file is the canonical home for **event/outbox mechanics** and the **stable event payload envelope** used in `events.data`.
- Other docs may reference this contract, but should not restate it verbatim.

---

## 2. Decision matrix: `events` vs history table vs derived snapshots

Use this decision matrix when adding “history”:

### 2.1 Use `events` (preferred) when
- It’s “**something that happened**” (a state transition, an update, a submission).
- You need auditability and replay, but **not** heavy relational querying across history.
- The payload can be stable and versioned.

Examples:
- SupplyPoint status updates (`SUPPLY_POINT_STATUS_UPDATED`)
- Order lifecycle transitions (`ORDER_*`)
- Reservoir location update (`RESERVOIR_LOCATION_UPDATED`)

### 2.2 Use a dedicated history table when
- You need to query history **relationally at scale** (time-series queries, analytics joins).
- The history records are high-volume and need efficient indexing and retention policies.
- You need strong typing at the DB level (not JSON payloads) for performance and correctness.

Examples:
- `reservoir_readings` (time series)

Guideline:
- Even when using a history table, still emit an `events` row for cross-module integration and audit.

### 2.3 Use derived snapshots / cached “latest” columns when
- The latest value is requested constantly and computing it from history is expensive.
- You can define a **single source of truth** and **invalidations/update rules**.

Implementation options:
- Maintain `last_*` columns on the entity table (write-through in the same transaction).
- Use a materialized view refreshed by worker (eventually consistent).

---

## 3. Best practices for “current state” fields

### 3.1 Store current state on the entity table (and treat it as authoritative)
Examples in our model:
- `supply_points.operational_status`, `availability_status`, and their `*_updated_at` / `availability_evidence_type`
- `reservoirs.location`, `location_updated_at`
- `devices.last_seen_at`, `last_battery_pct`
- `orders.status` and lifecycle timestamps (`accepted_at`, `delivered_at`, etc.)

### 3.2 Use explicit conflict-resolution rules when multiple actors can update
Example: SupplyPoint status updates
- Evidence priority: `SENSOR_DERIVED` > `VERIFIED` > `REPORTED`
- Same evidence: newest `availability_updated_at` wins

Why:
- Avoids “last writer wins” corruption when trusted and untrusted updates compete.

### 3.3 Keep history immutable
- Never update “history rows” in place; append new records.
- If you need to correct, append a correction record with a clear reason.

---

## 4. Best practices for history storage

### 4.1 Append-only time series table pattern (for telemetry/readings)
Use:
- a monotonically increasing PK (`bigint` identity)
- indexed event time: `(entity_id, recorded_at desc)`
- uniqueness for idempotency (v1; see decision D-007):
  - `device_telemetry_messages`: `unique (mqtt_client_id, seq)`
  - `reservoir_readings`: `unique (device_id, device_seq)` for `source = DEVICE`

Also decide early:
- retention policy (days to keep raw)
- downsampling strategy (if needed)

Analytics retention policy (post-v1 intelligence layer):
- Keep `device_telemetry_messages` as the canonical raw telemetry flight recorder per existing policy.
- Keep `device_location_points` for short-horizon movement reconstruction (default target: 90 days in operational environments).
- Keep derived analytics read models (`mobile_stop_episodes`, `mobile_places`, `*_metrics_windows`) for longer historical reporting needs.
- Any retention compaction must preserve reproducibility requirements (`inputs_version`, `metric_version`) for published windows.

### 4.2 State machine entities (orders)
Store:
- current state on the main row
- strict conditional updates for transitions
- emit an event for each valid transition

Why:
- protects against races under retries
- yields an auditable transition trail

### 4.3 “Slow-changing” attributes
If an attribute changes rarely but you still want history:
- Prefer emitting `events` with the changed fields
- Only promote to a typed history table if you must query those changes frequently.

---

## 5. Canonical choices for Jila v1 (by entity/table)

### 5.1 SupplyPoints
- **Current**: `supply_points.operational_status*` and `supply_points.availability_status*` columns
- **History**: `events` (`SUPPLY_POINT_STATUS_UPDATED`)
- **No dedicated history table** in v1 (anti-drift)

#### Event: `SUPPLY_POINT_STATUS_UPDATED` (v1)
Subject:
- `subject_type = "SUPPLY_POINT"`
- `subject_id = supply_points.id`

Envelope:
- Uses the standard `events.data` envelope (D-008), with `event_version = 1`.

Payload (`events.data.payload`, `event_version = 1`):

```json
{
  "supply_point_id": "uuid",
  "operational_status": "ACTIVE|INACTIVE|UNKNOWN",
  "availability_status": "AVAILABLE|LOW|NONE|CLOSED|UNKNOWN",
  "availability_evidence_type": "REPORTED|VERIFIED|SENSOR_DERIVED",
  "attributes": {}
}
```

Notes:
- The API is **partial-update friendly** (D-010): omit fields that were not updated.
- Availability is conflict-resolved by evidence priority (SENSOR_DERIVED > VERIFIED > REPORTED).

### 5.2 Reservoir readings (manual + device)
- **Current**: derived at read-time (“latest reading” via index) OR optionally cached later
- **History**: `reservoir_readings` (typed time series)
- **Also emit**: `events` (`RESERVOIR_LEVEL_READING`) for audit/integration

Reservoir geometry + capacity (v1 guidance):
- **Current**: `reservoirs.capacity_liters` (single canonical value), plus optional `geometry_shape`/`geometry_params`
- **History**: `events`
  - `RESERVOIR_GEOMETRY_UPDATED` (when dimensions/shape are changed or inferred)
  - `RESERVOIR_CAPACITY_UPDATED` (when `capacity_liters` changes; include `capacity_source`)

Why:
- Clients often misreport capacity; we accept `capacity_reported_liters` but keep one authoritative `capacity_liters` for computations.
- Shape-specific dimensions are modeled as one discriminator + JSON params (validated in the API), avoiding schema branching.

### 5.3 Orders
- **Current**: `orders` row (`status` + lifecycle timestamps)
- **History**: `events` (`ORDER_CREATED`, `ORDER_ACCEPTED`, etc.)
- Optional later: a typed transition table only if analytics requires it (not v1)

#### Event: `SELLER_PROFILE_CREATED` / `SELLER_PROFILE_UPDATED` (v1)
Subject:
- `subject_type = "ACCOUNT"`
- `subject_id = seller_profiles.principal_id`

Payload (`event_version = 1`):
- `principal_id` (uuid)
- `status` (`ACTIVE|INACTIVE`)

#### Event: `SELLER_RESERVOIR_UPDATED` (v1)
Subject:
- `subject_type = "RESERVOIR"`
- `subject_id = reservoirs.id`

Payload (`event_version = 1`):
- `reservoir_id` (uuid)
- `seller_availability_status` (`AVAILABLE|UNAVAILABLE|UNKNOWN`)

#### Event: `PRICE_RULE_CREATED` (v1)
Subject:
- `subject_type = "RESERVOIR"`
- `subject_id = reservoirs.id`

Payload (`event_version = 1`):
- `price_rule_id` (uuid)
- `reservoir_id` (uuid)
- `currency` (char(3))
- `min_volume_liters` (numeric)
- `max_volume_liters` (numeric)
- `base_price_per_liter` (numeric)
- `delivery_fee_flat` (numeric|null)

### 5.4 Devices
- **Current**: `devices.last_seen_at`, `last_battery_pct`, `status`
- **History**: `events` for important state changes; raw telemetry history belongs to `reservoir_readings`

### 5.6 Device configuration + firmware (device-connected reservoirs)

#### Device configuration
- **Current desired state**: `device_config_desired` (1 row per device **and config type**)
- **Current applied state**: `device_config_applied` (1 row per device **and config type**)
- **History**: `events`
  - `DEVICE_CONFIG_UPDATED` (when desired config changes)
  - `DEVICE_CONFIG_APPLIED` (when device reports applying a config version)
  - `DEVICE_SEEN` (throttled: emitted when any MQTT message from device is observed, if previous last_seen_at was >=60s ago; triggers config retry publish)

Why:
- Config schema is explicit and type-safe via structured typed columns (no JSONB config blob in canonical tables).
- Desired/applied split avoids ambiguity and makes “eventually applied” behavior explicit.

#### Firmware updates
- **Current**: `devices.firmware_version`
- **History / tracking**:
  - `firmware_releases` (immutable release metadata)
  - `firmware_update_jobs` (per-device state machine)
  - `events` for audit (`FIRMWARE_UPDATE_AVAILABLE`, `FIRMWARE_UPDATE_APPLIED`, etc.)

#### Raw device telemetry payloads
- **History**: `device_telemetry_messages` (append-only JSON payloads)
- **Derived typed history**: `reservoir_readings` (time series for reservoir level + battery %, etc.)

### 5.5 Auth / security events
- **Current**: `users` + `tokens` + `access_grants`
- **History**: `events` for security-relevant actions (invites sent/accepted, password reset completed, etc.)

#### Event: `ORG_INVITE_SENT` (v1)
Subject:
- `subject_type = "ORG"`
- `subject_id = organizations.id`

Payload (`event_version = 1`):
- `org_id` (uuid)
- `invite_token_id` (uuid)
- `target_email` (string)
- `proposed_role` (`OWNER|MANAGER|VIEWER`)
- `site_ids` (array of uuid; optional/empty)
- `expires_at` (ISO8601 UTC)

#### Event: `ORG_INVITE_EMAIL_SENT` (v1)
Subject:
- `subject_type = "ORG"`
- `subject_id = organizations.id`

Payload (`event_version = 1`):
- `invite_token_id` (uuid)
- `channel` (`EMAIL`)
- `attempt_count` (int)

#### Event: `ORG_INVITE_EMAIL_FAILED` (v1)
Subject:
- `subject_type = "ORG"`
- `subject_id = organizations.id`

Payload (`event_version = 1`):
- `invite_token_id` (uuid)
- `channel` (`EMAIL`)
- `attempt_count` (int)
- `error_code` (string)

#### Event: `ORG_INVITE_ACCEPTED` (v1)
Subject:
- `subject_type = "ORG"`
- `subject_id = organizations.id`

Payload (`event_version = 1`):
- `org_id` (uuid)
- `org_principal_id` (uuid)  # the organization's principal id (container principal)
- `user_id` (uuid)
- `status` (`PENDING_VERIFICATION|ACTIVE`)
- `otp_sent_via` (`EMAIL|SMS|null`)
- `subject_principal_id` (uuid)  # the invited user's principal id
- `role` (`OWNER|MANAGER|VIEWER`)
- `site_ids` (array of uuid; may be empty)

---

## 6. Operational guidance (how to implement safely)

### 6.1 “Write state first, then emit event”
Within a DB transaction:
1. write/update the canonical row(s)
2. insert exactly one `events` row describing what happened (versioned payload)

### 6.2 Keep payloads stable and versioned
All derived/event payloads should include:
- `event_version`
- primary IDs (`reservoir_id`, `site_id`, `zone_id` where relevant)
- minimal details needed to understand the event

### 6.2.1 Canonical event payload envelope (`events.data`)
All events stored in `events.data` must follow a stable, versioned envelope. Not all events relate to a reservoir/site/zone, so context fields must be treated as optional and event-specific.

```json
{
  "event_version": 1,
  "payload": {}
}
```

Notes:
- `event_version` is required and controls the payload schema for the given `events.type`.
- `payload` is event-type-specific and must be versioned via `event_version`.
- Keep the envelope stable; only evolve it with explicit version bumps.
- Event producers may include additional **optional** top-level context fields when they materially help consumers (for example mirroring/analytics/alerts):
  - `reservoir_id` (uuid)
  - `site_id` (uuid|null)
  - `zone_id` (uuid|null)
  - `source` (`DEVICE|MANUAL|MIXED`)
  - These context fields are **not** required for all event types; per-event payload schemas below define what is required.

### 6.3 Don’t over-normalize early
If you can answer product questions from:
- canonical state tables + `reservoir_readings` + `events`
then do not add extra history tables in v1.

### 6.4 “Outbox” mechanics (make `events` consumable)
When we refer to `events` as a “transactional outbox”, we mean:
- The `events` row is inserted **in the same DB transaction** as the canonical state write(s).
- Background consumers read events in a **stable order** and checkpoint progress so they can retry safely.

Canonical implementation choice (v1):
- Add an ordered, monotonic sequence column on `events` (e.g. `events.seq bigint identity`) used for consumption order.
- Track consumer progress in a small checkpoint table (e.g. `event_consumers(consumer_name, last_seq, updated_at)`).

Consumer rules:
- Consumers must be **idempotent** (replaying an event must not corrupt mirrors/side effects).
- Consumers should checkpoint **after** successful handling of an event.
- Do not rely on `created_at` ordering for correctness (clock skew and ties); use `events.seq`.

#### 6.4.1 Consumer wakeups (v1 low-usage optimization): Postgres `LISTEN/NOTIFY` + fallback
To reduce idle polling (and therefore connection pressure) in low-usage environments, v1 uses Postgres
as a **best-effort wakeup signal** for outbox consumers:

- **On event emission (producer path)**:
  - When the service inserts an `events` row (as part of the same transaction as the state write),
    it also issues `NOTIFY <channel>`.
  - Postgres delivers notifications to listeners **only after commit**, so consumers will never
    wake on uncommitted events.

- **On consumption (worker path)**:
  - The worker holds a single dedicated connection that runs `LISTEN <channel>` and blocks waiting
    for notifications.
  - On wake, it **drains** outbox consumers by reading `events` (`seq > last_seq`) until no more
    work is reported (bounded to avoid infinite loops under pathological backlogs).

Correctness note (non-negotiable):
- `NOTIFY` is not a durable queue. Notifications may be missed during reconnects. Therefore,
  the worker must also perform a **periodic fallback wake** that re-checks the outbox and drains
  consumers to guarantee progress.

Operational/observability note:
- Ensure DB connections set `application_name` so `pg_stat_activity` can attribute connection usage
  to `api`, `worker`, `telemetry`, and the outbox listener.

Configuration (runtime knobs; environment-driven):
- `WORKER_OUTBOX_NOTIFY_CHANNEL` (default `jila_events_ready`)
- `WORKER_OUTBOX_USE_LISTEN_NOTIFY` (default `true`)
- `WORKER_OUTBOX_FALLBACK_WAKE_SECONDS` (default `60`)
- `WORKER_OUTBOX_DRAIN_MAX_ROUNDS` (default `25`)

Downstream impacts (operational):
- **One extra steady DB connection per worker process** (LISTEN socket). Plan pool sizes accordingly.
- **Connection exhaustion degrades to fallback**: if LISTEN cannot connect, consumers still run via fallback wakes (more latency + more DB queries).
- **NOTIFY is not durable**: fallback wake is mandatory to guarantee eventual processing.
- **Debuggability requirement**: connections must set `application_name` so `pg_stat_activity` can attribute usage and identify leaks/GUI connection storms.
- **Low-tier SKU risk**: GUI tools opening many idle sessions can consume all usable slots and block the app; mitigate via pool sizing and terminating idle GUI sessions.

##### 6.4.1.1 Ops playbook: diagnosing and clearing connection exhaustion
Symptom (common on small managed Postgres tiers):
- App logs show: `remaining connection slots are reserved for roles with privileges of the "pg_use_reserved_connections" role`.

Step 1 — Confirm pressure (Azure):
- Use Azure Monitor `active_connections` to see whether you are near `max_connections` (minus reserved slots).

Step 2 — Attribute connections (Postgres):

```sql
-- Top-level attribution: who is holding connections?
select
  coalesce(nullif(application_name,''),'(empty)') as application_name,
  usename,
  client_addr::text as client,
  state,
  count(*) as n
from pg_stat_activity
where datname = current_database()
group by 1,2,3,4
order by n desc, application_name asc;
```

Step 3 — Safe remediation (terminate only idle GUI sessions):
- Prefer terminating only **idle** sessions from GUI tools that do not set `application_name` (often shows as empty).
- Do **not** terminate active app sessions unless you intentionally want to disrupt processing.

```sql
-- Example: terminate idle sessions with empty application_name.
-- Adjust filters (user/client) to avoid killing app traffic.
select pg_terminate_backend(pid) as terminated, pid, usename, client_addr, state
from pg_stat_activity
where datname = current_database()
  and state = 'idle'
  and coalesce(application_name,'') = '';
```

Step 4 — Prevention (required if this happens more than once):
- Ensure all app connections set `application_name` (API/worker/telemetry/listener).
- Keep SQLAlchemy pools conservative (`DB_POOL_SIZE`, `DB_MAX_OVERFLOW`) and avoid running many local workers against the shared dev database.

---

## 7. Canonical event payload schemas (v1)

This section is the **single source of truth** for the stable payload shapes stored in `events.data` by `events.type`.

Conventions:
- All event payloads must include the **envelope** defined in §6.2.1 (including `event_version`).
- `subject_type`/`subject_id` are stored as columns on `events`; the `events.data` payload must still include the key IDs required for downstream consumers (mirrors, alerts, analytics).
- Event type list is canonical in `docs/architecture/jila_api_backend_data_models.md` (`event_type`). This section defines **payload fields** only.

### 7.1 Reservoir events

#### `RESERVOIR_CREATED` (subject: `RESERVOIR`)
Required `events.data.payload` fields:
- `reservoir_id` (uuid)  # redundant but required for consumers
- `site_id` (uuid|null)
- `owner_principal_id` (uuid)
- `monitoring_mode` (`MANUAL|DEVICE`)

#### `RESERVOIR_SHARE_INVITED` (subject: `RESERVOIR`)
Required `events.data.payload` fields:
- `reservoir_id` (uuid)
- `invite_token_id` (uuid)
- `invited_by_principal_id` (uuid)
- `proposed_role` (`OWNER|MANAGER|VIEWER`)
- `expires_at` (ISO8601)

#### `RESERVOIR_SHARE_ACCEPTED` (subject: `RESERVOIR`)
Required `events.data.payload` fields:
- `reservoir_id` (uuid)
- `invite_token_id` (uuid)
- `invited_by_principal_id` (uuid)
- `subject_principal_id` (uuid)  # the principal receiving access
- `role` (`OWNER|MANAGER|VIEWER`)
- `accepted_at` (ISO8601)

#### `RESERVOIR_LEVEL_READING` (subject: `RESERVOIR`)
Required `events.data.payload` fields:
- `reservoir_id` (uuid)
- `reading_id` (int|null)  # `reservoir_readings.id` when available
- `recorded_at` (ISO8601)
- `source` (`DEVICE|MANUAL`)
- `level_pct` (number)
- `volume_liters` (number)
- `device_id` (uuid|null)
- `telemetry_message_id` (int|null)

#### `RESERVOIR_LEVEL_STATE_CHANGED` (subject: `RESERVOIR`)
Required `events.data.payload` fields:
- `reservoir_id` (uuid)
- `trigger_reading_id` (int|null)  # `reservoir_readings.id` when transition was computed
- `trigger_event_id` (uuid|null)   # upstream event id when computed from another event (optional)
- `recorded_at` (ISO8601)          # the reading time that triggered the transition
- `level_pct` (number)             # level at the time of transition
- `previous_state` (`FULL|NORMAL|LOW|CRITICAL`)
- `new_state` (`FULL|NORMAL|LOW|CRITICAL`)
- `thresholds`:
  - `full_threshold_pct` (number)
  - `low_threshold_pct` (number)
  - `critical_threshold_pct` (number)
- `hysteresis_pct` (number)

#### `RESERVOIR_LOCATION_UPDATED` (subject: `RESERVOIR`)
Required `events.data.payload` fields:
- `reservoir_id` (uuid)
- `recorded_at` (ISO8601)
- `location`:
  - `lat` (number)
  - `lng` (number)
- `source` (`DEVICE_GPS|MANUAL_PING|FIXED_GEO`)

#### `RESERVOIR_GEOMETRY_UPDATED` (subject: `RESERVOIR`)
Required `events.data.payload` fields:
- `reservoir_id` (uuid)
- `geometry_shape` (string|null)
- `geometry_params` (object|null)

#### `RESERVOIR_CAPACITY_UPDATED` (subject: `RESERVOIR`)
Required `events.data.payload` fields:
- `reservoir_id` (uuid)
- `capacity_liters` (number)
- `capacity_source` (`REPORTED|DERIVED_FROM_GEOMETRY|ADMIN_OVERRIDE`)
- `capacity_reported_liters` (number|null)

#### `RESERVOIR_SENSOR_CALIBRATION_UPDATED` (subject: `RESERVOIR`)
Required `events.data.payload` fields:
- `reservoir_id` (uuid)
- `sensor_empty_distance_mm` (int)
- `sensor_full_distance_mm` (int; >= 0)

### 7.2 Device events

#### `DEVICE_ATTACHED` (subject: `DEVICE`)
Required `events.data.payload` fields:
- `device_id` (string)  # MQTT identity (topic segment), stored uppercase
- `reservoir_id` (uuid)

#### `DEVICE_DETACHED` (subject: `DEVICE`)
Required `events.data.payload` fields:
- `device_id` (string)  # MQTT identity (topic segment), stored uppercase
- `reservoir_id` (uuid)

#### `DEVICE_TELEMETRY_DROPPED_UNATTACHED` (subject: `DEVICE`)
Required `events.data.payload` fields:
- `device_id` (string|null)  # topic segment when available
- `mqtt_client_id` (string|null)
- `recorded_at` (ISO8601|null)
- `reason` (`UNREGISTERED_DEVICE|UNATTACHED_DEVICE|MISSING_SEQ|UNKNOWN`)

#### `DEVICE_CONFIG_UPDATED` (subject: `DEVICE`)
Required `events.data.payload` fields:
- `device_id` (string)  # MQTT identity (topic segment), stored uppercase
- `config_version` (int)
- `mqtt_queue_id` (string)
Optional `events.data.payload` fields:
- `config` (object|null)  # desired config snapshot; when present, should include `type` for MQTT routing

#### `DEVICE_CONFIG_APPLIED` (subject: `DEVICE`)
Required `events.data.payload` fields:
- `device_id` (string)  # MQTT identity (topic segment), stored uppercase
- `applied_config_version` (int)
- `applied_at` (ISO8601)
- `mqtt_queue_id` (string|null)
- `success` (bool)  # true if device successfully applied config; false if device reported failure
- `status` (string)  # device-reported status message
- `type` (string)  # config type (e.g., "operations", "network")

Note: Applied state (`device_config_applied`) is only updated when `success=true`. If `success=false`, the event is still emitted for audit, but retry publishing continues until a success ACK is received.

#### `DEVICE_SEEN` (subject: `DEVICE`)
Required `events.data.payload` fields:
- `device_id` (string)  # MQTT identity (topic segment), stored uppercase
- `last_seen_at` (ISO8601)  # server receive time of the MQTT message that triggered this event

Note: Emitted when any MQTT message (telemetry or status/ACK) from a device is observed, but throttled to at most once per 60 seconds per device (based on `devices.last_seen_at`). Used by MQTT publisher to trigger retry publish of pending desired configs.

#### `FIRMWARE_RELEASE_CREATED` (subject: `ACCOUNT`)
Required `events.data.payload` fields:
- `firmware_release_id` (uuid)
- `version` (string)

#### `FIRMWARE_UPDATE_REQUESTED` (subject: `DEVICE`)
Required `events.data.payload` fields:
- `device_id` (string)  # MQTT identity (topic segment), stored uppercase
- `job_id` (uuid)
- `firmware_release_id` (uuid)
- `mqtt_queue_id` (string)
- `config_version` (int)

#### `FIRMWARE_UPDATE_STATUS` (subject: `DEVICE`)
Required `events.data.payload` fields:
- `device_id` (string)  # MQTT identity (topic segment), stored uppercase
- `job_id` (uuid)
- `firmware_release_id` (uuid)
- `mqtt_queue_id` (string)
- `status` (string)  # `PENDING|IN_PROGRESS|COMPLETED|FAILED`
- `success` (bool)
- `message` (string|null)
- `received_at` (ISO8601)

### 7.3 Marketplace events

#### `SUPPLY_POINT_STATUS_UPDATED` (subject: `SUPPLY_POINT`)
Required `events.data.payload` fields:
- `supply_point_id` (uuid)
- `operational_status` (`ACTIVE|INACTIVE|UNKNOWN`)
- `availability_status` (`AVAILABLE|LOW|NONE|CLOSED|UNKNOWN`)
- `availability_evidence_type` (`REPORTED|VERIFIED|SENSOR_DERIVED|null`)
- `operational_status_updated_at` (ISO8601|null)
- `availability_updated_at` (ISO8601|null)
- `reported_by_principal_id` (uuid|null)

#### `ORDER_CREATED` (subject: `ORDER`)
Required `events.data.payload` fields:
- `order_id` (uuid)
- `order_code` (string|null)  # additive in v1; format: `ORD-` + 12 chars; present for newly created orders
- `buyer_principal_id` (uuid)
- `seller_reservoir_id` (uuid)
- `price_rule_id` (uuid)  # applied pricing basis at order creation
- `target_reservoir_id` (uuid|null)
- `requested_volume_liters` (number)
- `price_quote_total` (number)
- `currency` (string)

#### `ORDER_ACCEPTED` | `ORDER_REJECTED` | `ORDER_CANCELLED` | `ORDER_DISPUTED` (subject: `ORDER`)
Required `events.data.payload` fields:
- `order_id` (uuid)
- `order_code` (string|null)  # additive v1 field; present for newly created orders
- `status` (string)  # new status after transition
- `acted_by_principal_id` (uuid)
- `acted_at` (ISO8601)

#### `ORDER_DELIVERED` (subject: `ORDER`)
Required `events.data.payload` fields:
- `order_id` (uuid)
- `order_code` (string|null)  # additive v1 field; present for newly created orders
- `delivered_at` (ISO8601)
- `buyer_confirmed_delivery_at` (ISO8601|null)
- `seller_confirmed_delivery_at` (ISO8601|null)

#### `REVIEW_SUBMITTED` (subject: `ORDER`)
Required `events.data.payload` fields:
- `order_id` (uuid)
- `order_code` (string|null)  # additive v1 field; present for newly created orders
- `review_id` (uuid)
- `rating` (int)

### 7.4 Access and notification events

#### `ACCESS_GRANT_CREATED` | `ACCESS_GRANT_REVOKED` (subject: `ACCOUNT`)
Required `events.data.payload` fields:
- `subject_principal_id` (uuid)
- `object_type` (string)
- `object_id` (uuid)
- `role` (string|null)
- `acted_by_principal_id` (uuid|null)

#### `ALERT_CREATED` (subject: `ACCOUNT`)
Required `events.data.payload` fields:
- `alert_id` (uuid)
- `user_id` (uuid)
- `event_id` (uuid)  # trigger event id (domain event)
- `event_type` (string)  # trigger event type (e.g., `ORDER_CREATED`)
- `subject_type` (string)  # trigger event subject type (e.g., `ORDER`)
- `subject_id` (uuid)  # trigger event subject id
- `channel` (`APP|PUSH|SMS|EMAIL`)
- `message_key` (string)  # stable localization key (see mobile notifications strategy)
- `message_args` (object)  # JSON object for client interpolation
- `deeplink` (object)  # `{ "screen": "<ScreenId>", "params": { ... } }`

#### `OTP_DELIVERY_REQUESTED` (subject: `ACCOUNT`)
Required `events.data.payload` fields:
- `token_id` (uuid)
- `token_type` (`VERIFY_PHONE|VERIFY_EMAIL|PASSWORD_RESET|INVITE|ACCOUNT_ERASURE`)
- `channel` (`SMS|EMAIL`)

Notes:
- This event must not include OTP plaintext.
- This event must not include `target_identifier` (phone/email) to avoid PII in the outbox stream.

#### `OTP_DELIVERY_SENT` (subject: `ACCOUNT`)
Required `events.data.payload` fields:
- `token_id` (uuid)
- `token_type` (string)
- `channel` (`SMS|EMAIL`)
- `attempt_count` (int)

#### `OTP_DELIVERY_FAILED` (subject: `ACCOUNT`)
Required `events.data.payload` fields:
- `token_id` (uuid)
- `channel` (`SMS|EMAIL`)
- `attempt_count` (int)
- `error_code` (string)

#### `ACCOUNT_ERASURE_REQUESTED` (subject: `ACCOUNT`)
Required `events.data.payload` fields:
- `user_id` (uuid)
- `channel` (`SMS|EMAIL`)

Notes:
- Must not include raw phone/email in the outbox payload (avoid PII in `events`).

#### `ACCOUNT_ERASURE_COMPLETED` (subject: `ACCOUNT`)
Required `events.data.payload` fields:
- `user_id` (uuid)
- `erased_at` (ISO8601)

#### `IDENTIFIER_VERIFIED` (subject: `USER`)
Required `events.data.payload` fields:
- `user_id` (uuid)
- `verified_identifier` (`PHONE|EMAIL`)

#### `PRINCIPAL_UPDATED` (subject: `PRINCIPAL`)
Required `events.data.payload` fields:
- `principal_id` (uuid)
- `status` (string)  # principal/user status (e.g., `ACTIVE`)

Optional `events.data.payload` fields:
- `display_name` (string|null)
- `avatar_uri` (string|null)

#### `FIRESTORE_MIRROR_RECONCILE_REQUESTED` (subject: `PRINCIPAL`)
Request a rebuild/prune of one principal's Firestore subtree from Postgres truth.

Required `events.data.payload` fields:
- `principal_id` (uuid)
- `scopes` (array[string])  # e.g. `["me_profile", "orders"]`

Optional `events.data.payload` fields:
- `reason` (string|null)  # operator/debug hint only

#### `SESSION_CREATED` (subject: `PRINCIPAL`)
Required `events.data.payload` fields:
- `session_id` (uuid)
- `principal_id` (uuid)
- `user_id` (uuid)

#### `SESSION_REVOKED` (subject: `PRINCIPAL`)
Required `events.data.payload` fields:
- `session_id` (uuid)
- `principal_id` (uuid|null)  # optional, included when available
- `user_id` (uuid|null)  # optional, included when available

#### `USER_REGISTERED` (subject: `USER`)
Required `events.data.payload` fields:
- `status` (string)  # user status (e.g., `PENDING_VERIFICATION`)

#### `PASSWORD_RESET` (subject: `USER`)
Required `events.data.payload` fields:
- `user_id` (uuid)

### 7.5 Subscription events

#### `SUBSCRIPTION_UPGRADED` | `SUBSCRIPTION_DOWNGRADED` (subject: `PRINCIPAL`)
Required `events.data.payload` fields:
- `account_principal_id` (uuid)
- `previous_plan_id` (string|null)  # null when no prior plan exists
- `new_plan_id` (string)

#### `SUBSCRIPTION_EXPIRING_SOON` (subject: `PRINCIPAL`)
Required `events.data.payload` fields:
- `account_principal_id` (uuid)
- `plan_id` (string)
- `current_period_end` (ISO8601 UTC)
