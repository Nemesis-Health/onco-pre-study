-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-05-07 12:40:20 BST
-- Source file    : sql/sql_server/characterization_full.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

DROP TABLE IF EXISTS a9of9doxdx_anchor_include;
DROP TABLE IF EXISTS a9of9doxdx_anchor_include;
CREATE TABLE a9of9doxdx_anchor_include  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS smallint) AS include_descendants  WHERE 1 = 0;
INSERT INTO a9of9doxdx_anchor_include (concept_id, include_descendants) VALUES
 (197508, 1), -- Malignant neoplasm of urinary bladder
 (4181357, 1), -- Malignant tumor of renal pelvis
 (4177230, 1), -- Malignant tumor of urethra
 (37163176, 1), -- Transitional cell carcinoma of upper urinary tract
 (4178972, 1), -- Malignant tumor of ureter
 (4091486, 0), -- Malignant neoplasm of overlapping sites of urinary organs
 (44501785, 0), -- Transitional cell carcinoma, NOS, of urinary system, NOS (ICDO3)
 (37110270, 1) -- Primary urothelial carcinoma of overlapping sites of urinary organs
;
DROP TABLE IF EXISTS a9of9doxdx_anchor_exclude;
DROP TABLE IF EXISTS a9of9doxdx_anchor_exclude;
CREATE TABLE a9of9doxdx_anchor_exclude  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS smallint) AS include_descendants  WHERE 1 = 0;
INSERT INTO a9of9doxdx_anchor_exclude (concept_id, include_descendants) VALUES
 (4280899, 1),
 (4289374, 1),
 (4280900, 1),
 (4283614, 1),
 (4289097, 1),
 (4280901, 1),
 (4289376, 1),
 (4280897, 1),
 (4200889, 1);
DROP TABLE IF EXISTS a9of9doxdx_anchor_concepts;
DROP TABLE IF EXISTS a9of9doxdx_anchor_concepts;
CREATE TABLE a9of9doxdx_anchor_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxdx_anchor_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM a9of9doxdx_anchor_include i
JOIN @cdm_database_schema.concept_ancestor ca
 ON ca.ancestor_concept_id = i.concept_id
 AND (i.include_descendants = 1 OR ca.descendant_concept_id = i.concept_id);
DELETE FROM a9of9doxdx_anchor_concepts
WHERE EXISTS (
 SELECT 1
 FROM a9of9doxdx_anchor_exclude e
 JOIN @cdm_database_schema.concept_ancestor ca
 ON ca.ancestor_concept_id = e.concept_id
 AND a9of9doxdx_anchor_concepts.concept_id = ca.descendant_concept_id
 AND (e.include_descendants = 1 OR ca.descendant_concept_id = e.concept_id)
);
DROP TABLE IF EXISTS a9of9doxgen_cancer_concepts;
DROP TABLE IF EXISTS a9of9doxgen_cancer_concepts;
CREATE TABLE a9of9doxgen_cancer_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxgen_cancer_concepts (concept_id)
SELECT DISTINCT ca.ancestor_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN a9of9doxdx_anchor_concepts d
 ON ca.descendant_concept_id = d.concept_id
JOIN @cdm_database_schema.concept_ancestor malign
 ON malign.ancestor_concept_id = 443392
 AND malign.descendant_concept_id = ca.ancestor_concept_id
WHERE NOT EXISTS (
 SELECT 1
 FROM a9of9doxdx_anchor_concepts dx
 WHERE dx.concept_id = ca.ancestor_concept_id
)
;
DROP TABLE IF EXISTS a9of9doxother_dx_ancestor_concepts;
DROP TABLE IF EXISTS a9of9doxother_dx_ancestor_concepts;
CREATE TABLE a9of9doxother_dx_ancestor_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS ancestor_concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxother_dx_ancestor_concepts (ancestor_concept_id)
VALUES
 (443392) -- Malignant neoplastic disease
;
DROP TABLE IF EXISTS a9of9doxother_dx_concepts;
DROP TABLE IF EXISTS a9of9doxother_dx_concepts;
CREATE TABLE a9of9doxother_dx_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxother_dx_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN a9of9doxother_dx_ancestor_concepts a
 ON ca.ancestor_concept_id = a.ancestor_concept_id
LEFT JOIN a9of9doxdx_anchor_concepts dx
 ON dx.concept_id = ca.descendant_concept_id
LEFT JOIN a9of9doxgen_cancer_concepts gdx
 ON gdx.concept_id = ca.descendant_concept_id
WHERE dx.concept_id IS NULL
 AND gdx.concept_id IS NULL
;
DROP TABLE IF EXISTS a9of9doxmet_ancestor_concepts;
DROP TABLE IF EXISTS a9of9doxmet_ancestor_concepts;
CREATE TABLE a9of9doxmet_ancestor_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS ancestor_concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxmet_ancestor_concepts (ancestor_concept_id)
VALUES
 (1633308), -- AJCC/UICC Stage 4
 (1635142), -- AJCC/UICC M1 Category
 (36769180) -- Metastasis
;
DROP TABLE IF EXISTS a9of9doxmet_concepts;
DROP TABLE IF EXISTS a9of9doxmet_concepts;
CREATE TABLE a9of9doxmet_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxmet_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN a9of9doxmet_ancestor_concepts a
 ON ca.ancestor_concept_id = a.ancestor_concept_id
;
DROP TABLE IF EXISTS a9of9doxl01_ancestor_concepts;
DROP TABLE IF EXISTS a9of9doxl01_ancestor_concepts;
CREATE TABLE a9of9doxl01_ancestor_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS ancestor_concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxl01_ancestor_concepts (ancestor_concept_id)
VALUES
 (21601387)
;
DROP TABLE IF EXISTS a9of9doxl01_concepts;
DROP TABLE IF EXISTS a9of9doxl01_concepts;
CREATE TABLE a9of9doxl01_concepts  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxl01_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN a9of9doxl01_ancestor_concepts a
 ON ca.ancestor_concept_id = a.ancestor_concept_id
;
DROP TABLE IF EXISTS a9of9doxdx_events;
DROP TABLE IF EXISTS a9of9doxdx_events;
CREATE TABLE a9of9doxdx_events  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date,
	CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxdx_events (person_id, event_date, concept_id)
SELECT
 co.person_id,
 co.condition_start_date,
 co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN a9of9doxdx_anchor_concepts d
 ON co.condition_concept_id = d.concept_id
;
DROP TABLE IF EXISTS a9of9doxanchor_person;
DROP TABLE IF EXISTS a9of9doxanchor_person;
CREATE TABLE a9of9doxanchor_person  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id  WHERE 1 = 0;
INSERT INTO a9of9doxanchor_person (person_id)
SELECT DISTINCT person_id
FROM a9of9doxdx_events
;
DROP TABLE IF EXISTS a9of9doxother_dx_events;
DROP TABLE IF EXISTS a9of9doxother_dx_events;
CREATE TABLE a9of9doxother_dx_events  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date,
	CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxother_dx_events (person_id, event_date, concept_id)
SELECT
 co.person_id,
 co.condition_start_date,
 co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN a9of9doxanchor_person ap
 ON co.person_id = ap.person_id
JOIN a9of9doxother_dx_concepts d
 ON co.condition_concept_id = d.concept_id
;
DROP TABLE IF EXISTS a9of9doxgen_cancer_events;
DROP TABLE IF EXISTS a9of9doxgen_cancer_events;
CREATE TABLE a9of9doxgen_cancer_events  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date,
	CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxgen_cancer_events (person_id, event_date, concept_id)
SELECT
 co.person_id,
 co.condition_start_date,
 co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN a9of9doxanchor_person ap
 ON co.person_id = ap.person_id
JOIN a9of9doxgen_cancer_concepts g
 ON co.condition_concept_id = g.concept_id
;
DROP TABLE IF EXISTS a9of9doxmet_events;
DROP TABLE IF EXISTS a9of9doxmet_events;
CREATE TABLE a9of9doxmet_events  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date,
	CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxmet_events (person_id, event_date, concept_id)
SELECT
 m.person_id,
 m.measurement_date,
 m.measurement_concept_id
FROM @cdm_database_schema.measurement m
JOIN a9of9doxanchor_person ap
 ON m.person_id = ap.person_id
JOIN a9of9doxmet_concepts mc
 ON m.measurement_concept_id = mc.concept_id
;
DROP TABLE IF EXISTS a9of9doxl01_events;
DROP TABLE IF EXISTS a9of9doxl01_events;
CREATE TABLE a9of9doxl01_events  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date,
	CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxl01_events (person_id, event_date, concept_id)
SELECT
 de.person_id,
 de.drug_exposure_start_date,
 de.drug_concept_id
FROM @cdm_database_schema.drug_exposure de
JOIN a9of9doxanchor_person ap
 ON de.person_id = ap.person_id
JOIN a9of9doxl01_concepts l
 ON de.drug_concept_id = l.concept_id
;
DROP TABLE IF EXISTS a9of9doxl01_ingredient_events;
DROP TABLE IF EXISTS a9of9doxl01_ingredient_events;
CREATE TABLE a9of9doxl01_ingredient_events  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date,
	CAST(NULL AS bigint) AS concept_id  WHERE 1 = 0;
INSERT INTO a9of9doxl01_ingredient_events (person_id, event_date, concept_id)
SELECT DISTINCT
 de.person_id,
 de.drug_exposure_start_date,
 ca.ancestor_concept_id
FROM @cdm_database_schema.drug_exposure de
JOIN a9of9doxanchor_person ap
 ON de.person_id = ap.person_id
JOIN a9of9doxl01_concepts l
 ON de.drug_concept_id = l.concept_id
JOIN @cdm_database_schema.concept_ancestor ca
 ON ca.descendant_concept_id = de.drug_concept_id
JOIN @cdm_database_schema.concept ing
 ON ing.concept_id = ca.ancestor_concept_id
 AND ing.concept_class_id = 'Ingredient'
;
DROP TABLE IF EXISTS a9of9doxcohort_attrition;
DROP TABLE IF EXISTS a9of9doxcohort_attrition;
CREATE TABLE a9of9doxcohort_attrition  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS stage,
	CAST(NULL AS int) AS n_patients  WHERE 1 = 0;
