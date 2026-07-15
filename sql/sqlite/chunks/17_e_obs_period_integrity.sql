-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : sqlite
-- Translated     : 2026-07-15 15:37:32 CEST
-- Source file    : sql/sql_server/chunks/17_e_obs_period_integrity.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

-- 17) E. Observation-period characterization <U+2014> integrity checks
--     Whether the observation period behaves the way a phenotype would assume.
--     Long format: one row per (anchor_event, metric, stratum). Metrics:
--
--       PERIOD_TYPE_CONCEPT              (anchor_event = 'ALL')
--           How the period is defined at this site. One row per distinct
--           observation_period.period_type_concept_id among cohort patients.
--           n_numerator   = distinct cohort patients with a period of this type
--           n_denominator = distinct cohort patients with any period
--           (states the definition/source: claims-enrollment vs EHR-estimated
--            period types resolve to different concept ids; label upstream).
--
--       PATIENTS_WITH_MULTIPLE_OBS_PERIODS   (per anchor)
--           n_numerator   = patients with more than one observation period (a gap)
--           n_denominator = patients in this anchor's cohort
--
--       DEATHS_OUTSIDE_OBS_PERIOD            (per anchor)
--           n_numerator   = deaths on/after the anchor recorded outside any period
--           n_denominator = deaths on/after the anchor
--           (read straight from #death_stratum_counts OVERALL rows.)
--
--       DECEDENTS_PERIOD_ENDS_AFTER_DEATH    (per anchor)
--           n_numerator   = decedents whose last observation_period_end_date is
--                           AFTER the death date (period runs past death)
--           n_denominator = decedents (deaths on/after the anchor)
--
--       MEDIAN_DAYS_PERIOD_ENDS_PAST_DEATH   (per anchor)
--           median_days   = median (last_obs_end - death_date) among the decedents
--                           counted in DECEDENTS_PERIOD_ENDS_AFTER_DEATH
--           n_denominator = count of those decedents
--
--     Anchors: INDEX (cohort index date) and FIRST_MET (first metastasis date).
--     Sources: #cohort, #met_summary, #death_obs_status, #death_stratum_counts
--     (00_setup.sql) and @cdm_database_schema.observation_period.
--     Small-cell suppression: n_numerator in (0, @min_cell_count] set to
--     -@min_cell_count; median set to NULL when its decedent denominator is
--     suppressed. Aggregate cohort/death denominators are not suppressed.
WITH patient_obs AS (
    SELECT
        person_id,
        MAX(observation_period_end_date) AS last_obs_end,
        COUNT(*)                         AS n_periods
    FROM @cdm_database_schema.observation_period
    WHERE person_id IN (SELECT person_id FROM temp.cohort)
    GROUP BY person_id
),
period_type_patients AS (
    SELECT
        op.period_type_concept_id,
        COUNT(DISTINCT op.person_id) AS n_patients
    FROM @cdm_database_schema.observation_period op
    WHERE op.person_id IN (SELECT person_id FROM temp.cohort)
    GROUP BY op.period_type_concept_id
),
period_type_total AS (
    SELECT COUNT(DISTINCT person_id) AS n_patients_any_period
    FROM @cdm_database_schema.observation_period
    WHERE person_id IN (SELECT person_id FROM temp.cohort)
),
-- Anchor cohorts: INDEX = full DX cohort; FIRST_MET = cohort with a metastasis.
anchor_cohort AS (
    SELECT 'INDEX' AS anchor_event, c.person_id, po.n_periods
    FROM temp.cohort c
    LEFT JOIN patient_obs po ON po.person_id = c.person_id
    UNION ALL
    SELECT 'FIRST_MET' AS anchor_event, c.person_id, po.n_periods
    FROM temp.cohort c
    INNER JOIN temp.met_summary ms ON ms.person_id = c.person_id AND ms.first_met_date IS NOT NULL
    LEFT JOIN patient_obs po ON po.person_id = c.person_id
),
-- Decedents relative to each anchor, with whether the period runs past death.
decedent_anchor AS (
    SELECT
        'INDEX' AS anchor_event,
        dos.death_date,
        CASE WHEN po.last_obs_end > dos.death_date THEN 1 ELSE 0 END AS period_ends_after_death,
        CASE WHEN po.last_obs_end > dos.death_date
             THEN (JULIANDAY(po.last_obs_end, 'unixepoch') - JULIANDAY(dos.death_date, 'unixepoch')) END  AS days_past_death
    FROM temp.cohort c
    INNER JOIN temp.death_obs_status dos ON dos.person_id = c.person_id
    LEFT JOIN patient_obs po ON po.person_id = c.person_id
    WHERE dos.death_date >= c.index_date
    UNION ALL
    SELECT
        'FIRST_MET' AS anchor_event,
        dos.death_date,
        CASE WHEN po.last_obs_end > dos.death_date THEN 1 ELSE 0 END,
        CASE WHEN po.last_obs_end > dos.death_date
             THEN (JULIANDAY(po.last_obs_end, 'unixepoch') - JULIANDAY(dos.death_date, 'unixepoch')) END
    FROM temp.cohort c
    INNER JOIN temp.met_summary ms ON ms.person_id = c.person_id AND ms.first_met_date IS NOT NULL
    INNER JOIN temp.death_obs_status dos ON dos.person_id = c.person_id
    LEFT JOIN patient_obs po ON po.person_id = c.person_id
    WHERE dos.death_date >= ms.first_met_date
),
decedent_days_ranked AS (
    -- Rank ONLY the decedents whose period runs past death (days_past_death
    -- populated). Ranking over the full decedent set would let the NULL rows
    -- (period does not run past death) consume the lowest row numbers, since
    -- SQL Server sorts NULLs first, and the ordered-set median filter below would
    -- then pick the minimum rather than the true median. Match the non-NULL-inside
    -- pattern used by chunks 06b, 23, 27, 28, 34.
    SELECT
        anchor_event,
        days_past_death,
        ROW_NUMBER() OVER (PARTITION BY anchor_event ORDER BY days_past_death) AS rn,
        COUNT(*)     OVER (PARTITION BY anchor_event)                          AS non_null_cnt
    FROM decedent_anchor
    WHERE days_past_death IS NOT NULL
),
metrics AS (
    -- (1) period definition: period_type distribution (site-level)
    SELECT
        'ALL' AS anchor_event,
        'PERIOD_TYPE_CONCEPT' AS metric,
        CAST(ptp.period_type_concept_id AS TEXT) AS stratum,
        ptp.n_patients AS n_numerator,
        ptt.n_patients_any_period AS n_denominator,
        CAST(NULL AS REAL) AS median_days
    FROM period_type_patients ptp
    CROSS JOIN period_type_total ptt
    UNION ALL
    -- (2) patients with more than one observation period (a gap)
    SELECT
        anchor_event,
        'PATIENTS_WITH_MULTIPLE_OBS_PERIODS',
        '',
        SUM(CASE WHEN n_periods > 1 THEN 1 ELSE 0 END),
        COUNT(*),
        CAST(NULL AS REAL)
    FROM anchor_cohort
    GROUP BY anchor_event
    UNION ALL
    -- (3) deaths recorded outside any observation period
    SELECT
        anchor_event,
        'DEATHS_OUTSIDE_OBS_PERIOD',
        '',
        n_deaths_out_obs,
        n_deaths,
        CAST(NULL AS REAL)
    FROM temp.death_stratum_counts
    WHERE prevalence_year = 'OVERALL'
    UNION ALL
    -- (4) decedents whose observation period ends after the death date
    SELECT
        anchor_event,
        'DECEDENTS_PERIOD_ENDS_AFTER_DEATH',
        '',
        SUM(period_ends_after_death),
        COUNT(*),
        CAST(NULL AS REAL)
    FROM decedent_anchor
    GROUP BY anchor_event
    UNION ALL
    -- (5) median days the period runs past death, among those decedents
    SELECT
        anchor_event,
        'MEDIAN_DAYS_PERIOD_ENDS_PAST_DEATH',
        '',
        CAST(NULL AS INT),
        MAX(non_null_cnt),
        MIN(CASE WHEN 2.0 * rn >= non_null_cnt
                 THEN CAST(days_past_death AS REAL) END)
    FROM decedent_days_ranked
    GROUP BY anchor_event
)
SELECT
    anchor_event,
    metric,
    stratum,
    CASE WHEN n_numerator IS NOT NULL AND n_numerator > 0 AND n_numerator <= @min_cell_count
         THEN -@min_cell_count ELSE n_numerator END AS n_numerator,
    n_denominator,
    CASE WHEN median_days IS NOT NULL AND n_denominator IS NOT NULL AND n_denominator <= @min_cell_count
         THEN NULL ELSE median_days END AS median_days
FROM metrics
ORDER BY
    CASE metric
        WHEN 'PERIOD_TYPE_CONCEPT'                 THEN 0
        WHEN 'PATIENTS_WITH_MULTIPLE_OBS_PERIODS'  THEN 1
        WHEN 'DEATHS_OUTSIDE_OBS_PERIOD'           THEN 2
        WHEN 'DECEDENTS_PERIOD_ENDS_AFTER_DEATH'   THEN 3
        WHEN 'MEDIAN_DAYS_PERIOD_ENDS_PAST_DEATH'  THEN 4
        ELSE 9
    END,
    CASE anchor_event WHEN 'ALL' THEN 0 WHEN 'INDEX' THEN 1 ELSE 2 END,
    stratum
;

