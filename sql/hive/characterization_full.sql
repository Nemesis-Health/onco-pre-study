-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : hive
-- Translated     : 2026-05-07 06:29:50 BST
-- Source file    : sql/sql_server/characterization_full.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (hive) does not support native session
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
DROP TABLE IF EXISTS dx_anchor_include;
CREATE TEMPORARY TABLE IF NOT EXISTS dx_anchor_include  (concept_id BIGINT,
    include_descendants SMALLINT
);
INSERT INTO dx_anchor_include (concept_id, include_descendants) VALUES
    (197508, 1),      -- Malignant neoplasm of urinary bladder
    (4181357, 1),     -- Malignant tumor of renal pelvis
    (4177230, 1),     -- Malignant tumor of urethra
    (37163176, 1),    -- Transitional cell carcinoma of upper urinary tract
    (4178972, 1),     -- Malignant tumor of ureter
    (4091486, 0),     -- Malignant neoplasm of overlapping sites of urinary organs
    (44501785, 0),    -- Transitional cell carcinoma, NOS, of urinary system, NOS (ICDO3)
    (37110270, 1)     -- Primary urothelial carcinoma of overlapping sites of urinary organs
;
DROP TABLE IF EXISTS dx_anchor_exclude;
CREATE TEMPORARY TABLE IF NOT EXISTS dx_anchor_exclude  (concept_id BIGINT,
    include_descendants SMALLINT
);
INSERT INTO dx_anchor_exclude (concept_id, include_descendants) VALUES
    (4280899, 1),
    (4289374, 1),
    (4280900, 1),
    (4283614, 1),
    (4289097, 1),
    (4280901, 1),
    (4289376, 1),
    (4280897, 1),
    (4200889, 1);
DROP TABLE IF EXISTS dx_anchor_concepts;
CREATE TEMPORARY TABLE IF NOT EXISTS dx_anchor_concepts  (concept_id BIGINT
);
INSERT INTO dx_anchor_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM dx_anchor_include i
JOIN @cdm_database_schema.concept_ancestor ca
  ON ca.ancestor_concept_id = i.concept_id
 AND (i.include_descendants = 1 OR ca.descendant_concept_id = i.concept_id);
DELETE FROM dx_anchor_concepts
WHERE EXISTS (
    SELECT 1
    FROM dx_anchor_exclude e
    JOIN @cdm_database_schema.concept_ancestor ca
      ON ca.ancestor_concept_id = e.concept_id
     AND dx_anchor_concepts.concept_id = ca.descendant_concept_id
     AND (e.include_descendants = 1 OR ca.descendant_concept_id = e.concept_id)
);
------------------------------------------------------------
-- B) OTHER GENERALIZED CANCER DX CONCEPTS (GDX)
-- Default: distinct ancestors of DX anchor concepts, excluding anchor DX concepts themselves,
-- but constrained to descendants of 443392 (Malignant neoplastic disease) to avoid overly-broad ancestors.
-- (concept_ancestor includes self-links; we only want broader/generalized codes).
------------------------------------------------------------
DROP TABLE IF EXISTS gen_cancer_concepts;
CREATE TEMPORARY TABLE IF NOT EXISTS gen_cancer_concepts  (concept_id BIGINT
);
INSERT INTO gen_cancer_concepts (concept_id)
SELECT DISTINCT ca.ancestor_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN dx_anchor_concepts d
  ON ca.descendant_concept_id = d.concept_id
JOIN @cdm_database_schema.concept_ancestor malign
  ON malign.ancestor_concept_id = 443392
 AND malign.descendant_concept_id = ca.ancestor_concept_id
WHERE NOT EXISTS (
    SELECT 1
    FROM dx_anchor_concepts dx
    WHERE dx.concept_id = ca.ancestor_concept_id
)
;
------------------------------------------------------------
-- C) OTHER CANCER DIAGNOSIS CONCEPTS (ODX)
-- Default: descendants of 443392 excluding DX + GDX sets.
------------------------------------------------------------
DROP TABLE IF EXISTS other_dx_ancestor_concepts;
CREATE TEMPORARY TABLE IF NOT EXISTS other_dx_ancestor_concepts  (ancestor_concept_id BIGINT
);
-- EDIT THIS LIST
INSERT INTO other_dx_ancestor_concepts (ancestor_concept_id)
VALUES
    (443392) -- Malignant neoplastic disease
;
DROP TABLE IF EXISTS other_dx_concepts;
CREATE TEMPORARY TABLE IF NOT EXISTS other_dx_concepts  (concept_id BIGINT
);
INSERT INTO other_dx_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN other_dx_ancestor_concepts a
  ON ca.ancestor_concept_id = a.ancestor_concept_id
LEFT JOIN dx_anchor_concepts dx
  ON dx.concept_id = ca.descendant_concept_id
LEFT JOIN gen_cancer_concepts gdx
  ON gdx.concept_id = ca.descendant_concept_id
WHERE dx.concept_id IS NULL
  AND gdx.concept_id IS NULL
;
------------------------------------------------------------
-- D) METASTASIS CONCEPTS (MEASUREMENT)
-- Define via ancestor IDs (descendants pulled from concept_ancestor)
------------------------------------------------------------
DROP TABLE IF EXISTS met_ancestor_concepts;
CREATE TEMPORARY TABLE IF NOT EXISTS met_ancestor_concepts  (ancestor_concept_id BIGINT
);
-- Default: concept set "Secondary malignancy" from cohort_definitions/Target_Cohort_2B.json
INSERT INTO met_ancestor_concepts (ancestor_concept_id)
VALUES
    (1633308),  -- AJCC/UICC Stage 4
    (1635142),  -- AJCC/UICC M1 Category
    (36769180)  -- Metastasis
;
DROP TABLE IF EXISTS met_concepts;
CREATE TEMPORARY TABLE IF NOT EXISTS met_concepts  (concept_id BIGINT
);
INSERT INTO met_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN met_ancestor_concepts a
  ON ca.ancestor_concept_id = a.ancestor_concept_id
;
------------------------------------------------------------
-- E) L01 TREATMENT CONCEPTS (DRUG_EXPOSURE)
------------------------------------------------------------
DROP TABLE IF EXISTS l01_ancestor_concepts;
CREATE TEMPORARY TABLE IF NOT EXISTS l01_ancestor_concepts  (ancestor_concept_id BIGINT
);
-- EDIT THIS LIST
INSERT INTO l01_ancestor_concepts (ancestor_concept_id)
VALUES
    (21601387)
;
DROP TABLE IF EXISTS l01_concepts;
CREATE TEMPORARY TABLE IF NOT EXISTS l01_concepts  (concept_id BIGINT
);
INSERT INTO l01_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN l01_ancestor_concepts a
  ON ca.ancestor_concept_id = a.ancestor_concept_id
;
------------------------------------------------------------
-- F) EVENT TABLES
------------------------------------------------------------
DROP TABLE IF EXISTS dx_events;
CREATE TEMPORARY TABLE IF NOT EXISTS dx_events  (person_id BIGINT,
    event_date TIMESTAMP,
    concept_id BIGINT
);
INSERT INTO dx_events (person_id, event_date, concept_id)
SELECT
    co.person_id,
    co.condition_start_date,
    co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN dx_anchor_concepts d
  ON co.condition_concept_id = d.concept_id
;
-- Distinct anchor cohort persons; limits later F) pulls to rows that downstream joins to #cohort use anyway.
DROP TABLE IF EXISTS anchor_person;
CREATE TEMPORARY TABLE IF NOT EXISTS anchor_person  (person_id BIGINT
);
INSERT INTO anchor_person (person_id)
SELECT DISTINCT person_id
FROM dx_events
;
DROP TABLE IF EXISTS other_dx_events;
CREATE TEMPORARY TABLE IF NOT EXISTS other_dx_events  (person_id BIGINT,
    event_date TIMESTAMP,
    concept_id BIGINT
);
INSERT INTO other_dx_events (person_id, event_date, concept_id)
SELECT
    co.person_id,
    co.condition_start_date,
    co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN anchor_person ap
  ON co.person_id = ap.person_id
JOIN other_dx_concepts d
  ON co.condition_concept_id = d.concept_id
;
DROP TABLE IF EXISTS gen_cancer_events;
CREATE TEMPORARY TABLE IF NOT EXISTS gen_cancer_events  (person_id BIGINT,
    event_date TIMESTAMP,
    concept_id BIGINT
);
INSERT INTO gen_cancer_events (person_id, event_date, concept_id)
SELECT
    co.person_id,
    co.condition_start_date,
    co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN anchor_person ap
  ON co.person_id = ap.person_id
JOIN gen_cancer_concepts g
  ON co.condition_concept_id = g.concept_id
;
DROP TABLE IF EXISTS met_events;
CREATE TEMPORARY TABLE IF NOT EXISTS met_events  (person_id BIGINT,
    event_date TIMESTAMP,
    concept_id BIGINT
);
INSERT INTO met_events (person_id, event_date, concept_id)
SELECT
    m.person_id,
    m.measurement_date,
    m.measurement_concept_id
FROM @cdm_database_schema.measurement m
JOIN anchor_person ap
  ON m.person_id = ap.person_id
JOIN met_concepts mc
  ON m.measurement_concept_id = mc.concept_id
;
DROP TABLE IF EXISTS l01_events;
CREATE TEMPORARY TABLE IF NOT EXISTS l01_events  (person_id BIGINT,
    event_date TIMESTAMP,
    concept_id BIGINT
);
INSERT INTO l01_events (person_id, event_date, concept_id)
SELECT
    de.person_id,
    de.drug_exposure_start_date,
    de.drug_concept_id
FROM @cdm_database_schema.drug_exposure de
JOIN anchor_person ap
  ON de.person_id = ap.person_id
JOIN l01_concepts l
  ON de.drug_concept_id = l.concept_id
;
-- Ingredient-level L01 events used for concept-level code counts/timing.
DROP TABLE IF EXISTS l01_ingredient_events;
CREATE TEMPORARY TABLE IF NOT EXISTS l01_ingredient_events  (person_id BIGINT,
    event_date TIMESTAMP,
    concept_id BIGINT
);
INSERT INTO l01_ingredient_events (person_id, event_date, concept_id)
SELECT DISTINCT
    de.person_id,
    de.drug_exposure_start_date,
    ca.ancestor_concept_id
FROM @cdm_database_schema.drug_exposure de
JOIN anchor_person ap
  ON de.person_id = ap.person_id