INSERT INTO a9of9doxcohort_attrition (stage, n_patients)
SELECT 'dx_any', COUNT(DISTINCT person_id) FROM a9of9doxdx_events;
DROP TABLE IF EXISTS a9of9doxcohort;
DROP TABLE IF EXISTS a9of9doxcohort;
CREATE TABLE a9of9doxcohort  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS index_date  WHERE 1 = 0;
INSERT INTO a9of9doxcohort (person_id, index_date)
SELECT
 dx.person_id,
 MIN(dx.event_date) AS index_date
FROM a9of9doxdx_events dx
INNER JOIN @cdm_database_schema.observation_period op
 ON op.person_id = dx.person_id
 AND dx.event_date BETWEEN op.observation_period_start_date
 AND op.observation_period_end_date
GROUP BY dx.person_id
;
INSERT INTO a9of9doxcohort_attrition (stage, n_patients)
SELECT 'dx_in_obs', COUNT(*) FROM a9of9doxcohort;
DROP TABLE IF EXISTS a9of9doxdx_summary;
DROP TABLE IF EXISTS a9of9doxdx_summary;
CREATE TABLE a9of9doxdx_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS n_dx_records,
	CAST(NULL AS int) AS n_dx_codes  WHERE 1 = 0;
INSERT INTO a9of9doxdx_summary (person_id, n_dx_records, n_dx_codes)
SELECT
 e.person_id,
 COUNT(*) AS n_dx_records,
 COUNT(DISTINCT e.concept_id) AS n_dx_codes
FROM a9of9doxdx_events e
JOIN a9of9doxcohort c
 ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS a9of9doxother_dx_summary;
DROP TABLE IF EXISTS a9of9doxother_dx_summary;
CREATE TABLE a9of9doxother_dx_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS first_other_dx_date,
	CAST(NULL AS int) AS n_other_dx_records,
	CAST(NULL AS int) AS n_other_dx_codes  WHERE 1 = 0;
INSERT INTO a9of9doxother_dx_summary (person_id, first_other_dx_date, n_other_dx_records, n_other_dx_codes)
SELECT
 e.person_id,
 MIN(e.event_date) AS first_other_dx_date,
 COUNT(*) AS n_other_dx_records,
 COUNT(DISTINCT e.concept_id) AS n_other_dx_codes
FROM a9of9doxother_dx_events e
JOIN a9of9doxcohort c
 ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS a9of9doxgen_cancer_summary;
DROP TABLE IF EXISTS a9of9doxgen_cancer_summary;
CREATE TABLE a9of9doxgen_cancer_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS first_gen_cancer_date,
	CAST(NULL AS int) AS n_gen_cancer_records,
	CAST(NULL AS int) AS n_gen_cancer_codes  WHERE 1 = 0;
INSERT INTO a9of9doxgen_cancer_summary (person_id, first_gen_cancer_date, n_gen_cancer_records, n_gen_cancer_codes)
SELECT
 e.person_id,
 MIN(e.event_date) AS first_gen_cancer_date,
 COUNT(*) AS n_gen_cancer_records,
 COUNT(DISTINCT e.concept_id) AS n_gen_cancer_codes
FROM a9of9doxgen_cancer_events e
JOIN a9of9doxcohort c
 ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS a9of9doxmet_summary;
DROP TABLE IF EXISTS a9of9doxmet_summary;
CREATE TABLE a9of9doxmet_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS first_met_date,
	CAST(NULL AS int) AS n_met_records  WHERE 1 = 0;
INSERT INTO a9of9doxmet_summary (person_id, first_met_date, n_met_records)
SELECT
 e.person_id,
 MIN(e.event_date) AS first_met_date,
 COUNT(*) AS n_met_records
FROM a9of9doxmet_events e
JOIN a9of9doxcohort c
 ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS a9of9doxl01_summary;
DROP TABLE IF EXISTS a9of9doxl01_summary;
CREATE TABLE a9of9doxl01_summary  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS first_l01_date,
	CAST(NULL AS int) AS n_l01_exposures  WHERE 1 = 0;
INSERT INTO a9of9doxl01_summary (person_id, first_l01_date, n_l01_exposures)
SELECT
 e.person_id,
 MIN(e.event_date) AS first_l01_date,
 COUNT(*) AS n_l01_exposures
FROM a9of9doxl01_events e
JOIN a9of9doxcohort c
 ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS a9of9doxevent_code_counts;
DROP TABLE IF EXISTS a9of9doxevent_code_counts;
CREATE TABLE a9of9doxevent_code_counts  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS index) AS --,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS int) AS n_records,
	CAST(NULL AS int) AS n_patients  WHERE 1 = 0;
INSERT INTO a9of9doxevent_code_counts (anchor_event, event_family, concept_id, n_records, n_patients)
SELECT 'INDEX', 'DX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM a9of9doxdx_events
WHERE person_id IN (SELECT person_id FROM a9of9doxcohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'ODX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM a9of9doxother_dx_events
WHERE person_id IN (SELECT person_id FROM a9of9doxcohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'GDX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM a9of9doxgen_cancer_events
WHERE person_id IN (SELECT person_id FROM a9of9doxcohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'MET', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM a9of9doxmet_events
WHERE person_id IN (SELECT person_id FROM a9of9doxcohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'L01', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM a9of9doxl01_ingredient_events
WHERE person_id IN (SELECT person_id FROM a9of9doxcohort)
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'DX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM a9of9doxdx_events e
JOIN a9of9doxmet_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'ODX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM a9of9doxother_dx_events e
JOIN a9of9doxmet_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'GDX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM a9of9doxgen_cancer_events e
JOIN a9of9doxmet_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'MET', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM a9of9doxmet_events e
JOIN a9of9doxmet_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'L01', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM a9of9doxl01_ingredient_events e
JOIN a9of9doxmet_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
;
DROP TABLE IF EXISTS a9of9doxevent_code_counts_before_after;
DROP TABLE IF EXISTS a9of9doxevent_code_counts_before_after;
CREATE TABLE a9of9doxevent_code_counts_before_after  
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
INSERT INTO a9of9doxevent_code_counts_before_after (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
SELECT 'INDEX',
 'DX',
 CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END AS time_relative,
 e.concept_id,
 COUNT(*) AS n_records,
 COUNT(DISTINCT e.person_id) AS n_patients
FROM a9of9doxdx_events e
JOIN a9of9doxcohort c
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
FROM a9of9doxother_dx_events e
JOIN a9of9doxcohort c
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
FROM a9of9doxgen_cancer_events e
JOIN a9of9doxcohort c
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
FROM a9of9doxmet_events e
JOIN a9of9doxcohort c
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
FROM a9of9doxl01_ingredient_events e
JOIN a9of9doxcohort c
 ON e.person_id = c.person_id
GROUP BY
 CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id
;
DROP TABLE IF EXISTS a9of9doxevent_code_counts_before_after_first_met;
DROP TABLE IF EXISTS a9of9doxevent_code_counts_before_after_first_met;
CREATE TABLE a9of9doxevent_code_counts_before_after_first_met  
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
INSERT INTO a9of9doxevent_code_counts_before_after_first_met (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
SELECT 'FIRST_MET',
 'DX',
 CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END AS time_relative,
 e.concept_id,
 COUNT(*) AS n_records,
 COUNT(DISTINCT e.person_id) AS n_patients
FROM a9of9doxdx_events e
JOIN a9of9doxmet_summary ms
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
FROM a9of9doxother_dx_events e
JOIN a9of9doxmet_summary ms
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
FROM a9of9doxgen_cancer_events e
JOIN a9of9doxmet_summary ms
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
FROM a9of9doxmet_events e
JOIN a9of9doxmet_summary ms
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
FROM a9of9doxl01_ingredient_events e
JOIN a9of9doxmet_summary ms
 ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY
 CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
 e.concept_id
;
DROP TABLE IF EXISTS a9of9doxevent_code_all_events;
DROP TABLE IF EXISTS a9of9doxevent_code_all_events;
CREATE TABLE a9of9doxevent_code_all_events  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS days_diff,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date  WHERE 1 = 0;
INSERT INTO a9of9doxevent_code_all_events (
 anchor_event, event_family, concept_id, person_id, days_diff, event_date
)
SELECT 'INDEX' AS anchor_event, 'DX' AS event_family, e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date) AS days_diff, e.event_date
FROM a9of9doxdx_events e
JOIN a9of9doxcohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'ODX', e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date), e.event_date
FROM a9of9doxother_dx_events e
JOIN a9of9doxcohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'GDX', e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date), e.event_date
FROM a9of9doxgen_cancer_events e
JOIN a9of9doxcohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'MET', e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date), e.event_date
FROM a9of9doxmet_events e
JOIN a9of9doxcohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'L01', e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date), e.event_date
FROM a9of9doxl01_ingredient_events e
JOIN a9of9doxcohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'FIRST_MET', 'DX', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM a9of9doxdx_events e
JOIN a9of9doxmet_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'ODX', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM a9of9doxother_dx_events e
JOIN a9of9doxmet_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'GDX', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM a9of9doxgen_cancer_events e
JOIN a9of9doxmet_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'MET', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM a9of9doxmet_events e
JOIN a9of9doxmet_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'L01', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM a9of9doxl01_ingredient_events e
JOIN a9of9doxmet_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
;
DROP TABLE IF EXISTS a9of9doxevent_code_patient_chosen_first;
DROP TABLE IF EXISTS a9of9doxevent_code_patient_chosen_first;
CREATE TABLE a9of9doxevent_code_patient_chosen_first  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
INSERT INTO a9of9doxevent_code_patient_chosen_first (anchor_event, event_family, concept_id, person_id, days_diff)
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
 FROM a9of9doxevent_code_all_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS a9of9doxevent_code_patient_chosen_closest;
DROP TABLE IF EXISTS a9of9doxevent_code_patient_chosen_closest;
CREATE TABLE a9of9doxevent_code_patient_chosen_closest  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
INSERT INTO a9of9doxevent_code_patient_chosen_closest (anchor_event, event_family, concept_id, person_id, days_diff)
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
 FROM a9of9doxevent_code_all_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS a9of9doxevent_code_timing_summary;
DROP TABLE IF EXISTS a9of9doxevent_code_timing_summary;
CREATE TABLE a9of9doxevent_code_timing_summary  
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
INSERT INTO a9of9doxevent_code_timing_summary (
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
 FROM a9of9doxevent_code_patient_chosen_first
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
 FROM a9of9doxevent_code_patient_chosen_closest
 ) x
 GROUP BY anchor_event, event_family, concept_id
) k
 ON f.anchor_event = k.anchor_event
 AND f.event_family = k.event_family
 AND f.concept_id = k.concept_id
