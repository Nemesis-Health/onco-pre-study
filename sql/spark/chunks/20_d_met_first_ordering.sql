-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/20_d_met_first_ordering.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH met_all AS (
 -- DX-anchored MET population: earliest MET date per patient. #met_events is
 -- already restricted to patients who carry an anchor DX code (#anchor_person)
 -- and carries no observation-period gate.
 SELECT
 person_id,
 MIN(event_date) AS first_met_date
 FROM vcbo5u4zmet_events
 GROUP BY person_id
),
dx_all AS (
 -- First specific (anchor) DX per patient, over all anchor-DX events (no
 -- observation-period gate). Every met_all patient appears here by construction.
 SELECT
 person_id,
 MIN(event_date) AS first_dx_date
 FROM vcbo5u4zdx_events
 GROUP BY person_id
),
classified AS (
 SELECT
 ma.person_id,
 CASE
 WHEN dx.first_dx_date < ma.first_met_date THEN 'DX_FIRST'
 WHEN dx.first_dx_date = ma.first_met_date THEN 'SAME_DAY'
 ELSE 'MET_FIRST_THEN_DX'
 END AS ordering_category
 FROM met_all ma
 JOIN dx_all dx
 ON dx.person_id = ma.person_id
),
totals AS (
 SELECT COUNT(*) AS n_patients_met_total FROM classified
)
SELECT
 c.ordering_category,
 CASE WHEN c.ordering_category = 'MET_FIRST_THEN_DX'
 THEN 1 ELSE 0 END AS is_met_first_subgroup,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count
 ELSE COUNT(*) END AS n_patients,
 t.n_patients_met_total
FROM classified c
CROSS JOIN totals t
GROUP BY c.ordering_category, t.n_patients_met_total
ORDER BY
 CASE c.ordering_category
 WHEN 'DX_FIRST' THEN 0
 WHEN 'SAME_DAY' THEN 1
 WHEN 'MET_FIRST_THEN_DX' THEN 2
 ELSE 9
 END;
