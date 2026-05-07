-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : snowflake
-- Translated     : 2026-05-07 11:58:25 BST
-- Source file    : sql/sql_server/chunks/14_death_gap_buckets.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

-- 14) Death date vs observation period — bucketed gap histogram
--     Restricted to patients where death_date > obs_period_end_date.
--     Exported for both INDEX (all DX cohort) and FIRST_MET (MET subgroup)
--     so that each can be shown as a separate figure in the report.
WITH patient_obs AS (
    SELECT
        person_id,
        MIN(observation_period_start_date) AS first_obs_start,
        MAX(observation_period_end_date)   AS last_obs_end
    FROM @cdm_database_schema.observation_period
    WHERE person_id IN (SELECT person_id FROM y8hp12zkcohort)
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
    FROM y8hp12zkcohort c
    INNER JOIN y8hp12zkdeath_obs_status dos ON dos.person_id = c.person_id
    LEFT JOIN y8hp12zkmet_summary ms        ON ms.person_id  = c.person_id
    LEFT JOIN patient_obs po         ON po.person_id  = c.person_id
),
bucketed AS (
    SELECT
        person_id,
        first_met_date,
        CASE
            WHEN gap_death_after_obs <   30 THEN 'lt30d'
            WHEN gap_death_after_obs <   60 THEN '30_59d'
            WHEN gap_death_after_obs <   90 THEN '60_89d'
            WHEN gap_death_after_obs <  180 THEN '90_179d'
            WHEN gap_death_after_obs <  365 THEN '180_364d'
            WHEN gap_death_after_obs <  730 THEN '365_729d'
            ELSE 'ge730d'
        END AS gap_bucket,
        CASE
            WHEN gap_death_after_obs <   30 THEN 1
            WHEN gap_death_after_obs <   60 THEN 2
            WHEN gap_death_after_obs <   90 THEN 3
            WHEN gap_death_after_obs <  180 THEN 4
            WHEN gap_death_after_obs <  365 THEN 5
            WHEN gap_death_after_obs <  730 THEN 6
            ELSE 7
        END AS sort_key
    FROM death_obs_gaps
    WHERE gap_death_after_obs IS NOT NULL
)
SELECT anchor_event, gap_bucket, n_patients
FROM (
    SELECT 'INDEX' AS anchor_event, gap_bucket,
        CASE WHEN COUNT(*) <= @min_cell_count THEN -@min_cell_count ELSE COUNT(*) END AS n_patients,
        MIN(sort_key) AS sort_key
    FROM bucketed
    GROUP BY gap_bucket
    UNION ALL
    SELECT 'FIRST_MET' AS anchor_event, gap_bucket,
        CASE WHEN COUNT(*) <= @min_cell_count THEN -@min_cell_count ELSE COUNT(*) END AS n_patients,
        MIN(sort_key) AS sort_key
    FROM bucketed
    WHERE first_met_date IS NOT NULL
    GROUP BY gap_bucket
) x
ORDER BY
    CASE WHEN anchor_event = 'INDEX' THEN 0 ELSE 1 END,
    sort_key
;