;
DROP TABLE IF EXISTS a9of9doxevent_code_ba_events;
DROP TABLE IF EXISTS a9of9doxevent_code_ba_events;
CREATE TABLE a9of9doxevent_code_ba_events  
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
INSERT INTO a9of9doxevent_code_ba_events (
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
FROM a9of9doxevent_code_all_events
;
DROP TABLE IF EXISTS a9of9doxevent_code_patient_chosen_before_after_first;
DROP TABLE IF EXISTS a9of9doxevent_code_patient_chosen_before_after_first;
CREATE TABLE a9of9doxevent_code_patient_chosen_before_after_first  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS STRING) AS time_relative,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
INSERT INTO a9of9doxevent_code_patient_chosen_before_after_first (
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
 FROM a9of9doxevent_code_ba_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS a9of9doxevent_code_patient_chosen_before_after_closest;
DROP TABLE IF EXISTS a9of9doxevent_code_patient_chosen_before_after_closest;
CREATE TABLE a9of9doxevent_code_patient_chosen_before_after_closest  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS STRING) AS event_family,
	CAST(NULL AS STRING) AS time_relative,
	CAST(NULL AS bigint) AS concept_id,
	CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
INSERT INTO a9of9doxevent_code_patient_chosen_before_after_closest (
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
 FROM a9of9doxevent_code_ba_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS a9of9doxevent_code_timing_before_after_summary;
DROP TABLE IF EXISTS a9of9doxevent_code_timing_before_after_summary;
CREATE TABLE a9of9doxevent_code_timing_before_after_summary  
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
INSERT INTO a9of9doxevent_code_timing_before_after_summary (
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
 FROM a9of9doxevent_code_patient_chosen_before_after_first
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
 FROM a9of9doxevent_code_patient_chosen_before_after_closest
 ) x
 GROUP BY anchor_event, event_family, time_relative, concept_id
) k
 ON f.anchor_event = k.anchor_event
 AND f.event_family = k.event_family
 AND f.time_relative = k.time_relative
 AND f.concept_id = k.concept_id
;
DROP TABLE IF EXISTS a9of9doxpatient_char;
DROP TABLE IF EXISTS a9of9doxpatient_char;
CREATE TABLE a9of9doxpatient_char  
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
INSERT INTO a9of9doxpatient_char (
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
FROM a9of9doxcohort c
LEFT JOIN a9of9doxdx_summary dx
 ON c.person_id = dx.person_id
LEFT JOIN a9of9doxother_dx_summary odx
 ON c.person_id = odx.person_id
LEFT JOIN a9of9doxgen_cancer_summary gdx
 ON c.person_id = gdx.person_id
LEFT JOIN a9of9doxmet_summary mt
 ON c.person_id = mt.person_id
LEFT JOIN a9of9doxl01_summary l01
 ON c.person_id = l01.person_id
;
DROP TABLE IF EXISTS a9of9doxpatient_timing_pairs;
DROP TABLE IF EXISTS a9of9doxpatient_timing_pairs;
CREATE TABLE a9of9doxpatient_timing_pairs  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS STRING) AS from_event,
	CAST(NULL AS STRING) AS to_event,
	CAST(NULL AS int) AS days_diff  WHERE 1 = 0;
WITH events  AS (SELECT person_id,  CAST('DX' as STRING) AS event_name, index_date AS event_date FROM a9of9doxpatient_char
 UNION ALL
 SELECT person_id, 'ODX', first_other_dx_date FROM a9of9doxpatient_char
 UNION ALL
 SELECT person_id, 'GDX', first_gen_cancer_date FROM a9of9doxpatient_char
 UNION ALL
 SELECT person_id, 'MET', first_met_date FROM a9of9doxpatient_char
 UNION ALL
 SELECT person_id, 'L01', first_l01_date FROM a9of9doxpatient_char
)
INSERT INTO a9of9doxpatient_timing_pairs (person_id, from_event, to_event, days_diff)
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
DROP TABLE IF EXISTS a9of9doxtiming_pair_summary;
DROP TABLE IF EXISTS a9of9doxtiming_pair_summary;
CREATE TABLE a9of9doxtiming_pair_summary  
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
INSERT INTO a9of9doxtiming_pair_summary (
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
 FROM a9of9doxpatient_timing_pairs
) x
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS a9of9doxall_events_for_pairs;
DROP TABLE IF EXISTS a9of9doxall_events_for_pairs;
CREATE TABLE a9of9doxall_events_for_pairs  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS STRING) AS event_family,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_date  WHERE 1 = 0;
INSERT INTO a9of9doxall_events_for_pairs (person_id, event_family, event_date)
SELECT person_id, 'DX', event_date FROM a9of9doxdx_events
UNION ALL
SELECT person_id, 'ODX', event_date FROM a9of9doxother_dx_events
UNION ALL
SELECT person_id, 'GDX', event_date FROM a9of9doxgen_cancer_events
UNION ALL
SELECT person_id, 'MET', event_date FROM a9of9doxmet_events
UNION ALL
SELECT person_id, 'L01', event_date FROM a9of9doxl01_events
;
DROP TABLE IF EXISTS a9of9doxfirst_event_dates;
DROP TABLE IF EXISTS a9of9doxfirst_event_dates;
CREATE TABLE a9of9doxfirst_event_dates  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS STRING) AS from_event,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS from_first_date  WHERE 1 = 0;
INSERT INTO a9of9doxfirst_event_dates (person_id, from_event, from_first_date)
SELECT person_id, 'DX', index_date FROM a9of9doxpatient_char
UNION ALL
SELECT person_id, 'ODX', first_other_dx_date FROM a9of9doxpatient_char WHERE first_other_dx_date IS NOT NULL
UNION ALL
SELECT person_id, 'GDX', first_gen_cancer_date FROM a9of9doxpatient_char WHERE first_gen_cancer_date IS NOT NULL
UNION ALL
SELECT person_id, 'MET', first_met_date FROM a9of9doxpatient_char WHERE first_met_date IS NOT NULL
UNION ALL
SELECT person_id, 'L01', first_l01_date FROM a9of9doxpatient_char WHERE first_l01_date IS NOT NULL
;
DROP TABLE IF EXISTS a9of9doxpatient_timing_pairs_first_to_closest;
DROP TABLE IF EXISTS a9of9doxpatient_timing_pairs_first_to_closest;
CREATE TABLE a9of9doxpatient_timing_pairs_first_to_closest  
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
 FROM a9of9doxfirst_event_dates f
 JOIN a9of9doxall_events_for_pairs a
 ON f.person_id = a.person_id
 AND f.from_event <> a.event_family
)
INSERT INTO a9of9doxpatient_timing_pairs_first_to_closest (person_id, from_event, to_event, days_diff)
SELECT
 person_id,
 from_event,
 to_event,
 days_diff
FROM ranked
WHERE rn = 1
;
DROP TABLE IF EXISTS a9of9doxtiming_pair_summary_first_to_closest;
DROP TABLE IF EXISTS a9of9doxtiming_pair_summary_first_to_closest;
CREATE TABLE a9of9doxtiming_pair_summary_first_to_closest  
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
INSERT INTO a9of9doxtiming_pair_summary_first_to_closest (
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
 FROM a9of9doxpatient_timing_pairs_first_to_closest
) x
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS a9of9doxpatient_timing_pairs_first_to_closest_before;
DROP TABLE IF EXISTS a9of9doxpatient_timing_pairs_first_to_closest_before;
CREATE TABLE a9of9doxpatient_timing_pairs_first_to_closest_before  
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
 FROM a9of9doxfirst_event_dates f
 JOIN a9of9doxall_events_for_pairs a
 ON f.person_id = a.person_id
 AND f.from_event <> a.event_family
 WHERE DATEDIFF(DAY, f.from_first_date, a.event_date) < 0
)
INSERT INTO a9of9doxpatient_timing_pairs_first_to_closest_before (person_id, from_event, to_event, days_diff)
SELECT
 person_id,
 from_event,
 to_event,
 days_diff
FROM ranked_before
WHERE rn = 1
;
DROP TABLE IF EXISTS a9of9doxtiming_pair_summary_first_to_closest_before;
DROP TABLE IF EXISTS a9of9doxtiming_pair_summary_first_to_closest_before;
CREATE TABLE a9of9doxtiming_pair_summary_first_to_closest_before  
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
INSERT INTO a9of9doxtiming_pair_summary_first_to_closest_before (
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
 FROM a9of9doxpatient_timing_pairs_first_to_closest_before
) x
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS a9of9doxpatient_timing_pairs_first_to_closest_after;
DROP TABLE IF EXISTS a9of9doxpatient_timing_pairs_first_to_closest_after;
CREATE TABLE a9of9doxpatient_timing_pairs_first_to_closest_after  
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
 FROM a9of9doxfirst_event_dates f
 JOIN a9of9doxall_events_for_pairs a
 ON f.person_id = a.person_id
 AND f.from_event <> a.event_family
 WHERE DATEDIFF(DAY, f.from_first_date, a.event_date) >= 0
)
INSERT INTO a9of9doxpatient_timing_pairs_first_to_closest_after (person_id, from_event, to_event, days_diff)
SELECT
 person_id,
 from_event,
 to_event,
 days_diff
