# Frontend Config Payload (Implementation-Aligned)

This document aligns frontend payloads with the current API implementation.

The backend enforces:
- the request envelope (`config_version`, `config.type`)
- and type-specific validation for known config types (schema-stable v1).

## Payload Envelope (API)

All config updates must include:
- `config_version` (integer > 0)
- `config` (object) with a non-empty `type` string

Any additional root fields are ignored by the API.

```json
{
  "config_version": 3,
  "config": {
    "type": "operation",
    "reservoir_id": "server-injected (ignored if sent by client)",
    "... type-specific fields ..."
  }
}
```

### Common Field (All Types, Firmware-Parsed)

- `reservoir_id` (string UUID, or `null`): Links the config to the reservoir the device is currently attached to.

Important (v1 behavior):
- Clients **must not** set `reservoir_id`. Any client-provided `reservoir_id` (or legacy `tank_id`) is ignored.
- The backend injects `reservoir_id` from the device attachment (`devices.reservoir_id`) when persisting and publishing.
- **Partial updates are allowed**: the frontend may send only the fields it wants to change for a given `config.type`.
  - Omitted fields are not sent to the device (delta publish) to avoid overriding device-side values.
  - The backend stores provided fields into typed Postgres columns and keeps previously-set values.
  - Explicit `null` values are rejected (no “clear field” semantics in v1).

## Config Types

### Required Field (All Types)
- `type` (string, non-empty): Used by the backend to route MQTT topic `devices/{device_id}/config/{type}`.

The API enforces a closed set of `type` values in v1.

### operation

When to use: Change sleep behavior, retry policy, or battery voltage thresholds.

Send any subset (delta update):
- `sleep_duration_ms` (number, ms, > 0)
- `sleep_mode` (`"ALWAYS_ON" | "POWER_MANAGED" | "ALWAYS_SLEEP"`)
- `battery_voltage_critical` (number, mV, > 0)
- `battery_voltage_low` (number, mV, > 0)
- `battery_voltage_normal` (number, mV, > 0)
- `samples_per_reading` (number, > 0)

Notes (firmware expectations):
- Battery thresholds must be ordered `critical < low < normal`.

### ultrasonic

When to use: Associate the ultrasonic mode/config with the attached reservoir (`reservoir_id`).

### network

When to use: Switch between WiFi and cellular or update carrier credentials.

Send any subset (delta update):
- `transport` (`"WIFI" | "CELLULAR"`): Primary network path used by the device.

Firmware expectations (when setting transport, make sure required peer fields are set somewhere on the device):
- If setting `transport = "CELLULAR"`, you typically also set `gsm_apn`.
- If setting `transport = "WIFI"`, you typically also set `wifi_ssid` + `wifi_password`.

Optional:
- `rat_preference` (`"AUTO" | "GSM" | "LTE"`)
- `gsm_username` (string)
- `gsm_password` (string)
- `connection_timeout_ms` (number, ms, > 0)
- MQTT fields (optional; when present they must be internally consistent):
  - `mqtt_broker_url` (string)
  - `mqtt_port` (int, 1..65535)
  - `mqtt_client_id` (string)
  - `mqtt_username` (string)
  - `mqtt_password` (string)

### location

When to use: Enable GPS or adjust fix frequency/timeouts.

Send any subset (delta update):
- `gps_enabled` (boolean): Turns GPS on or off.
- `update_interval_ms` (number, > 0): How often to request a GPS fix.
- `gps_timeout_ms` (number, > 0): How long to wait for a GPS fix.

Useful optional (firmware expectations):
- `speed_threshold_kmh` (number, >= 0): Optional speed gate for reporting or filtering location.

### firmware

When to use: Trigger an OTA update.

Send any subset (delta update):
- `download_url` (string): URL to the firmware image for OTA.
- `checksum` (string, 64 lowercase hex SHA256): Integrity check for the download (required by backend schema when provided).
- `version` (string): Human-readable firmware version label.
- `force` (boolean; allow OTA in ALWAYS_SLEEP)
- `signature` (string)

Useful optional (firmware expectations):
- `file_size_bytes` (number): Expected image size for validation and progress tracking.
- `install_after` (string, ISO timestamp): Schedule OTA after a specific time.
- `retry_attempts` (number, uint8): Number of OTA retries.
- `retry_backoff_ms` (number): Delay between OTA retries.

Notes (firmware expectations):
- If `sleep_mode` is `ALWAYS_SLEEP` and `force` is false, OTA is deferred.

## Example Payloads (API + Firmware)

### operation
```json
{
  "config_version": 3,
  "config": {
    "type": "operation",
    "sleep_duration_ms": 120000,
    "sleep_mode": "POWER_MANAGED",
    "retry_attempts": 3,
    "retry_delay_ms": 1000
  }
}
```

### ultrasonic
```json
{
  "config_version": 3,
  "config": {
    "type": "ultrasonic",
    "reservoir_id": "server-injected (ignored if sent by client)"
  }
}
```

### network (cellular)
```json
{
  "config_version": 3,
  "config": {
    "type": "network",
    "transport": "CELLULAR",
    "gsm_apn": "sensor.net",
    "rat_preference": "AUTO"
  }
}
```

### network (wifi)
```json
{
  "config_version": 3,
  "config": {
    "type": "network",
    "transport": "WIFI",
    "wifi_ssid": "MyNetwork",
    "wifi_password": "MyPassword"
  }
}
```

### location
```json
{
  "config_version": 3,
  "config": {
    "type": "location",
    "gps_enabled": true,
    "update_interval_ms": 30000,
    "gps_timeout_ms": 60000
  }
}
```


### firmware
```json
{
  "config_version": 3,
  "config": {
    "type": "firmware",
    "download_url": "https://example.com/firmware.bin",
    "version": "1.2.3",
    "checksum": "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
  }
}
```
