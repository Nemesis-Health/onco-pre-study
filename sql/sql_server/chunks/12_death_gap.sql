-- 12) Death date vs observation period alignment — gap distribution
--     For patients where death_date falls AFTER obs_period_end (already
--     flagged in the n_deaths_out_obs column of chunk 08), this query
--     exports the distribution of the gap: death_date - obs_period_end_date
--     (i.e. how many days after the last observation period did death occur).
--
--     Also reports:
--       - death_before_obs: patients where death_date < obs_period_start_date
--         (data quality error — rare but important to flag separately)
--
--     Stratified by anchor (INDEX / FIRST_MET).
--     Small-cell suppression applied.

WITH patient_obs AS (
    -- Latest observation period end and earliest observation period start per patient
    SELECT
        person_id,
        MIN(observation_period_start_date) AS first_obs_start,
        MAX(observation_period_end_date)   AS last_obs_end
    FROM @cdm_database_schema.observation_period
    WHERE person_id IN (SELECT person_id FROM #cohort)
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
    FROM #cohort c
    INNER JOIN #death_obs_status dos ON dos.person_id = c.person_id
    LEFT JOIN #met_summary ms ON ms.person_id = c.person_id
    LEFT JOIN patient_obs po  ON po.person_id  = c.person_id
)

-- 1) Summary counts: death-before-obs and gap magnitude summary
SELECT
    'INDEX' AS anchor_event,
    SUM(CASE WHEN death_before_obs = 1 THEN 1 ELSE 0 END) AS n_death_before_obs,
    SUM(CASE WHEN gap_death_after_obs IS NOT NULL THEN 1 ELSE 0 END) AS n_death_after_obs,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY gap_death_after_obs) AS lq_gap_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY gap_death_after_obs) AS median_gap_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY gap_death_after_obs) AS uq_gap_days,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY gap_death_after_obs) AS p90_gap_days
FROM death_obs_gaps
WHERE death_date IS NOT NULL

UNION ALL

SELECT
    'FIRST_MET' AS anchor_event,
    SUM(CASE WHEN death_before_obs = 1 THEN 1 ELSE 0 END) AS n_death_before_obs,
    SUM(CASE WHEN gap_death_after_obs IS NOT NULL THEN 1 ELSE 0 END) AS n_death_after_obs,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY gap_death_after_obs) AS lq_gap_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY gap_death_after_obs) AS median_gap_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY gap_death_after_obs) AS uq_gap_days,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY gap_death_after_obs) AS p90_gap_days
FROM death_obs_gaps
WHERE death_date IS NOT NULL
  AND first_met_date IS NOT NULL
;

-- 2) Raw gap distribution for histogram (death_after_obs patients only, INDEX anchor)
--    Binned at 30-day intervals up to 730 days, then a single ">730d" bucket.
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
    CASE
        WHEN gap_death_after_obs <   30 THEN 1
        WHEN gap_death_after_obs <   60 THEN 2
        WHEN gap_death_after_obs <   90 THEN 3
        WHEN gap_death_after_obs <  180 THEN 4
        WHEN gap_death_after_obs <  365 THEN 5
        WHEN gap_death_after_obs <  730 THEN 6
        ELSE 7
    END
;
