-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/24_h_closest_treatment_placement.sql
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
l01_all AS (
 -- Antineoplastic drug_exposure records for the DX anchor cohort (#l01_events is
 -- gated to #anchor_person, the same cohort as the MET population).
 SELECT
 person_id,
 event_date
 FROM vcbo5u4zl01_events
),
pair AS (
 -- Signed L01-to-first-MET distance for every L01 record of a MET patient.
 SELECT
 ma.person_id,
 DATEDIFF(DAY, ma.first_met_date, la.event_date) AS days_diff,
 la.event_date
 FROM met_all ma
 JOIN l01_all la
 ON la.person_id = ma.person_id
),
closest AS (
 -- Single closest L01 record per patient (framework CLOSEST convention).
 SELECT
 person_id,
 days_diff,
 ROW_NUMBER() OVER (
 PARTITION BY person_id
 ORDER BY ABS(days_diff), event_date
 ) AS rn
 FROM pair
),
classified AS (
 SELECT
 ma.person_id,
 CASE
 WHEN c.days_diff IS NULL THEN 'NO_L01_EVER'
 WHEN c.days_diff < 0 THEN 'CLOSEST_L01_BEFORE_MET'
 WHEN c.days_diff = 0 THEN 'CLOSEST_L01_ON_MET_DAY'
 ELSE 'CLOSEST_L01_AFTER_MET'
 END AS placement_category
 FROM met_all ma
 LEFT JOIN (SELECT person_id, days_diff FROM closest WHERE rn = 1) c
 ON c.person_id = ma.person_id
),
totals AS (
 SELECT COUNT(*) AS n_patients_met_total FROM met_all
)
SELECT
 c.placement_category,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count
 ELSE COUNT(*) END AS n_patients,
 t.n_patients_met_total
FROM classified c
CROSS JOIN totals t
GROUP BY c.placement_category, t.n_patients_met_total
ORDER BY
 CASE c.placement_category
 WHEN 'CLOSEST_L01_BEFORE_MET' THEN 0
 WHEN 'CLOSEST_L01_ON_MET_DAY' THEN 1
 WHEN 'CLOSEST_L01_AFTER_MET' THEN 2
 WHEN 'NO_L01_EVER' THEN 3
 ELSE 9
 END;
