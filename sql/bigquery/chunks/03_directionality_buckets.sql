-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-07 11:54:00 BST
-- Source file    : sql/sql_server/chunks/03_directionality_buckets.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 3) Temporal directionality buckets
--    Exact patient counts by direction category for key event pairs:
--      DX -> MET  (using index_date -> first_met_date from #patient_char)
--      MET -> L01 (using first_met_date -> first_l01_date from #patient_char)
--
--    Categories (days = TO_date - FROM_date):
--      BEFORE_GT90  : TO event > 90 days before FROM  (days < -90)
--      BEFORE_1_90  : TO event 1-90 days before FROM  (-90 <= days < 0)
--      SAME_DAY     : same calendar day                (days = 0)
--      AFTER_1_30   : 1-30 days after                  (1 <= days <= 30)
--      AFTER_31_90  : 31-90 days after                 (31 <= days <= 90)
--      AFTER_91_365 : 91-365 days after                (91 <= days <= 365)
--      AFTER_GT365  : > 365 days after                 (days > 365)
--      NO_EVENT     : FROM event present but TO event absent
--
--    Stratified by OVERALL and by anchor year: DX_MET uses YEAR(index_date), MET_L01 uses YEAR(first_met_date).
--    Small-cell suppression: n suppressed to -@min_cell_count when <= @min_cell_count.
with dx_met_base as (
    select
        EXTRACT(YEAR from index_date) as index_year_int,
        case
            when first_met_date is null  then 'NO_EVENT'
            when days_dx_to_met < -90    then 'BEFORE_GT90'
            when days_dx_to_met < 0      then 'BEFORE_1_90'
            when days_dx_to_met = 0      then 'SAME_DAY'
            when days_dx_to_met <= 30    then 'AFTER_1_30'
            when days_dx_to_met <= 90    then 'AFTER_31_90'
            when days_dx_to_met <= 365   then 'AFTER_91_365'
            else 'AFTER_GT365'
        end as direction
    from ctxb0wompatient_char
),
met_l01_base as (
    select
        EXTRACT(YEAR from first_met_date) as index_year_int,
        case
            when first_l01_date is null  then 'NO_EVENT'
            when days_met_to_l01 < -90   then 'BEFORE_GT90'
            when days_met_to_l01 < 0     then 'BEFORE_1_90'
            when days_met_to_l01 = 0     then 'SAME_DAY'
            when days_met_to_l01 <= 30   then 'AFTER_1_30'
            when days_met_to_l01 <= 90   then 'AFTER_31_90'
            when days_met_to_l01 <= 365  then 'AFTER_91_365'
            else 'AFTER_GT365'
        end as direction
    from ctxb0wompatient_char
    where first_met_date is not null
)
 select x.pair,
    x.index_year,
    x.direction,
    case when x.n_patients <= @min_cell_count then -@min_cell_count else x.n_patients end as n_patients
 from (
    -- DX -> MET: OVERALL
     select 'DX_MET'   as pair,
        'OVERALL'  as index_year,
        direction,
        count(*)   as n_patients
     from dx_met_base
     group by  direction
    union all
    -- DX -> MET: by index year
     select 'DX_MET'                              as pair, cast(index_year_int as STRING)    as index_year, 3, count(*)                              as n_patients
     from dx_met_base
     group by  2, direction
    union all
    -- MET -> L01: OVERALL
     select 'MET_L01'  as pair, 'OVERALL'  as index_year, 3, count(*)   as n_patients
     from met_l01_base
     group by  direction
    union all
    -- MET -> L01: by index year
     select 'MET_L01'                             as pair, cast(index_year_int as STRING)    as index_year, 3, count(*)                              as n_patients
     from met_l01_base
     group by  2, 3 ) x
 order by  x.pair, case when x.index_year = 'OVERALL' then 0 else 1 end, case when x.index_year = 'OVERALL' then null else cast(x.index_year  as int64) end, case x.direction
        when 'BEFORE_GT90'  then 1
        when 'BEFORE_1_90'  then 2
        when 'SAME_DAY'     then 3
        when 'AFTER_1_30'   then 4
        when 'AFTER_31_90'  then 5
        when 'AFTER_91_365' then 6
        when 'AFTER_GT365'  then 7
        when 'NO_EVENT'     then 8
        else 9
    end
 ;

