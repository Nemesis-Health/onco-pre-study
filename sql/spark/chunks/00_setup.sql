-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-05-06 20:27:55 BST
-- Source file    : sql/sql_server/chunks/00_setup.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

DROP TABLE IF EXISTS d5ifm2a4dx_anchor_include;
DROP TABLE IF EXISTS d5ifm2a4dx_anchor_include;
CREATE TABLE d5ifm2a4dx_anchor_include  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS smallint) AS include_descendants  WHERE 1 = 0;
INSERT INTO d5ifm2a4dx_anchor_include (concept_id, include_descendants) VALUES
 (197508, 1), -- Malignant neoplasm of urinary bladder
 (4181357, 1), -- Malignant tumor of renal pelvis
 (4177230, 1), -- Malignant tumor of urethra
 (37163176, 1), -- Transitional cell carcinoma of upper urinary tract
 (4178972, 1), -- Malignant tumor of ureter
 (4091486, 0), -- Malignant neoplasm of overlapping sites of urinary organs
 (44501785, 0), -- Transitional cell carcinoma, NOS, of urinary system, NOS (ICDO3)
 (37110270, 1) -- Primary urothelial carcinoma of overlapping sites of urinary organs
;
DROP TABLE IF EXISTS d5ifm2a4dx_anchor_exclude;
DROP TABLE IF EXISTS d5ifm2a4dx_anchor_exclude;
CREATE TABLE d5ifm2a4dx_anchor_exclude  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS smallint) AS include_descendants  WHERE 1 = 0;
INSERT INTO d5ifm2a4dx_anchor_exclude (concept_id, include_descendants) VALUES
 (4280899, 1),
 (4289374, 1),
 (4280900, 1),
 (4283614, 1),
 (4289097, 1),
 (4280901, 1),
 (4289376, 1),
 (4280897, 1),
 (4200889, 1);
DROP TABLE IF EXISTS d5ifm2a4dx_anchor_concepts;
DROP TABLE IF EXISTS d5ifm2a4dx_anchor_concepts;
CREATE TABLE d5ifm2a4dx_anchor_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4dx_anchor_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM d5ifm2a4dx_anchor_include i
JOIN @cdm_database_schema.concept_ancestor ca
 ON ca.ancestor_concept_id = i.concept_id
 AND (i.include_descendants = 1 OR ca.descendant_concept_id = i.concept_id);
DELETE FROM d5ifm2a4dx_anchor_concepts
WHERE EXISTS (
 SELECT 1
 FROM d5ifm2a4dx_anchor_exclude e
 JOIN @cdm_database_schema.concept_ancestor ca
 ON ca.ancestor_concept_id = e.concept_id
 AND d5ifm2a4dx_anchor_concepts.concept_id = ca.descendant_concept_id
 AND (e.include_descendants = 1 OR ca.descendant_concept_id = e.concept_id)
);
DROP TABLE IF EXISTS d5ifm2a4gen_cancer_concepts;
DROP TABLE IF EXISTS d5ifm2a4gen_cancer_concepts;
CREATE TABLE d5ifm2a4gen_cancer_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4gen_cancer_concepts (concept_id)
SELECT DISTINCT ca.ancestor_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN d5ifm2a4dx_anchor_concepts d
 ON ca.descendant_concept_id = d.concept_id
JOIN @cdm_database_schema.concept_ancestor malign
 ON malign.ancestor_concept_id = 443392
 AND malign.descendant_concept_id = ca.ancestor_concept_id
WHERE NOT EXISTS (
 SELECT 1
 FROM d5ifm2a4dx_anchor_concepts dx
 WHERE dx.concept_id = ca.ancestor_concept_id
)
;
DROP TABLE IF EXISTS d5ifm2a4other_dx_ancestor_concepts;
DROP TABLE IF EXISTS d5ifm2a4other_dx_ancestor_concepts;
CREATE TABLE d5ifm2a4other_dx_ancestor_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS ancestor_concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4other_dx_ancestor_concepts (ancestor_concept_id)
VALUES
 (443392) -- Malignant neoplastic disease
;
DROP TABLE IF EXISTS d5ifm2a4other_dx_concepts;
DROP TABLE IF EXISTS d5ifm2a4other_dx_concepts;
CREATE TABLE d5ifm2a4other_dx_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4other_dx_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN d5ifm2a4other_dx_ancestor_concepts a
 ON ca.ancestor_concept_id = a.ancestor_concept_id
LEFT JOIN d5ifm2a4dx_anchor_concepts dx
 ON dx.concept_id = ca.descendant_concept_id
LEFT JOIN d5ifm2a4gen_cancer_concepts gdx
 ON gdx.concept_id = ca.descendant_concept_id
WHERE dx.concept_id IS NULL
 AND gdx.concept_id IS NULL
;
DROP TABLE IF EXISTS d5ifm2a4met_ancestor_concepts;
DROP TABLE IF EXISTS d5ifm2a4met_ancestor_concepts;
CREATE TABLE d5ifm2a4met_ancestor_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS ancestor_concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4met_ancestor_concepts (ancestor_concept_id)
VALUES
 (1633308), -- AJCC/UICC Stage 4
 (1635142), -- AJCC/UICC M1 Category
 (36769180) -- Metastasis
;
DROP TABLE IF EXISTS d5ifm2a4met_concepts;
DROP TABLE IF EXISTS d5ifm2a4met_concepts;
CREATE TABLE d5ifm2a4met_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4met_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN d5ifm2a4met_ancestor_concepts a
 ON ca.ancestor_concept_id = a.ancestor_concept_id
;
DROP TABLE IF EXISTS d5ifm2a4l01_ancestor_concepts;
DROP TABLE IF EXISTS d5ifm2a4l01_ancestor_concepts;
CREATE TABLE d5ifm2a4l01_ancestor_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS ancestor_concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4l01_ancestor_concepts (ancestor_concept_id)
VALUES
 (21601387)
;
DROP TABLE IF EXISTS d5ifm2a4l01_concepts;
DROP TABLE IF EXISTS d5ifm2a4l01_concepts;
CREATE TABLE d5ifm2a4l01_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4l01_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN d5ifm2a4l01_ancestor_concepts a
 ON ca.ancestor_concept_id = a.ancestor_concept_id
;
DROP TABLE IF EXISTS d5ifm2a4dx_events;
DROP TABLE IF EXISTS d5ifm2a4dx_events;
CREATE TABLE d5ifm2a4dx_events  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date,
	CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4dx_events (person_id, event_date, concept_id)
SELECT
 co.person_id,
 co.condition_start_date,
 co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN d5ifm2a4dx_anchor_concepts d
 ON co.condition_concept_id = d.concept_id
;
DROP TABLE IF EXISTS d5ifm2a4anchor_person;
DROP TABLE IF EXISTS d5ifm2a4anchor_person;
CREATE TABLE d5ifm2a4anchor_person  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4anchor_person (person_id)
SELECT DISTINCT person_id
FROM d5ifm2a4dx_events
;
DROP TABLE IF EXISTS d5ifm2a4other_dx_events;
DROP TABLE IF EXISTS d5ifm2a4other_dx_events;
CREATE TABLE d5ifm2a4other_dx_events  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date,
	CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4other_dx_events (person_id, event_date, concept_id)
SELECT
 co.person_id,
 co.condition_start_date,
 co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN d5ifm2a4anchor_person ap
 ON co.person_id = ap.person_id
JOIN d5ifm2a4other_dx_concepts d
 ON co.condition_concept_id = d.concept_id
;
DROP TABLE IF EXISTS d5ifm2a4gen_cancer_events;
DROP TABLE IF EXISTS d5ifm2a4gen_cancer_events;
CREATE TABLE d5ifm2a4gen_cancer_events  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date,
	CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4gen_cancer_events (person_id, event_date, concept_id)
SELECT
 co.person_id,
 co.condition_start_date,
 co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN d5ifm2a4anchor_person ap
 ON co.person_id = ap.person_id
JOIN d5ifm2a4gen_cancer_concepts g
 ON co.condition_concept_id = g.concept_id
;
DROP TABLE IF EXISTS d5ifm2a4met_events;
DROP TABLE IF EXISTS d5ifm2a4met_events;
CREATE TABLE d5ifm2a4met_events  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date,
	CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4met_events (person_id, event_date, concept_id)
SELECT
 m.person_id,
 m.measurement_date,
 m.measurement_concept_id
