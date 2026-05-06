# SQL Translation Report

Generated: 2026-05-06 18:36:59 BST
Source: `sql/sql_server/`
Dialects: oracle, postgresql, pdw, impala, netezza, bigquery, spark, sqlite, redshift, hive, sqlite extended, duckdb, snowflake, synapse, iris

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