FROM ranked_after
WHERE rn = 1
;
DROP TABLE IF EXISTS a9of9doxtiming_pair_summary_first_to_closest_after;
DROP TABLE IF EXISTS a9of9doxtiming_pair_summary_first_to_closest_after;
CREATE TABLE a9of9doxtiming_pair_summary_first_to_closest_after  
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
INSERT INTO a9of9doxtiming_pair_summary_first_to_closest_after (
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
 FROM a9of9doxpatient_timing_pairs_first_to_closest_after
) x
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS a9of9doxevent_presence;
DROP TABLE IF EXISTS a9of9doxevent_presence;
CREATE TABLE a9of9doxevent_presence  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	CAST(NULL AS int) AS has_dx,
	CAST(NULL AS int) AS has_odx,
	CAST(NULL AS int) AS has_gdx,
	CAST(NULL AS int) AS has_met,
	CAST(NULL AS int) AS has_l01  WHERE 1 = 0;
INSERT INTO a9of9doxevent_presence (
 person_id, has_dx, has_odx, has_gdx, has_met, has_l01
)
SELECT
 person_id,
 1,
 CASE WHEN first_other_dx_date IS NOT NULL THEN 1 ELSE 0 END,
 CASE WHEN first_gen_cancer_date IS NOT NULL THEN 1 ELSE 0 END,
 CASE WHEN first_met_date IS NOT NULL THEN 1 ELSE 0 END,
 CASE WHEN first_l01_date IS NOT NULL THEN 1 ELSE 0 END
FROM a9of9doxpatient_char
;
DROP TABLE IF EXISTS a9of9doxdeath_obs_status;
DROP TABLE IF EXISTS a9of9doxdeath_obs_status;
CREATE TABLE a9of9doxdeath_obs_status  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS death_date,
	CAST(NULL AS smallint) AS death_in_obs  WHERE 1 = 0;
INSERT INTO a9of9doxdeath_obs_status (person_id, death_date, death_in_obs)
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
WHERE d.person_id IN (SELECT person_id FROM a9of9doxcohort)
;
DROP TABLE IF EXISTS a9of9doxdeath_index_long;
DROP TABLE IF EXISTS a9of9doxdeath_index_long;
CREATE TABLE a9of9doxdeath_index_long  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS int) AS days_to_death  WHERE 1 = 0;
INSERT INTO a9of9doxdeath_index_long (prevalence_year, days_to_death)
SELECT 'OVERALL', DATEDIFF(DAY, c.index_date, dos.death_date)
FROM a9of9doxcohort c
INNER JOIN a9of9doxdeath_obs_status dos ON dos.person_id = c.person_id
WHERE dos.death_date >= c.index_date
UNION ALL
SELECT CAST(YEAR(c.index_date) AS STRING), DATEDIFF(DAY, c.index_date, dos.death_date)
FROM a9of9doxcohort c
INNER JOIN a9of9doxdeath_obs_status dos ON dos.person_id = c.person_id
WHERE dos.death_date >= c.index_date
;
DROP TABLE IF EXISTS a9of9doxdeath_first_met_long;
DROP TABLE IF EXISTS a9of9doxdeath_first_met_long;
CREATE TABLE a9of9doxdeath_first_met_long  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS int) AS days_to_death  WHERE 1 = 0;
INSERT INTO a9of9doxdeath_first_met_long (prevalence_year, days_to_death)
SELECT 'OVERALL', DATEDIFF(DAY, ms.first_met_date, dos.death_date)
FROM a9of9doxcohort c
INNER JOIN a9of9doxmet_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN a9of9doxdeath_obs_status dos ON dos.person_id = c.person_id
WHERE dos.death_date >= ms.first_met_date
UNION ALL
SELECT CAST(YEAR(ms.first_met_date) AS STRING), DATEDIFF(DAY, ms.first_met_date, dos.death_date)
FROM a9of9doxcohort c
INNER JOIN a9of9doxmet_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN a9of9doxdeath_obs_status dos ON dos.person_id = c.person_id
WHERE dos.death_date >= ms.first_met_date
;
DROP TABLE IF EXISTS a9of9doxdeath_stratum_counts;
DROP TABLE IF EXISTS a9of9doxdeath_stratum_counts;
CREATE TABLE a9of9doxdeath_stratum_counts  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS int) AS n_patients,
	CAST(NULL AS int) AS n_deaths,
	CAST(NULL AS int) AS n_deaths_in_obs,
	CAST(NULL AS int) AS n_deaths_out_obs  WHERE 1 = 0;
INSERT INTO a9of9doxdeath_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths, n_deaths_in_obs, n_deaths_out_obs)
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
FROM a9of9doxcohort c
LEFT JOIN a9of9doxdeath_obs_status dos ON dos.person_id = c.person_id
GROUP BY GROUPING SETS ((), (YEAR(c.index_date)))
;
INSERT INTO a9of9doxdeath_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths, n_deaths_in_obs, n_deaths_out_obs)
SELECT
 CASE
 WHEN GROUPING(YEAR(ms.first_met_date)) = 1 THEN 'OVERALL'
 ELSE CAST(YEAR(ms.first_met_date) AS STRING)
 END,
 'FIRST_MET',
 COUNT(*),
 SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= ms.first_met_date THEN 1 ELSE 0 END),
 SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= ms.first_met_date AND dos.death_in_obs = 1 THEN 1 ELSE 0 END),
 SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= ms.first_met_date AND dos.death_in_obs = 0 THEN 1 ELSE 0 END)
FROM a9of9doxcohort c
INNER JOIN a9of9doxmet_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
LEFT JOIN a9of9doxdeath_obs_status dos ON dos.person_id = c.person_id
GROUP BY GROUPING SETS ((), (YEAR(ms.first_met_date)))
;
DROP TABLE IF EXISTS a9of9doxdeath_timing_long;
DROP TABLE IF EXISTS a9of9doxdeath_timing_long;
CREATE TABLE a9of9doxdeath_timing_long  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS int) AS days_to_death  WHERE 1 = 0;
INSERT INTO a9of9doxdeath_timing_long (prevalence_year, anchor_event, days_to_death)
SELECT prevalence_year, 'INDEX', days_to_death FROM a9of9doxdeath_index_long
UNION ALL
SELECT prevalence_year, 'FIRST_MET', days_to_death FROM a9of9doxdeath_first_met_long
;
DROP TABLE IF EXISTS a9of9doxdeath_timing_quantiles;
DROP TABLE IF EXISTS a9of9doxdeath_timing_quantiles;
CREATE TABLE a9of9doxdeath_timing_quantiles  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS DOUBLE) AS lq_days,
	CAST(NULL AS DOUBLE) AS median_days,
	CAST(NULL AS DOUBLE) AS uq_days  WHERE 1 = 0;
INSERT INTO a9of9doxdeath_timing_quantiles (
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
 FROM a9of9doxdeath_timing_long
) x
GROUP BY prevalence_year, anchor_event
;
DROP TABLE IF EXISTS a9of9doxfollowup_long;
DROP TABLE IF EXISTS a9of9doxfollowup_long;
CREATE TABLE a9of9doxfollowup_long  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS int) AS followup_days  WHERE 1 = 0;
INSERT INTO a9of9doxfollowup_long (prevalence_year, anchor_event, followup_days)
SELECT 'OVERALL', 'INDEX',
 DATEDIFF(DAY, c.index_date, MAX(op.observation_period_end_date))
FROM a9of9doxcohort c
INNER JOIN @cdm_database_schema.observation_period op
 ON op.person_id = c.person_id
 AND op.observation_period_end_date >= c.index_date
GROUP BY c.person_id, c.index_date
UNION ALL
SELECT CAST(YEAR(c.index_date) AS STRING), 'INDEX',
 DATEDIFF(DAY, c.index_date, MAX(op.observation_period_end_date))
FROM a9of9doxcohort c
INNER JOIN @cdm_database_schema.observation_period op
 ON op.person_id = c.person_id
 AND op.observation_period_end_date >= c.index_date
GROUP BY c.person_id, c.index_date, YEAR(c.index_date)
UNION ALL
SELECT 'OVERALL', 'FIRST_MET',
 DATEDIFF(DAY, ms.first_met_date, MAX(op.observation_period_end_date))
FROM a9of9doxcohort c
INNER JOIN a9of9doxmet_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN @cdm_database_schema.observation_period op
 ON op.person_id = c.person_id
 AND op.observation_period_end_date >= ms.first_met_date
GROUP BY c.person_id, ms.first_met_date
UNION ALL
SELECT CAST(YEAR(ms.first_met_date) AS STRING), 'FIRST_MET',
 DATEDIFF(DAY, ms.first_met_date, MAX(op.observation_period_end_date))
FROM a9of9doxcohort c
INNER JOIN a9of9doxmet_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN @cdm_database_schema.observation_period op
 ON op.person_id = c.person_id
 AND op.observation_period_end_date >= ms.first_met_date
GROUP BY c.person_id, ms.first_met_date, YEAR(ms.first_met_date)
;
DROP TABLE IF EXISTS a9of9doxfollowup_quantiles;
DROP TABLE IF EXISTS a9of9doxfollowup_quantiles;
CREATE TABLE a9of9doxfollowup_quantiles  
USING DELTA
 AS
SELECT
CAST(NULL AS STRING) AS prevalence_year,
	CAST(NULL AS STRING) AS anchor_event,
	CAST(NULL AS DOUBLE) AS lq_followup_days,
	CAST(NULL AS DOUBLE) AS median_followup_days,
	CAST(NULL AS DOUBLE) AS uq_followup_days  WHERE 1 = 0;
INSERT INTO a9of9doxfollowup_quantiles (
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
 FROM a9of9doxfollowup_long
) x
GROUP BY prevalence_year, anchor_event
;
DROP TABLE IF EXISTS a9of9doxl01_event_days;
DROP TABLE IF EXISTS a9of9doxl01_event_days;
CREATE TABLE a9of9doxl01_event_days  
USING DELTA
 AS
SELECT
CAST(NULL AS bigint) AS person_id,
	IF(try_cast(NULL  AS DATE) IS NULL, to_date(cast(NULL  AS STRING), 'yyyyMMdd'), try_cast(NULL  AS DATE)) AS event_day  WHERE 1 = 0;
