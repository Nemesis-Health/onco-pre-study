-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-06 18:06:52 BST
-- Source file    : sql/sql_server/chunks/09_demographics.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 9) Demographics at anchor dates (INDEX = first DX, FIRST_MET = first MET)
-- Gender concept IDs (OMOP): 8507=Male, 8532=Female. Others treated as unknown.
with anchor_persons as (
    select
        'INDEX' as anchor_event,
        c.person_id,
        c.index_date as anchor_date
    from cbse36ibpatient_char c
    where c.index_date is not null
    union all
    select
        'FIRST_MET' as anchor_event,
        c.person_id,
        c.first_met_date as anchor_date
    from cbse36ibpatient_char c
    where c.first_met_date is not null
),
base as (
    select
        a.anchor_event,
        a.person_id,
        a.anchor_date,
        p.gender_concept_id,
        p.birth_datetime,
        p.year_of_birth
    from anchor_persons a
    join @cdm_database_schema.person p
      on a.person_id = p.person_id
),
ages as (
    select
        anchor_event,
        person_id,
        gender_concept_id,
        case
            when birth_datetime is not null
                then DATE_DIFF(IF(SAFE_CAST(anchor_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(anchor_date  AS STRING)),SAFE_CAST(anchor_date  AS DATE)), IF(SAFE_CAST(IF(SAFE_CAST(birth_datetime  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(birth_datetime  AS STRING)),SAFE_CAST(birth_datetime  AS DATE))  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(IF(SAFE_CAST(birth_datetime  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(birth_datetime  AS STRING)),SAFE_CAST(birth_datetime  AS DATE))  AS STRING)),SAFE_CAST(IF(SAFE_CAST(birth_datetime  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(birth_datetime  AS STRING)),SAFE_CAST(birth_datetime  AS DATE))  AS DATE)), DAY) / 365.25
            when year_of_birth is not null
                then DATE_DIFF(IF(SAFE_CAST(anchor_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(anchor_date  AS STRING)),SAFE_CAST(anchor_date  AS DATE)), IF(SAFE_CAST(DATE(year_of_birth, 7, 1)  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(DATE(year_of_birth, 7, 1)  AS STRING)),SAFE_CAST(DATE(year_of_birth, 7, 1)  AS DATE)), DAY) / 365.25
            else null
        end as age_years
    from base
)
 select agg.anchor_event,
    agg.n_patients,
    agg.n_male,
    agg.n_female,
    agg.pct_male,
    agg.pct_female,
    p.age_lq_years,
    p.age_median_years,
    p.age_uq_years
 from (
     select anchor_event,
        count(*) as n_patients,
        sum(case when gender_concept_id = 8507 then 1 else 0 end) as n_male,
        sum(case when gender_concept_id = 8532 then 1 else 0 end) as n_female,
        cast(100.0 * sum(case when gender_concept_id = 8507 then 1 else 0 end) / nullif(count(*), 0)  as float64) as pct_male,
        cast(100.0 * sum(case when gender_concept_id = 8532 then 1 else 0 end) / nullif(count(*), 0)  as float64) as pct_female
     from ages
    where age_years is not null
     group by  1 ) agg
join (
     select anchor_event,
        percentile_cont(0.25) within group (order by age_years) as age_lq_years,
        percentile_cont(0.50) within group (order by age_years) as age_median_years,
        percentile_cont(0.75) within group (order by age_years) as age_uq_years
     from ages
    where age_years is not null
     group by  1 ) p
  on agg.anchor_event = p.anchor_event
 order by  case when agg.anchor_event = 'INDEX' then 0 else 1 end
 ;

