-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/29_g_treatment_signal_source.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH met_all AS (
 -- DX-anchored MET population: earliest MET date per patient (#met_events is
 -- gated to #anchor_person and carries no observation-period gate).
 SELECT
 person_id,
 MIN(event_date) AS first_met_date
 FROM vcbo5u4zmet_events
 GROUP BY person_id
),
drugexp_flag AS (
 -- MET patients with >= 1 antineoplastic drug_exposure on or after the first MET.
 -- #l01_events is gated to #anchor_person, the same cohort as met_all.
 SELECT DISTINCT ma.person_id
 FROM met_all ma
 JOIN vcbo5u4zl01_events le
 ON le.person_id = ma.person_id
 WHERE le.event_date >= ma.first_met_date
),
dtp_flag AS (
 -- MET patients with >= 1 Drug Therapy procedure on or after the first MET.
 -- No procedure event table exists in setup the join to the DX-anchored met_all
 -- restricts procedure_occurrence to the same cohort.
 SELECT DISTINCT ma.person_id
 FROM met_all ma
 JOIN @cdm_database_schema.procedure_occurrence po
 ON po.person_id = ma.person_id
 JOIN vcbo5u4zdtp_concepts dtp
 ON po.procedure_concept_id = dtp.concept_id
 WHERE po.procedure_date >= ma.first_met_date
),
classified AS (
 SELECT
 ma.person_id,
 CASE
 WHEN d.person_id IS NOT NULL THEN 'DRUG_EXPOSURE_ON_OR_AFTER_MET'
 WHEN p.person_id IS NOT NULL THEN 'DTP_ONLY_ON_OR_AFTER_MET'
 ELSE 'NEITHER_ON_OR_AFTER_MET'
 END AS signal_source
 FROM met_all ma
 LEFT JOIN drugexp_flag d ON d.person_id = ma.person_id
 LEFT JOIN dtp_flag p ON p.person_id = ma.person_id
),
totals AS (
 SELECT COUNT(*) AS n_patients_met_total FROM met_all
)
SELECT
 c.signal_source,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count
 ELSE COUNT(*) END AS n_patients,
 t.n_patients_met_total
FROM classified c
CROSS JOIN totals t
GROUP BY c.signal_source, t.n_patients_met_total
ORDER BY
 CASE c.signal_source
 WHEN 'DRUG_EXPOSURE_ON_OR_AFTER_MET' THEN 0
 WHEN 'DTP_ONLY_ON_OR_AFTER_MET' THEN 1
 WHEN 'NEITHER_ON_OR_AFTER_MET' THEN 2
 ELSE 9
 END;
