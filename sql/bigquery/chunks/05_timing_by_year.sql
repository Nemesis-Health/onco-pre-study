-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-07 12:40:20 BST
-- Source file    : sql/sql_server/chunks/05_timing_by_year.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 5) Pairwise timing summary stratified by anchor year
--    Same structure as chunk 04 (final_timing_pairwise.csv) but grouped by year.
--    Year is anchored on the from_event: DX-anchored pairs use YEAR(index_date),
--    MET-anchored pairs use YEAR(first_met_date).
--    Used for year-over-year plots and for the per-year columns in the §06 stability matrix.
--    Small-cell suppression applied.
 select x.timing_type,
    x.index_year,
    x.from_event,
    x.to_event,
    case when x.n_patients_with_pair <= @min_cell_count then -@min_cell_count else x.n_patients_with_pair end as n_patients_with_pair,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p25_days  end as p25_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p50_days  end as p50_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p75_days  end as p75_days
 from (
    -- first_to_first by anchor year
     select 'first_to_first' as timing_type,
        cast(index_year_int as STRING) as index_year,
        from_event,
        to_event,
        count(*) as n_patients_with_pair,
        min(case when 4.0 * rn >= cnt then cast(days_diff  as float64) end) as p25_days,
        min(case when 2.0 * rn >= cnt then cast(days_diff  as float64) end) as p50_days,
        min(case when 4.0 * rn >= 3 * cnt then cast(days_diff  as float64) end) as p75_days
     from (
        select p.from_event, p.to_event, p.days_diff,
            case when p.from_event = 'MET' then EXTRACT(YEAR from ms.first_met_date) else EXTRACT(YEAR from pc.index_date) end as index_year_int,
            row_number() over (partition by case when p.from_event = 'MET' then EXTRACT(YEAR from ms.first_met_date) else EXTRACT(YEAR from pc.index_date) end, p.from_event, p.to_event order by p.days_diff) as rn,
            count(*)     over (partition by case when p.from_event = 'MET' then EXTRACT(YEAR from ms.first_met_date) else EXTRACT(YEAR from pc.index_date) end, p.from_event, p.to_event)                    as cnt
        from a9of9doxpatient_timing_pairs p
        join a9of9doxpatient_char pc    on p.person_id = pc.person_id
        left join a9of9doxmet_summary ms on p.person_id = ms.person_id
    ) y
     group by  2, 3, to_event
    union all
    -- first_to_closest_after by anchor year (MET-anchored pairs use MET year)
     select 'first_to_closest_after' as timing_type, cast(index_year_int as STRING) as index_year, 3, 4, count(*) as n_patients_with_pair, min(case when 4.0 * rn >= cnt then cast(days_diff  as float64) end) as p25_days, min(case when 2.0 * rn >= cnt then cast(days_diff  as float64) end) as p50_days, min(case when 4.0 * rn >= 3 * cnt then cast(days_diff  as float64) end) as p75_days
     from (
        select p.from_event, p.to_event, p.days_diff,
            case when p.from_event = 'MET' then EXTRACT(YEAR from ms.first_met_date) else EXTRACT(YEAR from pc.index_date) end as index_year_int,
            row_number() over (partition by case when p.from_event = 'MET' then EXTRACT(YEAR from ms.first_met_date) else EXTRACT(YEAR from pc.index_date) end, p.from_event, p.to_event order by p.days_diff) as rn,
            count(*)     over (partition by case when p.from_event = 'MET' then EXTRACT(YEAR from ms.first_met_date) else EXTRACT(YEAR from pc.index_date) end, p.from_event, p.to_event)                    as cnt
        from a9of9doxpatient_timing_pairs_first_to_closest_after p
        join a9of9doxpatient_char pc    on p.person_id = pc.person_id
        left join a9of9doxmet_summary ms on p.person_id = ms.person_id
    ) y
     group by  2, 3, 2 ) x
 order by  x.timing_type, x.from_event, x.to_event, cast(x.index_year  as int64)
 ;

