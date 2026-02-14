# Device Configuration Endpoints - Complete API Reference

This document provides exhaustive specifications for device configuration update endpoints, using both the current implementation and the published contract.

## Overview

Device configurations are rapidly evolving JSON objects that are published to devices via MQTT. Configurations support monotonic versioning to prevent race conditions and include flexible schemas that can evolve over time.

## Sources Used

- Implementation:
  - `app/modules/core_water/api/router.py`
  - `app/modules/core_water/api/schemas.py`
  - `app/modules/core_water/service/service.py`
- Contract:
  - `docs/architecture/api_contract/06_devices_firmware_telemetry.md`
  - `docs/architecture/jila_api_backend_device_management.md` (MQTT config types)

## Core Concepts

- **Configuration Types**: Each configuration object must include a `type` field that determines the MQTT topic routing (`devices/{device_id}/config/{type}`)
- **Monotonic Versioning**: `config_version` must be greater than the current version
- **Desired vs Applied State**: Backend tracks both what operators want (`desired`) and what devices report they've applied (`applied`)
- **MQTT Delivery**: Configurations are published immediately and retried based on device activity

---

## 1. GET Device Configuration State

### Endpoint
```
GET /v1/accounts/{org_principal_id}/devices/{device_id}/config
```

### Authentication
- Requires `Authorization: Bearer <jwt>`
- Caller must have access to the device (explicit `DEVICE` grant or container RBAC when attached)

### Path Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `org_principal_id` | string | Organization principal identifier (UUID format) |
| `device_id` | string | Device identifier (MAC address format, e.g., "B43A4536C83C") |

### Response (200 OK)
```json
{
  "device_id": "string",
  "desired": [
    {
      "type": "operation",
      "config_version": 123,
      "mqtt_queue_id": "op-1",
      "updated_at": "2025-01-26T11:45:00Z",
      "config": {
        "type": "operation",
        "sleep_duration_ms": 30000,
        "sleep_mode": "POWER_MANAGED",
        "battery_voltage_critical": 3200,
        "battery_voltage_low": 3500,
        "battery_voltage_normal": 3800,
        "samples_per_reading": 5,
        "reservoir_id": null
      }
    }
  ],
  "applied": [
    {
      "type": "operation",
      "applied_config_version": 123,
      "applied_at": "2025-01-26T11:45:00Z",
      "mqtt_queue_id": "op-1"
    }
  ]
}
```

### Response Fields

#### Root Level
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `device_id` | string | Yes | The device identifier |

#### Desired Configuration Array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Config type (`operation|ultrasonic|network|location|firmware`) |
| `config_version` | integer | Yes | Monotonic version number (starts at 1) |
| `mqtt_queue_id` | string | Yes | Correlation ID for MQTT publish/ACK |
| `updated_at` | string | No | ISO8601 UTC `Z` |
| `config` | object | Yes | Typed config object (must include `type`) |

#### Applied Configuration Array
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | Yes | Config type |
| `applied_config_version` | integer | Yes | Version number that device reports as applied |
| `applied_at` | string | Yes | ISO8601 UTC timestamp when device reported application |
| `mqtt_queue_id` | string | No | Correlation ID echoed by device |

### Special Cases
- If no desired configs have been set: `desired = []`
- If device has never reported applied config for a type: that type is absent from `applied`

### Error Responses

#### 401 UNAUTHORIZED
```json
{
  "error_code": "UNAUTHORIZED",
  "message": "Authentication required",
  "details": {}
}
```

#### 403 FORBIDDEN
```json
{
  "error_code": "FORBIDDEN",
  "message": "Insufficient permissions",
  "details": {}
}
```

#### 404 RESOURCE_NOT_FOUND
```json
{
  "error_code": "RESOURCE_NOT_FOUND",
  "message": "Device not found",
  "details": {
    "resource": "device",
    "device_id": "B43A4536C83C"
  }
}
```

---

## 2. PUT Device Configuration

### Endpoint
```
PUT /v1/accounts/{org_principal_id}/devices/{device_id}/config
```

### Authentication
- Requires `Authorization: Bearer <jwt>`
- Caller must be `OWNER|MANAGER` of the containing org/site/reservoir

### Path Parameters
| Parameter | Type | Description |
|-----------|------|-------------|
| `org_principal_id` | string | Organization principal identifier (UUID format) |
| `device_id` | string | Device identifier (MAC address format) |

### Request Body
```json
{
  "config_version": 3,
  "config": {
    "type": "operation",
    "sleep_seconds": 300,
    "gps_enabled": true,
    "sampling_interval_seconds": 60,
    "heartbeat_interval_seconds": 3600
  }
}
```

### Request Fields

| Field | Type | Required | Validation | Description |
|-------|------|----------|------------|-------------|
| `config_version` | integer | Yes | `> 0` | Must be greater than current desired version |
| `config` | object | Yes | Must contain `type` field | Flexible JSON configuration object |

### Configuration Object Requirements

#### Required Fields
| Field | Type | Description |
|-------|------|-------------|
| `type` | string | Configuration type (non-empty, used for MQTT routing) |

#### Known Configuration Types (device protocol)
These are the current types used by the device MQTT protocol and status ACKs. The HTTP API requires `config.type` to be a non-empty string, but does not enforce a closed enum.

