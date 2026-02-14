## Jila – Platform Value Proposition Review Notes (Aligned to Grant/Investor Summary)

### 0. Scope and intended use

This document anchors product scope and domain concepts so that:
- The **architecture and schemas** stay aligned to the **grant/investor narrative**.
- The near-term product remains **deliverable**, while preserving a credible path to **utility-grade evidence**.

Initial geographic focus: **Luanda (Angola)**. The model should generalize to other Angolan provinces and similar intermittent-supply markets.

Utilities/public stakeholders are a **later commercial track** (captured here for grant alignment) and should not expand Phase A scope.

---

## 1. Problem context (Luanda / Angola)

Water access is defined by **chronic intermittence** and a split between **formal utility supply** and a large **parallel informal/tanker economy**.

Observed sector dynamics we must reflect in product claims and requirements:
- Only **~one-third** of Luanda residents have a direct household connection to the network; a large share relies on **standpipes**, **illegal connections**, and **tanker-truck supply**.
- The main utility loses roughly **~50%** of treated water as **Non-Revenue Water**, and recovers only **~one-third** of billed revenue — producing structural operating losses and persistent domestic debt.
- In peri-urban areas, tanker wholesale prices around **US$10–14 per m³** mean households can pay **~40–50×** the subsidized tariff.
- The informal chain is **expensive, unreliable, and often unsafe**: low-cost chlorination at filling points exists but is inconsistently applied, and untreated water can be sold.

This creates a structural “coping economy”:
- Households and institutions pay high financial/time costs to avoid running out.
- Sellers drive inefficiently due to demand uncertainty and lack of routing/dispatch signals.
- Utilities and funders lack **granular, independent** visibility into where intermittence is worst and whether interventions measurably improve service.

---

## 2. What Jila is

Jila is a **mobile-first water reliability platform** for markets with intermittent water supply, designed for low-power and low-connectivity environments.

It does three things:
1. **Monitor reservoirs** so households and organizations aren’t surprised by empty storage — with the UX centered on “**days of autonomy**” (how long water is likely to last) rather than raw liters.
2. **Connect buyers and sellers of water** in a transparent, simple way when refills are needed.
3. **Generate trustworthy evidence** on intermittence, refills, and coping behavior so organizations, utilities, and funders can plan, contest bills, and evaluate interventions.

Why “days of autonomy”:
- Users don’t typically think in liters; they think in **time-to-empty** (“When will we run out?”).
- Presenting the system as time-left is more intuitive and supports better decisions (refill timing, safety margin).
- **Implementation note:** “days of autonomy” is a UI-only helper; the client converts it to **liters** and submits
  `requested_volume_liters` to the API (the API is volume-based).
- **Portal alignment note:** the v1 backend contract is explicitly allowed to expose **portal-friendly summary fields**
  (e.g., thresholds, risk/freshness, connectivity state, counts) so HQ users can triage multi-site risk without the UI
  fabricating data. This does not change the “orders are liters” invariant.
- **Credibility guardrail (trust-critical):** “days” is only high-value UX if we can compute it credibly. Estimating
  time-to-empty requires a consumption model (e.g., household size, historical usage/seasonality, safety margin, and
  data quality/availability). If we guess wrong, we can cause **over-ordering** (wasted money) or **under-ordering**
  (running out of water) — both directly undermine user trust in the platform.
- **Backend modeling note:** consumption-model inputs that drive time-to-empty are modeled **per site** (not per login
  user). In the API data model, these inputs live in `site_consumption_profiles` (keyed by `sites.id`) so orgs can have
  different profiles per site and household accounts can use their selected site.

The device is the core product:
- **Device + app** provide precise, automatic monitoring and reliable refill triggers.
- **Marketplace + evidence layer** make the device more valuable, widen access, and create additional revenue (subscriptions, commissions, later data products).

The platform must also work in **manual/community mode (no device)** so it does not become a “rich person’s app” and so it can collect useful baseline data before device penetration is high.

---

## 3. Customer segments (logical groups)

We keep segments defined by interaction patterns (not personas).

### 3.1 Households & small sites (single-site users)
- Mobile-app first.
- Often start in manual mode; upgrade to devices when feasible.
- Jobs: avoid dry reservoirs; order water predictably; reduce emergency buying.

### 3.2 Professional sellers (tanker trucks + fixed informal sellers)
- Mobile-app first.
- Jobs: reach real demand; reduce wasted trips; smooth utilization (including residual/end-of-day water).
- May or may not have devices (device is optional at v1).

### 3.3 Multi-site organizations (enterprise/NGO/bank/telco)
- Field operators use the app; HQ uses a portal.
- Jobs: see risk across sites; plan refills; justify budgets; contest suspicious bills; coordinate operations.