JOIN l01_concepts l
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
DROP TABLE IF EXISTS cohort_attrition;
CREATE TEMPORARY TABLE IF NOT EXISTS cohort_attrition  (stage      VARCHAR(50),
    n_patients INT
);
INSERT INTO cohort_attrition (stage, n_patients)
SELECT 'dx_any', COUNT(DISTINCT person_id) FROM dx_events;
DROP TABLE IF EXISTS cohort;
CREATE TEMPORARY TABLE IF NOT EXISTS cohort  (person_id BIGINT,
    index_date TIMESTAMP
);
-- Index date = earliest qualifying DX that falls within an observation period.
-- Patients with no obs-period-covered DX are excluded entirely.
INSERT INTO cohort (person_id, index_date)
SELECT
    dx.person_id,
    MIN(dx.event_date) AS index_date
FROM dx_events dx
INNER JOIN @cdm_database_schema.observation_period op
    ON  op.person_id = dx.person_id
    AND dx.event_date BETWEEN op.observation_period_start_date
                          AND op.observation_period_end_date
GROUP BY dx.person_id
;
INSERT INTO cohort_attrition (stage, n_patients)
SELECT 'dx_in_obs', COUNT(*) FROM cohort;
DROP TABLE IF EXISTS dx_summary;
CREATE TEMPORARY TABLE IF NOT EXISTS dx_summary  (person_id BIGINT,
    n_dx_records INT,
    n_dx_codes INT
);
INSERT INTO dx_summary (person_id, n_dx_records, n_dx_codes)
SELECT
    e.person_id,
    COUNT(*) AS n_dx_records,
    COUNT(DISTINCT e.concept_id) AS n_dx_codes
FROM dx_events e
JOIN cohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS other_dx_summary;
CREATE TEMPORARY TABLE IF NOT EXISTS other_dx_summary  (person_id BIGINT,
    first_other_dx_date TIMESTAMP,
    n_other_dx_records INT,
    n_other_dx_codes INT
);
INSERT INTO other_dx_summary (person_id, first_other_dx_date, n_other_dx_records, n_other_dx_codes)
SELECT
    e.person_id,
    MIN(e.event_date) AS first_other_dx_date,
    COUNT(*) AS n_other_dx_records,
    COUNT(DISTINCT e.concept_id) AS n_other_dx_codes
FROM other_dx_events e
JOIN cohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS gen_cancer_summary;
CREATE TEMPORARY TABLE IF NOT EXISTS gen_cancer_summary  (person_id BIGINT,
    first_gen_cancer_date TIMESTAMP,
    n_gen_cancer_records INT,
    n_gen_cancer_codes INT
);
INSERT INTO gen_cancer_summary (person_id, first_gen_cancer_date, n_gen_cancer_records, n_gen_cancer_codes)
SELECT
    e.person_id,
    MIN(e.event_date) AS first_gen_cancer_date,
    COUNT(*) AS n_gen_cancer_records,
    COUNT(DISTINCT e.concept_id) AS n_gen_cancer_codes
FROM gen_cancer_events e
JOIN cohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS met_summary;
CREATE TEMPORARY TABLE IF NOT EXISTS met_summary  (person_id BIGINT,
    first_met_date TIMESTAMP,
    n_met_records INT
);
INSERT INTO met_summary (person_id, first_met_date, n_met_records)
SELECT
    e.person_id,
    MIN(e.event_date) AS first_met_date,
    COUNT(*) AS n_met_records
FROM met_events e
JOIN cohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS l01_summary;
CREATE TEMPORARY TABLE IF NOT EXISTS l01_summary  (person_id BIGINT,
    first_l01_date TIMESTAMP,
    n_l01_exposures INT
);
INSERT INTO l01_summary (person_id, first_l01_date, n_l01_exposures)
SELECT
    e.person_id,
    MIN(e.event_date) AS first_l01_date,
    COUNT(*) AS n_l01_exposures
FROM l01_events e
JOIN cohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
;
-- H) EVENT CODE COUNTS (single table across event families)
------------------------------------------------------------
DROP TABLE IF EXISTS event_code_counts;
CREATE TEMPORARY TABLE IF NOT EXISTS event_code_counts  (anchor_event VARCHAR(20), -- INDEX or FIRST_MET
    event_family VARCHAR(20),
    concept_id BIGINT,
    n_records INT,
    n_patients INT
);
INSERT INTO event_code_counts (anchor_event, event_family, concept_id, n_records, n_patients)
SELECT 'INDEX', 'DX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM dx_events
WHERE person_id IN (SELECT person_id FROM cohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'ODX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM other_dx_events
WHERE person_id IN (SELECT person_id FROM cohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'GDX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM gen_cancer_events
WHERE person_id IN (SELECT person_id FROM cohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'MET', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM met_events
WHERE person_id IN (SELECT person_id FROM cohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'L01', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM l01_ingredient_events
WHERE person_id IN (SELECT person_id FROM cohort)
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'DX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM dx_events e
JOIN met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'ODX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM other_dx_events e
JOIN met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'GDX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM gen_cancer_events e
JOIN met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'MET', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM met_events e
JOIN met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'L01', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM l01_ingredient_events e
JOIN met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
;
DROP TABLE IF EXISTS event_code_counts_before_after;
CREATE TEMPORARY TABLE IF NOT EXISTS event_code_counts_before_after  (anchor_event VARCHAR(20), -- INDEX
    event_family VARCHAR(20),
    time_relative VARCHAR(10), -- BEFORE or AFTER (relative to index_date)
    concept_id BIGINT,
    n_records INT,
    n_patients INT
);
INSERT INTO event_code_counts_before_after (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
SELECT 'INDEX',
       'DX',
       CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END AS time_relative,
       e.concept_id,
       COUNT(*) AS n_records,
       COUNT(DISTINCT e.person_id) AS n_patients
FROM dx_events e
JOIN cohort c
  ON e.person_id = c.person_id
GROUP BY
    CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    e.concept_id
UNION ALL
SELECT 'INDEX',
       'ODX',
       CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
       COUNT(*),
       COUNT(DISTINCT e.person_id)
FROM other_dx_events e
JOIN cohort c
  ON e.person_id = c.person_id
GROUP BY
    CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    e.concept_id
UNION ALL
SELECT 'INDEX',
       'GDX',
       CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
       COUNT(*),
       COUNT(DISTINCT e.person_id)
FROM gen_cancer_events e
JOIN cohort c
  ON e.person_id = c.person_id
GROUP BY
    CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    e.concept_id
UNION ALL
SELECT 'INDEX',
       'MET',
       CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
       COUNT(*),
       COUNT(DISTINCT e.person_id)
FROM met_events e
JOIN cohort c
  ON e.person_id = c.person_id
GROUP BY
    CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    e.concept_id
UNION ALL
SELECT 'INDEX',
       'L01',
       CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
       COUNT(*),
       COUNT(DISTINCT e.person_id)
FROM l01_ingredient_events e
JOIN cohort c
  ON e.person_id = c.person_id
GROUP BY
    CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    e.concept_id
;
DROP TABLE IF EXISTS event_code_counts_before_after_first_met;
CREATE TEMPORARY TABLE IF NOT EXISTS event_code_counts_before_after_first_met  (anchor_event VARCHAR(20), -- FIRST_MET
    event_family VARCHAR(20),
    time_relative VARCHAR(10), -- BEFORE or AFTER (relative to first_met_date)
    concept_id BIGINT,
    n_records INT,
    n_patients INT
);
INSERT INTO event_code_counts_before_after_first_met (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
SELECT 'FIRST_MET',
       'DX',
       CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END AS time_relative,
       e.concept_id,
       COUNT(*) AS n_records,
       COUNT(DISTINCT e.person_id) AS n_patients
FROM dx_events e
JOIN met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY
    CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    e.concept_id
UNION ALL
SELECT 'FIRST_MET',
       'ODX',
       CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
       COUNT(*),
       COUNT(DISTINCT e.person_id)
FROM other_dx_events e
JOIN met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY
    CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    e.concept_id
UNION ALL
SELECT 'FIRST_MET',
       'GDX',
       CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
       COUNT(*),
       COUNT(DISTINCT e.person_id)
FROM gen_cancer_events e
JOIN met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY
    CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    e.concept_id
UNION ALL
SELECT 'FIRST_MET',
       'MET',
       CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
       COUNT(*),
       COUNT(DISTINCT e.person_id)
FROM met_events e
JOIN met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY
    CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    e.concept_id
UNION ALL
SELECT 'FIRST_MET',
       'L01',
       CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
       e.concept_id,
       COUNT(*),
       COUNT(DISTINCT e.person_id)
FROM l01_ingredient_events e
JOIN met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY
    CASE WHEN day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    e.concept_id
;
DROP TABLE IF EXISTS event_code_all_events;
CREATE TEMPORARY TABLE IF NOT EXISTS event_code_all_events  (anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    concept_id BIGINT,
    person_id BIGINT,
    days_diff INT,
    event_date TIMESTAMP
);
INSERT INTO event_code_all_events (
    anchor_event, event_family, concept_id, person_id, days_diff, event_date
)
SELECT 'INDEX' AS anchor_event, 'DX' AS event_family, e.concept_id, e.person_id, day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) AS days_diff, e.event_date
FROM dx_events e
JOIN cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'ODX', e.concept_id, e.person_id, day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)), e.event_date
FROM other_dx_events e
JOIN cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'GDX', e.concept_id, e.person_id, day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)), e.event_date
FROM gen_cancer_events e
JOIN cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'MET', e.concept_id, e.person_id, day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)), e.event_date
FROM met_events e
JOIN cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'L01', e.concept_id, e.person_id, day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)), e.event_date
FROM l01_ingredient_events e
JOIN cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'FIRST_MET', 'DX', e.concept_id, e.person_id, day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)), e.event_date
FROM dx_events e
JOIN met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'ODX', e.concept_id, e.person_id, day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)), e.event_date
FROM other_dx_events e
JOIN met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'GDX', e.concept_id, e.person_id, day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)), e.event_date
FROM gen_cancer_events e
JOIN met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'MET', e.concept_id, e.person_id, day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)), e.event_date
FROM met_events e
JOIN met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'L01', e.concept_id, e.person_id, day(CAST(e.event_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP)), e.event_date
FROM l01_ingredient_events e
JOIN met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
;
DROP TABLE IF EXISTS event_code_patient_chosen_first;
CREATE TEMPORARY TABLE IF NOT EXISTS event_code_patient_chosen_first  (anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    concept_id BIGINT,
    person_id BIGINT,
    days_diff INT
);
INSERT INTO event_code_patient_chosen_first (anchor_event, event_family, concept_id, person_id, days_diff)
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
            ORDER BY day(CAST(event_date AS TIMESTAMP) - CAST(CAST('1900-01-01' AS TIMESTAMP) AS TIMESTAMP)) ASC, event_date ASC
        ) AS rn
    FROM event_code_all_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS event_code_patient_chosen_closest;
CREATE TEMPORARY TABLE IF NOT EXISTS event_code_patient_chosen_closest  (anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    concept_id BIGINT,
    person_id BIGINT,
    days_diff INT
);
INSERT INTO event_code_patient_chosen_closest (anchor_event, event_family, concept_id, person_id, days_diff)
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
    FROM event_code_all_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS event_code_timing_summary;
