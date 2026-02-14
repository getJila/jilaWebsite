# Mock Data Inventory - API Response Format

> **Purpose**: This document provides a comprehensive inventory of all mock data currently used in the Jila Web Portal. The data is formatted to resemble API responses, suitable for creating a test dataset that mirrors the current website population.

---

## Table of Contents

1. [Organization & Current User](#1-organization--current-user)
2. [Sites](#2-sites)
3. [Reservoirs](#3-reservoirs)
4. [Devices](#4-devices)
5. [Users & Access](#5-users--access)
6. [Alerts](#6-alerts)
7. [Settings](#7-settings)
8. [Data Relationships](#8-data-relationships)

---

## 1. Organization & Current User

### GET /v1/auth/me

```json
{
  "user": {
    "id": "user-001",
    "name": "Alex Morgan",
    "email": "alex.morgan@acmecorp.com",
    "role": "admin",
    "roleLabel": "Administrator",
    "avatarUrl": null,
    "initials": "AM"
  },
  "organization": {
    "id": "org-001",
    "name": "Acme Corp",
    "logoUrl": null,
    "initials": "AC"
  }
}
```

| Field | Value | Type |
|-------|-------|------|
| user.id | `user-001` | string |
| user.name | `Alex Morgan` | string |
| user.email | `alex.morgan@acmecorp.com` | string |
| user.role | `admin` | enum: admin, manager, viewer |
| user.roleLabel | `Administrator` | string |
| user.initials | `AM` | string |
| organization.id | `org-001` | string |
| organization.name | `Acme Corp` | string |
| organization.initials | `AC` | string |

---

## 2. Sites

### GET /v1/sites

| id | name | type | address | latitude | longitude | zone | region | status | riskLevel | reservoirCount | deviceCount | lastUpdated | createdAt | updatedAt |
|----|------|------|---------|----------|-----------|------|--------|--------|-----------|----------------|-------------|-------------|-----------|-----------|
| `site-alpha-1` | Site A - Downtown | treatment | Northern Valley District | 34.0522 | -118.2437 | North Zone | North Region | active | critical | 3 | 12 | 10 min ago | 2024-01-15T10:00:00Z | 2024-12-20T14:30:00Z |
| `site-beta-2` | Site B - Industrial Park | pumping | California, USA | 36.7783 | -119.4179 | South Zone | Central Region | active | stale | 5 | 5 | 1 day ago | 2024-03-10T08:00:00Z | 2024-12-18T09:15:00Z |
| `site-gamma-3` | Site C - Hillside | distribution | Arizona, USA | 33.4484 | -112.074 | East Zone | South Region | active | good | 2 | 2 | 2 min ago | 2024-06-01T12:00:00Z | 2024-12-15T16:45:00Z |
| `site-delta-4` | Site D - West End | reservoir | Nevada, USA | 36.1699 | -115.1398 | West Zone | West Region | active | good | 1 | 3 | 5 min ago | 2024-08-15T10:00:00Z | 2024-12-20T12:00:00Z |
| `site-epsilon-5` | Site E - Uptown | treatment | Oregon, USA | 45.5152 | -122.6784 | North Zone | North Region | active | warning | 4 | 8 | 30 min ago | 2024-02-20T14:00:00Z | 2024-12-19T18:30:00Z |

**Site Types**: `treatment`, `pumping`, `distribution`, `reservoir`

**Risk Levels**: `critical`, `warning`, `stale`, `good`

### GET /v1/sites/:id/stats

| siteId | totalVolume | volumeUnit | volumeTrend | avgFlowRate | flowRateUnit | flowRateStatus | peakFlowRate |
|--------|-------------|------------|-------------|-------------|--------------|----------------|--------------|
| `site-alpha-1` | 1200000 | Liters | +5% | 845 | L/min | optimal | 920 |
| `site-beta-2` | 800000 | Liters | -2% | 620 | L/min | low | 750 |
| `site-gamma-3` | 450000 | Liters | +8% | 380 | L/min | optimal | 420 |

### GET /v1/sites/:id/reservoirs

**Site: site-alpha-1**

| id | name | capacity | level | status |
|----|------|----------|-------|--------|
| `res-a01` | Reservoir A-01 | 500000 | 85% | online |
| `res-a02` | Reservoir A-02 | 250000 | 32% | maintenance |
| `res-a03` | Reservoir A-03 | 500000 | 92% | online |

**Site: site-beta-2**

| id | name | capacity | level | status |
|----|------|----------|-------|--------|
| `res-b01` | Reservoir B-01 | 300000 | 65% | online |

**Site: site-gamma-3**

| id | name | capacity | level | status |
|----|------|----------|-------|--------|
| `res-c01` | Reservoir C-01 | 200000 | 78% | online |
| `res-c02` | Reservoir C-02 | 250000 | 88% | online |

### GET /v1/sites/:id/alerts

**Site: site-alpha-1**

| id | title | description | severity | source | timestamp |
|----|-------|-------------|----------|--------|-----------|
| `alert-1` | Pressure Drop Detected | Reservoir A-02 - Pump 3 | critical | Reservoir A-02 | 12 mins ago |
| `alert-2` | Maintenance Due | Sensor Array 4 | warning | Sensor Array 4 | 2 hours ago |
| `alert-3` | Firmware Updated | Gateway Node | info | Gateway Node | Yesterday |

**Site: site-beta-2**

| id | title | description | severity | source | timestamp |
|----|-------|-------------|----------|--------|-----------|
| `alert-4` | Data Sync Delayed | No data for 24 hours | warning | Gateway B-01 | 1 day ago |

---

## 3. Reservoirs

### GET /v1/reservoirs

| id | name | siteId | siteName | capacity | capacityUnit | currentLevel | currentVolume | status | estimatedRemaining | monitoringMode | samplingFrequency | createdAt | updatedAt |
|----|------|--------|----------|----------|--------------|--------------|---------------|--------|-------------------|----------------|-------------------|-----------|-----------|
| `rsv-north-alpha` | North Tank Alpha | site-alpha-1 | Facility 01 - Zone A | 15000 | gallons | 84% | 12400 | normal | ~ 14 Days | DEVICE | realtime | 2024-01-15T10:00:00Z | 2024-12-20T14:30:00Z |
| `rsv-south-b` | South Reserve B | site-alpha-1 | Facility 01 - Zone B | 7000 | gallons | 12% | 840 | critical | ~ 2 Days | DEVICE | realtime | 2024-02-10T08:00:00Z | 2024-12-21T09:15:00Z |
| `rsv-west-main` | West Main Tank | site-beta-2 | West Outpost | 12500 | gallons | 65% | 8100 | stale | Stable | DEVICE | hourly | 2024-03-05T12:00:00Z | 2024-12-20T16:45:00Z |
| `rsv-east-irrigation` | East Irrigation 01 | site-gamma-3 | Agricultural Zone | 50000 | gallons | 92% | 45000 | normal | ~ 28 Days | DEVICE | daily | 2024-04-20T09:00:00Z | 2024-12-21T08:00:00Z |
| `rsv-fire-tank` | Secondary Fire Tank | site-alpha-1 | Central HQ | 11000 | gallons | 45% | 5000 | warning | Refill Soon | DEVICE | hourly | 2024-05-15T14:00:00Z | 2024-12-21T10:30:00Z |

**Reservoir Status**: `normal`, `warning`, `critical`, `stale`

**Monitoring Mode**: `DEVICE`, `MANUAL`

**Sampling Frequency**: `realtime`, `hourly`, `daily`

### Reservoir Device Details (embedded in reservoir response)

| reservoirId | device.id | device.name | device.status | device.batteryLevel | device.signalStrength | device.firmwareVersion | device.lastReading |
|-------------|-----------|-------------|---------------|---------------------|----------------------|------------------------|-------------------|
| `rsv-north-alpha` | dev-sensor-x2-1 | Sensor-X2 | online | 98% | strong | v2.4.1 | 2m ago |
| `rsv-south-b` | dev-sensor-x2-2 | Sensor-X2 | online | 15% | medium | v2.3.0 | 5m ago |
| `rsv-west-main` | dev-sensor-y4 | Sensor-Y4 | maintenance | null | null | v2.1.0 | 4h ago |
| `rsv-east-irrigation` | dev-sensor-z1 | Sensor-Z1 | online | 100% | strong | v2.4.1 | 10m ago |
| `rsv-fire-tank` | dev-sensor-a9 | Sensor-A9 | online | 92% | strong | v2.4.0 | 15m ago |

### Reservoir Location Details

| reservoirId | latitude | longitude | region |
|-------------|----------|-----------|--------|
| `rsv-north-alpha` | 34.0522 | -118.2437 | North West |
| `rsv-south-b` | 34.0515 | -118.2430 | South East |
| `rsv-west-main` | 36.7783 | -119.4179 | West |
| `rsv-east-irrigation` | 33.4484 | -112.074 | East |
| `rsv-fire-tank` | 34.0530 | -118.2445 | Central |

### Reservoir Thresholds

| reservoirId | criticalLow | warningLow |
|-------------|-------------|------------|
| `rsv-north-alpha` | 10% | 25% |
| `rsv-south-b` | 15% | 30% |
| `rsv-west-main` | 10% | 25% |
| `rsv-east-irrigation` | 10% | 20% |
| `rsv-fire-tank` | 20% | 50% |

### GET /v1/reservoirs/:id/stats

| reservoirId | currentLevel | levelUnit | levelTrend | capacityUsed | capacityTrend | totalVolume | volumeUnit | systemStatus |
|-------------|--------------|-----------|------------|--------------|---------------|-------------|------------|--------------|
| `rsv-north-alpha` | 4.2 | m | +2.1% | 84% | +0.5% | 12.4 | ML | normal |
| `rsv-south-b` | 0.6 | m | -5.2% | 12% | -2.1% | 0.84 | ML | critical |

### GET /v1/reservoirs/:id/alerts

**Reservoir: rsv-north-alpha**

| id | title | description | severity | timestamp |
|----|-------|-------------|----------|-----------|
| `alert-1` | High water level detected | Threshold exceeded by 5% for > 15mins. | warning | 2h ago |
| `alert-2` | Sensor battery healthy | Self-diagnostic test passed. | info | 1d ago |

**Reservoir: rsv-south-b**

| id | title | description | severity | timestamp |
|----|-------|-------------|----------|-----------|
| `alert-3` | Critical low water level | Water level dropped below 15% threshold. | critical | 30m ago |
| `alert-4` | Low battery warning | Sensor battery at 15%. Replace soon. | warning | 2h ago |

### GET /v1/reservoirs/:id/readings

**Reservoir: rsv-north-alpha**

| timestamp | level (m) | volume (gal) |
|-----------|-----------|--------------|
| 2024-12-15 | 3.8 | 11800 |
| 2024-12-16 | 3.9 | 12000 |
| 2024-12-17 | 4.0 | 12200 |
| 2024-12-18 | 3.85 | 11900 |
| 2024-12-19 | 4.1 | 12350 |
| 2024-12-20 | 4.15 | 12380 |
| 2024-12-21 | 4.2 | 12400 |

---

## 4. Devices

### GET /v1/accounts/{account_id}/devices

| id | name | type | reservoirId | reservoirName | siteId | siteName | pairingState | connectionStatus | battery | batteryTimeRemaining | firmware | configSynced | lastSeen | createdAt | updatedAt |
|----|------|------|-------------|---------------|--------|----------|--------------|------------------|---------|---------------------|----------|--------------|----------|-----------|-----------|
| `dev-8821` | #DEV-8821 | Sensor Type A | res-a01 | Main Tank Alpha | site-alpha-1 | Site Alpha | paired | online | 84% | ~12 days | v2.4.1 | true | 2 mins ago | 2024-01-15T10:00:00Z | 2024-12-20T14:30:00Z |
| `dev-9932` | #DEV-9932 | Flow Meter X | res-b01 | North Reservoir | site-beta-2 | Site Beta | warning | online | 65% | ~8 days | v2.3.0 | false | 1 hour ago | 2024-03-10T08:00:00Z | 2024-12-18T09:15:00Z |
| `dev-1029` | #DEV-1029 | New Import | - | - | - | - | unpaired | online | - | - | v2.4.1 | false | Online | 2024-12-19T12:00:00Z | 2024-12-19T12:00:00Z |
| `dev-4412` | #DEV-4412 | Pressure Gauge | res-c01 | Treatment Plant C | site-gamma-3 | Site Gamma | error | offline | 12% | ~1 day | v2.1.0 | false | 4 days ago | 2024-06-01T12:00:00Z | 2024-12-15T16:45:00Z |
| `dev-1199` | #DEV-1199 | Sensor Type B | res-d01 | East Spillway | site-delta-4 | Site Delta | paired | online | 92% | ~15 days | v1.8.0 | true | 10 mins ago | 2024-08-15T10:00:00Z | 2024-12-20T12:00:00Z |
| `dev-2234` | #DEV-2234 | Hydraulic Pump Controller | res-a02 | Secondary Tank | site-alpha-1 | Site Alpha | paired | online | 78% | ~10 days | v2.4.1 | true | 5 mins ago | 2024-02-20T14:00:00Z | 2024-12-19T18:30:00Z |
| `dev-3345` | #DEV-3345 | Flow Meter X | res-c02 | West Basin | site-gamma-3 | Site Gamma | warning | online | 45% | ~5 days | v2.2.0 | false | 30 mins ago | 2024-05-10T09:00:00Z | 2024-12-20T10:00:00Z |

**Pairing States**: `paired`, `unpaired`, `warning`, `error`

**Connection Status**: `online`, `offline`

**Device Types**: `Sensor Type A`, `Sensor Type B`, `Flow Meter X`, `Pressure Gauge`, `Hydraulic Pump Controller`, `New Import`

### Device Location Details

| deviceId | latitude | longitude |
|----------|----------|-----------|
| `dev-8821` | 34.0522 | -118.2437 |
| `dev-9932` | 36.7783 | -119.4179 |
| `dev-4412` | 33.4484 | -112.074 |
| `dev-1199` | 36.1699 | -115.1398 |
| `dev-2234` | 34.0522 | -118.2437 |
| `dev-3345` | 33.4484 | -112.074 |

### Device Config Version Status

| deviceId | desiredConfigVersion | appliedConfigVersion | configSynced |
|----------|---------------------|---------------------|--------------|
| `dev-8821` | v2.1 | v2.1 | true |
| `dev-9932` | v2.2 | v2.0 | false |
| `dev-4412` | v2.1 | null | false |
| `dev-1199` | v1.8 | v1.8 | true |
| `dev-2234` | v2.1 | v2.1 | true |
| `dev-3345` | v2.3 | v2.1 | false |

### GET /v1/accounts/{account_id}/devices/:id/config

**Device: dev-8821**

```json
{
  "samplingInterval": "15 minutes",
  "heartbeatInterval": 900,
  "gpsEnabled": true,
  "sleepSeconds": 300,
  "samplesPerReading": 5,
  "outlierRejection": "Median filter",
  "calibrationEmpty": 2200,
  "calibrationFull": 250,
  "locationPublishInterval": 3600,
  "cellularApn": "internet",
  "roamingAllowed": false,
  "mqttKeepalive": 60,
  "telemetryQos": 1,
  "installedVersion": "v2.4.1",
  "updateStatus": "up_to_date"
}
```

**Device: dev-9932**

```json
{
  "samplingInterval": "30 minutes",
  "heartbeatInterval": 1800,
  "gpsEnabled": true,
  "sleepSeconds": 600,
  "samplesPerReading": 3,
  "outlierRejection": "Trimmed mean",
  "calibrationEmpty": 2000,
  "calibrationFull": 200,
  "locationPublishInterval": 7200,
  "cellularApn": "internet",
  "roamingAllowed": true,
  "mqttKeepalive": 120,
  "telemetryQos": 1,
  "installedVersion": "v2.3.0",
  "targetRelease": "v2.4.1",
  "updateStatus": "pending"
}
```

### GET /v1/accounts/{account_id}/devices/:id/config-history

**Device: dev-8821**

| id | action | title | description | user | timestamp |
|----|--------|-------|-------------|------|-----------|
| `hist-1` | applied | Applied Successfully | System synchronized desired configuration. | - | Just now |
| `hist-2` | updated | Config Update | User changed interval to 15m. | j.doe | 2 hours ago |
| `hist-3` | reboot | Device Reboot | - | - | Yesterday at 16:00 |
| `hist-4` | firmware | Firmware v2.4.1 | - | - | Oct 24, 2023 |

**Device: dev-9932**

| id | action | title | description | user | timestamp |
|----|--------|-------|-------------|------|-----------|
| `hist-5` | updated | Config Mismatch | Desired config updated, awaiting device sync. | admin | 1 hour ago |
| `hist-6` | reboot | Device Reboot | - | - | 3 days ago |

### GET /v1/accounts/{account_id}/devices/stats

```json
{
  "total": 1248,
  "totalTrend": "+12 this week",
  "online": 1180,
  "onlinePercent": 94.5,
  "issues": 42,
  "issuesReason": "Config mismatch",
  "offline": 26,
  "offlineReason": "Needs attention"
}
```

---

## 5. Users & Access

### GET /v1/members

| id | name | email | avatar | role | scope | scopeDetails | status | lastActive | createdAt |
|----|------|-------|--------|------|-------|--------------|--------|------------|-----------|
| `member-1` | Sarah Jenkins | sarah.j@hydro.co | [avatar-url] | admin | Global Access | - | active | Oct 24, 2023 | 2023-01-15 |
| `member-2` | Michael Chen | m.chen@hydro.co | [avatar-url] | site_manager | North Reservoir | + 2 Pump Stations | active | 2 hours ago | 2023-02-20 |
| `member-3` | James Doe | james.d@partner.inc | - | viewer | Dam Unit 4 Only | - | pending | - | 2023-10-20 |
| `member-4` | Emily Blunt | e.blunt@hydro.co | [avatar-url] | viewer | All Sites | - | revoked | Sep 12, 2023 | 2023-03-10 |
| `member-5` | Robert Fox | r.fox@hydro.co | [avatar-url] | site_manager | South River Dam | - | active | Yesterday | 2023-04-05 |

**Member Roles**: `admin`, `site_manager`, `viewer`, `technician`

**Member Status**: `active`, `pending`, `revoked`

### GET /v1/members/stats

```json
{
  "totalMembers": 45,
  "activeUsers": 42,
  "pendingInvites": 3
}
```

### GET /v1/invites

| id | email | initials | category | role | scope | sentDate | status |
|----|-------|----------|----------|------|-------|----------|--------|
| `invite-1` | jane.doe@partners.com | JD | External Vendor | technician | North Reservoir | Oct 24, 2023 | pending |
| `invite-2` | m.khan@company.com | MK | Internal Staff | viewer | Global | Oct 23, 2023 | pending |
| `invite-3` | tech.support@example.com | TS | Contractor | site_manager | South Treatment | Sep 12, 2023 | expired |

**Invite Status**: `pending`, `expired`

**Invite Categories**: `External Vendor`, `Internal Staff`, `Contractor`

### GET /v1/scope-sites (for access assignment)

| id | name | status | reservoirCount | deviceCount |
|----|------|--------|----------------|-------------|
| `site-north-a` | North Sector - Site A | active | 3 | 12 |
| `site-south-b` | South Sector - Site B | active | 2 | 0 |
| `site-east-c` | East Sector - Site C | maintenance | 0 | 5 |
| `site-west-d` | West Sector - Site D | active | 1 | 4 |

### Scope Site Children (nested resources for assignment)

**Site: site-north-a**

| id | name | type | parentId | metadata |
|----|------|------|----------|----------|
| `reservoir-01` | Reservoir 01 (Main Tank) | reservoir | site-north-a | - |
| `sensor-hub-x` | Sensor Hub X | device | site-north-a | ID: SN-829 |
| `pump-alpha` | Pump Station Alpha | device | site-north-a | - |

**Site: site-south-b**

| id | name | type | parentId | metadata |
|----|------|------|----------|----------|
| `reservoir-02` | Reservoir 02 | reservoir | site-south-b | - |

---

## 6. Alerts

### GET /v1/accounts/{account_id}/alerts

| id | title | message | severity | status | context | source.id | source.type | source.name | source.location | timestamp | receivedAt |
|----|-------|---------|----------|--------|---------|-----------|-------------|-------------|-----------------|-----------|------------|
| `alert-1` | Pressure Critical High | Pressure sensor reading 48 PSI exceeds critical threshold of 45 PSI. Immediate attention required. | critical | unread | device | DEV-4412 | device | Pressure Gauge #4412 | North Reservoir - Zone A | 2m ago | Today at 10:42 AM |
| `alert-2` | Connection Lost | Device #DEV-1029 has failed to report heartbeat for 3 consecutive intervals. | warning | unread | device | DEV-1029 | device | Sensor #DEV-1029 | - | 15m ago | Today at 10:29 AM |
| `alert-3` | Firmware Update Successful | Batch update v2.1 applied successfully to 12 devices in East Sector. | info | read | system | system | system | System | - | 2h ago | Today at 8:42 AM |
| `alert-4` | Low Battery Warning | Battery level dropped below 15% on Device #DEV-1199. Estimated 48h remaining. | warning | read | device | DEV-1199 | device | Sensor #DEV-1199 | - | 5h ago | Today at 5:42 AM |
| `alert-5` | Flow Rate Normalized | Flow rate returned to normal operating range (250 L/min) after spike. | info | read | reservoir | pipe-b | reservoir | Main Pipe B | - | Yesterday | Yesterday at 3:15 PM |

**Alert Severity**: `critical`, `warning`, `info`

**Alert Status**: `unread`, `read`

**Alert Context**: `device`, `system`, `reservoir`

### Alert Data Snapshots (for detailed view)

**Alert: alert-1**

| label | value | unit | isThreshold |
|-------|-------|------|-------------|
| Current Value | 48.2 | PSI | false |
| Threshold | 45.0 | PSI | true |

---

## 7. Settings

### GET /v1/settings/profile

```json
{
  "firstName": "Jo\u00e3o",
  "lastName": "Silva",
  "email": "joao.silva@aqualink.ao",
  "phone": "+244 923 456 789",
  "department": "Operations",
  "role": "Site Manager",
  "bio": "Water infrastructure specialist with 10+ years of experience in reservoir management and IoT monitoring systems.",
  "avatar": null
}
```

### GET /v1/settings/organization

```json
{
  "name": "AquaLink Angola",
  "industry": "Water Infrastructure",
  "description": "Leading water infrastructure management company in Angola, specializing in reservoir monitoring and IoT solutions.",
  "logo": null,
  "country": "Angola",
  "region": "Luanda",
  "city": "Luanda",
  "address": "Rua Major Kanhangulo, 290",
  "timezone": "Africa/Luanda",
  "units": "metric",
  "dateFormat": "DD/MM/YYYY"
}
```

### GET /v1/settings/notifications

**Critical Alerts**

| id | label | description | email | sms |
|----|-------|-------------|-------|-----|
| `low-water` | Low Water Level | When reservoir falls below critical threshold | true | true |
| `device-offline` | Device Offline | When a monitoring device loses connection | true | true |
| `high-water` | High Water Level | When reservoir exceeds maximum threshold | true | false |

**Operational Updates**

| id | label | description | email | sms |
|----|-------|-------------|-------|-----|
| `daily-summary` | Daily Summary | Daily report of all reservoir levels | true | false |
| `weekly-report` | Weekly Report | Weekly analytics and trends | true | false |
| `maintenance-due` | Maintenance Due | Scheduled maintenance reminders | true | false |

**User Management**

| id | label | description | email | sms |
|----|-------|-------------|-------|-----|
| `new-invite` | New Invitations | When you receive team invitations | true | false |
| `role-change` | Role Changes | When your permissions are updated | true | false |

### GET /v1/settings/security

```json
{
  "twoFactor": {
    "enabled": false,
    "method": null
  },
  "lastPasswordChange": "2025-11-15"
}
```

**Active Sessions**

| id | device | location | lastActive | current |
|----|--------|----------|------------|---------|
| `session-1` | Chrome on macOS | Luanda, Angola | Now | true |
| `session-2` | Safari on iPhone | Luanda, Angola | 2 hours ago | false |
| `session-3` | Firefox on Windows | Benguela, Angola | 3 days ago | false |

### Settings Options (Reference Data)

**Timezones**

| value | label |
|-------|-------|
| Africa/Luanda | Africa/Luanda (WAT) |
| Africa/Lagos | Africa/Lagos (WAT) |
| Europe/Lisbon | Europe/Lisbon (WET) |
| UTC | UTC |

**Date Formats**

| value | label |
|-------|-------|
| DD/MM/YYYY | DD/MM/YYYY |
| MM/DD/YYYY | MM/DD/YYYY |
| YYYY-MM-DD | YYYY-MM-DD |

**Industries**

| value | label |
|-------|-------|
| water-infrastructure | Water Infrastructure |
| agriculture | Agriculture |
| mining | Mining |
| municipal | Municipal Services |
| other | Other |

---

## 8. Data Relationships

### Entity Relationship Diagram

```
Organization (org-001)
│
├── Current User (user-001: Alex Morgan)
│
├── Sites
│   ├── site-alpha-1 (Site A - Downtown)
│   │   ├── Reservoirs
│   │   │   ├── rsv-north-alpha (North Tank Alpha)
│   │   │   │   └── Device: dev-sensor-x2-1
│   │   │   ├── rsv-south-b (South Reserve B)
│   │   │   │   └── Device: dev-sensor-x2-2
│   │   │   └── rsv-fire-tank (Secondary Fire Tank)
│   │   │       └── Device: dev-sensor-a9
│   │   └── Devices
│   │       ├── dev-8821 (Sensor Type A) → res-a01
│   │       └── dev-2234 (Hydraulic Pump Controller) → res-a02
│   │
│   ├── site-beta-2 (Site B - Industrial Park)
│   │   ├── Reservoirs
│   │   │   └── rsv-west-main (West Main Tank)
│   │   │       └── Device: dev-sensor-y4 (maintenance)
│   │   └── Devices
│   │       └── dev-9932 (Flow Meter X) → res-b01
│   │
│   ├── site-gamma-3 (Site C - Hillside)
│   │   ├── Reservoirs
│   │   │   └── rsv-east-irrigation (East Irrigation 01)
│   │   │       └── Device: dev-sensor-z1
│   │   └── Devices
│   │       ├── dev-4412 (Pressure Gauge) → res-c01
│   │       └── dev-3345 (Flow Meter X) → res-c02
│   │
│   ├── site-delta-4 (Site D - West End)
│   │   └── Devices
│   │       └── dev-1199 (Sensor Type B) → res-d01
│   │
│   └── site-epsilon-5 (Site E - Uptown)
│       └── (4 reservoirs, 8 devices - not detailed in mock)
│
├── Members (5 total)
│   ├── member-1: Sarah Jenkins (admin, Global)
│   ├── member-2: Michael Chen (site_manager, North Reservoir)
│   ├── member-3: James Doe (viewer, Dam Unit 4)
│   ├── member-4: Emily Blunt (viewer, revoked)
│   └── member-5: Robert Fox (site_manager, South River Dam)
│
├── Pending Invites (3 total)
│   ├── invite-1: jane.doe@partners.com (technician)
│   ├── invite-2: m.khan@company.com (viewer)
│   └── invite-3: tech.support@example.com (expired)
│
└── Alerts (5 active)
    ├── alert-1: Pressure Critical (DEV-4412)
    ├── alert-2: Connection Lost (DEV-1029)
    ├── alert-3: Firmware Update (system)
    ├── alert-4: Low Battery (DEV-1199)
    └── alert-5: Flow Normalized (pipe-b)
```

### Foreign Key Relationships

| Entity | Foreign Key | References |
|--------|-------------|------------|
| Reservoir | `siteId` | Site.id |
| Device | `siteId` | Site.id |
| Device | `reservoirId` | Reservoir.id |
| Alert (device context) | `source.id` | Device.id |
| Alert (reservoir context) | `source.id` | Reservoir.id |
| Member | `scope` | Site.name (text reference) |
| Invite | `scope` | Site.name (text reference) |

### Summary Statistics

| Entity | Count |
|--------|-------|
| Organizations | 1 |
| Sites | 5 |
| Reservoirs | 5 |
| Devices | 7 |
| Members | 5 |
| Invites | 3 |
| Alerts | 5 |
| Active Sessions | 3 |
| Notification Types | 8 |

---

## Appendix: Complete JSON Export

For programmatic use, here is the complete mock data in JSON format:

<details>
<summary>Click to expand full JSON export</summary>

```json
{
  "organization": {
    "id": "org-001",
    "name": "Acme Corp",
    "initials": "AC"
  },
  "currentUser": {
    "id": "user-001",
    "name": "Alex Morgan",
    "email": "alex.morgan@acmecorp.com",
    "role": "admin",
    "roleLabel": "Administrator",
    "initials": "AM"
  },
  "sites": [
    {
      "id": "site-alpha-1",
      "name": "Site A - Downtown",
      "type": "treatment",
      "location": {
        "address": "Northern Valley District",
        "latitude": 34.0522,
        "longitude": -118.2437,
        "zone": "North Zone",
        "region": "North Region"
      },
      "description": "Main distribution hub for the northern valley district. Contains 3 active reservoirs and 12 monitoring sensors.",
      "status": "active",
      "riskLevel": "critical",
      "reservoirCount": 3,
      "deviceCount": 12,
      "lastUpdated": "10 min ago",
      "createdAt": "2024-01-15T10:00:00Z",
      "updatedAt": "2024-12-20T14:30:00Z"
    },
    {
      "id": "site-beta-2",
      "name": "Site B - Industrial Park",
      "type": "pumping",
      "location": {
        "address": "California, USA",
        "latitude": 36.7783,
        "longitude": -119.4179,
        "zone": "South Zone",
        "region": "Central Region"
      },
      "description": "Secondary pumping station for the central district.",
      "status": "active",
      "riskLevel": "stale",
      "reservoirCount": 5,
      "deviceCount": 5,
      "lastUpdated": "1 day ago",
      "createdAt": "2024-03-10T08:00:00Z",
      "updatedAt": "2024-12-18T09:15:00Z"
    },
    {
      "id": "site-gamma-3",
      "name": "Site C - Hillside",
      "type": "distribution",
      "location": {
        "address": "Arizona, USA",
        "latitude": 33.4484,
        "longitude": -112.074,
        "zone": "East Zone",
        "region": "South Region"
      },
      "description": "Distribution node in optimal condition.",
      "status": "active",
      "riskLevel": "good",
      "reservoirCount": 2,
      "deviceCount": 2,
      "lastUpdated": "2 min ago",
      "createdAt": "2024-06-01T12:00:00Z",
      "updatedAt": "2024-12-15T16:45:00Z"
    },
    {
      "id": "site-delta-4",
      "name": "Site D - West End",
      "type": "reservoir",
      "location": {
        "address": "Nevada, USA",
        "latitude": 36.1699,
        "longitude": -115.1398,
        "zone": "West Zone",
        "region": "West Region"
      },
      "description": "West district reservoir station.",
      "status": "active",
      "riskLevel": "good",
      "reservoirCount": 1,
      "deviceCount": 3,
      "lastUpdated": "5 min ago",
      "createdAt": "2024-08-15T10:00:00Z",
      "updatedAt": "2024-12-20T12:00:00Z"
    },
    {
      "id": "site-epsilon-5",
      "name": "Site E - Uptown",
      "type": "treatment",
      "location": {
        "address": "Oregon, USA",
        "latitude": 45.5152,
        "longitude": -122.6784,
        "zone": "North Zone",
        "region": "North Region"
      },
      "description": "Uptown treatment facility under maintenance.",
      "status": "active",
      "riskLevel": "warning",
      "reservoirCount": 4,
      "deviceCount": 8,
      "lastUpdated": "30 min ago",
      "createdAt": "2024-02-20T14:00:00Z",
      "updatedAt": "2024-12-19T18:30:00Z"
    }
  ],
  "reservoirs": [
    {
      "id": "rsv-north-alpha",
      "name": "North Tank Alpha",
      "siteId": "site-alpha-1",
      "siteName": "Facility 01 - Zone A",
      "capacity": 15000,
      "capacityUnit": "gallons",
      "currentLevel": 84,
      "currentVolume": 12400,
      "status": "normal",
      "estimatedRemaining": "~ 14 Days",
      "device": {
        "id": "dev-sensor-x2-1",
        "name": "Sensor-X2",
        "status": "online",
        "batteryLevel": 98,
        "signalStrength": "strong",
        "firmwareVersion": "v2.4.1",
        "lastReading": "2m ago"
      },
      "location": {
        "latitude": 34.0522,
        "longitude": -118.2437,
        "region": "North West"
      },
      "thresholds": {
        "criticalLow": 10,
        "warningLow": 25
      },
      "monitoringMode": "DEVICE",
      "samplingFrequency": "realtime",
      "createdAt": "2024-01-15T10:00:00Z",
      "updatedAt": "2024-12-20T14:30:00Z"
    },
    {
      "id": "rsv-south-b",
      "name": "South Reserve B",
      "siteId": "site-alpha-1",
      "siteName": "Facility 01 - Zone B",
      "capacity": 7000,
      "capacityUnit": "gallons",
      "currentLevel": 12,
      "currentVolume": 840,
      "status": "critical",
      "estimatedRemaining": "~ 2 Days",
      "device": {
        "id": "dev-sensor-x2-2",
        "name": "Sensor-X2",
        "status": "online",
        "batteryLevel": 15,
        "signalStrength": "medium",
        "firmwareVersion": "v2.3.0",
        "lastReading": "5m ago"
      },
      "location": {
        "latitude": 34.0515,
        "longitude": -118.2430,
        "region": "South East"
      },
      "thresholds": {
        "criticalLow": 15,
        "warningLow": 30
      },
      "monitoringMode": "DEVICE",
      "samplingFrequency": "realtime",
      "createdAt": "2024-02-10T08:00:00Z",
      "updatedAt": "2024-12-21T09:15:00Z"
    },
    {
      "id": "rsv-west-main",
      "name": "West Main Tank",
      "siteId": "site-beta-2",
      "siteName": "West Outpost",
      "capacity": 12500,
      "capacityUnit": "gallons",
      "currentLevel": 65,
      "currentVolume": 8100,
      "status": "stale",
      "estimatedRemaining": "Stable",
      "device": {
        "id": "dev-sensor-y4",
        "name": "Sensor-Y4",
        "status": "maintenance",
        "batteryLevel": null,
        "signalStrength": null,
        "firmwareVersion": "v2.1.0",
        "lastReading": "4h ago"
      },
      "location": {
        "latitude": 36.7783,
        "longitude": -119.4179,
        "region": "West"
      },
      "thresholds": {
        "criticalLow": 10,
        "warningLow": 25
      },
      "monitoringMode": "DEVICE",
      "samplingFrequency": "hourly",
      "createdAt": "2024-03-05T12:00:00Z",
      "updatedAt": "2024-12-20T16:45:00Z"
    },
    {
      "id": "rsv-east-irrigation",
      "name": "East Irrigation 01",
      "siteId": "site-gamma-3",
      "siteName": "Agricultural Zone",
      "capacity": 50000,
      "capacityUnit": "gallons",
      "currentLevel": 92,
      "currentVolume": 45000,
      "status": "normal",
      "estimatedRemaining": "~ 28 Days",
      "device": {
        "id": "dev-sensor-z1",
        "name": "Sensor-Z1",
        "status": "online",
        "batteryLevel": 100,
        "signalStrength": "strong",
        "firmwareVersion": "v2.4.1",
        "lastReading": "10m ago"
      },
      "location": {
        "latitude": 33.4484,
        "longitude": -112.074,
        "region": "East"
      },
      "thresholds": {
        "criticalLow": 10,
        "warningLow": 20
      },
      "monitoringMode": "DEVICE",
      "samplingFrequency": "daily",
      "createdAt": "2024-04-20T09:00:00Z",
      "updatedAt": "2024-12-21T08:00:00Z"
    },
    {
      "id": "rsv-fire-tank",
      "name": "Secondary Fire Tank",
      "siteId": "site-alpha-1",
      "siteName": "Central HQ",
      "capacity": 11000,
      "capacityUnit": "gallons",
      "currentLevel": 45,
      "currentVolume": 5000,
      "status": "warning",
      "estimatedRemaining": "Refill Soon",
      "device": {
        "id": "dev-sensor-a9",
        "name": "Sensor-A9",
        "status": "online",
        "batteryLevel": 92,
        "signalStrength": "strong",
        "firmwareVersion": "v2.4.0",
        "lastReading": "15m ago"
      },
      "location": {
        "latitude": 34.0530,
        "longitude": -118.2445,
        "region": "Central"
      },
      "thresholds": {
        "criticalLow": 20,
        "warningLow": 50
      },
      "monitoringMode": "DEVICE",
      "samplingFrequency": "hourly",
      "createdAt": "2024-05-15T14:00:00Z",
      "updatedAt": "2024-12-21T10:30:00Z"
    }
  ],
  "devices": [
    {
      "id": "dev-8821",
      "name": "#DEV-8821",
      "type": "Sensor Type A",
      "reservoirId": "res-a01",
      "reservoirName": "Main Tank Alpha",
      "siteId": "site-alpha-1",
      "siteName": "Site Alpha",
      "pairingState": "paired",
      "connectionStatus": "online",
      "battery": 84,
      "batteryTimeRemaining": "~12 days remaining",
      "firmware": "v2.4.1",
      "desiredConfigVersion": "v2.1",
      "appliedConfigVersion": "v2.1",
      "configSynced": true,
      "lastSeen": "2 mins ago",
      "location": {
        "latitude": 34.0522,
        "longitude": -118.2437
      },
      "createdAt": "2024-01-15T10:00:00Z",
      "updatedAt": "2024-12-20T14:30:00Z"
    },
    {
      "id": "dev-9932",
      "name": "#DEV-9932",
      "type": "Flow Meter X",
      "reservoirId": "res-b01",
      "reservoirName": "North Reservoir",
      "siteId": "site-beta-2",
      "siteName": "Site Beta",
      "pairingState": "warning",
      "connectionStatus": "online",
      "battery": 65,
      "batteryTimeRemaining": "~8 days remaining",
      "firmware": "v2.3.0",
      "desiredConfigVersion": "v2.2",
      "appliedConfigVersion": "v2.0",
      "configSynced": false,
      "lastSeen": "1 hour ago",
      "location": {
        "latitude": 36.7783,
        "longitude": -119.4179
      },
      "createdAt": "2024-03-10T08:00:00Z",
      "updatedAt": "2024-12-18T09:15:00Z"
    },
    {
      "id": "dev-1029",
      "name": "#DEV-1029",
      "type": "New Import",
      "pairingState": "unpaired",
      "connectionStatus": "online",
      "firmware": "v2.4.1",
      "configSynced": false,
      "lastSeen": "Online",
      "createdAt": "2024-12-19T12:00:00Z",
      "updatedAt": "2024-12-19T12:00:00Z"
    },
    {
      "id": "dev-4412",
      "name": "#DEV-4412",
      "type": "Pressure Gauge",
      "reservoirId": "res-c01",
      "reservoirName": "Treatment Plant C",
      "siteId": "site-gamma-3",
      "siteName": "Site Gamma",
      "pairingState": "error",
      "connectionStatus": "offline",
      "battery": 12,
      "batteryTimeRemaining": "~1 day remaining",
      "firmware": "v2.1.0",
      "desiredConfigVersion": "v2.1",
      "appliedConfigVersion": null,
      "configSynced": false,
      "lastSeen": "4 days ago",
      "location": {
        "latitude": 33.4484,
        "longitude": -112.074
      },
      "createdAt": "2024-06-01T12:00:00Z",
      "updatedAt": "2024-12-15T16:45:00Z"
    },
    {
      "id": "dev-1199",
      "name": "#DEV-1199",
      "type": "Sensor Type B",
      "reservoirId": "res-d01",
      "reservoirName": "East Spillway",
      "siteId": "site-delta-4",
      "siteName": "Site Delta",
      "pairingState": "paired",
      "connectionStatus": "online",
      "battery": 92,
      "batteryTimeRemaining": "~15 days remaining",
      "firmware": "v1.8.0",
      "desiredConfigVersion": "v1.8",
      "appliedConfigVersion": "v1.8",
      "configSynced": true,
      "lastSeen": "10 mins ago",
      "location": {
        "latitude": 36.1699,
        "longitude": -115.1398
      },
      "createdAt": "2024-08-15T10:00:00Z",
      "updatedAt": "2024-12-20T12:00:00Z"
    },
    {
      "id": "dev-2234",
      "name": "#DEV-2234",
      "type": "Hydraulic Pump Controller",
      "reservoirId": "res-a02",
      "reservoirName": "Secondary Tank",
      "siteId": "site-alpha-1",
      "siteName": "Site Alpha",
      "pairingState": "paired",
      "connectionStatus": "online",
      "battery": 78,
      "batteryTimeRemaining": "~10 days remaining",
      "firmware": "v2.4.1",
      "desiredConfigVersion": "v2.1",
      "appliedConfigVersion": "v2.1",
      "configSynced": true,
      "lastSeen": "5 mins ago",
      "location": {
        "latitude": 34.0522,
        "longitude": -118.2437
      },
      "createdAt": "2024-02-20T14:00:00Z",
      "updatedAt": "2024-12-19T18:30:00Z"
    },
    {
      "id": "dev-3345",
      "name": "#DEV-3345",
      "type": "Flow Meter X",
      "reservoirId": "res-c02",
      "reservoirName": "West Basin",
      "siteId": "site-gamma-3",
      "siteName": "Site Gamma",
      "pairingState": "warning",
      "connectionStatus": "online",
      "battery": 45,
      "batteryTimeRemaining": "~5 days remaining",
      "firmware": "v2.2.0",
      "desiredConfigVersion": "v2.3",
      "appliedConfigVersion": "v2.1",
      "configSynced": false,
      "lastSeen": "30 mins ago",
      "location": {
        "latitude": 33.4484,
        "longitude": -112.074
      },
      "createdAt": "2024-05-10T09:00:00Z",
      "updatedAt": "2024-12-20T10:00:00Z"
    }
  ],
  "members": [
    {
      "id": "member-1",
      "name": "Sarah Jenkins",
      "email": "sarah.j@hydro.co",
      "role": "admin",
      "scope": "Global Access",
      "status": "active",
      "lastActive": "Oct 24, 2023",
      "createdAt": "2023-01-15"
    },
    {
      "id": "member-2",
      "name": "Michael Chen",
      "email": "m.chen@hydro.co",
      "role": "site_manager",
      "scope": "North Reservoir",
      "scopeDetails": "+ 2 Pump Stations",
      "status": "active",
      "lastActive": "2 hours ago",
      "createdAt": "2023-02-20"
    },
    {
      "id": "member-3",
      "name": "James Doe",
      "email": "james.d@partner.inc",
      "role": "viewer",
      "scope": "Dam Unit 4 Only",
      "status": "pending",
      "createdAt": "2023-10-20"
    },
    {
      "id": "member-4",
      "name": "Emily Blunt",
      "email": "e.blunt@hydro.co",
      "role": "viewer",
      "scope": "All Sites",
      "status": "revoked",
      "lastActive": "Sep 12, 2023",
      "createdAt": "2023-03-10"
    },
    {
      "id": "member-5",
      "name": "Robert Fox",
      "email": "r.fox@hydro.co",
      "role": "site_manager",
      "scope": "South River Dam",
      "status": "active",
      "lastActive": "Yesterday",
      "createdAt": "2023-04-05"
    }
  ],
  "invites": [
    {
      "id": "invite-1",
      "email": "jane.doe@partners.com",
      "initials": "JD",
      "category": "External Vendor",
      "role": "technician",
      "scope": "North Reservoir",
      "sentDate": "Oct 24, 2023",
      "status": "pending"
    },
    {
      "id": "invite-2",
      "email": "m.khan@company.com",
      "initials": "MK",
      "category": "Internal Staff",
      "role": "viewer",
      "scope": "Global",
      "sentDate": "Oct 23, 2023",
      "status": "pending"
    },
    {
      "id": "invite-3",
      "email": "tech.support@example.com",
      "initials": "TS",
      "category": "Contractor",
      "role": "site_manager",
      "scope": "South Treatment",
      "sentDate": "Sep 12, 2023",
      "status": "expired"
    }
  ],
  "alerts": [
    {
      "id": "alert-1",
      "title": "Pressure Critical High",
      "message": "Pressure sensor reading 48 PSI exceeds critical threshold of 45 PSI. Immediate attention required.",
      "severity": "critical",
      "status": "unread",
      "context": "device",
      "source": {
        "id": "DEV-4412",
        "type": "device",
        "name": "Pressure Gauge #4412",
        "location": "North Reservoir - Zone A"
      },
      "dataSnapshot": [
        { "label": "Current Value", "value": "48.2", "unit": "PSI" },
        { "label": "Threshold", "value": "45.0", "unit": "PSI", "isThreshold": true }
      ],
      "timestamp": "2m ago",
      "receivedAt": "Today at 10:42 AM"
    },
    {
      "id": "alert-2",
      "title": "Connection Lost",
      "message": "Device #DEV-1029 has failed to report heartbeat for 3 consecutive intervals.",
      "severity": "warning",
      "status": "unread",
      "context": "device",
      "source": {
        "id": "DEV-1029",
        "type": "device",
        "name": "Sensor #DEV-1029"
      },
      "timestamp": "15m ago",
      "receivedAt": "Today at 10:29 AM"
    },
    {
      "id": "alert-3",
      "title": "Firmware Update Successful",
      "message": "Batch update v2.1 applied successfully to 12 devices in East Sector.",
      "severity": "info",
      "status": "read",
      "context": "system",
      "source": {
        "id": "system",
        "type": "system",
        "name": "System"
      },
      "timestamp": "2h ago",
      "receivedAt": "Today at 8:42 AM"
    },
    {
      "id": "alert-4",
      "title": "Low Battery Warning",
      "message": "Battery level dropped below 15% on Device #DEV-1199. Estimated 48h remaining.",
      "severity": "warning",
      "status": "read",
      "context": "device",
      "source": {
        "id": "DEV-1199",
        "type": "device",
        "name": "Sensor #DEV-1199"
      },
      "timestamp": "5h ago",
      "receivedAt": "Today at 5:42 AM"
    },
    {
      "id": "alert-5",
      "title": "Flow Rate Normalized",
      "message": "Flow rate returned to normal operating range (250 L/min) after spike.",
      "severity": "info",
      "status": "read",
      "context": "reservoir",
      "source": {
        "id": "pipe-b",
        "type": "reservoir",
        "name": "Main Pipe B"
      },
      "timestamp": "Yesterday",
      "receivedAt": "Yesterday at 3:15 PM"
    }
  ]
}
```

</details>

---

*Document generated: 2025-01-05*
*Source: jilaPortalFrontend mock data files*
