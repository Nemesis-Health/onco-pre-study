-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-05-06 18:36:53 BST
-- Source file    : sql/sql_server/chunks/01_population_prevalence.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH base  AS (SELECT CASE
 WHEN GROUPING(YEAR(index_date)) = 1 THEN  CAST('OVERALL' as STRING) ELSE CAST(YEAR(index_date) AS STRING)
 END AS prevalence_year,
 COUNT(*) AS n_patients,
 SUM(CASE WHEN first_other_dx_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_other_dx,
 SUM(CASE WHEN first_gen_cancer_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_gen_cancer_dx,
 SUM(CASE WHEN first_met_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_met,
 SUM(CASE WHEN first_l01_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_l01
 FROM ldpw47q6patient_char
 GROUP BY GROUPING SETS (
 (),
 (YEAR(index_date))
 )
)
SELECT
 prevalence_year,
 CASE WHEN n_patients <= @min_cell_count THEN -@min_cell_count ELSE n_patients END AS n_dx,
 CASE
 WHEN n_patients <= @min_cell_count THEN -@min_cell_count
 WHEN n_with_other_dx BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
 ELSE n_with_other_dx
 END AS n_odx,
 CASE
 WHEN n_patients <= @min_cell_count THEN -@min_cell_count
 WHEN n_with_gen_cancer_dx BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
 ELSE n_with_gen_cancer_dx
 END AS n_gdx,
 CASE
 WHEN n_patients <= @min_cell_count THEN -@min_cell_count
 WHEN n_with_met BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
 ELSE n_with_met
 END AS n_met,
 CASE
 WHEN n_patients <= @min_cell_count THEN -@min_cell_count
 WHEN n_with_l01 BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
 ELSE n_with_l01
 END AS n_l01
FROM base
ORDER BY
 CASE WHEN prevalence_year = 'OVERALL' THEN 0 ELSE 1 END,
 CASE WHEN prevalence_year = 'OVERALL' THEN NULL ELSE CAST(prevalence_year AS INT) END;
