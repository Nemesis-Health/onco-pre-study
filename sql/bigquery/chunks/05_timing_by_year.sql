-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-06 18:06:52 BST
-- Source file    : sql/sql_server/chunks/05_timing_by_year.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 5) Pairwise timing summary stratified by index year
--    Same structure as chunk 04 (final_timing_pairwise.csv) but grouped by
--    YEAR(index_date) instead of OVERALL.  Used for year-over-year plots and
--    for the per-year columns in the §06 stability matrix.
--
--    Only first_to_first timing is exported here (DX->MET, MET->L01 are the
--    primary year-over-year metrics).  Small-cell suppression applied.
 select x.timing_type,
    x.index_year,
    x.from_event,
    x.to_event,
    case when x.n_patients_with_pair <= @min_cell_count then -@min_cell_count else x.n_patients_with_pair end as n_patients_with_pair,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p25_days  end as p25_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p50_days  end as p50_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p75_days  end as p75_days
 from (
    -- first_to_first by year
     select 'first_to_first' as timing_type,
        cast(EXTRACT(YEAR from pc.index_date) as STRING) as index_year,
        p.from_event,
        p.to_event,
        count(*) as n_patients_with_pair,
        percentile_cont(0.25) within group (order by p.days_diff) as p25_days,
        percentile_cont(0.50) within group (order by p.days_diff) as p50_days,
        percentile_cont(0.75) within group (order by p.days_diff) as p75_days
     from cbse36ibpatient_timing_pairs p
    join cbse36ibpatient_char pc on p.person_id = pc.person_id
     group by  2, p.from_event, p.to_event
    union all
    -- first_to_closest_after by year (for MET->L01 post-MET treatment timing)
     select 'first_to_closest_after' as timing_type, cast(EXTRACT(YEAR from pc.index_date) as STRING) as index_year, p.from_event, p.to_event, count(*) as n_patients_with_pair, percentile_cont(0.25) within group (order by p.days_diff) as p25_days, percentile_cont(0.50) within group (order by p.days_diff) as p50_days, percentile_cont(0.75) within group (order by p.days_diff) as p75_days
     from cbse36ibpatient_timing_pairs_first_to_closest_after p
    join cbse36ibpatient_char pc on p.person_id = pc.person_id
     group by  2, p.from_event, p.to_event
  ) x
 order by  x.timing_type, x.from_event, x.to_event, cast(x.index_year  as int64)
 ;