CREATE TEMPORARY TABLE IF NOT EXISTS event_code_timing_summary  (anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    concept_id BIGINT,
    n_patients_with_code_timing INT,
    lq_days_first FLOAT,
    median_days_first FLOAT,
    uq_days_first FLOAT,
    lq_days_closest FLOAT,
    median_days_closest FLOAT,
    uq_days_closest FLOAT
);
INSERT INTO event_code_timing_summary (
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
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS lq_days_first,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS median_days_first,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS FLOAT) END) AS uq_days_first
    FROM (
        SELECT anchor_event, event_family, concept_id, days_diff,
            ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, concept_id ORDER BY days_diff) AS rn,
            COUNT(*)     OVER (PARTITION BY anchor_event, event_family, concept_id)                    AS cnt
        FROM event_code_patient_chosen_first
    ) x
    GROUP BY anchor_event, event_family, concept_id
) f
INNER JOIN (
    SELECT
        anchor_event,
        event_family,
        concept_id,
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS lq_days_closest,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS median_days_closest,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS FLOAT) END) AS uq_days_closest
    FROM (
        SELECT anchor_event, event_family, concept_id, days_diff,
            ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, concept_id ORDER BY days_diff) AS rn,
            COUNT(*)     OVER (PARTITION BY anchor_event, event_family, concept_id)                    AS cnt
        FROM event_code_patient_chosen_closest
    ) x
    GROUP BY anchor_event, event_family, concept_id
) k
  ON f.anchor_event = k.anchor_event
 AND f.event_family = k.event_family
 AND f.concept_id = k.concept_id
