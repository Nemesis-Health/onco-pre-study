-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/27_h_before_curve_cdf.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 27) H. Metastasis-to-treatment timing (Part 2, before-curve) <U+2014> cumulative reach
--     of the CLOSEST-before treatment, over the closest-before patients.
--     Over the patients whose CLOSEST antineoplastic (L01) record is strictly
--     before the first Metastasis (chunk 24 CLOSEST_L01_BEFORE_MET), the number
--     whose closest-before record sits WITHIN each day threshold before the first
--     MET. Cumulative and monotonically non-decreasing across thresholds. Reads
--     "how far back the nearest before-MET treatment sits":
--
--       n_within_30d_before, _60d, _90d, _180d, _365d
--
--     days_before = ABS(days_diff) of the closest record (all values >= 1 by
--     construction; day 0 is a separate central category, not on this curve). The
--     curve is CLOSEST-based, so it agrees with the histogram's before bars
--     (chunk 26, bin_order 1-6). Patients whose closest-before treatment is more
--     than 365 days before the MET are the earlier-than-one-year tail, derivable as
--     n_before_total - n_within_365d_before.
--
--     median_days_before_closest: median days_before among the same patients, using
--     the framework's ordered-set median convention (lower-middle value for even n,
--     as in chunks 16-17, 23 and 00_setup.sql).
--
--     Denominator (n_before_total):
--       closest-before patients (= chunk 24 CLOSEST_L01_BEFORE_MET n_patients).
--
--     NOTE (direction). This is the BEFORE curve. It reads leftward (backward in
--     time) from the first MET and uses its own directional denominator; it is
--     never combined with the after-curve into a symmetric window.
--
--     Population, observation-period and L01-source notes: same as chunk 24
--     (DX-anchored MET population from #met_events; L01 from #l01_events, gated to the
--     same #anchor_person cohort; no observation-period gate). No change to 00_setup.sql.
--
--     Small-cell suppression: each cumulative count in (0, @min_cell_count] set to
--     -@min_cell_count; median set to NULL when its denominator is suppressed.
--     n_before_total is an aggregate denominator, not suppressed.
with met_all as (
     select person_id,
        min(event_date) as first_met_date
     from vcbo5u4zmet_events
     group by  1 ),
l01_all as (
    select
        person_id,
        event_date
    from vcbo5u4zl01_events
),
pair as (
    select
        ma.person_id,
        DATE_DIFF(IF(SAFE_CAST(la.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(la.event_date  AS STRING)),SAFE_CAST(la.event_date  AS DATE)), IF(SAFE_CAST(ma.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ma.first_met_date  AS STRING)),SAFE_CAST(ma.first_met_date  AS DATE)), DAY) as days_diff,
        la.event_date
    from met_all ma
    join l01_all la
      on la.person_id = ma.person_id
),
closest as (
    select
        person_id,
        days_diff,
        row_number() over (
            partition by person_id
            order by abs(days_diff), event_date
        ) as rn
    from pair
),
before_closest as (
    -- Closest record is strictly before the first MET.
    select
        person_id,
        abs(days_diff) as days_before
    from closest
    where rn = 1
      and days_diff < 0
),
med as (
    select min(case when 2.0 * rn >= cnt then cast(days_before  as float64) end) as median_days
    from (
        select
            days_before,
            row_number() over (order by days_before) as rn,
            count(*)     over ()                     as cnt
        from before_closest
    ) x
),
agg as (
    select
        count(*)                                           as n_total,
        sum(case when days_before <= 30  then 1 else 0 end) as n_30,
        sum(case when days_before <= 60  then 1 else 0 end) as n_60,
        sum(case when days_before <= 90  then 1 else 0 end) as n_90,
        sum(case when days_before <= 180 then 1 else 0 end) as n_180,
        sum(case when days_before <= 365 then 1 else 0 end) as n_365
    from before_closest
)
select
    a.n_total as n_before_total,
    case when a.n_30  > 0 and a.n_30  <= @min_cell_count then -@min_cell_count else a.n_30  end as n_within_30d_before,
    case when a.n_60  > 0 and a.n_60  <= @min_cell_count then -@min_cell_count else a.n_60  end as n_within_60d_before,
    case when a.n_90  > 0 and a.n_90  <= @min_cell_count then -@min_cell_count else a.n_90  end as n_within_90d_before,
    case when a.n_180 > 0 and a.n_180 <= @min_cell_count then -@min_cell_count else a.n_180 end as n_within_180d_before,
    case when a.n_365 > 0 and a.n_365 <= @min_cell_count then -@min_cell_count else a.n_365 end as n_within_365d_before,
    case when a.n_total <= @min_cell_count then null else m.median_days end as median_days_before_closest
from agg a
cross join med m
;

