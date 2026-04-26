-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : sqlite extended
-- Translated     : 2026-04-26 18:36:21 BST
-- Source file    : sql/sql_server/characterization_full.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

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
DROP TABLE IF EXISTS temp.dx_anchor_include;
CREATE TEMP TABLE dx_anchor_include  (concept_id BIGINT NOT NULL,
    include_descendants SMALLINT NOT NULL
);
INSERT INTO temp.dx_anchor_include (concept_id, include_descendants) VALUES
    (197508, 1),      -- Malignant neoplasm of urinary bladder
    (4181357, 1),     -- Malignant tumor of renal pelvis
    (4177230, 1),     -- Malignant tumor of urethra
    (37163176, 1),    -- Transitional cell carcinoma of upper urinary tract
    (4178972, 1),     -- Malignant tumor of ureter
    (4091486, 0),     -- Malignant neoplasm of overlapping sites of urinary organs
    (44501785, 0),    -- Transitional cell carcinoma, NOS, of urinary system, NOS (ICDO3)
    (37110270, 1)     -- Primary urothelial carcinoma of overlapping sites of urinary organs
;
DROP TABLE IF EXISTS temp.dx_anchor_exclude;
CREATE TEMP TABLE dx_anchor_exclude  (concept_id BIGINT NOT NULL,
    include_descendants SMALLINT NOT NULL
);
INSERT INTO temp.dx_anchor_exclude (concept_id, include_descendants) VALUES
    (4280899, 1),
    (4289374, 1),
    (4280900, 1),
    (4283614, 1),
    (4289097, 1),
    (4280901, 1),
    (4289376, 1),
    (4280897, 1),
    (4200889, 1);
DROP TABLE IF EXISTS temp.dx_anchor_concepts;
CREATE TEMP TABLE dx_anchor_concepts  (concept_id BIGINT
);
INSERT INTO temp.dx_anchor_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM temp.dx_anchor_include i
JOIN @cdm_database_schema.concept_ancestor ca
  ON ca.ancestor_concept_id = i.concept_id
 AND (i.include_descendants = 1 OR ca.descendant_concept_id = i.concept_id);
DELETE FROM temp.dx_anchor_concepts
WHERE EXISTS (
    SELECT 1
    FROM temp.dx_anchor_exclude e
    JOIN @cdm_database_schema.concept_ancestor ca
      ON ca.ancestor_concept_id = e.concept_id
     AND temp.dx_anchor_concepts.concept_id = ca.descendant_concept_id
     AND (e.include_descendants = 1 OR ca.descendant_concept_id = e.concept_id)
);
------------------------------------------------------------
-- B) OTHER GENERALIZED CANCER DX CONCEPTS (GDX)
-- Default: distinct ancestors of DX anchor concepts, excluding anchor DX concepts themselves,
-- but constrained to descendants of 443392 (Malignant neoplastic disease) to avoid overly-broad ancestors.
-- (concept_ancestor includes self-links; we only want broader/generalized codes).
------------------------------------------------------------
DROP TABLE IF EXISTS temp.gen_cancer_concepts;
CREATE TEMP TABLE gen_cancer_concepts  (concept_id BIGINT
);
INSERT INTO temp.gen_cancer_concepts (concept_id)
SELECT DISTINCT ca.ancestor_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN temp.dx_anchor_concepts d
  ON ca.descendant_concept_id = d.concept_id
JOIN @cdm_database_schema.concept_ancestor malign
  ON malign.ancestor_concept_id = 443392
 AND malign.descendant_concept_id = ca.ancestor_concept_id
WHERE NOT EXISTS (
    SELECT 1
    FROM temp.dx_anchor_concepts dx
    WHERE dx.concept_id = ca.ancestor_concept_id
)
;
------------------------------------------------------------
-- C) OTHER CANCER DIAGNOSIS CONCEPTS (ODX)
-- Default: descendants of 443392 excluding DX + GDX sets.
------------------------------------------------------------
DROP TABLE IF EXISTS temp.other_dx_ancestor_concepts;
CREATE TEMP TABLE other_dx_ancestor_concepts  (ancestor_concept_id BIGINT
);
-- EDIT THIS LIST
INSERT INTO temp.other_dx_ancestor_concepts (ancestor_concept_id)
VALUES
    (443392) -- Malignant neoplastic disease
;
DROP TABLE IF EXISTS temp.other_dx_concepts;
CREATE TEMP TABLE other_dx_concepts  (concept_id BIGINT
);
INSERT INTO temp.other_dx_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN temp.other_dx_ancestor_concepts a
  ON ca.ancestor_concept_id = a.ancestor_concept_id
LEFT JOIN temp.dx_anchor_concepts dx
  ON dx.concept_id = ca.descendant_concept_id
LEFT JOIN temp.gen_cancer_concepts gdx
  ON gdx.concept_id = ca.descendant_concept_id
WHERE dx.concept_id IS NULL
  AND gdx.concept_id IS NULL
;
------------------------------------------------------------
-- D) METASTASIS CONCEPTS (MEASUREMENT)
-- Define via ancestor IDs (descendants pulled from concept_ancestor)
------------------------------------------------------------
DROP TABLE IF EXISTS temp.met_ancestor_concepts;
CREATE TEMP TABLE met_ancestor_concepts  (ancestor_concept_id BIGINT
);
-- Default: concept set "Secondary malignancy" from cohort_definitions/Target_Cohort_2B.json
INSERT INTO temp.met_ancestor_concepts (ancestor_concept_id)
VALUES
    (1633308),  -- AJCC/UICC Stage 4
    (1635142),  -- AJCC/UICC M1 Category
    (36769180)  -- Metastasis
;
DROP TABLE IF EXISTS temp.met_concepts;
CREATE TEMP TABLE met_concepts  (concept_id BIGINT
);
INSERT INTO temp.met_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN temp.met_ancestor_concepts a
  ON ca.ancestor_concept_id = a.ancestor_concept_id
;
------------------------------------------------------------
-- E) L01 TREATMENT CONCEPTS (DRUG_EXPOSURE)
------------------------------------------------------------
DROP TABLE IF EXISTS temp.l01_ancestor_concepts;
CREATE TEMP TABLE l01_ancestor_concepts  (ancestor_concept_id BIGINT
);
-- EDIT THIS LIST
INSERT INTO temp.l01_ancestor_concepts (ancestor_concept_id)
VALUES
    (21601387)
