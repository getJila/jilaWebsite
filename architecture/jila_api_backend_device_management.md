## Jila API Backend – Device Management (Firmware, Config, Telemetry) (v0.1)

This document specifies v1 behavior for device-connected reservoirs:
- **Firmware updates** (artifacts in blob storage, update jobs to devices)
- **Device configuration** (rapidly evolving desired/applied state; publish via MQTT)
- **Telemetry payloads** (JSON payload containing multiple signal types; cellular connectivity is first-class)

Single source of truth note (anti-drift):
- This file is the only canonical definition of the **device MQTT topic structure** and **device payload requirements** (schema_version/timestamps/seq/ACK semantics).
- Other docs may reference the protocol, but should not restate it verbatim.

Companion docs:
- `docs/architecture/jila_api_backend_data_models.md`
- `docs/architecture/jila_api_backend_api_contract_v1.md`
- `docs/architecture/jila_api_backend_state_and_history_patterns.md`

---

## 1. Firmware updates (blob storage + update jobs)

### 1.1 Storage model
- Firmware binaries are stored in **blob storage**, not in the database.
- The database stores:
  - immutable firmware **release metadata** (version, checksum, blob URI, size)
  - **update jobs** that target one or more devices

### 1.2 Operational flow (v1)
1. Jila uploads firmware binary to blob storage.
2. Jila publishes firmware release metadata via `POST /v1/internal/firmware/releases` (admin backend / internal pipeline).
3. An authorized device owner/manager creates a `firmware_update_jobs` row by calling `POST /v1/accounts/{account_id}/devices/{device_id}/firmware-update`.
4. Worker publishes an MQTT command:
   - immediately (if device appears online), and/or
   - opportunistically when device next connects (device publishes telemetry/heartbeat)
5. Device downloads binary from blob storage, applies update, then reports:
   - `firmware_version` (new)
   - `firmware_update_status` telemetry event (optional but recommended)
6. Backend updates job status and emits events for audit.

Firmware update commands include a `config_version` integer to align firmware updates with other device
configuration operations, and they use the same envelope as other config commands: the firmware details
are nested under `config` with `type = "firmware"`.

### 1.2a Firmware upload API (admin-only)
- `POST /v1/internal/firmware/upload` uploads the binary to blob storage and registers the release in one step.
- `POST /v1/firmware/upload` is a legacy-compatible alias (admin-only).

### 1.3 Safety constraints (recommended)
- A job must record the **expected checksum**; device should verify before applying.
- Support “staged rollout” by selecting devices by filter (later).

---

## 2. Device configuration (desired state + applied state)

Device configurations are treated as **schema-stable (v1)** at the application layer:
- The API validates the config object by `config.type` and rejects unknown/malformed fields.
- Postgres stores the config as JSONB for auditability, but the JSON is produced from typed schemas (no ad-hoc dicts).

### 2.1 Config shapes (v1, stable)
All desired config updates use:
- monotonic `config_version` (int > 0)
- `config` (object) with required `type`

Known `config.type` values (v1):
- `operation`: sleep/power thresholds and tank association.
- `ultrasonic`: tank association for ultrasonic sensor mode.
- `network`: cellular/WiFi transport + MQTT credentials.
- `location`: GPS enablement and update cadence.
- `firmware`: OTA request (download URL + checksum, optional signature/force).

Note: `tank_id` is supported across types as an optional association key.

### 2.2 Delivery model (MQTT)
- Desired configs are published via MQTT:
  - **Immediately** upon HTTP `PUT /v1/accounts/{account_id}/devices/{device_id}/config` receipt (via outbox event `DEVICE_CONFIG_UPDATED`).
  - **Retried** whenever device activity is observed (any MQTT message from the device), throttled to once per 60 seconds per device, until a config status ACK with `success=true` is received.
