-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/26_h_signed_closest_histogram.sql
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
c1 AS (
 SELECT person_id, days_diff FROM closest WHERE rn = 1
),
binned AS (
 SELECT
 person_id,
 CASE
 WHEN days_diff = 0 THEN 7
 WHEN days_diff <= -366 THEN 1
 WHEN days_diff <= -181 THEN 2
 WHEN days_diff <= -91 THEN 3
 WHEN days_diff <= -61 THEN 4
 WHEN days_diff <= -31 THEN 5
 WHEN days_diff <= -1 THEN 6
 WHEN days_diff <= 30 THEN 8
 WHEN days_diff <= 60 THEN 9
 WHEN days_diff <= 90 THEN 10
 WHEN days_diff <= 180 THEN 11
 WHEN days_diff <= 365 THEN 12
 ELSE 13
 END AS bin_order
 FROM c1
),
labelled AS (
 SELECT
 person_id,
 bin_order,
 CASE WHEN bin_order <= 6 THEN 'BEFORE'
 WHEN bin_order = 7 THEN 'DAY0'
 ELSE 'AFTER' END AS side,
 CASE bin_order
 WHEN 1 THEN '366+'
 WHEN 2 THEN '181-365'
 WHEN 3 THEN '91-180'
 WHEN 4 THEN '61-90'
 WHEN 5 THEN '31-60'
 WHEN 6 THEN '1-30'
 WHEN 7 THEN 'Day 0'
 WHEN 8 THEN '1-30'
 WHEN 9 THEN '31-60'
 WHEN 10 THEN '61-90'
 WHEN 11 THEN '91-180'
 WHEN 12 THEN '181-365'
 ELSE '366+'
 END AS day_range_label
 FROM binned
),
totals AS (
 SELECT COUNT(*) AS n_treated_total FROM c1
)
SELECT
 b.bin_order,
 b.side,
 b.day_range_label,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count
 ELSE COUNT(*) END AS n_patients,
 t.n_treated_total
FROM labelled b
CROSS JOIN totals t
GROUP BY b.bin_order, b.side, b.day_range_label, t.n_treated_total
ORDER BY b.bin_order;
