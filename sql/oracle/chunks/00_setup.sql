-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : oracle
-- Translated     : 2026-05-07 11:44:39 BST
-- Source file    : sql/sql_server/chunks/00_setup.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (oracle) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

/*
============================================================
 OMOP Characterization - SQL Server Base (SqlRender-ready)
  v2: dual concept-level event-code timing (FIRST + CLOSEST)
============================================================
UC ANCHOR VARIANT
-----------------
DX anchor follows cohort_definitions/UC.json concept set id 7
("UC - Malignant neoplasm"), built from #dx_anchor_include / #dx_anchor_exclude
and @cdm_database_schema.concept_ancestor.
Purpose
-------
Same cohort and pairwise timing as `v1_sqlserver_base_uc_malignant_neoplasm.sql`, but **concept-level**
event code timing exports **both** rules in one run (no `@event_code_timing_uses_closest`):
  - **FIRST:** earliest `event_date` per (anchor, family, concept, patient) [within TIME_RELATIVE stratum when applicable].
  - **CLOSEST:** minimum |days_diff| to anchor, tie-break `event_date`.
Final CSV columns include `lq_days_first` / `median_days_first` / `uq_days_first` and
`lq_days_closest` / `median_days_closest` / `uq_days_closest`. Legacy `lq_days` / `median_days` / `uq_days`
duplicate the **FIRST** triple for backward compatibility with older report code.
How to use
----------
1) Set @cdm_database_schema (or render via SqlRender).
2) Set privacy threshold below (small-cell suppression).
3) Edit concept-set INSERT blocks at top.
4) Run in SQL Server (or render+translate with SqlRender for target DB).
5) Export result sets from final SELECT statements (10 in this file, including per-concept anchor DX patient / patient-day counts).
Cross-dialect / SqlRender
-------------------------
- **Parameters (render):** `@cdm_database_schema`, `@min_cell_count` only.
- **Portable patterns:** same as v1 (SMALLINT, ordered-set percentiles + DISTINCT, etc.).
- **Validate:** `Rscript scripts/validate_characterization_sqlrender.R data_characterization/sql_versions/v2_sqlserver_base_uc_malignant_neoplasm_dual_event_code_timing.sql`
*/
------------------------------------------------------------
-- PARAMETERS (SqlRender style)
------------------------------------------------------------
-- Example:
-- DECLARE @cdm_database_schema VARCHAR(100) = 'cdm';
------------------------------------------------------------
-- PRIVACY CONTROLS
------------------------------------------------------------
-- Suppress small cells <= this threshold in final outputs.
-- SqlRender parameter (set during render, e.g. min_cell_count = 0).
-- Do not declare @min_cell_count here because SqlRender inlines @tokens.
------------------------------------------------------------
-- A) ANCHOR DIAGNOSIS CONCEPTS (DX)
-- Anchor cohort = patients with any of these condition_concept_id values
-- Source: cohort_definitions/UC.json — ConceptSets id 7 "UC - Malignant neoplasm"
-- Expanded with concept_ancestor (includeDescendants / isExcluded match Atlas).
------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdx_anchor_include';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdx_anchor_include';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdx_anchor_include';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdx_anchor_include';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kdx_anchor_include (
    concept_id NUMBER(19) NOT NULL,
    include_descendants SMALLINT NOT NULL
);
INSERT ALL
INTO prnpim5kdx_anchor_include        (concept_id, include_descendants) VALUES (INTO prnpim5kdx_anchor_include      (concept_id, include_descendants) VALUES (INTO prnpim5kdx_anchor_include    (concept_id, include_descendants) VALUES (INTO prnpim5kdx_anchor_include  (concept_id, include_descendants) VALUES (197508, 1)
 INTO prnpim5kdx_anchor_include  (concept_id, include_descendants) VALUES (4181357, 1)
)
 INTO prnpim5kdx_anchor_include   (concept_id, include_descendants) VALUES (4177230, 1)
)
 INTO prnpim5kdx_anchor_include    (concept_id, include_descendants) VALUES (37163176, 1)
)
 INTO prnpim5kdx_anchor_include     (concept_id, include_descendants) VALUES (4178972, 1)
)
 INTO prnpim5kdx_anchor_include      (concept_id, include_descendants) VALUES (4091486, 0)
)
 INTO prnpim5kdx_anchor_include       (concept_id, include_descendants) VALUES (44501785, 0)
)
 INTO prnpim5kdx_anchor_include        (concept_id, include_descendants) VALUES (37110270, 1)
SELECT *   FROM DUAL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdx_anchor_exclude';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdx_anchor_exclude';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdx_anchor_exclude';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdx_anchor_exclude';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kdx_anchor_exclude (
    concept_id NUMBER(19) NOT NULL,
    include_descendants SMALLINT NOT NULL
);
INSERT ALL
INTO prnpim5kdx_anchor_exclude         (concept_id, include_descendants) VALUES (INTO prnpim5kdx_anchor_exclude       (concept_id, include_descendants) VALUES (INTO prnpim5kdx_anchor_exclude     (concept_id, include_descendants) VALUES (INTO prnpim5kdx_anchor_exclude   (concept_id, include_descendants) VALUES (4280899, 1)
 INTO prnpim5kdx_anchor_exclude  (concept_id, include_descendants) VALUES (4289374, 1)
)
 INTO prnpim5kdx_anchor_exclude   (concept_id, include_descendants) VALUES (4280900, 1)
)
 INTO prnpim5kdx_anchor_exclude    (concept_id, include_descendants) VALUES (4283614, 1)
)
 INTO prnpim5kdx_anchor_exclude     (concept_id, include_descendants) VALUES (4289097, 1)
)
 INTO prnpim5kdx_anchor_exclude      (concept_id, include_descendants) VALUES (4280901, 1)
)
 INTO prnpim5kdx_anchor_exclude       (concept_id, include_descendants) VALUES (4289376, 1)
)
 INTO prnpim5kdx_anchor_exclude        (concept_id, include_descendants) VALUES (4280897, 1)
)
 INTO prnpim5kdx_anchor_exclude         (concept_id, include_descendants) VALUES (4200889, 1)
SELECT *   FROM DUAL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdx_anchor_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdx_anchor_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdx_anchor_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdx_anchor_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kdx_anchor_concepts (
    concept_id NUMBER(19)
);
INSERT INTO prnpim5kdx_anchor_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM prnpim5kdx_anchor_include i
JOIN @cdm_database_schema.concept_ancestor ca
  ON ca.ancestor_concept_id = i.concept_id
 AND (i.include_descendants = 1 OR ca.descendant_concept_id = i.concept_id) ;
DELETE FROM prnpim5kdx_anchor_concepts
WHERE EXISTS (SELECT 1
    FROM prnpim5kdx_anchor_exclude e
    JOIN @cdm_database_schema.concept_ancestor ca
      ON ca.ancestor_concept_id = e.concept_id
     AND prnpim5kdx_anchor_concepts.concept_id = ca.descendant_concept_id
     AND (e.include_descendants = 1 OR ca.descendant_concept_id = e.concept_id)
 );
------------------------------------------------------------
-- B) OTHER GENERALIZED CANCER DX CONCEPTS (GDX)
-- Default: distinct ancestors of DX anchor concepts, excluding anchor DX concepts themselves,
-- but constrained to descendants of 443392 (Malignant neoplastic disease) to avoid overly-broad ancestors.
-- (concept_ancestor includes self-links; we only want broader/generalized codes).
------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kgen_cancer_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kgen_cancer_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kgen_cancer_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kgen_cancer_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kgen_cancer_concepts (
    concept_id NUMBER(19)
);
INSERT INTO prnpim5kgen_cancer_concepts (concept_id)
SELECT DISTINCT ca.ancestor_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN prnpim5kdx_anchor_concepts d
  ON ca.descendant_concept_id = d.concept_id
JOIN @cdm_database_schema.concept_ancestor malign
  ON malign.ancestor_concept_id = 443392
 AND malign.descendant_concept_id = ca.ancestor_concept_id
  WHERE NOT EXISTS (SELECT 1
    FROM prnpim5kdx_anchor_concepts dx
      WHERE dx.concept_id = ca.ancestor_concept_id
 )
 ;
------------------------------------------------------------
-- C) OTHER CANCER DIAGNOSIS CONCEPTS (ODX)
-- Default: descendants of 443392 excluding DX + GDX sets.
------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kother_dx_ancestor_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kother_dx_ancestor_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kother_dx_ancestor_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kother_dx_ancestor_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kother_dx_ancestor_concepts (
    ancestor_concept_id NUMBER(19)
);
-- EDIT THIS LIST
INSERT INTO prnpim5kother_dx_ancestor_concepts (ancestor_concept_id)
VALUES
    (443392) -- Malignant neoplastic disease
;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kother_dx_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kother_dx_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kother_dx_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kother_dx_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kother_dx_concepts (
    concept_id NUMBER(19)
);
INSERT INTO prnpim5kother_dx_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN prnpim5kother_dx_ancestor_concepts a
  ON ca.ancestor_concept_id = a.ancestor_concept_id