;
DROP TABLE IF EXISTS temp.l01_concepts;
CREATE TEMP TABLE l01_concepts  (concept_id BIGINT
);
INSERT INTO temp.l01_concepts (concept_id)
SELECT DISTINCT ca.descendant_concept_id
FROM @cdm_database_schema.concept_ancestor ca
JOIN temp.l01_ancestor_concepts a
  ON ca.ancestor_concept_id = a.ancestor_concept_id
;
------------------------------------------------------------
-- F) EVENT TABLES
------------------------------------------------------------
DROP TABLE IF EXISTS temp.dx_events;
CREATE TEMP TABLE dx_events  (person_id BIGINT,
    event_date DATE,
    concept_id BIGINT
);
INSERT INTO temp.dx_events (person_id, event_date, concept_id)
SELECT
    co.person_id,
    co.condition_start_date,
    co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN temp.dx_anchor_concepts d
  ON co.condition_concept_id = d.concept_id
;
-- Distinct anchor cohort persons; limits later F) pulls to rows that downstream joins to #cohort use anyway.
DROP TABLE IF EXISTS temp.anchor_person;
CREATE TEMP TABLE anchor_person  (person_id BIGINT
);
INSERT INTO temp.anchor_person (person_id)
SELECT DISTINCT person_id
FROM temp.dx_events
;
DROP TABLE IF EXISTS temp.other_dx_events;
CREATE TEMP TABLE other_dx_events  (person_id BIGINT,
    event_date DATE,
    concept_id BIGINT
);
INSERT INTO temp.other_dx_events (person_id, event_date, concept_id)
SELECT
    co.person_id,
    co.condition_start_date,
    co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN temp.anchor_person ap
  ON co.person_id = ap.person_id
JOIN temp.other_dx_concepts d
  ON co.condition_concept_id = d.concept_id
;
DROP TABLE IF EXISTS temp.gen_cancer_events;
CREATE TEMP TABLE gen_cancer_events  (person_id BIGINT,
    event_date DATE,
    concept_id BIGINT
);
INSERT INTO temp.gen_cancer_events (person_id, event_date, concept_id)
SELECT
    co.person_id,
    co.condition_start_date,
    co.condition_concept_id
FROM @cdm_database_schema.condition_occurrence co
JOIN temp.anchor_person ap
  ON co.person_id = ap.person_id
JOIN temp.gen_cancer_concepts g
  ON co.condition_concept_id = g.concept_id
;
DROP TABLE IF EXISTS temp.met_events;
CREATE TEMP TABLE met_events  (person_id BIGINT,
    event_date DATE,
    concept_id BIGINT
);
INSERT INTO temp.met_events (person_id, event_date, concept_id)
SELECT
    m.person_id,
    m.measurement_date,
    m.measurement_concept_id
FROM @cdm_database_schema.measurement m
JOIN temp.anchor_person ap
  ON m.person_id = ap.person_id
JOIN temp.met_concepts mc
  ON m.measurement_concept_id = mc.concept_id
;
DROP TABLE IF EXISTS temp.l01_events;
CREATE TEMP TABLE l01_events  (person_id BIGINT,
    event_date DATE,
    concept_id BIGINT
);
INSERT INTO temp.l01_events (person_id, event_date, concept_id)
SELECT
    de.person_id,
    de.drug_exposure_start_date,
    de.drug_concept_id
FROM @cdm_database_schema.drug_exposure de
JOIN temp.anchor_person ap
  ON de.person_id = ap.person_id
JOIN temp.l01_concepts l
  ON de.drug_concept_id = l.concept_id
;
-- Ingredient-level L01 events used for concept-level code counts/timing.
DROP TABLE IF EXISTS temp.l01_ingredient_events;
CREATE TEMP TABLE l01_ingredient_events  (person_id BIGINT,
    event_date DATE,
    concept_id BIGINT
);
INSERT INTO temp.l01_ingredient_events (person_id, event_date, concept_id)
SELECT DISTINCT
    de.person_id,
    de.drug_exposure_start_date,
    ca.ancestor_concept_id
FROM @cdm_database_schema.drug_exposure de
JOIN temp.anchor_person ap
  ON de.person_id = ap.person_id
JOIN temp.l01_concepts l
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
DROP TABLE IF EXISTS temp.cohort;
CREATE TEMP TABLE cohort  (person_id BIGINT,
    index_date DATE
);
INSERT INTO temp.cohort (person_id, index_date)
SELECT
    person_id,
    MIN(event_date) AS index_date
FROM temp.dx_events
GROUP BY person_id
;
DROP TABLE IF EXISTS temp.dx_summary;
CREATE TEMP TABLE dx_summary  (person_id BIGINT,
    n_dx_records INT,
    n_dx_codes INT
);
INSERT INTO temp.dx_summary (person_id, n_dx_records, n_dx_codes)
SELECT
    e.person_id,
    COUNT(*) AS n_dx_records,
    COUNT(DISTINCT e.concept_id) AS n_dx_codes
FROM temp.dx_events e
JOIN temp.cohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS temp.other_dx_summary;
CREATE TEMP TABLE other_dx_summary  (person_id BIGINT,
    first_other_dx_date DATE,
    n_other_dx_records INT,
    n_other_dx_codes INT
);
INSERT INTO temp.other_dx_summary (person_id, first_other_dx_date, n_other_dx_records, n_other_dx_codes)
SELECT
    e.person_id,
    MIN(e.event_date) AS first_other_dx_date,
    COUNT(*) AS n_other_dx_records,
    COUNT(DISTINCT e.concept_id) AS n_other_dx_codes
FROM temp.other_dx_events e
JOIN temp.cohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS temp.gen_cancer_summary;
CREATE TEMP TABLE gen_cancer_summary  (person_id BIGINT,
    first_gen_cancer_date DATE,
    n_gen_cancer_records INT,
    n_gen_cancer_codes INT
);
INSERT INTO temp.gen_cancer_summary (person_id, first_gen_cancer_date, n_gen_cancer_records, n_gen_cancer_codes)
SELECT
    e.person_id,
    MIN(e.event_date) AS first_gen_cancer_date,
    COUNT(*) AS n_gen_cancer_records,
    COUNT(DISTINCT e.concept_id) AS n_gen_cancer_codes
