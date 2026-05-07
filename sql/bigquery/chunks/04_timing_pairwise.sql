-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-07 06:29:46 BST
-- Source file    : sql/sql_server/chunks/04_timing_pairwise.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 4) Pairwise timing summary: all four timing types combined (small-cell sentinel)
--    timing_type: first_to_first | first_to_closest | first_to_closest_before | first_to_closest_after
 select x.timing_type,
    x.from_event,
    x.to_event,
    case when x.n_patients_with_pair <= @min_cell_count then -@min_cell_count else x.n_patients_with_pair end as n_patients_with_pair,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p05_days end as p05_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p10_days end as p10_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p20_days end as p20_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p25_days end as p25_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p30_days end as p30_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p40_days end as p40_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p50_days end as p50_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p60_days end as p60_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p70_days end as p70_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p75_days end as p75_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p80_days end as p80_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p90_days end as p90_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p95_days end as p95_days
 from (
    select 'first_to_first'          as timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days from u2ijfaoqtiming_pair_summary
    union all
    select 'first_to_closest'        as timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days from u2ijfaoqtiming_pair_summary_first_to_closest
    union all
    select 'first_to_closest_before' as timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days from u2ijfaoqtiming_pair_summary_first_to_closest_before
    union all
    select 'first_to_closest_after'  as timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days from u2ijfaoqtiming_pair_summary_first_to_closest_after
) x
 order by  x.timing_type, x.from_event, x.to_event
 ;

