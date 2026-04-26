-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-04-26 18:36:18 BST
-- Source file    : sql/sql_server/chunks/07_timing_first_to_closest_after.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 7) Pairwise timing summary: FROM first -> TO closest AFTER (>=0)
 select from_event,
    to_event,
    case when n_patients_with_pair <= @min_cell_count then -@min_cell_count else n_patients_with_pair end as n_patients_with_pair,
    case when n_patients_with_pair <= @min_cell_count then null else p05_days end as p05_days,
    case when n_patients_with_pair <= @min_cell_count then null else p10_days end as p10_days,
    case when n_patients_with_pair <= @min_cell_count then null else p20_days end as p20_days,
    case when n_patients_with_pair <= @min_cell_count then null else p25_days end as p25_days,
    case when n_patients_with_pair <= @min_cell_count then null else p30_days end as p30_days,
    case when n_patients_with_pair <= @min_cell_count then null else p40_days end as p40_days,
    case when n_patients_with_pair <= @min_cell_count then null else p50_days end as p50_days,
    case when n_patients_with_pair <= @min_cell_count then null else p60_days end as p60_days,
    case when n_patients_with_pair <= @min_cell_count then null else p70_days end as p70_days,
    case when n_patients_with_pair <= @min_cell_count then null else p75_days end as p75_days,
    case when n_patients_with_pair <= @min_cell_count then null else p80_days end as p80_days,
    case when n_patients_with_pair <= @min_cell_count then null else p90_days end as p90_days,
    case when n_patients_with_pair <= @min_cell_count then null else p95_days end as p95_days
 from x0brqusctiming_pair_summary_first_to_closest_after
 order by  1, 2 ;

