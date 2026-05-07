-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-05-07 11:58:19 BST
-- Source file    : sql/sql_server/chunks/03_directionality_buckets.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH dx_met_base  AS (SELECT YEAR(index_date) AS index_year_int,
 CASE
 WHEN first_met_date IS NULL THEN  CAST('NO_EVENT' as STRING) WHEN days_dx_to_met < -90 THEN 'BEFORE_GT90'
 WHEN days_dx_to_met < 0 THEN 'BEFORE_1_90'
 WHEN days_dx_to_met = 0 THEN 'SAME_DAY'
 WHEN days_dx_to_met <= 30 THEN 'AFTER_1_30'
 WHEN days_dx_to_met <= 90 THEN 'AFTER_31_90'
 WHEN days_dx_to_met <= 365 THEN 'AFTER_91_365'
 ELSE 'AFTER_GT365'
 END AS direction
 FROM y8hp12zkpatient_char
),
met_l01_base AS (
 SELECT
 YEAR(first_met_date) AS index_year_int,
 CASE
 WHEN first_l01_date IS NULL THEN 'NO_EVENT'
 WHEN days_met_to_l01 < -90 THEN 'BEFORE_GT90'
 WHEN days_met_to_l01 < 0 THEN 'BEFORE_1_90'
 WHEN days_met_to_l01 = 0 THEN 'SAME_DAY'
 WHEN days_met_to_l01 <= 30 THEN 'AFTER_1_30'
 WHEN days_met_to_l01 <= 90 THEN 'AFTER_31_90'
 WHEN days_met_to_l01 <= 365 THEN 'AFTER_91_365'
 ELSE 'AFTER_GT365'
 END AS direction
 FROM y8hp12zkpatient_char
 WHERE first_met_date IS NOT NULL
)
SELECT
 x.pair,
 x.index_year,
 x.direction,
 CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE x.n_patients END AS n_patients
FROM (
 -- DX -> MET: OVERALL
 SELECT
 'DX_MET' AS pair,
 'OVERALL' AS index_year,
 direction,
 COUNT(*) AS n_patients
 FROM dx_met_base
 GROUP BY direction
 UNION ALL
 -- DX -> MET: by index year
 SELECT
 'DX_MET' AS pair,
 CAST(index_year_int AS STRING) AS index_year,
 direction,
 COUNT(*) AS n_patients
 FROM dx_met_base
 GROUP BY index_year_int, direction
 UNION ALL
 -- MET -> L01: OVERALL
 SELECT
 'MET_L01' AS pair,
 'OVERALL' AS index_year,
 direction,
 COUNT(*) AS n_patients
 FROM met_l01_base
 GROUP BY direction
 UNION ALL
 -- MET -> L01: by index year
 SELECT
 'MET_L01' AS pair,
 CAST(index_year_int AS STRING) AS index_year,
 direction,
 COUNT(*) AS n_patients
 FROM met_l01_base
 GROUP BY index_year_int, direction
) x
ORDER BY
 x.pair,
 CASE WHEN x.index_year = 'OVERALL' THEN 0 ELSE 1 END,
 CASE WHEN x.index_year = 'OVERALL' THEN NULL ELSE CAST(x.index_year AS INT) END,
 CASE x.direction
 WHEN 'BEFORE_GT90' THEN 1
 WHEN 'BEFORE_1_90' THEN 2
 WHEN 'SAME_DAY' THEN 3
 WHEN 'AFTER_1_30' THEN 4
 WHEN 'AFTER_31_90' THEN 5
 WHEN 'AFTER_91_365' THEN 6
 WHEN 'AFTER_GT365' THEN 7
 WHEN 'NO_EVENT' THEN 8
 ELSE 9
 END;
