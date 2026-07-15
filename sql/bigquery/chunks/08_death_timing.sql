-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/08_death_timing.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 8) Death timing from INDEX and FIRST_MET (stratified by calendar year of index date and OVERALL)
 select s.prevalence_year,
    s.anchor_event,
    case when s.n_patients <= @min_cell_count then -@min_cell_count else s.n_patients end as n_patients,
    case
        when s.n_patients <= @min_cell_count then -@min_cell_count
        when s.n_deaths between 1 and @min_cell_count then -@min_cell_count
        else s.n_deaths
    end as n_deaths,
    case when s.n_patients <= @min_cell_count or s.n_deaths <= @min_cell_count then null else s.n_deaths_in_obs end as n_deaths_in_obs,
    case when s.n_patients <= @min_cell_count or s.n_deaths <= @min_cell_count then null else s.n_deaths_out_obs end as n_deaths_out_obs,
    case when s.n_patients <= @min_cell_count or s.n_deaths <= @min_cell_count then null else q.lq_days end as lq_days,
    case when s.n_patients <= @min_cell_count or s.n_deaths <= @min_cell_count then null else q.median_days end as median_days,
    case when s.n_patients <= @min_cell_count or s.n_deaths <= @min_cell_count then null else q.uq_days end as uq_days,
    case when s.n_patients <= @min_cell_count then null else f.lq_followup_days end as lq_followup_days,
    case when s.n_patients <= @min_cell_count then null else f.median_followup_days end as median_followup_days,
    case when s.n_patients <= @min_cell_count then null else f.uq_followup_days end as uq_followup_days
 from vcbo5u4zdeath_stratum_counts s
left join vcbo5u4zdeath_timing_quantiles q
  on s.prevalence_year = q.prevalence_year
 and s.anchor_event = q.anchor_event
left join vcbo5u4zfollowup_quantiles f
  on s.prevalence_year = f.prevalence_year
 and s.anchor_event = f.anchor_event
 order by  case when s.prevalence_year = 'OVERALL' then 0 else 1 end, case when s.prevalence_year = 'OVERALL' then null else cast(s.prevalence_year  as int64) end, case when s.anchor_event = 'INDEX' then 0 else 1 end
 ;