### 3.4 Community SupplyPoints and informal access points
- Public standpipes, boreholes, kiosks, informal corners.
- Goal at Phase A: **reduce time poverty** by mapping and basic availability status (informational first) via community `SupplyPoints`.

### 3.5 Utilities and public stakeholders (later track)
- Primary interest: aggregated, anonymized **zone-level** analytics and evidence packs.
- Rarely interact at individual-reservoir level.

---

## 4. Product phasing and scope control

### Phase A — Core reliability + marketplace (v1)
- Reservoir monitoring (manual + device).
- Alerts and basic history.
- Marketplace ordering and fulfillment logging.
- Community `SupplyPoints` mapping + simple availability updates (plus operational closures when applicable).

### Phase A non-goals (explicit guardrails)
These are intentionally **out of scope** for Phase A to keep v1 shippable and prevent architecture drift:
- No payments/billing engine (subscription changes are admin/webhook-driven; no checkout UX).
- No OAuth/OIDC social login endpoints (see Decision D-025).
- No “request offers” marketplace flow (offers/broadcast routing is future work).
- No auto-refill rule engine (explicitly future; requires its own safety constraints).
- No unauthenticated Firestore browsing (public map/list is served by HTTP public endpoints only).
- No mirroring of time-series history or raw telemetry to Firestore (Firestore is “latest/current state” only).
- No utility integrations (Phase C only; Phase A/B focus on integrity + exports, not enterprise billing).

### Phase B — Evidence pack for utilities and funders
- Aggregated indicators of intermittence/outages/tanker reliance.
- Simple dashboards and exportable reports (monthly/quarterly “evidence packs”).
- Structured exports / APIs for funder reporting and early utility pilots.

### Phase C — Utility integration (optional)
- Deeper integration with metering/billing where utilities are ready.
- Use Jila’s edge-level data to complement NRW programs and performance-based contracts.

**Scope guardrail:** Jila is not a billing system in Phase A/B. The “utility-grade” aspect is the **data integrity + metric definitions + exports**, not enterprise complexity.

---

## 5. Simplified domain model (core nouns)

We anchor the system on **Reservoirs** (storage/measurement/monetization) and **SupplyPoints** (community discovery surface for procurement locations).

### 5.1 Reservoir (core entity)
A Reservoir is where water is stored for consumption and/or sale.

Conceptual attributes:
- Identity: `id`, `site_id` (internal grouping), `owner_principal_id`
- Physical: `capacity_liters`, `geometry`, `position`, `usage_type`
- Monitoring: `device_id` (optional), `last_level_pct`, `last_seen_at`, `last_battery_pct`
- Rules: `safety_margin_pct`, alert thresholds, optional auto-refill preferences (top tier)

Any reservoir can be:
- Consumer-only
- Seller-only
- Mixed (reserve for owner + sell surplus)

### 5.2 SupplyPoint (what buyers see in community mode)
A SupplyPoint is anything that appears on the map/list as a place to procure water (informational/discovery surface).

Types:
1. **Community SupplyPoint** (informational first)
   - Standpipes, boreholes, kiosks, informal corners.
   - Crowdsourced/managed data: hours, availability status, reliability indicator.

2. **Seller reservoir listing** (transactional; marketplace)
   - A publicly listed Reservoir owned by a seller principal.
   - Used for in-app ordering and matching; pricing comes from seller-set price rules on the reservoir.

Shared conceptual attributes:
- `location` (coordinates), `label`
- `status` (where applicable): available / low / none / closed (with timestamp + source)

Seller listing attributes (reservoir-based):
- `owner_principal_id` (user or organization principal)
- `mobility = FIXED|MOBILE`
- seller-set `price_rules`
- explicit seller availability toggle
- Optional: `water_source_type` and `treatment_claims` (capturable only if practical)

### 5.3 Seller model (no fleet abstraction at v1)
A seller is a principal with an active Seller Profile and ≥1 Reservoir that is publicly listed for sale.
- Multiple trucks/reservoirs → multiple seller reservoir listings.
- Device optional (seller can be manual or device-backed).

---

## 6. Marketplace behavior (v1)

Pricing principles:
- Sellers set prices; no dynamic/surge pricing.
- Price may vary by volume and a flat delivery fee (v1); distance and urgency are out of scope for Phase A.
- Jila’s role: transparency, matching, and later commission.

Core flow:
1. Buyer selects a target reservoir (or “no target reservoir”).
2. Jila computes requested volume:
   - Manual reservoir: slider + capacity.
   - Device reservoir: actual level + chosen target (fill-to-full, days of autonomy, etc.).
   - Apply configured safety margin to reduce underestimation.
3. Buyer selects a seller reservoir listing (or uses a simple “request” mode in future).
4. Seller accepts/rejects.
5. Both confirm delivery.

