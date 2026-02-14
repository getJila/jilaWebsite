# Jila Water Intelligence Framework v2.0  

**Master Document (Stationary + Mobile, Full Telemetry Assumption)**

**Version:** 2.0  
**Status:** Draft (narrative-expanded plain English; technical definitions preserved)  
**Primary sources integrated:**  

- *Angola Household Water Modeling v1.5*  
- *Jila Water Tracker v0.1*  

---

## 1. Executive Vision: The Closed-Loop Water Economy

Cities like Luanda do not have one water system. They have two systems running at the same time. The first system is the **unreliable grid**, where water arrives through pipes but does not arrive consistently. The second system is the **informal market**, where trucks compensate for grid failures by selling and delivering water directly to households and businesses.

Jila is designed to measure both systems as **one connected economy**. When we observe only households, we can see that people are suffering, but we cannot see whether the market can respond, how efficiently it responds, or where supply capacity is being lost. When we observe only trucks, we can see activity and movement, but we cannot quantify how much of that activity corresponds to real household stress or real service reliability.

Jila closes this gap by combining:

- **Demand sensing (households and stationary tanks):** The tank level tells us whether water is arriving, how fast it is being consumed, and how close the household is to running out.
- **Supply tracking (trucks and mobile sellers):** The truck route and the truck tank level tell us where water is being delivered, how much is being delivered, and what is being lost during transport.

**Core value statement:** We can only reduce the “poverty penalty” and improve distribution planning when we can see both the unmet need (demand) and the real delivery performance (supply) in the same data model.

---

## 2. Scope and Working Assumptions

### 2.1 What this framework covers

This framework covers two intelligence nodes and their integration:

- **Part A — Consumer Node (Stationary Intelligence):** Household or facility tanks, where we infer reliability, run-out risk, and usage patterns.
- **Part B — Provider Node (Mobile Intelligence):** Water trucks, where we infer delivery behavior, refill behavior, and operational efficiency.
- **Part C — Integrated Ecosystem Insights:** City-level indicators that explain how the grid and the market interact, and where intervention will have the highest impact.

### 2.2 The key decision in v2.0

For v2.0, we assume that mobile devices mounted on trucks provide **water level telemetry plus GPS** as standard. This matters because it lets us define delivery events based on **real volume delivered**, not based on stop duration alone.

This decision changes the narrative from “we think a delivery happened because the truck stopped” to “we can confirm a delivery happened because we can observe the truck tank level dropped while stationary at a location.”

### 2.3 Backward compatibility (GPS-only mode still supported)

If truck water level telemetry is missing in a future deployment, the system can still run in a degraded mode that uses **GPS proxies** (stop duration patterns and place clustering). However, the metrics in this document are defined as if volumetric telemetry exists, because that is the target operating state.

---

## 3. Shared Definitions (Written Once, Used Everywhere)

This section defines concepts that appear repeatedly across both stationary and mobile analytics. The goal is that a reader can understand these terms immediately, without needing to read the full document first.

### 3.1 Autonomy (stationary tanks)

**Plain meaning:** Autonomy is the number of days a household can keep using water if no new water arrives. A higher autonomy means the household is more buffered against outages. A low autonomy means the household becomes vulnerable very quickly when the grid stops or when deliveries are delayed.

**Technical definition:**  
`Autonomy_days = Capacity_L / AvgDailyConsumption_Lpd`

### 3.2 Intermittence (pipe reliability; stationary)

**Plain meaning:** Intermittence describes how inconsistent the pipe supply is. If water arrives only a few hours per day, or arrives in short unpredictable bursts, intermittence is high. If water arrives regularly and for long periods, intermittence is lower. Intermittence is not a “feelings” metric; it is computed from observed supply events in the tank level trace.

**Technical definition:** Computed from **supply events** inferred via sustained positive level changes (after smoothing and resampling), with fragmentation and coverage metrics.

### 3.3 Elasticity near empty (stationary demand behavior)

**Plain meaning:** Elasticity captures how people change their water usage when the tank is low. Many households ration water when they feel they may run out, so their consumption drops as the level approaches empty. Elasticity tells us whether users are “forced to conserve,” which is a strong signal of stress.

**Technical definition:**  
`Elasticity = mean(consumption | level<20%) / mean(consumption | level≥20%)`

### 3.4 Run-out risk (service safety; stationary)