;
DROP TABLE IF EXISTS event_code_ba_events;
CREATE TEMPORARY TABLE IF NOT EXISTS event_code_ba_events  (anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    time_relative VARCHAR(10),
    concept_id BIGINT,
    person_id BIGINT,
    days_diff INT,
    event_date TIMESTAMP
);
INSERT INTO event_code_ba_events (
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
FROM event_code_all_events
;
DROP TABLE IF EXISTS event_code_patient_chosen_before_after_first;
CREATE TEMPORARY TABLE IF NOT EXISTS event_code_patient_chosen_before_after_first  (anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    time_relative VARCHAR(10),
    concept_id BIGINT,
    person_id BIGINT,
    days_diff INT
);
INSERT INTO event_code_patient_chosen_before_after_first (
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
            ORDER BY day(CAST(event_date AS TIMESTAMP) - CAST(CAST('1900-01-01' AS TIMESTAMP) AS TIMESTAMP)) ASC, event_date ASC
        ) AS rn
    FROM event_code_ba_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS event_code_patient_chosen_before_after_closest;
CREATE TEMPORARY TABLE IF NOT EXISTS event_code_patient_chosen_before_after_closest  (anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    time_relative VARCHAR(10),
    concept_id BIGINT,
    person_id BIGINT,
    days_diff INT
);
INSERT INTO event_code_patient_chosen_before_after_closest (
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
    FROM event_code_ba_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS event_code_timing_before_after_summary;
CREATE TEMPORARY TABLE IF NOT EXISTS event_code_timing_before_after_summary  (anchor_event VARCHAR(20),
    event_family VARCHAR(20),
    time_relative VARCHAR(10),
    concept_id BIGINT,
    n_patients_with_code_timing INT,
    lq_days_first FLOAT,
    median_days_first FLOAT,
    uq_days_first FLOAT,
    lq_days_closest FLOAT,
    median_days_closest FLOAT,
    uq_days_closest FLOAT
);
INSERT INTO event_code_timing_before_after_summary (
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
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS lq_days_first,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS median_days_first,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS FLOAT) END) AS uq_days_first
    FROM (
        SELECT anchor_event, event_family, time_relative, concept_id, days_diff,
            ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, time_relative, concept_id ORDER BY days_diff) AS rn,
            COUNT(*)     OVER (PARTITION BY anchor_event, event_family, time_relative, concept_id)                    AS cnt
        FROM event_code_patient_chosen_before_after_first
    ) x
    GROUP BY anchor_event, event_family, time_relative, concept_id
) f
INNER JOIN (
    SELECT
        anchor_event,
        event_family,
        time_relative,
        concept_id,
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS lq_days_closest,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS median_days_closest,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS FLOAT) END) AS uq_days_closest
    FROM (
        SELECT anchor_event, event_family, time_relative, concept_id, days_diff,
            ROW_NUMBER() OVER (PARTITION BY anchor_event, event_family, time_relative, concept_id ORDER BY days_diff) AS rn,
            COUNT(*)     OVER (PARTITION BY anchor_event, event_family, time_relative, concept_id)                    AS cnt
        FROM event_code_patient_chosen_before_after_closest
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
DROP TABLE IF EXISTS patient_char;
CREATE TEMPORARY TABLE IF NOT EXISTS patient_char  (person_id BIGINT,
    index_date TIMESTAMP,
    n_dx_records INT,
    n_dx_codes INT,
    first_other_dx_date TIMESTAMP,
    n_other_dx_records INT,
    n_other_dx_codes INT,
    first_gen_cancer_date TIMESTAMP,
    n_gen_cancer_records INT,
    n_gen_cancer_codes INT,
    first_met_date TIMESTAMP,
    n_met_records INT,
    first_l01_date TIMESTAMP,
    n_l01_exposures INT,
    days_dx_to_met INT,
    days_dx_to_l01 INT,
    days_dx_to_other_dx INT,
    days_dx_to_gen_cancer INT,
    days_met_to_l01 INT
);
INSERT INTO patient_char (
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
    CASE WHEN mt.first_met_date IS NOT NULL THEN day(CAST(mt.first_met_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) END AS days_dx_to_met,
    CASE WHEN l01.first_l01_date IS NOT NULL THEN day(CAST(l01.first_l01_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) END AS days_dx_to_l01,
    CASE WHEN odx.first_other_dx_date IS NOT NULL THEN day(CAST(odx.first_other_dx_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) END AS days_dx_to_other_dx,
    CASE WHEN gdx.first_gen_cancer_date IS NOT NULL THEN day(CAST(gdx.first_gen_cancer_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) END AS days_dx_to_gen_cancer,
    CASE WHEN mt.first_met_date IS NOT NULL AND l01.first_l01_date IS NOT NULL THEN day(CAST(l01.first_l01_date AS TIMESTAMP) - CAST(mt.first_met_date AS TIMESTAMP)) END AS days_met_to_l01
FROM cohort c
LEFT JOIN dx_summary dx
       ON c.person_id = dx.person_id
LEFT JOIN other_dx_summary odx
       ON c.person_id = odx.person_id
LEFT JOIN gen_cancer_summary gdx
       ON c.person_id = gdx.person_id
LEFT JOIN met_summary mt
       ON c.person_id = mt.person_id
LEFT JOIN l01_summary l01
       ON c.person_id = l01.person_id
;
------------------------------------------------------------
-- J) FULL CROSSWISE TIMING PAIRS
------------------------------------------------------------
DROP TABLE IF EXISTS patient_timing_pairs;
CREATE TEMPORARY TABLE IF NOT EXISTS patient_timing_pairs  (person_id BIGINT,
    from_event VARCHAR(10),
    to_event VARCHAR(10),
    days_diff INT
);
WITH events AS (
    SELECT person_id, 'DX' AS event_name, index_date AS event_date FROM patient_char
    UNION ALL
    SELECT person_id, 'ODX', first_other_dx_date FROM patient_char
    UNION ALL
    SELECT person_id, 'GDX', first_gen_cancer_date FROM patient_char
    UNION ALL
    SELECT person_id, 'MET', first_met_date FROM patient_char
    UNION ALL
    SELECT person_id, 'L01', first_l01_date FROM patient_char
)
INSERT INTO patient_timing_pairs (person_id, from_event, to_event, days_diff)
SELECT
    e1.person_id,
    e1.event_name AS from_event,
    e2.event_name AS to_event,
    day(CAST(e2.event_date AS TIMESTAMP) - CAST(e1.event_date AS TIMESTAMP)) AS days_diff
FROM events e1
JOIN events e2
  ON e1.person_id = e2.person_id
 AND e1.event_name <> e2.event_name
WHERE e1.event_date IS NOT NULL
  AND e2.event_date IS NOT NULL
;
DROP TABLE IF EXISTS timing_pair_summary;
CREATE TEMPORARY TABLE IF NOT EXISTS timing_pair_summary  (from_event VARCHAR(10),
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
INSERT INTO timing_pair_summary (
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
FROM (
    SELECT from_event, to_event, days_diff,
        ROW_NUMBER() OVER (PARTITION BY from_event, to_event ORDER BY days_diff) AS rn,
        COUNT(*)     OVER (PARTITION BY from_event, to_event)                    AS cnt
    FROM patient_timing_pairs
) x
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS all_events_for_pairs;
CREATE TEMPORARY TABLE IF NOT EXISTS all_events_for_pairs  (person_id BIGINT,
    event_family VARCHAR(10),
    event_date TIMESTAMP
);
INSERT INTO all_events_for_pairs (person_id, event_family, event_date)
SELECT person_id, 'DX', event_date FROM dx_events
UNION ALL
SELECT person_id, 'ODX', event_date FROM other_dx_events
UNION ALL
SELECT person_id, 'GDX', event_date FROM gen_cancer_events
UNION ALL
SELECT person_id, 'MET', event_date FROM met_events
UNION ALL
SELECT person_id, 'L01', event_date FROM l01_events
;
DROP TABLE IF EXISTS first_event_dates;
CREATE TEMPORARY TABLE IF NOT EXISTS first_event_dates  (person_id BIGINT,
    from_event VARCHAR(10),
    from_first_date TIMESTAMP
);
INSERT INTO first_event_dates (person_id, from_event, from_first_date)
SELECT person_id, 'DX', index_date FROM patient_char
UNION ALL
SELECT person_id, 'ODX', first_other_dx_date FROM patient_char WHERE first_other_dx_date IS NOT NULL
UNION ALL
SELECT person_id, 'GDX', first_gen_cancer_date FROM patient_char WHERE first_gen_cancer_date IS NOT NULL
UNION ALL
SELECT person_id, 'MET', first_met_date FROM patient_char WHERE first_met_date IS NOT NULL
UNION ALL
SELECT person_id, 'L01', first_l01_date FROM patient_char WHERE first_l01_date IS NOT NULL
;
DROP TABLE IF EXISTS patient_timing_pairs_first_to_closest;
CREATE TEMPORARY TABLE IF NOT EXISTS patient_timing_pairs_first_to_closest  (person_id BIGINT,
    from_event VARCHAR(10),
    to_event VARCHAR(10),
    days_diff INT
);
WITH ranked AS (
    SELECT
        f.person_id,
        f.from_event,
        a.event_family AS to_event,
        day(CAST(a.event_date AS TIMESTAMP) - CAST(f.from_first_date AS TIMESTAMP)) AS days_diff,
        ROW_NUMBER() OVER (
            PARTITION BY f.person_id, f.from_event, a.event_family
            ORDER BY ABS(day(CAST(a.event_date AS TIMESTAMP) - CAST(f.from_first_date AS TIMESTAMP))), a.event_date
        ) AS rn
    FROM first_event_dates f
    JOIN all_events_for_pairs a
      ON f.person_id = a.person_id
     AND f.from_event <> a.event_family
)
INSERT INTO patient_timing_pairs_first_to_closest (person_id, from_event, to_event, days_diff)
SELECT
    person_id,
    from_event,
    to_event,
    days_diff
FROM ranked
WHERE rn = 1
;
DROP TABLE IF EXISTS timing_pair_summary_first_to_closest;
CREATE TEMPORARY TABLE IF NOT EXISTS timing_pair_summary_first_to_closest  (from_event VARCHAR(10),
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
INSERT INTO timing_pair_summary_first_to_closest (
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
FROM (
    SELECT from_event, to_event, days_diff,
        ROW_NUMBER() OVER (PARTITION BY from_event, to_event ORDER BY days_diff) AS rn,
        COUNT(*)     OVER (PARTITION BY from_event, to_event)                    AS cnt
    FROM patient_timing_pairs_first_to_closest
) x
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS patient_timing_pairs_first_to_closest_before;
CREATE TEMPORARY TABLE IF NOT EXISTS patient_timing_pairs_first_to_closest_before  (person_id BIGINT,
    from_event VARCHAR(10),
    to_event VARCHAR(10),
    days_diff INT
);
WITH ranked_before AS (
    SELECT
        f.person_id,
        f.from_event,
        a.event_family AS to_event,
        day(CAST(a.event_date AS TIMESTAMP) - CAST(f.from_first_date AS TIMESTAMP)) AS days_diff,
        ROW_NUMBER() OVER (
            PARTITION BY f.person_id, f.from_event, a.event_family
            ORDER BY ABS(day(CAST(a.event_date AS TIMESTAMP) - CAST(f.from_first_date AS TIMESTAMP))), a.event_date DESC
        ) AS rn
    FROM first_event_dates f
    JOIN all_events_for_pairs a
      ON f.person_id = a.person_id
     AND f.from_event <> a.event_family
    WHERE day(CAST(a.event_date AS TIMESTAMP) - CAST(f.from_first_date AS TIMESTAMP)) < 0
)
INSERT INTO patient_timing_pairs_first_to_closest_before (person_id, from_event, to_event, days_diff)
SELECT
    person_id,
    from_event,
    to_event,
    days_diff
FROM ranked_before
WHERE rn = 1
;
DROP TABLE IF EXISTS timing_pair_summary_first_to_closest_before;
CREATE TEMPORARY TABLE IF NOT EXISTS timing_pair_summary_first_to_closest_before  (from_event VARCHAR(10),
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
INSERT INTO timing_pair_summary_first_to_closest_before (
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
FROM (
    SELECT from_event, to_event, days_diff,
        ROW_NUMBER() OVER (PARTITION BY from_event, to_event ORDER BY days_diff) AS rn,
        COUNT(*)     OVER (PARTITION BY from_event, to_event)                    AS cnt
    FROM patient_timing_pairs_first_to_closest_before
) x
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS patient_timing_pairs_first_to_closest_after;
CREATE TEMPORARY TABLE IF NOT EXISTS patient_timing_pairs_first_to_closest_after  (person_id BIGINT,
    from_event VARCHAR(10),
    to_event VARCHAR(10),
    days_diff INT
);
WITH ranked_after AS (
    SELECT
        f.person_id,
        f.from_event,
        a.event_family AS to_event,
        day(CAST(a.event_date AS TIMESTAMP) - CAST(f.from_first_date AS TIMESTAMP)) AS days_diff,
        ROW_NUMBER() OVER (
            PARTITION BY f.person_id, f.from_event, a.event_family
            ORDER BY day(CAST(a.event_date AS TIMESTAMP) - CAST(f.from_first_date AS TIMESTAMP)), a.event_date
        ) AS rn
    FROM first_event_dates f
    JOIN all_events_for_pairs a
      ON f.person_id = a.person_id
     AND f.from_event <> a.event_family
    WHERE day(CAST(a.event_date AS TIMESTAMP) - CAST(f.from_first_date AS TIMESTAMP)) >= 0
)
INSERT INTO patient_timing_pairs_first_to_closest_after (person_id, from_event, to_event, days_diff)
SELECT
    person_id,
    from_event,
    to_event,
    days_diff
FROM ranked_after
WHERE rn = 1
;
DROP TABLE IF EXISTS timing_pair_summary_first_to_closest_after;
CREATE TEMPORARY TABLE IF NOT EXISTS timing_pair_summary_first_to_closest_after  (from_event VARCHAR(10),
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
INSERT INTO timing_pair_summary_first_to_closest_after (
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
FROM (
    SELECT from_event, to_event, days_diff,
        ROW_NUMBER() OVER (PARTITION BY from_event, to_event ORDER BY days_diff) AS rn,
        COUNT(*)     OVER (PARTITION BY from_event, to_event)                    AS cnt
    FROM patient_timing_pairs_first_to_closest_after
) x
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS event_presence;
CREATE TEMPORARY TABLE IF NOT EXISTS event_presence  (person_id BIGINT,
    has_dx INT,
    has_odx INT,
    has_gdx INT,
    has_met INT,
    has_l01 INT
);
INSERT INTO event_presence (
    person_id, has_dx, has_odx, has_gdx, has_met, has_l01
)
SELECT
    person_id,
    1,
    CASE WHEN first_other_dx_date IS NOT NULL THEN 1 ELSE 0 END,
    CASE WHEN first_gen_cancer_date IS NOT NULL THEN 1 ELSE 0 END,
    CASE WHEN first_met_date IS NOT NULL THEN 1 ELSE 0 END,
    CASE WHEN first_l01_date IS NOT NULL THEN 1 ELSE 0 END
FROM patient_char
;
------------------------------------------------------------
-- J-bis) DEATH TIMING FROM INDEX AND FIRST_MET ANCHORS
------------------------------------------------------------
-- Pre-compute each cohort patient's earliest death date and whether it
-- falls within any of their observation periods.
DROP TABLE IF EXISTS death_obs_status;
CREATE TEMPORARY TABLE IF NOT EXISTS death_obs_status  (person_id BIGINT,
    death_date TIMESTAMP,
    death_in_obs SMALLINT
);
INSERT INTO death_obs_status (person_id, death_date, death_in_obs)
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
WHERE d.person_id IN (SELECT person_id FROM cohort)
;
DROP TABLE IF EXISTS death_index_long;
CREATE TEMPORARY TABLE IF NOT EXISTS death_index_long  (prevalence_year VARCHAR(20),
    days_to_death INT
);
INSERT INTO death_index_long (prevalence_year, days_to_death)
SELECT 'OVERALL', day(CAST(dos.death_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP))
FROM cohort c
INNER JOIN death_obs_status dos ON dos.person_id = c.person_id
WHERE dos.death_date >= c.index_date
UNION ALL
SELECT CAST(YEAR(c.index_date) AS VARCHAR(4)), day(CAST(dos.death_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP))
FROM cohort c
INNER JOIN death_obs_status dos ON dos.person_id = c.person_id
WHERE dos.death_date >= c.index_date
;
DROP TABLE IF EXISTS death_first_met_long;
CREATE TEMPORARY TABLE IF NOT EXISTS death_first_met_long  (prevalence_year VARCHAR(20),
    days_to_death INT
);
INSERT INTO death_first_met_long (prevalence_year, days_to_death)
SELECT 'OVERALL', day(CAST(dos.death_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP))
FROM cohort c
INNER JOIN met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN death_obs_status dos ON dos.person_id = c.person_id
WHERE dos.death_date >= ms.first_met_date
UNION ALL
SELECT CAST(YEAR(c.index_date) AS VARCHAR(4)), day(CAST(dos.death_date AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP))
FROM cohort c
INNER JOIN met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN death_obs_status dos ON dos.person_id = c.person_id
WHERE dos.death_date >= ms.first_met_date
;
DROP TABLE IF EXISTS death_stratum_counts;
CREATE TEMPORARY TABLE IF NOT EXISTS death_stratum_counts  (prevalence_year VARCHAR(20),
    anchor_event VARCHAR(20),
    n_patients INT,
    n_deaths INT,
    n_deaths_in_obs INT,
    n_deaths_out_obs INT
);
INSERT INTO death_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths, n_deaths_in_obs, n_deaths_out_obs)
SELECT
    CASE
        WHEN GROUPING(YEAR(c.index_date)) = 1 THEN 'OVERALL'
        ELSE CAST(YEAR(c.index_date) AS VARCHAR(4))
    END,
    'INDEX',
    COUNT(*),
    SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= c.index_date THEN 1 ELSE 0 END),
    SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= c.index_date AND dos.death_in_obs = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= c.index_date AND dos.death_in_obs = 0 THEN 1 ELSE 0 END)
FROM cohort c
LEFT JOIN death_obs_status dos ON dos.person_id = c.person_id
GROUP BY GROUPING SETS ((), (YEAR(c.index_date)))
;
INSERT INTO death_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths, n_deaths_in_obs, n_deaths_out_obs)
SELECT
    CASE
        WHEN GROUPING(YEAR(c.index_date)) = 1 THEN 'OVERALL'
        ELSE CAST(YEAR(c.index_date) AS VARCHAR(4))
    END,
    'FIRST_MET',
    COUNT(*),
    SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= ms.first_met_date THEN 1 ELSE 0 END),
    SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= ms.first_met_date AND dos.death_in_obs = 1 THEN 1 ELSE 0 END),
    SUM(CASE WHEN dos.death_date IS NOT NULL AND dos.death_date >= ms.first_met_date AND dos.death_in_obs = 0 THEN 1 ELSE 0 END)
FROM cohort c
INNER JOIN met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
LEFT JOIN death_obs_status dos ON dos.person_id = c.person_id
GROUP BY GROUPING SETS ((), (YEAR(c.index_date)))
;
DROP TABLE IF EXISTS death_timing_long;
CREATE TEMPORARY TABLE IF NOT EXISTS death_timing_long  (prevalence_year VARCHAR(20),
    anchor_event VARCHAR(20),
    days_to_death INT
);
INSERT INTO death_timing_long (prevalence_year, anchor_event, days_to_death)
SELECT prevalence_year, 'INDEX', days_to_death FROM death_index_long
UNION ALL
SELECT prevalence_year, 'FIRST_MET', days_to_death FROM death_first_met_long
;
DROP TABLE IF EXISTS death_timing_quantiles;
CREATE TEMPORARY TABLE IF NOT EXISTS death_timing_quantiles  (prevalence_year VARCHAR(20),
    anchor_event VARCHAR(20),
    lq_days FLOAT,
    median_days FLOAT,
    uq_days FLOAT
);
INSERT INTO death_timing_quantiles (
    prevalence_year,
    anchor_event,
    lq_days,
    median_days,
    uq_days
)
SELECT
    prevalence_year,
    anchor_event,
    MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_to_death AS FLOAT) END) AS lq_days,
    MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_to_death AS FLOAT) END) AS median_days,
    MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_to_death AS FLOAT) END) AS uq_days