LEFT JOIN prnpim5kdx_anchor_concepts dx
  ON dx.concept_id = ca.descendant_concept_id
LEFT JOIN prnpim5kgen_cancer_concepts gdx
  ON gdx.concept_id = ca.descendant_concept_id
  WHERE dx.concept_id IS NULL
  AND gdx.concept_id IS NULL
 ;
------------------------------------------------------------
-- D) METASTASIS CONCEPTS (MEASUREMENT)
-- Define via ancestor IDs (descendants pulled from concept_ancestor)
------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kmet_ancestor_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kmet_ancestor_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kmet_ancestor_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kmet_ancestor_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kmet_ancestor_concepts (
    ancestor_concept_id NUMBER(19)
);
-- Default: concept set "Secondary malignancy" from cohort_definitions/Target_Cohort_2B.json
INSERT ALL
INTO prnpim5kmet_ancestor_concepts   (ancestor_concept_id) VALUES (1633308)
 INTO prnpim5kmet_ancestor_concepts  (ancestor_concept_id) VALUES (1635142)
)
 INTO prnpim5kmet_ancestor_concepts   (ancestor_concept_id) VALUES (36769180)
SELECT *   FROM DUAL;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kmet_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kmet_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kmet_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kmet_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kmet_concepts (
    concept_id NUMBER(19)
);
INSERT INTO prnpim5kmet_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN prnpim5kmet_ancestor_concepts a
  ON ca.ancestor_concept_id = a.ancestor_concept_id
 ;
------------------------------------------------------------
-- E) L01 TREATMENT CONCEPTS (DRUG_EXPOSURE)
------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_ancestor_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_ancestor_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_ancestor_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_ancestor_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kl01_ancestor_concepts (
    ancestor_concept_id NUMBER(19)
);
-- EDIT THIS LIST
INSERT INTO prnpim5kl01_ancestor_concepts (ancestor_concept_id)
VALUES
    (21601387)
;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_concepts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_concepts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kl01_concepts (
    concept_id NUMBER(19)
);
INSERT INTO prnpim5kl01_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN prnpim5kl01_ancestor_concepts a
  ON ca.ancestor_concept_id = a.ancestor_concept_id
 ;
------------------------------------------------------------
-- F) EVENT TABLES
------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdx_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdx_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdx_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdx_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kdx_events (
    person_id NUMBER(19),
    event_date DATE,
    concept_id NUMBER(19)
);
INSERT INTO prnpim5kdx_events (person_id, event_date, concept_id)
SELECT co.person_id,
    co.condition_start_date,
    co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN prnpim5kdx_anchor_concepts d
  ON co.condition_concept_id = d.concept_id
 ;
-- Distinct anchor cohort persons; limits later F) pulls to rows that downstream joins to #cohort use anyway.
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kanchor_person';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kanchor_person';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kanchor_person';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kanchor_person';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kanchor_person (
    person_id NUMBER(19)
);
INSERT INTO prnpim5kanchor_person (person_id)
SELECT DISTINCT person_id
FROM prnpim5kdx_events
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kother_dx_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kother_dx_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kother_dx_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kother_dx_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kother_dx_events (
    person_id NUMBER(19),
    event_date DATE,
    concept_id NUMBER(19)
);
INSERT INTO prnpim5kother_dx_events (person_id, event_date, concept_id)
SELECT co.person_id,
    co.condition_start_date,
    co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN prnpim5kanchor_person ap
  ON co.person_id = ap.person_id
JOIN prnpim5kother_dx_concepts d
  ON co.condition_concept_id = d.concept_id
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kgen_cancer_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kgen_cancer_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kgen_cancer_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kgen_cancer_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kgen_cancer_events (
    person_id NUMBER(19),
    event_date DATE,
    concept_id NUMBER(19)
);
INSERT INTO prnpim5kgen_cancer_events (person_id, event_date, concept_id)
SELECT co.person_id,
    co.condition_start_date,
    co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN prnpim5kanchor_person ap
  ON co.person_id = ap.person_id
JOIN prnpim5kgen_cancer_concepts g
  ON co.condition_concept_id = g.concept_id
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kmet_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kmet_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kmet_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kmet_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kmet_events (
    person_id NUMBER(19),
    event_date DATE,
    concept_id NUMBER(19)
);
INSERT INTO prnpim5kmet_events (person_id, event_date, concept_id)
SELECT m.person_id,
    m.measurement_date,
    m.measurement_concept_id
FROM @cdm_database_schema.measurement m
JOIN prnpim5kanchor_person ap
  ON m.person_id = ap.person_id
JOIN prnpim5kmet_concepts mc
  ON m.measurement_concept_id = mc.concept_id
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kl01_events (
    person_id NUMBER(19),
    event_date DATE,
    concept_id NUMBER(19)
);
INSERT INTO prnpim5kl01_events (person_id, event_date, concept_id)
SELECT de.person_id,
    de.drug_exposure_start_date,
    de.drug_concept_id
FROM @cdm_database_schema.drug_exposure de
JOIN prnpim5kanchor_person ap
  ON de.person_id = ap.person_id
JOIN prnpim5kl01_concepts l
  ON de.drug_concept_id = l.concept_id
 ;
-- Ingredient-level L01 events used for concept-level code counts/timing.
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_ingredient_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_ingredient_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_ingredient_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_ingredient_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kl01_ingredient_events (
    person_id NUMBER(19),
    event_date DATE,
    concept_id NUMBER(19)
);
INSERT INTO prnpim5kl01_ingredient_events (person_id, event_date, concept_id)
SELECT DISTINCT
    de.person_id,
    de.drug_exposure_start_date,
    ca.ancestor_concept_id
FROM @cdm_database_schema.drug_exposure de
JOIN prnpim5kanchor_person ap
  ON de.person_id = ap.person_id
JOIN prnpim5kl01_concepts l
  ON de.drug_concept_id = l.concept_id
JOIN @cdm_database_schema.concept_ancestor ca
  ON ca.descendant_concept_id = de.drug_concept_id
JOIN @cdm_database_schema.concept ing
  ON ing.concept_id = ca.ancestor_concept_id
 AND ing.concept_class_id = 'Ingredient'
 ;
------------------------------------------------------------
-- G) COHORT ANCHOR + SUMMARIES
------------------------------------------------------------
-- Track attrition: count all patients with a qualifying DX before the
-- obs-period filter so the report can show how many were excluded.
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kcohort_attrition';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kcohort_attrition';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kcohort_attrition';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kcohort_attrition';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kcohort_attrition (
    stage      VARCHAR(50),
    n_patients INT
);
INSERT INTO prnpim5kcohort_attrition (stage, n_patients)
SELECT 'dx_any', COUNT(DISTINCT person_id) FROM prnpim5kdx_events ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kcohort';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kcohort';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kcohort';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kcohort';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kcohort (
    person_id NUMBER(19),
    index_date DATE
);
-- Index date = earliest qualifying DX that falls within an observation period.
-- Patients with no obs-period-covered DX are excluded entirely.
INSERT INTO prnpim5kcohort (person_id, index_date)
SELECT dx.person_id,
    MIN(dx.event_date) AS index_date
FROM prnpim5kdx_events dx
INNER JOIN @cdm_database_schema.observation_period op
    ON  op.person_id = dx.person_id
    AND dx.event_date BETWEEN op.observation_period_start_date
                          AND op.observation_period_end_date
GROUP BY dx.person_id
 ;
INSERT INTO prnpim5kcohort_attrition (stage, n_patients)
SELECT 'dx_in_obs', COUNT(*) FROM prnpim5kcohort ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdx_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdx_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdx_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdx_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kdx_summary (
    person_id NUMBER(19),
    n_dx_records INT,
    n_dx_codes INT
);
INSERT INTO prnpim5kdx_summary (person_id, n_dx_records, n_dx_codes)
SELECT e.person_id,
    COUNT(*) AS n_dx_records,
    COUNT(DISTINCT e.concept_id) AS n_dx_codes
FROM prnpim5kdx_events e
JOIN prnpim5kcohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kother_dx_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kother_dx_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kother_dx_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kother_dx_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kother_dx_summary (
    person_id NUMBER(19),
    first_other_dx_date DATE,
    n_other_dx_records INT,
    n_other_dx_codes INT
);
INSERT INTO prnpim5kother_dx_summary (person_id, first_other_dx_date, n_other_dx_records, n_other_dx_codes)
SELECT e.person_id,
    MIN(e.event_date) AS first_other_dx_date,
    COUNT(*) AS n_other_dx_records,
    COUNT(DISTINCT e.concept_id) AS n_other_dx_codes
