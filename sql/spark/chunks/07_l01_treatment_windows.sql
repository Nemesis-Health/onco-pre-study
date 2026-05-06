-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-05-06 18:06:53 BST
-- Source file    : sql/sql_server/chunks/07_l01_treatment_windows.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH window_bounds  AS (SELECT  CAST('INDEX' as STRING) AS anchor_event,
 c.person_id,
 c.index_date AS anchor_date,
 w.window_index
 FROM cbse36ibcohort c
 CROSS JOIN (
 SELECT -12 AS window_index UNION ALL SELECT -11 UNION ALL SELECT -10
 UNION ALL SELECT -9 UNION ALL SELECT -8 UNION ALL SELECT -7
 UNION ALL SELECT -6 UNION ALL SELECT -5 UNION ALL SELECT -4
 UNION ALL SELECT -3 UNION ALL SELECT -2 UNION ALL SELECT -1
 UNION ALL SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2
 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14
 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17
 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23
 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26
 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29
 UNION ALL SELECT 30 UNION ALL SELECT 31 UNION ALL SELECT 32
 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35
 UNION ALL SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38
 UNION ALL SELECT 39 UNION ALL SELECT 40 UNION ALL SELECT 41
 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL SELECT 44
 UNION ALL SELECT 45 UNION ALL SELECT 46 UNION ALL SELECT 47
 ) w
 UNION ALL
 SELECT
 'FIRST_MET' AS anchor_event,
 ms.person_id,
 ms.first_met_date AS anchor_date,
 w.window_index
 FROM cbse36ibmet_summary ms
 WHERE ms.first_met_date IS NOT NULL
 CROSS JOIN (
 SELECT -6 AS window_index UNION ALL SELECT -5 UNION ALL SELECT -4
 UNION ALL SELECT -3 UNION ALL SELECT -2 UNION ALL SELECT -1
 UNION ALL SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2
 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14
 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17
 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23
 ) w
),
-- Mark which patients have at least one L01 exposure in each window
window_l01 AS (
 SELECT
 wb.anchor_event,
 wb.person_id,
 wb.window_index,
 wb.anchor_date,
 MAX(
 CASE
 WHEN le.event_date >= DATEADD(DAY, 30 * wb.window_index, wb.anchor_date)
 AND le.event_date < DATEADD(DAY, 30 * (wb.window_index + 1), wb.anchor_date)
 THEN 1 ELSE 0
 END
 ) AS has_l01_in_window
 FROM window_bounds wb
 LEFT JOIN cbse36ibl01_events le
 ON wb.person_id = le.person_id
 GROUP BY wb.anchor_event, wb.person_id, wb.window_index, wb.anchor_date
),
-- Denominator: patients observed through the window midpoint
-- (anchor + 30*k + 15 days must be within at least one observation period)
window_denom AS (
 SELECT
 wb.anchor_event,
 wb.person_id,
 wb.window_index,
 wb.anchor_date,
 MAX(
 CASE
 WHEN op.observation_period_start_date <= DATEADD(DAY, 30 * wb.window_index + 15, wb.anchor_date)
 AND op.observation_period_end_date >= DATEADD(DAY, 30 * wb.window_index + 15, wb.anchor_date)
 THEN 1 ELSE 0
 END
 ) AS observed_at_midpoint
 FROM window_bounds wb
 LEFT JOIN @cdm_database_schema.observation_period op
 ON op.person_id = wb.person_id
 GROUP BY wb.anchor_event, wb.person_id, wb.window_index, wb.anchor_date
),
agg AS (
 SELECT
 wl.anchor_event,
 wl.window_index,
 COUNT(*) AS n_eligible,
 SUM(wd.observed_at_midpoint) AS n_observed,
 SUM(wl.has_l01_in_window) AS n_patients_with_l01
 FROM window_l01 wl
 JOIN window_denom wd
 ON wd.anchor_event = wl.anchor_event
 AND wd.person_id = wl.person_id
 AND wd.window_index = wl.window_index
 GROUP BY wl.anchor_event, wl.window_index
)
SELECT
 a.anchor_event,
 a.window_index,
 a.n_eligible,
 CASE WHEN a.n_observed <= @min_cell_count THEN -@min_cell_count ELSE a.n_observed END AS n_observed,
 CASE WHEN a.n_patients_with_l01 <= @min_cell_count THEN -@min_cell_count ELSE a.n_patients_with_l01 END AS n_patients_with_l01
FROM agg a
ORDER BY a.anchor_event, a.window_index;