FROM (
    SELECT prevalence_year, anchor_event, days_to_death,
        ROW_NUMBER() OVER (PARTITION BY prevalence_year, anchor_event ORDER BY days_to_death) AS rn,
        COUNT(*)     OVER (PARTITION BY prevalence_year, anchor_event)                        AS cnt
    FROM death_timing_long
) x
GROUP BY prevalence_year, anchor_event
;
-- Follow-up duration from anchor date to last observation period end,
-- for all patients with at least one observation period covering or after anchor.
DROP TABLE IF EXISTS followup_long;
CREATE TEMPORARY TABLE IF NOT EXISTS followup_long  (prevalence_year VARCHAR(20),
    anchor_event VARCHAR(20),
    followup_days INT
);
INSERT INTO followup_long (prevalence_year, anchor_event, followup_days)
SELECT 'OVERALL', 'INDEX',
       day(CAST(MAX(op.observation_period_end_date) AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP))
FROM cohort c
INNER JOIN @cdm_database_schema.observation_period op
  ON op.person_id = c.person_id
 AND op.observation_period_end_date >= c.index_date
GROUP BY c.person_id, c.index_date
UNION ALL
SELECT CAST(YEAR(c.index_date) AS VARCHAR(4)), 'INDEX',
       day(CAST(MAX(op.observation_period_end_date) AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP))
FROM cohort c
INNER JOIN @cdm_database_schema.observation_period op
  ON op.person_id = c.person_id
 AND op.observation_period_end_date >= c.index_date
GROUP BY c.person_id, c.index_date, YEAR(c.index_date)
UNION ALL
SELECT 'OVERALL', 'FIRST_MET',
       day(CAST(MAX(op.observation_period_end_date) AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP))
FROM cohort c
INNER JOIN met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN @cdm_database_schema.observation_period op
  ON op.person_id = c.person_id
 AND op.observation_period_end_date >= ms.first_met_date
GROUP BY c.person_id, ms.first_met_date
UNION ALL
SELECT CAST(YEAR(c.index_date) AS VARCHAR(4)), 'FIRST_MET',
       day(CAST(MAX(op.observation_period_end_date) AS TIMESTAMP) - CAST(ms.first_met_date AS TIMESTAMP))
FROM cohort c
INNER JOIN met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN @cdm_database_schema.observation_period op
  ON op.person_id = c.person_id
 AND op.observation_period_end_date >= ms.first_met_date
GROUP BY c.person_id, c.index_date, ms.first_met_date, YEAR(c.index_date)
;
DROP TABLE IF EXISTS followup_quantiles;
CREATE TEMPORARY TABLE IF NOT EXISTS followup_quantiles  (prevalence_year VARCHAR(20),
    anchor_event VARCHAR(20),
    lq_followup_days FLOAT,
    median_followup_days FLOAT,
    uq_followup_days FLOAT
);
INSERT INTO followup_quantiles (
    prevalence_year,
    anchor_event,
    lq_followup_days,
    median_followup_days,
    uq_followup_days
)
SELECT
    prevalence_year,
    anchor_event,
    MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(followup_days AS FLOAT) END) AS lq_followup_days,
    MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(followup_days AS FLOAT) END) AS median_followup_days,
    MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(followup_days AS FLOAT) END) AS uq_followup_days
FROM (
    SELECT prevalence_year, anchor_event, followup_days,
        ROW_NUMBER() OVER (PARTITION BY prevalence_year, anchor_event ORDER BY followup_days) AS rn,
        COUNT(*)     OVER (PARTITION BY prevalence_year, anchor_event)                        AS cnt
    FROM followup_long
) x
GROUP BY prevalence_year, anchor_event
;
------------------------------------------------------------
-- L) L01 CONSECUTIVE GAP TABLES (used by chunks 11 and 12)
------------------------------------------------------------
-- Deduplicated L01 event days per patient (one row per patient-day)
DROP TABLE IF EXISTS l01_event_days;
CREATE TEMPORARY TABLE IF NOT EXISTS l01_event_days  (person_id  BIGINT,
    event_day  TIMESTAMP
);
INSERT INTO l01_event_days (person_id, event_day)
SELECT DISTINCT person_id, event_date
FROM l01_events
WHERE person_id IN (SELECT person_id FROM cohort)
;
-- Consecutive gaps between L01 event days per patient
DROP TABLE IF EXISTS l01_consecutive_gaps;
CREATE TEMPORARY TABLE IF NOT EXISTS l01_consecutive_gaps  (person_id  BIGINT,
    subgroup   VARCHAR(12),
    gap_days   INT
);
WITH ranked AS (
    SELECT
        e.person_id,
        e.event_day,
        LEAD(e.event_day) OVER (PARTITION BY e.person_id ORDER BY e.event_day) AS next_day
    FROM l01_event_days e
),
gaps AS (
    SELECT
        person_id,
        day(CAST(next_day AS TIMESTAMP) - CAST(event_day AS TIMESTAMP)) AS gap_days
    FROM ranked
    WHERE next_day IS NOT NULL
)
INSERT INTO l01_consecutive_gaps (person_id, subgroup, gap_days)
SELECT g.person_id, 'ALL_L01', g.gap_days FROM gaps g
UNION ALL
SELECT g.person_id, 'MET_L01', g.gap_days
FROM gaps g
JOIN met_summary ms ON g.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
;
-- Max gap per patient (one row per patient; used for MAX-gap subgroups in chunks 11–12)
INSERT INTO l01_consecutive_gaps (person_id, subgroup, gap_days)
SELECT person_id, 'ALL_L01_MAX', MAX(gap_days)
FROM l01_consecutive_gaps
WHERE subgroup = 'ALL_L01'
GROUP BY person_id
UNION ALL
SELECT person_id, 'MET_L01_MAX', MAX(gap_days)
FROM l01_consecutive_gaps
WHERE subgroup = 'MET_L01'
GROUP BY person_id
;
------------------------------------------------------------
-- K) FINAL SELECTS (export to CSV from SQL client)
------------------------------------------------------------
-- 0b) Cohort attrition: patients with any qualifying DX vs those with a DX
--     that falls within an observation period (the study-eligible subset).
--     The difference is the number excluded by the obs-period filter.
SELECT
    SUM(CASE WHEN stage = 'dx_any'    THEN n_patients ELSE 0 END) AS n_dx_any,
    SUM(CASE WHEN stage = 'dx_in_obs' THEN n_patients ELSE 0 END) AS n_dx_in_obs,
    SUM(CASE WHEN stage = 'dx_any'    THEN n_patients ELSE 0 END)
    - SUM(CASE WHEN stage = 'dx_in_obs' THEN n_patients ELSE 0 END)  AS n_excluded_no_obs_dx
FROM cohort_attrition
;
-- 1) Population prevalence
WITH base AS (
    SELECT
        CASE
            WHEN GROUPING(YEAR(index_date)) = 1 THEN 'OVERALL'
            ELSE CAST(YEAR(index_date) AS VARCHAR(4))
        END AS prevalence_year,
        COUNT(*) AS n_patients,
        SUM(CASE WHEN first_other_dx_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_other_dx,
        SUM(CASE WHEN first_gen_cancer_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_gen_cancer_dx,
        SUM(CASE WHEN first_met_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_met,
        SUM(CASE WHEN first_l01_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_l01
    FROM patient_char
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
-- 2) Code-count summary: all three time windows combined (small-cell sentinel)
--    time_window: all | before | after
SELECT
    x.time_window,
    x.anchor_event,
    x.event_family,
    x.concept_id,
    CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE x.n_records END AS n_records,
    CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE x.n_patients END AS n_patients,
    CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE COALESCE(ts.n_patients_with_code_timing, tba.n_patients_with_code_timing) END AS n_patients_with_code_timing,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.lq_days_first,       tba.lq_days_first)       END AS lq_days_first,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.median_days_first,   tba.median_days_first)   END AS median_days_first,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.uq_days_first,       tba.uq_days_first)       END AS uq_days_first,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.lq_days_closest,     tba.lq_days_closest)     END AS lq_days_closest,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.median_days_closest, tba.median_days_closest) END AS median_days_closest,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.uq_days_closest,     tba.uq_days_closest)     END AS uq_days_closest,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.lq_days_first,       tba.lq_days_first)       END AS lq_days,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.median_days_first,   tba.median_days_first)   END AS median_days,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE COALESCE(ts.uq_days_first,       tba.uq_days_first)       END AS uq_days
FROM (
    SELECT 'all'    AS time_window, anchor_event, event_family, concept_id, n_records, n_patients FROM event_code_counts
    UNION ALL
    SELECT 'before' AS time_window, anchor_event, event_family, concept_id, n_records, n_patients FROM event_code_counts_before_after         WHERE time_relative = 'BEFORE'
    UNION ALL
    SELECT 'after'  AS time_window, anchor_event, event_family, concept_id, n_records, n_patients FROM event_code_counts_before_after         WHERE time_relative = 'AFTER'
    UNION ALL
    SELECT 'before' AS time_window, anchor_event, event_family, concept_id, n_records, n_patients FROM event_code_counts_before_after_first_met WHERE time_relative = 'BEFORE'
    UNION ALL
    SELECT 'after'  AS time_window, anchor_event, event_family, concept_id, n_records, n_patients FROM event_code_counts_before_after_first_met WHERE time_relative = 'AFTER'
) x
LEFT JOIN event_code_timing_summary ts
  ON x.time_window = 'all'
 AND x.anchor_event = ts.anchor_event
 AND x.event_family = ts.event_family
 AND x.concept_id   = ts.concept_id
LEFT JOIN event_code_timing_before_after_summary tba
  ON x.time_window != 'all'
 AND x.anchor_event = tba.anchor_event
 AND x.event_family = tba.event_family
 AND x.concept_id   = tba.concept_id
 AND ((x.time_window = 'before' AND tba.time_relative = 'BEFORE')
  OR  (x.time_window = 'after'  AND tba.time_relative = 'AFTER'))
