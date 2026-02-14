## Supply Point Enrichment and Enum Dictionary (v1.0)

Status: Canonical draft for implementation.

Applies to:
- CSV survey ingestion (for example, Pontos de Água).
- Normalization into `supply_points` enrichment columns.
- Public/admin exposure split for enrichment fields.

---

## 1) Scope and goals

Goals:
- Add rich, normalized enrichment for `supply_points`.
- Keep public endpoints safe by default (no PII/raw text leaks).
- Preserve raw/admin fields for audit and remapping.
- Make imports idempotent and reproducible.

Non-goals:
- Do not create a new status state machine from survey snapshots.
- Do not expose admin raw fields in public discovery APIs.

---

## 2) Canonical visibility tiers

### 2.1 Public enrichment

Public-safe normalized fields only (stored in `supply_points`, exposed on public endpoints).

### 2.2 Admin enrichment

PII and raw values, including free-text survey notes and contact details (stored in `supply_points`, exposed only on admin endpoints).

---

## 3) Canonical enum sets (v1.0)

### 3.1 `EXTRACTION_TYPE`
- `TAP_STANDPIPE`
- `HAND_PUMP`
- `SOLAR_PUMP`
- `ELECTRIC_PUMP`
- `BUCKET_AND_ROPE`
- `OTHER`
- `UNKNOWN`

### 3.2 `ASSET_STATUS`
- `FUNCTIONAL`
- `NOT_FUNCTIONAL`
- `ABANDONED`
- `UNKNOWN`

Note:
- `ABANDONED_LONG_TERM` is intentionally folded into `ABANDONED`.

### 3.3 `OPERATIONAL_CONDITION`
- `NORMAL`
- `HAS_ISSUES`
- `BROKEN`
- `ABANDONED`
- `UNKNOWN`

### 3.4 `BINARY_YN_UNKNOWN`
- `YES`
- `NO`
- `UNKNOWN`

### 3.5 `PAID_FREE_SOMETIMES_UNKNOWN`
- `PAID`
- `FREE`
- `SOMETIMES`
- `UNKNOWN`

### 3.6 `YN_SOMETIMES_UNKNOWN`
- `YES`
- `NO`
- `SOMETIMES`
- `UNKNOWN`

### 3.7 `CONDITION_RATING`
- `EXCELLENT`
- `GOOD`
- `FAIR`
- `POOR`
- `VERY_POOR`
- `UNKNOWN`

### 3.8 `GOVERNANCE_EFFECTIVENESS`
- `EXCELLENT`
- `GOOD`
- `FAIR`
- `POOR`
- `UNKNOWN`

### 3.9 `FAILURE_TYPE`
- `NO_WATER_OUTPUT`
- `NOT_WORKING`
- `VALVE_WORN`
- `TAP_DAMAGED`
- `OTHER`
- `UNKNOWN`
- `NOT_APPLICABLE`

### 3.10 `AVAILABILITY_BUCKET`
- `H_0_TO_2`
- `H_3_TO_5`
- `H_6_TO_11`
- `H_12_TO_23`
- `H_24`
- `UNKNOWN`

### 3.11 `WATER_TEST_COLOR`
- `CLEAR`
- `TURBID`
- `DIRTY`
- `OTHER`
- `UNKNOWN`
- `NOT_APPLICABLE`

### 3.12 `WATER_TEST_ODOR`
- `NONE`
- `SLIGHT`
- `STRONG`
- `OTHER`
- `UNKNOWN`
- `NOT_APPLICABLE`

---

## 4) Location consistency rule (authoritative)

All coordinate positions must use the same object shape and naming:
- `location: { lat, lng }`

If enrichment stores source survey coordinates, it must use:
- `source_location: { lat, lng }`

Location quality metadata may be stored as numeric side-fields:
- `source_location_precision_m`
- `source_location_altitude_m`

Do not introduce alternate coordinate field pairs (`latitude/longitude`, mixed prefixes) in API surfaces.

---

## 5) Inclusion matrix (v1.0)