INSERT INTO a9of9doxl01_event_days (person_id, event_day)
SELECT DISTINCT person_id, event_date
FROM a9of9doxl01_events
WHERE person_id IN (SELECT person_id FROM a9of9doxcohort)
;
DROP TABLE IF EXISTS a9of9doxl01_consecutive_gaps;
DROP TABLE IF EXISTS a9of9doxl01_consecutive_gaps;
CREATE TABLE a9of9doxl01_consecutive_gaps  
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
 FROM a9of9doxl01_event_days e
),
gaps AS (
 SELECT
 person_id,
 DATEDIFF(DAY, event_day, next_day) AS gap_days
 FROM ranked
 WHERE next_day IS NOT NULL
)
INSERT INTO a9of9doxl01_consecutive_gaps (person_id, subgroup, gap_days)
SELECT g.person_id, 'ALL_L01', g.gap_days FROM gaps g
UNION ALL
SELECT g.person_id, 'MET_L01', g.gap_days
FROM gaps g
JOIN a9of9doxmet_summary ms ON g.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
;
INSERT INTO a9of9doxl01_consecutive_gaps (person_id, subgroup, gap_days)
SELECT person_id, 'ALL_L01_MAX', MAX(gap_days)
FROM a9of9doxl01_consecutive_gaps
WHERE subgroup = 'ALL_L01'
GROUP BY person_id
UNION ALL
SELECT person_id, 'MET_L01_MAX', MAX(gap_days)
FROM a9of9doxl01_consecutive_gaps
WHERE subgroup = 'MET_L01'
GROUP BY person_id
;
SELECT
 SUM(CASE WHEN stage = 'dx_any' THEN n_patients ELSE 0 END) AS n_dx_any,
 SUM(CASE WHEN stage = 'dx_in_obs' THEN n_patients ELSE 0 END) AS n_dx_in_obs,
 SUM(CASE WHEN stage = 'dx_any' THEN n_patients ELSE 0 END)
 - SUM(CASE WHEN stage = 'dx_in_obs' THEN n_patients ELSE 0 END) AS n_excluded_no_obs_dx
FROM a9of9doxcohort_attrition
;
WITH base  AS (SELECT CASE
 WHEN GROUPING(YEAR(index_date)) = 1 THEN  CAST('OVERALL' as STRING) ELSE CAST(YEAR(index_date) AS STRING)
 END AS prevalence_year,
 COUNT(*) AS n_patients,
 SUM(CASE WHEN first_other_dx_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_other_dx,
 SUM(CASE WHEN first_gen_cancer_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_gen_cancer_dx,
 SUM(CASE WHEN first_met_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_met,
 SUM(CASE WHEN first_l01_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_l01
 FROM a9of9doxpatient_char
 GROUP BY GROUPING SETS (
 (),
 (YEAR(index_date))
 )
)
SELECT
 prevalence_year,
 CASE WHEN n_patients <= @min_cell_count THEN -@min_cell_count ELSE n_patients END AS n_dx,
 CASE
 WHEN n_patients <= @min_cell_count THEN -@min_cell_count
 WHEN n_with_other_dx BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
 ELSE n_with_other_dx
 END AS n_odx,
 CASE
 WHEN n_patients <= @min_cell_count THEN -@min_cell_count
 WHEN n_with_gen_cancer_dx BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
 ELSE n_with_gen_cancer_dx
 END AS n_gdx,
 CASE
 WHEN n_patients <= @min_cell_count THEN -@min_cell_count
 WHEN n_with_met BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
 ELSE n_with_met
 END AS n_met,
 CASE
 WHEN n_patients <= @min_cell_count THEN -@min_cell_count
 WHEN n_with_l01 BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
 ELSE n_with_l01
 END AS n_l01
FROM base
ORDER BY
 CASE WHEN prevalence_year = 'OVERALL' THEN 0 ELSE 1 END,
 CASE WHEN prevalence_year = 'OVERALL' THEN NULL ELSE CAST(prevalence_year AS INT) END
;
SELECT
 x.time_window,
 x.anchor_event,
 x.event_family,
 x.concept_id,
 CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE x.n_records END AS n_records,
 CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE x.n_patients END AS n_patients,
 CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE COALESCE(ts.n_patients_with_code_timing, tba.n_patients_with_code_timing) END AS n_patients_with_code_timing,
 CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.lq_days_first, tba.lq_days_first) END AS lq_days_first,
 CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.median_days_first, tba.median_days_first) END AS median_days_first,
 CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.uq_days_first, tba.uq_days_first) END AS uq_days_first,
 CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.lq_days_closest, tba.lq_days_closest) END AS lq_days_closest,
 CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.median_days_closest, tba.median_days_closest) END AS median_days_closest,
 CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.uq_days_closest, tba.uq_days_closest) END AS uq_days_closest,
 CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.lq_days_first, tba.lq_days_first) END AS lq_days,
 CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.median_days_first, tba.median_days_first) END AS median_days,
 CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.uq_days_first, tba.uq_days_first) END AS uq_days
FROM (
 SELECT 'all' AS time_window, anchor_event, event_family, concept_id, n_records, n_patients FROM a9of9doxevent_code_counts
 UNION ALL
 SELECT 'before' AS time_window, anchor_event, event_family, concept_id, n_records, n_patients FROM a9of9doxevent_code_counts_before_after WHERE time_relative = 'BEFORE'
 UNION ALL
 SELECT 'after' AS time_window, anchor_event, event_family, concept_id, n_records, n_patients FROM a9of9doxevent_code_counts_before_after WHERE time_relative = 'AFTER'
 UNION ALL
 SELECT 'before' AS time_window, anchor_event, event_family, concept_id, n_records, n_patients FROM a9of9doxevent_code_counts_before_after_first_met WHERE time_relative = 'BEFORE'
 UNION ALL
 SELECT 'after' AS time_window, anchor_event, event_family, concept_id, n_records, n_patients FROM a9of9doxevent_code_counts_before_after_first_met WHERE time_relative = 'AFTER'
) x
LEFT JOIN a9of9doxevent_code_timing_summary ts
 ON x.time_window = 'all'
 AND x.anchor_event = ts.anchor_event
 AND x.event_family = ts.event_family
 AND x.concept_id = ts.concept_id
LEFT JOIN a9of9doxevent_code_timing_before_after_summary tba
 ON x.time_window != 'all'
 AND x.anchor_event = tba.anchor_event
 AND x.event_family = tba.event_family
 AND x.concept_id = tba.concept_id
 AND ((x.time_window = 'before' AND tba.time_relative = 'BEFORE')
 OR (x.time_window = 'after' AND tba.time_relative = 'AFTER'))
ORDER BY x.time_window, x.anchor_event, x.event_family, x.n_patients DESC, x.n_records DESC, x.concept_id
;
WITH dx_met_base  AS (SELECT YEAR(index_date) AS index_year_int,
 CASE
 WHEN first_met_date IS NULL THEN  CAST('NO_EVENT' as STRING) WHEN days_dx_to_met < -90 THEN 'BEFORE_GT90'
 WHEN days_dx_to_met < 0 THEN 'BEFORE_1_90'
 WHEN days_dx_to_met = 0 THEN 'SAME_DAY'
 WHEN days_dx_to_met <= 30 THEN 'AFTER_1_30'
 WHEN days_dx_to_met <= 90 THEN 'AFTER_31_90'
 WHEN days_dx_to_met <= 365 THEN 'AFTER_91_365'
 ELSE 'AFTER_GT365'
 END AS direction
 FROM a9of9doxpatient_char
),
dx_l01_base AS (
 SELECT
 YEAR(index_date) AS index_year_int,
 CASE
 WHEN first_l01_date IS NULL THEN 'NO_EVENT'
 WHEN days_dx_to_l01 < -90 THEN 'BEFORE_GT90'
 WHEN days_dx_to_l01 < 0 THEN 'BEFORE_1_90'
 WHEN days_dx_to_l01 = 0 THEN 'SAME_DAY'
 WHEN days_dx_to_l01 <= 30 THEN 'AFTER_1_30'
 WHEN days_dx_to_l01 <= 90 THEN 'AFTER_31_90'
 WHEN days_dx_to_l01 <= 365 THEN 'AFTER_91_365'
 ELSE 'AFTER_GT365'
 END AS direction
 FROM a9of9doxpatient_char
),
met_l01_base AS (
 SELECT
 YEAR(first_met_date) AS index_year_int,
 CASE
 WHEN first_l01_date IS NULL THEN 'NO_EVENT'
 WHEN days_met_to_l01 < -90 THEN 'BEFORE_GT90'
 WHEN days_met_to_l01 < 0 THEN 'BEFORE_1_90'
 WHEN days_met_to_l01 = 0 THEN 'SAME_DAY'
 WHEN days_met_to_l01 <= 30 THEN 'AFTER_1_30'
 WHEN days_met_to_l01 <= 90 THEN 'AFTER_31_90'
 WHEN days_met_to_l01 <= 365 THEN 'AFTER_91_365'
 ELSE 'AFTER_GT365'
 END AS direction
 FROM a9of9doxpatient_char
 WHERE first_met_date IS NOT NULL
)
SELECT
 x.pair,
 x.index_year,
 x.direction,
 CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE x.n_patients END AS n_patients
FROM (
 -- DX -> MET: OVERALL
 SELECT 'DX_MET' AS pair, 'OVERALL' AS index_year, direction, COUNT(*) AS n_patients
 FROM dx_met_base
 GROUP BY direction
 UNION ALL
 -- DX -> MET: by DX year
 SELECT 'DX_MET' AS pair, CAST(index_year_int AS STRING) AS index_year, direction, COUNT(*) AS n_patients
 FROM dx_met_base
 GROUP BY index_year_int, direction
 UNION ALL
 -- DX -> L01: OVERALL
 SELECT 'DX_L01' AS pair, 'OVERALL' AS index_year, direction, COUNT(*) AS n_patients
 FROM dx_l01_base
 GROUP BY direction
 UNION ALL
 -- DX -> L01: by DX year
 SELECT 'DX_L01' AS pair, CAST(index_year_int AS STRING) AS index_year, direction, COUNT(*) AS n_patients
 FROM dx_l01_base
 GROUP BY index_year_int, direction
 UNION ALL
 -- MET -> L01: OVERALL
 SELECT 'MET_L01' AS pair, 'OVERALL' AS index_year, direction, COUNT(*) AS n_patients
 FROM met_l01_base
 GROUP BY direction
 UNION ALL
 -- MET -> L01: by MET year
 SELECT 'MET_L01' AS pair, CAST(index_year_int AS STRING) AS index_year, direction, COUNT(*) AS n_patients
 FROM met_l01_base
 GROUP BY index_year_int, direction
) x
ORDER BY
 x.pair,
 CASE WHEN x.index_year = 'OVERALL' THEN 0 ELSE 1 END,
 CASE WHEN x.index_year = 'OVERALL' THEN NULL ELSE CAST(x.index_year AS INT) END,
 CASE x.direction
 WHEN 'BEFORE_GT90' THEN 1
 WHEN 'BEFORE_1_90' THEN 2
 WHEN 'SAME_DAY' THEN 3
 WHEN 'AFTER_1_30' THEN 4
 WHEN 'AFTER_31_90' THEN 5
 WHEN 'AFTER_91_365' THEN 6
 WHEN 'AFTER_GT365' THEN 7
 WHEN 'NO_EVENT' THEN 8
 ELSE 9
 END
