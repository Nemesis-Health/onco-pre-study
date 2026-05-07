-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-07 11:54:00 BST
-- Source file    : sql/sql_server/chunks/12_l01_gap_buckets.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 12) L01 consecutive record gap distribution — bucketed histogram
--     Intermediate table #l01_consecutive_gaps is built in 00_setup.sql
--     (section L).  Same subgroups as chunk 11 (ALL_L01, MET_L01).
--
--     Output: one row per (subgroup, gap_bucket) for histogram rendering.
--     Small-cell suppression: n_gaps <= @min_cell_count suppressed to -@min_cell_count.
   select subgroup,
    case
        when gap_days <  30  then 'lt30d'
        when gap_days <  60  then '30_59d'
        when gap_days <  90  then '60_89d'
        when gap_days < 180  then '90_179d'
        when gap_days < 365  then '180_364d'
        else 'ge365d'
    end as gap_bucket,
    case when count(*) <= @min_cell_count then -@min_cell_count else count(*) end as n_gaps
   from ctxb0woml01_consecutive_gaps
  group by  1, 2   order by  1, min(case
        when gap_days <  30  then 1
        when gap_days <  60  then 2
        when gap_days <  90  then 3
        when gap_days < 180  then 4
        when gap_days < 365  then 5
        else 6
    end)
  ;

