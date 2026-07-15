-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:26 CEST
-- Source file    : sql/sql_server/chunks/06b_odx_gdx_directional_cdf.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH events  AS (SELECT  CAST('INDEX' as STRING) AS anchor_event, 'ODX' AS event_family, e.person_id, e.concept_id,
 DATEDIFF(DAY, c.index_date, e.event_date) AS days_from_anchor
 FROM vcbo5u4zother_dx_events e
 JOIN vcbo5u4zcohort c ON e.person_id = c.person_id
 UNION ALL
 SELECT 'INDEX' AS anchor_event, 'GDX' AS event_family, e.person_id, e.concept_id,
 DATEDIFF(DAY, c.index_date, e.event_date) AS days_from_anchor
 FROM vcbo5u4zgen_cancer_events e
 JOIN vcbo5u4zcohort c ON e.person_id = c.person_id
 UNION ALL
 SELECT 'FIRST_MET' AS anchor_event, 'ODX' AS event_family, e.person_id, e.concept_id,
 DATEDIFF(DAY, ms.first_met_date, e.event_date) AS days_from_anchor
 FROM vcbo5u4zother_dx_events e
 JOIN vcbo5u4zcohort c ON e.person_id = c.person_id
 JOIN vcbo5u4zmet_summary ms ON ms.person_id = c.person_id
 WHERE ms.first_met_date IS NOT NULL
 UNION ALL
 SELECT 'FIRST_MET' AS anchor_event, 'GDX' AS event_family, e.person_id, e.concept_id,
 DATEDIFF(DAY, ms.first_met_date, e.event_date) AS days_from_anchor
 FROM vcbo5u4zgen_cancer_events e
 JOIN vcbo5u4zcohort c ON e.person_id = c.person_id
 JOIN vcbo5u4zmet_summary ms ON ms.person_id = c.person_id
 WHERE ms.first_met_date IS NOT NULL
),
per_person AS (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 person_id,
 MAX(CASE WHEN days_from_anchor = 0 THEN 1 ELSE 0 END) AS has_day0,
 MAX(CASE WHEN days_from_anchor < 0 THEN days_from_anchor END) AS closest_before_days,
 MIN(CASE WHEN days_from_anchor > 0 THEN days_from_anchor END) AS closest_after_days
 FROM events
 GROUP BY anchor_event, event_family, concept_id, person_id
),
dir AS (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 person_id,
 has_day0,
 CASE WHEN closest_before_days IS NULL THEN NULL ELSE -closest_before_days END AS days_before,
 closest_after_days AS days_after
 FROM per_person
),
med_before AS (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_before AS FLOAT) END) AS median_days_before
 FROM (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 days_before,
 ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, concept_id ORDER BY days_before) AS rn,
 COUNT(*) OVER (PARTITION BY anchor_event, event_family, concept_id) AS cnt
 FROM dir
 WHERE days_before IS NOT NULL
 ) x
 GROUP BY anchor_event, event_family, concept_id
),
med_after AS (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_after AS FLOAT) END) AS median_days_after
 FROM (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 days_after,
 ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, concept_id ORDER BY days_after) AS rn,
 COUNT(*) OVER (PARTITION BY anchor_event, event_family, concept_id) AS cnt
 FROM dir
 WHERE days_after IS NOT NULL
 ) x
 GROUP BY anchor_event, event_family, concept_id
),
agg AS (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 COUNT(*) AS n_ever,
 SUM(CASE WHEN days_before IS NOT NULL THEN 1 ELSE 0 END) AS n_before_ever,
 SUM(CASE WHEN days_before <= 30 THEN 1 ELSE 0 END) AS n_before_30,
 SUM(CASE WHEN days_before <= 90 THEN 1 ELSE 0 END) AS n_before_90,
 SUM(CASE WHEN days_before <= 180 THEN 1 ELSE 0 END) AS n_before_180,
 SUM(CASE WHEN days_before <= 365 THEN 1 ELSE 0 END) AS n_before_365,
 SUM(CASE WHEN days_before <= 730 THEN 1 ELSE 0 END) AS n_before_730,
 SUM(has_day0) AS n_day0,
 SUM(CASE WHEN days_after IS NOT NULL THEN 1 ELSE 0 END) AS n_after_ever,
 SUM(CASE WHEN days_after <= 30 THEN 1 ELSE 0 END) AS n_after_30,
 SUM(CASE WHEN days_after <= 90 THEN 1 ELSE 0 END) AS n_after_90,
 SUM(CASE WHEN days_after <= 180 THEN 1 ELSE 0 END) AS n_after_180,
 SUM(CASE WHEN days_after <= 365 THEN 1 ELSE 0 END) AS n_after_365,
 SUM(CASE WHEN days_after <= 730 THEN 1 ELSE 0 END) AS n_after_730
 FROM dir
 GROUP BY anchor_event, event_family, concept_id
)
SELECT
 a.anchor_event,
 a.event_family,
 a.concept_id,
 CASE WHEN a.n_ever > 0 AND a.n_ever <= @min_cell_count THEN -@min_cell_count ELSE a.n_ever END AS n_ever,
 CASE WHEN a.n_before_ever > 0 AND a.n_before_ever <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_ever END AS n_before_ever,
 CASE WHEN a.n_before_30 > 0 AND a.n_before_30 <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_30 END AS n_within_30d_before,
 CASE WHEN a.n_before_90 > 0 AND a.n_before_90 <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_90 END AS n_within_90d_before,
 CASE WHEN a.n_before_180 > 0 AND a.n_before_180 <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_180 END AS n_within_180d_before,
 CASE WHEN a.n_before_365 > 0 AND a.n_before_365 <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_365 END AS n_within_365d_before,
 CASE WHEN a.n_before_730 > 0 AND a.n_before_730 <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_730 END AS n_within_730d_before,
 CASE WHEN a.n_before_ever <= @min_cell_count THEN NULL ELSE mb.median_days_before END AS median_days_before,
 CASE WHEN a.n_day0 > 0 AND a.n_day0 <= @min_cell_count THEN -@min_cell_count ELSE a.n_day0 END AS n_day0,
 CASE WHEN a.n_after_ever > 0 AND a.n_after_ever <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_ever END AS n_after_ever,
 CASE WHEN a.n_after_30 > 0 AND a.n_after_30 <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_30 END AS n_within_30d_after,
 CASE WHEN a.n_after_90 > 0 AND a.n_after_90 <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_90 END AS n_within_90d_after,
 CASE WHEN a.n_after_180 > 0 AND a.n_after_180 <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_180 END AS n_within_180d_after,
 CASE WHEN a.n_after_365 > 0 AND a.n_after_365 <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_365 END AS n_within_365d_after,
 CASE WHEN a.n_after_730 > 0 AND a.n_after_730 <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_730 END AS n_within_730d_after,
 CASE WHEN a.n_after_ever <= @min_cell_count THEN NULL ELSE ma.median_days_after END AS median_days_after
FROM agg a
LEFT JOIN med_before mb
 ON mb.anchor_event = a.anchor_event
 AND mb.event_family = a.event_family
 AND mb.concept_id = a.concept_id
LEFT JOIN med_after ma
 ON ma.anchor_event = a.anchor_event
 AND ma.event_family = a.event_family
 AND ma.concept_id = a.concept_id
ORDER BY
 CASE WHEN a.anchor_event = 'INDEX' THEN 0 ELSE 1 END,
 a.event_family,
 a.n_ever DESC,
 a.concept_id;