ORDER BY x.time_window, x.anchor_event, x.event_family, x.n_patients DESC, x.n_records DESC, x.concept_id
;
-- 3) Temporal directionality buckets
--    Exact patient counts by direction category for key event pairs:
--      DX -> MET  (using index_date -> first_met_date from #patient_char)
--      MET -> L01 (using first_met_date -> first_l01_date from #patient_char)
--
--    Categories (days = TO_date - FROM_date):
--      BEFORE_GT90  : TO event > 90 days before FROM  (days < -90)
--      BEFORE_1_90  : TO event 1-90 days before FROM  (-90 <= days < 0)
--      SAME_DAY     : same calendar day                (days = 0)
--      AFTER_1_30   : 1-30 days after                  (1 <= days <= 30)
--      AFTER_31_90  : 31-90 days after                 (31 <= days <= 90)
--      AFTER_91_365 : 91-365 days after                (91 <= days <= 365)
--      AFTER_GT365  : > 365 days after                 (days > 365)
--      NO_EVENT     : FROM event present but TO event absent
--
--    Stratified by OVERALL and by index_year (YEAR(index_date)).
--    Small-cell suppression: n suppressed to -@min_cell_count when <= @min_cell_count.
WITH dx_met_base AS (
    SELECT
        YEAR(index_date) AS index_year_int,
        CASE
            WHEN first_met_date IS NULL  THEN 'NO_EVENT'
            WHEN days_dx_to_met < -90    THEN 'BEFORE_GT90'
            WHEN days_dx_to_met < 0      THEN 'BEFORE_1_90'
            WHEN days_dx_to_met = 0      THEN 'SAME_DAY'
            WHEN days_dx_to_met <= 30    THEN 'AFTER_1_30'
            WHEN days_dx_to_met <= 90    THEN 'AFTER_31_90'
            WHEN days_dx_to_met <= 365   THEN 'AFTER_91_365'
            ELSE 'AFTER_GT365'
        END AS direction
    FROM patient_char
),
met_l01_base AS (
    SELECT
        YEAR(index_date) AS index_year_int,
        CASE
            WHEN first_l01_date IS NULL  THEN 'NO_EVENT'
            WHEN days_met_to_l01 < -90   THEN 'BEFORE_GT90'
            WHEN days_met_to_l01 < 0     THEN 'BEFORE_1_90'
            WHEN days_met_to_l01 = 0     THEN 'SAME_DAY'
            WHEN days_met_to_l01 <= 30   THEN 'AFTER_1_30'
            WHEN days_met_to_l01 <= 90   THEN 'AFTER_31_90'
            WHEN days_met_to_l01 <= 365  THEN 'AFTER_91_365'
            ELSE 'AFTER_GT365'
        END AS direction
    FROM patient_char
    WHERE first_met_date IS NOT NULL
)
SELECT
    x.pair,
    x.index_year,
    x.direction,
    CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE x.n_patients END AS n_patients
FROM (
    -- DX -> MET: OVERALL
    SELECT
        'DX_MET'   AS pair,
        'OVERALL'  AS index_year,
        direction,
        COUNT(*)   AS n_patients
    FROM dx_met_base
    GROUP BY direction
    UNION ALL
    -- DX -> MET: by index year
    SELECT
        'DX_MET'                              AS pair,
        CAST(index_year_int AS VARCHAR(4))    AS index_year,
        direction,
        COUNT(*)                              AS n_patients
    FROM dx_met_base
    GROUP BY index_year_int, direction
    UNION ALL
    -- MET -> L01: OVERALL
    SELECT
        'MET_L01'  AS pair,
        'OVERALL'  AS index_year,
        direction,
        COUNT(*)   AS n_patients
    FROM met_l01_base
    GROUP BY direction
    UNION ALL
    -- MET -> L01: by index year
    SELECT
        'MET_L01'                             AS pair,
        CAST(index_year_int AS VARCHAR(4))    AS index_year,
        direction,
        COUNT(*)                              AS n_patients
    FROM met_l01_base
    GROUP BY index_year_int, direction
) x
ORDER BY
    x.pair,
    CASE WHEN x.index_year = 'OVERALL' THEN 0 ELSE 1 END,
    CASE WHEN x.index_year = 'OVERALL' THEN NULL ELSE CAST(x.index_year AS INT) END,
    CASE x.direction
        WHEN 'BEFORE_GT90'  THEN 1
        WHEN 'BEFORE_1_90'  THEN 2
        WHEN 'SAME_DAY'     THEN 3
        WHEN 'AFTER_1_30'   THEN 4
        WHEN 'AFTER_31_90'  THEN 5
        WHEN 'AFTER_91_365' THEN 6
        WHEN 'AFTER_GT365'  THEN 7
        WHEN 'NO_EVENT'     THEN 8
        ELSE 9
    END
;
-- 4) Pairwise timing summary: all four timing types combined (small-cell sentinel)
--    timing_type: first_to_first | first_to_closest | first_to_closest_before | first_to_closest_after
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
    SELECT 'first_to_first'          AS timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days FROM timing_pair_summary
    UNION ALL
    SELECT 'first_to_closest'        AS timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days FROM timing_pair_summary_first_to_closest
    UNION ALL
    SELECT 'first_to_closest_before' AS timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days FROM timing_pair_summary_first_to_closest_before
    UNION ALL
    SELECT 'first_to_closest_after'  AS timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days FROM timing_pair_summary_first_to_closest_after
) x
ORDER BY x.timing_type, x.from_event, x.to_event
;
-- 5) Pairwise timing summary stratified by index year
--    Same structure as chunk 04 (final_timing_pairwise.csv) but grouped by
--    YEAR(index_date) instead of OVERALL.  Used for year-over-year plots and
--    for the per-year columns in the §06 stability matrix.
--
--    Only first_to_first timing is exported here (DX->MET, MET->L01 are the
--    primary year-over-year metrics).  Small-cell suppression applied.
SELECT
    x.timing_type,
    x.index_year,
    x.from_event,
    x.to_event,
    CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN -@min_cell_count ELSE x.n_patients_with_pair END AS n_patients_with_pair,
    CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p25_days  END AS p25_days,
    CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p50_days  END AS p50_days,
    CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p75_days  END AS p75_days
FROM (
    -- first_to_first by year
    SELECT
        'first_to_first' AS timing_type,
        CAST(index_year_int AS VARCHAR(4)) AS index_year,
        from_event,
        to_event,
        COUNT(*) AS n_patients_with_pair,
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS p25_days,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS p50_days,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS FLOAT) END) AS p75_days
    FROM (
        SELECT p.from_event, p.to_event, p.days_diff,
            YEAR(pc.index_date) AS index_year_int,
            ROW_NUMBER() OVER (PARTITION BY YEAR(pc.index_date), p.from_event, p.to_event ORDER BY p.days_diff) AS rn,
            COUNT(*)     OVER (PARTITION BY YEAR(pc.index_date), p.from_event, p.to_event)                    AS cnt
        FROM patient_timing_pairs p
        JOIN patient_char pc ON p.person_id = pc.person_id
    ) y
    GROUP BY index_year_int, from_event, to_event
    UNION ALL
    -- first_to_closest_after by year (for MET->L01 post-MET treatment timing)
    SELECT
        'first_to_closest_after' AS timing_type,
        CAST(index_year_int AS VARCHAR(4)) AS index_year,
        from_event,
        to_event,
        COUNT(*) AS n_patients_with_pair,
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS p25_days,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS FLOAT) END) AS p50_days,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS FLOAT) END) AS p75_days
    FROM (
        SELECT p.from_event, p.to_event, p.days_diff,
            YEAR(pc.index_date) AS index_year_int,
            ROW_NUMBER() OVER (PARTITION BY YEAR(pc.index_date), p.from_event, p.to_event ORDER BY p.days_diff) AS rn,
            COUNT(*)     OVER (PARTITION BY YEAR(pc.index_date), p.from_event, p.to_event)                    AS cnt
        FROM patient_timing_pairs_first_to_closest_after p
        JOIN patient_char pc ON p.person_id = pc.person_id
    ) y
    GROUP BY index_year_int, from_event, to_event
) x
ORDER BY
    x.timing_type,
    x.from_event,
    x.to_event,
    CAST(x.index_year AS INT)
;
-- 6) Windowed ODX (and GDX) concept prevalence relative to DX index date
--    For each event family / concept, counts the number of distinct patients
--    with at least one event in each time window around index_date.
--
--    Windows (days = event_date - index_date):
--      pm30d      : -30 <= days <= 30
--      pm90d      : -90 <= days <= 90
--      pm180d     : -180 <= days <= 180
--      pm1yr      : -365 <= days <= 365
--      ever_before: days < 0
--      ever_after : days >= 0
--      ever       : any time (same as time_window='all' in chunk 02)
--
--    Only returns rows from the INDEX anchor (DX index date).
--    Covers ODX and GDX families (the clinically relevant exclusion criteria).
--    Restricted to top concepts by overall patient count to keep output size
--    manageable; the report builder will further limit to top N.
--
--    Small-cell suppression: counts <= @min_cell_count suppressed to -@min_cell_count.
WITH odx_gdx_events AS (
    -- ODX events with days relative to index_date
    SELECT
        'ODX' AS event_family,
        e.concept_id,
        e.person_id,
        day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) AS days_from_index
    FROM other_dx_events e
    JOIN cohort c ON e.person_id = c.person_id
    UNION ALL
    -- GDX events with days relative to index_date
    SELECT
        'GDX' AS event_family,
        e.concept_id,
        e.person_id,
        day(CAST(e.event_date AS TIMESTAMP) - CAST(c.index_date AS TIMESTAMP)) AS days_from_index
    FROM gen_cancer_events e
    JOIN cohort c ON e.person_id = c.person_id
),
windowed AS (
    SELECT
        event_family,
        concept_id,
        person_id,
        MAX(CASE WHEN days_from_index >= -30  AND days_from_index <= 30  THEN 1 ELSE 0 END) AS in_pm30d,
        MAX(CASE WHEN days_from_index >= -90  AND days_from_index <= 90  THEN 1 ELSE 0 END) AS in_pm90d,
        MAX(CASE WHEN days_from_index >= -180 AND days_from_index <= 180 THEN 1 ELSE 0 END) AS in_pm180d,
        MAX(CASE WHEN days_from_index >= -365 AND days_from_index <= 365 THEN 1 ELSE 0 END) AS in_pm1yr,
        MAX(CASE WHEN days_from_index < 0                                THEN 1 ELSE 0 END) AS in_ever_before,
        MAX(CASE WHEN days_from_index >= 0                               THEN 1 ELSE 0 END) AS in_ever_after,
        1 AS in_ever
    FROM odx_gdx_events
    GROUP BY event_family, concept_id, person_id
),
agg AS (
    SELECT
        event_family,
        concept_id,
        COUNT(*)                        AS n_ever,
        SUM(in_pm30d)                   AS n_pm30d,
        SUM(in_pm90d)                   AS n_pm90d,
        SUM(in_pm180d)                  AS n_pm180d,
        SUM(in_pm1yr)                   AS n_pm1yr,
        SUM(in_ever_before)             AS n_ever_before,
        SUM(in_ever_after)              AS n_ever_after
    FROM windowed
    GROUP BY event_family, concept_id
)
SELECT
    a.event_family,
    a.concept_id,
    CASE WHEN a.n_ever          <= @min_cell_count THEN -@min_cell_count ELSE a.n_ever          END AS n_ever,
    CASE WHEN a.n_ever          <= @min_cell_count THEN NULL             ELSE a.n_pm30d         END AS n_pm30d,
    CASE WHEN a.n_ever          <= @min_cell_count THEN NULL             ELSE a.n_pm90d         END AS n_pm90d,
    CASE WHEN a.n_ever          <= @min_cell_count THEN NULL             ELSE a.n_pm180d        END AS n_pm180d,
    CASE WHEN a.n_ever          <= @min_cell_count THEN NULL             ELSE a.n_pm1yr         END AS n_pm1yr,
    CASE WHEN a.n_ever          <= @min_cell_count THEN NULL             ELSE a.n_ever_before   END AS n_ever_before,
    CASE WHEN a.n_ever          <= @min_cell_count THEN NULL             ELSE a.n_ever_after    END AS n_ever_after
