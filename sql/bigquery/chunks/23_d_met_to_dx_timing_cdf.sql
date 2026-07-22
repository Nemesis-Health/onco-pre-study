-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/23_d_met_to_dx_timing_cdf.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 23) D. MET-first subgroup, part 3b. The same MET-to-first-specific-DX gap as
--     chunk 22, expressed cumulatively (CDF) so a linking cutoff can be read off
--     directly, plus the median gap.
--     For the MET_FIRST_THEN_DX group of chunk 20, the number of patients whose
--     first specific DX has ARRIVED BY each day threshold after the first MET.
--     Cumulative and monotonically non-decreasing across thresholds:
--
--       n_arrived_by_30d, _45d, _60d, _90d, _180d, _365d
--
--     Thresholds 30/45/60/90 are the candidate cutoffs; 180/365 give the longer
--     shape. All time is AFTER the first MET by construction, so there is no before
--     side and no day-0 mass. Patients whose specific DX arrives after 365 days are
--     the >1-year tail, derivable as n_patients_reaching_dx_total - n_arrived_by_365d.
--
--     median_days_met_to_dx: median gap (days) among the same patients, using the
--     framework's ordered-set median convention (lower-middle value for even n, as
--     in chunks 16-17 and 00_setup.sql).
--
--     Denominator (n_patients_reaching_dx_total):
--       MET-first patients who reach a specific DX (same as chunk 22). Under the
--       corrected DX-anchored population every MET-first patient reaches a specific
--       DX, so this equals the full MET-first subgroup.
--
--     Population and observation-period notes: same as chunk 20 (DX-anchored MET
--     population from #met_events, first specific DX from #dx_events, anchored on
--     #anchor_person, no observation-period gate).
--
--     Small-cell suppression: each cumulative count in (0, @min_cell_count] set to
--     -@min_cell_count; median set to NULL when its denominator is suppressed.
--     n_patients_reaching_dx_total is an aggregate denominator, not suppressed.
with met_all as (
     select person_id,
        min(event_date) as first_met_date
     from vcbo5u4zmet_events
     group by  1 ),
dx_all as (
     select person_id,
        min(event_date) as first_dx_date
     from vcbo5u4zdx_events
     group by  1 ),
gap as (
    select
        ma.person_id,
        DATE_DIFF(IF(SAFE_CAST(dx.first_dx_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dx.first_dx_date  AS STRING)),SAFE_CAST(dx.first_dx_date  AS DATE)), IF(SAFE_CAST(ma.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ma.first_met_date  AS STRING)),SAFE_CAST(ma.first_met_date  AS DATE)), DAY) as gap_days
    from met_all ma
    join dx_all dx
      on dx.person_id = ma.person_id
    where ma.first_met_date < dx.first_dx_date
),
med as (
    select min(case when 2.0 * rn >= cnt then cast(gap_days  as float64) end) as median_days
    from (
        select
            gap_days,
            row_number() over (order by gap_days) as rn,
            count(*)     over ()                  as cnt
        from gap
    ) x
),
agg as (
    select
        count(*)                                          as n_total,
        sum(case when gap_days <= 30  then 1 else 0 end)  as n_by_30,
        sum(case when gap_days <= 45  then 1 else 0 end)  as n_by_45,
        sum(case when gap_days <= 60  then 1 else 0 end)  as n_by_60,
        sum(case when gap_days <= 90  then 1 else 0 end)  as n_by_90,
        sum(case when gap_days <= 180 then 1 else 0 end)  as n_by_180,
        sum(case when gap_days <= 365 then 1 else 0 end)  as n_by_365
    from gap
)
select
    a.n_total as n_patients_reaching_dx_total,
    case when a.n_by_30  > 0 and a.n_by_30  <= @min_cell_count then -@min_cell_count else a.n_by_30  end as n_arrived_by_30d,
    case when a.n_by_45  > 0 and a.n_by_45  <= @min_cell_count then -@min_cell_count else a.n_by_45  end as n_arrived_by_45d,
    case when a.n_by_60  > 0 and a.n_by_60  <= @min_cell_count then -@min_cell_count else a.n_by_60  end as n_arrived_by_60d,
    case when a.n_by_90  > 0 and a.n_by_90  <= @min_cell_count then -@min_cell_count else a.n_by_90  end as n_arrived_by_90d,
    case when a.n_by_180 > 0 and a.n_by_180 <= @min_cell_count then -@min_cell_count else a.n_by_180 end as n_arrived_by_180d,
    case when a.n_by_365 > 0 and a.n_by_365 <= @min_cell_count then -@min_cell_count else a.n_by_365 end as n_arrived_by_365d,
    case when a.n_total <= @min_cell_count then null else m.median_days end as median_days_met_to_dx
from agg a
cross join med m
;