**Plain meaning:** Run-out risk tells us how often a household is near empty, and therefore how often the household is at risk of having no water at all. A household can have “some water sometimes” and still be at high run-out risk if the tank repeatedly hits critical lows.

**Technical definition:**  
`RunOutProb = hours(level≤5%) / observed_hours` (plus episode counting)

### 3.5 Poverty penalty (economic inequality; stationary + integrated)

**Plain meaning:** The poverty penalty is the idea that households without reliable pipes pay far more per liter than households that are connected to a functioning network. The same water becomes dramatically more expensive when purchased through trucks. This is not only a cost problem; it also becomes a behavior problem, because higher price forces households to consume less than they need.

**Technical definition:**  
`PovertyPenaltyFactor = InformalMarketPrice / UtilityPrice`  
(Default prior used in v1.5: ~$15/m³ vs ~$0.25/m³.)

### 3.6 Suppressed demand (stationary + integrated)

**Plain meaning:** Suppressed demand means people use less water than they need because water is too expensive or too difficult to obtain. You should not interpret low consumption as “low need.” In many contexts, low consumption is evidence of constraint rather than comfort.

**Technical definition:** Observed consumption below reference minimum levels under conditions of limited affordability and irregular supply.

### 3.7 Delivery event (mobile, volumetric-first)

**Plain meaning:** A delivery event is a stop where the truck actually hands over water. In v2.0, we do not rely on stopping behavior alone. We define a delivery because we can observe the truck tank losing water while stationary at a location.

**Technical definition:** Stop episode with net negative `ΔV_stop` above a noise threshold.

### 3.8 Refill/load event (mobile, volumetric-first)

**Plain meaning:** A refill event is a stop where the truck replenishes its tank, typically at a standpipe, depot, or other source. We define it because we can observe the truck tank level rising during a stop.

**Technical definition:** Stop episode with net positive `ΔV_stop` above a noise threshold.

---

# Part A — The Consumer Node (Stationary Intelligence)

## A1. Segmentation rules (when metrics apply)

Not all stationary devices represent the same reality. Some tanks are primarily filled by the pipe network. Others are filled mainly by trucks. We do not want to calculate “intermittence” for a tank that is not primarily pipe-filled, because that would produce misleading results.

- **Pipe-connected (intermittence metrics apply):** 3760, 430, B2C  
- **Truck-refill only (intermittence not applicable):** 49F0

**Plain interpretation:** Intermittence is a metric about the pipe network. If the pipe network is not supplying that tank, then intermittence is not the right lens.

## A2. Stationary metrics (plain language first, technical retained)

### A2.1 Intermittence metrics (pipe-connected only)

These metrics describe *how often the grid works* and *how fragmented the supply is*:

- **Total supply hours:** How many hours within the observation window the tank shows evidence of pipe inflow.
- **Mean supply duration:** When supply occurs, how long it typically lasts.
- **Supply fragmentation index:** Whether supply is delivered in many short bursts or fewer long intervals.
- **Daily supply coverage:** The fraction of each day with supply (hours/day divided by 24).

### A2.2 WASH service risk metrics

These metrics translate raw tank telemetry into human-relevant service outcomes:

- **Run-out probability:** How often the tank is at critical low levels.
- **Intermittence severity index:** How often daily minimum levels fall below safety thresholds.
- **Consumption estimate:** Daily liters consumed, inferred from negative deltas after smoothing (with care around refill periods).

## A3. Archetypes and the meaning of behavior

We retain the archetype framing because it prevents a common analytics mistake: assuming that every household is optimizing the same way.

- **Archetype A (Urban Connected / higher income):** Has the ability to store, and may increase consumption when water is available. Their stress is mostly about timing and unpredictability.
- **Archetype C (Informal / market-dependent):** Faces high prices, so their usage may remain low even when water is available. Their stress is often affordability-driven, which shows up as suppressed demand.

---

# Part B — The Provider Node (Mobile Intelligence)

## B1. Why mobile intelligence is different

Trucks are not just “moving objects.” They are the logistics layer that compensates for a failing grid. If we want to improve the water economy, we must be able to answer simple questions such as:

- Where does the truck get its water?
- Where is the water being delivered?
- How much water is being delivered per stop and per day?
- How much time is being wasted in queues and refills?
- How much water disappears during transport (leakage, theft, spillage)?

Without volumetric telemetry, we can approximate some of these answers using stop behavior. With volumetric telemetry, we can measure them directly.

## B2. Mobile abstraction layers (retained structure; explained more clearly)

