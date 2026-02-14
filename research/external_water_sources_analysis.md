# External Water Data Sources Analysis (Developing Markets Focus)

**Date:** 2026-02-10
**Status:** DRAFT
**Context:** This document analyzes data sources and proxies optimized for Jila's target markets, specifically focusing on developing regions like **Angola (Luanda)** where high-frequency physical sensors are scarce and water supply is often intermittent.

## Executive Summary

To simulate realistic water scenarios in environments with limited sensor infrastructure:

1. **Supply Availability Proxies**: Use **IBNET** for intermittent supply windows and **CHIRPS/NASA POWER** for precipitation-driven natural inflow.
2. **Consumption/Demand Simulators**: Use **WHO/UNICEF JMP** for per-capita household baselines and **Population Density** mappings to model aggregate demand.
3. **Behavioral Modeling**: Model manual collection events (20L Jerry Can units) and storage-driven consumption rather than continuous flow.

## 1. Supply Availability Sources (The "Inflow")

In regions like Luanda, water levels are driven more by **utility supply schedules** and **seasonal rainfall** than by predictable infrastructure streams.

### A. IBNET (International Benchmarking Network)

* **Best for**: Understanding utility constraints and intermittency.
* **Key Parameter**: *Hours of supply per day* (Metric: `Service Coverage`).
* **Value for Jila**: Defines the "Fill Window."
* **Simulation**: Instead of a steady state, reservoirs "fill" only during specific windows (e.g., 4h/day). If the utility is down, inflow = 0.
* **Source**: [wbwaterdata.org/ibnet](https://wbwaterdata.org/ibnet/)

### B. CHIRPS (Precipitation Proxy)

* **Best for**: Simulating natural recharge of open or rainwater-fed reservoirs.
* **Source**: Climate Hazards Group InfraRed Precipitation with Station data.
* **Granularity**: Daily (Global coverage, extremely accurate for Sub-Saharan Africa).
* **Integration Strategy**:
  * **Map to Jila**: Calculate `rain_inflow = precipitation (mm) * catch_area (m2)`.
  * **Simulation**: Use historical CHIRPS data for Luanda to drive "Rainy Season" scenarios where reservoirs may overflow.

### C. NASA POWER (Global Meteorological Data)

* **Best for**: Evapotranspiration and evaporation estimates for open community tanks.
* **Parameters**: Temperature, Solar Radiation, Wind Speed.
* **Value**: Helps calculate "Evaporative Loss" (Passive Outflow) in large communal reservoirs in semi-arid regions.
* **Access**: REST API (No key required).

## 2. Consumption & Demand Sources (Behavioral State)

How water is used in developing markets differs fundamentally from "Western" 24/7 pressurized systems.

### A. WHO/UNICEF JMP (Joint Monitoring Programme)

* **Best for**: Establishing realistic per-capita usage based on service level.
* **Angola Context**:
  * **Safely Managed (Pipe on premises)**: ~80-120 L/capita/day.
  * **Basic (Public tap/Neighbor)**: ~20-50 L/capita/day (highly constrained by manual haulage effort).
* **Application**: Tune the `Simulator Config` based on the site's "Water Source Type."
* **Source**: [washdata.org](https://washdata.org/data/household)

### B. World Bank WDI (Renewable Freshwater)

* **Best for**: National stress context.
* **Value**: Provides the "Scarcity Multiplier." In high-stress countries like Angola during drought, consumption decreases as prices rise or availability drops.

### C. The "Jerry Can" Unit (Physical Proxy)

* **Analysis**: For a large percentage of the population, water is transported in 20-liter yellow/blue jerry cans.
* **Universal Unit**: 1 Unit = 20L.
* **Application**:
  * **Extraction Events**: Households don't use 0.5L/min; they withdraw 20L in 30 seconds (pouring).
  * **Simulator logic**: Generate "Spiky" extraction events of 20L or 200L (drum) multiples to reflect manual collection patterns.

## 3. Targeted Integration Plan

| Source | Jila Concept | Market Logic |
| :--- | :--- | :--- |
| **IBNET** | `Inflow Schedule` | **Intermittency**: 04:00 - 08:00 (Supply active). |
| **CHIRPS** | `Environmental Reading` | **Seasonality**: Increases reservoir volume during rain events. |
| **JMP (WHO/UNICEF)** | `Demand Baseline` | **Service Level**: 50L (Communal) vs 100L (Private). |
| **Jerry Can Proxy** | `Event Delta` | **Discrete Usage**: Multiple of 20L withdrawals. |

## 4. Optimized Angola Case Study

1. **Baseline Site**: Zango II, Viana (Intermittent supply).
2. **Inflow Pattern**: 6 hours of utility supply (IBNET benchmark) + Seasonal Rain (CHIRPS).
3. **Consumption Pattern**: 5 persons * 80L/day = 400L total.
4. **Events**: Simulate a "Dry Week" where utility breaks; track how long the storage lasts before hitting a Critical Level (15%).
