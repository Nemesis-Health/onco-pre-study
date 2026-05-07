-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-05-07 12:40:21 BST
-- Source file    : sql/sql_server/chunks/15_l01_day_count_buckets.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

SELECT
 subgroup,
 CASE
 WHEN n_days = 1 THEN '1'
 WHEN n_days <= 6 THEN '2_6'
 WHEN n_days <= 11 THEN '7_11'
 ELSE '12plus'
 END AS days_bucket,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count ELSE COUNT(*) END AS n_patients
FROM (
 SELECT e.person_id, COUNT(*) AS n_days, 'ALL_L01' AS subgroup
 FROM a9of9doxl01_event_days e
 GROUP BY e.person_id
 UNION ALL
 SELECT e.person_id, COUNT(*) AS n_days, 'MET_L01' AS subgroup
 FROM a9of9doxl01_event_days e
 JOIN a9of9doxmet_summary ms ON e.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
 GROUP BY e.person_id
) x
GROUP BY
 subgroup,
 CASE
 WHEN n_days = 1 THEN '1'
 WHEN n_days <= 6 THEN '2_6'
 WHEN n_days <= 11 THEN '7_11'
 ELSE '12plus'
 END
ORDER BY
 subgroup,
 MIN(n_days);
