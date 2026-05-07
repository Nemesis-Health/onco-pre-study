# v4 Report — Figure & Table Reference

Every element in `build_v4_report.py`, section by section.
Columns are resolved case-insensitively from the CSVs listed under **Source**.

---

## Section 0 — Cohort Overview & Population Prevalence

### Stat box row 1

**Source:** `final_population_prevalence.csv` (OVERALL row), `final_demographics_from_anchors.csv` (INDEX anchor row)


| Box               | Value                   | Denominator |
| ----------------- | ----------------------- | ----------- |
| DX cohort         | `n_dx` (OVERALL row)    | —           |
| Metastasis (MET)  | `n_met`                 | `n_dx`      |
| Any L01 treatment | `n_l01`                 | `n_dx`      |
| No L01 ever       | `(n_dx − n_l01) / n_dx` | `n_dx`      |


### Stat box row 2


| Box                             | Value                             | Denominator |
| ------------------------------- | --------------------------------- | ----------- |
| Co-occurring other cancer (ODX) | `n_odx`                           | `n_dx`      |
| Broader/non-specific DX (GDX)   | `n_gdx`                           | `n_dx`      |
| Median age at DX                | `age_median_years` (INDEX anchor) | —           |
| Sex                             | `pct_male` (INDEX anchor)         | —           |


Age IQR shown as `age_lq_years`–`age_uq_years`.

### Cohort attrition note

**Source:** `final_cohort_attrition.csv`

Displays `n_excluded_no_obs_dx` as a percentage of `n_dx_any`. Shown as inline paragraph if present.

---

### Figure 0.1 — Population prevalence by calendar year

**Source:** `final_population_prevalence.csv` (year rows only, `prevalence_year != OVERALL`, year ≥ 2010)

**Type:** Dual-axis combo chart (bars + lines)


| Series                  | Column               | Axis                |
| ----------------------- | -------------------- | ------------------- |
| DX cohort (N)           | `n_dx`               | Left (bar)          |
| % Metastasis (MET)      | `n_met / n_dx × 100` | Right (line)        |
| % Antineoplastic (L01)  | `n_l01 / n_dx × 100` | Right (dotted line) |
| % Other cancer DX (ODX) | `n_odx / n_dx × 100` | Right (dashed line) |


X-axis = `prevalence_year` as integer, tick every 2 years.

---

### Table 0.1 — Demographics by anchor cohort

**Source:** `final_demographics_from_anchors.csv`

One row per value of `anchor_event`. Columns displayed: N (`n_patients`), median age IQR (`age_median_years`, `age_lq_years`, `age_uq_years`), `pct_male`, `pct_female`. Label: INDEX → "Cancer of interest — first DX"; FIRST_MET → "Metastasis — first MET".

---

### Table 0.2 — Top 10 anchor DX concepts

**Source:** `final_anchor_dx_concept_counts.csv`

Top 10 rows by `n_distinct_patients` (positive values only). Concept names fetched live from OMOP `concept` table if DB available. Columns: rank, concept_id, concept_name, `n_distinct_patients`, `n_distinct_patient_days`, `n_distinct_patients / n_dx` (%).

---

## Section 1 — Disease Code Timing & Sequencing

### Table 1.1 — DX ↔ MET temporal directionality

**Source:** `final_directionality.csv` (pair = `DX_MET`, `index_year = OVERALL`)

Denominator = `n_dx` (from OVERALL row of `final_population_prevalence.csv`).

Rows in order: `BEFORE_GT90`, `BEFORE_1_90`, `SAME_DAY`, `AFTER_1_30`, `AFTER_31_90`, `AFTER_91_365`, `AFTER_GT365`, `NO_EVENT`. Each row shows N (`n_patients`), % of DX cohort, and an interpretation string. BEFORE rows are flagged red; NO_EVENT is flagged amber.

---

### Figure 1.1 — Time from first DX to first MET (full distribution)

**Source:** `final_timing_pairwise.csv` (`from_event = DX`, `to_event = MET`, `timing_type = first_to_first`)

**Type:** Density histogram approximated from percentiles

Bins constructed from percentile columns: `p05_days`, `p10_days`, `p20_days`, `p25_days`, `p30_days`, `p40_days`, `p50_days`, `p60_days`, `p70_days`, `p75_days`, `p80_days`, `p90_days`, `p95_days`.


