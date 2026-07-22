-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/28_h_after_curve_cdf.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 28) H. Metastasis-to-treatment timing (Part 2, after-curve) <U+2014> cumulative reach
--     of the FIRST after-Metastasis treatment, over EVERY patient with any
--     after-Metastasis treatment (the re-based after population, AA's decision
--     13 Jul 2026).
--     Over the patients who have ANY antineoplastic (L01) record strictly after the
--     first Metastasis (days_diff > 0), timed by that patient's FIRST such record
--     (the minimum positive days_diff), the number whose first after-MET treatment
--     has arrived WITHIN each day threshold after the first MET. Cumulative and
--     monotonically non-decreasing:
--
--       n_within_30d_after, _60d, _90d, _180d, _365d
--
--     This is the forward attribution window: for any forward window it reads the
--     share of everyone eventually treated after the MET who is captured by that
--     window. Patients whose first after-MET treatment is more than 365 days out
--     are the later-than-one-year tail, derivable as
--     n_after_any_total - n_within_365d_after.
--
--     median_days_after_first: median first-after-MET days among the same patients,
--     framework ordered-set median convention (lower-middle for even n, as in
--     chunks 16-17, 23, 27 and 00_setup.sql).
--
--     Denominator (n_after_any_total):
--       patients with any strictly-after L01 record (= chunk 25 n_after_any). This
--       is a SUPERSET of the closest-after patients (chunk 25 n_closest_after and
--       the histogram after bars, chunk 26): it adds patients whose closest record
--       is before or on the MET day but who also have a genuine after-MET record.
--       Consequently this curve is NOT the cumulative of the histogram's after bars,
--       by design.
--
--     JUDGMENT CALL / FLAG (population definition, differs from before-curve and
--     histogram). Unlike the CLOSEST-based before-curve (chunk 27) and histogram
--     (chunk 26), this after-curve is over the ANY-strictly-after population and is
--     timed by each patient's FIRST after-MET record, not their closest record.
--       - Day 0 is excluded (strictly after, days_diff > 0), consistent with the
--         locked day-0-explicit principle; day-0 treatment is on neither curve. The
--         task prose said "on or after," reconciled here to strictly after per the
--         mock (source of truth) and the day-0 rule.
--       - A patient with treatment ONLY before the MET and none strictly after
--         correctly falls OUT of this curve (no positive days_diff, so absent from
--         the WHERE days_diff > 0 set).
--       - A closest-before patient who ALSO has an after-MET record is INCLUDED
--         here (via their after record) while remaining on the before side of the
--         histogram and before-curve; this is the intended superset behaviour.
--
--     Population, observation-period and L01-source notes: same as chunk 24
--     (DX-anchored MET population from #met_events; L01 from #l01_events, gated to the
--     same #anchor_person cohort; no observation-period gate). No change to 00_setup.sql.
--
--     Small-cell suppression: each cumulative count in (0, @min_cell_count] set to
--     -@min_cell_count; median set to NULL when its denominator is suppressed.
--     n_after_any_total is an aggregate denominator, not suppressed.
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
        DATE_DIFF(IF(SAFE_CAST(la.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(la.event_date  AS STRING)),SAFE_CAST(la.event_date  AS DATE)), IF(SAFE_CAST(ma.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ma.first_met_date  AS STRING)),SAFE_CAST(ma.first_met_date  AS DATE)), DAY) as days_diff
    from met_all ma
    join l01_all la
      on la.person_id = ma.person_id
),
after_first as (
    -- One row per patient with any strictly-after record: their first after-MET day.
     select person_id,
        min(days_diff) as first_after_days
     from pair
    where days_diff > 0
     group by  1 ),
med as (
    select min(case when 2.0 * rn >= cnt then cast(first_after_days  as float64) end) as median_days
    from (
        select
            first_after_days,
            row_number() over (order by first_after_days) as rn,
            count(*)     over ()                          as cnt
        from after_first
    ) x
),
agg as (
    select
        count(*)                                                as n_total,
        sum(case when first_after_days <= 30  then 1 else 0 end) as n_30,
        sum(case when first_after_days <= 60  then 1 else 0 end) as n_60,
        sum(case when first_after_days <= 90  then 1 else 0 end) as n_90,
        sum(case when first_after_days <= 180 then 1 else 0 end) as n_180,
        sum(case when first_after_days <= 365 then 1 else 0 end) as n_365
    from after_first
)
select
    a.n_total as n_after_any_total,
    case when a.n_30  > 0 and a.n_30  <= @min_cell_count then -@min_cell_count else a.n_30  end as n_within_30d_after,
    case when a.n_60  > 0 and a.n_60  <= @min_cell_count then -@min_cell_count else a.n_60  end as n_within_60d_after,
    case when a.n_90  > 0 and a.n_90  <= @min_cell_count then -@min_cell_count else a.n_90  end as n_within_90d_after,
    case when a.n_180 > 0 and a.n_180 <= @min_cell_count then -@min_cell_count else a.n_180 end as n_within_180d_after,
    case when a.n_365 > 0 and a.n_365 <= @min_cell_count then -@min_cell_count else a.n_365 end as n_within_365d_after,
    case when a.n_total <= @min_cell_count then null else m.median_days end as median_days_after_first
from agg a
cross join med m
;

