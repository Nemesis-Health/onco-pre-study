-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : impala
-- Translated     : 2026-05-06 18:36:47 BST
-- Source file    : sql/sql_server/chunks/09_demographics.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (impala) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 9) Demographics at anchor dates (INDEX = first DX, FIRST_MET = first MET)
-- Gender concept IDs (OMOP): 8507=Male, 8532=Female. Others treated as unknown.
WITH anchor_persons AS (
    SELECT
        'INDEX' AS anchor_event,
        c.person_id,
        c.index_date AS anchor_date
    FROM ldpw47q6patient_char c
    WHERE c.index_date IS NOT NULL
    UNION ALL
    SELECT
        'FIRST_MET' AS anchor_event,
        c.person_id,
        c.first_met_date AS anchor_date
    FROM ldpw47q6patient_char c
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
                THEN DATEDIFF(CASE TYPEOF(anchor_date ) WHEN 'TIMESTAMP' THEN CAST(anchor_date  AS TIMESTAMP) ELSE TO_UTC_TIMESTAMP(CONCAT_WS('-', SUBSTR(CAST(anchor_date  AS STRING), 1, 4), SUBSTR(CAST(anchor_date  AS STRING), 5, 2), SUBSTR(CAST(anchor_date  AS STRING), 7, 2)), 'UTC') END, CASE TYPEOF(CASE TYPEOF(birth_datetime ) WHEN 'TIMESTAMP' THEN CAST(birth_datetime  AS TIMESTAMP) ELSE TO_UTC_TIMESTAMP(CONCAT_WS('-', SUBSTR(CAST(birth_datetime  AS STRING), 1, 4), SUBSTR(CAST(birth_datetime  AS STRING), 5, 2), SUBSTR(CAST(birth_datetime  AS STRING), 7, 2)), 'UTC') END ) WHEN 'TIMESTAMP' THEN CAST(CASE TYPEOF(birth_datetime ) WHEN 'TIMESTAMP' THEN CAST(birth_datetime  AS TIMESTAMP) ELSE TO_UTC_TIMESTAMP(CONCAT_WS('-', SUBSTR(CAST(birth_datetime  AS STRING), 1, 4), SUBSTR(CAST(birth_datetime  AS STRING), 5, 2), SUBSTR(CAST(birth_datetime  AS STRING), 7, 2)), 'UTC') END  AS TIMESTAMP) ELSE TO_UTC_TIMESTAMP(CONCAT_WS('-', SUBSTR(CAST(CASE TYPEOF(birth_datetime ) WHEN 'TIMESTAMP' THEN CAST(birth_datetime  AS TIMESTAMP) ELSE TO_UTC_TIMESTAMP(CONCAT_WS('-', SUBSTR(CAST(birth_datetime  AS STRING), 1, 4), SUBSTR(CAST(birth_datetime  AS STRING), 5, 2), SUBSTR(CAST(birth_datetime  AS STRING), 7, 2)), 'UTC') END  AS STRING), 1, 4), SUBSTR(CAST(CASE TYPEOF(birth_datetime ) WHEN 'TIMESTAMP' THEN CAST(birth_datetime  AS TIMESTAMP) ELSE TO_UTC_TIMESTAMP(CONCAT_WS('-', SUBSTR(CAST(birth_datetime  AS STRING), 1, 4), SUBSTR(CAST(birth_datetime  AS STRING), 5, 2), SUBSTR(CAST(birth_datetime  AS STRING), 7, 2)), 'UTC') END  AS STRING), 5, 2), SUBSTR(CAST(CASE TYPEOF(birth_datetime ) WHEN 'TIMESTAMP' THEN CAST(birth_datetime  AS TIMESTAMP) ELSE TO_UTC_TIMESTAMP(CONCAT_WS('-', SUBSTR(CAST(birth_datetime  AS STRING), 1, 4), SUBSTR(CAST(birth_datetime  AS STRING), 5, 2), SUBSTR(CAST(birth_datetime  AS STRING), 7, 2)), 'UTC') END  AS STRING), 7, 2)), 'UTC') END) / 365.25
            WHEN year_of_birth IS NOT NULL
                THEN DATEDIFF(CASE TYPEOF(anchor_date ) WHEN 'TIMESTAMP' THEN CAST(anchor_date  AS TIMESTAMP) ELSE TO_UTC_TIMESTAMP(CONCAT_WS('-', SUBSTR(CAST(anchor_date  AS STRING), 1, 4), SUBSTR(CAST(anchor_date  AS STRING), 5, 2), SUBSTR(CAST(anchor_date  AS STRING), 7, 2)), 'UTC') END, CASE TYPEOF(to_timestamp(CONCAT(CAST(year_of_birth AS VARCHAR),'-',CAST(7 AS VARCHAR),'-',CAST(1 AS VARCHAR)), 'yyyy-M-d') ) WHEN 'TIMESTAMP' THEN CAST(to_timestamp(CONCAT(CAST(year_of_birth AS VARCHAR),'-',CAST(7 AS VARCHAR),'-',CAST(1 AS VARCHAR)), 'yyyy-M-d')  AS TIMESTAMP) ELSE TO_UTC_TIMESTAMP(CONCAT_WS('-', SUBSTR(CAST(to_timestamp(CONCAT(CAST(year_of_birth AS VARCHAR),'-',CAST(7 AS VARCHAR),'-',CAST(1 AS VARCHAR)), 'yyyy-M-d')  AS STRING), 1, 4), SUBSTR(CAST(to_timestamp(CONCAT(CAST(year_of_birth AS VARCHAR),'-',CAST(7 AS VARCHAR),'-',CAST(1 AS VARCHAR)), 'yyyy-M-d')  AS STRING), 5, 2), SUBSTR(CAST(to_timestamp(CONCAT(CAST(year_of_birth AS VARCHAR),'-',CAST(7 AS VARCHAR),'-',CAST(1 AS VARCHAR)), 'yyyy-M-d')  AS STRING), 7, 2)), 'UTC') END) / 365.25
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