FROM agg a
ORDER BY a.event_family, a.n_ever DESC, a.concept_id
;
-- 7) L01 treatment exposure in 30-day windows around anchor dates
--    For each 30-day window k (window_start = anchor + 30*k days,
--    window_end = anchor + 30*(k+1) - 1 days), counts the number of
--    distinct patients with at least one L01 drug_exposure_start_date in
--    that window, as a fraction of the eligible denominator.
--
--    Two anchors:
--      INDEX    : all DX cohort patients; windows -12 to +48 (3 yr post-DX)
--      FIRST_MET: all patients with first_met_date; windows -6 to +24 (2 yr post-MET)
--
--    The denominator for each window is the number of patients whose
--    observation period covers the window midpoint (anchor + 30*k + 15 days).
--    This avoids deflating late windows due to censoring.
--    If observation_period data is unavailable, denominator = all anchor patients
--    (conservative; may underestimate late-window rates).
--
--    Output: one row per (anchor_event, window_index).
--    window_index: integer; window covers [anchor + 30*k, anchor + 30*(k+1) - 1].
--    Small-cell suppression on n_patients_with_l01.
WITH window_bounds AS (
    -- All (anchor, patient, window_index) combinations in scope
    SELECT
        'INDEX' AS anchor_event,
        c.person_id,
        c.index_date AS anchor_date,
        w.window_index
    FROM cohort c
    CROSS JOIN (
        SELECT -12 AS window_index UNION ALL SELECT -11 UNION ALL SELECT -10
        UNION ALL SELECT -9  UNION ALL SELECT -8  UNION ALL SELECT -7
        UNION ALL SELECT -6  UNION ALL SELECT -5  UNION ALL SELECT -4
        UNION ALL SELECT -3  UNION ALL SELECT -2  UNION ALL SELECT -1
        UNION ALL SELECT  0  UNION ALL SELECT  1  UNION ALL SELECT  2
        UNION ALL SELECT  3  UNION ALL SELECT  4  UNION ALL SELECT  5
        UNION ALL SELECT  6  UNION ALL SELECT  7  UNION ALL SELECT  8
        UNION ALL SELECT  9  UNION ALL SELECT 10  UNION ALL SELECT 11
        UNION ALL SELECT 12  UNION ALL SELECT 13  UNION ALL SELECT 14
        UNION ALL SELECT 15  UNION ALL SELECT 16  UNION ALL SELECT 17
        UNION ALL SELECT 18  UNION ALL SELECT 19  UNION ALL SELECT 20
        UNION ALL SELECT 21  UNION ALL SELECT 22  UNION ALL SELECT 23
        UNION ALL SELECT 24  UNION ALL SELECT 25  UNION ALL SELECT 26
        UNION ALL SELECT 27  UNION ALL SELECT 28  UNION ALL SELECT 29
        UNION ALL SELECT 30  UNION ALL SELECT 31  UNION ALL SELECT 32
        UNION ALL SELECT 33  UNION ALL SELECT 34  UNION ALL SELECT 35
        UNION ALL SELECT 36  UNION ALL SELECT 37  UNION ALL SELECT 38
        UNION ALL SELECT 39  UNION ALL SELECT 40  UNION ALL SELECT 41
        UNION ALL SELECT 42  UNION ALL SELECT 43  UNION ALL SELECT 44
        UNION ALL SELECT 45  UNION ALL SELECT 46  UNION ALL SELECT 47
    ) w
    UNION ALL
    SELECT
        'FIRST_MET' AS anchor_event,
        ms.person_id,
        ms.first_met_date AS anchor_date,
        w.window_index
    FROM met_summary ms
    CROSS JOIN (
        SELECT -6  AS window_index UNION ALL SELECT -5  UNION ALL SELECT -4
        UNION ALL SELECT -3  UNION ALL SELECT -2  UNION ALL SELECT -1
        UNION ALL SELECT  0  UNION ALL SELECT  1  UNION ALL SELECT  2
        UNION ALL SELECT  3  UNION ALL SELECT  4  UNION ALL SELECT  5
        UNION ALL SELECT  6  UNION ALL SELECT  7  UNION ALL SELECT  8
        UNION ALL SELECT  9  UNION ALL SELECT 10  UNION ALL SELECT 11
        UNION ALL SELECT 12  UNION ALL SELECT 13  UNION ALL SELECT 14
        UNION ALL SELECT 15  UNION ALL SELECT 16  UNION ALL SELECT 17
        UNION ALL SELECT 18  UNION ALL SELECT 19  UNION ALL SELECT 20
        UNION ALL SELECT 21  UNION ALL SELECT 22  UNION ALL SELECT 23
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
                WHEN le.event_date >= DATE_ADD(CAST(wb.anchor_date AS TIMESTAMP), 30 * wb.window_index)
                 AND le.event_date <  DATE_ADD(CAST(wb.anchor_date AS TIMESTAMP), 30 * (wb.window_index + 1))
                THEN 1 ELSE 0
            END
        ) AS has_l01_in_window
    FROM window_bounds wb
    LEFT JOIN l01_events le
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
                WHEN op.observation_period_start_date <= DATE_ADD(CAST(wb.anchor_date AS TIMESTAMP), 30 * wb.window_index + 15)
                 AND op.observation_period_end_date   >= DATE_ADD(CAST(wb.anchor_date AS TIMESTAMP), 30 * wb.window_index + 15)
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
        COUNT(*)                    AS n_eligible,
        SUM(wd.observed_at_midpoint) AS n_observed,
        SUM(wl.has_l01_in_window)   AS n_patients_with_l01
    FROM window_l01 wl
    JOIN window_denom wd
      ON wd.anchor_event = wl.anchor_event
     AND wd.person_id    = wl.person_id
     AND wd.window_index = wl.window_index
    GROUP BY wl.anchor_event, wl.window_index
)
SELECT
    a.anchor_event,
    a.window_index,
    a.n_eligible,
    CASE WHEN a.n_observed          <= @min_cell_count THEN -@min_cell_count ELSE a.n_observed          END AS n_observed,
    CASE WHEN a.n_patients_with_l01 <= @min_cell_count THEN -@min_cell_count ELSE a.n_patients_with_l01 END AS n_patients_with_l01
FROM agg a
ORDER BY a.anchor_event, a.window_index
;
-- 8) Death timing from INDEX and FIRST_MET (stratified by calendar year of index date and OVERALL)
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
FROM death_stratum_counts s
LEFT JOIN death_timing_quantiles q
  ON s.prevalence_year = q.prevalence_year
 AND s.anchor_event = q.anchor_event
LEFT JOIN followup_quantiles f
  ON s.prevalence_year = f.prevalence_year
 AND s.anchor_event = f.anchor_event
ORDER BY
    CASE WHEN s.prevalence_year = 'OVERALL' THEN 0 ELSE 1 END,
    CASE WHEN s.prevalence_year = 'OVERALL' THEN NULL ELSE CAST(s.prevalence_year AS INT) END,
    CASE WHEN s.anchor_event = 'INDEX' THEN 0 ELSE 1 END
;
-- 9) Demographics at anchor dates (INDEX = first DX, FIRST_MET = first MET)
-- Gender concept IDs (OMOP): 8507=Male, 8532=Female. Others treated as unknown.
WITH anchor_persons AS (
    SELECT
        'INDEX' AS anchor_event,
        c.person_id,
        c.index_date AS anchor_date
    FROM patient_char c
    WHERE c.index_date IS NOT NULL
    UNION ALL
    SELECT
        'FIRST_MET' AS anchor_event,
        c.person_id,
        c.first_met_date AS anchor_date
    FROM patient_char c
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
                THEN day(CAST(anchor_date AS TIMESTAMP) - CAST(CAST(birth_datetime AS TIMESTAMP) AS TIMESTAMP)) / 365.25
            WHEN year_of_birth IS NOT NULL
                THEN day(CAST(anchor_date AS TIMESTAMP) - CAST(CAST(CONCAT(CAST(year_of_birth AS STRING),'-',CAST(7 AS STRING),'-',CAST(1 AS STRING)) AS TIMESTAMP) AS TIMESTAMP)) / 365.25
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
        CAST(100.0 * SUM(CASE WHEN gender_concept_id = 8507 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS FLOAT) AS pct_male,
        CAST(100.0 * SUM(CASE WHEN gender_concept_id = 8532 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS FLOAT) AS pct_female
    FROM ages
    WHERE age_years IS NOT NULL
    GROUP BY anchor_event
) agg
JOIN (
    SELECT
        anchor_event,
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(age_years AS FLOAT) END) AS age_lq_years,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(age_years AS FLOAT) END) AS age_median_years,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(age_years AS FLOAT) END) AS age_uq_years
    FROM (
        SELECT anchor_event, age_years,
            ROW_NUMBER() OVER (PARTITION BY anchor_event ORDER BY age_years) AS rn,
            COUNT(*)     OVER (PARTITION BY anchor_event)                    AS cnt
        FROM ages
        WHERE age_years IS NOT NULL
    ) y
    GROUP BY anchor_event
) p
  ON agg.anchor_event = p.anchor_event
