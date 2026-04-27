# SQL Translation Report

Generated: 2026-04-26 18:36:23 BST
Source: `sql/sql_server/`
Dialects: oracle, postgresql, pdw, impala, netezza, bigquery, spark, sqlite, redshift, hive, sqlite extended, duckdb, snowflake, synapse, iris

## Dialect notes

Dialects requiring `tempEmulationSchema` at execution time (no native session temp tables): **oracle, bigquery, spark, hive, impala, pdw, netezza**.

## Pattern warnings

### oracle/characterization_full.sql

- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### oracle/chunks/00_setup.sql

- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/characterization_full.sql

- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### postgresql/chunks/00_setup.sql

- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/characterization_full.sql

- [characterization_full.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [characterization_full.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/01_population_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/chunks/02_event_code_counts.sql

- [chunks/02_event_code_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/chunks/03_suppression_audit.sql

- [chunks/03_suppression_audit.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/chunks/03b_event_code_counts_before_after.sql

- [chunks/03b_event_code_counts_before_after.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/chunks/04_timing_first_to_first.sql

- [chunks/04_timing_first_to_first.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/chunks/05_timing_first_to_closest.sql

- [chunks/05_timing_first_to_closest.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/chunks/06_timing_first_to_closest_before.sql

- [chunks/06_timing_first_to_closest_before.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/chunks/07_timing_first_to_closest_after.sql

- [chunks/07_timing_first_to_closest_after.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/chunks/08_death_timing.sql

- [chunks/08_death_timing.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/08_death_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/09_demographics.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### pdw/chunks/10_anchor_dx_codes.sql

- [chunks/10_anchor_dx_codes.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/characterization_full.sql

- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/00_setup.sql

- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### impala/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### netezza/characterization_full.sql

- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### netezza/chunks/00_setup.sql

- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/characterization_full.sql

- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### bigquery/chunks/00_setup.sql

- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

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

### spark/chunks/09_demographics.sql

- [chunks/09_demographics.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### sqlite/characterization_full.sql

- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### sqlite/chunks/00_setup.sql

- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/characterization_full.sql

- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/chunks/02_event_code_counts.sql

- [chunks/02_event_code_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/chunks/03_suppression_audit.sql

- [chunks/03_suppression_audit.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/chunks/03b_event_code_counts_before_after.sql

- [chunks/03b_event_code_counts_before_after.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/chunks/04_timing_first_to_first.sql

- [chunks/04_timing_first_to_first.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/chunks/05_timing_first_to_closest.sql

- [chunks/05_timing_first_to_closest.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/chunks/06_timing_first_to_closest_before.sql

- [chunks/06_timing_first_to_closest_before.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/chunks/07_timing_first_to_closest_after.sql

- [chunks/07_timing_first_to_closest_after.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/chunks/08_death_timing.sql

- [chunks/08_death_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/09_demographics.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### redshift/chunks/10_anchor_dx_codes.sql

- [chunks/10_anchor_dx_codes.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

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

- [chunks/01_population_prevalence.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### sqlite_extended/chunks/08_death_timing.sql

- [chunks/08_death_timing.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.

### sqlite_extended/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

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

### snowflake/characterization_full.sql

- [characterization_full.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### snowflake/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.

### snowflake/chunks/08_death_timing.sql

- [chunks/08_death_timing.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.

### snowflake/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

### synapse/characterization_full.sql

- [characterization_full.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [characterization_full.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [characterization_full.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [characterization_full.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [characterization_full.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [characterization_full.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.
- [chunks/00_setup.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/01_population_prevalence.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/chunks/02_event_code_counts.sql

- [chunks/02_event_code_counts.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/chunks/03_suppression_audit.sql

- [chunks/03_suppression_audit.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/chunks/03b_event_code_counts_before_after.sql

- [chunks/03b_event_code_counts_before_after.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/chunks/04_timing_first_to_first.sql

- [chunks/04_timing_first_to_first.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/chunks/05_timing_first_to_closest.sql

- [chunks/05_timing_first_to_closest.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/chunks/06_timing_first_to_closest_before.sql

- [chunks/06_timing_first_to_closest_before.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/chunks/07_timing_first_to_closest_after.sql

- [chunks/07_timing_first_to_closest_after.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/chunks/08_death_timing.sql

- [chunks/08_death_timing.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/08_death_timing.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/09_demographics.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

### synapse/chunks/10_anchor_dx_codes.sql

- [chunks/10_anchor_dx_codes.sql] RESIDUAL_HASH_TEMP: Residual #temp_table reference. SqlRender should have rewritten these. If they remain, confirm SqlRender version >= 1.6 and that the source SQL uses the standard #temp pattern.

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

### iris/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