FROM temp.gen_cancer_events e
JOIN temp.cohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS temp.met_summary;
CREATE TEMP TABLE met_summary  (person_id BIGINT,
    first_met_date DATE,
    n_met_records INT
);
INSERT INTO temp.met_summary (person_id, first_met_date, n_met_records)
SELECT
    e.person_id,
    MIN(e.event_date) AS first_met_date,
    COUNT(*) AS n_met_records
FROM temp.met_events e
JOIN temp.cohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
;
DROP TABLE IF EXISTS temp.l01_summary;
CREATE TEMP TABLE l01_summary  (person_id BIGINT,
    first_l01_date DATE,
    n_l01_exposures INT
);
INSERT INTO temp.l01_summary (person_id, first_l01_date, n_l01_exposures)
SELECT
    e.person_id,
    MIN(e.event_date) AS first_l01_date,
    COUNT(*) AS n_l01_exposures
FROM temp.l01_events e
JOIN temp.cohort c
  ON e.person_id = c.person_id
GROUP BY e.person_id
;
-- H) EVENT CODE COUNTS (single table across event families)
------------------------------------------------------------
DROP TABLE IF EXISTS temp.event_code_counts;
CREATE TEMP TABLE event_code_counts  (anchor_event TEXT, -- INDEX or FIRST_MET
    event_family TEXT,
    concept_id BIGINT,
    n_records INT,
    n_patients INT
);
INSERT INTO temp.event_code_counts (anchor_event, event_family, concept_id, n_records, n_patients)
SELECT 'INDEX', 'DX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM temp.dx_events
WHERE person_id IN (SELECT person_id FROM temp.cohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'ODX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM temp.other_dx_events
WHERE person_id IN (SELECT person_id FROM temp.cohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'GDX', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM temp.gen_cancer_events
WHERE person_id IN (SELECT person_id FROM temp.cohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'MET', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM temp.met_events
WHERE person_id IN (SELECT person_id FROM temp.cohort)
GROUP BY concept_id
UNION ALL
SELECT 'INDEX', 'L01', concept_id, COUNT(*), COUNT(DISTINCT person_id)
FROM temp.l01_ingredient_events
WHERE person_id IN (SELECT person_id FROM temp.cohort)
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'DX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM temp.dx_events e
JOIN temp.met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'ODX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM temp.other_dx_events e
JOIN temp.met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'GDX', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM temp.gen_cancer_events e
JOIN temp.met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'MET', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM temp.met_events e
JOIN temp.met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
UNION ALL
SELECT 'FIRST_MET', 'L01', concept_id, COUNT(*), COUNT(DISTINCT e.person_id)
FROM temp.l01_ingredient_events e
JOIN temp.met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY concept_id
;
DROP TABLE IF EXISTS temp.event_code_counts_before_after;
CREATE TEMP TABLE event_code_counts_before_after  (anchor_event TEXT, -- INDEX
    event_family TEXT,
    time_relative TEXT, -- BEFORE or AFTER (relative to index_date)
    concept_id BIGINT,
    n_records INT,
    n_patients INT
);
INSERT INTO temp.event_code_counts_before_after (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
SELECT 'INDEX',
       'DX',
       CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END AS time_relative,
       e.concept_id,
       COUNT(*) AS n_records,
       COUNT(DISTINCT e.person_id) AS n_patients
FROM temp.dx_events e
JOIN temp.cohort c
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
FROM temp.other_dx_events e
JOIN temp.cohort c
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
FROM temp.gen_cancer_events e
JOIN temp.cohort c
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
FROM temp.met_events e
JOIN temp.cohort c
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
FROM temp.l01_ingredient_events e
JOIN temp.cohort c
  ON e.person_id = c.person_id
GROUP BY
    CASE WHEN DATEDIFF(DAY, c.index_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    e.concept_id
;
DROP TABLE IF EXISTS temp.event_code_counts_before_after_first_met;
CREATE TEMP TABLE event_code_counts_before_after_first_met  (anchor_event TEXT, -- FIRST_MET
    event_family TEXT,
    time_relative TEXT, -- BEFORE or AFTER (relative to first_met_date)
    concept_id BIGINT,
    n_records INT,
    n_patients INT
);
INSERT INTO temp.event_code_counts_before_after_first_met (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
SELECT 'FIRST_MET',
       'DX',
       CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END AS time_relative,
       e.concept_id,
       COUNT(*) AS n_records,
       COUNT(DISTINCT e.person_id) AS n_patients
FROM temp.dx_events e
JOIN temp.met_summary ms
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
FROM temp.other_dx_events e
JOIN temp.met_summary ms
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
FROM temp.gen_cancer_events e
JOIN temp.met_summary ms
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
FROM temp.met_events e
JOIN temp.met_summary ms
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
FROM temp.l01_ingredient_events e
JOIN temp.met_summary ms
  ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
GROUP BY
    CASE WHEN DATEDIFF(DAY, ms.first_met_date, e.event_date) < 0 THEN 'BEFORE' ELSE 'AFTER' END,
    e.concept_id
;
DROP TABLE IF EXISTS temp.event_code_all_events;
CREATE TEMP TABLE event_code_all_events  (anchor_event TEXT,
    event_family TEXT,
    concept_id BIGINT,
    person_id BIGINT,
    days_diff INT,
    event_date DATE
);
INSERT INTO temp.event_code_all_events (
    anchor_event, event_family, concept_id, person_id, days_diff, event_date
)
SELECT 'INDEX' AS anchor_event, 'DX' AS event_family, e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date) AS days_diff, e.event_date
FROM temp.dx_events e
JOIN temp.cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'ODX', e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date), e.event_date
FROM temp.other_dx_events e
JOIN temp.cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'GDX', e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date), e.event_date
FROM temp.gen_cancer_events e
JOIN temp.cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'MET', e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date), e.event_date
FROM temp.met_events e
JOIN temp.cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'INDEX', 'L01', e.concept_id, e.person_id, DATEDIFF(DAY, c.index_date, e.event_date), e.event_date
FROM temp.l01_ingredient_events e
JOIN temp.cohort c ON e.person_id = c.person_id
UNION ALL
SELECT 'FIRST_MET', 'DX', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM temp.dx_events e
JOIN temp.met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'ODX', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM temp.other_dx_events e
JOIN temp.met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'GDX', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM temp.gen_cancer_events e
JOIN temp.met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'MET', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM temp.met_events e
JOIN temp.met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
UNION ALL
SELECT 'FIRST_MET', 'L01', e.concept_id, e.person_id, DATEDIFF(DAY, ms.first_met_date, e.event_date), e.event_date
FROM temp.l01_ingredient_events e
JOIN temp.met_summary ms ON e.person_id = ms.person_id
WHERE ms.first_met_date IS NOT NULL
;
DROP TABLE IF EXISTS temp.event_code_patient_chosen_first;
CREATE TEMP TABLE event_code_patient_chosen_first  (anchor_event TEXT,
    event_family TEXT,
    concept_id BIGINT,
    person_id BIGINT,
    days_diff INT
);
INSERT INTO temp.event_code_patient_chosen_first (anchor_event, event_family, concept_id, person_id, days_diff)
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
            ORDER BY DATEDIFF(DAY, CAST('1900-01-01' AS DATE), event_date) ASC, event_date ASC
        ) AS rn
    FROM temp.event_code_all_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS temp.event_code_patient_chosen_closest;
CREATE TEMP TABLE event_code_patient_chosen_closest  (anchor_event TEXT,
    event_family TEXT,
    concept_id BIGINT,
    person_id BIGINT,
    days_diff INT
);
INSERT INTO temp.event_code_patient_chosen_closest (anchor_event, event_family, concept_id, person_id, days_diff)
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
    FROM temp.event_code_all_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS temp.event_code_timing_summary;
CREATE TEMP TABLE event_code_timing_summary  (anchor_event TEXT,
    event_family TEXT,
    concept_id BIGINT,
    n_patients_with_code_timing INT,
    lq_days_first REAL,
    median_days_first REAL,
    uq_days_first REAL,
    lq_days_closest REAL,
    median_days_closest REAL,
    uq_days_closest REAL
);
INSERT INTO temp.event_code_timing_summary (
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
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_diff) AS lq_days_first,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY days_diff) AS median_days_first,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_diff) AS uq_days_first
    FROM temp.event_code_patient_chosen_first
    GROUP BY anchor_event, event_family, concept_id
) f
INNER JOIN (
    SELECT
        anchor_event,
        event_family,
        concept_id,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_diff) AS lq_days_closest,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY days_diff) AS median_days_closest,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_diff) AS uq_days_closest
    FROM temp.event_code_patient_chosen_closest
    GROUP BY anchor_event, event_family, concept_id
) k
  ON f.anchor_event = k.anchor_event
 AND f.event_family = k.event_family
 AND f.concept_id = k.concept_id
