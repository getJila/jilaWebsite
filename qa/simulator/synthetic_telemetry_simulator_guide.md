# Synthetic Telemetry Simulator Guide (v1)

This guide explains how to run and operate the reservoir synthetic device simulator introduced for analytics demonstrations.

It covers:
- prerequisites and safety checks,
- command usage (`validate`, `dry-run`, `bootstrap`, `run`),
- scenario schema in detail,
- archetype behavior,
- expected outputs and troubleshooting.

## 1) Purpose and scope

The simulator is intended for demonstration and QA workflows while physical device deployment scales.

v1 design goals:
- Reuse production ingestion semantics.
- Generate deterministic, scenario-driven telemetry.
- Support both historical backfill and live MQTT simulation.
- Drive stationary, mobile, and integrated analytics surfaces.

v1 non-goals:
- No new HTTP API endpoints.
- No direct writes to analytics read-model tables.
- No DB schema/migration changes.

## 2) Components and data flow

### 2.1 Entrypoints

- Canonical CLI:
  - `scripts/synthetic_telemetry_simulator.py`
- Backward-compatible wrapper:
  - `tests/e2e/scripts/mqtt_simulator.py`

### 2.2 Internal modules

- `scripts/synthetic_telemetry/models.py`
  - Pydantic scenario schema and validation.
- `scripts/synthetic_telemetry/archetypes.py`
  - Built-in archetype defaults and metric tendencies.
- `scripts/synthetic_telemetry/engine.py`
  - Deterministic state machine and payload generation.
- `scripts/synthetic_telemetry/preflight.py`
  - Device/reservoir/route safety checks against DB.
- `scripts/synthetic_telemetry/bootstrap.py`
  - Historical generation via ingestion internals.
- `scripts/synthetic_telemetry/mqtt_runtime.py`
  - Live MQTT publication loop.
- `scripts/synthetic_telemetry/state_store.py`
  - Persistent sequence state.

### 2.3 Ingestion paths

- Live mode (`run`): publishes MQTT messages to `devices/{device_id}/telemetry`.
- Bootstrap mode (`bootstrap`): calls `ingest_device_telemetry_from_mqtt(...)` directly with synthetic `received_at`.

Both modes generate production-compatible payloads and preserve dedupe semantics with monotonic `seq` per device.

## 3) Prerequisites

Run commands from repo root:
- `/Users/dionisio/Documents/Projects/Jila/JilaAPI`

Use project virtualenv:
- `.venv/bin/python ...`

Required runtime conditions:
- PostgreSQL reachable with migrated schema.
- Target devices exist and are attached to reservoirs.
- Reservoir calibration is valid:
  - explicit `sensor_empty_distance_mm` and `sensor_full_distance_mm`, or
  - `height_mm` (fallback derivation to `empty=height_mm`, `full=0`).
- For live MQTT mode:
  - broker reachable,
  - cert/key resolvable via scenario `mqtt` block or app settings.

Operational note:
- If API/worker/listener restart is needed, restart manually via team process.

## 4) Step-by-step runbook (stationary-only)

This is the recommended operator sequence for:
- `docs/qa/simulator/scenarios/stationary_only_v1.yaml`

Important shell note:
- Copy commands only, not your terminal prompt (for example do not copy `%` or `user@host`).

### 4.1 Step 1: Validate scenario and DB preflight

Run:

```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --scenario docs/qa/simulator/scenarios/stationary_only_v1.yaml \
  --strict validate
```

Success looks like:
- JSON output with `"command": "validate"`.
- `devices_validated` contains both stationary device IDs.
- `warnings` is empty or only informational.

Stop here if validation fails.

### 4.2 Step 2: Preview dynamics without writes

Run:

```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --scenario docs/qa/simulator/scenarios/stationary_only_v1.yaml \
  --strict dry-run --preview-steps 10
```

Success looks like:
- Per-device samples printed with increasing `seq`.
- `raw_samples` present for ultrasonic readings.
- No DB writes and no MQTT publishes happen in this step.

### 4.3 Step 3A (recommended): CSV-first history flow