| Bin                            | X centre | Width       | Height (density) |
| ------------------------------ | -------- | ----------- | ---------------- |
| p05–p10                        | midpoint | `p10 − p05` | `5% / width`     |
| p10–p20                        | midpoint | `p20 − p10` | `10% / width`    |
| … same pattern through p90–p95 |          |             |                  |


Bar colour: **red** if bin entirely < 0, **purple** if bin straddles 0, **blue** otherwise. Median annotated with dotted amber line and IQR label. A red-shaded region marks the negative (pre-DX) territory. Subtitle shows `median Xd (IQR Y–Z)`. Denominator count = `n_patients_with_pair`.

---

### Figure 1.2 — DX→MET median days by index year

**Source:** `final_timing_by_year.csv` (`from_event = DX`, `to_event = MET`, `timing_type = first_to_first`, year ≥ 2010)

**Type:** Heatmap table (HTML, not Plotly)

One cell per year. Value = `p50_days` rounded to integer. Cell class `hm-1` through `hm-5` assigned by linear interpolation between observed min and max median. Grey (`hm-0`) for missing years.

---

## Section 2 — Broader & Co-occurring Cancer Codes (GDX / ODX)

### Table 2.1 — Most frequent GDX concepts

**Source:** `final_code_counts.csv` (`anchor_event = INDEX`, `event_family = GDX`, `time_window = all`)

Top 15 rows by `n_patients`. Columns: rank, concept_id, concept_name (live lookup), `n_patients`, `n_patients / n_dx` (%).

---

### Table 2.2 — Windowed ODX prevalence relative to DX index date

**Source:** `final_windowed_odx_prevalence.csv` (`event_family = ODX`)

Top 10 concepts by `n_ever`. One row per concept. Window columns shown (when present): `n_pm30d` (±30d), `n_pm90d` (±90d), `n_pm180d` (±180d), `n_pm1yr` (±1yr), `n_ever_before`, `n_ever_after`, `n_ever`. All values are raw N counts.

---

### Figure 2.1 — Windowed ODX prevalence for top 5 concepts

**Source:** `final_windowed_odx_prevalence.csv` (`event_family = ODX`)

**Type:** Grouped bar chart

Top 5 concepts by `n_ever`. X-axis = time windows (±30d, ±90d, ±180d, ±1yr, Ever before, Ever after). Y-axis = `window_count / n_dx × 100` (% of DX cohort). One bar group per concept. Concept names from live DB lookup.

---

### Figure 2.2 — ODX timing relative to DX index (full distribution)

**Source:** `final_timing_pairwise.csv` (`from_event = DX`, `to_event = ODX`, `timing_type = first_to_first`)

**Type:** Density histogram — same construction as Figure 1.1 but purple colour scheme. Negative region = ODX code precedes DX.

---

## Section 3 — Treatment Timing & Data Provenance Signals

### Table 3.1 — MET ↔ L01 temporal directionality

**Source:** `final_directionality.csv` (pair = `MET_L01`, `index_year = OVERALL`)

Denominator = `n_met` (from `final_population_prevalence.csv` OVERALL row, i.e. the MET subgroup).

Same 8-direction row order as Table 1.1. Column 4 header = "Phenotype implication". `NO_EVENT` (amber) = patients with MET but no L01 ever recorded; clinically this is the investigational drug / trial enrollment signal.

---

### Figure 3.1 — Time from first MET to first L01 (bidirectional, full range)

**Source:** `final_timing_pairwise.csv` (`from_event = MET`, `to_event = L01`)

**Type:** Overlaid density histogram (two series)


| Series                         | `timing_type`            | Fill  | Meaning                                                   |
| ------------------------------ | ------------------------ | ----- | --------------------------------------------------------- |
| First-ever L01 (incl. pre-MET) | `first_to_first`         | Blue  | First L01 occurrence relative to first MET, any direction |
| First L01 on/after MET         | `first_to_closest_after` | Amber | First L01 on or after the MET date                        |


Each series uses the same percentile-to-bin construction as Figure 1.1. Median dotted lines shown per series. Bars overlap (`barmode = overlay`).

---

### Table 3.2 — Drug-level L01 timing around MET (top 15)

**Source:** `final_code_counts.csv` (`anchor_event = FIRST_MET`, `event_family = L01`)

