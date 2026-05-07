-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-07 06:29:46 BST
-- Source file    : sql/sql_server/chunks/02_code_counts.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 2) Code-count summary: all three time windows combined (small-cell sentinel)
--    time_window: all | before | after
 select x.time_window,
    x.anchor_event,
    x.event_family,
    x.concept_id,
    case when x.n_patients <= @min_cell_count then -@min_cell_count else x.n_records end as n_records,
    case when x.n_patients <= @min_cell_count then -@min_cell_count else x.n_patients end as n_patients,
    case when x.n_patients <= @min_cell_count then -@min_cell_count else coalesce(ts.n_patients_with_code_timing, tba.n_patients_with_code_timing) end as n_patients_with_code_timing,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.lq_days_first,       tba.lq_days_first)       end as lq_days_first,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.median_days_first,   tba.median_days_first)   end as median_days_first,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.uq_days_first,       tba.uq_days_first)       end as uq_days_first,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.lq_days_closest,     tba.lq_days_closest)     end as lq_days_closest,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.median_days_closest, tba.median_days_closest) end as median_days_closest,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.uq_days_closest,     tba.uq_days_closest)     end as uq_days_closest,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.lq_days_first,       tba.lq_days_first)       end as lq_days,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.median_days_first,   tba.median_days_first)   end as median_days,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.uq_days_first,       tba.uq_days_first)       end as uq_days
 from (
    select 'all'    as time_window, anchor_event, event_family, concept_id, n_records, n_patients from u2ijfaoqevent_code_counts
    union all
    select 'before' as time_window, anchor_event, event_family, concept_id, n_records, n_patients from u2ijfaoqevent_code_counts_before_after         where time_relative = 'BEFORE'
    union all
    select 'after'  as time_window, anchor_event, event_family, concept_id, n_records, n_patients from u2ijfaoqevent_code_counts_before_after         where time_relative = 'AFTER'
    union all
    select 'before' as time_window, anchor_event, event_family, concept_id, n_records, n_patients from u2ijfaoqevent_code_counts_before_after_first_met where time_relative = 'BEFORE'
    union all
    select 'after'  as time_window, anchor_event, event_family, concept_id, n_records, n_patients from u2ijfaoqevent_code_counts_before_after_first_met where time_relative = 'AFTER'
) x
left join u2ijfaoqevent_code_timing_summary ts
  on x.time_window = 'all'
 and x.anchor_event = ts.anchor_event
 and x.event_family = ts.event_family
 and x.concept_id   = ts.concept_id
left join u2ijfaoqevent_code_timing_before_after_summary tba
  on x.time_window != 'all'
 and x.anchor_event = tba.anchor_event
 and x.event_family = tba.event_family
 and x.concept_id   = tba.concept_id
 and ((x.time_window = 'before' and tba.time_relative = 'BEFORE')
  or  (x.time_window = 'after'  and tba.time_relative = 'AFTER'))
 order by  x.time_window, x.anchor_event, x.event_family, x.n_patients desc, x.n_records desc, x.concept_id
 ;

