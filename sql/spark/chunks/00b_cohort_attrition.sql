-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-05-07 11:44:49 BST
-- Source file    : sql/sql_server/chunks/00b_cohort_attrition.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

SELECT
 SUM(CASE WHEN stage = 'dx_any' THEN n_patients ELSE 0 END) AS n_dx_any,
 SUM(CASE WHEN stage = 'dx_in_obs' THEN n_patients ELSE 0 END) AS n_dx_in_obs,
 SUM(CASE WHEN stage = 'dx_any' THEN n_patients ELSE 0 END)
 - SUM(CASE WHEN stage = 'dx_in_obs' THEN n_patients ELSE 0 END) AS n_excluded_no_obs_dx
FROM prnpim5kcohort_attrition;
