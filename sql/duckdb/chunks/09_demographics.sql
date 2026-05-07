-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : duckdb
-- Translated     : 2026-05-07 11:58:24 BST
-- Source file    : sql/sql_server/chunks/09_demographics.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

-- 9) Demographics at anchor dates (INDEX = first DX, FIRST_MET = first MET)
-- Gender concept IDs (OMOP): 8507=Male, 8532=Female. Others treated as unknown.
WITH anchor_persons  AS (SELECT  CAST('INDEX' as TEXT) AS anchor_event,
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
                THEN (CAST(anchor_date AS DATE) - CAST(CAST(birth_datetime AS DATE) AS DATE)) / 365.25
            WHEN year_of_birth IS NOT NULL
                THEN (CAST(anchor_date AS DATE) - CAST((CAST(year_of_birth AS VARCHAR) || '-' || CAST(7 AS VARCHAR) || '-' || CAST(1 AS VARCHAR)) :: DATE AS DATE)) / 365.25
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
        CAST(100.0 * SUM(CASE WHEN gender_concept_id = 8507 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS NUMERIC) AS pct_male,
        CAST(100.0 * SUM(CASE WHEN gender_concept_id = 8532 THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS NUMERIC) AS pct_female
    FROM ages
    WHERE age_years IS NOT NULL
    GROUP BY anchor_event
) agg
JOIN (
    SELECT
        anchor_event,
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(age_years AS NUMERIC) END) AS age_lq_years,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(age_years AS NUMERIC) END) AS age_median_years,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(age_years AS NUMERIC) END) AS age_uq_years
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

