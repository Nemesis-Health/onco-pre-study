-- 11) L01 consecutive record gap distribution
--     Intermediate tables #l01_event_days and #l01_consecutive_gaps are
--     built in 00_setup.sql (section L).
--
--     Two subgroups:
--       ALL_L01 : all DX cohort patients with any L01 record
--       MET_L01 : patients who also have a first_met_date
--
--     Output 1: Decile summary — one row per subgroup
--     Output 2: Bucket distribution — one row per (subgroup, bucket)

-- 11a) Decile summary
SELECT
    subgroup,
    COUNT(*)                                                   AS n_gaps,
    COUNT(DISTINCT person_id)                                  AS n_patients_with_gaps,
    PERCENTILE_CONT(0.10) WITHIN GROUP (ORDER BY gap_days)    AS p10_days,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY gap_days)    AS p25_days,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY gap_days)    AS p50_days,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY gap_days)    AS p75_days,
    PERCENTILE_CONT(0.90) WITHIN GROUP (ORDER BY gap_days)    AS p90_days
FROM #l01_consecutive_gaps
GROUP BY subgroup
ORDER BY subgroup
;

-- 11b) Gap bucket distribution
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
FROM #l01_consecutive_gaps
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
    CASE
        WHEN gap_days <  30  THEN 1
        WHEN gap_days <  60  THEN 2
        WHEN gap_days <  90  THEN 3
        WHEN gap_days < 180  THEN 4
        WHEN gap_days < 365  THEN 5
        ELSE 6
    END
;