- Config payloads are schema-stable JSON and **must include `type` (string)**. The backend publishes to per-type topics:
  - **Publish topic**: `devices/{device_id}/config/{type}`
  - **ACK topic**: `devices/{device_id}/config/status/{type}` (see §4)
  - Envelope fields are stable: `schema_version`, `mqtt_queue_id` (required), `config_version`, `config` (object with `type`).
- Retry behavior: The backend emits `DEVICE_SEEN` outbox events (throttled) when any MQTT message from a device is observed. The MQTT publisher consumer processes `DEVICE_SEEN` events and republishes the desired config if it has not yet been confirmed (i.e., `device_config_applied.mqtt_queue_id != device_config_desired.mqtt_queue_id` or applied row is missing). Guardrail: if the latest ACK for that config type is `success=true` but carries a different `mqtt_queue_id` than the current desired row, the consumer skips republish for that cycle to avoid stale/unknown ACK loops.

### 2.3 Applied-state reporting
- Device reports the applied config version and (optionally) the applied config blob.
- Backend keeps:
  - **desired** config (what we want)
  - **applied** config state (what the device says it is running)

---

## 3. Telemetry payloads (JSON; cellular is first-class)

### 3.1 Payload envelope
Devices publish telemetry to the MQTT broker / IoT gateway:
- **Topic**: `devices/{device_id}/telemetry`

Backend ingestion path (canonical):
- MQTT is terminated by an **Azure Event Grid Namespace (MQTT broker)** (Terraform-provisioned in `infra/terraform`).
- Devices connect over **TLS (port 8883)** and authenticate using **client certificate authentication** (thumbprint match) as configured on the Event Grid Namespace.
- The MQTT broker routes messages into **Azure Event Hubs** (Terraform-provisioned). The envelope includes the MQTT topic and payload.
- The backend telemetry listener consumes from **Event Hubs** and processes the embedded MQTT payload/topic metadata.

Observed Event Hubs message envelope (v1, canonical for this repo/workspace):
- Messages arrive as **CloudEvents v1.0** with:
  - `type = "MQTT.EventPublished"`
  - `subject = "devices/{device_id}/telemetry"` (canonical topic string)
  - `data_base64` containing the MQTT payload bytes (UTF-8 JSON after base64 decode)
- The backend must treat **CloudEvent `subject` as the single source of truth** for the MQTT topic.

Payload is JSON and may omit fields (partial updates are normal).

Canonical fields (robust):
- `schema_version` (int)
- `local_timestamp_ms` (int64)  # root event time, device-local, milliseconds since epoch
- `seq` (int64, **required**)  # monotonic per device publish (v1); must persist across reboots for dedupe
- sections like `sensors`, `power`, `location`, `system` (optional)

Device identity:
- The device identity is derived from the topic path: `{device_id}`.
- The payload **must not require** a `device_id` field to identify the device.
- If a `device_id` appears in payload, the backend ignores it (topic identity is canonical).

Idempotency (v1, canonical; see decision D-007):
- The backend dedupes raw telemetry on `(mqtt_client_id, seq)`.
- Devices must treat `seq` as part of the protocol contract; missing `seq` will cause the backend to store raw payload only (audit) and skip derived readings/side effects.

Missing `seq` fallback (v1, decided for this repo/workspace):
- If `seq` is missing, the backend **does not store raw telemetry** in `device_telemetry_messages` (schema requires `seq`).
- Instead, the backend emits a diagnostic outbox event `DEVICE_TELEMETRY_DROPPED_UNATTACHED` with `reason = MISSING_SEQ`.

Important timestamp semantics:
- `local_timestamp_ms` may appear in multiple places (root and per-section like `power.local_timestamp_ms`).
- All `*_timestamp_ms` values are **milliseconds**.
- Backend stores:
  - `received_at` as server receive time (UTC)
  - `recorded_at` as the canonical event time used for ordering/computation, derived from `received_at` (UTC) (see decision D-011)

UI note:
- Device-provided timestamps (e.g. `local_timestamp_ms`) are non-authoritative and may be used for UI display/diagnostics only.

### 3.1.1 Example telemetry payload (canonical)