FROM @cdm_database_schema.measurement m
JOIN d5ifm2a4anchor_person ap
 ON m.person_id = ap.person_id
JOIN d5ifm2a4met_concepts mc
 ON m.measurement_concept_id = mc.concept_id
;
DROP TABLE IF EXISTS d5ifm2a4l01_events;
DROP TABLE IF EXISTS d5ifm2a4l01_events;
CREATE TABLE d5ifm2a4l01_events  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date,
	CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4l01_events (person_id, event_date, concept_id)
SELECT
 de.person_id,
 de.drug_exposure_start_date,
 de.drug_concept_id
FROM @cdm_database_schema.drug_exposure de
JOIN d5ifm2a4anchor_person ap
 ON de.person_id = ap.person_id
JOIN d5ifm2a4l01_concepts l
 ON de.drug_concept_id = l.concept_id
;
DROP TABLE IF EXISTS d5ifm2a4l01_ingredient_events;
DROP TABLE IF EXISTS d5ifm2a4l01_ingredient_events;
CREATE TABLE d5ifm2a4l01_ingredient_events  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date,
	CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO d5ifm2a4l01_ingredient_events (person_id, event_date, concept_id)
SELECT DISTINCT
 de.person_id,
 de.drug_exposure_start_date,
 ca.ancestor_concept_id
FROM @cdm_database_schema.drug_exposure de
JOIN d5ifm2a4anchor_person ap
 ON de.person_id = ap.person_id
JOIN d5ifm2a4l01_concepts l
 ON de.drug_concept_id = l.concept_id
JOIN @cdm_database_schema.concept_ancestor ca
 ON ca.descendant_concept_id = de.drug_concept_id
JOIN @cdm_database_schema.concept ing
 ON ing.concept_id = ca.ancestor_concept_id
 AND ing.concept_class_id = 'Ingredient'
;
DROP TABLE IF EXISTS d5ifm2a4cohort_attrition;
DROP TABLE IF EXISTS d5ifm2a4cohort_attrition;
CREATE TABLE d5ifm2a4cohort_attrition  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS stage,
	CAST(NULL AS int) AS n_patients  WHERE 1 = 0;
INSERT INTO d5ifm2a4cohort_attrition (stage, n_patients)
SELECT 'dx_any', COUNT(DISTINCT person_id) FROM d5ifm2a4dx_events;
DROP TABLE IF EXISTS d5ifm2a4cohort;
DROP TABLE IF EXISTS d5ifm2a4cohort;
CREATE TABLE d5ifm2a4cohort  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS index_date  WHERE 1 = 0;
INSERT INTO d5ifm2a4cohort (person_id, index_date)
SELECT
 dx.person_id,
 MIN(dx.event_date) AS index_date
FROM d5ifm2a4dx_events dx
INNER JOIN @cdm_database_schema.observation_period op
 ON op.person_id = dx.person_id
 AND dx.event_date BETWEEN op.observation_period_start_date
 AND op.observation_period_end_date
GROUP BY dx.person_id
;
INSERT INTO d5ifm2a4cohort_attrition (stage, n_patients)
SELECT 'dx_in_obs', COUNT(*) FROM d5ifm2a4cohort;
DROP TABLE IF EXISTS d5ifm2a4dx_summary;
DROP TABLE IF EXISTS d5ifm2a4dx_summary;
CREATE TABLE d5ifm2a4dx_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS n_dx_records,
	CAST(NULL AS int) AS n_dx_codes  WHERE 1 = 0;
INSERT INTO d5ifm2a4dx_summary (person_id, n_dx_records, n_dx_codes)
SELECT
 e.person_id,
 COUNT(*) AS n_dx_records,
 COUNT(DISTINCT e.concept_id) AS n_dx_codes
FROM d5ifm2a4dx_events e
JOIN d5ifm2a4cohort c
 ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS d5ifm2a4other_dx_summary;
DROP TABLE IF EXISTS d5ifm2a4other_dx_summary;
CREATE TABLE d5ifm2a4other_dx_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS first_other_dx_date,
	CAST(NULL AS int) AS n_other_dx_records,
	CAST(NULL AS int) AS n_other_dx_codes  WHERE 1 = 0;
INSERT INTO d5ifm2a4other_dx_summary (person_id, first_other_dx_date, n_other_dx_records, n_other_dx_codes)
SELECT
 e.person_id,
 MIN(e.event_date) AS first_other_dx_date,
 COUNT(*) AS n_other_dx_records,
 COUNT(DISTINCT e.concept_id) AS n_other_dx_codes
FROM d5ifm2a4other_dx_events e
JOIN d5ifm2a4cohort c
 ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS d5ifm2a4gen_cancer_summary;
DROP TABLE IF EXISTS d5ifm2a4gen_cancer_summary;
CREATE TABLE d5ifm2a4gen_cancer_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS first_gen_cancer_date,
	CAST(NULL AS int) AS n_gen_cancer_records,
	CAST(NULL AS int) AS n_gen_cancer_codes  WHERE 1 = 0;
INSERT INTO d5ifm2a4gen_cancer_summary (person_id, first_gen_cancer_date, n_gen_cancer_records, n_gen_cancer_codes)
SELECT
 e.person_id,
 MIN(e.event_date) AS first_gen_cancer_date,
 COUNT(*) AS n_gen_cancer_records,
 COUNT(DISTINCT e.concept_id) AS n_gen_cancer_codes
FROM d5ifm2a4gen_cancer_events e
JOIN d5ifm2a4cohort c
 ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS d5ifm2a4met_summary;
DROP TABLE IF EXISTS d5ifm2a4met_summary;
CREATE TABLE d5ifm2a4met_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS first_met_date,
	CAST(NULL AS int) AS n_met_records  WHERE 1 = 0;
INSERT INTO d5ifm2a4met_summary (person_id, first_met_date, n_met_records)
SELECT
 e.person_id,
 MIN(e.event_date) AS first_met_date,
 COUNT(*) AS n_met_records
FROM d5ifm2a4met_events e
JOIN d5ifm2a4cohort c
 ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS d5ifm2a4l01_summary;
DROP TABLE IF EXISTS d5ifm2a4l01_summary;
CREATE TABLE d5ifm2a4l01_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS first_l01_date,
	CAST(NULL AS int) AS n_l01_exposures  WHERE 1 = 0;
INSERT INTO d5ifm2a4l01_summary (person_id, first_l01_date, n_l01_exposures)
SELECT
 e.person_id,
 MIN(e.event_date) AS first_l01_date,
 COUNT(*) AS n_l01_exposures
FROM d5ifm2a4l01_events e
JOIN d5ifm2a4cohort c
 ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS d5ifm2a4event_code_counts;
DROP TABLE IF EXISTS d5ifm2a4event_code_counts;
CREATE TABLE d5ifm2a4event_code_counts  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS index) AS --,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS int) AS n_records,
	CAST(NULL AS int) AS n_patients  WHERE 1 = 0;
