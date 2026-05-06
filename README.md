# onco-pre-study

OMOP characterization scripts for urothelial carcinoma (UC) malignant neoplasm cohorts.
Produces population prevalence, event code counts, pairwise timing, and death metrics
across anchor families (DX, ODX, GDX, MET, L01).

## Repository layout

```
sql/
└── sql_server/
    ├── characterization_full.sql     # Complete monolithic query (auto-built from chunks)
    └── chunks/
        ├── 00_setup.sql              # Concept sets, event tables, cohort, summaries (no SELECT output)
        ├── 01_population_prevalence.sql
        ├── 02_code_counts.sql
        ├── 03_directionality_buckets.sql
        ├── 04_timing_pairwise.sql
        ├── 05_timing_by_year.sql
        ├── 06_windowed_odx_prevalence.sql
        ├── 07_l01_treatment_windows.sql
        ├── 08_death_timing.sql
        ├── 09_demographics.sql
        ├── 10_anchor_dx_codes.sql
        ├── 11_l01_gap_deciles.sql
        ├── 12_l01_gap_buckets.sql
        ├── 13_death_gap_summary.sql
        └── 14_death_gap_buckets.sql

scripts/
├── build_full_sql.py                 # Concatenates chunks → characterization_full.sql
├── translate_sql_dialects.R          # Translates to 14 other dialects via SqlRender
└── build_v4_report.py               # Generates outputs_v2/summary_report_v4.html

outputs_v2/               # CSV results land here; summary_report_v4.html is generated here
```

## Generating the report

