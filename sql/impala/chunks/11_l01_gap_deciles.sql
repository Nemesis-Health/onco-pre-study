-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : impala
-- Translated     : 2026-05-06 18:06:48 BST
-- Source file    : sql/sql_server/chunks/11_l01_gap_deciles.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (impala) does not support native session
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
SELECT
    subgroup,
    COUNT(*)                                                   AS n_gaps,
    COUNT(DISTINCT person_id)                                  AS n_patients_with_gaps,
    PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY gap_days)    AS p10_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY gap_days)    AS p25_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY gap_days)    AS p50_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY gap_days)    AS p75_days,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY gap_days)    AS p90_days
FROM cbse36ibl01_consecutive_gaps
GROUP BY subgroup
ORDER BY subgroup
;

