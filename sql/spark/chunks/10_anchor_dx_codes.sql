-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-04-26 18:36:18 BST
-- Source file    : sql/sql_server/chunks/10_anchor_dx_codes.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH dx_days AS (
 SELECT DISTINCT
 person_id,
 event_date,
 concept_id
 FROM x0brquscdx_events
)
SELECT
 s.concept_id,
 CASE WHEN s.n_distinct_patients <= @min_cell_count THEN -@min_cell_count ELSE s.n_distinct_patients END AS n_distinct_patients,
 CASE WHEN s.n_distinct_patients <= @min_cell_count THEN NULL ELSE s.n_distinct_patient_days END AS n_distinct_patient_days
FROM (
 SELECT
 concept_id,
 COUNT(DISTINCT person_id) AS n_distinct_patients,
 COUNT(*) AS n_distinct_patient_days
 FROM dx_days
 GROUP BY concept_id
) s
ORDER BY s.n_distinct_patients DESC, s.concept_id;