;
DROP TABLE IF EXISTS temp.event_code_ba_events;
CREATE TEMP TABLE event_code_ba_events  (anchor_event TEXT,
    event_family TEXT,
    time_relative TEXT,
    concept_id BIGINT,
    person_id BIGINT,
    days_diff INT,
    event_date DATE
);
INSERT INTO temp.event_code_ba_events (
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
FROM temp.event_code_all_events
;
DROP TABLE IF EXISTS temp.event_code_patient_chosen_before_after_first;
CREATE TEMP TABLE event_code_patient_chosen_before_after_first  (anchor_event TEXT,
    event_family TEXT,
    time_relative TEXT,
    concept_id BIGINT,
    person_id BIGINT,
    days_diff INT
);
INSERT INTO temp.event_code_patient_chosen_before_after_first (
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
            ORDER BY DATEDIFF(DAY, CAST('1900-01-01' AS DATE), event_date) ASC, event_date ASC
        ) AS rn
    FROM temp.event_code_ba_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS temp.event_code_patient_chosen_before_after_closest;
CREATE TEMP TABLE event_code_patient_chosen_before_after_closest  (anchor_event TEXT,
    event_family TEXT,
    time_relative TEXT,
    concept_id BIGINT,
    person_id BIGINT,
    days_diff INT
);
INSERT INTO temp.event_code_patient_chosen_before_after_closest (
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
    FROM temp.event_code_ba_events
) x
WHERE rn = 1
;
DROP TABLE IF EXISTS temp.event_code_timing_before_after_summary;
CREATE TEMP TABLE event_code_timing_before_after_summary  (anchor_event TEXT,
    event_family TEXT,
    time_relative TEXT,
    concept_id BIGINT,
    n_patients_with_code_timing INT,
    lq_days_first REAL,
    median_days_first REAL,
    uq_days_first REAL,
    lq_days_closest REAL,
    median_days_closest REAL,
    uq_days_closest REAL
);
INSERT INTO temp.event_code_timing_before_after_summary (
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
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_diff) AS lq_days_first,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY days_diff) AS median_days_first,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_diff) AS uq_days_first
    FROM temp.event_code_patient_chosen_before_after_first
    GROUP BY anchor_event, event_family, time_relative, concept_id
) f
INNER JOIN (
    SELECT
        anchor_event,
        event_family,
        time_relative,
        concept_id,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_diff) AS lq_days_closest,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY days_diff) AS median_days_closest,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_diff) AS uq_days_closest
    FROM temp.event_code_patient_chosen_before_after_closest
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
DROP TABLE IF EXISTS temp.patient_char;
CREATE TEMP TABLE patient_char  (person_id BIGINT,
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
INSERT INTO temp.patient_char (
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
FROM temp.cohort c
LEFT JOIN temp.dx_summary dx
       ON c.person_id = dx.person_id
LEFT JOIN temp.other_dx_summary odx
       ON c.person_id = odx.person_id
LEFT JOIN temp.gen_cancer_summary gdx
       ON c.person_id = gdx.person_id
LEFT JOIN temp.met_summary mt
       ON c.person_id = mt.person_id
LEFT JOIN temp.l01_summary l01
       ON c.person_id = l01.person_id
;
------------------------------------------------------------
-- J) FULL CROSSWISE TIMING PAIRS
------------------------------------------------------------
DROP TABLE IF EXISTS temp.patient_timing_pairs;
CREATE TEMP TABLE patient_timing_pairs  (person_id BIGINT,
    from_event TEXT,
    to_event TEXT,
    days_diff INT
);
WITH events  AS (SELECT person_id,  CAST('DX' as TEXT) AS event_name, index_date AS event_date FROM temp.patient_char
    UNION ALL
    SELECT person_id, 'ODX', first_other_dx_date FROM temp.patient_char
    UNION ALL
    SELECT person_id, 'GDX', first_gen_cancer_date FROM temp.patient_char
    UNION ALL
    SELECT person_id, 'MET', first_met_date FROM temp.patient_char
    UNION ALL
    SELECT person_id, 'L01', first_l01_date FROM temp.patient_char
)
INSERT INTO temp.patient_timing_pairs (person_id, from_event, to_event, days_diff)
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
DROP TABLE IF EXISTS temp.timing_pair_summary;
CREATE TEMP TABLE timing_pair_summary  (from_event TEXT,
    to_event TEXT,
    n_patients_with_pair INT,
    p05_days REAL,
    p10_days REAL,
    p20_days REAL,
    p25_days REAL,
    p30_days REAL,
    p40_days REAL,
    p50_days REAL,
    p60_days REAL,
    p70_days REAL,
    p75_days REAL,
    p80_days REAL,
    p90_days REAL,
    p95_days REAL
);
INSERT INTO temp.timing_pair_summary (
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
    PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY days_diff) AS p05_days,
    PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY days_diff) AS p10_days,
    PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY days_diff) AS p20_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_diff) AS p25_days,
    PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY days_diff) AS p30_days,
    PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY days_diff) AS p40_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY days_diff) AS p50_days,
    PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY days_diff) AS p60_days,
    PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY days_diff) AS p70_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_diff) AS p75_days,
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY days_diff) AS p80_days,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY days_diff) AS p90_days,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY days_diff) AS p95_days
FROM temp.patient_timing_pairs
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS temp.all_events_for_pairs;
CREATE TEMP TABLE all_events_for_pairs  (person_id BIGINT,
    event_family TEXT,
    event_date DATE
);
INSERT INTO temp.all_events_for_pairs (person_id, event_family, event_date)
SELECT person_id, 'DX', event_date FROM temp.dx_events
UNION ALL
SELECT person_id, 'ODX', event_date FROM temp.other_dx_events
UNION ALL
SELECT person_id, 'GDX', event_date FROM temp.gen_cancer_events
UNION ALL
SELECT person_id, 'MET', event_date FROM temp.met_events
UNION ALL
SELECT person_id, 'L01', event_date FROM temp.l01_events
;
DROP TABLE IF EXISTS temp.first_event_dates;
CREATE TEMP TABLE first_event_dates  (person_id BIGINT,
    from_event TEXT,
    from_first_date DATE
);
INSERT INTO temp.first_event_dates (person_id, from_event, from_first_date)
SELECT person_id, 'DX', index_date FROM temp.patient_char
UNION ALL
SELECT person_id, 'ODX', first_other_dx_date FROM temp.patient_char WHERE first_other_dx_date IS NOT NULL
UNION ALL
SELECT person_id, 'GDX', first_gen_cancer_date FROM temp.patient_char WHERE first_gen_cancer_date IS NOT NULL
UNION ALL
SELECT person_id, 'MET', first_met_date FROM temp.patient_char WHERE first_met_date IS NOT NULL
UNION ALL
SELECT person_id, 'L01', first_l01_date FROM temp.patient_char WHERE first_l01_date IS NOT NULL
;
DROP TABLE IF EXISTS temp.patient_timing_pairs_first_to_closest;
CREATE TEMP TABLE patient_timing_pairs_first_to_closest  (person_id BIGINT,
    from_event TEXT,
    to_event TEXT,
    days_diff INT
);
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
    FROM temp.first_event_dates f
    JOIN temp.all_events_for_pairs a
      ON f.person_id = a.person_id
     AND f.from_event <> a.event_family
)
INSERT INTO temp.patient_timing_pairs_first_to_closest (person_id, from_event, to_event, days_diff)
SELECT
    person_id,
    from_event,
    to_event,
    days_diff
