-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-05-07 12:40:21 BST
-- Source file    : sql/sql_server/chunks/12_l01_gap_buckets.sql
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
 WHEN gap_days < 30 THEN 'lt30d'
 WHEN gap_days < 60 THEN '30_59d'
 WHEN gap_days < 90 THEN '60_89d'
 WHEN gap_days < 180 THEN '90_179d'
 WHEN gap_days < 365 THEN '180_364d'
 ELSE 'ge365d'
 END AS gap_bucket,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count ELSE COUNT(*) END AS n_gaps
FROM a9of9doxl01_consecutive_gaps
GROUP BY
 subgroup,
 CASE
 WHEN gap_days < 30 THEN 'lt30d'
 WHEN gap_days < 60 THEN '30_59d'
 WHEN gap_days < 90 THEN '60_89d'
 WHEN gap_days < 180 THEN '90_179d'
 WHEN gap_days < 365 THEN '180_364d'
 ELSE 'ge365d'
 END
ORDER BY
 subgroup,
 MIN(CASE
 WHEN gap_days < 30 THEN 1
 WHEN gap_days < 60 THEN 2
 WHEN gap_days < 90 THEN 3
 WHEN gap_days < 180 THEN 4
 WHEN gap_days < 365 THEN 5
 ELSE 6
 END);