ORDER BY CASE WHEN agg.anchor_event = 'INDEX' THEN 0 ELSE 1 END
;
-- 10) Anchor DX (main cohort) codes: distinct patients and distinct patient-days per condition_concept_id
--     Patient-day = one calendar day per person (multiple DX rows on the same day collapse to one).
WITH dx_days AS (
    SELECT DISTINCT
        person_id,
        event_date,
        concept_id
    FROM dx_events
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
-- 11) L01 consecutive record gap distribution — decile summary
--     Intermediate tables #l01_event_days and #l01_consecutive_gaps are
--     built in 00_setup.sql (section L).
--
--     Two subgroups:
--       ALL_L01 : all DX cohort patients with any L01 record
--       MET_L01 : patients who also have a first_met_date
--
--     Output: one row per subgroup with gap-day deciles.
SELECT
    subgroup,
    COUNT(*)                  AS n_gaps,
    COUNT(DISTINCT person_id) AS n_patients_with_gaps,
    MIN(CASE WHEN 10.0 * rn >= cnt      THEN CAST(gap_days AS FLOAT) END) AS p10_days,
    MIN(CASE WHEN  4.0 * rn >= cnt      THEN CAST(gap_days AS FLOAT) END) AS p25_days,
    MIN(CASE WHEN  2.0 * rn >= cnt      THEN CAST(gap_days AS FLOAT) END) AS p50_days,
    MIN(CASE WHEN  4.0 * rn >= 3 * cnt THEN CAST(gap_days AS FLOAT) END) AS p75_days,
    MIN(CASE WHEN 10.0 * rn >= 9 * cnt THEN CAST(gap_days AS FLOAT) END) AS p90_days
FROM (
    SELECT subgroup, person_id, gap_days,
        ROW_NUMBER() OVER (PARTITION BY subgroup ORDER BY gap_days) AS rn,
        COUNT(*)     OVER (PARTITION BY subgroup)                   AS cnt
    FROM l01_consecutive_gaps
) x
GROUP BY subgroup
ORDER BY subgroup
;
-- 12) L01 consecutive record gap distribution — bucketed histogram
--     Intermediate table #l01_consecutive_gaps is built in 00_setup.sql
--     (section L).  Same subgroups as chunk 11 (ALL_L01, MET_L01).
--
--     Output: one row per (subgroup, gap_bucket) for histogram rendering.
SELECT
    subgroup,
    CASE
        WHEN gap_days <  30  THEN 'lt30d'
        WHEN gap_days <  60  THEN '30_59d'
        WHEN gap_days <  90  THEN '60_89d'
        WHEN gap_days < 180  THEN '90_179d'
        WHEN gap_days < 365  THEN '180_364d'
        ELSE 'ge365d'
    END AS gap_bucket,
    COUNT(*) AS n_gaps
FROM l01_consecutive_gaps
GROUP BY
    subgroup,
    CASE
        WHEN gap_days <  30  THEN 'lt30d'
        WHEN gap_days <  60  THEN '30_59d'
        WHEN gap_days <  90  THEN '60_89d'
        WHEN gap_days < 180  THEN '90_179d'
        WHEN gap_days < 365  THEN '180_364d'
        ELSE 'ge365d'
    END
ORDER BY
    subgroup,
    MIN(CASE
        WHEN gap_days <  30  THEN 1
        WHEN gap_days <  60  THEN 2
        WHEN gap_days <  90  THEN 3
        WHEN gap_days < 180  THEN 4
        WHEN gap_days < 365  THEN 5
        ELSE 6
    END)
;
-- 13) Death date vs observation period alignment — summary counts
--     For patients in the DX cohort (and the FIRST_MET subgroup), reports:
--       - n_death_before_obs : death_date < first observation_period_start
--                              (data quality error — rare but important)
--       - n_death_after_obs  : death_date > last  observation_period_end
--                              (gap distribution summarized in chunk 14)
--       - lq/median/uq/p90 percentiles of the post-obs gap (days).
--
--     Stratified by anchor (INDEX / FIRST_MET).
--     Small-cell suppression intentionally NOT applied here — these are
--     aggregate distribution statistics over (already small) flagged subsets.
WITH patient_obs AS (
    SELECT
        person_id,
        MIN(observation_period_start_date) AS first_obs_start,
        MAX(observation_period_end_date)   AS last_obs_end
    FROM @cdm_database_schema.observation_period
    WHERE person_id IN (SELECT person_id FROM cohort)
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
                THEN day(CAST(dos.death_date AS TIMESTAMP) - CAST(po.last_obs_end AS TIMESTAMP))
            ELSE NULL
        END AS gap_death_after_obs,
        CASE
            WHEN dos.death_date < po.first_obs_start
                THEN 1
            ELSE 0
        END AS death_before_obs
    FROM cohort c
    INNER JOIN death_obs_status dos ON dos.person_id = c.person_id
    LEFT JOIN met_summary ms ON ms.person_id = c.person_id
    LEFT JOIN patient_obs po  ON po.person_id  = c.person_id
)
SELECT
    'INDEX' AS anchor_event,
    SUM(CASE WHEN death_before_obs = 1 THEN 1 ELSE 0 END) AS n_death_before_obs,
    SUM(CASE WHEN gap_death_after_obs IS NOT NULL THEN 1 ELSE 0 END) AS n_death_after_obs,
    MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND  4.0 * rn >= non_null_cnt THEN CAST(gap_death_after_obs AS FLOAT) END) AS lq_gap_days,
    MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND  2.0 * rn >= non_null_cnt THEN CAST(gap_death_after_obs AS FLOAT) END) AS median_gap_days,
    MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND  4.0 * rn >= 3 * non_null_cnt THEN CAST(gap_death_after_obs AS FLOAT) END) AS uq_gap_days,
    MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 10.0 * rn >= 9 * non_null_cnt THEN CAST(gap_death_after_obs AS FLOAT) END) AS p90_gap_days
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
    MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND  4.0 * rn >= non_null_cnt THEN CAST(gap_death_after_obs AS FLOAT) END) AS lq_gap_days,
    MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND  2.0 * rn >= non_null_cnt THEN CAST(gap_death_after_obs AS FLOAT) END) AS median_gap_days,
    MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND  4.0 * rn >= 3 * non_null_cnt THEN CAST(gap_death_after_obs AS FLOAT) END) AS uq_gap_days,
    MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 10.0 * rn >= 9 * non_null_cnt THEN CAST(gap_death_after_obs AS FLOAT) END) AS p90_gap_days
FROM (
    SELECT death_before_obs, gap_death_after_obs,
        ROW_NUMBER() OVER (ORDER BY gap_death_after_obs) AS rn,
        SUM(CASE WHEN gap_death_after_obs IS NOT NULL THEN 1 ELSE 0 END) OVER () AS non_null_cnt
    FROM death_obs_gaps
    WHERE death_date IS NOT NULL
      AND first_met_date IS NOT NULL
) x
;
-- 14) Death date vs observation period — bucketed gap histogram
--     Restricted to patients where death_date > obs_period_end_date (i.e.
--     the n_death_after_obs subset summarized in chunk 13).  Binned at
--     30-day intervals up to 730 days, then a single ">=730d" bucket.
--
--     Output: one row per gap_bucket (INDEX anchor; FIRST_MET subset is a
--     proper subset whose distribution closely mirrors INDEX, so we only
--     export the INDEX histogram for the report).
WITH patient_obs AS (
    SELECT
        person_id,
        MIN(observation_period_start_date) AS first_obs_start,
        MAX(observation_period_end_date)   AS last_obs_end
    FROM @cdm_database_schema.observation_period
    WHERE person_id IN (SELECT person_id FROM cohort)
    GROUP BY person_id
),
death_obs_gaps AS (
    SELECT
        c.person_id,
        CASE
            WHEN dos.death_date > po.last_obs_end
                THEN day(CAST(dos.death_date AS TIMESTAMP) - CAST(po.last_obs_end AS TIMESTAMP))
            ELSE NULL
        END AS gap_death_after_obs
    FROM cohort c
    INNER JOIN death_obs_status dos ON dos.person_id = c.person_id
    LEFT JOIN patient_obs po  ON po.person_id  = c.person_id
)
SELECT
    CASE
        WHEN gap_death_after_obs <   30 THEN 'lt30d'
        WHEN gap_death_after_obs <   60 THEN '30_59d'
        WHEN gap_death_after_obs <   90 THEN '60_89d'
        WHEN gap_death_after_obs <  180 THEN '90_179d'
        WHEN gap_death_after_obs <  365 THEN '180_364d'
        WHEN gap_death_after_obs <  730 THEN '365_729d'
        ELSE 'ge730d'
    END AS gap_bucket,
    COUNT(*) AS n_patients
FROM death_obs_gaps
WHERE gap_death_after_obs IS NOT NULL
GROUP BY
    CASE
        WHEN gap_death_after_obs <   30 THEN 'lt30d'
        WHEN gap_death_after_obs <   60 THEN '30_59d'
        WHEN gap_death_after_obs <   90 THEN '60_89d'
        WHEN gap_death_after_obs <  180 THEN '90_179d'
        WHEN gap_death_after_obs <  365 THEN '180_364d'
        WHEN gap_death_after_obs <  730 THEN '365_729d'
        ELSE 'ge730d'
    END
ORDER BY
    MIN(CASE
        WHEN gap_death_after_obs <   30 THEN 1
        WHEN gap_death_after_obs <   60 THEN 2
        WHEN gap_death_after_obs <   90 THEN 3
        WHEN gap_death_after_obs <  180 THEN 4
        WHEN gap_death_after_obs <  365 THEN 5
        WHEN gap_death_after_obs <  730 THEN 6
        ELSE 7
    END)
;
-- 15) Distribution of distinct L01 event days per patient
--     Shows how many patients have 1, 2-6, 7-11, or 12+ distinct L01 days.
--     Patients with exactly 1 day cannot contribute to gap analyses (chunks 11-12).
--     Source: #l01_event_days (built in 00_setup.sql section L).
--
--     Two subgroups:
--       ALL_L01 : all DX cohort patients with any L01 record
--       MET_L01 : patients who also have a first_met_date
SELECT
    subgroup,
    CASE
        WHEN n_days =  1 THEN '1'
        WHEN n_days <= 6 THEN '2_6'
        WHEN n_days <= 11 THEN '7_11'
        ELSE '12plus'
    END AS days_bucket,
    COUNT(*) AS n_patients
FROM (
    SELECT e.person_id, COUNT(*) AS n_days, 'ALL_L01' AS subgroup
    FROM l01_event_days e
    GROUP BY e.person_id
    UNION ALL
    SELECT e.person_id, COUNT(*) AS n_days, 'MET_L01' AS subgroup
    FROM l01_event_days e
    JOIN met_summary ms ON e.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
    GROUP BY e.person_id
) x
GROUP BY
    subgroup,
    CASE
        WHEN n_days =  1 THEN '1'
        WHEN n_days <= 6 THEN '2_6'
        WHEN n_days <= 11 THEN '7_11'
        ELSE '12plus'
    END
ORDER BY
    subgroup,
    MIN(n_days)
;

