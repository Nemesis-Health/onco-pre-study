-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/21_d_met_first_dx_support.sql
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
 MIN(event_date) AS first_dx_date,
 COUNT(DISTINCT event_date) AS n_dx_days
 FROM vcbo5u4zdx_events
 GROUP BY person_id
),
subgroup AS (
 -- MET-first subgroup: the first MET strictly precedes the first specific DX.
 -- Every patient has a specific DX (DX-anchored cohort), so the only remaining
 -- distinction is how well supported that DX anchor is.
 SELECT
 ma.person_id,
 dx.n_dx_days
 FROM met_all ma
 JOIN dx_all dx
 ON dx.person_id = ma.person_id
 WHERE ma.first_met_date < dx.first_dx_date
),
bucketed AS (
 SELECT
 person_id,
 CASE
 WHEN n_dx_days = 1 THEN 'SPECIFIC_DX_SINGLE_DAY'
 ELSE 'SPECIFIC_DX_2PLUS_DAYS'
 END AS dx_support_bucket
 FROM subgroup
),
totals AS (
 SELECT COUNT(*) AS n_patients_subgroup_total FROM bucketed
)
SELECT
 b.dx_support_bucket,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count
 ELSE COUNT(*) END AS n_patients,
 t.n_patients_subgroup_total
FROM bucketed b
CROSS JOIN totals t
GROUP BY b.dx_support_bucket, t.n_patients_subgroup_total
ORDER BY
 CASE b.dx_support_bucket
 WHEN 'SPECIFIC_DX_SINGLE_DAY' THEN 1
 WHEN 'SPECIFIC_DX_2PLUS_DAYS' THEN 2
 ELSE 9
 END;