Use this path when you want inspectable history before writes.

1. Export deterministic historical rows (no writes):

```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --scenario docs/qa/simulator/scenarios/stationary_only_v1.yaml \
  --state-file .tmp/synthetic_sim_seq_state.json \
  --strict export-csv --run-id stationary_hist_v1 --end-at 2026-02-12T10:00:00Z
```

2. Confirm artifact files exist:
- `docs/qa/simulator/generated/stationary_only_v1/stationary_hist_v1/telemetry_rows.csv`
- `docs/qa/simulator/generated/stationary_only_v1/stationary_hist_v1/manifest.json`

3. Analyze exported CSV (no writes):

```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  analyze-csv --artifact-dir docs/qa/simulator/generated/stationary_only_v1/stationary_hist_v1
```

Success looks like:
- JSON output with `"command": "analyze-csv"`.
- `"qc_passed": true`.
- `seq_gap_count`, `seq_duplicate_count`, and `invalid_row_count` are `0`.

4. Dry-run import check (no writes):

```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  import-csv --artifact-dir docs/qa/simulator/generated/stationary_only_v1/stationary_hist_v1
```

Success looks like:
- JSON output with `"command": "import-csv"` and `"apply": false`.
- `status_counts` contains `dry_run:READY`.

5. Apply import (writes through ingestion contract):

```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --state-file .tmp/synthetic_sim_seq_state.json \
  import-csv --artifact-dir docs/qa/simulator/generated/stationary_only_v1/stationary_hist_v1 \
  --apply --commit-batch-size 500
```

Optional if analytics worker is not running:

```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --state-file .tmp/synthetic_sim_seq_state.json \
  import-csv --artifact-dir docs/qa/simulator/generated/stationary_only_v1/stationary_hist_v1 \
  --apply --commit-batch-size 500 --drain-analytics --analytics-batch-size 300
```

Success looks like:
- JSON output with `"apply": true`.
- `status_counts` includes mostly `stored:*` and `duplicate:*`.
- `import_result.json` is written in the artifact directory.

### 4.4 Step 3B (alternative): Direct bootstrap history flow

Use this when you do not need a CSV approval step.

```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --scenario docs/qa/simulator/scenarios/stationary_only_v1.yaml \
  --state-file .tmp/synthetic_sim_seq_state.json \
  --strict bootstrap --commit-batch-size 1000 --analytics-batch-size 300
```

Important behavior:
- `bootstrap` does not publish MQTT.
- It replays directly through `ingest_device_telemetry_from_mqtt(...)` with historical `received_at`.
- Output is a final JSON summary after processing.

### 4.5 Step 4: Verify history landed

Minimum checks:
- Command output has non-zero `row_count` (CSV import) or non-zero `total_emitted` (bootstrap).
- No fatal errors in the final JSON summary.
- Your backend telemetry and analytics views now include the backfilled time window.

### 4.6 Step 5: Start live stationary simulation (real-time MQTT)

After history is loaded, start live stream:

```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --scenario docs/qa/simulator/scenarios/stationary_only_v1.yaml \
  --state-file .tmp/synthetic_sim_seq_state.json \
  --strict run --duration-seconds 600
```

Success looks like:
- JSON output with `"command": "run"` and non-zero `"emitted"`.
- Live telemetry appears during runtime.

## 5) Command reference

## `validate`

What it does:
- Validates schema and cross-references.
- Validates DB preflight constraints.

What it does not do:
- No telemetry writes.
- No analytics writes.

Example:
```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --scenario docs/qa/simulator/scenarios/stationary_only_v1.yaml \
  --strict validate
```

## `dry-run`

What it does:
- Generates deterministic preview emissions in memory.
- Prints per-device tendencies and emission samples.

What it does not do:
- No DB writes.
- No MQTT publishes.

Example:
```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --scenario docs/qa/simulator/scenarios/mobile_only_v1.yaml \
  --strict dry-run --preview-steps 10
```

## `bootstrap`

What it does:
- Generates historical emissions over `bootstrap.days`.
- Ingests through `ingest_device_telemetry_from_mqtt(...)`.
- Optionally drains analytics consumer and runs place clustering.

