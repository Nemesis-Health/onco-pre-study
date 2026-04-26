-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : sqlite
-- Translated     : 2026-04-26 18:36:19 BST
-- Source file    : sql/sql_server/chunks/02_event_code_counts.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

-- 2) Event code counts by family+concept_id (small-cell suppressed)
--    Concept-level timing: FIRST (earliest) and CLOSEST (min |days|) per person/concept; lq/median/uq = FIRST for legacy.
SELECT
    c.anchor_event,
    c.event_family,
    c.concept_id,
    CASE WHEN c.n_patients <= @min_cell_count THEN -@min_cell_count ELSE c.n_records END AS n_records,
    CASE WHEN c.n_patients <= @min_cell_count THEN -@min_cell_count ELSE c.n_patients END AS n_patients,
    CASE WHEN c.n_patients <= @min_cell_count THEN -@min_cell_count ELSE t.n_patients_with_code_timing END AS n_patients_with_code_timing,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.lq_days_first END AS lq_days_first,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.median_days_first END AS median_days_first,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.uq_days_first END AS uq_days_first,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.lq_days_closest END AS lq_days_closest,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.median_days_closest END AS median_days_closest,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.uq_days_closest END AS uq_days_closest,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.lq_days_first END AS lq_days,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.median_days_first END AS median_days,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.uq_days_first END AS uq_days
FROM temp.event_code_counts c
LEFT JOIN temp.event_code_timing_summary t
  ON c.anchor_event = t.anchor_event
 AND c.event_family = t.event_family
 AND c.concept_id = t.concept_id
ORDER BY c.anchor_event, c.event_family, c.n_patients DESC, c.n_records DESC, c.concept_id
;

