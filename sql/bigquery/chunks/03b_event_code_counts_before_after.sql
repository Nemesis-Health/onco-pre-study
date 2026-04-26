-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-04-26 18:36:18 BST
-- Source file    : sql/sql_server/chunks/03b_event_code_counts_before_after.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 3b) Event code counts by family+concept_id split BEFORE/AFTER
--     around both INDEX and FIRST_MET anchors (small-cell sentinel)
 select x.anchor_event,
    x.event_family,
    x.time_relative,
    x.concept_id,
    case when x.n_patients <= @min_cell_count then -@min_cell_count else x.n_records end as n_records,
    case when x.n_patients <= @min_cell_count then -@min_cell_count else x.n_patients end as n_patients,
    case when x.n_patients <= @min_cell_count then -@min_cell_count else t.n_patients_with_code_timing end as n_patients_with_code_timing,
    case when x.n_patients <= @min_cell_count then null else t.lq_days_first end as lq_days_first,
    case when x.n_patients <= @min_cell_count then null else t.median_days_first end as median_days_first,
    case when x.n_patients <= @min_cell_count then null else t.uq_days_first end as uq_days_first,
    case when x.n_patients <= @min_cell_count then null else t.lq_days_closest end as lq_days_closest,
    case when x.n_patients <= @min_cell_count then null else t.median_days_closest end as median_days_closest,
    case when x.n_patients <= @min_cell_count then null else t.uq_days_closest end as uq_days_closest,
    case when x.n_patients <= @min_cell_count then null else t.lq_days_first end as lq_days,
    case when x.n_patients <= @min_cell_count then null else t.median_days_first end as median_days,
    case when x.n_patients <= @min_cell_count then null else t.uq_days_first end as uq_days
 from (
    select anchor_event, event_family, time_relative, concept_id, n_records, n_patients
    from x0brquscevent_code_counts_before_after
    union all
    select anchor_event, event_family, time_relative, concept_id, n_records, n_patients
    from x0brquscevent_code_counts_before_after_first_met
) x
left join x0brquscevent_code_timing_before_after_summary t
  on x.anchor_event = t.anchor_event
 and x.event_family = t.event_family
 and x.time_relative = t.time_relative
 and x.concept_id = t.concept_id
 order by  x.anchor_event, x.event_family, x.time_relative, x.n_patients desc, x.n_records desc, x.concept_id
 ;