Key flags:
- `--commit-batch-size` (default `500`)
- `--analytics-batch-size` (default `200`)

Example:
```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --scenario docs/qa/simulator/scenarios/demo_city_v1.yaml \
  --strict bootstrap --commit-batch-size 1000
```

How historical window is computed:
- `end_at = now_utc` at command start.
- `start_at = now_utc - bootstrap.days`.
- Emissions are generated from `start_at` forward until `end_at`.
- Effective step per device:
  - `step_seconds = max(device.cadence_seconds, bootstrap.step_minutes * 60)`.
- Approximate emitted points per device:
  - `~ floor((bootstrap.days * 86400) / step_seconds) + 1`.

Concrete example:
- If command starts at `2026-02-12T10:00:00Z` and `bootstrap.days=30`,
  the backfill window is approximately:
  - start: `2026-01-13T10:00:00Z`
  - end: `2026-02-12T10:00:00Z`

## `run`

What it does:
- Opens per-device MQTT connections.
- Publishes live synthetic telemetry at device cadence.

Key flags:
- `--iterations` (default `0`, unlimited)
- `--duration-seconds` (default `0`, unlimited)

Example:
```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --scenario docs/qa/simulator/scenarios/demo_city_v1.yaml \
  --strict run --iterations 200
```

## `export-csv`

What it does:
- Generates historical telemetry rows as CSV artifact files.
- Uses scenario + preflight + engine + seq state, but performs no DB writes.
- Writes:
  - `telemetry_rows.csv`
  - `manifest.json`

Key flags:
- `--output-root` (default `docs/qa/simulator/generated`)
- `--run-id` (optional override for artifact directory)
- `--end-at` (optional UTC ISO8601 end boundary)

Example:

```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --scenario docs/qa/simulator/scenarios/stationary_only_v1.yaml \
  --strict export-csv --run-id jan_demo --end-at 2026-02-12T10:00:00Z
```

## `analyze-csv`

What it does:
- Reads one generated artifact directory.
- Validates row schema and timestamps.
- Produces dataset profile and QC summary in `analysis.json`.

Checks include:
- missing/invalid timestamps,
- per-device seq gaps/duplicates/non-monotonic order,
- modeled level bounds.

Example:

```bash
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  analyze-csv --artifact-dir docs/qa/simulator/generated/stationary_only_v1/jan_demo
```

## `import-csv`

What it does:
- Verifies `manifest.json` + CSV hash integrity.
- Replays rows through `ingest_device_telemetry_from_mqtt(...)`.
- Updates local seq state on apply mode.
- Writes `import_result.json`.

Safety gate:
- Default mode is dry-run.
- DB writes occur only with `--apply`.

Key flags:
- `--artifact-dir` (required)
- `--apply` (required for writes)
- `--commit-batch-size` (default `500`)
- `--drain-analytics` (optional)
- `--analytics-batch-size` (default `200`)

Examples:

```bash
# dry-run (no writes)
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  import-csv --artifact-dir docs/qa/simulator/generated/stationary_only_v1/jan_demo

# apply write replay
.venv/bin/python scripts/synthetic_telemetry_simulator.py \
  --state-file .tmp/synthetic_sim_seq_state.json \
  import-csv --artifact-dir docs/qa/simulator/generated/stationary_only_v1/jan_demo \
  --apply --commit-batch-size 500
```

## 6) Sequence state and idempotency

Sequence state file:
- default: `.tmp/synthetic_sim_seq_state.json`
- override: `--state-file <path>`

Behavior:
- Loaded at start.
- Updated after bootstrap/live run.
- Ensures monotonic `seq` continuity across runs.

Why it matters:
- Telemetry dedupe in ingestion relies on `(mqtt_client_id, seq)`.
- Resetting seq carelessly can cause duplicates to be ignored or produce confusing demo output.

## 7) Scenario schema (field-by-field)

Root fields:
- `scenario_id` (string, required)
- `seed` (int, default `42`)
- `timezone` (must be `UTC` in v1)
- `speedup_factor` (float > 0)
- `mqtt` (object)
- `bootstrap` (object)
- `devices[]` (required, at least one)
- `routes[]` (optional unless mobile devices are defined)

