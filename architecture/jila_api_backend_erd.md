## Jila API Backend — Entity Relationship Diagram (Mermaid)

This ERD is derived from `docs/architecture/jila_api_backend_architecture_v_0 (3).md` (v0.3 hardened).

Anti-drift note:
- This ERD is a **derived visualization** for understanding relationships.
- The **only canonical database schema** (tables/enums/constraints) is:
  - `docs/architecture/jila_api_backend_data_models.md`

### How to read this (brief narrative)

This data model is intentionally built around a few **anti-drift primitives**. When reading the diagram, keep these meanings in mind:

- **`principals`**: a single canonical “actor / owner container” identifier.
  - Every **User** has exactly one **User Principal**.
  - Every **Organization** has exactly one **Org Principal**.
  - Anywhere you see `*_principal_id`, that’s a deliberate “no ambiguity” move: we’re avoiding scattered `user_id` + `organization_id` fields.

- **Ownership vs access (crucial distinction)**:
  - **Ownership** is modeled by `owner_principal_id` on the resource (e.g., a Reservoir is owned by a user-principal or org-principal).
  - **Access** (membership, sharing, delegation) is modeled only via **`access_grants`**.

- **`access_grants`**: the single table for “who can do what on which resource”.
  - `subject_principal_id` = who gets access.
  - (`object_type`, `object_id`) = what they get access *to* (ORG/SITE/RESERVOIR/SUPPLY_POINT/…).
  - `role` = the capability label (interpreted by the permission matrix in the architecture doc).

- **`tokens`**: the single table for short-lived or one-time secrets (OTP, password reset, invite).
  - Invites are represented as a token first; **acceptance materializes an `access_grants` row**.
  - Invite anti-theft binding:
    - If an invite token has `target_identifier` set and the caller is already authenticated, acceptance must bind to a user whose **verified identifier** matches it.
    - For org user onboarding (public invite acceptance), `email` must match `target_identifier` and the user must verify that email before the account becomes `ACTIVE` (see decision D-004).
  - Invite scope can be carried in `tokens.metadata` (for example `site_ids` for org invites).

- **`events`**: the canonical audit/outbox stream.
  - We prefer emitting Events over creating new “history tables” (e.g., SupplyPoint status history).

#### Concrete examples (map to the ERD)

- **Org membership**: a user joins an org when they have an `access_grants` row on `ORG:<org_id>` with role like `MANAGER`.
- **Reservoir sharing**: sender creates a `tokens` row (`INVITE` to `RESERVOIR:<reservoir_id>`); receiver accepts; system creates/updates `access_grants` on that reservoir.
- **Seller listings (v1)**: a principal can expose reservoirs as public listings only when:
  - `seller_profiles.status = ACTIVE`
  - the reservoir has at least one `reservoir_price_rules` row
  - the reservoir has a discoverable location
  - the seller explicitly toggled `reservoirs.seller_availability_status = AVAILABLE`
- **Orders (pricing snapshot)**: at `ORDER_CREATED`, the backend computes a **price snapshot** and stores it on the `orders` row (e.g., `price_quote_total` + `currency`). This snapshot does not change even if price rules change later.
- **Orders (v1 constraint)**: `seller_reservoir_id` is required for v1 instant orders; v1 does not support broadcast “request offers” without explicit seller selection.
- **Device pairing (v1, 1:1)**: attaching a device to a reservoir is explicit; if either side is already paired, the API returns a conflict (detach-first) to prevent silent reassignment.
- **SupplyPoint availability updates**:
  - Community updates are allowed for authenticated users (rate-limited) for `availability_status`.
  - If a SupplyPoint has an operator (`supply_points.operator_principal_id`) or an explicit grant exists, operator updates can carry stronger evidence semantics for availability (e.g., `VERIFIED` vs `REPORTED`).
  - Cached availability conflict resolution is evidence-prioritized (`SENSOR_DERIVED` > `VERIFIED` > `REPORTED`); weaker evidence cannot overwrite stronger cached availability.
  - `operational_status` is a separate field intended for closures/operations, typically set by operator/admin.
- **Telemetry ingestion (v1)**: telemetry for unregistered or unattached devices is discarded (no `reservoir_readings` row); emit a diagnostic event for audit/observability.
- **Reservoir location signals (v1)**: seller/mobile locations are stored as `reservoirs.location` and updated by PATCH (emits `RESERVOIR_LOCATION_UPDATED`).

> Note: `access_grants`, `tokens`, and `events` use **polymorphic references** (`object_type`/`object_id`, `subject_type`/`subject_id`) to avoid table explosion. Those polymorphic links are documented below the diagram.