FROM ranked
WHERE rn = 1
;
DROP TABLE IF EXISTS temp.timing_pair_summary_first_to_closest;
CREATE TEMP TABLE timing_pair_summary_first_to_closest  (from_event TEXT,
    to_event TEXT,
    n_patients_with_pair INT,
    p05_days REAL,
    p10_days REAL,
    p20_days REAL,
    p25_days REAL,
    p30_days REAL,
    p40_days REAL,
    p50_days REAL,
    p60_days REAL,
    p70_days REAL,
    p75_days REAL,
    p80_days REAL,
    p90_days REAL,
    p95_days REAL
);
INSERT INTO temp.timing_pair_summary_first_to_closest (
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
    PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY days_diff) AS p05_days,
    PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY days_diff) AS p10_days,
    PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY days_diff) AS p20_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_diff) AS p25_days,
    PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY days_diff) AS p30_days,
    PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY days_diff) AS p40_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY days_diff) AS p50_days,
    PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY days_diff) AS p60_days,
    PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY days_diff) AS p70_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_diff) AS p75_days,
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY days_diff) AS p80_days,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY days_diff) AS p90_days,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY days_diff) AS p95_days
FROM temp.patient_timing_pairs_first_to_closest
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS temp.patient_timing_pairs_first_to_closest_before;
CREATE TEMP TABLE patient_timing_pairs_first_to_closest_before  (person_id BIGINT,
    from_event TEXT,
    to_event TEXT,
    days_diff INT
);
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
    FROM temp.first_event_dates f
    JOIN temp.all_events_for_pairs a
      ON f.person_id = a.person_id
     AND f.from_event <> a.event_family
    WHERE DATEDIFF(DAY, f.from_first_date, a.event_date) < 0
)
INSERT INTO temp.patient_timing_pairs_first_to_closest_before (person_id, from_event, to_event, days_diff)
SELECT
    person_id,
    from_event,
    to_event,
    days_diff