INSERT INTO d5ifm2a4event_code_counts (anchor_event, event_family, concept_id, n_records, n_patients)
SELECT 'INDEX', 'DX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM d5ifm2a4dx_events
WHERE person_id IN (SELECT person_id FROM d5ifm2a4cohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'ODX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM d5ifm2a4other_dx_events
WHERE person_id IN (SELECT person_id FROM d5ifm2a4cohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'GDX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM d5ifm2a4gen_cancer_events
WHERE person_id IN (SELECT person_id FROM d5ifm2a4cohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'MET', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM d5ifm2a4met_events
WHERE person_id IN (SELECT person_id FROM d5ifm2a4cohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'L01', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM d5ifm2a4l01_ingredient_events
WHERE person_id IN (SELECT person_id FROM d5ifm2a4cohort)
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'DX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM d5ifm2a4dx_events e
JOIN d5ifm2a4met_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'ODX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM d5ifm2a4other_dx_events e
JOIN d5ifm2a4met_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'GDX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM d5ifm2a4gen_cancer_events e
JOIN d5ifm2a4met_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'MET', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM d5ifm2a4met_events e
JOIN d5ifm2a4met_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'L01', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM d5ifm2a4l01_ingredient_events e
JOIN d5ifm2a4met_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
;
DROP TABLE IF EXISTS d5ifm2a4event_code_counts_before_after;
DROP TABLE IF EXISTS d5ifm2a4event_code_counts_before_after;
CREATE TABLE d5ifm2a4event_code_counts_before_after  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS index
) AS --,
	CAST(NULL AS STRING) AS time_relative,
	CAST(NULL AS before) AS --,
	CAST(NULL AS int) AS n_records,
	CAST(NULL AS int) AS n_patients  WHERE 1 = 0;
INSERT INTO d5ifm2a4event_code_counts_before_after (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
SELECT 'INDEX',
 'DX',
 CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END AS time_relative,
 e.concept_id,
 COUNT(*) AS n_records,
 COUNT(DISTINCT e.person_id) AS n_patients
FROM d5ifm2a4dx_events e
JOIN d5ifm2a4cohort c
 ON e.person_id = c.person_id
GROUP BY
 CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id
UNION ALL
SELECT 'INDEX',
 'ODX',
 CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id,
 COUNT(*),
 COUNT(DISTINCT e.person_id)
FROM d5ifm2a4other_dx_events e
JOIN d5ifm2a4cohort c
 ON e.person_id = c.person_id
GROUP BY
 CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id
UNION ALL
SELECT 'INDEX',
 'GDX',
 CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id,
 COUNT(*),
 COUNT(DISTINCT e.person_id)
FROM d5ifm2a4gen_cancer_events e
JOIN d5ifm2a4cohort c
 ON e.person_id = c.person_id
GROUP BY
 CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id
UNION ALL
SELECT 'INDEX',
 'MET',
 CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id,
 COUNT(*),
 COUNT(DISTINCT e.person_id)
FROM d5ifm2a4met_events e
JOIN d5ifm2a4cohort c
 ON e.person_id = c.person_id
GROUP BY
 CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id
UNION ALL
SELECT 'INDEX',
 'L01',
 CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id,
 COUNT(*),
 COUNT(DISTINCT e.person_id)
FROM d5ifm2a4l01_ingredient_events e
JOIN d5ifm2a4cohort c
 ON e.person_id = c.person_id
GROUP BY
 CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id
;
DROP TABLE IF EXISTS d5ifm2a4event_code_counts_before_after_first_met;
DROP TABLE IF EXISTS d5ifm2a4event_code_counts_before_after_first_met;
CREATE TABLE d5ifm2a4event_code_counts_before_after_first_met  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS first_met
) AS --,
	CAST(NULL AS STRING) AS time_relative,
	CAST(NULL AS before) AS --,
	CAST(NULL AS int) AS n_records,
	CAST(NULL AS int) AS n_patients  WHERE 1 = 0;
INSERT INTO d5ifm2a4event_code_counts_before_after_first_met (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
SELECT 'FIRST_MET',
 'DX',
 CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END AS time_relative,
 e.concept_id,
 COUNT(*) AS n_records,
 COUNT(DISTINCT e.person_id) AS n_patients
FROM d5ifm2a4dx_events e
JOIN d5ifm2a4met_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY
 CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id
UNION ALL
SELECT 'FIRST_MET',
 'ODX',
 CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id,
 COUNT(*),
 COUNT(DISTINCT e.person_id)
FROM d5ifm2a4other_dx_events e
JOIN d5ifm2a4met_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY
 CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id
UNION ALL
SELECT 'FIRST_MET',
 'GDX',
 CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id,
 COUNT(*),
 COUNT(DISTINCT e.person_id)
FROM d5ifm2a4gen_cancer_events e
JOIN d5ifm2a4met_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY
 CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id
UNION ALL
SELECT 'FIRST_MET',
 'MET',
 CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id,
 COUNT(*),
 COUNT(DISTINCT e.person_id)
FROM d5ifm2a4met_events e
JOIN d5ifm2a4met_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY
 CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id
UNION ALL
SELECT 'FIRST_MET',
 'L01',
 CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id,
 COUNT(*),
 COUNT(DISTINCT e.person_id)
FROM d5ifm2a4l01_ingredient_events e
JOIN d5ifm2a4met_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY
 CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id
;
DROP TABLE IF EXISTS d5ifm2a4event_code_all_events;
DROP TABLE IF EXISTS d5ifm2a4event_code_all_events;
CREATE TABLE d5ifm2a4event_code_all_events  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS days_diff,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date  WHERE 1 = 0;
INSERT INTO d5ifm2a4event_code_all_events (
 anchor_event, event_family, concept_id, person_id, days_diff, event_date
)
SELECT 'INDEX' AS anchor_event, 'DX' AS event_family, e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date) AS days_diff, e.event_date
FROM d5ifm2a4dx_events e
JOIN d5ifm2a4cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'ODX', e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date), e.event_date
FROM d5ifm2a4other_dx_events e
JOIN d5ifm2a4cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'GDX', e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date), e.event_date
FROM d5ifm2a4gen_cancer_events e
JOIN d5ifm2a4cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'MET', e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date), e.event_date
FROM d5ifm2a4met_events e
JOIN d5ifm2a4cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'L01', e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date), e.event_date
FROM d5ifm2a4l01_ingredient_events e
JOIN d5ifm2a4cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'FIRST_MET', 'DX', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM d5ifm2a4dx_events e
JOIN d5ifm2a4met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'ODX', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM d5ifm2a4other_dx_events e
JOIN d5ifm2a4met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'GDX', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM d5ifm2a4gen_cancer_events e
JOIN d5ifm2a4met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'MET', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM d5ifm2a4met_events e
JOIN d5ifm2a4met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'L01', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM d5ifm2a4l01_ingredient_events e
JOIN d5ifm2a4met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
;
DROP TABLE IF EXISTS d5ifm2a4event_code_patient_chosen_first;
DROP TABLE IF EXISTS d5ifm2a4event_code_patient_chosen_first;
CREATE TABLE d5ifm2a4event_code_patient_chosen_first  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
INSERT INTO d5ifm2a4event_code_patient_chosen_first (anchor_event, event_family, concept_id, person_id, days_diff)
SELECT anchor_event, event_family, concept_id, person_id, days_diff
FROM (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 person_id,
 days_diff,
 ROW_NUMBER() OVER (
 PARTITION BY anchor_event, event_family, concept_id, person_id
 ORDER BY DATEDIFF(DAY, IF(try_cast('1900-01-01'  AS DATE) IS NULL, to_date(cast('1900-01-01'  AS STRING), 'yyyyMMdd'), try_cast('1900-01-01'  AS DATE)), event_date) ASC, event_date ASC
 ) AS rn
 FROM d5ifm2a4event_code_all_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS d5ifm2a4event_code_patient_chosen_closest;
DROP TABLE IF EXISTS d5ifm2a4event_code_patient_chosen_closest;
CREATE TABLE d5ifm2a4event_code_patient_chosen_closest  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
INSERT INTO d5ifm2a4event_code_patient_chosen_closest (anchor_event, event_family, concept_id, person_id, days_diff)
SELECT anchor_event, event_family, concept_id, person_id, days_diff
FROM (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 person_id,
 days_diff,
 ROW_NUMBER() OVER (
 PARTITION BY anchor_event, event_family, concept_id, person_id
 ORDER BY ABS(days_diff) ASC, event_date ASC
 ) AS rn
 FROM d5ifm2a4event_code_all_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS d5ifm2a4event_code_timing_summary;
DROP TABLE IF EXISTS d5ifm2a4event_code_timing_summary;
CREATE TABLE d5ifm2a4event_code_timing_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS int) AS n_patients_with_code_timing,
	CAST(NULL AS DOUBLE) AS lq_days_first,
	CAST(NULL AS DOUBLE) AS median_days_first,
	CAST(NULL AS DOUBLE) AS uq_days_first,
	CAST(NULL AS DOUBLE) AS lq_days_closest,
	CAST(NULL AS DOUBLE) AS median_days_closest,
	CAST(NULL AS DOUBLE) AS uq_days_closest  WHERE 1 = 0;
INSERT INTO d5ifm2a4event_code_timing_summary (
 anchor_event,
 event_family,
 concept_id,
 n_patients_with_code_timing,
 lq_days_first,
 median_days_first,
 uq_days_first,
 lq_days_closest,
 median_days_closest,
 uq_days_closest
)
SELECT
 f.anchor_event,
 f.event_family,
 f.concept_id,
 f.n_patients_with_code_timing,
 f.lq_days_first,
 f.median_days_first,
 f.uq_days_first,
 k.lq_days_closest,
 k.median_days_closest,
 k.uq_days_closest
FROM (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 COUNT(*) AS n_patients_with_code_timing,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS lq_days_first,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS median_days_first,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS uq_days_first
 FROM (
 SELECT anchor_event, event_family, concept_id, days_diff,
 ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, concept_id ORDER BY days_diff) AS rn,
 COUNT(*) OVER (PARTITION BY anchor_event, event_family, concept_id) AS cnt
 FROM d5ifm2a4event_code_patient_chosen_first
 ) x
 GROUP BY anchor_event, event_family, concept_id
) f
INNER JOIN (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS lq_days_closest,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS median_days_closest,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS uq_days_closest
 FROM (
 SELECT anchor_event, event_family, concept_id, days_diff,
 ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, concept_id ORDER BY days_diff) AS rn,
 COUNT(*) OVER (PARTITION BY anchor_event, event_family, concept_id) AS cnt
 FROM d5ifm2a4event_code_patient_chosen_closest
 ) x
 GROUP BY anchor_event, event_family, concept_id
) k
 ON f.anchor_event = k.anchor_event
 AND f.event_family = k.event_family
 AND f.concept_id = k.concept_id
