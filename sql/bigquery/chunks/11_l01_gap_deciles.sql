-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-06 18:06:52 BST
-- Source file    : sql/sql_server/chunks/11_l01_gap_deciles.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 11) L01 consecutive record gap distribution — decile summary
--     Intermediate tables #l01_event_days and #l01_consecutive_gaps are
--     built in 00_setup.sql (section L).
--
--     Two subgroups:
--       ALL_L01 : all DX cohort patients with any L01 record
--       MET_L01 : patients who also have a first_met_date
--
--     Output: one row per subgroup with gap-day deciles.
   select subgroup,
    count(*)                                                   as n_gaps,
    count(distinct person_id)                                  as n_patients_with_gaps,
    percentile_cont(0.10) within group (order by gap_days)    as p10_days,
    percentile_cont(0.25) within group (order by gap_days)    as p25_days,
    percentile_cont(0.50) within group (order by gap_days)    as p50_days,
    percentile_cont(0.75) within group (order by gap_days)    as p75_days,
    percentile_cont(0.90) within group (order by gap_days)    as p90_days
   from cbse36ibl01_consecutive_gaps
  group by  1   order by  1 ;