### Layer 1 — Raw telemetry

**Plain meaning:** This is the raw stream of GPS points and sensor readings that arrives from the tracker. It can be irregular and may contain gaps.

**Minimum fields (v2.0):**

- `timestamp_utc`
- `latitude`, `longitude`
- optional: `speed`
- recommended: `device_id`
- **required for v2 metrics:** `truck_tank_level_pct` (or liters), plus calibration to liters

### Layer 2 — Movement state

**Plain meaning:** We turn a stream of points into a clear signal: “moving” vs “not moving.” This lets us detect stops, which are the building blocks of deliveries and refills.

**Technical rule (retained default):**  
`MOVING` if `speed_kmh ≥ 5` OR `step_distance_m ≥ 200`, else `STATIONARY`

### Layer 3 — Stop episodes

**Plain meaning:** A stop episode is not a single point. It is a period of time where the truck remains in the same place. Stop episodes are where deliveries happen, refills happen, and operational delays happen.

**Stop episode outputs:**

- Start time, end time, duration
- Mean location
- Context: weekday patterns, hour-of-day patterns

**Simulator implementation note (v1.1):** Synthetic stationary telemetry encodes hour-of-day and
weekday behavior through typed per-device dynamics vectors (`hourly_weights`,
`hourly_probability_multipliers`, `hourly_volume_multipliers`, weekday multipliers) evaluated in
UTC.

### Layer 4 — Significant places

**Plain meaning:** If a truck stops repeatedly in the same area, that area becomes a meaningful node in the network. Some of these nodes will be bases, some will be refill depots, and many will be client locations.

### Layer 5 — Operational intelligence

**Plain meaning:** This layer converts “where and when the truck moved” into business-relevant metrics: deliveries performed, liters delivered, time wasted, distance efficiency, and losses.

---

## B3. Mobile metrics (volumetric-first; plain language emphasized)

### B3.1 Event detection logic (what we are really doing)

For each stop episode, we look at the truck tank level at the start and at the end. We then ask a simple question: did the truck gain water, lose water, or stay roughly the same?

- If the truck tank level **increases**, that stop is treated as a **refill/load event**.
- If the truck tank level **decreases**, that stop is treated as a **delivery event**.
- If it stays similar, the stop may be a rest stop, traffic, admin, or queue with no water transfer.

During movement segments, we look for drops that happen while moving. If meaningful drops appear while moving and cannot be explained by normal sensor noise, we treat them as candidate losses.

### B3.2 Primary mobile KPIs (v2.0)

#### (1) True delivery events

**Plain meaning:** This counts actual deliveries, not just stops. It also tells us how much water was delivered at each stop, which is the most important unit for market modeling.

**Technical output per event:** `volume_delivered_L`, `place_id`, `timestamp`, `dwell_time`, confidence.

#### (2) Liters per kilometer (route efficiency)

**Plain meaning:** This tells us how efficiently a truck converts driving into delivered water. A low liters-per-kilometer value usually means long distances for small deliveries, poor routing, or a weak customer density.

**Technical definition:**  
`L_per_km = total_delivered_L / total_distance_km`

#### (3) Refill efficiency (time productivity at source)

**Plain meaning:** This tells us how much water a truck can load per minute at a refill location. Low refill efficiency often means queues, pump limitations, or operational friction.

**Technical definitions:**  

- `Liters_Loaded = Σ(ΔV_stop positive)`  
- `Load_Rate_L_per_min = Liters_Loaded / time_at_refill_minutes`

#### (4) Market liquidity (district per day)

**Plain meaning:** This tells us the actual volume of water the informal market mobilizes into a district each day. This is the foundation for “how much the city is relying on trucks.”

**Technical definition:**  
`Liquidity_district_day = Σ delivered_L within district per day`

#### (5) Mobile non-revenue water (loss during transit)

**Plain meaning:** This captures water that disappears between refill and delivery. In the mobile economy this can be leakage, theft, spillage, or unlogged offloads.

**Technical definitions:**  

- `NRW_mobile_L = −Σ(ΔV while MOVING where ΔV_move < −τ_loss)`  
- `NRW_mobile_rate = NRW_mobile_L / total_loaded_L`

#### (6) Reliability and downtime (still important even with level)

**Plain meaning:** We want to know whether a truck is consistently operational, or whether it frequently disappears for days. This matters for market reliability, not just data quality.

We keep two concepts separate:

- **Operational downtime:** the truck is not delivering and not moving.
- **Data downtime:** the telemetry is missing.

---

## B4. Place classification (retained; now easier to justify)

**Plain meaning:** A “place” is only useful if we can explain what it represents. We classify places because different place types drive different policy and product actions.

Retained place types:

- `BASE_PRIMARY`, `BASE_SECONDARY`, `CLIENT`, `REFILL_DEPOT`, `DOWNTIME_EVENT`, `OTHER_UNCERTAIN`

**v2 evidence upgrade:** In v2, classification becomes more reliable because we can use water transfer signatures:

- Refill depots show repeated **positive** volume changes.
- Client locations show repeated **negative** volume changes.
- Bases show long overnight dwell with little or no transfer.

---

# Part C — Integrated Ecosystem Insights

## C1. The “Invisible Map” (where the city is actually stressed)

**Plain meaning:** Many water-stressed neighborhoods do not show up in official maps. However, truck behavior creates a shadow map of stress. If trucks repeatedly deliver large volumes to a cluster of places, that cluster is revealing a structural dependency.

In practical terms:

- Heavy truck delivery clusters often indicate **grid failure** or **affordability-driven dependence**.
- When we have stationary devices nearby, we can separate those causes:
  - High intermittence + heavy delivery → grid failure cluster.
  - Moderate intermittence + heavy delivery → affordability / suppressed demand / service avoidance.

## C2. Price verification (if prices are recorded)

**Plain meaning:** If we log truck selling prices (even imperfectly), we can stop arguing about assumed costs. We can measure the real price burden and relate it directly to household stress and consumption suppression.

Operational outputs:

- District-level price distributions
- Poverty-penalty verification against observed transactions
- Identification of price spikes during prolonged grid failures

## C3. Resilience scoring (how “flexible” the city is)

**Plain meaning:** A resilient city is one where the grid supplies most demand reliably, and the market fills gaps without imposing extreme cost burdens. A fragile city is one where the market becomes the dominant supply mechanism.

**Technical indicator (simple but interpretable):**

- `GridFlow_L = Σ stationary inflows`
- `TruckFlow_L = Σ mobile deliveries`
- `ResilienceRatio = GridFlow_L / (GridFlow_L + TruckFlow_L)`

Interpretation:

- Closer to 1 → grid-dominant
- Closer to 0 → market-dominant

---

# 4. Data Processing Pipelines (Preserved, Now Split Cleanly)

## 4.1 Stationary pipeline (reproducible workflow)

**Plain meaning:** The stationary pipeline turns messy device telemetry into stable hourly signals, then derives consumption and supply events from those signals.

Retained steps:

1) Load raw CSV; parse timestamps as UTC  
2) Remove invalid rows (e.g., out-of-range measurements)  
3) Convert percent to liters using capacity  
4) Apply device-specific windows  
5) Resample to hourly median; smooth with rolling median  
6) Compute demand (negative deltas) and supply (positive deltas)  
7) Apply segmentation rules (pipe vs truck)  
8) Compute metrics (intermittence, autonomy, elasticity, run-out, economic burden)

## 4.2 Mobile pipeline (GPS foundation + volumetric extension)

### 4.2.1 GPS foundation (retained)

**Plain meaning:** This converts GPS points into stops, places, and activity patterns, even if volume is missing.

Steps retained:

- Movement classification
- Stop episode generation
- DBSCAN place clustering
- Place classification
- Operational outputs (activity index, downtime, territory footprint)

### 4.2.2 Volumetric extension (v2 default)

**Plain meaning:** This adds the missing piece: the water itself. It converts stops into deliveries and refills, and movement into loss detection.

Steps:

1) Calibrate truck level % → liters  
2) Denoise the level series (rolling median; outlier rejection)  
3) Compute `ΔV_stop` per stop episode and classify events  
4) Compute `ΔV_move` per movement segment for loss detection  
5) Aggregate: deliveries/day, liters/day, liters/km, refill productivity, district liquidity, NRW-mobile

---

# 5. Unified State Accounting (Why the math is coherent)

## 5.1 Stationary conservation (tank state)

**Plain meaning:** The tank is a storage container. It goes up when water arrives and goes down when water is used. This is simple, but extremely powerful because it lets us detect supply reliability from a single sensor.

**Technical form:**  
`S(t+1) = clamp(S(t) + Inflow(t) − Demand(t), 0, Capacity)`

