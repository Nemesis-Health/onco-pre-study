-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/32_g_drugexp_cooccurrence.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH proc_carriers AS (
 -- Distinct patients carrying each DTP concept root (row denominator), restricted
 -- to the DX-anchored cohort (#anchor_person).
 SELECT DISTINCT
 po.person_id,
 dtp.root_concept_id
 FROM @cdm_database_schema.procedure_occurrence po
 JOIN vcbo5u4zanchor_person ap
 ON ap.person_id = po.person_id
 JOIN vcbo5u4zdtp_concepts dtp
 ON po.procedure_concept_id = dtp.concept_id
),
proc_dates AS (
 -- Distinct (patient, root, procedure_date) for the timing comparison, restricted
 -- to the DX-anchored cohort.
 SELECT DISTINCT
 po.person_id,
 dtp.root_concept_id,
 po.procedure_date
 FROM @cdm_database_schema.procedure_occurrence po
 JOIN vcbo5u4zanchor_person ap
 ON ap.person_id = po.person_id
 JOIN vcbo5u4zdtp_concepts dtp
 ON po.procedure_concept_id = dtp.concept_id
),
l01_dates AS (
 -- Distinct antineoplastic drug_exposure dates per patient. #l01_events is already
 -- gated to #anchor_person (drug_exposure JOIN #l01_concepts JOIN #anchor_person).
 SELECT DISTINCT
 person_id,
 event_date AS l01_date
 FROM vcbo5u4zl01_events
),
pairs AS (
 -- Signed gap from each procedure to each L01 record of the same patient.
 -- gap_days = DATEDIFF(procedure_date, l01_date): negative = L01 before the
 -- procedure, 0 = same day, positive = L01 after the procedure.
 SELECT
 pd.person_id,
 pd.root_concept_id,
 DATEDIFF(DAY, pd.procedure_date, ld.l01_date) AS gap_days
 FROM proc_dates pd
 JOIN l01_dates ld
 ON ld.person_id = pd.person_id
),
per_patient AS (
 -- Per (patient, root): closest L01 on each side and any-ever flag.
 SELECT
 person_id,
 root_concept_id,
 MIN(CASE WHEN gap_days < 0 THEN -gap_days END) AS closest_before_days,
 MAX(CASE WHEN gap_days = 0 THEN 1 ELSE 0 END) AS has_day0,
 MIN(CASE WHEN gap_days > 0 THEN gap_days END) AS closest_after_days,
 1 AS has_l01_ever
 FROM pairs
 GROUP BY person_id, root_concept_id
),
joined AS (
 -- All procedure carriers co-occurrence attributes NULL when the patient has
 -- no L01 record at all (still counted in the denominator, contributes 0).
 SELECT
 c.person_id,
 c.root_concept_id,
 pp.closest_before_days,
 pp.has_day0,
 pp.closest_after_days,
 pp.has_l01_ever
 FROM proc_carriers c
 LEFT JOIN per_patient pp
 ON pp.person_id = c.person_id
 AND pp.root_concept_id = c.root_concept_id
),
agg AS (
 SELECT
 root_concept_id,
 COUNT(*) AS n_with_proc,
 SUM(CASE WHEN closest_before_days <= 7 THEN 1 ELSE 0 END) AS n_before_7d,
 SUM(CASE WHEN closest_before_days <= 14 THEN 1 ELSE 0 END) AS n_before_14d,
 SUM(CASE WHEN closest_before_days <= 30 THEN 1 ELSE 0 END) AS n_before_30d,
 SUM(CASE WHEN closest_before_days <= 90 THEN 1 ELSE 0 END) AS n_before_90d,
 SUM(CASE WHEN has_day0 = 1 THEN 1 ELSE 0 END) AS n_day0,
 SUM(CASE WHEN closest_after_days <= 7 THEN 1 ELSE 0 END) AS n_after_7d,
 SUM(CASE WHEN closest_after_days <= 14 THEN 1 ELSE 0 END) AS n_after_14d,
 SUM(CASE WHEN closest_after_days <= 30 THEN 1 ELSE 0 END) AS n_after_30d,
 SUM(CASE WHEN closest_after_days <= 90 THEN 1 ELSE 0 END) AS n_after_90d,
 SUM(CASE WHEN has_l01_ever = 1 THEN 1 ELSE 0 END) AS n_ever
 FROM joined
 GROUP BY root_concept_id
)
SELECT
 a.root_concept_id,
 CASE WHEN a.n_with_proc > 0 AND a.n_with_proc <= @min_cell_count THEN -@min_cell_count ELSE a.n_with_proc END AS n_patients_with_procedure,
 CASE WHEN a.n_before_7d > 0 AND a.n_before_7d <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_7d END AS n_drugexp_le7d_before,
 CASE WHEN a.n_before_14d > 0 AND a.n_before_14d <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_14d END AS n_drugexp_le14d_before,
 CASE WHEN a.n_before_30d > 0 AND a.n_before_30d <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_30d END AS n_drugexp_le30d_before,
 CASE WHEN a.n_before_90d > 0 AND a.n_before_90d <= @min_cell_count THEN -@min_cell_count ELSE a.n_before_90d END AS n_drugexp_le90d_before,
 CASE WHEN a.n_day0 > 0 AND a.n_day0 <= @min_cell_count THEN -@min_cell_count ELSE a.n_day0 END AS n_drugexp_on_day0,
 CASE WHEN a.n_after_7d > 0 AND a.n_after_7d <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_7d END AS n_drugexp_le7d_after,
 CASE WHEN a.n_after_14d > 0 AND a.n_after_14d <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_14d END AS n_drugexp_le14d_after,
 CASE WHEN a.n_after_30d > 0 AND a.n_after_30d <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_30d END AS n_drugexp_le30d_after,
 CASE WHEN a.n_after_90d > 0 AND a.n_after_90d <= @min_cell_count THEN -@min_cell_count ELSE a.n_after_90d END AS n_drugexp_le90d_after,
 CASE WHEN a.n_ever > 0 AND a.n_ever <= @min_cell_count THEN -@min_cell_count ELSE a.n_ever END AS n_drugexp_ever
FROM agg a
ORDER BY a.n_with_proc DESC, a.root_concept_id;
