## Analytics Metric Dictionary (v1)

Status: Canonical for analytics surfaces introduced in the post-v1 intelligence layer.

Versioning:
- `inputs_version`: `1`
- `metric_version`: `1`

All formulas use UTC windows (`window_start`, `window_end`).

## 1. Purpose And Reading Guide

This document has two jobs:
- **Contract summary:** exact implemented formulas and required inputs.
- **Narrative explanation:** why each metric matters, who should care, and what decision it enables.

Read the summary table first for exact logic, then use Sections 4-7 for plain-language interpretation.

## 2. Scope And Applicability

- Primary computation scope: `reservoir_metrics_windows`.
- Aggregation scopes: `site_metrics_windows`, `org_metrics_windows`, `zone_metrics_windows` (latest per-reservoir rows for the same `window_label`).

Applicability rules:
- Pipe-network reliability metrics are meaningful only for **pipe-connected stationary reservoirs** (`reservoirs.is_pipe_connected = true` and non-mobile).
- Mobile reservoirs (`mobility=MOBILE` or truck tanks) do not carry pipe-network intermittence semantics.
- Behavioral demand metrics (`elasticity_near_empty`, `suppressed_demand_index`) can be `null` when required comparison bands are missing.

Recompute invariants:
- Same inputs + same window + same versions yield the same metric values (except `computed_at` / `snapshot_at`).

## 3. Canonical Formula Summary (Implemented)

| Metric | Unit | Formula (v1) | Required inputs | Caveats / WIF mapping |
|---|---|---|---|---|
| `runout_hours` | hours | Count of hourly rows where `median_level_pct <= 5` | `stationary_hourly_series.median_level_pct` | WIF A2.2 run-out risk; bounded by observed hours |
| `runout_prob` | ratio [0..1] | `runout_hours / observed_hours` | `runout_hours`, observed hourly rows | If no observations: `0` |
| `autonomy_days_est` | days | `latest_volume_liters / avg_daily_demand_liters` | `stationary_hourly_series.smoothed_volume_liters`, `demand_liters` | Null when demand is zero/insufficient data; WIF 3.1 |
| `supply_hours` | hours | Count of hourly rows where `inflow_liters > 0` | `stationary_hourly_series.inflow_liters` | Proxy for supply availability |
| `supply_fragmentation_index` | ratio | `supply_segments / supply_hours` | `stationary_hourly_series.inflow_liters` | Higher means more fragmented supply; WIF A2.1 |
| `mean_supply_duration_hours` | hours | `supply_hours / supply_segments` | `stationary_hourly_series.inflow_liters` | Zero when no supply segments in the window; WIF A2.1 |
| `daily_supply_coverage` | ratio [0..1] | `supply_hours / window_hours` | `supply_hours`, window label | Pipe-network applicability only; WIF A2.1 |
| `intermittence_severity_index` | ratio [0..1] | `days(min_hourly_level_pct <= 20) / observed_days` | `stationary_hourly_series.median_level_pct` | Tracks low daily minimum pressure/risk; WIF A2.2 |
| `demand_liters` | liters | Sum of hourly `demand_liters` | `stationary_hourly_series.demand_liters` | Stationary consumption proxy used for autonomy and suppression analysis; WIF A2.2 |
| `elasticity_near_empty` | ratio | `mean(demand_liters | level_pct < 20) / mean(demand_liters | level_pct >= 20)` | `stationary_hourly_series.demand_liters`, `stationary_hourly_series.median_level_pct` | Null when either band has no observations or denominator mean is zero; WIF 3.3 |
| `suppressed_demand_index` | ratio [0..1] | `max(min((baseline_daily_demand - observed_daily_demand) / baseline_daily_demand,1),0)` | `stationary_hourly_series.demand_liters`, `stationary_hourly_series.median_level_pct`, `stationary_hourly_series.inflow_liters` | `baseline_daily_demand` uses mean demand of rows with `level_pct >= 20` and `inflow_liters > 0`, scaled by 24; null when baseline unavailable; WIF 3.6 |
| `deliveries_count` | count | Count of stop episodes with `event_type='DELIVERY'` | `mobile_stop_episodes` | WIF B3.2(1) |
| `delivered_liters` | liters | Sum of `abs(volume_delta_liters)` over `DELIVERY` episodes | `mobile_stop_episodes.volume_delta_liters` | Requires volumetric telemetry signal |
| `liters_loaded` | liters | Sum of positive `volume_delta_liters` over `REFILL` episodes | `mobile_stop_episodes.volume_delta_liters` | Volumetric refill proxy; WIF B3.2(3) |
| `liters_per_km` | liters/km | `delivered_liters / moving_distance_km` | `device_location_points`, `mobile_stop_episodes` | Null when distance is zero |
| `refill_time_minutes` | minutes | Sum of `duration_seconds/60` over `REFILL` episodes | `mobile_stop_episodes` | WIF B3.2(3) |
| `refill_load_rate_l_per_min` | liters/min | `liters_loaded / refill_time_minutes` | `liters_loaded`, `refill_time_minutes` | Null when refill time is zero; WIF B3.2(3) |
| `downtime_hours` | hours | Sum of `duration_seconds/3600` over `DOWNTIME` episodes | `mobile_stop_episodes` | Operational downtime only (distinct from data gap); WIF B3.2(6) |
| `mobile_nrw_liters` | liters | `max(total_negative_volume_delta - delivered_liters, 0)` | `mobile_stop_episodes.volume_delta_liters` | Proxy for non-revenue water in transit; WIF B3.2(5) |
| `pipeflow_liters` | liters | Sum of hourly `inflow_liters` | `stationary_hourly_series` | Meaning: **piped-network inflow** (WIF C3) and only interpreted for **pipe-connected stationary reservoirs** |
| `truckflow_liters` | liters | `delivered_liters` | `mobile_stop_episodes` | Proxy for market contribution |
| `resilience_ratio` | ratio [0..1] | `pipeflow_liters / (pipeflow_liters + truckflow_liters)` | `pipeflow_liters`, `truckflow_liters` | Interpretable at site/org/zone scopes when `pipeflow_liters` reflects piped-network inflow; null when denominator is zero; WIF C3 |
| `data_gap_hours` | hours | `window_hours - observed_hours` (clamped at `>=0`) | hourly observation count | Explicit missing-data signal |
| `confidence` | enum | Coverage rubric: `HIGH` >= 90%, `MEDIUM` >= 70%, else `LOW` | observed hours vs window hours | Applied per-scope, aggregated using worst-case |