## 5.2 Mobile conservation (truck state)

**Plain meaning:** The truck is also a storage container, but it moves through the city. It gains water when it refills, loses water when it delivers, and may lose water unintentionally while moving. This is exactly what we need to model the informal market as a system.

**Technical form:**  
`TruckV(t+1) = clamp(TruckV(t) + Load(t) − Deliver(t) − Loss(t), 0, TruckCapacity)`

---

# 6. Baseline Constraints and Update Protocol (What to do when data improves)

## 6.1 Known constraints (retained)

**Plain meaning:** Early datasets often have gaps and may oversample stationary time. This does not invalidate the analysis, but it changes what we can confidently infer about routes and timing.

Retained observations:

- Daytime operations dominate; weekday bias
- Movement is under-sampled; stop inference stronger than route reconstruction

## 6.2 When to recalibrate (retained triggers)

Recalibrate thresholds and models when:

- You have at least three trucks with comparable data quality, or
- Moving sampling improves significantly, or
- Refill depots can be confirmed with high confidence

---

# 7. High-ROI Next Extensions (Kept, but stated plainly)

## 7.1 Stationary extensions

- Capturing household size improves per-capita impact modeling.
- Logging prices turns poverty-penalty assumptions into measurable distributions.
- Adding water quality sensors creates a pathway from quantity reliability to safety reliability.

## 7.2 Mobile extensions

- Higher reporting frequency while moving (1–3 minutes) improves route reconstruction.
- Pump activation signals turn refills and deliveries into high-confidence labeled events.
- Motion/ignition sensors reduce ambiguity between downtime and low reporting.

---

## 8. What this master document is meant to achieve

This document is meant to be a shared language. A reader should be able to open it, read one section, and understand what the metrics mean without needing to “hold the entire framework in their head.”

It provides:

- A clear explanation of why stationary and mobile intelligence must be combined
- Plain English descriptions that tell a complete story, not just keywords
- Technical definitions that stay stable and computable
- Separate processing pipelines that remain reproducible
- A volumetric-first mobile model that supports real delivery volume and logistics optimization

---

## 9. Implementation mapping (JilaAPI post-v1 analytics)

This section maps WIF v2.0 concepts to implemented backend surfaces so the framework stays operational and testable.

### 9.1 Stationary node mapping

- Raw + typed history:
  - `device_telemetry_messages` (raw payload flight recorder)
  - `reservoir_readings` (typed level/volume time series)
- Derived stationary read models:
  - `stationary_hourly_series`
  - `stationary_supply_events`
- Windowed metrics outputs:
  - `reservoir_metrics_windows`
  - `site_metrics_windows`
  - `org_metrics_windows`
  - `zone_metrics_windows`

### 9.2 Mobile node mapping

- GPS extraction from telemetry payload:
  - `device_location_points`
- Stop + event classification:
  - `mobile_stop_episodes` (`DELIVERY|REFILL|DOWNTIME|UNKNOWN`)
- Significant places:
  - `mobile_places` (`BASE|REFILL_DEPOT|CLIENT_CLUSTER|UNKNOWN`)

### 9.3 Integrated ecosystem mapping

- Grid/truck interaction metrics are materialized in windowed metrics tables:
  - `pipeflow_liters`
  - `truckflow_liters`
  - `resilience_ratio`
- Zone-level integrated reads:
  - `GET /v1/zones/{zone_id}/analytics`

### 9.4 API + operations mapping

- Windowed analytics APIs:
  - `GET /v1/reservoirs/{reservoir_id}/analytics`
  - `GET /v1/sites/{site_id}/analytics`
  - `GET /v1/accounts/{org_principal_id}/analytics`
  - `GET /v1/zones/{zone_id}/analytics`
- Mobile analytics APIs:
  - `GET /v1/devices/{device_id}/mobile/stops`
  - `GET /v1/devices/{device_id}/mobile/places`
- Exports + diagnostics:
  - `POST /v1/analytics/exports`
  - `GET /v1/internal/diagnostics/analytics`
- Compute mode:
  - Outbox-driven near-real-time consumer (`analytics_consumer`) on `RESERVOIR_LEVEL_READING`
  - Scheduled place clustering job

### 9.5 Simulator/generator mapping (archetype-driven demos)

To support demonstrations while device rollout scales, Jila includes a synthetic telemetry simulator that
reuses production ingestion logic and metric pipelines.