`mqtt`:
- `host` (optional)
- `port` (default `8883`)
- `cert_path` / `key_path` (optional, otherwise app settings are used)

`bootstrap`:
- `days` (1..365)
- `step_minutes` (1..60)
- `drain_analytics` (`true|false`)

`devices[]` item:
- `device_id` (normalized uppercase)
- `reservoir_id` (optional UUID pin; default is device-attached reservoir from DB)
- `archetype`
  - `stationary_archetype_a`
  - `stationary_archetype_c`
  - `mobile_high_efficiency`
  - `mobile_fragmented_high_loss`
- `mode`
  - `STATIONARY`
  - `MOBILE`
- `cadence_seconds` (60..3600)
- `route_id` (required when `mode=MOBILE`)
- `dynamics` (optional, `STATIONARY` only)
  - `demand.target_daily_liters` (optional, >0; if omitted then `demand_liters_per_hour * 24`)
  - `demand.hourly_weights` (24 values, each >0)
  - `demand.weekday_multipliers` (7 values, each >0; Monday index 0)
  - `supply.hourly_probability_multipliers` (24 values, each >=0)
  - `supply.hourly_volume_multipliers` (24 values, each >=0)
  - `supply.weekday_probability_multipliers` (7 values, each >=0; Monday index 0)
- `parameter_overrides` (free-form overrides)

`routes[]` item:
- `route_id`
- `points[]`
  - `point_id`
  - `kind`: `BASE|REFILL|CLIENT`
  - `latitude`, `longitude`
  - optional `zone_id`
- `transitions[]` (optional)
  - `from_kind`, `to_kind`, `probability`
  - per `from_kind`, probabilities must sum to `1.0`

### 7.1 UTC hour mapping for stationary dynamics

- Hour-of-day controls use `received_at` in UTC only (`timezone` is fixed to `UTC` in v1).
- Demand formula per emission step:
  - `hour = received_at.hour`
  - `dow = received_at.weekday()` (Monday=0)
  - `weights_norm = hourly_weights * (24 / sum(hourly_weights))`
  - `base_lph = target_daily_liters / 24` (or fallback `demand_liters_per_hour`)
  - `demand_step = base_lph * weights_norm[hour] * weekday_multipliers[dow] * (cadence_seconds/3600)`
- Supply probability/volume are scaled by hourly and weekday multipliers before state update.

Example (`fixed liters/day + peak hours`):

```yaml
devices:
  - device_id: E2E2024STATA1
    archetype: stationary_archetype_a
    mode: STATIONARY
    cadence_seconds: 300
    dynamics:
      demand:
        target_daily_liters: 900.0
        hourly_weights: [0.6, 0.5, 0.5, 0.5, 0.6, 0.8, 1.2, 1.4, 1.3, 1.0, 0.9, 0.9, 1.0, 1.0, 1.0, 1.0, 1.1, 1.3, 1.4, 1.3, 1.0, 0.9, 0.7, 0.6]
        weekday_multipliers: [1.0, 1.0, 1.0, 1.0, 1.05, 1.1, 0.95]
      supply:
        hourly_probability_multipliers: [0.8, 0.75, 0.7, 0.65, 0.7, 0.85, 1.0, 1.2, 1.25, 1.1, 1.0, 0.95, 0.9, 0.95, 1.0, 1.05, 1.1, 1.2, 1.3, 1.2, 1.05, 0.95, 0.9, 0.85]
        hourly_volume_multipliers: [0.8, 0.75, 0.7, 0.7, 0.75, 0.9, 1.0, 1.15, 1.2, 1.1, 1.0, 0.95, 0.9, 0.95, 1.0, 1.05, 1.1, 1.2, 1.25, 1.2, 1.0, 0.9, 0.85, 0.8]
        weekday_probability_multipliers: [1.0, 1.0, 1.0, 1.0, 1.0, 0.95, 0.95]
```

## 8) Preflight checks