## 4. Stationary Metrics: Reliability, Demand, And Household Stress

| Metric | Implemented logic (plain English) | So what? | Primary user and value proposition |
|---|---|---|---|
| `runout_hours` | Counts how many observed hours the tank is at critical low (`<=5%`). | Shows how often service is at immediate failure risk. | **Site ops / household support:** prioritize interventions before households run dry. |
| `runout_prob` | Converts runout hours into a share of observed time. | Makes risk comparable across sites/windows of different data volume. | **Planners / dashboard users:** rank risk consistently across assets. |
| `autonomy_days_est` | Uses latest storage and inferred daily demand to estimate days of buffer. | Answers “if no new supply comes, how long until stress?”. | **Ops and support teams:** triage where replenishment urgency is highest. |
| `supply_hours` | Counts hours with positive inflow. | Quantifies how much piped supply actually reached the reservoir. | **Utility/network ops:** evidence of real network service, not nominal schedule. |
| `supply_fragmentation_index` | Number of supply segments divided by supply hours. | Distinguishes steady service from short bursty service. | **Utility/network ops:** find unstable neighborhoods where timing drives stress. |
| `mean_supply_duration_hours` | Average duration of contiguous supply episodes. | Translates fragmentation into an intuitive “how long supply lasts when it appears.” | **Utility/network ops:** optimize pump cycles and routing by duration quality. |
| `daily_supply_coverage` | Share of the full window covered by supply hours. | Gives an immediate coverage percentage for reliability dashboards. | **City/site managers:** communicate service sufficiency clearly to stakeholders. |
| `intermittence_severity_index` | Share of observed days with very low daily minimum (`<=20%`). | Captures repeated daily stress, not just isolated events. | **Service quality teams:** detect chronic fragility versus one-off outages. |
| `demand_liters` | Sums inferred demand (negative storage deltas) over the window. | Establishes total usage pressure in liters, the core demand signal. | **Operations and planning:** size deliveries, storage, and replenishment windows. |
| `elasticity_near_empty` | Compares mean demand when low (`<20%`) vs non-low (`>=20%`). | Reveals behavior compression when users are near empty (rationing signal). | **Policy and customer success:** identify where low usage is stress-driven, not comfort-driven. |
| `suppressed_demand_index` | Compares observed daily demand to a baseline from non-stressed, supply-available hours. | Estimates hidden unmet demand under constrained conditions. | **Planning and equity lens:** expose under-consumption caused by constraints, not low need. |

## 5. Mobile Metrics: Delivery Throughput And Fleet Productivity

| Metric | Implemented logic (plain English) | So what? | Primary user and value proposition |
|---|---|---|---|
| `deliveries_count` | Counts stop episodes classified as `DELIVERY`. | Tracks true service events, not just movement. | **Fleet operators:** monitor operational throughput and workload. |
| `delivered_liters` | Sums absolute delivered volume over delivery events. | Measures actual water moved to clients. | **Marketplace/fleet managers:** manage capacity and fulfillment performance. |
| `liters_loaded` | Sums positive volume deltas at refill events. | Quantifies how much supply was acquired at sources. | **Fleet operators:** evaluate source productivity and refill patterns. |
| `liters_per_km` | Delivered liters divided by moving distance. | Core route-efficiency KPI. | **Fleet optimization:** reduce cost and time per liter delivered. |
| `refill_time_minutes` | Total time spent in refill-classified stops. | Measures non-delivery time spent acquiring water. | **Fleet operations:** identify queue friction and depot bottlenecks. |
| `refill_load_rate_l_per_min` | Loaded liters divided by refill minutes. | Converts refill time into source throughput productivity. | **Depot and fleet managers:** compare refill points and improve turnaround. |
| `downtime_hours` | Sums durations of `DOWNTIME` stop episodes. | Separates idle/parked operations from productive activity. | **Fleet operators:** improve utilization and detect persistent inactivity. |
| `mobile_nrw_liters` | Negative transit-related volume not explained by deliveries (clamped at zero). | Indicates likely losses in transit (leakage/theft/spillage/unlogged offload). | **Risk/compliance/fleet:** target loss investigations and maintenance actions. |