Place the characterization CSVs in `outputs_v2/` (see [Result chunks](#result-chunks) for filenames), then run:

```bash
python3 scripts/build_v4_report.py outputs_v2
```

The report is written to `outputs_v2/summary_report_v4.html`. Chunks whose CSVs are absent degrade gracefully with amber callouts in the report rather than erroring.

## SQL dialect

The primary dialect is **SQL Server** (T-SQL) with [SqlRender](https://github.com/OHDSI/SqlRender)-style
parameters (`@cdm_database_schema`, `@min_cell_count`). Translations to other dialects
(Snowflake, PostgreSQL, etc.) are planned under `sql/<dialect>/`.

To render for a specific target database:
```r
library(SqlRender)
sql <- readSql("sql/sql_server/characterization_full.sql")
rendered <- render(sql, cdm_database_schema = "cdm", min_cell_count = 5)
translated <- translate(rendered, targetDialect = "postgresql")
```

## The characterization query

**Version:** v2 — dual concept-level event-code timing (FIRST + CLOSEST)

**Cohort anchor:** UC malignant neoplasm (UC.json concept set id 7), expanded via
`concept_ancestor`. Excludes renal pelvis / ureteral / overlapping-site concepts
per the exclusion list in section A.

**Event families tracked:**
| Label | Source table | Description |
|-------|-------------|-------------|
| DX | condition_occurrence | Anchor UC diagnosis concepts |
| ODX | condition_occurrence | Other malignant neoplasm diagnoses |
| GDX | condition_occurrence | Generalized cancer ancestors of DX |
| MET | measurement | Metastasis / AJCC stage 4 / M1 concepts |
| L01 | drug_exposure | L01 antineoplastic drugs (ingredient level) |

**Timing rules (both computed per run):**
- **FIRST** — earliest `event_date` per (anchor, family, concept, patient)
- **CLOSEST** — minimum `|days_diff|` to anchor date, tie-break by event_date

**Privacy:** small cells ≤ `@min_cell_count` are replaced with `-@min_cell_count` sentinels.

### Setup chunk (`00_setup.sql`)

Builds all temp tables (no result returned). Sections:

| Section | Tables created |
|---------|---------------|
| A | `#dx_anchor_include/exclude/concepts` |
| B | `#gen_cancer_concepts` |
| C | `#other_dx_concepts` |
| D | `#met_concepts` |
| E | `#l01_concepts` |
| F | Event tables: `#dx_events`, `#other_dx_events`, `#gen_cancer_events`, `#met_events`, `#l01_events`, `#l01_ingredient_events`, `#anchor_person` |
| G | Cohort + summaries: `#cohort`, `#dx_summary`, `#other_dx_summary`, `#gen_cancer_summary`, `#met_summary`, `#l01_summary` |
| H | Code counts + timing: `#event_code_counts`, `#event_code_counts_before_after`, `#event_code_timing_summary`, etc. |
| I | `#patient_char` (one row per patient) |
| J | `#patient_timing_pairs`, `#timing_pair_summary` (first-to-first and first-to-closest variants) |
| J-bis | Death timing: `#death_timing_long`, `#death_timing_quantiles`, `#death_stratum_counts` |

### Result chunks

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
| `08_death_timing.sql` | Summarises deaths relative to INDEX and FIRST_MET anchors, stratified by calendar year of index date and OVERALL. Includes death counts (total, within and outside observation period), IQR of days from anchor to death, and IQR of follow-up duration (anchor to last observation period end). | `final_death_from_anchors.csv` | One row per `(prevalence_year × anchor_event)`. Columns: `n_patients`, `n_deaths`, `n_deaths_in_obs`, `n_deaths_out_obs`, LQ/median/UQ days to death, LQ/median/UQ follow-up days. |
| `09_demographics.sql` | Gender split and age distribution at anchor date for INDEX and FIRST_MET cohorts. Age is computed from `birth_datetime` if available, otherwise estimated from `year_of_birth` (assumes 1 July). | `final_demographics_from_anchors.csv` | Two rows (one per anchor). Columns: `n_patients`, `n_male`, `n_female`, `pct_male`, `pct_female`, `age_lq_years`, `age_median_years`, `age_uq_years`. |
| `10_anchor_dx_codes.sql` | For each specific condition concept in the DX anchor concept set, reports distinct patient count and distinct patient-day count. Shows which diagnosis codes drive cohort membership and how frequently they recur. | `final_anchor_dx_concept_counts.csv` | One row per `concept_id`. Columns: `n_distinct_patients`, `n_distinct_patient_days`. |
| `11_l01_gap_deciles.sql` | Summarises the distribution of consecutive gaps between L01 exposure records (days between successive treatment dates per patient) using decile percentiles (p10/p25/p50/p75/p90). Two subgroups: ALL_L01 (all patients with any L01) and MET_L01 (patients with metastasis). | `final_l01_gap_deciles.csv` | Two rows (one per subgroup). Columns: `n_gaps`, `n_patients_with_gaps`, `p10_days`, `p25_days`, `p50_days`, `p75_days`, `p90_days`. |
| `12_l01_gap_buckets.sql` | Histograms the same L01 consecutive gaps as chunk 11 into six buckets: `lt30d`, `30_59d`, `60_89d`, `90_179d`, `180_364d`, `ge365d`. Two subgroups (ALL_L01, MET_L01). | `final_l01_gap_buckets.csv` | One row per `(subgroup × gap_bucket)`. Columns: `subgroup`, `gap_bucket`, `n_gaps`. |
| `13_death_gap_summary.sql` | For patients whose recorded death date falls outside their observation period, reports counts of death before obs start (data quality flag) and death after obs end, plus percentiles (LQ/median/UQ/p90) of the post-obs gap in days. Stratified by INDEX and FIRST_MET anchors. | `final_death_gap_summary.csv` | Two rows (one per anchor). Columns: `anchor_event`, `n_death_before_obs`, `n_death_after_obs`, `lq_gap_days`, `median_gap_days`, `uq_gap_days`, `p90_gap_days`. |
| `14_death_gap_buckets.sql` | Histogram of the post-observation-period death gap (days between last obs period end and death date), restricted to patients where death follows obs end. Binned at 30-day intervals up to 730 days, with a final `ge730d` bucket. INDEX anchor only (FIRST_MET subset closely mirrors it). | `final_death_gap_buckets.csv` | One row per `gap_bucket`. Columns: `gap_bucket` (`lt30d`, `30_59d`, `60_89d`, `90_179d`, `180_364d`, `365_729d`, `ge730d`), `n_patients`. |
