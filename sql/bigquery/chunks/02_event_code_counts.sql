-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-04-26 18:36:18 BST
-- Source file    : sql/sql_server/chunks/02_event_code_counts.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 2) Event code counts by family+concept_id (small-cell suppressed)
--    Concept-level timing: FIRST (earliest) and CLOSEST (min |days|) per person/concept; lq/median/uq = FIRST for legacy.
 select c.anchor_event,
    c.event_family,
    c.concept_id,
    case when c.n_patients <= @min_cell_count then -@min_cell_count else c.n_records end as n_records,
    case when c.n_patients <= @min_cell_count then -@min_cell_count else c.n_patients end as n_patients,
    case when c.n_patients <= @min_cell_count then -@min_cell_count else t.n_patients_with_code_timing end as n_patients_with_code_timing,
    case when c.n_patients <= @min_cell_count then null else t.lq_days_first end as lq_days_first,
    case when c.n_patients <= @min_cell_count then null else t.median_days_first end as median_days_first,
    case when c.n_patients <= @min_cell_count then null else t.uq_days_first end as uq_days_first,
    case when c.n_patients <= @min_cell_count then null else t.lq_days_closest end as lq_days_closest,
    case when c.n_patients <= @min_cell_count then null else t.median_days_closest end as median_days_closest,
    case when c.n_patients <= @min_cell_count then null else t.uq_days_closest end as uq_days_closest,
    case when c.n_patients <= @min_cell_count then null else t.lq_days_first end as lq_days,
    case when c.n_patients <= @min_cell_count then null else t.median_days_first end as median_days,
    case when c.n_patients <= @min_cell_count then null else t.uq_days_first end as uq_days
 from x0brquscevent_code_counts c
left join x0brquscevent_code_timing_summary t
  on c.anchor_event = t.anchor_event
 and c.event_family = t.event_family
 and c.concept_id = t.concept_id
 order by  c.anchor_event, c.event_family, c.n_patients desc, c.n_records desc, c.concept_id
 ;