## 6. Integrated Metrics: Grid-Market Balance And System Resilience

| Metric | Implemented logic (plain English) | So what? | Primary user and value proposition |
|---|---|---|---|
| `pipeflow_liters` | Piped-network inflow liters from stationary inflow signals. | Quantifies contribution of formal network supply. | **City/zone planners:** baseline formal service contribution. |
| `truckflow_liters` | Delivered liters from mobile delivery events. | Quantifies contribution of informal/mobile market supply. | **City/zone planners:** understand dependence on trucked supply. |
| `resilience_ratio` | `pipeflow / (pipeflow + truckflow)` when denominator exists. | Single indicator of grid-dominant vs market-dominant supply balance. | **Strategy/policy leaders:** prioritize resilience interventions by zone/site. |

## 7. Data Quality Metrics: Trust And Decision Safety

| Metric | Implemented logic (plain English) | So what? | Primary user and value proposition |
|---|---|---|---|
| `data_gap_hours` | Missing hours inside the requested window. | Makes incompleteness explicit so users do not over-trust sparse data. | **All personas:** avoid false certainty in dashboards and exports. |
| `confidence` | Coverage tier (`HIGH/MEDIUM/LOW`) from observed vs expected window hours. | Fast reliability signal for whether decisions should be automated/escalated/manual. | **All personas:** calibrate operational action to evidence quality. |

## 8. Simulator Mapping (v1 demo mode)

This section maps simulator-generated telemetry signals to metric behavior without changing formulas.

### Archetype templates and expected metric tendencies

- `stationary_archetype_a`
  - Inputs emphasis: higher regular inflow windows, higher storage buffer.
  - Expected tendency: lower `runout_prob`, higher `autonomy_days_est`, lower `supply_fragmentation_index` vs Archetype C.
- `stationary_archetype_c`
  - Inputs emphasis: fragmented/irregular inflow windows, stronger near-empty demand suppression.
  - Expected tendency: higher `runout_prob`, lower `autonomy_days_est`, higher `supply_fragmentation_index` vs Archetype A.
- `mobile_high_efficiency`
  - Inputs emphasis: denser delivery stops, lower transit-loss signal.
  - Expected tendency: higher `liters_per_km`, lower `mobile_nrw_liters`.
- `mobile_fragmented_high_loss`
  - Inputs emphasis: more fragmented operations, longer non-productive stop periods, stronger transit-loss signal.
  - Expected tendency: lower `liters_per_km`, higher `mobile_nrw_liters`.

### Signal-to-metric notes

- `runout_*`, `autonomy_days_est`, `supply_*`, `demand_liters`, `elasticity_near_empty`, `suppressed_demand_index`, `pipeflow_liters` are driven by generated `reservoir_readings` -> `stationary_hourly_series`.
- `deliveries_count`, `delivered_liters`, `liters_loaded`, `refill_time_minutes`, `refill_load_rate_l_per_min`, `downtime_hours`, `mobile_nrw_liters`, `liters_per_km`, `truckflow_liters` are driven by generated device telemetry payloads containing both:
  - ultrasonic-derived volume changes, and
  - GPS/location fields (`location.latitude`, `location.longitude`, `location.speed_kmh`, `location.course_degrees`) that produce `device_location_points` and `mobile_stop_episodes`.
- `resilience_ratio` follows existing formula and rises/falls as simulator mix shifts between stationary inflow (`pipeflow_liters`) and mobile deliveries (`truckflow_liters`).

### Stationary diurnal controls (v1.1)

- `devices[].dynamics.demand.target_daily_liters` sets daily demand magnitude directly.
- `devices[].dynamics.demand.hourly_weights` and `weekday_multipliers` shape when demand occurs.
- `devices[].dynamics.supply.hourly_probability_multipliers` and `hourly_volume_multipliers` shape when inflow occurs and how intense each inflow event is.
- `devices[].dynamics.supply.weekday_probability_multipliers` controls day-level supply availability.

Expected directional effects (no formula changes):

- Stronger peak demand windows with weak supply windows increase `runout_prob` tendency and reduce `autonomy_days_est`.
- More regular/high-probability supply windows reduce `supply_fragmentation_index` tendency and increase `pipeflow_liters`.
- More fragmented/low-probability supply windows increase `supply_fragmentation_index` tendency and raise runout pressure.