;
DROP TABLE IF EXISTS d5ifm2a4event_code_ba_events;
DROP TABLE IF EXISTS d5ifm2a4event_code_ba_events;
CREATE TABLE d5ifm2a4event_code_ba_events  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS STRING) AS time_relative,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS days_diff,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date  WHERE 1 = 0;
INSERT INTO d5ifm2a4event_code_ba_events (
 anchor_event, event_family, time_relative, concept_id, person_id, days_diff, event_date
)
SELECT
 anchor_event,
 event_family,
 CASE WHEN days_diff < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 concept_id,
 person_id,
 days_diff,
 event_date
FROM d5ifm2a4event_code_all_events
;
DROP TABLE IF EXISTS d5ifm2a4event_code_patient_chosen_before_after_first;
DROP TABLE IF EXISTS d5ifm2a4event_code_patient_chosen_before_after_first;
CREATE TABLE d5ifm2a4event_code_patient_chosen_before_after_first  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS STRING) AS time_relative,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
INSERT INTO d5ifm2a4event_code_patient_chosen_before_after_first (
 anchor_event, event_family, time_relative, concept_id, person_id, days_diff
)
SELECT anchor_event, event_family, time_relative, concept_id, person_id, days_diff
FROM (
 SELECT
 anchor_event,
 event_family,
 time_relative,
 concept_id,
 person_id,
 days_diff,
 ROW_NUMBER() OVER (
 PARTITION BY anchor_event, event_family, time_relative, concept_id, person_id
 ORDER BY DATEDIFF(DAY, IF(try_cast('1900-01-01'  AS DATE) IS NULL, to_date(cast('1900-01-01'  AS STRING), 'yyyyMMdd'), try_cast('1900-01-01'  AS DATE)), event_date) ASC, event_date ASC
 ) AS rn
 FROM d5ifm2a4event_code_ba_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS d5ifm2a4event_code_patient_chosen_before_after_closest;
DROP TABLE IF EXISTS d5ifm2a4event_code_patient_chosen_before_after_closest;
CREATE TABLE d5ifm2a4event_code_patient_chosen_before_after_closest  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS STRING) AS time_relative,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
INSERT INTO d5ifm2a4event_code_patient_chosen_before_after_closest (
 anchor_event, event_family, time_relative, concept_id, person_id, days_diff
)
SELECT anchor_event, event_family, time_relative, concept_id, person_id, days_diff
FROM (
 SELECT
 anchor_event,
 event_family,
 time_relative,
 concept_id,
 person_id,
 days_diff,
 ROW_NUMBER() OVER (
 PARTITION BY anchor_event, event_family, time_relative, concept_id, person_id
 ORDER BY ABS(days_diff) ASC, event_date ASC
 ) AS rn
 FROM d5ifm2a4event_code_ba_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS d5ifm2a4event_code_timing_before_after_summary;
DROP TABLE IF EXISTS d5ifm2a4event_code_timing_before_after_summary;
CREATE TABLE d5ifm2a4event_code_timing_before_after_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS STRING) AS time_relative,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS int) AS n_patients_with_code_timing,
	CAST(NULL AS DOUBLE) AS lq_days_first,
	CAST(NULL AS DOUBLE) AS median_days_first,
	CAST(NULL AS DOUBLE) AS uq_days_first,
	CAST(NULL AS DOUBLE) AS lq_days_closest,
	CAST(NULL AS DOUBLE) AS median_days_closest,
	CAST(NULL AS DOUBLE) AS uq_days_closest  WHERE 1 = 0;
INSERT INTO d5ifm2a4event_code_timing_before_after_summary (
 anchor_event,
 event_family,
 time_relative,
 concept_id,
 n_patients_with_code_timing,
 lq_days_first,
 median_days_first,
 uq_days_first,
 lq_days_closest,
 median_days_closest,
 uq_days_closest
)
SELECT
 f.anchor_event,
 f.event_family,
 f.time_relative,
 f.concept_id,
 f.n_patients_with_code_timing,
 f.lq_days_first,
 f.median_days_first,
 f.uq_days_first,
 k.lq_days_closest,
 k.median_days_closest,
 k.uq_days_closest
FROM (
 SELECT
 anchor_event,
 event_family,
 time_relative,
 concept_id,
 COUNT(*) AS n_patients_with_code_timing,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS lq_days_first,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS median_days_first,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS uq_days_first
 FROM (
 SELECT anchor_event, event_family, time_relative, concept_id, days_diff,
 ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, time_relative, concept_id ORDER BY days_diff) AS rn,
 COUNT(*) OVER (PARTITION BY anchor_event, event_family, time_relative, concept_id) AS cnt
 FROM d5ifm2a4event_code_patient_chosen_before_after_first
 ) x
 GROUP BY anchor_event, event_family, time_relative, concept_id
) f
INNER JOIN (
 SELECT
 anchor_event,
 event_family,
 time_relative,
 concept_id,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS lq_days_closest,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS median_days_closest,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS uq_days_closest
 FROM (
 SELECT anchor_event, event_family, time_relative, concept_id, days_diff,
 ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, time_relative, concept_id ORDER BY days_diff) AS rn,
 COUNT(*) OVER (PARTITION BY anchor_event, event_family, time_relative, concept_id) AS cnt
 FROM d5ifm2a4event_code_patient_chosen_before_after_closest
 ) x
 GROUP BY anchor_event, event_family, time_relative, concept_id
) k
 ON f.anchor_event = k.anchor_event
 AND f.event_family = k.event_family
 AND f.time_relative = k.time_relative
 AND f.concept_id = k.concept_id
;
DROP TABLE IF EXISTS d5ifm2a4patient_char;
DROP TABLE IF EXISTS d5ifm2a4patient_char;
CREATE TABLE d5ifm2a4patient_char  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS index_date,
	CAST(NULL AS int) AS n_dx_records,
	CAST(NULL AS int) AS n_dx_codes,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS first_other_dx_date,
	CAST(NULL AS int) AS n_other_dx_records,
	CAST(NULL AS int) AS n_other_dx_codes,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS first_gen_cancer_date,
	CAST(NULL AS int) AS n_gen_cancer_records,
	CAST(NULL AS int) AS n_gen_cancer_codes,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS first_met_date,
	CAST(NULL AS int) AS n_met_records,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS first_l01_date,
	CAST(NULL AS int) AS n_l01_exposures,
	CAST(NULL AS int) AS days_dx_to_met,
	CAST(NULL AS int) AS days_dx_to_l01,
	CAST(NULL AS int) AS days_dx_to_other_dx,
	CAST(NULL AS int) AS days_dx_to_gen_cancer,
	CAST(NULL AS int) AS days_met_to_l01  WHERE 1 = 0;