Top 15 concepts by `n_patients` where `time_window = all`.


| Column                             | Source                                                                          | Notes                         |
| ---------------------------------- | ------------------------------------------------------------------------------- | ----------------------------- |
| N patients                         | `n_patients` (time_window=all)                                                  |                               |
| % of MET cohort                    | `n_patients / n_met`                                                            | denominator = OVERALL `n_met` |
| % with record before MET           | `n_patients` (time_window=before) / N total                                     |                               |
| % with record after MET            | `n_patients` (time_window=after) / N total                                      |                               |
| Median days IQR — first occurrence | `median_days_first`, `lq_days_first`, `uq_days_first` (time_window=all)         |                               |
| Median days IQR — closest after    | `median_days_closest`, `lq_days_closest`, `uq_days_closest` (time_window=after) |                               |


---

## Section 4 — Longitudinal Treatment Exposure

### Figures 4.1 & 4.2 — % cohort with L01 per 30-day window

**Source:** `final_l01_treatment_windows.csv`

**Type:** Line chart (one line per `anchor_event` value)


| Column                | Role                                              |
| --------------------- | ------------------------------------------------- |
| `anchor_event`        | Series key: `INDEX` (navy) or `FIRST_MET` (amber) |
| `window_index`        | X-axis: multiplied by 30 to convert to days       |
| `n_patients_with_l01` | Numerator                                         |
| `n_observed`          | Denominator                                       |


Y-axis = `n_patients_with_l01 / n_observed × 100`. Missing `n_observed` falls back to raw `n_patients_with_l01`. Note: at time of writing both figures use the same data (DX/MET-anchored outputs not yet separated).

---

### Figure 4.3 — Distribution of gaps between consecutive L01 records

**Source:** `final_l01_gap_buckets.csv`

**Type:** Grouped bar chart

Bucket order: `lt30d`, `30_59d`, `60_89d`, `90_179d`, `180_364d`, `365_729d`, `ge365d`, `ge730d`. Grouped by `subgroup` column (values: `ALL_L01` navy, `MET_L01` amber). Y = raw count from `n_gaps` (or `n_patients` if absent).

Note: `final_l01_gap_buckets.csv` also contains `ALL_L01_MAX` and `MET_L01_MAX` subgroups (one gap per patient — the largest gap only). These are not currently rendered in this figure.

---

### Table 4.1 — L01 gap distribution summary

**Sources:** `final_l01_gap_deciles.csv`, `final_l01_gap_buckets.csv`, `final_population_prevalence.csv`

Fixed rows, two columns (All L01 / MET subgroup). Uses `ALL_L01` and `MET_L01` subgroups only (all gaps, not max-gap):


| Row                          | Source                                                   |
| ---------------------------- | -------------------------------------------------------- |
| Patients with ≥2 L01 records | `n_patients_with_gaps` from gap_deciles                  |
| Median gap days (IQR)        | `p50_days`, `p25_days`, `p75_days` from gap_deciles      |
| % gaps < 30d                 | `n_gaps` for bucket `lt30d` / total `n_gaps` in subgroup |
| % gaps 30–59d                | bucket `30_59d`                                          |
| % gaps 60–89d                | bucket `60_89d`                                          |
| % gaps 90–179d               | bucket `90_179d`                                         |
| % gaps ≥ 180d                | bucket `ge180d`                                          |


Subgroup keys: `ALL_L01`, `MET_L01` (matched via `subgroup` column).

---

## Section 5 — Observation Period, Death & Survival Validity

### Stat boxes

**Source:** `final_death_from_anchors.csv` (`anchor_event = INDEX`, `prevalence_year = OVERALL`)


| Box                            | Value                                           | % denominator |
| ------------------------------ | ----------------------------------------------- | ------------- |
| Deaths recorded                | `n_deaths`                                      | `n_patients`  |
| Death within obs. period       | `n_deaths_in_obs`                               | `n_deaths`    |
| Death AFTER obs. period end    | `n_deaths_out_obs`                              | `n_deaths`    |
| Death BEFORE obs. period start | `n_deaths − n_deaths_in_obs − n_deaths_out_obs` | `n_deaths`    |


---

### Table 5.1 — Death vs observation period alignment

**Source:** `final_death_from_anchors.csv` (`anchor_event = INDEX`, `prevalence_year = OVERALL`)

