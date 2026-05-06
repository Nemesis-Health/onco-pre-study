-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : sqlite extended
-- Translated     : 2026-04-27 15:05:09 BST
-- Source file    : sql/sql_server/chunks/09_demographics.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

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

