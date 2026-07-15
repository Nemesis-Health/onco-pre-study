-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/16_e_obs_period_observability.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 16) E. Observation-period characterization <U+2014> observability around the index
--     How much observable time each patient has BEFORE the index (look-back) and
--     AFTER the index (follow-up), reported as cumulative day-threshold counts:
--     the number of patients with fewer than 30 / 90 / 180 / 365 days of
--     observation on each side of the index. Look-back and follow-up are kept
--     strictly separate (one row per side); day 0 sits on the follow-up side
--     (follow-up = days from the index to the observation-period end, >= 0).
--
--     Observable time is measured inside the single observation period that
--     CONTAINS the anchor date, so both sides are contiguous observable time:
--       look-back_days = index_date - observation_period_start_date
--       follow-up_days = observation_period_end_date - index_date
--     A patient contributes only if the anchor date falls within one of their
--     observation periods. For INDEX this holds for every cohort patient by
--     construction (see #cohort in 00_setup.sql); for FIRST_MET it holds only
--     for patients whose first metastasis date is inside an observation period.
--
--     Two anchors: INDEX (first qualifying DX = cohort index date) and FIRST_MET
--     (first metastasis date). Source: #cohort, #met_summary (00_setup.sql) and
--     @cdm_database_schema.observation_period.
--     Small-cell suppression: threshold counts in (0, @min_cell_count] are set to
--     -@min_cell_count; median set to NULL when the group denominator is suppressed.
--     n_patients is an aggregate cohort denominator and is not suppressed, matching
--     the existing death/prevalence chunks.
with obs_around_anchor as (
    -- INDEX anchor: index_date is guaranteed to fall inside an observation period.
    select
        'INDEX' as anchor_event,
        c.person_id,
        DATE_DIFF(IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), IF(SAFE_CAST(op.observation_period_start_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(op.observation_period_start_date  AS STRING)),SAFE_CAST(op.observation_period_start_date  AS DATE)), DAY) as lookback_days,
        DATE_DIFF(IF(SAFE_CAST(op.observation_period_end_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(op.observation_period_end_date  AS STRING)),SAFE_CAST(op.observation_period_end_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY)   as followup_days
    from vcbo5u4zcohort c
    inner join @cdm_database_schema.observation_period op
        on  op.person_id = c.person_id
        and c.index_date between op.observation_period_start_date
                             and op.observation_period_end_date
    union all
    -- FIRST_MET anchor: only patients whose first metastasis date is inside a period.
    select
        'FIRST_MET' as anchor_event,
        c.person_id,
        DATE_DIFF(IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), IF(SAFE_CAST(op.observation_period_start_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(op.observation_period_start_date  AS STRING)),SAFE_CAST(op.observation_period_start_date  AS DATE)), DAY) as lookback_days,
        DATE_DIFF(IF(SAFE_CAST(op.observation_period_end_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(op.observation_period_end_date  AS STRING)),SAFE_CAST(op.observation_period_end_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY)   as followup_days
    from vcbo5u4zcohort c
    inner join vcbo5u4zmet_summary ms
        on ms.person_id = c.person_id and ms.first_met_date is not null
    inner join @cdm_database_schema.observation_period op
        on  op.person_id = c.person_id
        and ms.first_met_date between op.observation_period_start_date
                                  and op.observation_period_end_date
),
obs_sided as (
    select anchor_event, person_id, 'LOOKBACK_BEFORE_ANCHOR' as observation_side, lookback_days as obs_days
    from obs_around_anchor
    union all
    select anchor_event, person_id, 'FOLLOWUP_AFTER_ANCHOR'  as observation_side, followup_days as obs_days
    from obs_around_anchor
),
ranked as (
    select
        anchor_event,
        observation_side,
        obs_days,
        row_number() over (partition by anchor_event, observation_side order by obs_days) as rn,
        count(*)     over (partition by anchor_event, observation_side)                    as cnt
    from obs_sided
),
agg as (
     select anchor_event,
        observation_side,
        count(*) as n_patients,
        sum(case when obs_days < 30  then 1 else 0 end) as n_lt_30d,
        sum(case when obs_days < 90  then 1 else 0 end) as n_lt_90d,
        sum(case when obs_days < 180 then 1 else 0 end) as n_lt_180d,
        sum(case when obs_days < 365 then 1 else 0 end) as n_lt_365d,
        min(case when 2.0 * rn >= cnt then cast(obs_days  as float64) end) as median_days
     from ranked
     group by  1, 2 )
 select anchor_event,
    observation_side,
    n_patients,
    case when n_lt_30d  > 0 and n_lt_30d  <= @min_cell_count then -@min_cell_count else n_lt_30d  end as n_lt_30d,
    case when n_lt_90d  > 0 and n_lt_90d  <= @min_cell_count then -@min_cell_count else n_lt_90d  end as n_lt_90d,
    case when n_lt_180d > 0 and n_lt_180d <= @min_cell_count then -@min_cell_count else n_lt_180d end as n_lt_180d,
    case when n_lt_365d > 0 and n_lt_365d <= @min_cell_count then -@min_cell_count else n_lt_365d end as n_lt_365d,
    case when n_patients <= @min_cell_count then null else median_days end as median_days
 from agg
 order by  case anchor_event when 'INDEX' then 0 else 1 end, case observation_side when 'LOOKBACK_BEFORE_ANCHOR' then 0 else 1 end
 ;