Three fixed category rows:


| Category                       | N                     | % denominator | Gap (IQR)                           |
| ------------------------------ | --------------------- | ------------- | ----------------------------------- |
| Death within obs. period       | `n_deaths_in_obs`     | `n_patients`  | —                                   |
| Death AFTER obs. period end    | `n_deaths_out_obs`    | `n_patients`  | `median_days`, `lq_days`, `uq_days` |
| Death BEFORE obs. period start | `n_deaths − in − out` | `n_patients`  | —                                   |


---

### Table 5.2 — Deaths by year: inside vs outside observation period

**Source:** `final_death_from_anchors.csv` (`anchor_event = INDEX`)

One row per `prevalence_year` ≥ 2010, plus an OVERALL summary row. Columns: year, anchor, N (`n_patients`), Deaths % (`n_deaths / n_patients`), Deaths in obs (`n_deaths_in_obs`), Deaths outside obs (`n_deaths_out_obs` + % of n_deaths), follow-up days IQR (`median_followup_days`, `lq_followup_days`, `uq_followup_days`).

---

### Figure 5.1 — Gap distribution: death date − obs. period end

**Source:** `final_death_gap_buckets.csv`

**Type:** Bar chart (single series, no subgroup grouping)

Same bucket order as Figure 4.3. Y = `n_patients`. Shows only patients whose death date falls outside their observation window.

---

### Figure 5.2 — Deaths by calendar year: inside vs outside obs. period

**Source:** `final_death_from_anchors.csv` (`anchor_event = INDEX`, year rows ≥ 2010)

**Type:** Dual-axis combo chart


| Series                       | Column                              | Axis                      |
| ---------------------------- | ----------------------------------- | ------------------------- |
| N DX                         | `n_patients`                        | Left (bar)                |
| % Deceased                   | `n_deaths / n_patients × 100`       | Right (red line)          |
| % Deaths in obs. period      | `n_deaths_in_obs / n_deaths × 100`  | Right (green dotted line) |
| % Deaths outside obs. period | `n_deaths_out_obs / n_deaths × 100` | Right (amber dashed line) |


---

## Section 6 — Year-over-Year Stability

### Table 6.1 — Timing summary matrix by index year

**Sources:** `final_population_prevalence.csv`, `final_timing_by_year.csv`, `final_directionality.csv`, `final_death_from_anchors.csv`

One row per index year ≥ 2010. Columns:


| Column                | Source & logic                                                                       |
| --------------------- | ------------------------------------------------------------------------------------ |
| N (DX)                | `n_dx` from prev_by_year                                                             |
| N (MET)               | `n_met` from prev_by_year                                                            |
| % MET before DX       | directionality pair=`DX_MET`, direction=`BEFORE_GT90`, `n_patients / n_met` per year |
| DX→MET median (d)     | `p50_days` from by_year (`from=DX`, `to=MET`, `timing_type=first_to_first`)          |
| % L01 before MET      | directionality pair=`MET_L01`, direction=`NO_EVENT`, `n_patients / n_met` per year   |
| MET→L01 median (d)    | `p50_days` from by_year (`from=MET`, `to=L01`, `timing_type=first_to_first`)         |
| % no L01 (MET cohort) | not yet populated (shown as —)                                                       |
| % death outside obs.  | `n_deaths_out_obs / n_deaths` from death_by_year (INDEX anchor)                      |


---

### Figure 6.1 — Key timing metrics by index year

**Source:** `final_timing_by_year.csv` (year ≥ 2010)

**Type:** Multi-line chart


| Series           | Filter                                             | Column     | Style        |
| ---------------- | -------------------------------------------------- | ---------- | ------------ |
| DX→MET (median)  | `from=DX`, `to=MET`, `timing_type=first_to_first`  | `p50_days` | Navy solid   |
| MET→L01 (median) | `from=MET`, `to=L01`, `timing_type=first_to_first` | `p50_days` | Green dotted |


X = `index_year`, Y = median days (first-to-first).

---

### Table 6.2 — DX→MET directionality by index year

**Source:** `final_directionality.csv` (pair=`DX_MET`, year rows ≥ 2010, excluding `SAME_DAY`)

Pivot: rows = direction categories (7 directions excluding SAME_DAY), columns = years. Values = raw `n_patients` per direction × year. Rendered as a scrollable HTML table.