- Control surface:
  - CLI + scenario files (no new HTTP route in v1)
  - commands: `validate`, `dry-run`, `bootstrap`, `run`
- Ingestion alignment:
  - Live mode publishes MQTT telemetry on `devices/{device_id}/telemetry`
  - Bootstrap mode generates historical telemetry by calling ingestion internals with controlled `received_at`
  - No direct writes to analytics read-model tables
- Sequence continuity:
  - Monotonic per-device sequence state persisted in `.tmp/synthetic_sim_seq_state.json`

Built-in v1 archetype profiles:

- `stationary_archetype_a`: regular supply windows, higher buffer behavior
- `stationary_archetype_c`: fragmented supply, stronger near-empty demand suppression
- `mobile_high_efficiency`: dense delivery behavior, low transit loss
- `mobile_fragmented_high_loss`: fragmented operations, higher transit loss

These simulator profiles are expected to preserve relative directional outcomes used in demos:

- A vs C:
  - A lower `runout_prob` tendency
  - C higher `supply_fragmentation_index` tendency
- Mobile profiles:
  - high-efficiency higher `liters_per_km`
  - fragmented/high-loss higher `mobile_nrw_liters`

---

## 10. Metrics Implementation Roadmap (Summary)

This table tracks the implementation status of every framework metric within the JilaAPI analytics stack (`app/modules/analytics/`). Use it to decide what to implement next or where to revise existing logic.

### 10.1 Key decision context (scope + terminology)

This section captures the decisions required to keep metric meaning consistent across **households (stationary)**, **trucks (mobile)**, and **integrated zone insights**.

1) **Pipe-connected gating (new canonical rule)**

- A reservoir has a boolean attribute `is_pipe_connected`.
- If `is_pipe_connected = false`, then **pipe-network reliability metrics are not applicable** and must not be shown as if they describe grid behavior.
- Pipe-network reliability metrics include (at minimum): **Intermittence / supply availability** measures derived from inflow events (e.g., `supply_hours`, `supply_fragmentation_index`, daily supply coverage, intermittence severity).
- Mobile reservoirs (truck tanks / `mobility=MOBILE`) are **never pipe-connected** for the purposes of intermittence.

2) **Terminology: “Grid flow” → “Piped-network inflow”**

- The concept formerly labeled “GridFlow” in earlier drafts should be interpreted and communicated as:
  - **Piped-network inflow** = water arriving via the piped network into a pipe-connected stationary reservoir.
- Analytics surfaces use the field name `pipeflow_liters`; meaning is piped-network inflow.
- When `is_pipe_connected = false`, this value should be treated as **not applicable** (or explicitly zeroed/nullable once implemented).

3) **Attribution of inflow source (separate work package)**

- Determining whether an observed reservoir inflow came from **pipe vs truck vs other** requires an inference layer.
- That inference logic is not fully specified in v2.0 and will be carved out as a separate work package (see 10.3).

**Legend:** ✅ Full — computed, stored, and exposed via API | ⚠️ Partial — computed internally but not aggregated or exposed | ❌ Planned — defined in framework only

