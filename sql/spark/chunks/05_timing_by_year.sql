-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-05-07 06:29:47 BST
-- Source file    : sql/sql_server/chunks/05_timing_by_year.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

SELECT
 x.timing_type,
 x.index_year,
 x.from_event,
 x.to_event,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN -@min_cell_count ELSE x.n_patients_with_pair END AS n_patients_with_pair,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p25_days END AS p25_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p50_days END AS p50_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p75_days END AS p75_days
FROM (
 -- first_to_first by year
 SELECT
 'first_to_first' AS timing_type,
 CAST(index_year_int AS STRING) AS index_year,
 from_event,
 to_event,
 COUNT(*) AS n_patients_with_pair,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p25_days,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p50_days,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p75_days
 FROM (
 SELECT p.from_event, p.to_event, p.days_diff,
 YEAR(pc.index_date) AS index_year_int,
 ROW_NUMBER() OVER (PARTITION BY YEAR(pc.index_date), p.from_event, p.to_event ORDER BY p.days_diff) AS rn,
 COUNT(*) OVER (PARTITION BY YEAR(pc.index_date), p.from_event, p.to_event) AS cnt
 FROM u2ijfaoqpatient_timing_pairs p
 JOIN u2ijfaoqpatient_char pc ON p.person_id = pc.person_id
 ) y
 GROUP BY index_year_int, from_event, to_event
 UNION ALL
 -- first_to_closest_after by year (for MET->L01 post-MET treatment timing)
 SELECT
 'first_to_closest_after' AS timing_type,
 CAST(index_year_int AS STRING) AS index_year,
 from_event,
 to_event,
 COUNT(*) AS n_patients_with_pair,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p25_days,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p50_days,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p75_days
 FROM (
 SELECT p.from_event, p.to_event, p.days_diff,
 YEAR(pc.index_date) AS index_year_int,
 ROW_NUMBER() OVER (PARTITION BY YEAR(pc.index_date), p.from_event, p.to_event ORDER BY p.days_diff) AS rn,
 COUNT(*) OVER (PARTITION BY YEAR(pc.index_date), p.from_event, p.to_event) AS cnt
 FROM u2ijfaoqpatient_timing_pairs_first_to_closest_after p
 JOIN u2ijfaoqpatient_char pc ON p.person_id = pc.person_id
 ) y
 GROUP BY index_year_int, from_event, to_event
) x
ORDER BY
 x.timing_type,
 x.from_event,
 x.to_event,
 CAST(x.index_year AS INT);