;
SELECT
 x.timing_type,
 x.from_event,
 x.to_event,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN -@min_cell_count ELSE x.n_patients_with_pair END AS n_patients_with_pair,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p05_days END AS p05_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p10_days END AS p10_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p20_days END AS p20_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p25_days END AS p25_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p30_days END AS p30_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p40_days END AS p40_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p50_days END AS p50_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p60_days END AS p60_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p70_days END AS p70_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p75_days END AS p75_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p80_days END AS p80_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p90_days END AS p90_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p95_days END AS p95_days
FROM (
 SELECT 'first_to_first' AS timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days FROM a9of9doxtiming_pair_summary
 UNION ALL
 SELECT 'first_to_closest' AS timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days FROM a9of9doxtiming_pair_summary_first_to_closest
 UNION ALL
 SELECT 'first_to_closest_before' AS timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days FROM a9of9doxtiming_pair_summary_first_to_closest_before
 UNION ALL
 SELECT 'first_to_closest_after' AS timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days FROM a9of9doxtiming_pair_summary_first_to_closest_after
) x
ORDER BY x.timing_type, x.from_event, x.to_event
;
SELECT
 x.timing_type,
 x.index_year,
 x.from_event,
 x.to_event,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN -@min_cell_count ELSE x.n_patients_with_pair END AS n_patients_with_pair,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p25_days END AS p25_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p50_days END AS p50_days,
 CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p75_days END AS p75_days
FROM (
 -- first_to_first by anchor year
 SELECT
 'first_to_first' AS timing_type,
 CAST(index_year_int AS STRING) AS index_year,
 from_event,
 to_event,
 COUNT(*) AS n_patients_with_pair,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p25_days,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p50_days,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p75_days
 FROM (
 SELECT p.from_event, p.to_event, p.days_diff,
 CASE WHEN p.from_event = 'MET' THEN YEAR(ms.first_met_date) ELSE YEAR(pc.index_date) END AS index_year_int,
 ROW_NUMBER() OVER (PARTITION BY CASE WHEN p.from_event = 'MET' THEN YEAR(ms.first_met_date) ELSE YEAR(pc.index_date) END, p.from_event, p.to_event ORDER BY p.days_diff) AS rn,
 COUNT(*) OVER (PARTITION BY CASE WHEN p.from_event = 'MET' THEN YEAR(ms.first_met_date) ELSE YEAR(pc.index_date) END, p.from_event, p.to_event) AS cnt
 FROM a9of9doxpatient_timing_pairs p
 JOIN a9of9doxpatient_char pc ON p.person_id = pc.person_id
 LEFT JOIN a9of9doxmet_summary ms ON p.person_id = ms.person_id
 ) y
 GROUP BY index_year_int, from_event, to_event
 UNION ALL
 -- first_to_closest_after by anchor year (MET-anchored pairs use MET year)
 SELECT
 'first_to_closest_after' AS timing_type,
 CAST(index_year_int AS STRING) AS index_year,
 from_event,
 to_event,
 COUNT(*) AS n_patients_with_pair,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p25_days,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS DOUBLE) END) AS p50_days,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS DOUBLE) END) AS p75_days
 FROM (
 SELECT p.from_event, p.to_event, p.days_diff,
 CASE WHEN p.from_event = 'MET' THEN YEAR(ms.first_met_date) ELSE YEAR(pc.index_date) END AS index_year_int,
 ROW_NUMBER() OVER (PARTITION BY CASE WHEN p.from_event = 'MET' THEN YEAR(ms.first_met_date) ELSE YEAR(pc.index_date) END, p.from_event, p.to_event ORDER BY p.days_diff) AS rn,
 COUNT(*) OVER (PARTITION BY CASE WHEN p.from_event = 'MET' THEN YEAR(ms.first_met_date) ELSE YEAR(pc.index_date) END, p.from_event, p.to_event) AS cnt
 FROM a9of9doxpatient_timing_pairs_first_to_closest_after p
 JOIN a9of9doxpatient_char pc ON p.person_id = pc.person_id
 LEFT JOIN a9of9doxmet_summary ms ON p.person_id = ms.person_id
 ) y
 GROUP BY index_year_int, from_event, to_event
) x
ORDER BY
 x.timing_type,
 x.from_event,
 x.to_event,
 CAST(x.index_year AS INT)
;
WITH index_events  AS (SELECT  CAST('INDEX' as STRING) AS anchor_event, 'ODX' AS event_family, e.concept_id, e.person_id,
 DATEDIFF(DAY, c.index_date, e.event_date) AS days_from_anchor
 FROM a9of9doxother_dx_events e
 JOIN a9of9doxcohort c ON e.person_id = c.person_id
 UNION ALL
 SELECT 'INDEX' AS anchor_event, 'GDX' AS event_family, e.concept_id, e.person_id,
 DATEDIFF(DAY, c.index_date, e.event_date) AS days_from_anchor
 FROM a9of9doxgen_cancer_events e
 JOIN a9of9doxcohort c ON e.person_id = c.person_id
),
met_events AS (
 SELECT 'FIRST_MET' AS anchor_event, 'ODX' AS event_family, e.concept_id, e.person_id,
 DATEDIFF(DAY, ms.first_met_date, e.event_date) AS days_from_anchor
 FROM a9of9doxother_dx_events e
 JOIN a9of9doxcohort c ON e.person_id = c.person_id
 JOIN a9of9doxmet_summary ms ON ms.person_id = c.person_id
 WHERE ms.first_met_date IS NOT NULL
 UNION ALL
 SELECT 'FIRST_MET' AS anchor_event, 'GDX' AS event_family, e.concept_id, e.person_id,
 DATEDIFF(DAY, ms.first_met_date, e.event_date) AS days_from_anchor
 FROM a9of9doxgen_cancer_events e
 JOIN a9of9doxcohort c ON e.person_id = c.person_id
 JOIN a9of9doxmet_summary ms ON ms.person_id = c.person_id
 WHERE ms.first_met_date IS NOT NULL
),
all_events AS (
 SELECT * FROM index_events
 UNION ALL
 SELECT * FROM met_events
),
windowed AS (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 person_id,
 MAX(CASE WHEN days_from_anchor >= -30 AND days_from_anchor <= 30 THEN 1 ELSE 0 END) AS in_pm30d,
 MAX(CASE WHEN days_from_anchor >= -90 AND days_from_anchor <= 90 THEN 1 ELSE 0 END) AS in_pm90d,
 MAX(CASE WHEN days_from_anchor >= -180 AND days_from_anchor <= 180 THEN 1 ELSE 0 END) AS in_pm180d,
 MAX(CASE WHEN days_from_anchor >= -365 AND days_from_anchor <= 365 THEN 1 ELSE 0 END) AS in_pm1yr,
 MAX(CASE WHEN days_from_anchor < 0 THEN 1 ELSE 0 END) AS in_ever_before,
 MAX(CASE WHEN days_from_anchor >= 0 THEN 1 ELSE 0 END) AS in_ever_after,
 1 AS in_ever
 FROM all_events
 GROUP BY anchor_event, event_family, concept_id, person_id
),
agg AS (
 SELECT
 anchor_event,
 event_family,
 concept_id,
 COUNT(*) AS n_ever,
 SUM(in_pm30d) AS n_pm30d,
 SUM(in_pm90d) AS n_pm90d,
 SUM(in_pm180d) AS n_pm180d,
 SUM(in_pm1yr) AS n_pm1yr,
 SUM(in_ever_before) AS n_ever_before,
 SUM(in_ever_after) AS n_ever_after
 FROM windowed
 GROUP BY anchor_event, event_family, concept_id
)
SELECT
 a.anchor_event,
 a.event_family,
 a.concept_id,
 CASE WHEN a.n_ever > 0 AND a.n_ever <= @min_cell_count THEN -@min_cell_count ELSE a.n_ever END AS n_ever,
 CASE WHEN a.n_pm30d > 0 AND a.n_pm30d <= @min_cell_count THEN -@min_cell_count ELSE a.n_pm30d END AS n_pm30d,
 CASE WHEN a.n_pm90d > 0 AND a.n_pm90d <= @min_cell_count THEN -@min_cell_count ELSE a.n_pm90d END AS n_pm90d,
 CASE WHEN a.n_pm180d > 0 AND a.n_pm180d <= @min_cell_count THEN -@min_cell_count ELSE a.n_pm180d END AS n_pm180d,
 CASE WHEN a.n_pm1yr > 0 AND a.n_pm1yr <= @min_cell_count THEN -@min_cell_count ELSE a.n_pm1yr END AS n_pm1yr,
 CASE WHEN a.n_ever_before > 0 AND a.n_ever_before <= @min_cell_count THEN -@min_cell_count ELSE a.n_ever_before END AS n_ever_before,
 CASE WHEN a.n_ever_after > 0 AND a.n_ever_after <= @min_cell_count THEN -@min_cell_count ELSE a.n_ever_after END AS n_ever_after
FROM agg a
ORDER BY
 CASE WHEN a.anchor_event = 'INDEX' THEN 0 ELSE 1 END,
 a.event_family,
 a.n_ever DESC,
 a.concept_id
