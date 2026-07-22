# SQL Translation Report

Generated: 2026-07-15 15:37:54 CEST
Source: `sql/sql_server/`
Dialects: oracle, postgresql, pdw, impala, netezza, bigquery, spark, sqlite, redshift, hive, sqlite extended, duckdb, snowflake, synapse, iris

## Dialect notes

Dialects requiring `tempEmulationSchema` at execution time (no native session temp tables): **oracle, bigquery, spark, hive, impala, pdw, netezza**.

## Pattern warnings

### oracle/characterization_full.sql

- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
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

### oracle/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/06_odx_gdx_directional_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### oracle/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/15_l01_day_count_buckets.sql

- [chunks/15_l01_day_count_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/18_f_index_event_record_counts.sql

- [chunks/18_f_index_event_record_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/20_d_met_first_ordering.sql

- [chunks/20_d_met_first_ordering.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/21_d_met_first_dx_support.sql

- [chunks/21_d_met_first_dx_support.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/24_h_closest_treatment_placement.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/29_g_treatment_signal_source.sql

- [chunks/29_g_treatment_signal_source.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/30_g_procedure_only_by_concept.sql

- [chunks/30_g_procedure_only_by_concept.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/31_g_procedure_timing_vs_met.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/characterization_full.sql

- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
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

### postgresql/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/06_odx_gdx_directional_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### postgresql/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/15_l01_day_count_buckets.sql

- [chunks/15_l01_day_count_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/18_f_index_event_record_counts.sql

- [chunks/18_f_index_event_record_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/20_d_met_first_ordering.sql

- [chunks/20_d_met_first_ordering.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/21_d_met_first_dx_support.sql

- [chunks/21_d_met_first_dx_support.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/24_h_closest_treatment_placement.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/29_g_treatment_signal_source.sql

- [chunks/29_g_treatment_signal_source.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/30_g_procedure_only_by_concept.sql

- [chunks/30_g_procedure_only_by_concept.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/31_g_procedure_timing_vs_met.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/characterization_full.sql

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

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### pdw/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/13_death_gap_summary.sql

- [chunks/13_death_gap_summary.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/14_death_gap_buckets.sql

- [chunks/14_death_gap_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### pdw/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### impala/characterization_full.sql

- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
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

### impala/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/06_odx_gdx_directional_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### impala/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/15_l01_day_count_buckets.sql

- [chunks/15_l01_day_count_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/18_f_index_event_record_counts.sql

- [chunks/18_f_index_event_record_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/20_d_met_first_ordering.sql

- [chunks/20_d_met_first_ordering.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/21_d_met_first_dx_support.sql

- [chunks/21_d_met_first_dx_support.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/24_h_closest_treatment_placement.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/29_g_treatment_signal_source.sql

- [chunks/29_g_treatment_signal_source.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/30_g_procedure_only_by_concept.sql

- [chunks/30_g_procedure_only_by_concept.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/31_g_procedure_timing_vs_met.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/characterization_full.sql

- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
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

### netezza/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/06_odx_gdx_directional_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### netezza/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/15_l01_day_count_buckets.sql

- [chunks/15_l01_day_count_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/18_f_index_event_record_counts.sql

- [chunks/18_f_index_event_record_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/20_d_met_first_ordering.sql

- [chunks/20_d_met_first_ordering.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/21_d_met_first_dx_support.sql

- [chunks/21_d_met_first_dx_support.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/24_h_closest_treatment_placement.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/29_g_treatment_signal_source.sql

- [chunks/29_g_treatment_signal_source.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/30_g_procedure_only_by_concept.sql

- [chunks/30_g_procedure_only_by_concept.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/31_g_procedure_timing_vs_met.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/characterization_full.sql

- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
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

### bigquery/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/06_odx_gdx_directional_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### bigquery/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/15_l01_day_count_buckets.sql

- [chunks/15_l01_day_count_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/18_f_index_event_record_counts.sql

- [chunks/18_f_index_event_record_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/20_d_met_first_ordering.sql

- [chunks/20_d_met_first_ordering.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/21_d_met_first_dx_support.sql

- [chunks/21_d_met_first_dx_support.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/24_h_closest_treatment_placement.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/29_g_treatment_signal_source.sql

- [chunks/29_g_treatment_signal_source.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/30_g_procedure_only_by_concept.sql

- [chunks/30_g_procedure_only_by_concept.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/31_g_procedure_timing_vs_met.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### spark/characterization_full.sql

- [characterization_full.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

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

### spark/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/09_demographics.sql

- [chunks/09_demographics.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/13_death_gap_summary.sql

- [chunks/13_death_gap_summary.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/14_death_gap_buckets.sql

- [chunks/14_death_gap_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/20_d_met_first_ordering.sql

- [chunks/20_d_met_first_ordering.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### spark/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/24_h_closest_treatment_placement.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### spark/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/29_g_treatment_signal_source.sql

- [chunks/29_g_treatment_signal_source.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### spark/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/32_g_drugexp_cooccurrence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### spark/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### spark/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### sqlite/characterization_full.sql

- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
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

### sqlite/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/06_odx_gdx_directional_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### sqlite/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/15_l01_day_count_buckets.sql

- [chunks/15_l01_day_count_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/18_f_index_event_record_counts.sql

- [chunks/18_f_index_event_record_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/20_d_met_first_ordering.sql

- [chunks/20_d_met_first_ordering.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/21_d_met_first_dx_support.sql

- [chunks/21_d_met_first_dx_support.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/24_h_closest_treatment_placement.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/29_g_treatment_signal_source.sql

- [chunks/29_g_treatment_signal_source.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/30_g_procedure_only_by_concept.sql

- [chunks/30_g_procedure_only_by_concept.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/31_g_procedure_timing_vs_met.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

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

### redshift/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/13_death_gap_summary.sql

- [chunks/13_death_gap_summary.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/14_death_gap_buckets.sql

- [chunks/14_death_gap_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### redshift/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### hive/characterization_full.sql

- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
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

### hive/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/06_odx_gdx_directional_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### hive/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/15_l01_day_count_buckets.sql

- [chunks/15_l01_day_count_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/18_f_index_event_record_counts.sql

- [chunks/18_f_index_event_record_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/20_d_met_first_ordering.sql

- [chunks/20_d_met_first_ordering.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/21_d_met_first_dx_support.sql

- [chunks/21_d_met_first_dx_support.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/24_h_closest_treatment_placement.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/29_g_treatment_signal_source.sql

- [chunks/29_g_treatment_signal_source.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/30_g_procedure_only_by_concept.sql

- [chunks/30_g_procedure_only_by_concept.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/31_g_procedure_timing_vs_met.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### hive/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/characterization_full.sql

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

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### sqlite_extended/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/06_odx_gdx_directional_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

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

### sqlite_extended/chunks/15_l01_day_count_buckets.sql

- [chunks/15_l01_day_count_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/16_e_obs_period_observability.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/17_e_obs_period_integrity.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/18_f_index_event_record_counts.sql

- [chunks/18_f_index_event_record_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/19_f_dx_intercode_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/20_d_met_first_ordering.sql

- [chunks/20_d_met_first_ordering.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/21_d_met_first_dx_support.sql

- [chunks/21_d_met_first_dx_support.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/22_d_met_to_dx_timing_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/23_d_met_to_dx_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/24_h_closest_treatment_placement.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/25_h_after_curve_population_reconciliation.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/26_h_signed_closest_histogram.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/27_h_before_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/28_h_after_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/29_g_treatment_signal_source.sql

- [chunks/29_g_treatment_signal_source.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/30_g_procedure_only_by_concept.sql

- [chunks/30_g_procedure_only_by_concept.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/31_g_procedure_timing_vs_met.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/32_g_drugexp_cooccurrence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/33_b_gdx_trajectory_categories.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/34_b_gdx_first_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite_extended/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/35_b_gdx_per_concept_windowed.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/characterization_full.sql

- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
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

### duckdb/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/06_odx_gdx_directional_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### duckdb/chunks/11_l01_gap_deciles.sql

- [chunks/11_l01_gap_deciles.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/12_l01_gap_buckets.sql

- [chunks/12_l01_gap_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/15_l01_day_count_buckets.sql

- [chunks/15_l01_day_count_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/18_f_index_event_record_counts.sql

- [chunks/18_f_index_event_record_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/20_d_met_first_ordering.sql

- [chunks/20_d_met_first_ordering.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/21_d_met_first_dx_support.sql

- [chunks/21_d_met_first_dx_support.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/24_h_closest_treatment_placement.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/29_g_treatment_signal_source.sql

- [chunks/29_g_treatment_signal_source.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/30_g_procedure_only_by_concept.sql

- [chunks/30_g_procedure_only_by_concept.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/31_g_procedure_timing_vs_met.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### duckdb/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

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

### snowflake/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/06_odx_gdx_directional_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

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

### snowflake/chunks/15_l01_day_count_buckets.sql

- [chunks/15_l01_day_count_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/16_e_obs_period_observability.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/17_e_obs_period_integrity.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/17_e_obs_period_integrity.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/18_f_index_event_record_counts.sql

- [chunks/18_f_index_event_record_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/19_f_dx_intercode_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/20_d_met_first_ordering.sql

- [chunks/20_d_met_first_ordering.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/21_d_met_first_dx_support.sql

- [chunks/21_d_met_first_dx_support.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/22_d_met_to_dx_timing_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/23_d_met_to_dx_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/24_h_closest_treatment_placement.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/25_h_after_curve_population_reconciliation.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/26_h_signed_closest_histogram.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/27_h_before_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/28_h_after_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/29_g_treatment_signal_source.sql

- [chunks/29_g_treatment_signal_source.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/30_g_procedure_only_by_concept.sql

- [chunks/30_g_procedure_only_by_concept.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/31_g_procedure_timing_vs_met.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/32_g_drugexp_cooccurrence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/33_b_gdx_trajectory_categories.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/34_b_gdx_first_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/35_b_gdx_per_concept_windowed.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/characterization_full.sql

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

- [chunks/05_timing_by_year.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### synapse/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/13_death_gap_summary.sql

- [chunks/13_death_gap_summary.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/14_death_gap_buckets.sql

- [chunks/14_death_gap_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

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

### iris/chunks/06_odx_gdx_directional_prevalence.sql

- [chunks/06_odx_gdx_directional_prevalence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/06_odx_gdx_directional_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/06b_odx_gdx_directional_cdf.sql

- [chunks/06b_odx_gdx_directional_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

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

### iris/chunks/15_l01_day_count_buckets.sql

- [chunks/15_l01_day_count_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/16_e_obs_period_observability.sql

- [chunks/16_e_obs_period_observability.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/16_e_obs_period_observability.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/17_e_obs_period_integrity.sql

- [chunks/17_e_obs_period_integrity.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/17_e_obs_period_integrity.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/18_f_index_event_record_counts.sql

- [chunks/18_f_index_event_record_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/19_f_dx_intercode_timing.sql

- [chunks/19_f_dx_intercode_timing.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/19_f_dx_intercode_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/20_d_met_first_ordering.sql

- [chunks/20_d_met_first_ordering.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/21_d_met_first_dx_support.sql

- [chunks/21_d_met_first_dx_support.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/22_d_met_to_dx_timing_buckets.sql

- [chunks/22_d_met_to_dx_timing_buckets.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/22_d_met_to_dx_timing_buckets.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/23_d_met_to_dx_timing_cdf.sql

- [chunks/23_d_met_to_dx_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/23_d_met_to_dx_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/24_h_closest_treatment_placement.sql

- [chunks/24_h_closest_treatment_placement.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/24_h_closest_treatment_placement.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/25_h_after_curve_population_reconciliation.sql

- [chunks/25_h_after_curve_population_reconciliation.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/25_h_after_curve_population_reconciliation.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/26_h_signed_closest_histogram.sql

- [chunks/26_h_signed_closest_histogram.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/26_h_signed_closest_histogram.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/27_h_before_curve_cdf.sql

- [chunks/27_h_before_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/27_h_before_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/28_h_after_curve_cdf.sql

- [chunks/28_h_after_curve_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/28_h_after_curve_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/29_g_treatment_signal_source.sql

- [chunks/29_g_treatment_signal_source.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/30_g_procedure_only_by_concept.sql

- [chunks/30_g_procedure_only_by_concept.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/31_g_procedure_timing_vs_met.sql

- [chunks/31_g_procedure_timing_vs_met.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/31_g_procedure_timing_vs_met.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/32_g_drugexp_cooccurrence.sql

- [chunks/32_g_drugexp_cooccurrence.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/32_g_drugexp_cooccurrence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/33_b_gdx_trajectory_categories.sql

- [chunks/33_b_gdx_trajectory_categories.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/33_b_gdx_trajectory_categories.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/34_b_gdx_first_timing_cdf.sql

- [chunks/34_b_gdx_first_timing_cdf.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/34_b_gdx_first_timing_cdf.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### iris/chunks/35_b_gdx_per_concept_windowed.sql

- [chunks/35_b_gdx_per_concept_windowed.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/35_b_gdx_per_concept_windowed.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