INSERT INTO d5ifm2a4patient_char (
 person_id,
 index_date,
 n_dx_records,
 n_dx_codes,
 first_other_dx_date,
 n_other_dx_records,
 n_other_dx_codes,
 first_gen_cancer_date,
 n_gen_cancer_records,
 n_gen_cancer_codes,
 first_met_date,
 n_met_records,
 first_l01_date,
 n_l01_exposures,
 days_dx_to_met,
 days_dx_to_l01,
 days_dx_to_other_dx,
 days_dx_to_gen_cancer,
 days_met_to_l01
)
SELECT
 c.person_id,
 c.index_date,
 COALESCE(dx.n_dx_records, 0),
 COALESCE(dx.n_dx_codes, 0),
 odx.first_other_dx_date,
 COALESCE(odx.n_other_dx_records, 0),
 COALESCE(odx.n_other_dx_codes, 0),
 gdx.first_gen_cancer_date,
 COALESCE(gdx.n_gen_cancer_records, 0),
 COALESCE(gdx.n_gen_cancer_codes, 0),
 mt.first_met_date,
 COALESCE(mt.n_met_records, 0),
 l01.first_l01_date,
 COALESCE(l01.n_l01_exposures, 0),
 CASE WHEN mt.first_met_date IS NOT NULL THEN DATEDIFF(DAY, c.index_date, mt.first_met_date) END AS days_dx_to_met,
 CASE WHEN l01.first_l01_date IS NOT NULL THEN DATEDIFF(DAY, c.index_date, l01.first_l01_date) END AS days_dx_to_l01,
 CASE WHEN odx.first_other_dx_date IS NOT NULL THEN DATEDIFF(DAY, c.index_date, odx.first_other_dx_date) END AS days_dx_to_other_dx,
 CASE WHEN gdx.first_gen_cancer_date IS NOT NULL THEN DATEDIFF(DAY, c.index_date, gdx.first_gen_cancer_date) END AS days_dx_to_gen_cancer,
 CASE WHEN mt.first_met_date IS NOT NULL AND l01.first_l01_date IS NOT NULL THEN DATEDIFF(DAY, mt.first_met_date, l01.first_l01_date) END AS days_met_to_l01
FROM d5ifm2a4cohort c
LEFT JOIN d5ifm2a4dx_summary dx
 ON c.person_id = dx.person_id
LEFT JOIN d5ifm2a4other_dx_summary odx
 ON c.person_id = odx.person_id
LEFT JOIN d5ifm2a4gen_cancer_summary gdx
 ON c.person_id = gdx.person_id
LEFT JOIN d5ifm2a4met_summary mt
 ON c.person_id = mt.person_id
LEFT JOIN d5ifm2a4l01_summary l01
 ON c.person_id = l01.person_id
;
DROP TABLE IF EXISTS d5ifm2a4patient_timing_pairs;
DROP TABLE IF EXISTS d5ifm2a4patient_timing_pairs;
CREATE TABLE d5ifm2a4patient_timing_pairs  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS STRING) AS from_event,
	CAST(NULL AS STRING) AS to_event,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
WITH events  AS (SELECT person_id,  CAST('DX' as STRING) AS event_name, index_date AS event_date FROM d5ifm2a4patient_char
 UNION ALL
 SELECT person_id, 'ODX', first_other_dx_date FROM d5ifm2a4patient_char
 UNION ALL
 SELECT person_id, 'GDX', first_gen_cancer_date FROM d5ifm2a4patient_char
 UNION ALL
 SELECT person_id, 'MET', first_met_date FROM d5ifm2a4patient_char
 UNION ALL
 SELECT person_id, 'L01', first_l01_date FROM d5ifm2a4patient_char
)
INSERT INTO d5ifm2a4patient_timing_pairs (person_id, from_event, to_event, days_diff)
SELECT
 e1.person_id,
 e1.event_name AS from_event,
 e2.event_name AS to_event,
 DATEDIFF(DAY, e1.event_date, e2.event_date) AS days_diff
FROM events e1
JOIN events e2
 ON e1.person_id = e2.person_id
 AND e1.event_name <> e2.event_name
WHERE e1.event_date IS NOT NULL
 AND e2.event_date IS NOT NULL
;
DROP TABLE IF EXISTS d5ifm2a4timing_pair_summary;
DROP TABLE IF EXISTS d5ifm2a4timing_pair_summary;
CREATE TABLE d5ifm2a4timing_pair_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS from_event,
	CAST(NULL AS STRING) AS to_event,
	CAST(NULL AS int) AS n_patients_with_pair,
	CAST(NULL AS DOUBLE) AS p05_days,
	CAST(NULL AS DOUBLE) AS p10_days,
	CAST(NULL AS DOUBLE) AS p20_days,
	CAST(NULL AS DOUBLE) AS p25_days,
	CAST(NULL AS DOUBLE) AS p30_days,
	CAST(NULL AS DOUBLE) AS p40_days,
	CAST(NULL AS DOUBLE) AS p50_days,
	CAST(NULL AS DOUBLE) AS p60_days,
	CAST(NULL AS DOUBLE) AS p70_days,
	CAST(NULL AS DOUBLE) AS p75_days,
	CAST(NULL AS DOUBLE) AS p80_days,
	CAST(NULL AS DOUBLE) AS p90_days,
	CAST(NULL AS DOUBLE) AS p95_days  WHERE 1 = 0;
