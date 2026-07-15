-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/22_d_met_to_dx_timing_buckets.sql
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
 -- MET-first-then-DX only: first MET strictly before the first specific DX.
 SELECT
 ma.person_id,
 DATEDIFF(DAY, ma.first_met_date, dx.first_dx_date) AS gap_days
 FROM met_all ma
 JOIN dx_all dx
 ON dx.person_id = ma.person_id
 WHERE ma.first_met_date < dx.first_dx_date
),
bucketed AS (
 SELECT
 person_id,
 CASE
 WHEN gap_days <= 30 THEN 'LTE30D'
 WHEN gap_days <= 60 THEN 'D31_60'
 WHEN gap_days <= 90 THEN 'D61_90'
 WHEN gap_days <= 180 THEN 'D91_180'
 WHEN gap_days <= 365 THEN 'D181_365'
 ELSE 'GT365D'
 END AS timing_bucket,
 CASE
 WHEN gap_days <= 30 THEN 1
 WHEN gap_days <= 60 THEN 2
 WHEN gap_days <= 90 THEN 3
 WHEN gap_days <= 180 THEN 4
 WHEN gap_days <= 365 THEN 5
 ELSE 6
 END AS bucket_order
 FROM gap
),
totals AS (
 SELECT COUNT(*) AS n_patients_reaching_dx_total FROM bucketed
)
SELECT
 b.timing_bucket,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count
 ELSE COUNT(*) END AS n_patients,
 t.n_patients_reaching_dx_total
FROM bucketed b
CROSS JOIN totals t
GROUP BY b.timing_bucket, t.n_patients_reaching_dx_total
ORDER BY MIN(b.bucket_order);