```json
{
  "schema_version": 1,
  "local_timestamp_ms": 1730000000000,
  "seq": 123,
  "sensors": {
    "ultrasonic": {
      "sensor_type": "ULTRASONIC",
      "local_timestamp_ms": 1730000000000,
      "raw_readings": [123, 456, -1]
    }
  },
  "power": {
    "sensor_type": "POWER",
    "battery_voltage_mv": 0,
    "system_voltage_mv": 0,
    "battery_current_ma": 0,
    "input_current_ma": 0,
    "vbus_mv": 0,
    "power_good": true,
    "power_mode": "OPTIMAL|LOW|CRITICAL|SHUTDOWN|UNKNOWN",
    "battery_percentage": 0,
    "is_charging": true,
    "pmic_die_temp_c": 0,
    "charge_status": 0,
    "ce_pin_enabled": true,
    "is_iindpm": true,
    "is_vindpm": true,
    "is_hiz": true,
    "thermal_derated": true,
    "ichg_setpoint_ma": 0,
    "iindpm_setpoint_ma": 0,
    "local_timestamp_ms": 1730000000000
  },
  "location": {
    "latitude": 0,
    "longitude": 0,
    "course_degrees": 0,
    "speed_kmh": 0,
    "local_timestamp_ms": 1730000000000
  },
  "system": {
    "firmware_version": "string",
    "build_date": "string",
    "build_time": "string",
    "build_version": "string",
    "cpu_freq_mhz": 0,
    "base_mac": "AA:BB:CC:DD:EE:FF",
    "board_version": 0,
    "free_heap_bytes": 0,
    "local_timestamp_ms": 1730000000000
  }
}
```

### 3.2 Telemetry categories (typical)
- **Sensor readings**: reservoir level, orientation, temperature (if any), etc.
- **Battery**: battery percentage, voltage, charging state (if applicable)
- **Network (cellular)**:
  - identifiers (IMEI/ICCID/IMSI as available)
  - radio metrics (RSSI/RSRP/RSRQ/SINR)
  - carrier/network info (MCC/MNC, operator name, APN)
  - connectivity info (IP, connection state, last attach time)
- **Device health**: uptime, reboot reason, error codes

### 3.3 Storage strategy (canonical)
- Store high-signal, frequently queried metrics in **typed columns** (battery %, last seen, firmware version, key radio metrics).
- Store the full evolving payload in a **JSONB telemetry table** for audit/debugging and future extraction.
- Keep high-volume time series such as reservoir level in a typed time-series table (`reservoir_readings`).

Reservoir level derivation (device-sourced):
- Devices publish **raw samples** (variable-length arrays, e.g. `sensors.ultrasonic.raw_readings`) in the telemetry payload.
- The backend stores the raw payload in `device_telemetry_messages.payload` and computes derived stats:
  - `raw_sample_count`, `raw_mean`, `raw_stddev` (in mm)
  - `level_pct` and `volume_liters`
- `reservoir_readings.telemetry_message_id` links the derived row back to the raw telemetry message for audit/debugging.

---

## 4. MQTT protocol: config ACKs + OTA status (canonical v1)

### 4.1 Config update ACK (applied/failed/ota-started)

- **Topic**: `devices/{device_id}/config/status/{type}`
- `{type}` ∈ `operation | ultrasonic | location | mqtt | network | firmware`
- **QoS/retain**: QoS 1, retain false
- **When sent**:
  - only if the inbound config update included a non-empty `mqtt_queue_id`

Payload:

```json
{
  "schema_version": 1,
  "local_timestamp_ms": 1730000000000,
  "seq": 123,
  "mqtt_queue_id": "string",
  "success": true,
  "status": "RECEIVED",
  "message": "Applied configuration|Apply failed|OTA started|OTA failed"
}
```

Message selection:
- `firmware`: `"OTA started"` on success, `"OTA failed"` on failure (and “deferred OTA” counts as failure)
- others: `"Applied configuration"` on success, `"Apply failed"` on failure

