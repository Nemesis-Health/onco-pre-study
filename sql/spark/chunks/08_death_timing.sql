-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-05-07 11:54:01 BST
-- Source file    : sql/sql_server/chunks/08_death_timing.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

SELECT
 s.prevalence_year,
 s.anchor_event,
 CASE WHEN s.n_patients <= @min_cell_count THEN -@min_cell_count ELSE s.n_patients END AS n_patients,
 CASE
 WHEN s.n_patients <= @min_cell_count THEN -@min_cell_count
 WHEN s.n_deaths BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
 ELSE s.n_deaths
 END AS n_deaths,
 CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE s.n_deaths_in_obs END AS n_deaths_in_obs,
 CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE s.n_deaths_out_obs END AS n_deaths_out_obs,
 CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.lq_days END AS lq_days,
 CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.median_days END AS median_days,
 CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.uq_days END AS uq_days,
 CASE WHEN s.n_patients <= @min_cell_count THEN NULL ELSE f.lq_followup_days END AS lq_followup_days,
 CASE WHEN s.n_patients <= @min_cell_count THEN NULL ELSE f.median_followup_days END AS median_followup_days,
 CASE WHEN s.n_patients <= @min_cell_count THEN NULL ELSE f.uq_followup_days END AS uq_followup_days
FROM ctxb0womdeath_stratum_counts s
LEFT JOIN ctxb0womdeath_timing_quantiles q
 ON s.prevalence_year = q.prevalence_year
 AND s.anchor_event = q.anchor_event
LEFT JOIN ctxb0womfollowup_quantiles f
 ON s.prevalence_year = f.prevalence_year
 AND s.anchor_event = f.anchor_event
ORDER BY
 CASE WHEN s.prevalence_year = 'OVERALL' THEN 0 ELSE 1 END,
 CASE WHEN s.prevalence_year = 'OVERALL' THEN NULL ELSE CAST(s.prevalence_year AS INT) END,
 CASE WHEN s.anchor_event = 'INDEX' THEN 0 ELSE 1 END;
