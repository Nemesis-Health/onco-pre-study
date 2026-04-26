-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : iris
-- Translated     : 2026-04-26 18:36:23 BST
-- Source file    : sql/sql_server/chunks/08_death_timing.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

-- 8) Death timing from INDEX and FIRST_MET (stratified by calendar year of index date and OVERALL)
SELECT
    s.prevalence_year,
    s.anchor_event,
    CASE WHEN s.n_patients <= @min_cell_count THEN -@min_cell_count ELSE s.n_patients END AS n_patients,
    CASE
        WHEN s.n_patients <= @min_cell_count THEN -@min_cell_count
        WHEN s.n_deaths BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
        ELSE s.n_deaths
    END AS n_deaths,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.p05_days END AS p05_days,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.p10_days END AS p10_days,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.lq_days END AS lq_days,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.median_days END AS median_days,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.uq_days END AS uq_days,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.p90_days END AS p90_days,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.p95_days END AS p95_days
FROM x0brquscdeath_stratum_counts s
LEFT JOIN x0brquscdeath_timing_quantiles q
  ON s.prevalence_year = q.prevalence_year
 AND s.anchor_event = q.anchor_event
ORDER BY
    CASE WHEN s.prevalence_year = 'OVERALL' THEN 0 ELSE 1 END,
    CAST(s.prevalence_year AS INT),
    CASE WHEN s.anchor_event = 'INDEX' THEN 0 ELSE 1 END
;

