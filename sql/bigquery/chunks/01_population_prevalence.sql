-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-06 18:36:52 BST
-- Source file    : sql/sql_server/chunks/01_population_prevalence.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 1) Population prevalence
with base as (
     select case
            when grouping(EXTRACT(YEAR from index_date)) = 1 then 'OVERALL'
            else cast(EXTRACT(YEAR from index_date) as STRING)
        end as prevalence_year,
        count(*) as n_patients,
        sum(case when first_other_dx_date is not null then 1 else 0 end) as n_with_other_dx,
        sum(case when first_gen_cancer_date is not null then 1 else 0 end) as n_with_gen_cancer_dx,
        sum(case when first_met_date is not null then 1 else 0 end) as n_with_met,
        sum(case when first_l01_date is not null then 1 else 0 end) as n_with_l01
     from ldpw47q6patient_char
     group by  grouping sets (
        (),
        (EXTRACT(YEAR from index_date))
    )
 )
 select prevalence_year,
    case when n_patients <= @min_cell_count then -@min_cell_count else n_patients end as n_dx,
    case
        when n_patients <= @min_cell_count then -@min_cell_count
        when n_with_other_dx between 1 and @min_cell_count then -@min_cell_count
        else n_with_other_dx
    end as n_odx,
    case
        when n_patients <= @min_cell_count then -@min_cell_count
        when n_with_gen_cancer_dx between 1 and @min_cell_count then -@min_cell_count
        else n_with_gen_cancer_dx
    end as n_gdx,
    case
        when n_patients <= @min_cell_count then -@min_cell_count
        when n_with_met between 1 and @min_cell_count then -@min_cell_count
        else n_with_met
    end as n_met,
    case
        when n_patients <= @min_cell_count then -@min_cell_count
        when n_with_l01 between 1 and @min_cell_count then -@min_cell_count
        else n_with_l01
    end as n_l01
 from base
 order by  case when prevalence_year = 'OVERALL' then 0 else 1 end, case when prevalence_year = 'OVERALL' then null else cast(prevalence_year  as int64) end
 ;