```mermaid
erDiagram
  USERS {
    uuid id PK
    string phone_e164
    string email
    timestamp phone_verified_at
    timestamp email_verified_at
  }

  USER_SESSIONS {
    uuid id PK
    uuid user_id FK
    string client_type
    string refresh_token_hash
    uuid family_id
    timestamp expires_at
    timestamp revoked_at
  }

  ORGANIZATIONS {
    uuid id PK
    uuid primary_contact_user_id FK
  }

  PRINCIPALS {
    uuid id PK
    enum type
    uuid user_id FK
    uuid organization_id FK
  }

  ACCESS_GRANTS {
    uuid id PK
    uuid subject_principal_id FK
    enum object_type
    uuid object_id
    string role
    uuid granted_by_principal_id FK
    enum status
  }

  TOKENS {
    uuid id PK
    enum type
    uuid subject_principal_id FK
    string target_identifier
    enum object_type
    uuid object_id
    string proposed_role
    json metadata
    string token_hash
    timestamp revoked_at
  }

  ZONES {
    uuid id PK
    string name
  }

  SITES {
    uuid id PK
    uuid owner_principal_id FK
    uuid zone_id FK
  }

  SUPPLY_POINTS {
    uuid id PK
    uuid zone_id FK
    uuid operator_principal_id FK
    enum operational_status
    timestamp operational_status_updated_at
    enum availability_status
    enum availability_evidence_type
    timestamp availability_updated_at
  }

  RESERVOIRS {
    uuid id PK
    uuid site_id FK
    uuid owner_principal_id FK
    uuid supply_point_id FK
    enum seller_availability_status
    geopoint location
    timestamp location_updated_at
  }

  DEVICES {
    uuid id PK
    uuid reservoir_id FK
    string hardware_id
  }

  RESERVOIR_READINGS {
    int id PK
    uuid reservoir_id FK
    uuid device_id FK
  }

  SELLER_PROFILES {
    uuid principal_id PK
    enum status
  }

  RESERVOIR_PRICE_RULES {
    uuid id PK
    uuid reservoir_id FK
    string currency
    float min_volume_liters
    float max_volume_liters
  }

  ORDERS {
    uuid id PK
    uuid buyer_principal_id FK
    uuid target_reservoir_id FK
    uuid seller_reservoir_id FK
    enum status
    float requested_volume_liters
    float price_quote_total
    string currency
    timestamp buyer_confirmed_delivery_at
    timestamp seller_confirmed_delivery_at
    timestamp delivered_at
  }

  REVIEWS {
    uuid id PK
    uuid order_id FK
    uuid reviewer_principal_id FK
  }

  EVENTS {
    uuid id PK
    enum type
    enum subject_type
    uuid subject_id
  }

  ALERTS {
    uuid id PK
    uuid user_id FK
    uuid event_id FK
  }

  PLANS {
    string id PK
  }

  SUBSCRIPTIONS {
    uuid id PK
    uuid account_principal_id FK
    string plan_id FK
  }

  USERS ||--o| PRINCIPALS : "user principal"
  ORGANIZATIONS ||--o| PRINCIPALS : "org principal"
  USERS ||--o{ ALERTS : "receives"
  USERS ||--o{ USER_SESSIONS : "sessions"
  EVENTS ||--o{ ALERTS : "produces"

  PRINCIPALS ||--o{ ACCESS_GRANTS : "subject"
  PRINCIPALS ||--o{ ACCESS_GRANTS : "granted_by"
  PRINCIPALS ||--o{ TOKENS : "subject"

  PRINCIPALS ||--o{ SITES : "owns"
  ZONES ||--o{ SITES : "contains"

  ZONES ||--o{ SUPPLY_POINTS : "contains"
  PRINCIPALS ||--o{ SUPPLY_POINTS : "operates (optional)"

  SITES ||--o{ RESERVOIRS : "contains"
  PRINCIPALS ||--o{ RESERVOIRS : "owns"
  SUPPLY_POINTS ||--o{ RESERVOIRS : "associated (optional)"

  RESERVOIRS ||--o| DEVICES : "paired (0..1)"
  RESERVOIRS ||--o{ RESERVOIR_READINGS : "has"
  DEVICES ||--o{ RESERVOIR_READINGS : "reports"

  PRINCIPALS ||--o| SELLER_PROFILES : "seller (0..1)"
  RESERVOIRS ||--o{ RESERVOIR_PRICE_RULES : "prices"

  PRINCIPALS ||--o{ ORDERS : "buyer"
  RESERVOIRS ||--o{ ORDERS : "target (optional)"
  RESERVOIRS ||--o{ ORDERS : "seller (required in v1)"

  ORDERS ||--o{ REVIEWS : "review(s)"
  PRINCIPALS ||--o{ REVIEWS : "reviewer"

  PRINCIPALS ||--o{ SUBSCRIPTIONS : "account"
  PLANS ||--o{ SUBSCRIPTIONS : "plan"
```

### Polymorphic reference notes (anti-table-explosion)

- **`access_grants.object_type` + `access_grants.object_id`** points to one of:
  - `ORG` → `organizations.id`
  - `SITE` → `sites.id`
  - `RESERVOIR` → `reservoirs.id`
  - `SUPPLY_POINT` → `supply_points.id`
  - `ORDER` → `orders.id`
  - `DEVICE` → `devices.id`

- **`tokens.object_type` + `tokens.object_id`** is used for invites and points to the same set of objects as above (when `tokens.type = INVITE`).

- **`events.subject_type` + `events.subject_id`** points to:
  - `RESERVOIR` → `reservoirs.id`
  - `DEVICE` → `devices.id`
  - `ORDER` → `orders.id`
  - `SITE` → `sites.id`
  - `ACCOUNT` → `principals.id` (account container)
