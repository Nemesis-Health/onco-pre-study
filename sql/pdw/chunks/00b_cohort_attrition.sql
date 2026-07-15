-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : pdw
-- Translated     : 2026-07-15 15:36:58 CEST
-- Source file    : sql/sql_server/chunks/00b_cohort_attrition.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (pdw) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 0b) Cohort attrition: patients with any qualifying DX vs those with a DX
--     that falls within an observation period (the study-eligible subset).
--     The difference is the number excluded by the obs-period filter.
SELECT
    SUM(CASE WHEN stage = 'dx_any'    THEN n_patients ELSE 0 END) AS n_dx_any,
    SUM(CASE WHEN stage = 'dx_in_obs' THEN n_patients ELSE 0 END) AS n_dx_in_obs,
    SUM(CASE WHEN stage = 'dx_any'    THEN n_patients ELSE 0 END)
    - SUM(CASE WHEN stage = 'dx_in_obs' THEN n_patients ELSE 0 END)  AS n_excluded_no_obs_dx
FROM #cohort_attrition
;

