-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-06 18:06:52 BST
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
--     Restricted to patients where death_date > obs_period_end_date (i.e.
--     the n_death_after_obs subset summarized in chunk 13).  Binned at
--     30-day intervals up to 730 days, then a single ">=730d" bucket.
--
--     Output: one row per gap_bucket (INDEX anchor; FIRST_MET subset is a
--     proper subset whose distribution closely mirrors INDEX, so we only
--     export the INDEX histogram for the report).
with patient_obs as (
     select person_id,
        min(observation_period_start_date) as first_obs_start,
        max(observation_period_end_date)   as last_obs_end
     from @cdm_database_schema.observation_period
    where person_id in (select person_id from cbse36ibcohort)
     group by  1 ),
death_obs_gaps as (
    select
        c.person_id,
        case
            when dos.death_date > po.last_obs_end
                then DATE_DIFF(IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), IF(SAFE_CAST(po.last_obs_end  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(po.last_obs_end  AS STRING)),SAFE_CAST(po.last_obs_end  AS DATE)), DAY)
            else null
        end as gap_death_after_obs
    from cbse36ibcohort c
    inner join cbse36ibdeath_obs_status dos on dos.person_id = c.person_id
    left join patient_obs po  on po.person_id  = c.person_id
)
   select case
        when gap_death_after_obs <   30 then 'lt30d'
        when gap_death_after_obs <   60 then '30_59d'
        when gap_death_after_obs <   90 then '60_89d'
        when gap_death_after_obs <  180 then '90_179d'
        when gap_death_after_obs <  365 then '180_364d'
        when gap_death_after_obs <  730 then '365_729d'
        else 'ge730d'
    end as gap_bucket,
    count(*) as n_patients
   from death_obs_gaps
where gap_death_after_obs is not null
  group by  1   order by  case
        when gap_death_after_obs <   30 then 1
        when gap_death_after_obs <   60 then 2
        when gap_death_after_obs <   90 then 3
        when gap_death_after_obs <  180 then 4
        when gap_death_after_obs <  365 then 5
        when gap_death_after_obs <  730 then 6
        else 7
    end
  ;

