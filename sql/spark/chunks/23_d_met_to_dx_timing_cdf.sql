-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/23_d_met_to_dx_timing_cdf.sql
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
dx_all AS (
 SELECT
 person_id,
 MIN(event_date) AS first_dx_date
 FROM vcbo5u4zdx_events
 GROUP BY person_id
),
gap AS (
 SELECT
 ma.person_id,
 DATEDIFF(DAY, ma.first_met_date, dx.first_dx_date) AS gap_days
 FROM met_all ma
 JOIN dx_all dx
 ON dx.person_id = ma.person_id
 WHERE ma.first_met_date < dx.first_dx_date
),
med AS (
 SELECT MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(gap_days AS FLOAT) END) AS median_days
 FROM (
 SELECT
 gap_days,
 ROW_NUMBER() OVER (ORDER BY gap_days) AS rn,
 COUNT(*) OVER () AS cnt
 FROM gap
 ) x
),
agg AS (
 SELECT
 COUNT(*) AS n_total,
 SUM(CASE WHEN gap_days <= 30 THEN 1 ELSE 0 END) AS n_by_30,
 SUM(CASE WHEN gap_days <= 45 THEN 1 ELSE 0 END) AS n_by_45,
 SUM(CASE WHEN gap_days <= 60 THEN 1 ELSE 0 END) AS n_by_60,
 SUM(CASE WHEN gap_days <= 90 THEN 1 ELSE 0 END) AS n_by_90,
 SUM(CASE WHEN gap_days <= 180 THEN 1 ELSE 0 END) AS n_by_180,
 SUM(CASE WHEN gap_days <= 365 THEN 1 ELSE 0 END) AS n_by_365
 FROM gap
)
SELECT
 a.n_total AS n_patients_reaching_dx_total,
 CASE WHEN a.n_by_30 > 0 AND a.n_by_30 <= @min_cell_count THEN -@min_cell_count ELSE a.n_by_30 END AS n_arrived_by_30d,
 CASE WHEN a.n_by_45 > 0 AND a.n_by_45 <= @min_cell_count THEN -@min_cell_count ELSE a.n_by_45 END AS n_arrived_by_45d,
 CASE WHEN a.n_by_60 > 0 AND a.n_by_60 <= @min_cell_count THEN -@min_cell_count ELSE a.n_by_60 END AS n_arrived_by_60d,
 CASE WHEN a.n_by_90 > 0 AND a.n_by_90 <= @min_cell_count THEN -@min_cell_count ELSE a.n_by_90 END AS n_arrived_by_90d,
 CASE WHEN a.n_by_180 > 0 AND a.n_by_180 <= @min_cell_count THEN -@min_cell_count ELSE a.n_by_180 END AS n_arrived_by_180d,
 CASE WHEN a.n_by_365 > 0 AND a.n_by_365 <= @min_cell_count THEN -@min_cell_count ELSE a.n_by_365 END AS n_arrived_by_365d,
 CASE WHEN a.n_total <= @min_cell_count THEN NULL ELSE m.median_days END AS median_days_met_to_dx
FROM agg a
CROSS JOIN med m;
