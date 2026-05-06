-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-06 20:27:55 BST
-- Source file    : sql/sql_server/chunks/00b_cohort_attrition.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 0b) Cohort attrition: patients with any qualifying DX vs those with a DX
--     that falls within an observation period (the study-eligible subset).
--     The difference is the number excluded by the obs-period filter.
select
    sum(case when stage = 'dx_any'    then n_patients else 0 end) as n_dx_any,
    sum(case when stage = 'dx_in_obs' then n_patients else 0 end) as n_dx_in_obs,
    sum(case when stage = 'dx_any'    then n_patients else 0 end)
    - sum(case when stage = 'dx_in_obs' then n_patients else 0 end)  as n_excluded_no_obs_dx
from d5ifm2a4cohort_attrition
;