FROM ranked_before
WHERE rn = 1
;
DROP TABLE IF EXISTS temp.timing_pair_summary_first_to_closest_before;
CREATE TEMP TABLE timing_pair_summary_first_to_closest_before  (from_event TEXT,
    to_event TEXT,
    n_patients_with_pair INT,
    p05_days REAL,
    p10_days REAL,
    p20_days REAL,
    p25_days REAL,
    p30_days REAL,
    p40_days REAL,
    p50_days REAL,
    p60_days REAL,
    p70_days REAL,
    p75_days REAL,
    p80_days REAL,
    p90_days REAL,
    p95_days REAL
);
INSERT INTO temp.timing_pair_summary_first_to_closest_before (
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
    PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY days_diff) AS p05_days,
    PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY days_diff) AS p10_days,
    PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY days_diff) AS p20_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_diff) AS p25_days,
    PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY days_diff) AS p30_days,
    PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY days_diff) AS p40_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY days_diff) AS p50_days,
    PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY days_diff) AS p60_days,
    PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY days_diff) AS p70_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_diff) AS p75_days,
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY days_diff) AS p80_days,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY days_diff) AS p90_days,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY days_diff) AS p95_days
FROM temp.patient_timing_pairs_first_to_closest_before
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS temp.patient_timing_pairs_first_to_closest_after;
CREATE TEMP TABLE patient_timing_pairs_first_to_closest_after  (person_id BIGINT,
    from_event TEXT,
    to_event TEXT,
    days_diff INT
);
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
    FROM temp.first_event_dates f
    JOIN temp.all_events_for_pairs a
      ON f.person_id = a.person_id
     AND f.from_event <> a.event_family
    WHERE DATEDIFF(DAY, f.from_first_date, a.event_date) >= 0
)
INSERT INTO temp.patient_timing_pairs_first_to_closest_after (person_id, from_event, to_event, days_diff)
SELECT
    person_id,
    from_event,
    to_event,
    days_diff
FROM ranked_after
WHERE rn = 1
;
DROP TABLE IF EXISTS temp.timing_pair_summary_first_to_closest_after;
CREATE TEMP TABLE timing_pair_summary_first_to_closest_after  (from_event TEXT,
    to_event TEXT,
    n_patients_with_pair INT,
    p05_days REAL,
    p10_days REAL,
    p20_days REAL,
    p25_days REAL,
    p30_days REAL,
    p40_days REAL,
    p50_days REAL,
    p60_days REAL,
    p70_days REAL,
    p75_days REAL,
    p80_days REAL,
    p90_days REAL,
    p95_days REAL
);
INSERT INTO temp.timing_pair_summary_first_to_closest_after (
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
    PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY days_diff) AS p05_days,
    PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY days_diff) AS p10_days,
    PERCENTILE_CONT(0.20) WITHIN GROUP (ORDER BY days_diff) AS p20_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_diff) AS p25_days,
    PERCENTILE_CONT(0.30) WITHIN GROUP (ORDER BY days_diff) AS p30_days,
    PERCENTILE_CONT(0.40) WITHIN GROUP (ORDER BY days_diff) AS p40_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY days_diff) AS p50_days,
    PERCENTILE_CONT(0.60) WITHIN GROUP (ORDER BY days_diff) AS p60_days,
    PERCENTILE_CONT(0.70) WITHIN GROUP (ORDER BY days_diff) AS p70_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_diff) AS p75_days,
    PERCENTILE_CONT(0.80) WITHIN GROUP (ORDER BY days_diff) AS p80_days,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY days_diff) AS p90_days,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY days_diff) AS p95_days
FROM temp.patient_timing_pairs_first_to_closest_after
GROUP BY from_event, to_event
;
DROP TABLE IF EXISTS temp.event_presence;
CREATE TEMP TABLE event_presence  (person_id BIGINT,
    has_dx INT,
    has_odx INT,
    has_gdx INT,
    has_met INT,
    has_l01 INT
);
INSERT INTO temp.event_presence (
    person_id, has_dx, has_odx, has_gdx, has_met, has_l01
)
SELECT
    person_id,
    1,
    CASE WHEN first_other_dx_date IS NOT NULL THEN 1 ELSE 0 END,
    CASE WHEN first_gen_cancer_date IS NOT NULL THEN 1 ELSE 0 END,
    CASE WHEN first_met_date IS NOT NULL THEN 1 ELSE 0 END,
    CASE WHEN first_l01_date IS NOT NULL THEN 1 ELSE 0 END
FROM temp.patient_char
;
------------------------------------------------------------
-- J-bis) DEATH TIMING FROM INDEX AND FIRST_MET ANCHORS
------------------------------------------------------------
DROP TABLE IF EXISTS temp.death_index_long;
CREATE TEMP TABLE death_index_long  (prevalence_year TEXT,
    days_to_death INT
);
INSERT INTO temp.death_index_long (prevalence_year, days_to_death)
SELECT 'OVERALL', DATEDIFF(DAY, c.index_date, d.death_date)
FROM temp.cohort c
INNER JOIN (
    SELECT person_id, MIN(death_date) AS death_date
    FROM @cdm_database_schema.death
    GROUP BY person_id
) d ON d.person_id = c.person_id
WHERE d.death_date >= c.index_date
UNION ALL
SELECT CAST(YEAR(c.index_date) AS TEXT), DATEDIFF(DAY, c.index_date, d.death_date)
FROM temp.cohort c
INNER JOIN (
    SELECT person_id, MIN(death_date) AS death_date
    FROM @cdm_database_schema.death
    GROUP BY person_id
) d ON d.person_id = c.person_id
WHERE d.death_date >= c.index_date
;
DROP TABLE IF EXISTS temp.death_first_met_long;
CREATE TEMP TABLE death_first_met_long  (prevalence_year TEXT,
    days_to_death INT
);
INSERT INTO temp.death_first_met_long (prevalence_year, days_to_death)
SELECT 'OVERALL', DATEDIFF(DAY, ms.first_met_date, d.death_date)
FROM temp.cohort c
INNER JOIN temp.met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN (
    SELECT person_id, MIN(death_date) AS death_date
    FROM @cdm_database_schema.death
    GROUP BY person_id
) d ON d.person_id = c.person_id
WHERE d.death_date >= ms.first_met_date
UNION ALL
SELECT CAST(YEAR(c.index_date) AS TEXT), DATEDIFF(DAY, ms.first_met_date, d.death_date)
FROM temp.cohort c
INNER JOIN temp.met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
INNER JOIN (
    SELECT person_id, MIN(death_date) AS death_date
    FROM @cdm_database_schema.death
    GROUP BY person_id
) d ON d.person_id = c.person_id
WHERE d.death_date >= ms.first_met_date
;
DROP TABLE IF EXISTS temp.death_stratum_counts;
CREATE TEMP TABLE death_stratum_counts  (prevalence_year TEXT,
    anchor_event TEXT,
    n_patients INT,
    n_deaths INT
);
INSERT INTO temp.death_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths)
SELECT
    CASE
        WHEN GROUPING(YEAR(c.index_date)) = 1 THEN 'OVERALL'
        ELSE CAST(YEAR(c.index_date) AS TEXT)
    END,
    'INDEX',
    COUNT(*),
    SUM(CASE WHEN d.death_date IS NOT NULL AND d.death_date >= c.index_date THEN 1 ELSE 0 END)