- `"operation"` - Operational settings (sleep, GPS, intervals)
- `"ultrasonic"` - Ultrasonic sensor configuration
- `"location"` - GPS/location settings
- `"mqtt"` - MQTT communication settings
- `"network"` - Cellular/network configuration
- `"firmware"` - Firmware update settings

### Example Configurations

#### Operations Configuration
```json
{
  "type": "operation",
  "sleep_seconds": 300,
  "gps_enabled": true,
  "sampling_interval_seconds": 60,
  "heartbeat_interval_seconds": 3600
}
```

#### Ultrasonic Sensor Configuration
```json
{
  "type": "ultrasonic",
  "measurement_interval_seconds": 60
}
```

#### Network Configuration
```json
{
  "type": "network",
  "cellular_apn": "internet"
}
```

#### Location Configuration
```json
{
  "type": "location",
  "gps_update_interval_seconds": 300
}
```

### Response (200 OK)
```json
{
  "status": "OK",
  "mqtt_queue_id": "string"
}
```

### Response Fields
| Field | Type | Description |
|-------|------|-------------|
| `status` | string | Always "OK" |
| `mqtt_queue_id` | string | Correlation ID for tracking MQTT delivery |

### Error Responses

#### 401 UNAUTHORIZED
```json
{
  "error_code": "UNAUTHORIZED",
  "message": "Authentication required",
  "details": {}
}
```

#### 403 FORBIDDEN
```json
{
  "error_code": "FORBIDDEN",
  "message": "Insufficient permissions",
  "details": {}
}
```

#### 404 RESOURCE_NOT_FOUND
```json
{
  "error_code": "RESOURCE_NOT_FOUND",
  "message": "Device not found",
  "details": {}
}
```

#### 409 DEVICE_CONFIG_VERSION_CONFLICT
```json
{
  "error_code": "DEVICE_CONFIG_VERSION_CONFLICT",
  "message": "Device config_version must be monotonic",
  "details": {
    "device_id": "B43A4536C83C",
    "current_config_version": 2,
    "attempted_config_version": 1
  }
}
```

#### 422 VALIDATION_ERROR
```json
{
  "error_code": "VALIDATION_ERROR",
  "message": "Validation failed",
  "details": {
    "field": "config.type",
    "reason": "Field required"
  }
}
```

---

## 3. Internal Operations Endpoints

### GET Internal Device Configuration
```
GET /v1/internal/devices/{device_id}/config
```

Same as public endpoint but with internal ops bypass rules. Requires internal ops admin role.

### PUT Internal Device Configuration
```
PUT /v1/internal/devices/{device_id}/config
```

Same as public endpoint but with internal ops bypass rules. Requires internal ops admin role.

---

## Implementation Guidelines

### Version Management
1. Always fetch current configuration before updating
2. Increment `config_version` by 1 (or more if needed)
3. If `config_version` equals current and `config` matches, the server returns the existing `mqtt_queue_id` (idempotent)
4. If `config_version` equals current but `config` differs, the server returns `409 DEVICE_CONFIG_VERSION_CONFLICT`
5. Handle version conflicts gracefully in UI
6. Display current desired vs applied versions to users

### Configuration Types
- Use consistent naming for configuration types
- Document new configuration types when added
- Consider backward compatibility when evolving schemas

### Error Handling
- Always check for version conflicts before allowing updates
- Provide clear feedback for permission errors
- Handle network failures gracefully with retry logic

### UI Considerations
- Show current configuration state clearly
- Allow preview of changes before submission
- Display configuration delivery status (pending, applied, failed)
- Provide validation feedback for configuration fields

### MQTT Delivery
- Backend publishes to `devices/{device_id}/config/{type}`
- Devices acknowledge via `devices/{device_id}/config/status/{type}`
- Delivery is retried every 60 seconds when device activity is observed
- Correlation via `mqtt_queue_id`

---

## Enums and Constants

### HTTP Status Codes
- `200` - Success
- `401` - Authentication required
- `403` - Insufficient permissions
- `404` - Resource not found
- `409` - Version conflict or validation error
- `422` - Request validation failed

### Error Codes
- `UNAUTHORIZED`
- `FORBIDDEN`
- `RESOURCE_NOT_FOUND`
- `DEVICE_CONFIG_VERSION_CONFLICT`
- `VALIDATION_ERROR`

### Configuration Types (device protocol, current set)
- `"operation"`
- `"ultrasonic"`
- `"location"`
- `"mqtt"`
- `"network"`
- `"firmware"`

### Field Validation Rules
- `config_version`: Must be integer > 0
- `config.type`: Non-empty string, required
- Timestamps: ISO8601 format with 'Z' suffix (UTC)

## Contract vs Implementation Notes

- `GET /v1/accounts/{org_principal_id}/devices/{device_id}/config`:
  - Implementation returns `desired.config_version` and `desired.config` only.
  - It does not return `desired.mqtt_queue_id` or `desired.updated_at` in this endpoint.
- `PUT /v1/accounts/{org_principal_id}/devices/{device_id}/config`:
  - Implementation enforces: `config_version > 0`, `config` is an object, and `config.type` is a non-empty string.
  - The API does not enforce a closed enum for `config.type`; the set listed above reflects the current device protocol.
- `DEVICE_CONFIG_VERSION_CONFLICT` details:
  - Implementation provides `device_id`, `current_config_version`, and `attempted_config_version`.

This document should be updated whenever new configuration types or fields are added to maintain completeness.