FROM prnpim5kother_dx_events e
JOIN prnpim5kcohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kgen_cancer_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kgen_cancer_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kgen_cancer_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kgen_cancer_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kgen_cancer_summary (
    person_id NUMBER(19),
    first_gen_cancer_date DATE,
    n_gen_cancer_records INT,
    n_gen_cancer_codes INT
);
INSERT INTO prnpim5kgen_cancer_summary (person_id, first_gen_cancer_date, n_gen_cancer_records, n_gen_cancer_codes)
SELECT e.person_id,
    MIN(e.event_date) AS first_gen_cancer_date,
    COUNT(*) AS n_gen_cancer_records,
    COUNT(DISTINCT e.concept_id) AS n_gen_cancer_codes
FROM prnpim5kgen_cancer_events e
JOIN prnpim5kcohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kmet_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kmet_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kmet_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kmet_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kmet_summary (
    person_id NUMBER(19),
    first_met_date DATE,
    n_met_records INT
);
INSERT INTO prnpim5kmet_summary (person_id, first_met_date, n_met_records)
SELECT e.person_id,
    MIN(e.event_date) AS first_met_date,
    COUNT(*) AS n_met_records
FROM prnpim5kmet_events e
JOIN prnpim5kcohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kl01_summary (
    person_id NUMBER(19),
    first_l01_date DATE,
    n_l01_exposures INT
);
INSERT INTO prnpim5kl01_summary (person_id, first_l01_date, n_l01_exposures)
SELECT e.person_id,
    MIN(e.event_date) AS first_l01_date,
    COUNT(*) AS n_l01_exposures
FROM prnpim5kl01_events e
JOIN prnpim5kcohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
 ;
-- H) EVENT CODE COUNTS (single table across event families)
------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_counts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_counts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_counts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_counts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kevent_code_counts (
    anchor_event VARCHAR(20), -- INDEX or FIRST_MET
    event_family VARCHAR(20),
    concept_id NUMBER(19),
    n_records INT,
    n_patients INT
);
INSERT INTO prnpim5kevent_code_counts (anchor_event, event_family, concept_id, n_records, n_patients)
SELECT 'INDEX', 'DX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM prnpim5kdx_events
    WHERE person_id IN (SELECT person_id FROM prnpim5kcohort )
GROUP BY concept_id
   UNION ALL
SELECT 'INDEX', 'ODX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM prnpim5kother_dx_events
    WHERE person_id IN (SELECT person_id FROM prnpim5kcohort )
GROUP BY concept_id
   UNION ALL
SELECT 'INDEX', 'GDX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM prnpim5kgen_cancer_events
    WHERE person_id IN (SELECT person_id FROM prnpim5kcohort )
GROUP BY concept_id
   UNION ALL
SELECT 'INDEX', 'MET', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM prnpim5kmet_events
    WHERE person_id IN (SELECT person_id FROM prnpim5kcohort )
GROUP BY concept_id
   UNION ALL
SELECT 'INDEX', 'L01', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM prnpim5kl01_ingredient_events
    WHERE person_id IN (SELECT person_id FROM prnpim5kcohort )
GROUP BY concept_id
   UNION ALL
SELECT 'FIRST_MET', 'DX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM prnpim5kdx_events e
JOIN prnpim5kmet_summary ms
  ON e.person_id = ms.person_id
    WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
   UNION ALL
SELECT 'FIRST_MET', 'ODX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM prnpim5kother_dx_events e
JOIN prnpim5kmet_summary ms
  ON e.person_id = ms.person_id
    WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
   UNION ALL
SELECT 'FIRST_MET', 'GDX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM prnpim5kgen_cancer_events e
JOIN prnpim5kmet_summary ms
  ON e.person_id = ms.person_id
    WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
   UNION ALL
SELECT 'FIRST_MET', 'MET', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM prnpim5kmet_events e
JOIN prnpim5kmet_summary ms
  ON e.person_id = ms.person_id
    WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
   UNION ALL
SELECT 'FIRST_MET', 'L01', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM prnpim5kl01_ingredient_events e
JOIN prnpim5kmet_summary ms
  ON e.person_id = ms.person_id
  WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
                   ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_counts_before_after';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_counts_before_after';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_counts_before_after';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_counts_before_after';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kevent_code_counts_before_after (
    anchor_event VARCHAR(20), -- INDEX
    event_family VARCHAR(20),
    time_relative VARCHAR(10), -- BEFORE or AFTER (relative to index_date)
    concept_id NUMBER(19),
    n_records INT,
    n_patients INT
);
INSERT INTO prnpim5kevent_code_counts_before_after (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
SELECT 'INDEX',
       'DX',
        CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER' END AS time_relative,
       e.concept_id,
        COUNT(*) AS n_records,
       COUNT(DISTINCT e.person_id) AS n_patients
FROM prnpim5kdx_events e
JOIN prnpim5kcohort c
  ON e.person_id = c.person_id
GROUP BY
    CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER'  END ,
    e.concept_id
  UNION ALL
SELECT 'INDEX',
       'ODX',
        CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
        COUNT(*) ,
       COUNT(DISTINCT e.person_id)
FROM prnpim5kother_dx_events e
JOIN prnpim5kcohort c
  ON e.person_id = c.person_id
GROUP BY
    CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER'  END ,
    e.concept_id
  UNION ALL
SELECT 'INDEX',
       'GDX',
        CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
        COUNT(*) ,
       COUNT(DISTINCT e.person_id)
FROM prnpim5kgen_cancer_events e
JOIN prnpim5kcohort c
  ON e.person_id = c.person_id
GROUP BY
    CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER'  END ,
    e.concept_id
  UNION ALL
SELECT 'INDEX',
       'MET',
        CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
        COUNT(*) ,
       COUNT(DISTINCT e.person_id)
FROM prnpim5kmet_events e
JOIN prnpim5kcohort c
  ON e.person_id = c.person_id
GROUP BY
    CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER'  END ,
    e.concept_id
  UNION ALL
SELECT 'INDEX',
       'L01',
        CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
        COUNT(*) ,
       COUNT(DISTINCT e.person_id)
FROM prnpim5kl01_ingredient_events e
JOIN prnpim5kcohort c
  ON e.person_id = c.person_id
GROUP BY CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER'  END ,
    e.concept_id
             GROUP BY 1 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_counts_before_after_first_met';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_counts_before_after_first_met';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_counts_before_after_first_met';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_counts_before_after_first_met';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kevent_code_counts_before_after_first_met (
    anchor_event VARCHAR(20), -- FIRST_MET
    event_family VARCHAR(20),
    time_relative VARCHAR(10), -- BEFORE or AFTER (relative to first_met_date)
    concept_id NUMBER(19),
    n_records INT,
    n_patients INT
);
INSERT INTO prnpim5kevent_code_counts_before_after_first_met (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
SELECT 'FIRST_MET',
       'DX',
        CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER' END AS time_relative,
       e.concept_id,
        COUNT(*) AS n_records,
       COUNT(DISTINCT e.person_id) AS n_patients
FROM prnpim5kdx_events e
JOIN prnpim5kmet_summary ms
  ON e.person_id = ms.person_id
    WHERE ms.first_met_date IS NOT NULL
GROUP BY
    CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER'  END ,
    e.concept_id
   UNION ALL
SELECT 'FIRST_MET',
       'ODX',
        CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
        COUNT(*) ,
       COUNT(DISTINCT e.person_id)
FROM prnpim5kother_dx_events e
JOIN prnpim5kmet_summary ms
  ON e.person_id = ms.person_id
    WHERE ms.first_met_date IS NOT NULL
GROUP BY
    CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER'  END ,
    e.concept_id
   UNION ALL
SELECT 'FIRST_MET',
       'GDX',
        CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
        COUNT(*) ,
       COUNT(DISTINCT e.person_id)
FROM prnpim5kgen_cancer_events e
JOIN prnpim5kmet_summary ms
  ON e.person_id = ms.person_id
    WHERE ms.first_met_date IS NOT NULL
GROUP BY
    CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER'  END ,
    e.concept_id
   UNION ALL
SELECT 'FIRST_MET',
       'MET',
        CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
        COUNT(*) ,
       COUNT(DISTINCT e.person_id)
FROM prnpim5kmet_events e
JOIN prnpim5kmet_summary ms
  ON e.person_id = ms.person_id
    WHERE ms.first_met_date IS NOT NULL
GROUP BY
    CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER'  END ,
    e.concept_id
   UNION ALL
SELECT 'FIRST_MET',
       'L01',
        CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
        COUNT(*) ,
       COUNT(DISTINCT e.person_id)
FROM prnpim5kl01_ingredient_events e
JOIN prnpim5kmet_summary ms
  ON e.person_id = ms.person_id
  WHERE ms.first_met_date IS NOT NULL
GROUP BY CASE WHEN CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)) < 0 THEN 'BEFORE' ELSE 'AFTER'  END ,
    e.concept_id
             GROUP BY 1 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_all_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_all_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_all_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_all_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kevent_code_all_events (
    anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    concept_id NUMBER(19),
    person_id NUMBER(19),
    days_diff INT,
    event_date DATE
);
INSERT INTO prnpim5kevent_code_all_events (
    anchor_event, event_family, concept_id, person_id, days_diff, event_date
)
SELECT 'INDEX' AS anchor_event, 'DX' AS event_family, e.concept_id, e.person_id, CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)) AS days_diff, e.event_date
FROM prnpim5kdx_events e
JOIN prnpim5kcohort c ON e.person_id = c.person_id
  UNION ALL