FROM temp.cohort c
LEFT JOIN (
    SELECT person_id, MIN(death_date) AS death_date
    FROM @cdm_database_schema.death
    GROUP BY person_id
) d ON d.person_id = c.person_id
GROUP BY GROUPING SETS ((), (YEAR(c.index_date)))
;
INSERT INTO temp.death_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths)
SELECT
    CASE
        WHEN GROUPING(YEAR(c.index_date)) = 1 THEN 'OVERALL'
        ELSE CAST(YEAR(c.index_date) AS TEXT)
    END,
    'FIRST_MET',
    COUNT(*),
    SUM(CASE WHEN d.death_date IS NOT NULL AND d.death_date >= ms.first_met_date THEN 1 ELSE 0 END)
FROM temp.cohort c
INNER JOIN temp.met_summary ms ON c.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
LEFT JOIN (
    SELECT person_id, MIN(death_date) AS death_date
    FROM @cdm_database_schema.death
    GROUP BY person_id
) d ON d.person_id = c.person_id
GROUP BY GROUPING SETS ((), (YEAR(c.index_date)))
;
DROP TABLE IF EXISTS temp.death_timing_long;
CREATE TEMP TABLE death_timing_long  (prevalence_year TEXT,
    anchor_event TEXT,
    days_to_death INT
);
INSERT INTO temp.death_timing_long (prevalence_year, anchor_event, days_to_death)
SELECT prevalence_year, 'INDEX', days_to_death FROM temp.death_index_long
UNION ALL
SELECT prevalence_year, 'FIRST_MET', days_to_death FROM temp.death_first_met_long
;
DROP TABLE IF EXISTS temp.death_timing_quantiles;
CREATE TEMP TABLE death_timing_quantiles  (prevalence_year TEXT,
    anchor_event TEXT,
    n_deaths_in_dist INT,
    p05_days REAL,
    p10_days REAL,
    lq_days REAL,
    median_days REAL,
    uq_days REAL,
    p90_days REAL,
    p95_days REAL
);
INSERT INTO temp.death_timing_quantiles (
    prevalence_year,
    anchor_event,
    n_deaths_in_dist,
    p05_days,
    p10_days,
    lq_days,
    median_days,
    uq_days,
    p90_days,
    p95_days
)
SELECT
    prevalence_year,
    anchor_event,
    COUNT(*) AS n_deaths_in_dist,
    PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY days_to_death) AS p05_days,
    PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY days_to_death) AS p10_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY days_to_death) AS lq_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY days_to_death) AS median_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY days_to_death) AS uq_days,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY days_to_death) AS p90_days,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY days_to_death) AS p95_days
FROM temp.death_timing_long
GROUP BY prevalence_year, anchor_event
;
------------------------------------------------------------
-- K) FINAL SELECTS (export to CSV from SQL client)
------------------------------------------------------------
-- 1) Population prevalence
WITH base  AS (SELECT CASE
            WHEN GROUPING(YEAR(index_date)) = 1 THEN  CAST('OVERALL' as TEXT) ELSE CAST(YEAR(index_date) AS TEXT)
        END AS prevalence_year,
        COUNT(*) AS n_patients,
        SUM(CASE WHEN first_other_dx_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_other_dx,
        SUM(CASE WHEN first_gen_cancer_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_gen_cancer_dx,
        SUM(CASE WHEN first_met_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_met,
        SUM(CASE WHEN first_l01_date IS NOT NULL THEN 1 ELSE 0 END) AS n_with_l01
    FROM temp.patient_char
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
    TRY_CAST(prevalence_year AS INT)
;
-- 2) Event code counts by family+concept_id (small-cell suppressed)
--    Concept-level timing: FIRST (earliest) and CLOSEST (min |days|) per person/concept; lq/median/uq = FIRST for legacy.
SELECT
    c.anchor_event,
    c.event_family,
    c.concept_id,
    CASE WHEN c.n_patients <= @min_cell_count THEN -@min_cell_count ELSE c.n_records END AS n_records,
    CASE WHEN c.n_patients <= @min_cell_count THEN -@min_cell_count ELSE c.n_patients END AS n_patients,
    CASE WHEN c.n_patients <= @min_cell_count THEN -@min_cell_count ELSE t.n_patients_with_code_timing END AS n_patients_with_code_timing,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.lq_days_first END AS lq_days_first,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.median_days_first END AS median_days_first,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.uq_days_first END AS uq_days_first,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.lq_days_closest END AS lq_days_closest,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.median_days_closest END AS median_days_closest,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.uq_days_closest END AS uq_days_closest,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.lq_days_first END AS lq_days,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.median_days_first END AS median_days,
    CASE WHEN c.n_patients <= @min_cell_count THEN NULL ELSE t.uq_days_first END AS uq_days
FROM temp.event_code_counts c
LEFT JOIN temp.event_code_timing_summary t
  ON c.anchor_event = t.anchor_event
 AND c.event_family = t.event_family
 AND c.concept_id = t.concept_id
ORDER BY c.anchor_event, c.event_family, c.n_patients DESC, c.n_records DESC, c.concept_id
;
-- 3) Suppressed-row audit for event_code_counts
SELECT
    event_family,
    CASE
        WHEN COUNT(*) BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
        ELSE COUNT(*)
    END AS n_concepts_total,
    CASE
        WHEN SUM(CASE WHEN n_patients <= @min_cell_count THEN 1 ELSE 0 END) BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
        ELSE SUM(CASE WHEN n_patients <= @min_cell_count THEN 1 ELSE 0 END)
    END AS n_concepts_suppressed
FROM temp.event_code_counts
GROUP BY event_family
ORDER BY event_family
;
-- 3b) Event code counts by family+concept_id split BEFORE/AFTER
--     around both INDEX and FIRST_MET anchors (small-cell sentinel)
SELECT
    x.anchor_event,
    x.event_family,
    x.time_relative,
    x.concept_id,
    CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE x.n_records END AS n_records,
    CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE x.n_patients END AS n_patients,
    CASE WHEN x.n_patients <= @min_cell_count THEN -@min_cell_count ELSE t.n_patients_with_code_timing END AS n_patients_with_code_timing,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.lq_days_first END AS lq_days_first,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.median_days_first END AS median_days_first,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.uq_days_first END AS uq_days_first,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.lq_days_closest END AS lq_days_closest,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.median_days_closest END AS median_days_closest,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.uq_days_closest END AS uq_days_closest,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.lq_days_first END AS lq_days,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.median_days_first END AS median_days,
    CASE WHEN x.n_patients <= @min_cell_count THEN NULL ELSE t.uq_days_first END AS uq_days
FROM (
    SELECT anchor_event, event_family, time_relative, concept_id, n_records, n_patients
    FROM temp.event_code_counts_before_after
    UNION ALL
    SELECT anchor_event, event_family, time_relative, concept_id, n_records, n_patients
    FROM temp.event_code_counts_before_after_first_met
) x
LEFT JOIN temp.event_code_timing_before_after_summary t
  ON x.anchor_event = t.anchor_event
 AND x.event_family = t.event_family
 AND x.time_relative = t.time_relative
 AND x.concept_id = t.concept_id
ORDER BY x.anchor_event, x.event_family, x.time_relative, x.n_patients DESC, x.n_records DESC, x.concept_id
;
-- 4) Full pairwise timing summary (counts/min/max censored for small cells)
SELECT
    from_event,
    to_event,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN -@min_cell_count ELSE n_patients_with_pair END AS n_patients_with_pair,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p05_days END AS p05_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p10_days END AS p10_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p20_days END AS p20_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p25_days END AS p25_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p30_days END AS p30_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p40_days END AS p40_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p50_days END AS p50_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p60_days END AS p60_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p70_days END AS p70_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p75_days END AS p75_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p80_days END AS p80_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p90_days END AS p90_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p95_days END AS p95_days