| # | Category | Metric | WIF Section | Status | Implementation Details |
|---|----------|--------|-------------|--------|------------------------|
| 1 | Consumer (Stationary) | Autonomy (Days) | §3.1 | ✅ Full | `autonomy_days_est` — `latest_volume / avg_daily_demand`. Stored in all `*_metrics_windows` tables. |
| 2 | Consumer (Stationary) | Total Supply Hours | §A2.1 | ✅ Full | `supply_hours` — count of hourly rows with `inflow_liters > 0`. |
| 3 | Consumer (Stationary) | Supply Fragmentation Index | §A2.1 | ✅ Full | `supply_fragmentation_index` — `segments / supply_hours`. |
| 4 | Consumer (Stationary) | Run-out Risk (Probability) | §3.4 | ✅ Full | `runout_prob` — `hours(level ≤ 5%) / observed_hours`. |
| 5 | Consumer (Stationary) | Run-out Hours | §3.4 | ✅ Full | `runout_hours` — absolute hour count at critical level. |
| 6 | Consumer (Stationary) | Consumption Estimate (demand) | §A2.2 | ✅ Full | `demand_liters` aggregated in all `*_metrics_windows` tables and exposed by analytics APIs. |
| 7 | Consumer (Stationary) | Mean Supply Duration | §A2.1 | ✅ Full | `mean_supply_duration_hours` — `supply_hours / supply_segments` per window. |
| 8 | Consumer (Stationary) | Daily Supply Coverage | §A2.1 | ✅ Full | `daily_supply_coverage` — `supply_hours / window_hours` per window. |
| 9 | Consumer (Stationary) | Intermittence Severity Index | §A2.2 | ✅ Full | `intermittence_severity_index` — share of observed days where daily min level is at/below low threshold (<=20%). |
| 10 | Consumer (Stationary) | Elasticity near empty | §3.3 | ✅ Full | `elasticity_near_empty` computed from hourly demand means for low-level vs non-low-level bands. |
| 11 | Consumer (Stationary) | Poverty Penalty Factor | §3.5 | ❌ Planned | Blocked by price telemetry ingestion (no price field in current schema). |
| 12 | Consumer (Stationary) | Suppressed Demand | §3.6 | ✅ Full | `suppressed_demand_index` compares observed daily demand to a baseline derived from non-stressed, supply-available hours. |
| 13 | Provider (Mobile) | True Delivery Events (count) | §B3.2(1) | ✅ Full | `deliveries_count` — stop episodes with `volume_delta < −30 L`. |
| 14 | Provider (Mobile) | True Delivery Volume | §B3.2(1) | ✅ Full | `delivered_liters` — `Σ abs(volume_delta)` for delivery events. |
| 15 | Provider (Mobile) | Liters per Kilometer | §B3.2(2) | ✅ Full | `liters_per_km` — `delivered_liters / (distance_m / 1000)`. |
| 16 | Provider (Mobile) | Refill Efficiency (time at source) | §B3.2(3) | ✅ Full | `refill_time_minutes` — total dwell at refill-classified stops. |
| 17 | Provider (Mobile) | Refill Load Rate (L/min) | §B3.2(3) | ✅ Full | `refill_load_rate_l_per_min` computed as `liters_loaded / refill_time_minutes` when refill time is available. |
| 18 | Provider (Mobile) | Market Liquidity (district/day) | §B3.2(4) | ✅ Full | `truckflow_liters` aggregated at zone scope via `zone_metrics_windows`. |
| 19 | Provider (Mobile) | Mobile NRW (transit losses) | §B3.2(5) | ✅ Full | `mobile_nrw_liters` — `total_negative_deltas − delivered_liters`. |
| 20 | Provider (Mobile) | Operational Downtime | §B3.2(6) | ✅ Full | `downtime_hours` — sum of `DOWNTIME` stop episode durations per window. |
| 21 | Provider (Mobile) | Data Downtime | §B3.2(6) | ✅ Full | `data_gap_hours` — `window_hours − observed_hours`. |
| 22 | Integrated | Resilience Ratio | §C3 | ✅ Full | `resilience_ratio` — `gridflow / (gridflow + truckflow)`. |
| 23 | Integrated | Grid Flow (liters) | §C3 | ✅ Full | `pipeflow_liters` — sum of stationary inflows. |
| 24 | Integrated | Truck Flow (liters) | §C3 | ✅ Full | `truckflow_liters` — sum of mobile deliveries. |
| 25 | Integrated | Price Verification | §C2 | ❌ Planned | Blocked by price data ingestion — no price schema or endpoint exists. |

### Next implementation priorities