;
WITH window_bounds  AS (SELECT  CAST('INDEX' as STRING) AS anchor_event,
 c.person_id,
 c.index_date AS anchor_date,
 w.window_index
 FROM a9of9doxcohort c
 CROSS JOIN (
 SELECT -12 AS window_index UNION ALL SELECT -11 UNION ALL SELECT -10
 UNION ALL SELECT -9 UNION ALL SELECT -8 UNION ALL SELECT -7
 UNION ALL SELECT -6 UNION ALL SELECT -5 UNION ALL SELECT -4
 UNION ALL SELECT -3 UNION ALL SELECT -2 UNION ALL SELECT -1
 UNION ALL SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2
 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14
 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17
 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23
 UNION ALL SELECT 24 UNION ALL SELECT 25 UNION ALL SELECT 26
 UNION ALL SELECT 27 UNION ALL SELECT 28 UNION ALL SELECT 29
 UNION ALL SELECT 30 UNION ALL SELECT 31 UNION ALL SELECT 32
 UNION ALL SELECT 33 UNION ALL SELECT 34 UNION ALL SELECT 35
 UNION ALL SELECT 36 UNION ALL SELECT 37 UNION ALL SELECT 38
 UNION ALL SELECT 39 UNION ALL SELECT 40 UNION ALL SELECT 41
 UNION ALL SELECT 42 UNION ALL SELECT 43 UNION ALL SELECT 44
 UNION ALL SELECT 45 UNION ALL SELECT 46 UNION ALL SELECT 47
 ) w
 UNION ALL
 SELECT
 'FIRST_MET' AS anchor_event,
 ms.person_id,
 ms.first_met_date AS anchor_date,
 w.window_index
 FROM a9of9doxmet_summary ms
 CROSS JOIN (
 SELECT -6 AS window_index UNION ALL SELECT -5 UNION ALL SELECT -4
 UNION ALL SELECT -3 UNION ALL SELECT -2 UNION ALL SELECT -1
 UNION ALL SELECT 0 UNION ALL SELECT 1 UNION ALL SELECT 2
 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
 UNION ALL SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11
 UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14
 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17
 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
 UNION ALL SELECT 21 UNION ALL SELECT 22 UNION ALL SELECT 23
 ) w
 WHERE ms.first_met_date IS NOT NULL
),
-- Mark which patients have at least one L01 exposure in each window
window_l01 AS (
 SELECT
 wb.anchor_event,
 wb.person_id,
 wb.window_index,
 wb.anchor_date,
 MAX(
 CASE
 WHEN le.event_date >= DATEADD(DAY, 30 * wb.window_index, wb.anchor_date)
 AND le.event_date < DATEADD(DAY, 30 * (wb.window_index + 1), wb.anchor_date)
 THEN 1 ELSE 0
 END
 ) AS has_l01_in_window
 FROM window_bounds wb
 LEFT JOIN a9of9doxl01_events le
 ON wb.person_id = le.person_id
 GROUP BY wb.anchor_event, wb.person_id, wb.window_index, wb.anchor_date
),
-- Denominator: patients observed through the window midpoint
-- (anchor + 30*k + 15 days must be within at least one observation period)
window_denom AS (
 SELECT
 wb.anchor_event,
 wb.person_id,
 wb.window_index,
 wb.anchor_date,
 MAX(
 CASE
 WHEN op.observation_period_start_date <= DATEADD(DAY, 30 * wb.window_index + 15, wb.anchor_date)
 AND op.observation_period_end_date >= DATEADD(DAY, 30 * wb.window_index + 15, wb.anchor_date)
 THEN 1 ELSE 0
 END
 ) AS observed_at_midpoint
 FROM window_bounds wb
 LEFT JOIN @cdm_database_schema.observation_period op
 ON op.person_id = wb.person_id
 GROUP BY wb.anchor_event, wb.person_id, wb.window_index, wb.anchor_date
),
agg AS (
 SELECT
 wl.anchor_event,
 wl.window_index,
 COUNT(*) AS n_eligible,
 SUM(wd.observed_at_midpoint) AS n_observed,
 SUM(wl.has_l01_in_window) AS n_patients_with_l01
 FROM window_l01 wl
 JOIN window_denom wd
 ON wd.anchor_event = wl.anchor_event
 AND wd.person_id = wl.person_id
 AND wd.window_index = wl.window_index
 GROUP BY wl.anchor_event, wl.window_index
)
SELECT
 a.anchor_event,
 a.window_index,
 a.n_eligible,
 CASE WHEN a.n_observed <= @min_cell_count THEN -@min_cell_count ELSE a.n_observed END AS n_observed,
 CASE WHEN a.n_patients_with_l01 <= @min_cell_count THEN -@min_cell_count ELSE a.n_patients_with_l01 END AS n_patients_with_l01
FROM agg a
ORDER BY a.anchor_event, a.window_index
;
SELECT
 s.prevalence_year,
 s.anchor_event,
 CASE WHEN s.n_patients <= @min_cell_count THEN -@min_cell_count ELSE s.n_patients END AS n_patients,
 CASE
 WHEN s.n_patients <= @min_cell_count THEN -@min_cell_count
 WHEN s.n_deaths BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
 ELSE s.n_deaths
 END AS n_deaths,
 CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE s.n_deaths_in_obs END AS n_deaths_in_obs,
 CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE s.n_deaths_out_obs END AS n_deaths_out_obs,
 CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.lq_days END AS lq_days,
 CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.median_days END AS median_days,
 CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.uq_days END AS uq_days,
 CASE WHEN s.n_patients <= @min_cell_count THEN NULL ELSE f.lq_followup_days END AS lq_followup_days,
 CASE WHEN s.n_patients <= @min_cell_count THEN NULL ELSE f.median_followup_days END AS median_followup_days,
 CASE WHEN s.n_patients <= @min_cell_count THEN NULL ELSE f.uq_followup_days END AS uq_followup_days
FROM a9of9doxdeath_stratum_counts s
LEFT JOIN a9of9doxdeath_timing_quantiles q
 ON s.prevalence_year = q.prevalence_year
 AND s.anchor_event = q.anchor_event
LEFT JOIN a9of9doxfollowup_quantiles f
 ON s.prevalence_year = f.prevalence_year
 AND s.anchor_event = f.anchor_event
ORDER BY
 CASE WHEN s.prevalence_year = 'OVERALL' THEN 0 ELSE 1 END,
 CASE WHEN s.prevalence_year = 'OVERALL' THEN NULL ELSE CAST(s.prevalence_year AS INT) END,
 CASE WHEN s.anchor_event = 'INDEX' THEN 0 ELSE 1 END
;
WITH anchor_persons  AS (SELECT  CAST('INDEX' as STRING) AS anchor_event,
 c.person_id,
 c.index_date AS anchor_date
 FROM a9of9doxpatient_char c
 WHERE c.index_date IS NOT NULL
 UNION ALL
 SELECT
 'FIRST_MET' AS anchor_event,
 c.person_id,
 c.first_met_date AS anchor_date
 FROM a9of9doxpatient_char c
 WHERE c.first_met_date IS NOT NULL
),
base AS (
 SELECT
 a.anchor_event,
 a.person_id,
 a.anchor_date,
 p.gender_concept_id,
 p.birth_datetime,
 p.year_of_birth
 FROM anchor_persons a
 JOIN @cdm_database_schema.person p
 ON a.person_id = p.person_id
),
ages AS (
 SELECT
 anchor_event,
 person_id,
 gender_concept_id,
 CASE
 WHEN birth_datetime IS NOT NULL
 THEN DATEDIFF(DAY, IF(try_cast(birth_datetime  AS DATE) IS NULL, to_date(cast(birth_datetime  AS STRING), 'yyyyMMdd'), try_cast(birth_datetime  AS DATE)), anchor_date) / 365.25
 WHEN year_of_birth IS NOT NULL
 THEN DATEDIFF(DAY, to_date(cast(year_of_birth as string) || '-' || cast(7 as string) || '-' || cast(1 as string)), anchor_date) / 365.25
 ELSE NULL
 END AS age_years
 FROM base
)
SELECT
 agg.anchor_event,
 agg.n_patients,
 agg.n_male,
 agg.n_female,
 agg.pct_male,
 agg.pct_female,
 p.age_lq_years,
 p.age_median_years,
 p.age_uq_years
FROM (
 SELECT
 anchor_event,
 COUNT(*) AS n_patients,
 SUM(CASE WHEN gender_concept_id = 8507 THEN 1 ELSE 0 END) AS n_male,
 SUM(CASE WHEN gender_concept_id = 8532 THEN 1 ELSE 0 END) AS n_female,
 CAST(100.0 * SUM(CASE WHEN gender_concept_id = 8507 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DOUBLE) AS pct_male,
 CAST(100.0 * SUM(CASE WHEN gender_concept_id = 8532 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DOUBLE) AS pct_female
 FROM ages
 WHERE age_years IS NOT NULL
 GROUP BY anchor_event
) agg
JOIN (
 SELECT
 anchor_event,
 MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(age_years AS DOUBLE) END) AS age_lq_years,
 MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(age_years AS DOUBLE) END) AS age_median_years,
 MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(age_years AS DOUBLE) END) AS age_uq_years
 FROM (
 SELECT anchor_event, age_years,
 ROW_NUMBER() OVER (PARTITION BY anchor_event ORDER BY age_years) AS rn,
 COUNT(*) OVER (PARTITION BY anchor_event) AS cnt
 FROM ages
 WHERE age_years IS NOT NULL
 ) y
 GROUP BY anchor_event
) p
 ON agg.anchor_event = p.anchor_event