Preflight validates:
- route completeness for mobile devices (`BASE`, `REFILL`, `CLIENT` point kinds),
- device exists,
- device is attached,
- attached reservoir matches scenario `reservoir_id` when provided,
- reservoir is not deleted,
- `capacity_liters > 0`,
- calibration is usable,
- mobile mode only on mobile-capable context (`TRUCK_TANK` or `MOBILE`).

`--strict` behavior:
- any preflight error fails the command immediately.

## 9) Archetypes and expected tendencies

- `stationary_archetype_a`
  - More regular inflow, stronger buffering.
  - Tendency: lower `runout_prob`, higher `autonomy_days_est`.

- `stationary_archetype_c`
  - More fragmented inflow, stronger near-empty demand suppression.
  - Tendency: higher `runout_prob`, higher `supply_fragmentation_index`.

- `mobile_high_efficiency`
  - Higher delivery density, lower transit loss.
  - Tendency: higher `liters_per_km`, lower `mobile_nrw_liters`.

- `mobile_fragmented_high_loss`
  - More non-productive stops and higher transit loss.
  - Tendency: lower `liters_per_km`, higher `mobile_nrw_liters`.

## 10) Payload contract produced by simulator

Generated payload includes:
- `schema_version`
- `local_timestamp_ms`
- `seq`
- `sensors.ultrasonic.raw_readings`
- `sensors.ultrasonic.temperature_c`
- `power.battery_percentage`
- `signal_strength_dbm`
- `location.*` (mobile mode only)

The engine converts:
- liters -> level_pct -> ultrasonic distance samples,
using reservoir calibration semantics compatible with ingestion.

## 11) Included scenario templates

- `docs/qa/simulator/scenarios/demo_city_v1.yaml`
  - mixed stationary + mobile integrated demonstration.

- `docs/qa/simulator/scenarios/stationary_only_v1.yaml`
  - stationary A vs C contrast.

- `docs/qa/simulator/scenarios/mobile_only_v1.yaml`
  - mobile high-efficiency vs fragmented/high-loss contrast.

Important:
- Template IDs are placeholders. Replace `device_id` with real attached entities before running.
- Use `reservoir_id` only when you want explicit pinning to detect attachment drift during preflight.

## 12) Legacy wrapper

Existing E2E users can continue with:

```bash
.venv/bin/python tests/e2e/scripts/mqtt_simulator.py --single
.venv/bin/python tests/e2e/scripts/mqtt_simulator.py --batch --count 20
```

Wrapper behavior:
- builds a temporary one-device scenario,
- delegates execution to `scripts/synthetic_telemetry_simulator.py`.

## 13) Troubleshooting

`Preflight failed: device not found`
- Verify `device_id` exists in `devices` and is uppercase in scenario.

`Preflight failed: not attached to a reservoir`
- Attach device first; simulator requires attached devices.

`Preflight failed: missing calibration`
- Ensure reservoir has sensor calibration fields or positive `height_mm`.

`MQTT cert/key not found`
- Set `scenario.mqtt.cert_path` and `scenario.mqtt.key_path`, or configure MQTT cert settings in app env.

`bootstrap produced data but analytics still stale`
- Ensure worker/analytics consumer is running and `drain_analytics` is enabled.

`import-csv failed with manifest csv_sha256 mismatch`
- CSV or manifest changed after export; regenerate export, then re-run analyze/import.

`import-csv dry-run succeeded but no DB rows changed`
- Expected behavior: dry-run does not write; rerun with explicit `--apply`.

`live run appears to emit but API shows no new data`
- Check MQTT broker connectivity and device identity mapping (`mqtt_client_id == device_id` contract).

`unexpected duplicate behavior`
- Inspect and preserve sequence state file; do not reset unless intentionally starting a fresh stream.

## 14) Operational recommendations

- Use `validate` before every bootstrap/live run.
- Keep scenarios versioned in Git.
- Start with `dry-run` when changing overrides.
- Use dedicated test/demo devices to avoid polluting operational dashboards.
- Record run metadata (scenario, seed, state-file path, start/end timestamps) for reproducibility.