| Source column (PT) | Canonical field | Tier |
|---|---|---|
| Forma de extração | extraction_type | Public |
| Chafariz com tanque | has_tank | Public |
| Chafariz com tanque _ nº de torneira | tap_count | Public (optional) |
| Chafariz com tanque _ Cerca | has_fence | Public |
| Funcional | asset_status | Public |
| Ponto funcional | operational_condition | Public |
| Avaria | has_breakdown | Public |
| Tipo de avaria | failure_type | Public |
| Outros especifique | failure_type_other_text_raw | Admin |
| Horas por dia | hours_per_day | Public |
| (derived) | availability_bucket | Public |
| Fluxo de água | flow_value_raw | Public |
| Nº de consumidores | consumer_count | Public |
| Estado de higiene | hygiene_rating | Public |
| Drenagem | drainage_rating | Public |
| Existe GAS | governance_exists | Public |
| Como funciona | governance_effectiveness | Public |
| Em caso de avarias o GAS tem feito algo | governance_response | Public |
| As pessoas pagam pela água | payment_model | Public |
| Teste _ Cor | water_test_color | Public (optional) |
| Teste _ Odor | water_test_odor | Public (optional) |
| Teste _ Data do último teste | last_test_date | Public (optional) |
| Data da construção | construction_date | Public |
| Ultima data que funcionou | last_working_date | Public (optional) |
| Data da ultima reabilitação | last_rehab_date | Public (optional) |
| Ano de levantamento | survey_year | Public |
| Província | province | Public |
| Município | municipality | Public |
| Comuna | commune | Public |
| Bairros | neighborhood | Public (optional) |
| Latitude/Longitude | source_location | Public |
| Precisão | source_location_precision_m | Public |
| Altitude | source_location_altitude_m | Public (optional) |
| Outras observações | notes_raw | Admin |
| Problemas de falta de água | community_response_raw | Admin |
| Nome do inqueridor | interviewer_name | Admin |
| Zelador nome / telefone | caretaker_name / caretaker_phone | Admin |
| Coordenador nome / telefone | coordinator_name / coordinator_phone | Admin |
| Investidor inicial | funder_raw | Admin |
| Implementador | implementer_raw | Admin |

---

## 6) Normalization dictionary (key mappings)

### 6.1 Extraction type
- Torneira -> `TAP_STANDPIPE`
- Bomba manual / Bomba Manual -> `HAND_PUMP`
- Bomba e painel solar -> `SOLAR_PUMP`
- Electrobomba -> `ELECTRIC_PUMP`
- Balde e corda -> `BUCKET_AND_ROPE`
- Other non-empty -> `OTHER`
- Empty -> `UNKNOWN`

### 6.2 Asset status
- Sim -> `FUNCTIONAL`
- Não -> `NOT_FUNCTIONAL`
- Abandonado / Abandonado (+ 1 ano não funcional) -> `ABANDONED`
- Other/empty -> `UNKNOWN`

### 6.3 Operational condition
- Normal -> `NORMAL`
- Com problemas -> `HAS_ISSUES`
- Avariado -> `BROKEN`
- Abandonado -> `ABANDONED`
- Other/empty -> `UNKNOWN`

### 6.4 Failure type
- Não sai água -> `NO_WATER_OUTPUT`
- Não funciona -> `NOT_WORKING`
- Bocha gasta -> `VALVE_WORN`
- Torneira(s) danificadas -> `TAP_DAMAGED`
- Outros -> `OTHER`
- Abandonado -> `NOT_APPLICABLE`
- Other/empty -> `UNKNOWN`

### 6.5 Ratings
- Excelente -> `EXCELLENT`
- Boa -> `GOOD`
- Razoavel -> `FAIR`
- Mau -> `POOR`
- Péssimo -> `VERY_POOR` (for condition ratings)
- Other/empty -> `UNKNOWN`

### 6.6 Binary and tri-state
- Sim -> `YES` (or `PAID` for payment model)
- Não -> `NO` (or `FREE` for payment model)
- Por vezes -> `SOMETIMES`
- Other/empty -> `UNKNOWN`

### 6.7 Water tests
- Cor: Incolor -> `CLEAR`; Turva -> `TURBID`; Suja -> `DIRTY`; Abandonado -> `NOT_APPLICABLE`; other -> `OTHER`; empty -> `UNKNOWN`
- Odor: Sem cheiro(/sabor) -> `NONE`; Com cheiro ligeiro -> `SLIGHT`; Com cheiro -> `STRONG`; Abandonado -> `NOT_APPLICABLE`; other -> `OTHER`; empty -> `UNKNOWN`

---

## 7) Ingestion and status precedence guardrails

1. Sparse fields are optional.
2. Store normalized + raw/admin data together in one table (`supply_points`) with API-layer exposure controls.
3. Import is idempotent by `(source_dataset, source_record_id)`.
4. New imported rows are created as `VERIFIED`.
5. Survey baseline can fill core status only when current status is unknown/unset.
6. Survey imports must not overwrite stronger post-baseline evidence.

---

## 8) Provenance fields (required)

Public enrichment must include:
- `normalization_version`
- `source_dataset`
- `source_record_id`
- `source_row_hash`