1. **Price ingestion** (#11, #25) — prerequisite for Poverty Penalty and Price Verification. Requires schema extension + ingestion endpoint.

### 10.2 Applicability + user/value mapping (what belongs where)

This table clarifies the **context** where each metric is applicable, the **primary API surface**, and the **user/value proposition**.

| Metric / concept | Applies to (entity + conditions) | Primary API surface | Primary user persona | Value proposition |
|---|---|---|---|---|
| Run-out risk (`runout_prob`, `runout_hours`) | Stationary reservoirs (`mobility=FIXED`) | `GET /v1/reservoirs/{id}/analytics`, rollups at site/org | Household/site ops | Detect WASH risk and intervene before empty events |
| Autonomy (`autonomy_days_est`) | Stationary reservoirs (`mobility=FIXED`) | Same as above | Household/site ops | Understand buffer time remaining under current demand |
| Demand estimate (`demand_liters`) | Stationary reservoirs (`mobility=FIXED`) | Reservoir + site/org/zone rollups | Household/site ops | Quantify inferred consumption in liters over the selected window |
| Elasticity near empty (`elasticity_near_empty`) | Stationary reservoirs (`mobility=FIXED`) with both level bands observed | Reservoir + site/org/zone rollups | Household/site ops | Detect behavioral demand compression under near-empty conditions |
| Suppressed demand (`suppressed_demand_index`) | Stationary reservoirs (`mobility=FIXED`) with baseline candidate hours | Reservoir + site/org/zone rollups | Household/site ops | Flag likely demand suppression vs unconstrained baseline behavior |
| Piped-network supply hours (`supply_hours`) | **Only** `is_pipe_connected=true` AND `mobility=FIXED` | Reservoir + site/org rollups | Utility/network ops | Quantify when the piped network is actually supplying |
| Piped-network fragmentation (`supply_fragmentation_index`) | **Only** `is_pipe_connected=true` AND `mobility=FIXED` | Reservoir + site/org rollups | Utility/network ops | Detect fragmented / bursty supply that drives stress |
| Mean supply duration (`mean_supply_duration_hours`) | **Only** `is_pipe_connected=true` AND `mobility=FIXED` | Reservoir + site/org/zone rollups | Utility/network ops | Understand average contiguous duration of supply episodes |
| Daily supply coverage (`daily_supply_coverage`) | **Only** `is_pipe_connected=true` AND `mobility=FIXED` | Reservoir + site/org/zone rollups | Utility/network ops | Fraction of the window covered by piped inflow availability |
| Intermittence severity (`intermittence_severity_index`) | **Only** `is_pipe_connected=true` AND `mobility=FIXED` | Reservoir + site/org/zone rollups | Utility/network ops | Flag repeated low daily minimum tank conditions over the window |
| Deliveries (count + liters) | Mobile reservoirs (`reservoir_type=TRUCK_TANK` OR `mobility=MOBILE`) | `GET /v1/reservoirs/{id}/analytics` (truck tank), drill-down via `/mobile/stops` | Fleet operator | Track true delivery throughput and volume moved |
| Liters per km (`liters_per_km`) | Mobile reservoirs with sufficient movement points | Reservoir analytics + org rollup | Fleet operator | Route efficiency and operational productivity |
| Refill time (`refill_time_minutes`) | Mobile reservoirs | Reservoir analytics + device stop drill-down | Fleet operator | Time cost at source / queue friction proxy |
| Loaded liters + refill load rate (`liters_loaded`, `refill_load_rate_l_per_min`) | Mobile reservoirs with refill events | Reservoir analytics + org rollup | Fleet operator | Measure refill throughput and source-side productivity |
| Operational downtime (`downtime_hours`) | Mobile reservoirs | Reservoir analytics + org rollup | Fleet operator | Separate non-productive stationary time from missing data |
| Mobile NRW (`mobile_nrw_liters`) | Mobile reservoirs | Reservoir analytics + org rollup | Fleet operator | Loss detection proxy (leakage/theft/spillage/unlogged offloads) |
| Truck flow (`truckflow_liters`) | Any scope containing mobile reservoirs | Site/org/zone analytics | City/zone ops | Market contribution to supply (informal delivery volume) |
| Piped-network inflow (`pipeflow_liters`) | **Only** `is_pipe_connected=true` stationary reservoirs in the scope | Site/org/zone analytics | City/zone ops | Formal network contribution to supply |
| Resilience ratio (`resilience_ratio`) | Zone/site/org scope (requires both flows) | `GET /v1/zones/{zone_id}/analytics` (also site/org) | City/zone planner | Quantify grid vs market dependence |

Notes:
- “Supply points” (standpipes/depots) are represented in the product as `supply_points`, but are not yet a first-class analytics aggregation surface. Linking mobile refill places (`mobile_places.place_type=REFILL_DEPOT`) to `supply_points` is a future extension.

### 10.3 Work packages (what changes are required)

**WP-1: Pipe-connected flag (schema + gating)**

- Add `reservoirs.is_pipe_connected` (boolean) and expose it on reservoir read surfaces.
- Gate pipe-network reliability metrics so they are computed/shown only when `is_pipe_connected=true` and reservoir is stationary.

**WP-2: Inflow source attribution (inference layer)**

- Implement a function that classifies each inflow episode as `PIPE|TRUCK|OTHER|UNKNOWN`.
- Use that classification to compute piped-network inflow strictly from pipe-attributed events (not all inflows).

**WP-3: Terminology cleanup (non-breaking API plan)**

- Breaking rename implemented: `gridflow_liters` → `pipeflow_liters` in API and analytics persistence.
