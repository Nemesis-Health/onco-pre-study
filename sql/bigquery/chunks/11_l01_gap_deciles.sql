-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-07 12:40:20 BST
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
--     Small-cell suppression: n_gaps <= @min_cell_count suppresses percentiles to NULL
--     and replaces counts with -@min_cell_count.
   select subgroup,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count else count(*) end as n_gaps,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count else count(distinct person_id) end as n_patients_with_gaps,
    min(case when cnt > @min_cell_count and 10.0 * rn >= cnt      then cast(gap_days  as float64) end) as p10_days,
    min(case when cnt > @min_cell_count and  4.0 * rn >= cnt      then cast(gap_days  as float64) end) as p25_days,
    min(case when cnt > @min_cell_count and  2.0 * rn >= cnt      then cast(gap_days  as float64) end) as p50_days,
    min(case when cnt > @min_cell_count and  4.0 * rn >= 3 * cnt  then cast(gap_days  as float64) end) as p75_days,
    min(case when cnt > @min_cell_count and 10.0 * rn >= 9 * cnt  then cast(gap_days  as float64) end) as p90_days
   from (
    select subgroup, person_id, gap_days,
        row_number() over (partition by subgroup order by gap_days) as rn,
        count(*)     over (partition by subgroup)                   as cnt
    from a9of9doxl01_consecutive_gaps
) x
  group by  1   order by  1 ;

