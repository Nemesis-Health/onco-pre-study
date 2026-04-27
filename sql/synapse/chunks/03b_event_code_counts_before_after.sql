-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : synapse
-- Translated     : 2026-04-26 18:36:22 BST
-- Source file    : sql/sql_server/chunks/03b_event_code_counts_before_after.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

-- 3b) Event code counts by family+concept_id split BEFORE/AFTER
--     around both INDEX and FIRST_MET anchors (small-cell sentinel)
SELECT
    x.anchor_event,
    x.event_family,
    x.time_relative,
    x.concept_id,
    CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE x.n_records END AS n_records,
    CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE x.n_patients END AS n_patients,
    CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE t.n_patients_with_code_timing END AS n_patients_with_code_timing,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.lq_days_first END AS lq_days_first,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.median_days_first END AS median_days_first,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.uq_days_first END AS uq_days_first,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.lq_days_closest END AS lq_days_closest,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.median_days_closest END AS median_days_closest,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.uq_days_closest END AS uq_days_closest,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.lq_days_first END AS lq_days,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.median_days_first END AS median_days,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.uq_days_first END AS uq_days
FROM (
    SELECT anchor_event, event_family, time_relative, concept_id, n_records, n_patients
    FROM #event_code_counts_before_after
    UNION ALL
    SELECT anchor_event, event_family, time_relative, concept_id, n_records, n_patients
    FROM #event_code_counts_before_after_first_met
) x
LEFT JOIN #event_code_timing_before_after_summary t
  ON x.anchor_event = t.anchor_event
 AND x.event_family = t.event_family
 AND x.time_relative = t.time_relative
 AND x.concept_id = t.concept_id
ORDER BY x.anchor_event, x.event_family, x.time_relative, x.n_patients DESC, x.n_records DESC, x.concept_id
;

