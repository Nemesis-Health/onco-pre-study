-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:26 CEST
-- Source file    : sql/sql_server/chunks/19_f_dx_intercode_timing.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH dx_days AS (
 SELECT DISTINCT e.person_id, e.event_date AS event_day
 FROM vcbo5u4zdx_events e
 JOIN vcbo5u4zcohort c ON e.person_id = c.person_id
),
ranked AS (
 SELECT
 person_id,
 event_day,
 ROW_NUMBER() OVER (PARTITION BY person_id ORDER BY event_day) AS day_rank,
 LEAD(event_day) OVER (PARTITION BY person_id ORDER BY event_day) AS next_day
 FROM dx_days
),
transitions AS (
 SELECT
 CASE day_rank WHEN 1 THEN 'DX_1_TO_2' WHEN 2 THEN 'DX_2_TO_3' END AS transition,
 DATEDIFF(DAY, event_day, next_day) AS gap_days
 FROM ranked
 WHERE day_rank IN (1, 2)
 AND next_day IS NOT NULL
),
bucketed AS (
 SELECT
 transition,
 CASE
 WHEN gap_days <= 30 THEN 'lte30d'
 WHEN gap_days <= 90 THEN '31_90d'
 WHEN gap_days <= 365 THEN '91_365d'
 ELSE 'gt365d'
 END AS gap_bucket,
 CASE
 WHEN gap_days <= 30 THEN 1
 WHEN gap_days <= 90 THEN 2
 WHEN gap_days <= 365 THEN 3
 ELSE 4
 END AS bucket_order
 FROM transitions
),
totals AS (
 SELECT transition, COUNT(*) AS n_transitions_total
 FROM bucketed
 GROUP BY transition
)
SELECT
 b.transition,
 b.gap_bucket,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count ELSE COUNT(*) END AS n_transitions,
 t.n_transitions_total
FROM bucketed b
JOIN totals t ON t.transition = b.transition
GROUP BY b.transition, b.gap_bucket, t.n_transitions_total
ORDER BY b.transition, MIN(b.bucket_order);
