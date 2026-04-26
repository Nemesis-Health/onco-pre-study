-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : snowflake
-- Translated     : 2026-04-26 18:36:22 BST
-- Source file    : sql/sql_server/chunks/05_timing_first_to_closest.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

-- 5) Pairwise timing summary: FROM first -> TO closest (counts/min/max censored for small cells)
SELECT
    from_event,
    to_event,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN -@min_cell_count ELSE n_patients_with_pair END AS n_patients_with_pair,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p05_days END AS p05_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p10_days END AS p10_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p20_days END AS p20_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p25_days END AS p25_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p30_days END AS p30_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p40_days END AS p40_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p50_days END AS p50_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p60_days END AS p60_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p70_days END AS p70_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p75_days END AS p75_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p80_days END AS p80_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p90_days END AS p90_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p95_days END AS p95_days
FROM x0brqusctiming_pair_summary_first_to_closest
ORDER BY from_event, to_event
;

