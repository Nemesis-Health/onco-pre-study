# SQL Translation Report

Generated: 2026-05-06 18:54:10 BST
Source: `sql/sql_server/`
Dialects: oracle, postgresql, pdw, impala, netezza, bigquery, spark, sqlite, redshift, hive, sqlite extended, duckdb, snowflake, synapse, iris

## Chunk reference

| Chunk | Description | Output file(s) | Output description |
|---|---|---|---|
| `00_setup.sql` | Pure setup — no SELECT output. Builds all intermediate temp tables: concept sets (DX anchor, GDX, ODX, MET, L01), raw event tables, per-patient summary tables, crosswise timing pair tables, death/follow-up timing tables, and L01 consecutive gap tables. All downstream chunks read from these temps. | _(none)_ | _(no CSV exported)_ |
| `01_population_prevalence.sql` | Counts cohort size and event-type prevalence by calendar year of first diagnosis (index date), plus an OVERALL row. Small-cell suppression applied. | `final_population_prevalence.csv` | One row per year + OVERALL. Columns: `prevalence_year`, `n_dx` (cohort size), `n_odx`, `n_gdx`, `n_met`, `n_l01` — number of patients with each event type that year. |
| `02_code_counts.sql` | For every concept code in every event family (DX, ODX, GDX, MET, L01), reports record counts, patient counts, and timing quartiles relative to the anchor date. Covers three time windows (all / before / after anchor) and two anchors (INDEX = first DX, FIRST_MET). Timing is computed two ways: using each patient's **first** occurrence of the code, and the **closest** occurrence to the anchor. | `final_code_counts.csv` | One row per `(time_window × anchor_event × event_family × concept_id)`. Columns include `n_records`, `n_patients`, and LQ/median/UQ for both first and closest timing (days relative to anchor). |
| `03_directionality_buckets.sql` | Classifies each patient's relative timing between key event pairs into direction buckets. Covers DX→MET (all cohort patients) and MET→L01 (metastatic sub-cohort). Buckets: `BEFORE_GT90`, `BEFORE_1_90`, `SAME_DAY`, `AFTER_1_30`, `AFTER_31_90`, `AFTER_91_365`, `AFTER_GT365`, `NO_EVENT`. Stratified by OVERALL and by index year. | `final_directionality.csv` | One row per `(pair × index_year × direction)`. Columns: `pair` (DX_MET or MET_L01), `index_year`, `direction`, `n_patients`. |
| `04_timing_pairwise.sql` | Full pairwise timing distribution across all event families (DX, ODX, GDX, MET, L01) for four timing strategies: first-to-first, first-to-closest, first-to-closest-before, first-to-closest-after. Reports 13 percentiles (p05–p95). | `final_timing_pairwise.csv` | One row per `(timing_type × from_event × to_event)`. Columns: `n_patients_with_pair`, `p05_days` through `p95_days`. |
| `05_timing_by_year.sql` | Same pairwise timing as chunk 04 but stratified by calendar year of index date; reduced to IQR only (p25/p50/p75). Covers `first_to_first` and `first_to_closest_after` timing types. Used for year-over-year trend plots and the stability matrix in the report. | `final_timing_by_year.csv` | One row per `(timing_type × index_year × from_event × to_event)`. Columns: `n_patients_with_pair`, `p25_days`, `p50_days`, `p75_days`. |
| `06_windowed_odx_prevalence.sql` | For each ODX and GDX concept, counts distinct patients with at least one event in seven time windows around the DX index date: ±30d, ±90d, ±180d, ±1yr, ever-before, ever-after, and ever (all time). Helps characterise co-occurring cancer diagnoses relative to cohort entry. | `final_windowed_odx_prevalence.csv` | One row per `(event_family × concept_id)`. Columns: `n_ever`, `n_pm30d`, `n_pm90d`, `n_pm180d`, `n_pm1yr`, `n_ever_before`, `n_ever_after`. |
| `07_l01_treatment_windows.sql` | Counts L01 (antineoplastic) drug exposures in consecutive 30-day windows around two anchors: INDEX (windows −12 to +47, covering 3 years post-DX) and FIRST_MET (windows −6 to +23, covering 2 years post-MET). Denominator is patients observed at each window's midpoint, adjusting for censoring. | `final_l01_treatment_windows.csv` | One row per `(anchor_event × window_index)`. Columns: `n_eligible`, `n_observed` (denominator), `n_patients_with_l01`. |
| `08_death_timing.sql` | Summarises deaths relative to INDEX and FIRST_MET anchors, stratified by calendar year of index date and OVERALL. Includes death counts (total, within and outside observation period), IQR of days from anchor to death, and IQR of follow-up duration (anchor to last observation period end). | `final_death_from_anchors.csv` | One row per `(prevalence_year × anchor_event)`. Columns: `n_patients`, `n_deaths`, `n_deaths_in_obs`, `n_deaths_out_obs`, LQ/median/UQ `days` to death, LQ/median/UQ `followup_days`. |
| `09_demographics.sql` | Gender split and age distribution at anchor date for INDEX and FIRST_MET cohorts. Age is computed from `birth_datetime` if available, otherwise estimated from `year_of_birth` (assumes 1 July). | `final_demographics_from_anchors.csv` | Two rows (one per anchor). Columns: `n_patients`, `n_male`, `n_female`, `pct_male`, `pct_female`, `age_lq_years`, `age_median_years`, `age_uq_years`. |
| `10_anchor_dx_codes.sql` | For each specific condition concept in the DX anchor concept set, reports distinct patient count and distinct patient-day count. Shows which diagnosis codes are driving cohort membership and how frequently they recur. | `final_anchor_dx_concept_counts.csv` | One row per `concept_id`. Columns: `n_distinct_patients`, `n_distinct_patient_days`. |
| `11_l01_gap_deciles.sql` | Summarises the distribution of consecutive gaps between L01 exposure records (i.e. days between successive treatment dates per patient) using decile percentiles (p10/p25/p50/p75/p90). Two subgroups: ALL_L01 (all patients with any L01) and MET_L01 (patients with metastasis). | `final_l01_gap_deciles.csv` | Two rows (one per subgroup). Columns: `n_gaps`, `n_patients_with_gaps`, `p10_days`, `p25_days`, `p50_days`, `p75_days`, `p90_days`. |
| `12_l01_gap_buckets.sql` | Histograms the same L01 consecutive gaps as chunk 11 into six 30–365-day buckets: `lt30d`, `30_59d`, `60_89d`, `90_179d`, `180_364d`, `ge365d`. Two subgroups (ALL_L01, MET_L01). | `final_l01_gap_buckets.csv` | One row per `(subgroup × gap_bucket)`. Columns: `subgroup`, `gap_bucket`, `n_gaps`. |
| `13_death_gap_summary.sql` | For patients whose recorded death date falls **outside** their observation period, reports the count with death before obs start (data quality flag) and death after obs end, plus percentiles (LQ/median/UQ/p90) of the post-obs gap in days. Stratified by INDEX and FIRST_MET anchors. | `final_death_gap_summary.csv` | Two rows (one per anchor). Columns: `anchor_event`, `n_death_before_obs`, `n_death_after_obs`, `lq_gap_days`, `median_gap_days`, `uq_gap_days`, `p90_gap_days`. |
| `14_death_gap_buckets.sql` | Histogram of the post-observation-period death gap (days between last obs period end and death date), restricted to patients where death follows obs end. Binned at 30-day intervals up to 730 days, with a final `ge730d` bucket. INDEX anchor only (FIRST_MET subset closely mirrors it). | `final_death_gap_buckets.csv` | One row per `gap_bucket`. Columns: `gap_bucket` (`lt30d`, `30_59d`, `60_89d`, `90_179d`, `180_364d`, `365_729d`, `ge730d`), `n_patients`. |

