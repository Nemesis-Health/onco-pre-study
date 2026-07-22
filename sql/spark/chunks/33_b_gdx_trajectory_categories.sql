-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/33_b_gdx_trajectory_categories.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH gdx_flags AS (
 -- Per anchor-cohort patient with >= 1 general cancer diagnosis code:
 -- flags for whether any code sits strictly before, exactly at, or strictly
 -- after the first specific Diagnosis.
 SELECT
 g.person_id,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) < 0 THEN 1 ELSE 0 END) AS has_before,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) = 0 THEN 1 ELSE 0 END) AS has_day0,
 MAX(CASE WHEN DATEDIFF(DAY, c.index_date, g.event_date) > 0 THEN 1 ELSE 0 END) AS has_after_strict
 FROM vcbo5u4zgen_cancer_events g
 JOIN vcbo5u4zcohort c
 ON g.person_id = c.person_id
 GROUP BY g.person_id
),
classified AS (
 -- Every cohort patient placed in exactly one category. at_or_after folds the
 -- day-0 mass onto the after side to reconcile with the validated HUS counts
 -- has_day0 is retained separately for the explicit day-0 column.
 SELECT
 c.person_id,
 CASE
 WHEN g.person_id IS NULL THEN 'NONE'
 WHEN g.has_before = 1 AND (g.has_day0 = 1 OR g.has_after_strict = 1) THEN 'GENERAL_BOTH_BEFORE_AND_AFTER'
 WHEN g.has_before = 1 THEN 'GENERAL_BEFORE_ONLY'
 ELSE 'GENERAL_AFTER_ONLY'
 END AS trajectory_category,
 CASE WHEN g.has_day0 = 1 THEN 1 ELSE 0 END AS at_day0
 FROM vcbo5u4zcohort c
 LEFT JOIN gdx_flags g
 ON g.person_id = c.person_id
),
totals AS (
 SELECT COUNT(*) AS n_cohort_total FROM vcbo5u4zcohort
)
SELECT
 c.trajectory_category,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count
 THEN -@min_cell_count ELSE COUNT(*) END AS n_patients,
 CASE WHEN SUM(c.at_day0) > 0 AND SUM(c.at_day0) <= @min_cell_count
 THEN -@min_cell_count ELSE SUM(c.at_day0) END AS n_general_at_day0,
 t.n_cohort_total
FROM classified c
CROSS JOIN totals t
GROUP BY c.trajectory_category, t.n_cohort_total
ORDER BY
 CASE c.trajectory_category
 WHEN 'NONE' THEN 0
 WHEN 'GENERAL_BEFORE_ONLY' THEN 1
 WHEN 'GENERAL_BOTH_BEFORE_AND_AFTER' THEN 2
 WHEN 'GENERAL_AFTER_ONLY' THEN 3
 ELSE 9
 END;
