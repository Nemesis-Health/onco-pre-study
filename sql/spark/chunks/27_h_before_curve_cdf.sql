-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/27_h_before_curve_cdf.sql
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
before_closest AS (
 -- Closest record is strictly before the first MET.
 SELECT
 person_id,
 ABS(days_diff) AS days_before
 FROM closest
 WHERE rn = 1
 AND days_diff < 0
),
med AS (
 SELECT MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_before AS FLOAT) END) AS median_days
 FROM (
 SELECT
 days_before,
 ROW_NUMBER() OVER (ORDER BY days_before) AS rn,
 COUNT(*) OVER () AS cnt
 FROM before_closest
 ) x
),
agg AS (
 SELECT
 COUNT(*) AS n_total,
 SUM(CASE WHEN days_before <= 30 THEN 1 ELSE 0 END) AS n_30,
 SUM(CASE WHEN days_before <= 60 THEN 1 ELSE 0 END) AS n_60,
 SUM(CASE WHEN days_before <= 90 THEN 1 ELSE 0 END) AS n_90,
 SUM(CASE WHEN days_before <= 180 THEN 1 ELSE 0 END) AS n_180,
 SUM(CASE WHEN days_before <= 365 THEN 1 ELSE 0 END) AS n_365
 FROM before_closest
)
SELECT
 a.n_total AS n_before_total,
 CASE WHEN a.n_30 > 0 AND a.n_30 <= @min_cell_count THEN -@min_cell_count ELSE a.n_30 END AS n_within_30d_before,
 CASE WHEN a.n_60 > 0 AND a.n_60 <= @min_cell_count THEN -@min_cell_count ELSE a.n_60 END AS n_within_60d_before,
 CASE WHEN a.n_90 > 0 AND a.n_90 <= @min_cell_count THEN -@min_cell_count ELSE a.n_90 END AS n_within_90d_before,
 CASE WHEN a.n_180 > 0 AND a.n_180 <= @min_cell_count THEN -@min_cell_count ELSE a.n_180 END AS n_within_180d_before,
 CASE WHEN a.n_365 > 0 AND a.n_365 <= @min_cell_count THEN -@min_cell_count ELSE a.n_365 END AS n_within_365d_before,
 CASE WHEN a.n_total <= @min_cell_count THEN NULL ELSE m.median_days END AS median_days_before_closest
FROM agg a
CROSS JOIN med m;