SELECT 'INDEX', 'ODX', e.concept_id, e.person_id, CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)), e.event_date
FROM prnpim5kother_dx_events e
JOIN prnpim5kcohort c ON e.person_id = c.person_id
  UNION ALL
SELECT 'INDEX', 'GDX', e.concept_id, e.person_id, CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)), e.event_date
FROM prnpim5kgen_cancer_events e
JOIN prnpim5kcohort c ON e.person_id = c.person_id
  UNION ALL
SELECT 'INDEX', 'MET', e.concept_id, e.person_id, CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)), e.event_date
FROM prnpim5kmet_events e
JOIN prnpim5kcohort c ON e.person_id = c.person_id
  UNION ALL
SELECT 'INDEX', 'L01', e.concept_id, e.person_id, CEIL(CAST(e.event_date AS DATE) - CAST(c.index_date AS DATE)), e.event_date
FROM prnpim5kl01_ingredient_events e
JOIN prnpim5kcohort c ON e.person_id = c.person_id
  UNION ALL
SELECT 'FIRST_MET', 'DX', e.concept_id, e.person_id, CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)), e.event_date
FROM prnpim5kdx_events e
JOIN prnpim5kmet_summary ms ON e.person_id = ms.person_id
                        WHERE ms.first_met_date IS NOT NULL
        UNION ALL
SELECT 'FIRST_MET', 'ODX', e.concept_id, e.person_id, CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)), e.event_date
FROM prnpim5kother_dx_events e
JOIN prnpim5kmet_summary ms ON e.person_id = ms.person_id
    WHERE ms.first_met_date IS NOT NULL
   UNION ALL
SELECT 'FIRST_MET', 'GDX', e.concept_id, e.person_id, CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)), e.event_date
FROM prnpim5kgen_cancer_events e
JOIN prnpim5kmet_summary ms ON e.person_id = ms.person_id
    WHERE ms.first_met_date IS NOT NULL
   UNION ALL
SELECT 'FIRST_MET', 'MET', e.concept_id, e.person_id, CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)), e.event_date
FROM prnpim5kmet_events e
JOIN prnpim5kmet_summary ms ON e.person_id = ms.person_id
    WHERE ms.first_met_date IS NOT NULL
   UNION ALL
SELECT 'FIRST_MET', 'L01', e.concept_id, e.person_id, CEIL(CAST(e.event_date AS DATE) - CAST(ms.first_met_date AS DATE)), e.event_date
FROM prnpim5kl01_ingredient_events e
JOIN prnpim5kmet_summary ms ON e.person_id = ms.person_id
  WHERE ms.first_met_date IS NOT NULL
                   ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_patient_chosen_first';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_patient_chosen_first';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_patient_chosen_first';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_patient_chosen_first';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kevent_code_patient_chosen_first (
    anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    concept_id NUMBER(19),
    person_id NUMBER(19),
    days_diff INT
);
INSERT INTO prnpim5kevent_code_patient_chosen_first (anchor_event, event_family, concept_id, person_id, days_diff)
SELECT anchor_event, event_family, concept_id, person_id, days_diff
FROM (SELECT anchor_event,
        event_family,
        concept_id,
        person_id,
        days_diff,
        ROW_NUMBER() OVER (
            PARTITION BY anchor_event, event_family, concept_id, person_id
            ORDER BY CEIL(CAST(event_date AS DATE) - CAST(TO_DATE('1900-01-01', 'YYYYMMDD') AS DATE)) ASC, event_date ASC
        ) AS rn
    FROM prnpim5kevent_code_all_events
 ) x
  WHERE rn = 1
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_patient_chosen_closest';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_patient_chosen_closest';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_patient_chosen_closest';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_patient_chosen_closest';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kevent_code_patient_chosen_closest (
    anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    concept_id NUMBER(19),
    person_id NUMBER(19),
    days_diff INT
);
INSERT INTO prnpim5kevent_code_patient_chosen_closest (anchor_event, event_family, concept_id, person_id, days_diff)
SELECT anchor_event, event_family, concept_id, person_id, days_diff
FROM (SELECT anchor_event,
        event_family,
        concept_id,
        person_id,
        days_diff,
        ROW_NUMBER() OVER (
            PARTITION BY anchor_event, event_family, concept_id, person_id
            ORDER BY ABS(days_diff) ASC, event_date ASC
        ) AS rn
    FROM prnpim5kevent_code_all_events
 ) x
  WHERE rn = 1
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_timing_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_timing_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_timing_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_timing_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kevent_code_timing_summary (
    anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    concept_id NUMBER(19),
    n_patients_with_code_timing INT,
    lq_days_first FLOAT,
    median_days_first FLOAT,
    uq_days_first FLOAT,
    lq_days_closest FLOAT,
    median_days_closest FLOAT,
    uq_days_closest FLOAT
);
INSERT INTO prnpim5kevent_code_timing_summary (
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
SELECT f.anchor_event,
    f.event_family,
    f.concept_id,
    f.n_patients_with_code_timing,
    f.lq_days_first,
    f.median_days_first,
    f.uq_days_first,
    k.lq_days_closest,
    k.median_days_closest,
    k.uq_days_closest
FROM (SELECT anchor_event,
        event_family,
        concept_id,
        COUNT(*) AS n_patients_with_code_timing,
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS lq_days_first,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS median_days_first,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS FLOAT) END) AS uq_days_first
    FROM (SELECT anchor_event, event_family, concept_id, days_diff,
            ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, concept_id ORDER BY days_diff) AS rn,
            COUNT(*)     OVER (PARTITION BY anchor_event, event_family, concept_id)                    AS cnt
        FROM prnpim5kevent_code_patient_chosen_first
     ) x
    GROUP BY anchor_event, event_family, concept_id
 ) f
INNER JOIN (SELECT anchor_event,
        event_family,
        concept_id,
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS lq_days_closest,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS median_days_closest,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS FLOAT) END) AS uq_days_closest
    FROM (SELECT anchor_event, event_family, concept_id, days_diff,
            ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, concept_id ORDER BY days_diff) AS rn,
            COUNT(*)     OVER (PARTITION BY anchor_event, event_family, concept_id)                    AS cnt
        FROM prnpim5kevent_code_patient_chosen_closest
     ) x
    GROUP BY anchor_event, event_family, concept_id
 ) k
  ON f.anchor_event = k.anchor_event
 AND f.event_family = k.event_family
 AND f.concept_id = k.concept_id
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_ba_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_ba_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_ba_events';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_ba_events';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kevent_code_ba_events (
    anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    time_relative VARCHAR(10),
    concept_id NUMBER(19),
    person_id NUMBER(19),
    days_diff INT,
    event_date DATE
);
INSERT INTO prnpim5kevent_code_ba_events (
    anchor_event, event_family, time_relative, concept_id, person_id, days_diff, event_date
)
SELECT anchor_event,
    event_family,
    CASE WHEN days_diff < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    concept_id,
    person_id,
    days_diff,
    event_date
FROM prnpim5kevent_code_all_events
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_patient_chosen_before_after_first';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_patient_chosen_before_after_first';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_patient_chosen_before_after_first';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_patient_chosen_before_after_first';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kevent_code_patient_chosen_before_after_first (
    anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    time_relative VARCHAR(10),
    concept_id NUMBER(19),
    person_id NUMBER(19),
    days_diff INT
);
INSERT INTO prnpim5kevent_code_patient_chosen_before_after_first (
    anchor_event, event_family, time_relative, concept_id, person_id, days_diff
)
SELECT anchor_event, event_family, time_relative, concept_id, person_id, days_diff
FROM (SELECT anchor_event,
        event_family,
        time_relative,
        concept_id,
        person_id,
        days_diff,
        ROW_NUMBER() OVER (
            PARTITION BY anchor_event, event_family, time_relative, concept_id, person_id
            ORDER BY CEIL(CAST(event_date AS DATE) - CAST(TO_DATE('1900-01-01', 'YYYYMMDD') AS DATE)) ASC, event_date ASC
        ) AS rn
    FROM prnpim5kevent_code_ba_events
 ) x
  WHERE rn = 1
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_patient_chosen_before_after_closest';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_patient_chosen_before_after_closest';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_patient_chosen_before_after_closest';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_patient_chosen_before_after_closest';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kevent_code_patient_chosen_before_after_closest (
    anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    time_relative VARCHAR(10),
    concept_id NUMBER(19),
    person_id NUMBER(19),
    days_diff INT
);
INSERT INTO prnpim5kevent_code_patient_chosen_before_after_closest (
    anchor_event, event_family, time_relative, concept_id, person_id, days_diff
)
SELECT anchor_event, event_family, time_relative, concept_id, person_id, days_diff
FROM (SELECT anchor_event,
        event_family,
        time_relative,
        concept_id,
        person_id,
        days_diff,
        ROW_NUMBER() OVER (
            PARTITION BY anchor_event, event_family, time_relative, concept_id, person_id
            ORDER BY ABS(days_diff) ASC, event_date ASC
        ) AS rn
    FROM prnpim5kevent_code_ba_events
 ) x
  WHERE rn = 1
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_timing_before_after_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_timing_before_after_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_code_timing_before_after_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_code_timing_before_after_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kevent_code_timing_before_after_summary (
    anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    time_relative VARCHAR(10),
    concept_id NUMBER(19),
    n_patients_with_code_timing INT,
    lq_days_first FLOAT,
    median_days_first FLOAT,
    uq_days_first FLOAT,
    lq_days_closest FLOAT,
    median_days_closest FLOAT,
    uq_days_closest FLOAT
);
INSERT INTO prnpim5kevent_code_timing_before_after_summary (
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
SELECT f.anchor_event,
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
FROM (SELECT anchor_event,
        event_family,
        time_relative,
        concept_id,
        COUNT(*) AS n_patients_with_code_timing,
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS lq_days_first,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS median_days_first,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS FLOAT) END) AS uq_days_first
    FROM (SELECT anchor_event, event_family, time_relative, concept_id, days_diff,
            ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, time_relative, concept_id ORDER BY days_diff) AS rn,
            COUNT(*)     OVER (PARTITION BY anchor_event, event_family, time_relative, concept_id)                    AS cnt
        FROM prnpim5kevent_code_patient_chosen_before_after_first
     ) x
    GROUP BY anchor_event, event_family, time_relative, concept_id
 ) f
