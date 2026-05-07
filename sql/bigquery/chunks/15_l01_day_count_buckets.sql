-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-07 11:54:00 BST
-- Source file    : sql/sql_server/chunks/15_l01_day_count_buckets.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 15) Distribution of distinct L01 event days per patient
--     Shows how many patients have 1, 2-6, 7-11, or 12+ distinct L01 days.
--     Patients with exactly 1 day cannot contribute to gap analyses (chunks 11-12).
--     Source: #l01_event_days (built in 00_setup.sql section L).
--
--     Two subgroups:
--       ALL_L01 : all DX cohort patients with any L01 record
--       MET_L01 : patients who also have a first_met_date
--     Small-cell suppression: n_patients <= @min_cell_count suppressed to -@min_cell_count.
   select subgroup,
    case
        when n_days =  1 then '1'
        when n_days <= 6 then '2_6'
        when n_days <= 11 then '7_11'
        else '12plus'
    end as days_bucket,
    case when count(*) <= @min_cell_count then -@min_cell_count else count(*) end as n_patients
   from (
     select e.person_id, count(*) as n_days, 'ALL_L01' as subgroup
     from ctxb0woml01_event_days e
     group by  e.person_id
    union all
     select e.person_id, count(*) as n_days, 'MET_L01' as subgroup
     from ctxb0woml01_event_days e
    join ctxb0wommet_summary ms on e.person_id = ms.person_id and ms.first_met_date is not null
     group by  e.person_id
  ) x
  group by  2, 2   order by  1, min(n_days)
  ;