ORDER BY CASE WHEN agg.anchor_event = 'INDEX' THEN 0 ELSE 1 END
;
WITH dx_days AS (
 SELECT DISTINCT
 person_id,
 event_date,
 concept_id
 FROM a9of9doxdx_events
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
ORDER BY s.n_distinct_patients DESC, s.concept_id
;
SELECT
 subgroup,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count ELSE COUNT(*) END AS n_gaps,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count ELSE COUNT(DISTINCT person_id) END AS n_patients_with_gaps,
 MIN(CASE WHEN cnt > @min_cell_count AND 10.0 * rn >= cnt THEN CAST(gap_days AS DOUBLE) END) AS p10_days,
 MIN(CASE WHEN cnt > @min_cell_count AND 4.0 * rn >= cnt THEN CAST(gap_days AS DOUBLE) END) AS p25_days,
 MIN(CASE WHEN cnt > @min_cell_count AND 2.0 * rn >= cnt THEN CAST(gap_days AS DOUBLE) END) AS p50_days,
 MIN(CASE WHEN cnt > @min_cell_count AND 4.0 * rn >= 3 * cnt THEN CAST(gap_days AS DOUBLE) END) AS p75_days,
 MIN(CASE WHEN cnt > @min_cell_count AND 10.0 * rn >= 9 * cnt THEN CAST(gap_days AS DOUBLE) END) AS p90_days
FROM (
 SELECT subgroup, person_id, gap_days,
 ROW_NUMBER() OVER (PARTITION BY subgroup ORDER BY gap_days) AS rn,
 COUNT(*) OVER (PARTITION BY subgroup) AS cnt
 FROM a9of9doxl01_consecutive_gaps
) x
GROUP BY subgroup
ORDER BY subgroup
;
SELECT
 subgroup,
 CASE
 WHEN gap_days < 30 THEN 'lt30d'
 WHEN gap_days < 60 THEN '30_59d'
 WHEN gap_days < 90 THEN '60_89d'
 WHEN gap_days < 180 THEN '90_179d'
 WHEN gap_days < 365 THEN '180_364d'
 ELSE 'ge365d'
 END AS gap_bucket,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count ELSE COUNT(*) END AS n_gaps
FROM a9of9doxl01_consecutive_gaps
GROUP BY
 subgroup,
 CASE
 WHEN gap_days < 30 THEN 'lt30d'
 WHEN gap_days < 60 THEN '30_59d'
 WHEN gap_days < 90 THEN '60_89d'
 WHEN gap_days < 180 THEN '90_179d'
 WHEN gap_days < 365 THEN '180_364d'
 ELSE 'ge365d'
 END
ORDER BY
 subgroup,
 MIN(CASE
 WHEN gap_days < 30 THEN 1
 WHEN gap_days < 60 THEN 2
 WHEN gap_days < 90 THEN 3
 WHEN gap_days < 180 THEN 4
 WHEN gap_days < 365 THEN 5
 ELSE 6
 END)
;
WITH patient_obs AS (
 SELECT
 person_id,
 MIN(observation_period_start_date) AS first_obs_start,
 MAX(observation_period_end_date) AS last_obs_end
 FROM @cdm_database_schema.observation_period
 WHERE person_id IN (SELECT person_id FROM a9of9doxcohort)
 GROUP BY person_id
),
death_obs_gaps AS (
 SELECT
 c.person_id,
 c.index_date,
 ms.first_met_date,
 dos.death_date,
 po.first_obs_start,
 po.last_obs_end,
 CASE
 WHEN dos.death_date > po.last_obs_end
 THEN DATEDIFF(DAY, po.last_obs_end, dos.death_date)
 ELSE NULL
 END AS gap_death_after_obs,
 CASE
 WHEN dos.death_date < po.first_obs_start
 THEN 1
 ELSE 0
 END AS death_before_obs
 FROM a9of9doxcohort c
 INNER JOIN a9of9doxdeath_obs_status dos ON dos.person_id = c.person_id
 LEFT JOIN a9of9doxmet_summary ms ON ms.person_id = c.person_id
 LEFT JOIN patient_obs po ON po.person_id = c.person_id
)
SELECT
 anchor_event,
 CASE WHEN n_death_before_obs > 0 AND n_death_before_obs <= @min_cell_count THEN -@min_cell_count ELSE n_death_before_obs END AS n_death_before_obs,
 CASE WHEN n_death_after_obs > 0 AND n_death_after_obs <= @min_cell_count THEN -@min_cell_count ELSE n_death_after_obs END AS n_death_after_obs,
 CASE WHEN n_death_after_obs > 0 AND n_death_after_obs <= @min_cell_count THEN NULL ELSE lq_gap_days END AS lq_gap_days,
 CASE WHEN n_death_after_obs > 0 AND n_death_after_obs <= @min_cell_count THEN NULL ELSE median_gap_days END AS median_gap_days,
 CASE WHEN n_death_after_obs > 0 AND n_death_after_obs <= @min_cell_count THEN NULL ELSE uq_gap_days END AS uq_gap_days,
 CASE WHEN n_death_after_obs > 0 AND n_death_after_obs <= @min_cell_count THEN NULL ELSE p90_gap_days END AS p90_gap_days
FROM (
 SELECT
 'INDEX' AS anchor_event,
 SUM(CASE WHEN death_before_obs = 1 THEN 1 ELSE 0 END) AS n_death_before_obs,
 SUM(CASE WHEN gap_death_after_obs IS NOT NULL THEN 1 ELSE 0 END) AS n_death_after_obs,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 4.0 * rn >= non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS lq_gap_days,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 2.0 * rn >= non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS median_gap_days,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 4.0 * rn >= 3 * non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS uq_gap_days,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 10.0 * rn >= 9 * non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS p90_gap_days
 FROM (
 SELECT death_before_obs, gap_death_after_obs,
 ROW_NUMBER() OVER (ORDER BY gap_death_after_obs) AS rn,
 SUM(CASE WHEN gap_death_after_obs IS NOT NULL THEN 1 ELSE 0 END) OVER () AS non_null_cnt
 FROM death_obs_gaps
 WHERE death_date IS NOT NULL
 ) x
 UNION ALL
 SELECT
 'FIRST_MET' AS anchor_event,
 SUM(CASE WHEN death_before_obs = 1 THEN 1 ELSE 0 END) AS n_death_before_obs,
 SUM(CASE WHEN gap_death_after_obs IS NOT NULL THEN 1 ELSE 0 END) AS n_death_after_obs,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 4.0 * rn >= non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS lq_gap_days,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 2.0 * rn >= non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS median_gap_days,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 4.0 * rn >= 3 * non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS uq_gap_days,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 10.0 * rn >= 9 * non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS p90_gap_days
 FROM (
 SELECT death_before_obs, gap_death_after_obs,
 ROW_NUMBER() OVER (ORDER BY gap_death_after_obs) AS rn,
 SUM(CASE WHEN gap_death_after_obs IS NOT NULL THEN 1 ELSE 0 END) OVER () AS non_null_cnt
 FROM death_obs_gaps
 WHERE death_date IS NOT NULL
 AND first_met_date IS NOT NULL
 ) x
) agg
;
WITH patient_obs AS (
 SELECT
 person_id,
 MIN(observation_period_start_date) AS first_obs_start,
 MAX(observation_period_end_date) AS last_obs_end
 FROM @cdm_database_schema.observation_period
 WHERE person_id IN (SELECT person_id FROM a9of9doxcohort)
 GROUP BY person_id
),
death_obs_gaps AS (
 SELECT
 c.person_id,
 ms.first_met_date,
 CASE
 WHEN dos.death_date > po.last_obs_end
 THEN DATEDIFF(DAY, po.last_obs_end, dos.death_date)
 ELSE NULL
 END AS gap_death_after_obs
 FROM a9of9doxcohort c
 INNER JOIN a9of9doxdeath_obs_status dos ON dos.person_id = c.person_id
 LEFT JOIN a9of9doxmet_summary ms ON ms.person_id = c.person_id
 LEFT JOIN patient_obs po ON po.person_id = c.person_id
),
bucketed AS (
 SELECT
 person_id,
 first_met_date,
 CASE
 WHEN gap_death_after_obs < 30 THEN 'lt30d'
 WHEN gap_death_after_obs < 60 THEN '30_59d'
 WHEN gap_death_after_obs < 90 THEN '60_89d'
 WHEN gap_death_after_obs < 180 THEN '90_179d'
 WHEN gap_death_after_obs < 365 THEN '180_364d'
 WHEN gap_death_after_obs < 730 THEN '365_729d'
 ELSE 'ge730d'
 END AS gap_bucket,
 CASE
 WHEN gap_death_after_obs < 30 THEN 1
 WHEN gap_death_after_obs < 60 THEN 2
 WHEN gap_death_after_obs < 90 THEN 3
 WHEN gap_death_after_obs < 180 THEN 4
 WHEN gap_death_after_obs < 365 THEN 5
 WHEN gap_death_after_obs < 730 THEN 6
 ELSE 7
 END AS sort_key
 FROM death_obs_gaps
 WHERE gap_death_after_obs IS NOT NULL
)
SELECT anchor_event, gap_bucket, n_patients
FROM (
 SELECT 'INDEX' AS anchor_event, gap_bucket,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count ELSE COUNT(*) END AS n_patients,
 MIN(sort_key) AS sort_key
 FROM bucketed
 GROUP BY gap_bucket
 UNION ALL
 SELECT 'FIRST_MET' AS anchor_event, gap_bucket,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count ELSE COUNT(*) END AS n_patients,
 MIN(sort_key) AS sort_key
 FROM bucketed
 WHERE first_met_date IS NOT NULL
 GROUP BY gap_bucket
) x
ORDER BY
 CASE WHEN anchor_event = 'INDEX' THEN 0 ELSE 1 END,
 sort_key
;
SELECT
 subgroup,
 CASE
 WHEN n_days = 1 THEN '1'
 WHEN n_days <= 6 THEN '2_6'
 WHEN n_days <= 11 THEN '7_11'
 ELSE '12plus'
 END AS days_bucket,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count ELSE COUNT(*) END AS n_patients
FROM (
 SELECT e.person_id, COUNT(*) AS n_days, 'ALL_L01' AS subgroup
 FROM a9of9doxl01_event_days e
 GROUP BY e.person_id
 UNION ALL
 SELECT e.person_id, COUNT(*) AS n_days, 'MET_L01' AS subgroup
 FROM a9of9doxl01_event_days e
 JOIN a9of9doxmet_summary ms ON e.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
 GROUP BY e.person_id
) x
GROUP BY
 subgroup,
 CASE
 WHEN n_days = 1 THEN '1'
 WHEN n_days <= 6 THEN '2_6'
 WHEN n_days <= 11 THEN '7_11'
 ELSE '12plus'
 END
ORDER BY
 subgroup,
 MIN(n_days);