FROM temp.timing_pair_summary
ORDER BY from_event, to_event
;
-- 5) Pairwise timing summary: FROM first -> TO closest (counts/min/max censored for small cells)
SELECT
    from_event,
    to_event,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN -@min_cell_count ELSE n_patients_with_pair END AS n_patients_with_pair,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p05_days END AS p05_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p10_days END AS p10_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p20_days END AS p20_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p25_days END AS p25_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p30_days END AS p30_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p40_days END AS p40_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p50_days END AS p50_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p60_days END AS p60_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p70_days END AS p70_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p75_days END AS p75_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p80_days END AS p80_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p90_days END AS p90_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p95_days END AS p95_days
FROM temp.timing_pair_summary_first_to_closest
ORDER BY from_event, to_event
;
-- 6) Pairwise timing summary: FROM first -> TO closest BEFORE (<0)
SELECT
    from_event,
    to_event,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN -@min_cell_count ELSE n_patients_with_pair END AS n_patients_with_pair,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p05_days END AS p05_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p10_days END AS p10_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p20_days END AS p20_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p25_days END AS p25_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p30_days END AS p30_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p40_days END AS p40_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p50_days END AS p50_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p60_days END AS p60_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p70_days END AS p70_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p75_days END AS p75_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p80_days END AS p80_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p90_days END AS p90_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p95_days END AS p95_days
FROM temp.timing_pair_summary_first_to_closest_before
ORDER BY from_event, to_event
;
-- 7) Pairwise timing summary: FROM first -> TO closest AFTER (>=0)
SELECT
    from_event,
    to_event,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN -@min_cell_count ELSE n_patients_with_pair END AS n_patients_with_pair,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p05_days END AS p05_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p10_days END AS p10_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p20_days END AS p20_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p25_days END AS p25_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p30_days END AS p30_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p40_days END AS p40_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p50_days END AS p50_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p60_days END AS p60_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p70_days END AS p70_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p75_days END AS p75_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p80_days END AS p80_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p90_days END AS p90_days,
    CASE WHEN n_patients_with_pair <= @min_cell_count THEN NULL ELSE p95_days END AS p95_days
FROM temp.timing_pair_summary_first_to_closest_after
ORDER BY from_event, to_event
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
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.p05_days END AS p05_days,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.p10_days END AS p10_days,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.lq_days END AS lq_days,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.median_days END AS median_days,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.uq_days END AS uq_days,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.p90_days END AS p90_days,
    CASE WHEN s.n_patients <= @min_cell_count OR s.n_deaths <= @min_cell_count THEN NULL ELSE q.p95_days END AS p95_days
FROM temp.death_stratum_counts s
LEFT JOIN temp.death_timing_quantiles q
  ON s.prevalence_year = q.prevalence_year
 AND s.anchor_event = q.anchor_event
ORDER BY
    CASE WHEN s.prevalence_year = 'OVERALL' THEN 0 ELSE 1 END,
    TRY_CAST(s.prevalence_year AS INT),
    CASE WHEN s.anchor_event = 'INDEX' THEN 0 ELSE 1 END
;
-- 9) Demographics at anchor dates (INDEX = first DX, FIRST_MET = first MET)
-- Gender concept IDs (OMOP): 8507=Male, 8532=Female. Others treated as unknown.
WITH anchor_persons  AS (SELECT  CAST('INDEX' as TEXT) AS anchor_event,
        c.person_id,
        c.index_date AS anchor_date
    FROM temp.patient_char c
    WHERE c.index_date IS NOT NULL
    UNION ALL
    SELECT
        'FIRST_MET' AS anchor_event,
        c.person_id,
        c.first_met_date AS anchor_date
    FROM temp.patient_char c
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
                THEN DATEDIFF(DAY, CAST(birth_datetime AS DATE), anchor_date) / 365.25
            WHEN year_of_birth IS NOT NULL
                THEN DATEDIFF(DAY, DATEFROMPARTS(year_of_birth, 7, 1), anchor_date) / 365.25
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
        CAST(100.0 * SUM(CASE WHEN gender_concept_id = 8507 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS REAL) AS pct_male,
        CAST(100.0 * SUM(CASE WHEN gender_concept_id = 8532 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS REAL) AS pct_female
    FROM ages
    WHERE age_years IS NOT NULL
    GROUP BY anchor_event
) agg
JOIN (
    SELECT
        anchor_event,
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY age_years) AS age_lq_years,
        PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY age_years) AS age_median_years,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY age_years) AS age_uq_years
    FROM ages
    WHERE age_years IS NOT NULL
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
    FROM temp.dx_events
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

