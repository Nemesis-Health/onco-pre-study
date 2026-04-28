# SQL Translation Report

Generated: 2026-04-27 15:05:10 BST
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

### pdw/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.

### pdw/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### pdw/chunks/08_death_timing.sql

- [chunks/08_death_timing.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.

### pdw/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

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

### redshift/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.

### redshift/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

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

### synapse/chunks/00_setup.sql

- [chunks/00_setup.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.
- [chunks/00_setup.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.
- [chunks/00_setup.sql] DELETE_FROM_EXISTS: DELETE FROM ... WHERE EXISTS(...) may not be supported. BigQuery requires DELETE ... WHERE ... without a correlated subquery in the same form; verify or rewrite as MERGE.

### synapse/chunks/01_population_prevalence.sql

- [chunks/01_population_prevalence.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.
- [chunks/01_population_prevalence.sql] YEAR_FUNC: YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects.

### synapse/chunks/08_death_timing.sql

- [chunks/08_death_timing.sql] TRY_CAST: TRY_CAST was left in translated SQL. SqlRender should rewrite it, but if it remains, the query will fail on dialects that don't support it. Even when rewritten to CAST, invalid values will raise errors rather than returning NULL — validate upstream data quality.

### synapse/chunks/09_demographics.sql

- [chunks/09_demographics.sql] DATEFROMPARTS: DATEFROMPARTS was not rewritten by SqlRender. This function is SQL Server–specific and will fail on this dialect.
- [chunks/09_demographics.sql] DATEDIFF_3ARG: DATEDIFF(DAY, start, end) was not rewritten. Most dialects use date subtraction or their own function instead.

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