INNER JOIN (SELECT anchor_event,
        event_family,
        time_relative,
        concept_id,
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS lq_days_closest,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS median_days_closest,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS FLOAT) END) AS uq_days_closest
    FROM (SELECT anchor_event, event_family, time_relative, concept_id, days_diff,
            ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, time_relative, concept_id ORDER BY days_diff) AS rn,
            COUNT(*)     OVER (PARTITION BY anchor_event, event_family, time_relative, concept_id)                    AS cnt
        FROM prnpim5kevent_code_patient_chosen_before_after_closest
     ) x
    GROUP BY anchor_event, event_family, time_relative, concept_id
 ) k
  ON f.anchor_event = k.anchor_event
 AND f.event_family = k.event_family
 AND f.time_relative = k.time_relative
 AND f.concept_id = k.concept_id
 ;
------------------------------------------------------------
-- I) PATIENT-LEVEL TABLE
------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kpatient_char';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kpatient_char';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kpatient_char';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kpatient_char';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kpatient_char (
    person_id NUMBER(19),
    index_date DATE,
    n_dx_records INT,
    n_dx_codes INT,
    first_other_dx_date DATE,
    n_other_dx_records INT,
    n_other_dx_codes INT,
    first_gen_cancer_date DATE,
    n_gen_cancer_records INT,
    n_gen_cancer_codes INT,
    first_met_date DATE,
    n_met_records INT,
    first_l01_date DATE,
    n_l01_exposures INT,
    days_dx_to_met INT,
    days_dx_to_l01 INT,
    days_dx_to_other_dx INT,
    days_dx_to_gen_cancer INT,
    days_met_to_l01 INT
);
INSERT INTO prnpim5kpatient_char (
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
SELECT c.person_id,
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
    CASE WHEN mt.first_met_date IS NOT NULL THEN CEIL(CAST(mt.first_met_date AS DATE) - CAST(c.index_date AS DATE)) END AS days_dx_to_met,
    CASE WHEN l01.first_l01_date IS NOT NULL THEN CEIL(CAST(l01.first_l01_date AS DATE) - CAST(c.index_date AS DATE)) END AS days_dx_to_l01,
    CASE WHEN odx.first_other_dx_date IS NOT NULL THEN CEIL(CAST(odx.first_other_dx_date AS DATE) - CAST(c.index_date AS DATE)) END AS days_dx_to_other_dx,
    CASE WHEN gdx.first_gen_cancer_date IS NOT NULL THEN CEIL(CAST(gdx.first_gen_cancer_date AS DATE) - CAST(c.index_date AS DATE)) END AS days_dx_to_gen_cancer,
    CASE WHEN mt.first_met_date IS NOT NULL AND l01.first_l01_date IS NOT NULL THEN CEIL(CAST(l01.first_l01_date AS DATE) - CAST(mt.first_met_date AS DATE)) END AS days_met_to_l01
FROM prnpim5kcohort c
LEFT JOIN prnpim5kdx_summary dx
       ON c.person_id = dx.person_id
LEFT JOIN prnpim5kother_dx_summary odx
       ON c.person_id = odx.person_id
LEFT JOIN prnpim5kgen_cancer_summary gdx
       ON c.person_id = gdx.person_id
LEFT JOIN prnpim5kmet_summary mt
       ON c.person_id = mt.person_id
LEFT JOIN prnpim5kl01_summary l01
       ON c.person_id = l01.person_id
 ;
------------------------------------------------------------
-- J) FULL CROSSWISE TIMING PAIRS
------------------------------------------------------------
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kpatient_timing_pairs';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kpatient_timing_pairs';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kpatient_timing_pairs';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kpatient_timing_pairs';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kpatient_timing_pairs (
    person_id NUMBER(19),
    from_event VARCHAR(10),
    to_event VARCHAR(10),
    days_diff INT
);
INSERT INTO prnpim5kpatient_timing_pairs (person_id, from_event, to_event, days_diff)
 WITH events  AS (SELECT person_id, 'DX' AS event_name, index_date AS event_date FROM prnpim5kpatient_char
      UNION ALL
    SELECT person_id, 'ODX', first_other_dx_date FROM prnpim5kpatient_char
      UNION ALL
    SELECT person_id, 'GDX', first_gen_cancer_date FROM prnpim5kpatient_char
      UNION ALL
    SELECT person_id, 'MET', first_met_date FROM prnpim5kpatient_char
      UNION ALL
    SELECT person_id, 'L01', first_l01_date FROM prnpim5kpatient_char
 )
 SELECT e1.person_id,
    e1.event_name AS from_event,
    e2.event_name AS to_event,
    CEIL(CAST(e2.event_date AS DATE) - CAST(e1.event_date AS DATE)) AS days_diff
