-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/17_e_obs_period_integrity.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

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
with patient_obs as (
     select person_id,
        max(observation_period_end_date) as last_obs_end,
        count(*)                         as n_periods
     from @cdm_database_schema.observation_period
    where person_id in (select person_id from vcbo5u4zcohort)
     group by  1 ),
period_type_patients as (
     select op.period_type_concept_id,
        count(distinct op.person_id) as n_patients
     from @cdm_database_schema.observation_period op
    where op.person_id in (select person_id from vcbo5u4zcohort)
     group by  op.period_type_concept_id
 ),
period_type_total as (
    select count(distinct person_id) as n_patients_any_period
    from @cdm_database_schema.observation_period
    where person_id in (select person_id from vcbo5u4zcohort)
),
-- Anchor cohorts: INDEX = full DX cohort; FIRST_MET = cohort with a metastasis.
anchor_cohort as (
    select 'INDEX' as anchor_event, c.person_id, po.n_periods
    from vcbo5u4zcohort c
    left join patient_obs po on po.person_id = c.person_id
    union all
    select 'FIRST_MET' as anchor_event, c.person_id, po.n_periods
    from vcbo5u4zcohort c
    inner join vcbo5u4zmet_summary ms on ms.person_id = c.person_id and ms.first_met_date is not null
    left join patient_obs po on po.person_id = c.person_id
),
-- Decedents relative to each anchor, with whether the period runs past death.
decedent_anchor as (
    select
        'INDEX' as anchor_event,
        dos.death_date,
        case when po.last_obs_end > dos.death_date then 1 else 0 end as period_ends_after_death,
        case when po.last_obs_end > dos.death_date
             then DATE_DIFF(IF(SAFE_CAST(po.last_obs_end  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(po.last_obs_end  AS STRING)),SAFE_CAST(po.last_obs_end  AS DATE)), IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), DAY) end  as days_past_death
    from vcbo5u4zcohort c
    inner join vcbo5u4zdeath_obs_status dos on dos.person_id = c.person_id
    left join patient_obs po on po.person_id = c.person_id
    where dos.death_date >= c.index_date
    union all
    select
        'FIRST_MET' as anchor_event,
        dos.death_date,
        case when po.last_obs_end > dos.death_date then 1 else 0 end,
        case when po.last_obs_end > dos.death_date
             then DATE_DIFF(IF(SAFE_CAST(po.last_obs_end  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(po.last_obs_end  AS STRING)),SAFE_CAST(po.last_obs_end  AS DATE)), IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), DAY) end
    from vcbo5u4zcohort c
    inner join vcbo5u4zmet_summary ms on ms.person_id = c.person_id and ms.first_met_date is not null
    inner join vcbo5u4zdeath_obs_status dos on dos.person_id = c.person_id
    left join patient_obs po on po.person_id = c.person_id
    where dos.death_date >= ms.first_met_date
),
decedent_days_ranked as (
    -- Rank ONLY the decedents whose period runs past death (days_past_death
    -- populated). Ranking over the full decedent set would let the NULL rows
    -- (period does not run past death) consume the lowest row numbers, since
    -- SQL Server sorts NULLs first, and the ordered-set median filter below would
    -- then pick the minimum rather than the true median. Match the non-NULL-inside
    -- pattern used by chunks 06b, 23, 27, 28, 34.
    select
        anchor_event,
        days_past_death,
        row_number() over (partition by anchor_event order by days_past_death) as rn,
        count(*)     over (partition by anchor_event)                          as non_null_cnt
    from decedent_anchor
    where days_past_death is not null
),
metrics as (
    -- (1) period definition: period_type distribution (site-level)
     select 'ALL' as anchor_event,
        'PERIOD_TYPE_CONCEPT' as metric,
        cast(ptp.period_type_concept_id as STRING) as stratum,
        ptp.n_patients as n_numerator,
        ptt.n_patients_any_period as n_denominator,
        cast(null  as float64) as median_days
     from period_type_patients ptp
    cross join period_type_total ptt
    union all
    -- (2) patients with more than one observation period (a gap)
     select anchor_event,
        'PATIENTS_WITH_MULTIPLE_OBS_PERIODS',
        '',
        sum(case when n_periods > 1 then 1 else 0 end),
        count(*),
        cast(null  as float64)
     from anchor_cohort
      group by  anchor_event
    union all
    -- (3) deaths recorded outside any observation period
     select anchor_event, 'DEATHS_OUTSIDE_OBS_PERIOD', 3, n_deaths_out_obs, n_deaths, cast(null  as float64)
     from vcbo5u4zdeath_stratum_counts
    where prevalence_year = 'OVERALL'
    union all
    -- (4) decedents whose observation period ends after the death date
     select anchor_event, 'DECEDENTS_PERIOD_ENDS_AFTER_DEATH', 3, sum(period_ends_after_death), 5, cast(null  as float64)
     from decedent_anchor
      group by  anchor_event
    union all
    -- (5) median days the period runs past death, among those decedents
     select anchor_event, 'MEDIAN_DAYS_PERIOD_ENDS_PAST_DEATH', 3, cast(null  as int64), max(non_null_cnt), min(case when 2.0 * rn >= non_null_cnt
                 then cast(days_past_death  as float64) end)
     from decedent_days_ranked
     group by  1 )
 select anchor_event,
    metric,
    stratum,
    case when n_numerator is not null and n_numerator > 0 and n_numerator <= @min_cell_count
         then -@min_cell_count else n_numerator end as n_numerator,
    n_denominator,
    case when median_days is not null and n_denominator is not null and n_denominator <= @min_cell_count
         then null else median_days end as median_days
 from metrics
 order by  case metric
        when 'PERIOD_TYPE_CONCEPT'                 then 0
        when 'PATIENTS_WITH_MULTIPLE_OBS_PERIODS'  then 1
        when 'DEATHS_OUTSIDE_OBS_PERIOD'           then 2
        when 'DECEDENTS_PERIOD_ENDS_AFTER_DEATH'   then 3
        when 'MEDIAN_DAYS_PERIOD_ENDS_PAST_DEATH'  then 4
        else 9
    end, case anchor_event when 'ALL' then 0 when 'INDEX' then 1 else 2 end, 3 ;

