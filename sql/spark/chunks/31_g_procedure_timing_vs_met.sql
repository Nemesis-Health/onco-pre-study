-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/31_g_procedure_timing_vs_met.sql
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
dtp_all AS (
 -- Earliest Drug Therapy procedure date per patient (any concept root). The inner
 -- join to the DX-anchored met_all below restricts this to the same cohort, so no
 -- separate DX gate is needed here.
 SELECT
 po.person_id,
 MIN(po.procedure_date) AS first_dtp_date
 FROM @cdm_database_schema.procedure_occurrence po
 JOIN vcbo5u4zdtp_concepts dtp
 ON po.procedure_concept_id = dtp.concept_id
 GROUP BY po.person_id
),
gap AS (
 -- Patients with BOTH events signed gap from first MET to first DTP.
 SELECT
 ma.person_id,
 DATEDIFF(DAY, ma.first_met_date, da.first_dtp_date) AS gap_days
 FROM met_all ma
 JOIN dtp_all da
 ON da.person_id = ma.person_id
),
bucketed AS (
 SELECT
 person_id,
 CASE
 WHEN gap_days < -90 THEN 'DTP_GT90D_BEFORE_MET'
 WHEN gap_days < 0 THEN 'DTP_1_90D_BEFORE_MET'
 WHEN gap_days = 0 THEN 'DTP_ON_MET_DAY'
 WHEN gap_days <= 90 THEN 'DTP_1_90D_AFTER_MET'
 WHEN gap_days <= 365 THEN 'DTP_91_365D_AFTER_MET'
 ELSE 'DTP_GT365D_AFTER_MET'
 END AS timing_bucket,
 CASE
 WHEN gap_days < -90 THEN 1
 WHEN gap_days < 0 THEN 2
 WHEN gap_days = 0 THEN 3
 WHEN gap_days <= 90 THEN 4
 WHEN gap_days <= 365 THEN 5
 ELSE 6
 END AS bucket_order
 FROM gap
),
totals AS (
 SELECT COUNT(*) AS n_patients_both_total FROM bucketed
)
SELECT
 b.timing_bucket,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count
 ELSE COUNT(*) END AS n_patients,
 t.n_patients_both_total
FROM bucketed b
CROSS JOIN totals t
GROUP BY b.timing_bucket, t.n_patients_both_total
ORDER BY MIN(b.bucket_order);