INSERT INTO d5ifm2a4timing_pair_summary (
 from_event,
 to_event,
 n_patients_with_pair,
 p05_days,
 p10_days,
 p20_days,
 p25_days,
 p30_days,
 p40_days,
 p50_days,
 p60_days,
 p70_days,
 p75_days,
 p80_days,
 p90_days,
 p95_days
)
SELECT
 from_event,
 to_event,
 COUNT(*) AS n_patients_with_pair,
 MIN(CASE WHEN 20.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p05_days,
 MIN(CASE WHEN 10.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p10_days,
 MIN(CASE WHEN 5.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p20_days,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p25_days,
 MIN(CASE WHEN 10.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p30_days,
 MIN(CASE WHEN 5.0 * rn >= 2 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p40_days,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p50_days,
 MIN(CASE WHEN 5.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p60_days,
 MIN(CASE WHEN 10.0 * rn >= 7 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p70_days,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p75_days,
 MIN(CASE WHEN 5.0 * rn >= 4 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p80_days,
 MIN(CASE WHEN 10.0 * rn >= 9 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p90_days,
 MIN(CASE WHEN 20.0 * rn >= 19 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p95_days
FROM (
 SELECT from_event, to_event, days_diff,
 ROW_NUMBER() OVER (PARTITION BY from_event, to_event ORDER BY days_diff) AS rn,
 COUNT(*) OVER (PARTITION BY from_event, to_event) AS cnt
 FROM d5ifm2a4patient_timing_pairs
) x
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS d5ifm2a4all_events_for_pairs;
DROP TABLE IF EXISTS d5ifm2a4all_events_for_pairs;
CREATE TABLE d5ifm2a4all_events_for_pairs  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS STRING) AS event_family,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date  WHERE 1 = 0;
INSERT INTO d5ifm2a4all_events_for_pairs (person_id, event_family, event_date)
SELECT person_id, 'DX', event_date FROM d5ifm2a4dx_events
UNION ALL
SELECT person_id, 'ODX', event_date FROM d5ifm2a4other_dx_events
UNION ALL
SELECT person_id, 'GDX', event_date FROM d5ifm2a4gen_cancer_events
UNION ALL
SELECT person_id, 'MET', event_date FROM d5ifm2a4met_events
UNION ALL
SELECT person_id, 'L01', event_date FROM d5ifm2a4l01_events
;
DROP TABLE IF EXISTS d5ifm2a4first_event_dates;
DROP TABLE IF EXISTS d5ifm2a4first_event_dates;
CREATE TABLE d5ifm2a4first_event_dates  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS STRING) AS from_event,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS from_first_date  WHERE 1 = 0;
INSERT INTO d5ifm2a4first_event_dates (person_id, from_event, from_first_date)
SELECT person_id, 'DX', index_date FROM d5ifm2a4patient_char
UNION ALL
SELECT person_id, 'ODX', first_other_dx_date FROM d5ifm2a4patient_char WHERE first_other_dx_date IS NOT NULL
UNION ALL
SELECT person_id, 'GDX', first_gen_cancer_date FROM d5ifm2a4patient_char WHERE first_gen_cancer_date IS NOT NULL
UNION ALL
SELECT person_id, 'MET', first_met_date FROM d5ifm2a4patient_char WHERE first_met_date IS NOT NULL
UNION ALL
SELECT person_id, 'L01', first_l01_date FROM d5ifm2a4patient_char WHERE first_l01_date IS NOT NULL
;
DROP TABLE IF EXISTS d5ifm2a4patient_timing_pairs_first_to_closest;
DROP TABLE IF EXISTS d5ifm2a4patient_timing_pairs_first_to_closest;
CREATE TABLE d5ifm2a4patient_timing_pairs_first_to_closest  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS STRING) AS from_event,
	CAST(NULL AS STRING) AS to_event,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
WITH ranked AS (
 SELECT
 f.person_id,
 f.from_event,
 a.event_family AS to_event,
 DATEDIFF(DAY, f.from_first_date, a.event_date) AS days_diff,
 ROW_NUMBER() OVER (
 PARTITION BY f.person_id, f.from_event, a.event_family
 ORDER BY ABS(DATEDIFF(DAY, f.from_first_date, a.event_date)), a.event_date
 ) AS rn
 FROM d5ifm2a4first_event_dates f
 JOIN d5ifm2a4all_events_for_pairs a
 ON f.person_id = a.person_id
 AND f.from_event <> a.event_family
)
INSERT INTO d5ifm2a4patient_timing_pairs_first_to_closest (person_id, from_event, to_event, days_diff)
SELECT
 person_id,
 from_event,
 to_event,
 days_diff
FROM ranked
WHERE rn = 1
;
DROP TABLE IF EXISTS d5ifm2a4timing_pair_summary_first_to_closest;
DROP TABLE IF EXISTS d5ifm2a4timing_pair_summary_first_to_closest;
CREATE TABLE d5ifm2a4timing_pair_summary_first_to_closest  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS from_event,
	CAST(NULL AS STRING) AS to_event,
	CAST(NULL AS int) AS n_patients_with_pair,
	CAST(NULL AS DOUBLE) AS p05_days,
	CAST(NULL AS DOUBLE) AS p10_days,
	CAST(NULL AS DOUBLE) AS p20_days,
	CAST(NULL AS DOUBLE) AS p25_days,
	CAST(NULL AS DOUBLE) AS p30_days,
	CAST(NULL AS DOUBLE) AS p40_days,
	CAST(NULL AS DOUBLE) AS p50_days,
	CAST(NULL AS DOUBLE) AS p60_days,
	CAST(NULL AS DOUBLE) AS p70_days,
	CAST(NULL AS DOUBLE) AS p75_days,
	CAST(NULL AS DOUBLE) AS p80_days,
	CAST(NULL AS DOUBLE) AS p90_days,
	CAST(NULL AS DOUBLE) AS p95_days  WHERE 1 = 0;
INSERT INTO d5ifm2a4timing_pair_summary_first_to_closest (
 from_event,
 to_event,
 n_patients_with_pair,
 p05_days,
 p10_days,
 p20_days,
 p25_days,
 p30_days,
 p40_days,
 p50_days,
 p60_days,
 p70_days,
 p75_days,
 p80_days,
 p90_days,
 p95_days
)
SELECT
 from_event,
 to_event,
 COUNT(*) AS n_patients_with_pair,
 MIN(CASE WHEN 20.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p05_days,
 MIN(CASE WHEN 10.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p10_days,
 MIN(CASE WHEN 5.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p20_days,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p25_days,
 MIN(CASE WHEN 10.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p30_days,
 MIN(CASE WHEN 5.0 * rn >= 2 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p40_days,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p50_days,
 MIN(CASE WHEN 5.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p60_days,
 MIN(CASE WHEN 10.0 * rn >= 7 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p70_days,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p75_days,
 MIN(CASE WHEN 5.0 * rn >= 4 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p80_days,
 MIN(CASE WHEN 10.0 * rn >= 9 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p90_days,
 MIN(CASE WHEN 20.0 * rn >= 19 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p95_days
FROM (
 SELECT from_event, to_event, days_diff,
 ROW_NUMBER() OVER (PARTITION BY from_event, to_event ORDER BY days_diff) AS rn,
 COUNT(*) OVER (PARTITION BY from_event, to_event) AS cnt
 FROM d5ifm2a4patient_timing_pairs_first_to_closest
) x
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS d5ifm2a4patient_timing_pairs_first_to_closest_before;
DROP TABLE IF EXISTS d5ifm2a4patient_timing_pairs_first_to_closest_before;
CREATE TABLE d5ifm2a4patient_timing_pairs_first_to_closest_before  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS STRING) AS from_event,
	CAST(NULL AS STRING) AS to_event,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
WITH ranked_before AS (
 SELECT
 f.person_id,
 f.from_event,
 a.event_family AS to_event,
 DATEDIFF(DAY, f.from_first_date, a.event_date) AS days_diff,
 ROW_NUMBER() OVER (
 PARTITION BY f.person_id, f.from_event, a.event_family
 ORDER BY ABS(DATEDIFF(DAY, f.from_first_date, a.event_date)), a.event_date DESC
 ) AS rn
 FROM d5ifm2a4first_event_dates f
 JOIN d5ifm2a4all_events_for_pairs a
 ON f.person_id = a.person_id
 AND f.from_event <> a.event_family
 WHERE DATEDIFF(DAY, f.from_first_date, a.event_date) < 0
)
INSERT INTO d5ifm2a4patient_timing_pairs_first_to_closest_before (person_id, from_event, to_event, days_diff)
SELECT
 person_id,
 from_event,
 to_event,
 days_diff
FROM ranked_before
WHERE rn = 1
;
DROP TABLE IF EXISTS d5ifm2a4timing_pair_summary_first_to_closest_before;
DROP TABLE IF EXISTS d5ifm2a4timing_pair_summary_first_to_closest_before;
CREATE TABLE d5ifm2a4timing_pair_summary_first_to_closest_before  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS from_event,
	CAST(NULL AS STRING) AS to_event,
	CAST(NULL AS int) AS n_patients_with_pair,
	CAST(NULL AS DOUBLE) AS p05_days,
	CAST(NULL AS DOUBLE) AS p10_days,
	CAST(NULL AS DOUBLE) AS p20_days,
	CAST(NULL AS DOUBLE) AS p25_days,
	CAST(NULL AS DOUBLE) AS p30_days,
	CAST(NULL AS DOUBLE) AS p40_days,
	CAST(NULL AS DOUBLE) AS p50_days,
	CAST(NULL AS DOUBLE) AS p60_days,
	CAST(NULL AS DOUBLE) AS p70_days,
	CAST(NULL AS DOUBLE) AS p75_days,
	CAST(NULL AS DOUBLE) AS p80_days,
	CAST(NULL AS DOUBLE) AS p90_days,
	CAST(NULL AS DOUBLE) AS p95_days  WHERE 1 = 0;
INSERT INTO d5ifm2a4timing_pair_summary_first_to_closest_before (
 from_event,
 to_event,
 n_patients_with_pair,
 p05_days,
 p10_days,
 p20_days,
 p25_days,
 p30_days,
 p40_days,
 p50_days,
 p60_days,
 p70_days,
 p75_days,
 p80_days,
 p90_days,
 p95_days
)
SELECT
 from_event,
 to_event,
 COUNT(*) AS n_patients_with_pair,
 MIN(CASE WHEN 20.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p05_days,
 MIN(CASE WHEN 10.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p10_days,
 MIN(CASE WHEN 5.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p20_days,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p25_days,
 MIN(CASE WHEN 10.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p30_days,
 MIN(CASE WHEN 5.0 * rn >= 2 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p40_days,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p50_days,
 MIN(CASE WHEN 5.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p60_days,
 MIN(CASE WHEN 10.0 * rn >= 7 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p70_days,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p75_days,
 MIN(CASE WHEN 5.0 * rn >= 4 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p80_days,
 MIN(CASE WHEN 10.0 * rn >= 9 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p90_days,
 MIN(CASE WHEN 20.0 * rn >= 19 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p95_days
FROM (
 SELECT from_event, to_event, days_diff,
 ROW_NUMBER() OVER (PARTITION BY from_event, to_event ORDER BY days_diff) AS rn,
 COUNT(*) OVER (PARTITION BY from_event, to_event) AS cnt
 FROM d5ifm2a4patient_timing_pairs_first_to_closest_before
) x
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS d5ifm2a4patient_timing_pairs_first_to_closest_after;
DROP TABLE IF EXISTS d5ifm2a4patient_timing_pairs_first_to_closest_after;
CREATE TABLE d5ifm2a4patient_timing_pairs_first_to_closest_after  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS STRING) AS from_event,
	CAST(NULL AS STRING) AS to_event,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
WITH ranked_after AS (
 SELECT
 f.person_id,
 f.from_event,
 a.event_family AS to_event,
 DATEDIFF(DAY, f.from_first_date, a.event_date) AS days_diff,
 ROW_NUMBER() OVER (
 PARTITION BY f.person_id, f.from_event, a.event_family
 ORDER BY DATEDIFF(DAY, f.from_first_date, a.event_date), a.event_date
 ) AS rn
 FROM d5ifm2a4first_event_dates f
 JOIN d5ifm2a4all_events_for_pairs a
 ON f.person_id = a.person_id
 AND f.from_event <> a.event_family
 WHERE DATEDIFF(DAY, f.from_first_date, a.event_date) >= 0
)
INSERT INTO d5ifm2a4patient_timing_pairs_first_to_closest_after (person_id, from_event, to_event, days_diff)
SELECT
 person_id,
 from_event,
 to_event,
 days_diff
FROM ranked_after
WHERE rn = 1
;
DROP TABLE IF EXISTS d5ifm2a4timing_pair_summary_first_to_closest_after;
DROP TABLE IF EXISTS d5ifm2a4timing_pair_summary_first_to_closest_after;
CREATE TABLE d5ifm2a4timing_pair_summary_first_to_closest_after  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS from_event,
	CAST(NULL AS STRING) AS to_event,
	CAST(NULL AS int) AS n_patients_with_pair,
	CAST(NULL AS DOUBLE) AS p05_days,
	CAST(NULL AS DOUBLE) AS p10_days,
	CAST(NULL AS DOUBLE) AS p20_days,
	CAST(NULL AS DOUBLE) AS p25_days,
	CAST(NULL AS DOUBLE) AS p30_days,
	CAST(NULL AS DOUBLE) AS p40_days,
	CAST(NULL AS DOUBLE) AS p50_days,
	CAST(NULL AS DOUBLE) AS p60_days,
	CAST(NULL AS DOUBLE) AS p70_days,
	CAST(NULL AS DOUBLE) AS p75_days,
	CAST(NULL AS DOUBLE) AS p80_days,
	CAST(NULL AS DOUBLE) AS p90_days,
	CAST(NULL AS DOUBLE) AS p95_days  WHERE 1 = 0;
INSERT INTO d5ifm2a4timing_pair_summary_first_to_closest_after (
 from_event,
 to_event,
 n_patients_with_pair,
 p05_days,
 p10_days,
 p20_days,
 p25_days,
 p30_days,
 p40_days,
 p50_days,
 p60_days,
 p70_days,
 p75_days,
 p80_days,
 p90_days,
 p95_days
)
SELECT
 from_event,
 to_event,
 COUNT(*) AS n_patients_with_pair,
 MIN(CASE WHEN 20.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p05_days,
 MIN(CASE WHEN 10.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p10_days,
 MIN(CASE WHEN 5.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p20_days,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p25_days,
 MIN(CASE WHEN 10.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p30_days,
 MIN(CASE WHEN 5.0 * rn >= 2 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p40_days,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p50_days,
 MIN(CASE WHEN 5.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p60_days,
 MIN(CASE WHEN 10.0 * rn >= 7 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p70_days,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p75_days,
 MIN(CASE WHEN 5.0 * rn >= 4 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p80_days,
 MIN(CASE WHEN 10.0 * rn >= 9 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p90_days,
 MIN(CASE WHEN 20.0 * rn >= 19 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p95_days
FROM (
 SELECT from_event, to_event, days_diff,
 ROW_NUMBER() OVER (PARTITION BY from_event, to_event ORDER BY days_diff) AS rn,
 COUNT(*) OVER (PARTITION BY from_event, to_event) AS cnt
 FROM d5ifm2a4patient_timing_pairs_first_to_closest_after
) x
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS d5ifm2a4event_presence;
DROP TABLE IF EXISTS d5ifm2a4event_presence;
CREATE TABLE d5ifm2a4event_presence  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS has_dx,
	CAST(NULL AS int) AS has_odx,
	CAST(NULL AS int) AS has_gdx,
	CAST(NULL AS int) AS has_met,
	CAST(NULL AS int) AS has_l01  WHERE 1 = 0;
INSERT INTO d5ifm2a4event_presence (
 person_id, has_dx, has_odx, has_gdx, has_met, has_l01
)
SELECT
 person_id,
 1,
 CASE WHEN first_other_dx_date IS NOT NULL THEN 1 ELSE 0 END,
 CASE WHEN first_gen_cancer_date IS NOT NULL THEN 1 ELSE 0 END,
 CASE WHEN first_met_date IS NOT NULL THEN 1 ELSE 0 END,
 CASE WHEN first_l01_date IS NOT NULL THEN 1 ELSE 0 END
FROM d5ifm2a4patient_char
;
DROP TABLE IF EXISTS d5ifm2a4death_obs_status;
DROP TABLE IF EXISTS d5ifm2a4death_obs_status;
CREATE TABLE d5ifm2a4death_obs_status  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS death_date,
	CAST(NULL AS smallint) AS death_in_obs  WHERE 1 = 0;
INSERT INTO d5ifm2a4death_obs_status (person_id, death_date, death_in_obs)
SELECT
 d.person_id,
 d.death_date,
 CASE WHEN EXISTS (
 SELECT 1
 FROM @cdm_database_schema.observation_period op
 WHERE op.person_id = d.person_id
 AND d.death_date BETWEEN op.observation_period_start_date
 AND op.observation_period_end_date
 ) THEN 1 ELSE 0 END
FROM (
 SELECT person_id, MIN(death_date) AS death_date
 FROM @cdm_database_schema.death
 GROUP BY person_id
) d
WHERE d.person_id IN (SELECT person_id FROM d5ifm2a4cohort)
;
DROP TABLE IF EXISTS d5ifm2a4death_index_long;
DROP TABLE IF EXISTS d5ifm2a4death_index_long;
CREATE TABLE d5ifm2a4death_index_long  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS int) AS days_to_death  WHERE 1 = 0;
INSERT INTO d5ifm2a4death_index_long (prevalence_year, days_to_death)
SELECT 'OVERALL', DATEDIFF(DAY, c.index_date, dos.death_date)
FROM d5ifm2a4cohort c
INNER JOIN d5ifm2a4death_obs_status dos ON dos.person_id = c.person_id
WHERE dos.death_date >= c.index_date
UNION ALL
SELECT CAST(YEAR(c.index_date) AS STRING), DATEDIFF(DAY, c.index_date, dos.death_date)
FROM d5ifm2a4cohort c
INNER JOIN d5ifm2a4death_obs_status dos ON dos.person_id = c.person_id
WHERE dos.death_date >= c.index_date
;
DROP TABLE IF EXISTS d5ifm2a4death_first_met_long;
DROP TABLE IF EXISTS d5ifm2a4death_first_met_long;
CREATE TABLE d5ifm2a4death_first_met_long  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS int) AS days_to_death  WHERE 1 = 0;
INSERT INTO d5ifm2a4death_first_met_long (prevalence_year, days_to_death)
SELECT 'OVERALL', DATEDIFF(DAY, ms.first_met_date, dos.death_date)
FROM d5ifm2a4cohort c
INNER JOIN d5ifm2a4met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN d5ifm2a4death_obs_status dos ON dos.person_id = c.person_id
WHERE dos.death_date >= ms.first_met_date
UNION ALL
SELECT CAST(YEAR(c.index_date) AS STRING), DATEDIFF(DAY, ms.first_met_date, dos.death_date)
FROM d5ifm2a4cohort c
INNER JOIN d5ifm2a4met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN d5ifm2a4death_obs_status dos ON dos.person_id = c.person_id
WHERE dos.death_date >= ms.first_met_date
;
DROP TABLE IF EXISTS d5ifm2a4death_stratum_counts;
DROP TABLE IF EXISTS d5ifm2a4death_stratum_counts;
CREATE TABLE d5ifm2a4death_stratum_counts  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS int) AS n_patients,
	CAST(NULL AS int) AS n_deaths,
	CAST(NULL AS int) AS n_deaths_in_obs,
	CAST(NULL AS int) AS n_deaths_out_obs  WHERE 1 = 0;
INSERT INTO d5ifm2a4death_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths, n_deaths_in_obs, n_deaths_out_obs)
SELECT
 CASE
 WHEN GROUPING(YEAR(c.index_date)) = 1 THEN 'OVERALL'
 ELSE CAST(YEAR(c.index_date) AS STRING)
 END,
 'INDEX',
 COUNT(*),
 SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= c.index_date THEN 1 ELSE 0 END),
 SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= c.index_date AND dos.death_in_obs = 1 THEN 1 ELSE 0 END),
 SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= c.index_date AND dos.death_in_obs = 0 THEN 1 ELSE 0 END)
FROM d5ifm2a4cohort c
LEFT JOIN d5ifm2a4death_obs_status dos ON dos.person_id = c.person_id
GROUP BY GROUPING SETS ((), (YEAR(c.index_date)))
;
INSERT INTO d5ifm2a4death_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths, n_deaths_in_obs, n_deaths_out_obs)
SELECT
 CASE
 WHEN GROUPING(YEAR(c.index_date)) = 1 THEN 'OVERALL'
 ELSE CAST(YEAR(c.index_date) AS STRING)
 END,
 'FIRST_MET',
 COUNT(*),
 SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= ms.first_met_date THEN 1 ELSE 0 END),
 SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= ms.first_met_date AND dos.death_in_obs = 1 THEN 1 ELSE 0 END),
 SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= ms.first_met_date AND dos.death_in_obs = 0 THEN 1 ELSE 0 END)
FROM d5ifm2a4cohort c
INNER JOIN d5ifm2a4met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
LEFT JOIN d5ifm2a4death_obs_status dos ON dos.person_id = c.person_id
GROUP BY GROUPING SETS ((), (YEAR(c.index_date)))
;
DROP TABLE IF EXISTS d5ifm2a4death_timing_long;
DROP TABLE IF EXISTS d5ifm2a4death_timing_long;
CREATE TABLE d5ifm2a4death_timing_long  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS int) AS days_to_death  WHERE 1 = 0;
INSERT INTO d5ifm2a4death_timing_long (prevalence_year, anchor_event, days_to_death)
SELECT prevalence_year, 'INDEX', days_to_death FROM d5ifm2a4death_index_long
UNION ALL
SELECT prevalence_year, 'FIRST_MET', days_to_death FROM d5ifm2a4death_first_met_long
;
DROP TABLE IF EXISTS d5ifm2a4death_timing_quantiles;
DROP TABLE IF EXISTS d5ifm2a4death_timing_quantiles;
CREATE TABLE d5ifm2a4death_timing_quantiles  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS DOUBLE) AS lq_days,
	CAST(NULL AS DOUBLE) AS median_days,
	CAST(NULL AS DOUBLE) AS uq_days  WHERE 1 = 0;
INSERT INTO d5ifm2a4death_timing_quantiles (
 prevalence_year,
 anchor_event,
 lq_days,
 median_days,
 uq_days
)
SELECT
 prevalence_year,
 anchor_event,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_to_death AS DOUBLE) END) AS lq_days,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_to_death AS DOUBLE) END) AS median_days,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_to_death AS DOUBLE) END) AS uq_days
FROM (
 SELECT prevalence_year, anchor_event, days_to_death,
 ROW_NUMBER() OVER (PARTITION BY prevalence_year, anchor_event ORDER BY days_to_death) AS rn,
 COUNT(*) OVER (PARTITION BY prevalence_year, anchor_event) AS cnt
 FROM d5ifm2a4death_timing_long
) x
GROUP BY prevalence_year, anchor_event
;
DROP TABLE IF EXISTS d5ifm2a4followup_long;
DROP TABLE IF EXISTS d5ifm2a4followup_long;
CREATE TABLE d5ifm2a4followup_long  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS int) AS followup_days  WHERE 1 = 0;
INSERT INTO d5ifm2a4followup_long (prevalence_year, anchor_event, followup_days)
SELECT 'OVERALL', 'INDEX',
 DATEDIFF(DAY, c.index_date, MAX(op.observation_period_end_date))
FROM d5ifm2a4cohort c
INNER JOIN @cdm_database_schema.observation_period op
 ON op.person_id = c.person_id
 AND op.observation_period_end_date >= c.index_date
GROUP BY c.person_id, c.index_date
UNION ALL
SELECT CAST(YEAR(c.index_date) AS STRING), 'INDEX',
 DATEDIFF(DAY, c.index_date, MAX(op.observation_period_end_date))
FROM d5ifm2a4cohort c
INNER JOIN @cdm_database_schema.observation_period op
 ON op.person_id = c.person_id
 AND op.observation_period_end_date >= c.index_date
GROUP BY c.person_id, c.index_date, YEAR(c.index_date)
UNION ALL
SELECT 'OVERALL', 'FIRST_MET',
 DATEDIFF(DAY, ms.first_met_date, MAX(op.observation_period_end_date))
FROM d5ifm2a4cohort c
INNER JOIN d5ifm2a4met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN @cdm_database_schema.observation_period op
 ON op.person_id = c.person_id
 AND op.observation_period_end_date >= ms.first_met_date
GROUP BY c.person_id, ms.first_met_date
UNION ALL
SELECT CAST(YEAR(c.index_date) AS STRING), 'FIRST_MET',
 DATEDIFF(DAY, ms.first_met_date, MAX(op.observation_period_end_date))
FROM d5ifm2a4cohort c
INNER JOIN d5ifm2a4met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN @cdm_database_schema.observation_period op
 ON op.person_id = c.person_id
 AND op.observation_period_end_date >= ms.first_met_date
GROUP BY c.person_id, c.index_date, ms.first_met_date, YEAR(c.index_date)
;
DROP TABLE IF EXISTS d5ifm2a4followup_quantiles;
DROP TABLE IF EXISTS d5ifm2a4followup_quantiles;
CREATE TABLE d5ifm2a4followup_quantiles  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS DOUBLE) AS lq_followup_days,
	CAST(NULL AS DOUBLE) AS median_followup_days,
	CAST(NULL AS DOUBLE) AS uq_followup_days  WHERE 1 = 0;
INSERT INTO d5ifm2a4followup_quantiles (
 prevalence_year,
 anchor_event,
 lq_followup_days,
 median_followup_days,
 uq_followup_days
)
SELECT
 prevalence_year,
 anchor_event,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(followup_days AS DOUBLE) END) AS lq_followup_days,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(followup_days AS DOUBLE) END) AS median_followup_days,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(followup_days AS DOUBLE) END) AS uq_followup_days
FROM (
 SELECT prevalence_year, anchor_event, followup_days,
 ROW_NUMBER() OVER (PARTITION BY prevalence_year, anchor_event ORDER BY followup_days) AS rn,
 COUNT(*) OVER (PARTITION BY prevalence_year, anchor_event) AS cnt
 FROM d5ifm2a4followup_long
) x
GROUP BY prevalence_year, anchor_event
;
DROP TABLE IF EXISTS d5ifm2a4l01_event_days;
DROP TABLE IF EXISTS d5ifm2a4l01_event_days;
CREATE TABLE d5ifm2a4l01_event_days  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_day  WHERE 1 = 0;
INSERT INTO d5ifm2a4l01_event_days (person_id, event_day)
SELECT DISTINCT person_id, event_date
FROM d5ifm2a4l01_events
WHERE person_id IN (SELECT person_id FROM d5ifm2a4cohort)
;
DROP TABLE IF EXISTS d5ifm2a4l01_consecutive_gaps;
DROP TABLE IF EXISTS d5ifm2a4l01_consecutive_gaps;
CREATE TABLE d5ifm2a4l01_consecutive_gaps  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS STRING) AS subgroup,
	CAST(NULL AS int) AS gap_days  WHERE 1 = 0;
WITH ranked AS (
 SELECT
 e.person_id,
 e.event_day,
 LEAD(e.event_day) OVER (PARTITION BY e.person_id ORDER BY e.event_day) AS next_day
 FROM d5ifm2a4l01_event_days e
),
gaps AS (
 SELECT
 person_id,
 DATEDIFF(DAY, event_day, next_day) AS gap_days
 FROM ranked
 WHERE next_day IS NOT NULL
)
INSERT INTO d5ifm2a4l01_consecutive_gaps (person_id, subgroup, gap_days)
SELECT g.person_id, 'ALL_L01', g.gap_days FROM gaps g
UNION ALL
SELECT g.person_id, 'MET_L01', g.gap_days
FROM gaps g
JOIN d5ifm2a4met_summary ms ON g.person_id = ms.person_id AND ms.first_met_date IS NOT NULL;
