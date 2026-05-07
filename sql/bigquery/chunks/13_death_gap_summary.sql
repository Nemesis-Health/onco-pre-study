-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-07 06:29:46 BST
-- Source file    : sql/sql_server/chunks/13_death_gap_summary.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 13) Death date vs observation period alignment — summary counts
--     For patients in the DX cohort (and the FIRST_MET subgroup), reports:
--       - n_death_before_obs : death_date < first observation_period_start
--                              (data quality error — rare but important)
--       - n_death_after_obs  : death_date > last  observation_period_end
--                              (gap distribution summarized in chunk 14)
--       - lq/median/uq/p90 percentiles of the post-obs gap (days).
--
--     Stratified by anchor (INDEX / FIRST_MET).
--     Small-cell suppression intentionally NOT applied here — these are
--     aggregate distribution statistics over (already small) flagged subsets.
with patient_obs as (
     select person_id,
        min(observation_period_start_date) as first_obs_start,
        max(observation_period_end_date)   as last_obs_end
     from @cdm_database_schema.observation_period
    where person_id in (select person_id from u2ijfaoqcohort)
     group by  1 ),
death_obs_gaps as (
    select
        c.person_id,
        c.index_date,
        ms.first_met_date,
        dos.death_date,
        po.first_obs_start,
        po.last_obs_end,
        case
            when dos.death_date > po.last_obs_end
                then DATE_DIFF(IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), IF(SAFE_CAST(po.last_obs_end  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(po.last_obs_end  AS STRING)),SAFE_CAST(po.last_obs_end  AS DATE)), DAY)
            else null
        end as gap_death_after_obs,
        case
            when dos.death_date < po.first_obs_start
                then 1
            else 0
        end as death_before_obs
    from u2ijfaoqcohort c
    inner join u2ijfaoqdeath_obs_status dos on dos.person_id = c.person_id
    left join u2ijfaoqmet_summary ms on ms.person_id = c.person_id
    left join patient_obs po  on po.person_id  = c.person_id
)
select
    'INDEX' as anchor_event,
    sum(case when death_before_obs = 1 then 1 else 0 end) as n_death_before_obs,
    sum(case when gap_death_after_obs is not null then 1 else 0 end) as n_death_after_obs,
    min(case when gap_death_after_obs is not null and  4.0 * rn >= non_null_cnt then cast(gap_death_after_obs  as float64) end) as lq_gap_days,
    min(case when gap_death_after_obs is not null and  2.0 * rn >= non_null_cnt then cast(gap_death_after_obs  as float64) end) as median_gap_days,
    min(case when gap_death_after_obs is not null and  4.0 * rn >= 3 * non_null_cnt then cast(gap_death_after_obs  as float64) end) as uq_gap_days,
    min(case when gap_death_after_obs is not null and 10.0 * rn >= 9 * non_null_cnt then cast(gap_death_after_obs  as float64) end) as p90_gap_days
from (
    select death_before_obs, gap_death_after_obs,
        row_number() over (order by gap_death_after_obs) as rn,
        sum(case when gap_death_after_obs is not null then 1 else 0 end) over () as non_null_cnt
    from death_obs_gaps
    where death_date is not null
) x
union all
select
    'FIRST_MET' as anchor_event,
    sum(case when death_before_obs = 1 then 1 else 0 end) as n_death_before_obs,
    sum(case when gap_death_after_obs is not null then 1 else 0 end) as n_death_after_obs,
    min(case when gap_death_after_obs is not null and  4.0 * rn >= non_null_cnt then cast(gap_death_after_obs  as float64) end) as lq_gap_days,
    min(case when gap_death_after_obs is not null and  2.0 * rn >= non_null_cnt then cast(gap_death_after_obs  as float64) end) as median_gap_days,
    min(case when gap_death_after_obs is not null and  4.0 * rn >= 3 * non_null_cnt then cast(gap_death_after_obs  as float64) end) as uq_gap_days,
    min(case when gap_death_after_obs is not null and 10.0 * rn >= 9 * non_null_cnt then cast(gap_death_after_obs  as float64) end) as p90_gap_days
from (
    select death_before_obs, gap_death_after_obs,
        row_number() over (order by gap_death_after_obs) as rn,
        sum(case when gap_death_after_obs is not null then 1 else 0 end) over () as non_null_cnt
    from death_obs_gaps
    where death_date is not null
      and first_met_date is not null
) x
;