FROM events e1
JOIN events e2
  ON e1.person_id = e2.person_id
 AND e1.event_name <> e2.event_name
  WHERE e1.event_date IS NOT NULL
  AND e2.event_date IS NOT NULL
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5ktiming_pair_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5ktiming_pair_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5ktiming_pair_summary';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5ktiming_pair_summary';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5ktiming_pair_summary (
    from_event VARCHAR(10),
    to_event VARCHAR(10),
    n_patients_with_pair INT,
    p05_days FLOAT,
    p10_days FLOAT,
    p20_days FLOAT,
    p25_days FLOAT,
    p30_days FLOAT,
    p40_days FLOAT,
    p50_days FLOAT,
    p60_days FLOAT,
    p70_days FLOAT,
    p75_days FLOAT,
    p80_days FLOAT,
    p90_days FLOAT,
    p95_days FLOAT
);
INSERT INTO prnpim5ktiming_pair_summary (
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
SELECT from_event,
    to_event,
    COUNT(*) AS n_patients_with_pair,
    MIN(CASE WHEN 20.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p05_days,
    MIN(CASE WHEN 10.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p10_days,
    MIN(CASE WHEN  5.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p20_days,
    MIN(CASE WHEN  4.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p25_days,
    MIN(CASE WHEN 10.0 * rn >= 3 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p30_days,
    MIN(CASE WHEN  5.0 * rn >= 2 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p40_days,
    MIN(CASE WHEN  2.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p50_days,
    MIN(CASE WHEN  5.0 * rn >= 3 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p60_days,
    MIN(CASE WHEN 10.0 * rn >= 7 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p70_days,
    MIN(CASE WHEN  4.0 * rn >= 3 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p75_days,
    MIN(CASE WHEN  5.0 * rn >= 4 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p80_days,
    MIN(CASE WHEN 10.0 * rn >= 9 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p90_days,
    MIN(CASE WHEN 20.0 * rn >= 19 * cnt THEN CAST(days_diff AS FLOAT) END) AS p95_days
FROM (SELECT from_event, to_event, days_diff,
        ROW_NUMBER() OVER (PARTITION BY from_event, to_event ORDER BY days_diff) AS rn,
        COUNT(*)     OVER (PARTITION BY from_event, to_event)                    AS cnt
    FROM prnpim5kpatient_timing_pairs
 ) x
GROUP BY from_event, to_event
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kall_events_for_pairs';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kall_events_for_pairs';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kall_events_for_pairs';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kall_events_for_pairs';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kall_events_for_pairs (
    person_id NUMBER(19),
    event_family VARCHAR(10),
    event_date DATE
);
INSERT INTO prnpim5kall_events_for_pairs (person_id, event_family, event_date)
SELECT person_id, 'DX', event_date FROM prnpim5kdx_events
  UNION ALL
SELECT person_id, 'ODX', event_date FROM prnpim5kother_dx_events
  UNION ALL
SELECT person_id, 'GDX', event_date FROM prnpim5kgen_cancer_events
  UNION ALL
SELECT person_id, 'MET', event_date FROM prnpim5kmet_events
  UNION ALL
SELECT person_id, 'L01', event_date FROM prnpim5kl01_events
         ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kfirst_event_dates';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kfirst_event_dates';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kfirst_event_dates';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kfirst_event_dates';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kfirst_event_dates (
    person_id NUMBER(19),
    from_event VARCHAR(10),
    from_first_date DATE
);
INSERT INTO prnpim5kfirst_event_dates (person_id, from_event, from_first_date)
SELECT person_id, 'DX', index_date FROM prnpim5kpatient_char
  UNION ALL
SELECT person_id, 'ODX', first_other_dx_date FROM prnpim5kpatient_char         WHERE first_other_dx_date IS NOT NULL
    UNION ALL
SELECT person_id, 'GDX', first_gen_cancer_date FROM prnpim5kpatient_char     WHERE first_gen_cancer_date IS NOT NULL
   UNION ALL
SELECT person_id, 'MET', first_met_date FROM prnpim5kpatient_char     WHERE first_met_date IS NOT NULL
   UNION ALL
SELECT person_id, 'L01', first_l01_date FROM prnpim5kpatient_char   WHERE first_l01_date IS NOT NULL
         ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kpatient_timing_pairs_first_to_closest';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kpatient_timing_pairs_first_to_closest';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kpatient_timing_pairs_first_to_closest';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kpatient_timing_pairs_first_to_closest';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kpatient_timing_pairs_first_to_closest (
    person_id NUMBER(19),
    from_event VARCHAR(10),
    to_event VARCHAR(10),
    days_diff INT
);
INSERT INTO prnpim5kpatient_timing_pairs_first_to_closest (person_id, from_event, to_event, days_diff)
 WITH ranked  AS (SELECT f.person_id,
        f.from_event,
        a.event_family AS to_event,
        CEIL(CAST(a.event_date AS DATE) - CAST(f.from_first_date AS DATE)) AS days_diff,
        ROW_NUMBER() OVER (
            PARTITION BY f.person_id, f.from_event, a.event_family
            ORDER BY ABS(CEIL(CAST(a.event_date AS DATE) - CAST(f.from_first_date AS DATE))), a.event_date
        ) AS rn
    FROM prnpim5kfirst_event_dates f
    JOIN prnpim5kall_events_for_pairs a
      ON f.person_id = a.person_id
     AND f.from_event <> a.event_family
 )
 SELECT person_id,
    from_event,
    to_event,
    days_diff
FROM ranked
  WHERE rn = 1
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5ktiming_pair_summary_first_to_closest';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5ktiming_pair_summary_first_to_closest';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5ktiming_pair_summary_first_to_closest';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5ktiming_pair_summary_first_to_closest';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5ktiming_pair_summary_first_to_closest (
    from_event VARCHAR(10),
    to_event VARCHAR(10),
    n_patients_with_pair INT,
    p05_days FLOAT,
    p10_days FLOAT,
    p20_days FLOAT,
    p25_days FLOAT,
    p30_days FLOAT,
    p40_days FLOAT,
    p50_days FLOAT,
    p60_days FLOAT,
    p70_days FLOAT,
    p75_days FLOAT,
    p80_days FLOAT,
    p90_days FLOAT,
    p95_days FLOAT
);
INSERT INTO prnpim5ktiming_pair_summary_first_to_closest (
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
SELECT from_event,
    to_event,
    COUNT(*) AS n_patients_with_pair,
    MIN(CASE WHEN 20.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p05_days,
    MIN(CASE WHEN 10.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p10_days,
    MIN(CASE WHEN  5.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p20_days,
    MIN(CASE WHEN  4.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p25_days,
    MIN(CASE WHEN 10.0 * rn >= 3 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p30_days,
    MIN(CASE WHEN  5.0 * rn >= 2 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p40_days,
    MIN(CASE WHEN  2.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p50_days,
    MIN(CASE WHEN  5.0 * rn >= 3 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p60_days,
    MIN(CASE WHEN 10.0 * rn >= 7 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p70_days,
    MIN(CASE WHEN  4.0 * rn >= 3 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p75_days,
    MIN(CASE WHEN  5.0 * rn >= 4 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p80_days,
    MIN(CASE WHEN 10.0 * rn >= 9 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p90_days,
    MIN(CASE WHEN 20.0 * rn >= 19 * cnt THEN CAST(days_diff AS FLOAT) END) AS p95_days
FROM (SELECT from_event, to_event, days_diff,
        ROW_NUMBER() OVER (PARTITION BY from_event, to_event ORDER BY days_diff) AS rn,
        COUNT(*)     OVER (PARTITION BY from_event, to_event)                    AS cnt
    FROM prnpim5kpatient_timing_pairs_first_to_closest
 ) x
GROUP BY from_event, to_event
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kpatient_timing_pairs_first_to_closest_before';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kpatient_timing_pairs_first_to_closest_before';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kpatient_timing_pairs_first_to_closest_before';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kpatient_timing_pairs_first_to_closest_before';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kpatient_timing_pairs_first_to_closest_before (
    person_id NUMBER(19),
    from_event VARCHAR(10),
    to_event VARCHAR(10),
    days_diff INT
);
INSERT INTO prnpim5kpatient_timing_pairs_first_to_closest_before (person_id, from_event, to_event, days_diff)
 WITH ranked_before  AS (SELECT f.person_id,
        f.from_event,
        a.event_family AS to_event,
        CEIL(CAST(a.event_date AS DATE) - CAST(f.from_first_date AS DATE)) AS days_diff,
        ROW_NUMBER() OVER (
            PARTITION BY f.person_id, f.from_event, a.event_family
            ORDER BY ABS(CEIL(CAST(a.event_date AS DATE) - CAST(f.from_first_date AS DATE))), a.event_date DESC
        ) AS rn
    FROM prnpim5kfirst_event_dates f
    JOIN prnpim5kall_events_for_pairs a
      ON f.person_id = a.person_id
     AND f.from_event <> a.event_family
      WHERE CEIL(CAST(a.event_date AS DATE) - CAST(f.from_first_date AS DATE)) < 0
 )
 SELECT person_id,
    from_event,
    to_event,
    days_diff
FROM ranked_before
  WHERE rn = 1
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5ktiming_pair_summary_first_to_closest_before';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5ktiming_pair_summary_first_to_closest_before';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5ktiming_pair_summary_first_to_closest_before';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5ktiming_pair_summary_first_to_closest_before';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5ktiming_pair_summary_first_to_closest_before (
    from_event VARCHAR(10),
    to_event VARCHAR(10),
    n_patients_with_pair INT,
    p05_days FLOAT,
    p10_days FLOAT,
    p20_days FLOAT,
    p25_days FLOAT,
    p30_days FLOAT,
    p40_days FLOAT,
    p50_days FLOAT,
    p60_days FLOAT,
    p70_days FLOAT,
    p75_days FLOAT,
    p80_days FLOAT,
    p90_days FLOAT,
    p95_days FLOAT
);
INSERT INTO prnpim5ktiming_pair_summary_first_to_closest_before (
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
SELECT from_event,
    to_event,
    COUNT(*) AS n_patients_with_pair,
    MIN(CASE WHEN 20.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p05_days,
    MIN(CASE WHEN 10.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p10_days,
    MIN(CASE WHEN  5.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p20_days,
    MIN(CASE WHEN  4.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p25_days,
    MIN(CASE WHEN 10.0 * rn >= 3 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p30_days,
    MIN(CASE WHEN  5.0 * rn >= 2 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p40_days,
    MIN(CASE WHEN  2.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p50_days,
    MIN(CASE WHEN  5.0 * rn >= 3 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p60_days,
    MIN(CASE WHEN 10.0 * rn >= 7 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p70_days,
    MIN(CASE WHEN  4.0 * rn >= 3 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p75_days,
    MIN(CASE WHEN  5.0 * rn >= 4 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p80_days,
    MIN(CASE WHEN 10.0 * rn >= 9 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p90_days,
    MIN(CASE WHEN 20.0 * rn >= 19 * cnt THEN CAST(days_diff AS FLOAT) END) AS p95_days
FROM (SELECT from_event, to_event, days_diff,
        ROW_NUMBER() OVER (PARTITION BY from_event, to_event ORDER BY days_diff) AS rn,
        COUNT(*)     OVER (PARTITION BY from_event, to_event)                    AS cnt
    FROM prnpim5kpatient_timing_pairs_first_to_closest_before
 ) x
GROUP BY from_event, to_event
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kpatient_timing_pairs_first_to_closest_after';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kpatient_timing_pairs_first_to_closest_after';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kpatient_timing_pairs_first_to_closest_after';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kpatient_timing_pairs_first_to_closest_after';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kpatient_timing_pairs_first_to_closest_after (
    person_id NUMBER(19),
    from_event VARCHAR(10),
    to_event VARCHAR(10),
    days_diff INT
);
INSERT INTO prnpim5kpatient_timing_pairs_first_to_closest_after (person_id, from_event, to_event, days_diff)
 WITH ranked_after  AS (SELECT f.person_id,
        f.from_event,
        a.event_family AS to_event,
        CEIL(CAST(a.event_date AS DATE) - CAST(f.from_first_date AS DATE)) AS days_diff,
        ROW_NUMBER() OVER (
            PARTITION BY f.person_id, f.from_event, a.event_family
            ORDER BY CEIL(CAST(a.event_date AS DATE) - CAST(f.from_first_date AS DATE)), a.event_date
        ) AS rn
    FROM prnpim5kfirst_event_dates f
    JOIN prnpim5kall_events_for_pairs a
      ON f.person_id = a.person_id
     AND f.from_event <> a.event_family
      WHERE CEIL(CAST(a.event_date AS DATE) - CAST(f.from_first_date AS DATE)) >= 0
 )
 SELECT person_id,
    from_event,
    to_event,
    days_diff
FROM ranked_after
  WHERE rn = 1
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5ktiming_pair_summary_first_to_closest_after';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5ktiming_pair_summary_first_to_closest_after';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5ktiming_pair_summary_first_to_closest_after';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5ktiming_pair_summary_first_to_closest_after';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5ktiming_pair_summary_first_to_closest_after (
    from_event VARCHAR(10),
    to_event VARCHAR(10),
    n_patients_with_pair INT,
    p05_days FLOAT,
    p10_days FLOAT,
    p20_days FLOAT,
    p25_days FLOAT,
    p30_days FLOAT,
    p40_days FLOAT,
    p50_days FLOAT,
    p60_days FLOAT,
    p70_days FLOAT,
    p75_days FLOAT,
    p80_days FLOAT,
    p90_days FLOAT,
    p95_days FLOAT
);
INSERT INTO prnpim5ktiming_pair_summary_first_to_closest_after (
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
SELECT from_event,
    to_event,
    COUNT(*) AS n_patients_with_pair,
    MIN(CASE WHEN 20.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p05_days,
    MIN(CASE WHEN 10.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p10_days,
    MIN(CASE WHEN  5.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p20_days,
    MIN(CASE WHEN  4.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p25_days,
    MIN(CASE WHEN 10.0 * rn >= 3 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p30_days,
    MIN(CASE WHEN  5.0 * rn >= 2 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p40_days,
    MIN(CASE WHEN  2.0 * rn >= cnt       THEN CAST(days_diff AS FLOAT) END) AS p50_days,
    MIN(CASE WHEN  5.0 * rn >= 3 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p60_days,
    MIN(CASE WHEN 10.0 * rn >= 7 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p70_days,
    MIN(CASE WHEN  4.0 * rn >= 3 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p75_days,
    MIN(CASE WHEN  5.0 * rn >= 4 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p80_days,
    MIN(CASE WHEN 10.0 * rn >= 9 * cnt  THEN CAST(days_diff AS FLOAT) END) AS p90_days,
    MIN(CASE WHEN 20.0 * rn >= 19 * cnt THEN CAST(days_diff AS FLOAT) END) AS p95_days
FROM (SELECT from_event, to_event, days_diff,
        ROW_NUMBER() OVER (PARTITION BY from_event, to_event ORDER BY days_diff) AS rn,
        COUNT(*)     OVER (PARTITION BY from_event, to_event)                    AS cnt
    FROM prnpim5kpatient_timing_pairs_first_to_closest_after
 ) x
GROUP BY from_event, to_event
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_presence';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_presence';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kevent_presence';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kevent_presence';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kevent_presence (
    person_id NUMBER(19),
    has_dx INT,
    has_odx INT,
    has_gdx INT,
    has_met INT,
    has_l01 INT
);
INSERT INTO prnpim5kevent_presence (
    person_id, has_dx, has_odx, has_gdx, has_met, has_l01
)
SELECT person_id,
    1,
    CASE WHEN first_other_dx_date IS NOT NULL THEN 1 ELSE 0 END,
    CASE WHEN first_gen_cancer_date IS NOT NULL THEN 1 ELSE 0 END,
    CASE WHEN first_met_date IS NOT NULL THEN 1 ELSE 0 END,
    CASE WHEN first_l01_date IS NOT NULL THEN 1 ELSE 0 END
FROM prnpim5kpatient_char
 ;
------------------------------------------------------------
-- J-bis) DEATH TIMING FROM INDEX AND FIRST_MET ANCHORS
------------------------------------------------------------
-- Pre-compute each cohort patient's earliest death date and whether it
-- falls within any of their observation periods.
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdeath_obs_status';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdeath_obs_status';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdeath_obs_status';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdeath_obs_status';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kdeath_obs_status (
    person_id NUMBER(19),
    death_date DATE,
    death_in_obs SMALLINT
);
INSERT INTO prnpim5kdeath_obs_status (person_id, death_date, death_in_obs)
SELECT d.person_id,
    d.death_date,
    CASE WHEN EXISTS (SELECT 1
        FROM @cdm_database_schema.observation_period op
          WHERE op.person_id = d.person_id
          AND d.death_date BETWEEN op.observation_period_start_date
                               AND op.observation_period_end_date
     ) THEN 1 ELSE 0 END
FROM (SELECT person_id, MIN(death_date) AS death_date
    FROM @cdm_database_schema.death
    GROUP BY person_id
 ) d
  WHERE d.person_id IN (SELECT person_id FROM prnpim5kcohort )
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdeath_index_long';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdeath_index_long';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdeath_index_long';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdeath_index_long';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kdeath_index_long (
    prevalence_year VARCHAR(20),
    days_to_death INT
);
INSERT INTO prnpim5kdeath_index_long (prevalence_year, days_to_death)
SELECT 'OVERALL', CEIL(CAST(dos.death_date AS DATE) - CAST(c.index_date AS DATE))
FROM prnpim5kcohort c
INNER JOIN prnpim5kdeath_obs_status dos ON dos.person_id = c.person_id
    WHERE dos.death_date >= c.index_date
   UNION ALL
SELECT CAST(EXTRACT(YEAR FROM c.index_date) AS VARCHAR(4)), CEIL(CAST(dos.death_date AS DATE) - CAST(c.index_date AS DATE))
FROM prnpim5kcohort c
INNER JOIN prnpim5kdeath_obs_status dos ON dos.person_id = c.person_id
  WHERE dos.death_date >= c.index_date
   ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdeath_first_met_long';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdeath_first_met_long';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdeath_first_met_long';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdeath_first_met_long';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kdeath_first_met_long (
    prevalence_year VARCHAR(20),
    days_to_death INT
);
INSERT INTO prnpim5kdeath_first_met_long (prevalence_year, days_to_death)
SELECT 'OVERALL', CEIL(CAST(dos.death_date AS DATE) - CAST(ms.first_met_date AS DATE))
FROM prnpim5kcohort c
INNER JOIN prnpim5kmet_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN prnpim5kdeath_obs_status dos ON dos.person_id = c.person_id
    WHERE dos.death_date >= ms.first_met_date
   UNION ALL
SELECT CAST(EXTRACT(YEAR FROM ms.first_met_date) AS VARCHAR(4)), CEIL(CAST(dos.death_date AS DATE) - CAST(ms.first_met_date AS DATE))
FROM prnpim5kcohort c
INNER JOIN prnpim5kmet_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN prnpim5kdeath_obs_status dos ON dos.person_id = c.person_id
  WHERE dos.death_date >= ms.first_met_date
   ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdeath_stratum_counts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdeath_stratum_counts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdeath_stratum_counts';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdeath_stratum_counts';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kdeath_stratum_counts (
    prevalence_year VARCHAR(20),
    anchor_event VARCHAR(20),
    n_patients INT,
    n_deaths INT,
    n_deaths_in_obs INT,
    n_deaths_out_obs INT
);
INSERT INTO prnpim5kdeath_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths, n_deaths_in_obs, n_deaths_out_obs)
SELECT CASE
        WHEN GROUPING(EXTRACT(YEAR FROM c.index_date)) = 1 THEN 'OVERALL'
        ELSE CAST(EXTRACT(YEAR FROM c.index_date) AS VARCHAR(4))
    END,
    'INDEX',
    COUNT(*),
    SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= c.index_date THEN 1 ELSE 0 END),
    SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= c.index_date AND dos.death_in_obs = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= c.index_date AND dos.death_in_obs = 0 THEN 1 ELSE 0 END)
FROM prnpim5kcohort c
LEFT JOIN prnpim5kdeath_obs_status dos ON dos.person_id = c.person_id
GROUP BY GROUPING SETS ((), (EXTRACT(YEAR FROM c.index_date)))
 ;
INSERT INTO prnpim5kdeath_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths, n_deaths_in_obs, n_deaths_out_obs)
SELECT CASE
        WHEN GROUPING(EXTRACT(YEAR FROM ms.first_met_date)) = 1 THEN 'OVERALL'
        ELSE CAST(EXTRACT(YEAR FROM ms.first_met_date) AS VARCHAR(4))
    END,
    'FIRST_MET',
    COUNT(*),
    SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= ms.first_met_date THEN 1 ELSE 0 END),
    SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= ms.first_met_date AND dos.death_in_obs = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= ms.first_met_date AND dos.death_in_obs = 0 THEN 1 ELSE 0 END)
FROM prnpim5kcohort c
INNER JOIN prnpim5kmet_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
LEFT JOIN prnpim5kdeath_obs_status dos ON dos.person_id = c.person_id
GROUP BY GROUPING SETS ((), (EXTRACT(YEAR FROM ms.first_met_date)))
 ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdeath_timing_long';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdeath_timing_long';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdeath_timing_long';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdeath_timing_long';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kdeath_timing_long (
    prevalence_year VARCHAR(20),
    anchor_event VARCHAR(20),
    days_to_death INT
);
INSERT INTO prnpim5kdeath_timing_long (prevalence_year, anchor_event, days_to_death)
SELECT prevalence_year, 'INDEX', days_to_death FROM prnpim5kdeath_index_long
  UNION ALL
SELECT prevalence_year, 'FIRST_MET', days_to_death FROM prnpim5kdeath_first_met_long
   ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdeath_timing_quantiles';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdeath_timing_quantiles';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kdeath_timing_quantiles';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kdeath_timing_quantiles';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kdeath_timing_quantiles (
    prevalence_year VARCHAR(20),
    anchor_event VARCHAR(20),
    lq_days FLOAT,
    median_days FLOAT,
    uq_days FLOAT
);
INSERT INTO prnpim5kdeath_timing_quantiles (
    prevalence_year,
    anchor_event,
    lq_days,
    median_days,
    uq_days
)
SELECT prevalence_year,
    anchor_event,
    MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_to_death AS FLOAT) END) AS lq_days,
    MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_to_death AS FLOAT) END) AS median_days,
    MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_to_death AS FLOAT) END) AS uq_days
FROM (SELECT prevalence_year, anchor_event, days_to_death,
        ROW_NUMBER() OVER (PARTITION BY prevalence_year, anchor_event ORDER BY days_to_death) AS rn,
        COUNT(*)     OVER (PARTITION BY prevalence_year, anchor_event)                        AS cnt
    FROM prnpim5kdeath_timing_long
 ) x
GROUP BY prevalence_year, anchor_event
 ;
-- Follow-up duration from anchor date to last observation period end,
-- for all patients with at least one observation period covering or after anchor.
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kfollowup_long';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kfollowup_long';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kfollowup_long';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kfollowup_long';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kfollowup_long (
    prevalence_year VARCHAR(20),
    anchor_event VARCHAR(20),
    followup_days INT
);
INSERT INTO prnpim5kfollowup_long (prevalence_year, anchor_event, followup_days)
SELECT 'OVERALL', 'INDEX',
       CEIL(CAST(MAX(op.observation_period_end_date) AS DATE) - CAST(c.index_date AS DATE))
FROM prnpim5kcohort c
INNER JOIN @cdm_database_schema.observation_period op
  ON op.person_id = c.person_id
 AND op.observation_period_end_date >= c.index_date
GROUP BY c.person_id, c.index_date
  UNION ALL
SELECT CAST(EXTRACT(YEAR FROM c.index_date) AS VARCHAR(4)), 'INDEX',
       CEIL(CAST(MAX(op.observation_period_end_date) AS DATE) - CAST(c.index_date AS DATE))
FROM prnpim5kcohort c
INNER JOIN @cdm_database_schema.observation_period op
  ON op.person_id = c.person_id
 AND op.observation_period_end_date >= c.index_date
GROUP BY c.person_id, c.index_date, EXTRACT(YEAR FROM c.index_date)
  UNION ALL
SELECT 'OVERALL', 'FIRST_MET',
       CEIL(CAST(MAX(op.observation_period_end_date) AS DATE) - CAST(ms.first_met_date AS DATE))
FROM prnpim5kcohort c
INNER JOIN prnpim5kmet_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN @cdm_database_schema.observation_period op
  ON op.person_id = c.person_id
 AND op.observation_period_end_date >= ms.first_met_date
GROUP BY c.person_id, ms.first_met_date
  UNION ALL
SELECT CAST(EXTRACT(YEAR FROM ms.first_met_date) AS VARCHAR(4)), 'FIRST_MET',
       CEIL(CAST(MAX(op.observation_period_end_date) AS DATE) - CAST(ms.first_met_date AS DATE))
FROM prnpim5kcohort c
INNER JOIN prnpim5kmet_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN @cdm_database_schema.observation_period op
  ON op.person_id = c.person_id
 AND op.observation_period_end_date >= ms.first_met_date
GROUP BY c.person_id, ms.first_met_date, EXTRACT(YEAR FROM ms.first_met_date)
       ;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kfollowup_quantiles';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kfollowup_quantiles';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kfollowup_quantiles';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kfollowup_quantiles';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kfollowup_quantiles (
    prevalence_year VARCHAR(20),
    anchor_event VARCHAR(20),
    lq_followup_days FLOAT,
    median_followup_days FLOAT,
    uq_followup_days FLOAT
);
INSERT INTO prnpim5kfollowup_quantiles (
    prevalence_year,
    anchor_event,
    lq_followup_days,
    median_followup_days,
    uq_followup_days
)
SELECT prevalence_year,
    anchor_event,
    MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(followup_days AS FLOAT) END) AS lq_followup_days,
    MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(followup_days AS FLOAT) END) AS median_followup_days,
    MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(followup_days AS FLOAT) END) AS uq_followup_days
FROM (SELECT prevalence_year, anchor_event, followup_days,
        ROW_NUMBER() OVER (PARTITION BY prevalence_year, anchor_event ORDER BY followup_days) AS rn,
        COUNT(*)     OVER (PARTITION BY prevalence_year, anchor_event)                        AS cnt
    FROM prnpim5kfollowup_long
 ) x
GROUP BY prevalence_year, anchor_event
 ;
------------------------------------------------------------
-- L) L01 CONSECUTIVE GAP TABLES (used by chunks 11 and 12)
------------------------------------------------------------
-- Deduplicated L01 event days per patient (one row per patient-day)
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_event_days';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_event_days';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_event_days';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_event_days';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kl01_event_days (
    person_id  NUMBER(19),
    event_day  DATE
);
INSERT INTO prnpim5kl01_event_days (person_id, event_day)
SELECT DISTINCT person_id, event_date
FROM prnpim5kl01_events
  WHERE person_id IN (SELECT person_id FROM prnpim5kcohort )
 ;
-- Consecutive gaps between L01 event days per patient
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_consecutive_gaps';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_consecutive_gaps';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
BEGIN
  EXECUTE IMMEDIATE 'TRUNCATE TABLE prnpim5kl01_consecutive_gaps';
  EXECUTE IMMEDIATE 'DROP TABLE prnpim5kl01_consecutive_gaps';
EXCEPTION
  WHEN OTHERS THEN
    IF SQLCODE != -942 THEN
      RAISE;
    END IF;
END;
CREATE TABLE prnpim5kl01_consecutive_gaps (
    person_id  NUMBER(19),
    subgroup   VARCHAR(12),
    gap_days   INT
);
INSERT INTO prnpim5kl01_consecutive_gaps (person_id, subgroup, gap_days)
 WITH ranked  AS (SELECT e.person_id,
        e.event_day,
        LEAD(e.event_day) OVER (PARTITION BY e.person_id ORDER BY e.event_day) AS next_day
    FROM prnpim5kl01_event_days e
 ),
gaps AS (SELECT person_id,
        CEIL(CAST(next_day AS DATE) - CAST(event_day AS DATE)) AS gap_days
    FROM ranked
      WHERE next_day IS NOT NULL
 )
 SELECT g.person_id, 'ALL_L01', g.gap_days FROM gaps g
  UNION ALL
SELECT g.person_id, 'MET_L01', g.gap_days
FROM gaps g
JOIN prnpim5kmet_summary ms ON g.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
   ;
-- Max gap per patient (one row per patient; used for MAX-gap subgroups in chunks 11–12)
INSERT INTO prnpim5kl01_consecutive_gaps (person_id, subgroup, gap_days)
SELECT person_id, 'ALL_L01_MAX', MAX(gap_days)
FROM prnpim5kl01_consecutive_gaps
    WHERE subgroup = 'ALL_L01'
GROUP BY person_id
   UNION ALL
SELECT person_id, 'MET_L01_MAX', MAX(gap_days)
FROM prnpim5kl01_consecutive_gaps
  WHERE subgroup = 'MET_L01'
GROUP BY person_id
   ;
------------------------------------------------------------
-- K) FINAL SELECTS (export to CSV from SQL client)
------------------------------------------------------------

