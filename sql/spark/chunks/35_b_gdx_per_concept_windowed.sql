-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/35_b_gdx_per_concept_windowed.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH patient_concept AS (
 -- Per (concept, patient): flags for each directional window. days is the
 -- general code date minus the first specific Diagnosis date.
 SELECT
 g.concept_id,
 g.person_id,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) >= -30 AND DATEDIFF(DAY, c.index_date, g.event_date) <= -1 THEN 1 ELSE 0 END) AS in_before_30d,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) >= -90 AND DATEDIFF(DAY, c.index_date, g.event_date) <= -1 THEN 1 ELSE 0 END) AS in_before_90d,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) >= -180 AND DATEDIFF(DAY, c.index_date, g.event_date) <= -1 THEN 1 ELSE 0 END) AS in_before_180d,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) >= -365 AND DATEDIFF(DAY, c.index_date, g.event_date) <= -1 THEN 1 ELSE 0 END) AS in_before_365d,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) < 0 THEN 1 ELSE 0 END) AS in_ever_before,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) = 0 THEN 1 ELSE 0 END) AS in_day0,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) >= 1 AND DATEDIFF(DAY, c.index_date, g.event_date) <= 30 THEN 1 ELSE 0 END) AS in_after_30d,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) >= 1 AND DATEDIFF(DAY, c.index_date, g.event_date) <= 90 THEN 1 ELSE 0 END) AS in_after_90d,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) >= 1 AND DATEDIFF(DAY, c.index_date, g.event_date) <= 180 THEN 1 ELSE 0 END) AS in_after_180d,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) >= 1 AND DATEDIFF(DAY, c.index_date, g.event_date) <= 365 THEN 1 ELSE 0 END) AS in_after_365d,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) > 0 THEN 1 ELSE 0 END) AS in_ever_after
 FROM vcbo5u4zgen_cancer_events g
 JOIN vcbo5u4zcohort c
 ON g.person_id = c.person_id
 GROUP BY g.concept_id, g.person_id
),
agg AS (
 SELECT
 concept_id,
 COUNT(*) AS n_patients,
 SUM(in_before_30d) AS n_before_30d,
 SUM(in_before_90d) AS n_before_90d,
 SUM(in_before_180d) AS n_before_180d,
 SUM(in_before_365d) AS n_before_365d,
 SUM(in_ever_before) AS n_ever_before,
 SUM(in_day0) AS n_at_day0,
 SUM(in_after_30d) AS n_after_30d,
 SUM(in_after_90d) AS n_after_90d,
 SUM(in_after_180d) AS n_after_180d,
 SUM(in_after_365d) AS n_after_365d,
 SUM(in_ever_after) AS n_ever_after
 FROM patient_concept
 GROUP BY concept_id
)
SELECT
 a.concept_id,
 CASE WHEN a.n_patients > 0 AND a.n_patients <= @min_cell_count THEN -@min_cell_count ELSE a.n_patients END AS n_patients,
 CASE WHEN a.n_before_30d > 0 AND a.n_before_30d <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_30d END AS n_before_30d,
 CASE WHEN a.n_before_90d > 0 AND a.n_before_90d <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_90d END AS n_before_90d,
 CASE WHEN a.n_before_180d > 0 AND a.n_before_180d <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_180d END AS n_before_180d,
 CASE WHEN a.n_before_365d > 0 AND a.n_before_365d <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_365d END AS n_before_365d,
 CASE WHEN a.n_ever_before > 0 AND a.n_ever_before <= @min_cell_count THEN -@min_cell_count ELSE a.n_ever_before END AS n_ever_before,
 CASE WHEN a.n_at_day0 > 0 AND a.n_at_day0 <= @min_cell_count THEN -@min_cell_count ELSE a.n_at_day0 END AS n_at_day0,
 CASE WHEN a.n_after_30d > 0 AND a.n_after_30d <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_30d END AS n_after_30d,
 CASE WHEN a.n_after_90d > 0 AND a.n_after_90d <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_90d END AS n_after_90d,
 CASE WHEN a.n_after_180d > 0 AND a.n_after_180d <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_180d END AS n_after_180d,
 CASE WHEN a.n_after_365d > 0 AND a.n_after_365d <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_365d END AS n_after_365d,
 CASE WHEN a.n_ever_after > 0 AND a.n_ever_after <= @min_cell_count THEN -@min_cell_count ELSE a.n_ever_after END AS n_ever_after
FROM agg a
ORDER BY
 a.n_patients DESC,
 a.concept_id;