### 4.2 OTA progress status (download)

- **Topic**: `devices/{device_id}/config/status/firmware`
- **QoS/retain**: QoS 0, retain false
- **When sent**: during OTA download, throttled (≥5% progress change and ≥5s since last publish)

Payload:

```json
{
  "schema_version": 1,
  "local_timestamp_ms": 1730000000000,
  "seq": 123,
  "mqtt_queue_id": "string",
  "success": true,
  "status": "RECEIVED",
  "download_progress_pct": 0,
  "avg_speed_kbps": 0.0,
  "message": "Downloading firmware..."
}
```

Notes:
- `mqtt_queue_id` is optional (only if known).

### 4.3 OTA completion status (installed)

- **Topic**: `devices/{device_id}/config/status/firmware`
- **QoS/retain**: QoS 1, retain false
- **When sent**: only on successful install and when `mqtt_queue_id` is known

Payload:

```json
{
  "schema_version": 1,
  "local_timestamp_ms": 1730000000000,
  "seq": 123,
  "mqtt_queue_id": "string",
  "success": true,
  "status": "INSTALLED",
  "message": "OTA installed"
}
```

---

## 5. Backend MQTT client choices (publish + ACK ingest)

These choices are canonical for the backend MQTT publisher/consumer and must not drift without updating this section.

- **MQTT version**: MQTT v5 for backend publishes and ACK handling (v1 devices speak MQTT v5).
- **Broker**: Azure Event Grid Namespace MQTT endpoint (TLS 8883).
- **Authentication**: mTLS (X.509 client certs) for MQTT. For firmware binaries, devices download from private blob storage using short-lived, per-blob **SAS URLs** in the firmware command `download_url` (read-only).
- **Client library**: Python `paho-mqtt` (TLS, QoS 1) wrapped in the worker; no ad-hoc clients per service.
- **QoS / retain**: QoS 1, retain = false for config/firmware commands and status topics.
- **Topics**:
  - Commands: `devices/{device_id}/config/{type}` (firmware commands use `type = firmware`).
  - Status/ACK: `devices/{device_id}/config/status/{type}` (as specified in §4).
- **Correlation + idempotency**: include `mqtt_queue_id` on every backend-initiated command; retries are idempotent on `(mqtt_queue_id, topic)`.
- **Connection policy**: TLS required; hostname verification on; keepalive 60s; exponential backoff with jitter on reconnect.
- **Observability/alerts**: structured logs for connect/publish/ACK failures (no secrets/PII); metrics for connect success/fail and publish retries; alert when publish failures or missing ACKs breach SLA.
- **Secrets handling**: cert/key provided via settings (`MQTT_CERT_CONTENT_B64`/`MQTT_KEY_CONTENT_B64` or file paths). Never log or echo credentials.

## 5. Protocol robustness requirements (canonical)

The MQTT contract must be robust by default, and breaking changes are acceptable while the device fleet is still controlled.

### 5.1 Required common fields (all device → backend MQTT payloads)

Every payload (telemetry, config status, OTA progress/completion) must include:
- `schema_version` (int)
- `local_timestamp_ms` (int64; milliseconds since epoch)

Required for robustness (v1; see D-007):
- `seq` (int64; monotonic per device, increments per publish) for ordering and dedupe.
  - `seq` must be persisted across reboots (must not reset).
  - `seq` must not wrap in v1; if overflow is ever approached, device must stop publishing and require reprovisioning/firmware update.

Factory reset / reprovisioning rule (v1):
- If a device is factory-reset such that `seq` would reset, the device must be **reprovisioned with a new MQTT identity** (new `{device_id}`) so the backend dedupe key remains correct.

### 5.2 Canonical correlation

- Any backend-initiated device operation that expects a device response must include a non-empty `mqtt_queue_id`.
- Any device status payload that corresponds to an operation must include the same `mqtt_queue_id`.
- Config/status ACKs must be published for all config types, including `network`, using the same topic family.
