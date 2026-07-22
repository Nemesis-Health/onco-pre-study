-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/25_h_after_curve_population_reconciliation.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 25) H. Metastasis-to-treatment timing (Part 1 support) <U+2014> reconciliation of the
--     two treated-patient populations Part 2 uses, and the bilateral-treatment
--     count referenced in the Part 1 caption.
--     Part 2 deliberately reads its two cumulative curves over DIFFERENT
--     denominators (AA's decision, 13 Jul 2026): the before-curve and the signed
--     histogram are CLOSEST-based, while the after-curve is over EVERY patient with
--     any antineoplastic (L01) record strictly after the first Metastasis. This
--     chunk quantifies exactly how those populations relate, so the after-curve's
--     superset construction is auditable rather than asserted. One row.
--
--     Over the treated MET patients (>= 1 L01 record), per-patient side flags are
--     built from the signed L01-to-first-MET distances:
--       has_before = any L01 record strictly before the first MET (days_diff < 0)
--       has_day0   = any L01 record on the first MET date        (days_diff = 0)
--       has_after  = any L01 record strictly after the first MET (days_diff > 0)
--     and each treated patient's CLOSEST side (BEFORE / DAY0 / AFTER) is taken from
--     the single closest record (same convention as chunk 24).
--
--     Columns (each a patient count over the treated subgroup):
--       n_treated                   before + day0 + after treated patients
--                                   (= chunk 24 before + day0 + after)
--       n_closest_after             treated patients whose CLOSEST record is after
--                                   the first MET (the histogram's after bars, and
--                                   the old closest-after after-curve population)
--       n_after_any                 treated patients with ANY strictly-after L01
--                                   record (the Part 2 after-curve denominator);
--                                   a SUPERSET of n_closest_after
--       n_after_any_added           n_after_any - n_closest_after: patients added to
--                                   the after-curve by re-basing it on any-after
--                                   rather than closest-after (their closest record
--                                   is before or on the MET day, but they also have
--                                   a real after-MET record)
--       n_bilateral                 treated patients with a record on BOTH sides
--                                   (has_before = 1 AND has_after = 1)
--       n_bilateral_closest_before  bilateral patients whose CLOSEST record is
--                                   before the MET (collapsed to the before side by
--                                   the closest-only view; these are the core of
--                                   n_after_any_added)
--       n_bilateral_closest_after   bilateral patients whose CLOSEST record is after
--                                   the MET (already inside n_closest_after)
--
--     JUDGMENT CALL / FLAG (after = strictly after, day 0 excluded). The after-curve
--     population is patients with any record with days_diff > 0. Day 0 is its own
--     explicit category and belongs to NEITHER curve, per the locked design
--     principle and the approved mock. The task prose phrased this as "on or after,"
--     but the mock (source of truth) and the day-0-explicit rule make it strictly
--     after; day-0 treatment is not counted toward the after-curve. Flagged rather
--     than silently decided.
--
--     JUDGMENT CALL / FLAG (superset arithmetic). n_after_any_added collects
--     every treated patient with an after-MET record whose closest record is NOT
--     after: closest-before-with-after (= n_bilateral_closest_before) plus the
--     residual closest-on-day-0-with-after. The mock modelled the added group as
--     40 closest-before patients only and assumed no day-0-closest patient also has
--     a later after-MET record; in real data that day-0 residual may be non-zero,
--     so n_after_any is computed directly as "any strictly-after record" and will
--     be >= the mock's 392 + 40 decomposition. n_after_any_added minus
--     n_bilateral_closest_before is that day-0 residual.
--
--     Population, observation-period and L01-source notes: same as chunk 24
--     (DX-anchored MET population from #met_events; L01 from #l01_events, gated to the
--     same #anchor_person cohort; no observation-period gate). No change to 00_setup.sql.
--
--     Small-cell suppression: each count in (0, @min_cell_count] set to
--     -@min_cell_count.
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
flags as (
    -- Per treated patient: which sides of the first MET carry any L01 record.
     select person_id,
        max(case when days_diff < 0 then 1 else 0 end) as has_before,
        max(case when days_diff = 0 then 1 else 0 end) as has_day0,
        max(case when days_diff > 0 then 1 else 0 end) as has_after
     from pair
     group by  1 ),
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
closest_side as (
    select
        person_id,
        case when days_diff < 0 then 'BEFORE'
             when days_diff = 0 then 'DAY0'
             else                    'AFTER' end as cside
    from closest
    where rn = 1
),
combined as (
    select
        f.person_id,
        f.has_before,
        f.has_after,
        cs.cside
    from flags f
    join closest_side cs
      on cs.person_id = f.person_id
),
agg as (
    select
        count(*)                                                                       as n_treated,
        sum(case when cside = 'AFTER' then 1 else 0 end)                               as n_closest_after,
        sum(has_after)                                                                 as n_after_any,
        sum(case when has_before = 1 and has_after = 1 then 1 else 0 end)              as n_bilateral,
        sum(case when has_before = 1 and has_after = 1 and cside = 'BEFORE' then 1 else 0 end) as n_bilateral_closest_before,
        sum(case when has_before = 1 and has_after = 1 and cside = 'AFTER'  then 1 else 0 end) as n_bilateral_closest_after
    from combined
)
select
    case when n_treated                  > 0 and n_treated                  <= @min_cell_count then -@min_cell_count else n_treated                  end as n_treated,
    case when n_closest_after            > 0 and n_closest_after            <= @min_cell_count then -@min_cell_count else n_closest_after            end as n_closest_after,
    case when n_after_any                > 0 and n_after_any                <= @min_cell_count then -@min_cell_count else n_after_any                end as n_after_any,
    case when (n_after_any - n_closest_after) > 0 and (n_after_any - n_closest_after) <= @min_cell_count then -@min_cell_count else (n_after_any - n_closest_after) end as n_after_any_added,
    case when n_bilateral                > 0 and n_bilateral                <= @min_cell_count then -@min_cell_count else n_bilateral                end as n_bilateral,
    case when n_bilateral_closest_before > 0 and n_bilateral_closest_before <= @min_cell_count then -@min_cell_count else n_bilateral_closest_before end as n_bilateral_closest_before,
    case when n_bilateral_closest_after  > 0 and n_bilateral_closest_after  <= @min_cell_count then -@min_cell_count else n_bilateral_closest_after  end as n_bilateral_closest_after
from agg
;