Minimum fulfillment logging (must exist at v1):
- Order created/accepted/delivered timestamps.
- Delivered volume (reported; later reconcilable).
- Reservoir/site linkage (where applicable).
- Seller identity + seller reservoir listing.

This logging is required because it becomes the dataset for:
- Seller utilization (short term).
- Evidence of tanker dependence and refill behavior (Phase B).

---

## 7. Monitoring modes and data collection

### 7.1 Manual / community mode (no device)
Purpose:
- Enable non-device users.
- Collect baseline usage/refill behavior.
- Funnel to device upsell where economically feasible.

Capabilities:
- Define reservoirs (capacity, type).
- Manual refill logs + level slider.
- Marketplace ordering based on estimates (+ margin).
- Prompts for periodic updates.

Explicit limitation:
- Manual mode is lower-precision and lower-automation than device mode.

### 7.2 Device mode
Capabilities:
- Automatic level readings and device health.
- Reliable alerts (threshold + trend).
- Accurate refill volume calculation.
- Telemetry that supports derived events and evidence packs.

---

## 8. Evidence and analytics (minimum viable but “utility-grade enough”)

Jila’s analytics are an evidence engine, not generic reporting.

Minimum scope:
1. **Telemetry retention**
   - Store raw readings + key derived states by subscription tier.

2. **Derived events with stable definitions**
   - Refill detected.
   - Outage periods (where inferable).
  - Availability % (per reservoir/site, later per zone).
   - Explicitly mark inference confidence when data is sparse.

3. **Exportable formats**
  - CSV exports: readings, derived events, reservoir/site metadata.
  - PDF/HTML summaries per reservoir/site over a chosen period (monthly by default).

4. **Integrity and transparency**
   - Data gaps explicitly shown (offline periods, missing readings).
   - Metric dictionary: stable definitions published in-product.

This is sufficient for organizations to justify budgets and contest bills, and for funders/utilities to evaluate improvement programs without turning Jila into a metering/billing stack.

---

## 9. Utilities and public stakeholders (later track)

Utilities/funders buy **aggregated insights**, not devices.

Key concepts:
- **Zone coverage strategy:** deploy devices across representative households/organizations in distribution zones.
- **Zone indicators:** intermittence index, outage frequency/duration, tanker reliance proxies, spatial anomalies.
- **Evidence packs:** before/after comparisons tied to interventions and time windows.

---

## 10. Market direction thesis (what changes over the next decade)

Expected shifts (Angola-aligned):
1. **Partial displacement of the most expensive tanker dependence** as infrastructure projects and operational reforms improve service unevenly.
2. **Formalization/regulation of informal supply** (registration, basic quality rules, simple reporting) rather than elimination.
3. **Digital performance management** for utilities and funders (benchmarks, performance-based contracts) requiring granular evidence.

Jila’s positioning:
- Short term: monetize reliability + marketplace in the parallel economy.
- Medium term: sell evidence packs to donors/utilities.
- Long term: become a verification/coordination layer for performance-based contracts.

---

## 11. Product implications (high-level requirements)

These are the high-level requirements that should shape architecture and schemas:

### 11.1 Device + telemetry
- Low-power, intermittent connectivity, buffering.
- Readings + device health.
- Documented event derivation rules.

### 11.2 App + portal
- Household UX centered on “My reservoirs”.
- Org portal supports multi-site dashboards, filters, and exports.
- Basic access control (organization + reservoir access) is required.

### 11.3 Marketplace
- Seller profiles, service area, capacity, price rules.
- Order lifecycle + delivery confirmation.
- Persistent linkage between orders and reservoirs/sites when available.

### 11.4 Community SupplyPoints
- Entity model with type, location, hours, and status.
  - SupplyPoints are informational/discovery surfaces; they do not carry monetized pricing rules.
- Status updates with provenance + rate limiting.
- Reliability indicators derived from update history (captured as Events to avoid extra “history tables” drift).

### 11.5 Aggregation readiness
- Models must support grouping by neighborhood/zone/administrative area.
- Phase B dashboards/exports should be buildable primarily from Phase A data.

---

## 12. Naming clean-up and retirements

- Use **SupplyPoint** (community discovery surface) as the unified concept for map/list procurement points.
- Retire “impact-focused seller” as a distinct domain concept.
- Keep the core data model anchored on:
  `User`, `Organization`, `Principal`, `AccessGrant`, `Token`, `Site`, `Reservoir`, `Device`, `SupplyPoint`, `SellerProfile`, `ReservoirPriceRule`, `Order`, `Review`, `Event`, `Subscription`.
- Avoid additional layers unless they express clear product value; prefer reusing `Principal` + `AccessGrant` + `Token` + `Event` as the platform primitives to reduce drift.

