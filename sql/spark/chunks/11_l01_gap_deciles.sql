-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-05-07 11:48:09 BST
-- Source file    : sql/sql_server/chunks/11_l01_gap_deciles.sql
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
 COUNT(*) AS n_gaps,
 COUNT(DISTINCT person_id) AS n_patients_with_gaps,
 MIN(CASE WHEN 10.0 * rn >= cnt THEN CAST(gap_days AS DOUBLE) END) AS p10_days,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(gap_days AS DOUBLE) END) AS p25_days,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(gap_days AS DOUBLE) END) AS p50_days,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(gap_days AS DOUBLE) END) AS p75_days,
 MIN(CASE WHEN 10.0 * rn >= 9 * cnt THEN CAST(gap_days AS DOUBLE) END) AS p90_days
FROM (
 SELECT subgroup, person_id, gap_days,
 ROW_NUMBER() OVER (PARTITION BY subgroup ORDER BY gap_days) AS rn,
 COUNT(*) OVER (PARTITION BY subgroup) AS cnt
 FROM qbz8duell01_consecutive_gaps
) x
GROUP BY subgroup
ORDER BY subgroup;
