-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-07 11:54:00 BST
-- Source file    : sql/sql_server/chunks/14_death_gap_buckets.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 14) Death date vs observation period — bucketed gap histogram
--     Restricted to patients where death_date > obs_period_end_date.
--     Exported for both INDEX (all DX cohort) and FIRST_MET (MET subgroup)
--     so that each can be shown as a separate figure in the report.
with patient_obs as (
     select person_id,
        min(observation_period_start_date) as first_obs_start,
        max(observation_period_end_date)   as last_obs_end
     from @cdm_database_schema.observation_period
    where person_id in (select person_id from ctxb0womcohort)
     group by  1 ),
death_obs_gaps as (
    select
        c.person_id,
        ms.first_met_date,
        case
            when dos.death_date > po.last_obs_end
                then DATE_DIFF(IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), IF(SAFE_CAST(po.last_obs_end  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(po.last_obs_end  AS STRING)),SAFE_CAST(po.last_obs_end  AS DATE)), DAY)
            else null
        end as gap_death_after_obs
    from ctxb0womcohort c
    inner join ctxb0womdeath_obs_status dos on dos.person_id = c.person_id
    left join ctxb0wommet_summary ms        on ms.person_id  = c.person_id
    left join patient_obs po         on po.person_id  = c.person_id
),
bucketed as (
    select
        person_id,
        first_met_date,
        case
            when gap_death_after_obs <   30 then 'lt30d'
            when gap_death_after_obs <   60 then '30_59d'
            when gap_death_after_obs <   90 then '60_89d'
            when gap_death_after_obs <  180 then '90_179d'
            when gap_death_after_obs <  365 then '180_364d'
            when gap_death_after_obs <  730 then '365_729d'
            else 'ge730d'
        end as gap_bucket,
        case
            when gap_death_after_obs <   30 then 1
            when gap_death_after_obs <   60 then 2
            when gap_death_after_obs <   90 then 3
            when gap_death_after_obs <  180 then 4
            when gap_death_after_obs <  365 then 5
            when gap_death_after_obs <  730 then 6
            else 7
        end as sort_key
    from death_obs_gaps
    where gap_death_after_obs is not null
)
 select anchor_event, gap_bucket, n_patients
 from (
     select 'INDEX' as anchor_event, gap_bucket,
        case when count(*) <= @min_cell_count then -@min_cell_count else count(*) end as n_patients,
        min(sort_key) as sort_key
     from bucketed
     group by  gap_bucket
    union all
     select 'FIRST_MET' as anchor_event, 2, case when count(*) <= @min_cell_count then -@min_cell_count else count(*) end as n_patients, min(sort_key) as sort_key
     from bucketed
    where first_met_date is not null
     group by  gap_bucket
  ) x
 order by  case when anchor_event = 'INDEX' then 0 else 1 end, sort_key
 ;

