-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/25_h_after_curve_population_reconciliation.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH met_all AS (
 SELECT
 person_id,
 MIN(event_date) AS first_met_date
 FROM vcbo5u4zmet_events
 GROUP BY person_id
),
l01_all AS (
 SELECT
 person_id,
 event_date
 FROM vcbo5u4zl01_events
),
pair AS (
 SELECT
 ma.person_id,
 DATEDIFF(DAY, ma.first_met_date, la.event_date) AS days_diff,
 la.event_date
 FROM met_all ma
 JOIN l01_all la
 ON la.person_id = ma.person_id
),
flags AS (
 -- Per treated patient: which sides of the first MET carry any L01 record.
 SELECT
 person_id,
 MAX(CASE WHEN days_diff < 0 THEN 1 ELSE 0 END) AS has_before,
 MAX(CASE WHEN days_diff = 0 THEN 1 ELSE 0 END) AS has_day0,
 MAX(CASE WHEN days_diff > 0 THEN 1 ELSE 0 END) AS has_after
 FROM pair
 GROUP BY person_id
),
closest AS (
 SELECT
 person_id,
 days_diff,
 ROW_NUMBER() OVER (
 PARTITION BY person_id
 ORDER BY ABS(days_diff), event_date
 ) AS rn
 FROM pair
),
closest_side AS (
 SELECT
 person_id,
 CASE WHEN days_diff < 0 THEN 'BEFORE'
 WHEN days_diff = 0 THEN 'DAY0'
 ELSE 'AFTER' END AS cside
 FROM closest
 WHERE rn = 1
),
combined AS (
 SELECT
 f.person_id,
 f.has_before,
 f.has_after,
 cs.cside
 FROM flags f
 JOIN closest_side cs
 ON cs.person_id = f.person_id
),
agg AS (
 SELECT
 COUNT(*) AS n_treated,
 SUM(CASE WHEN cside = 'AFTER' THEN 1 ELSE 0 END) AS n_closest_after,
 SUM(has_after) AS n_after_any,
 SUM(CASE WHEN has_before = 1 AND has_after = 1 THEN 1 ELSE 0 END) AS n_bilateral,
 SUM(CASE WHEN has_before = 1 AND has_after = 1 AND cside = 'BEFORE' THEN 1 ELSE 0 END) AS n_bilateral_closest_before,
 SUM(CASE WHEN has_before = 1 AND has_after = 1 AND cside = 'AFTER' THEN 1 ELSE 0 END) AS n_bilateral_closest_after
 FROM combined
)
SELECT
 CASE WHEN n_treated > 0 AND n_treated <= @min_cell_count THEN -@min_cell_count ELSE n_treated END AS n_treated,
 CASE WHEN n_closest_after > 0 AND n_closest_after <= @min_cell_count THEN -@min_cell_count ELSE n_closest_after END AS n_closest_after,
 CASE WHEN n_after_any > 0 AND n_after_any <= @min_cell_count THEN -@min_cell_count ELSE n_after_any END AS n_after_any,
 CASE WHEN (n_after_any - n_closest_after) > 0 AND (n_after_any - n_closest_after) <= @min_cell_count THEN -@min_cell_count ELSE (n_after_any - n_closest_after) END AS n_after_any_added,
 CASE WHEN n_bilateral > 0 AND n_bilateral <= @min_cell_count THEN -@min_cell_count ELSE n_bilateral END AS n_bilateral,
 CASE WHEN n_bilateral_closest_before > 0 AND n_bilateral_closest_before <= @min_cell_count THEN -@min_cell_count ELSE n_bilateral_closest_before END AS n_bilateral_closest_before,
 CASE WHEN n_bilateral_closest_after > 0 AND n_bilateral_closest_after <= @min_cell_count THEN -@min_cell_count ELSE n_bilateral_closest_after END AS n_bilateral_closest_after
FROM agg;