## Dialect notes

Dialects requiring `tempEmulationSchema` at execution time (no native session temp tables): **oracle, bigquery, spark, hive, impala, pdw, netezza**.

## Pattern warnings

### oracle/characterization_full.sql

- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/00_setup.sql

- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/03_directionality_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### oracle/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/characterization_full.sql

- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/00_setup.sql

- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/03_directionality_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### postgresql/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/characterization_full.sql

- [characterization_full.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [characterization_full.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.

### pdw/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.

### pdw/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### pdw/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### pdw/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### pdw/chunks/06_windowed_odx_prevalence.sql

- [chunks/06_windowed_odx_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/13_death_gap_summary.sql

- [chunks/13_death_gap_summary.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/14_death_gap_buckets.sql

- [chunks/14_death_gap_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### impala/characterization_full.sql

- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/00_setup.sql

- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### impala/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/03_directionality_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### impala/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/characterization_full.sql

- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/00_setup.sql

- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/03_directionality_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### netezza/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/characterization_full.sql

- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/00_setup.sql

- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/03_directionality_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### bigquery/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### spark/characterization_full.sql

- [characterization_full.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.

### spark/chunks/00_setup.sql

- [chunks/00_setup.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.

### spark/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### spark/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### spark/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### spark/chunks/06_windowed_odx_prevalence.sql

- [chunks/06_windowed_odx_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/09_demographics.sql

- [chunks/09_demographics.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/13_death_gap_summary.sql

- [chunks/13_death_gap_summary.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/14_death_gap_buckets.sql

- [chunks/14_death_gap_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### sqlite/characterization_full.sql

- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/00_setup.sql

- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/03_directionality_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### sqlite/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/characterization_full.sql

- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.

### redshift/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.

### redshift/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### redshift/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### redshift/chunks/06_windowed_odx_prevalence.sql

- [chunks/06_windowed_odx_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/13_death_gap_summary.sql

- [chunks/13_death_gap_summary.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/14_death_gap_buckets.sql

- [chunks/14_death_gap_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### hive/characterization_full.sql

- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/00_setup.sql

- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### hive/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/03_directionality_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### hive/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/characterization_full.sql

- [characterization_full.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [characterization_full.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### sqlite_extended/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/03_directionality_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### sqlite_extended/chunks/06_windowed_odx_prevalence.sql

- [chunks/06_windowed_odx_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### sqlite_extended/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### sqlite_extended/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/13_death_gap_summary.sql

- [chunks/13_death_gap_summary.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### sqlite_extended/chunks/14_death_gap_buckets.sql

- [chunks/14_death_gap_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### duckdb/characterization_full.sql

- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/00_setup.sql

- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### duckdb/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/03_directionality_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### duckdb/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/characterization_full.sql

- [characterization_full.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.

### snowflake/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/03_directionality_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### snowflake/chunks/06_windowed_odx_prevalence.sql

- [chunks/06_windowed_odx_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### snowflake/chunks/08_death_timing.sql

- [chunks/08_death_timing.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.

### snowflake/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### snowflake/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/13_death_gap_summary.sql

- [chunks/13_death_gap_summary.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### snowflake/chunks/14_death_gap_buckets.sql

- [chunks/14_death_gap_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/characterization_full.sql

- [characterization_full.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [characterization_full.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.

### synapse/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.

### synapse/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### synapse/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### synapse/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### synapse/chunks/06_windowed_odx_prevalence.sql

- [chunks/06_windowed_odx_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/13_death_gap_summary.sql

- [chunks/13_death_gap_summary.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/14_death_gap_buckets.sql

- [chunks/14_death_gap_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### iris/characterization_full.sql

- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### iris/chunks/03_directionality_buckets.sql

- [chunks/03_directionality_buckets.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/03_directionality_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/05_timing_by_year.sql

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### iris/chunks/06_windowed_odx_prevalence.sql

- [chunks/06_windowed_odx_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### iris/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### iris/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/13_death_gap_summary.sql

- [chunks/13_death_gap_summary.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### iris/chunks/14_death_gap_buckets.sql

- [chunks/14_death_gap_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

