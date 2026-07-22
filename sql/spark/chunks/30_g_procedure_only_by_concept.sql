-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/30_g_procedure_only_by_concept.sql
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
drugexp_flag AS (
 -- MET patients with an antineoplastic drug_exposure on or after the first MET.
 SELECT DISTINCT ma.person_id
 FROM met_all ma
 JOIN vcbo5u4zl01_events le
 ON le.person_id = ma.person_id
 WHERE le.event_date >= ma.first_met_date
),
proc_on_after AS (
 -- Every Drug Therapy procedure on or after the first MET, tagged with its root.
 SELECT DISTINCT
 ma.person_id,
 dtp.root_concept_id
 FROM met_all ma
 JOIN @cdm_database_schema.procedure_occurrence po
 ON po.person_id = ma.person_id
 JOIN vcbo5u4zdtp_concepts dtp
 ON po.procedure_concept_id = dtp.concept_id
 WHERE po.procedure_date >= ma.first_met_date
),
proc_only AS (
 -- Procedure-only group: a procedure on or after MET, and NOT in drugexp_flag.
 SELECT p.person_id, p.root_concept_id
 FROM proc_on_after p
 LEFT JOIN drugexp_flag d ON d.person_id = p.person_id
 WHERE d.person_id IS NULL
),
totals AS (
 SELECT COUNT(DISTINCT person_id) AS n_procedure_only_total FROM proc_only
)
SELECT
 po.root_concept_id,
 CASE WHEN COUNT(DISTINCT po.person_id) > 0
 AND COUNT(DISTINCT po.person_id) <= @min_cell_count THEN -@min_cell_count
 ELSE COUNT(DISTINCT po.person_id) END AS n_patients,
 t.n_procedure_only_total
FROM proc_only po
CROSS JOIN totals t
GROUP BY po.root_concept_id, t.n_procedure_only_total
ORDER BY COUNT(DISTINCT po.person_id) DESC, po.root_concept_id;
