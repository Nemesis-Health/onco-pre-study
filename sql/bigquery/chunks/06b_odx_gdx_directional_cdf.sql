-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/06b_odx_gdx_directional_cdf.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 6b) Directional ODX / GDX prevalence expressed CUMULATIVELY (CDF-style), so an
--     exclusion look-back (before) or follow-up (after) cutoff can be read off
--     directly. Cumulative companion to the disjoint bands in chunk 06; same
--     population, same closest-event-per-side construction, same two anchors.
--
--     For each anchor / event family / concept, the number of DISTINCT PATIENTS
--     whose closest event on a side sits WITHIN each day threshold of the anchor.
--     Because a patient counts as "within X" whenever ANY event on that side is
--     within X days of the anchor, n_within_Xd_before is exactly the number of
--     patients an X-day look-back exclusion would capture for this concept.
--     Counts are cumulative and monotonically non-decreasing across thresholds.
--
--     Anchors (both surfaced): INDEX (DX index_date, full DX cohort) and
--     FIRST_MET (first_met_date, MET subgroup only).
--     Families: ODX (other specific cancer dx), GDX (general / non-specific).
--     days = DATEDIFF(DAY, anchor_date, event_date); before = days <= -1,
--     after = days >= 1, day 0 its own category (never folded into a side).
--
--     Columns:
--       n_ever            : distinct patients with any event of the concept, any time.
--       n_before_ever     : distinct patients with any event before the anchor
--                           (the denominator for the before CDF; the tail beyond
--                           2 yr is n_before_ever - n_within_730d_before).
--       n_within_30d_before ... n_within_730d_before : cumulative before counts
--                           (patients with a before event within 30/90/180/365/730 days).
--       median_days_before: median of days-before over patients with any before
--                           event, days-before = distance of the closest-before
--                           event; framework ordered-set median convention
--                           (lower-middle for even n, as in chunks 16-17, 23, 27-28).
--       n_day0            : distinct patients with an event on the anchor day.
--       n_after_ever, n_within_30d_after ... n_within_730d_after, median_days_after:
--                           mirror of the before columns on the after side.
--
--     Covers ODX and GDX. All concepts reported; report builder limits to top N.
--
--     Small-cell suppression: each count in (0, @min_cell_count] set to
--     -@min_cell_count; a side median set to NULL when that side's denominator
--     (n_before_ever / n_after_ever) is <= @min_cell_count.
with events as (
    select 'INDEX' as anchor_event, 'ODX' as event_family, e.person_id, e.concept_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as days_from_anchor
    from vcbo5u4zother_dx_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
    union all
    select 'INDEX' as anchor_event, 'GDX' as event_family, e.person_id, e.concept_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as days_from_anchor
    from vcbo5u4zgen_cancer_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
    union all
    select 'FIRST_MET' as anchor_event, 'ODX' as event_family, e.person_id, e.concept_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) as days_from_anchor
    from vcbo5u4zother_dx_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
    join vcbo5u4zmet_summary ms on ms.person_id = c.person_id
    where ms.first_met_date is not null
    union all
    select 'FIRST_MET' as anchor_event, 'GDX' as event_family, e.person_id, e.concept_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) as days_from_anchor
    from vcbo5u4zgen_cancer_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
    join vcbo5u4zmet_summary ms on ms.person_id = c.person_id
    where ms.first_met_date is not null
),
per_person as (
     select anchor_event,
        event_family,
        concept_id,
        person_id,
        max(case when days_from_anchor = 0 then 1 else 0 end)      as has_day0,
        max(case when days_from_anchor < 0 then days_from_anchor end) as closest_before_days,
        min(case when days_from_anchor > 0 then days_from_anchor end) as closest_after_days
     from events
     group by  1, 2, 3, 4 ),
dir as (
    select
        anchor_event,
        event_family,
        concept_id,
        person_id,
        has_day0,
        case when closest_before_days is null then null else -closest_before_days end as days_before,
        closest_after_days as days_after
    from per_person
),
med_before as (
     select anchor_event,
        event_family,
        concept_id,
        min(case when 2.0 * rn >= cnt then cast(days_before  as float64) end) as median_days_before
     from (
        select
            anchor_event,
            event_family,
            concept_id,
            days_before,
            row_number() over (partition by anchor_event, event_family, concept_id order by days_before) as rn,
            count(*)     over (partition by anchor_event, event_family, concept_id)                      as cnt
        from dir
        where days_before is not null
    ) x
     group by  1, 2, 3 ),
med_after as (
     select anchor_event,
        event_family,
        concept_id,
        min(case when 2.0 * rn >= cnt then cast(days_after  as float64) end) as median_days_after
     from (
        select
            anchor_event,
            event_family,
            concept_id,
            days_after,
            row_number() over (partition by anchor_event, event_family, concept_id order by days_after) as rn,
            count(*)     over (partition by anchor_event, event_family, concept_id)                     as cnt
        from dir
        where days_after is not null
    ) x
     group by  1, 2, 3 ),
agg as (
     select anchor_event,
        event_family,
        concept_id,
        count(*)                                                       as n_ever,
        sum(case when days_before is not null then 1 else 0 end)       as n_before_ever,
        sum(case when days_before <= 30  then 1 else 0 end)            as n_before_30,
        sum(case when days_before <= 90  then 1 else 0 end)            as n_before_90,
        sum(case when days_before <= 180 then 1 else 0 end)            as n_before_180,
        sum(case when days_before <= 365 then 1 else 0 end)            as n_before_365,
        sum(case when days_before <= 730 then 1 else 0 end)            as n_before_730,
        sum(has_day0)                                                  as n_day0,
        sum(case when days_after is not null then 1 else 0 end)        as n_after_ever,
        sum(case when days_after <= 30  then 1 else 0 end)             as n_after_30,
        sum(case when days_after <= 90  then 1 else 0 end)             as n_after_90,
        sum(case when days_after <= 180 then 1 else 0 end)             as n_after_180,
        sum(case when days_after <= 365 then 1 else 0 end)             as n_after_365,
        sum(case when days_after <= 730 then 1 else 0 end)             as n_after_730
     from dir
     group by  1, 2, 3 )
 select a.anchor_event,
    a.event_family,
    a.concept_id,
    case when a.n_ever        > 0 and a.n_ever        <= @min_cell_count then -@min_cell_count else a.n_ever        end as n_ever,
    case when a.n_before_ever > 0 and a.n_before_ever <= @min_cell_count then -@min_cell_count else a.n_before_ever end as n_before_ever,
    case when a.n_before_30   > 0 and a.n_before_30   <= @min_cell_count then -@min_cell_count else a.n_before_30   end as n_within_30d_before,
    case when a.n_before_90   > 0 and a.n_before_90   <= @min_cell_count then -@min_cell_count else a.n_before_90   end as n_within_90d_before,
    case when a.n_before_180  > 0 and a.n_before_180  <= @min_cell_count then -@min_cell_count else a.n_before_180  end as n_within_180d_before,
    case when a.n_before_365  > 0 and a.n_before_365  <= @min_cell_count then -@min_cell_count else a.n_before_365  end as n_within_365d_before,
    case when a.n_before_730  > 0 and a.n_before_730  <= @min_cell_count then -@min_cell_count else a.n_before_730  end as n_within_730d_before,
    case when a.n_before_ever <= @min_cell_count then null else mb.median_days_before end as median_days_before,
    case when a.n_day0        > 0 and a.n_day0        <= @min_cell_count then -@min_cell_count else a.n_day0        end as n_day0,
    case when a.n_after_ever  > 0 and a.n_after_ever  <= @min_cell_count then -@min_cell_count else a.n_after_ever  end as n_after_ever,
    case when a.n_after_30    > 0 and a.n_after_30    <= @min_cell_count then -@min_cell_count else a.n_after_30    end as n_within_30d_after,
    case when a.n_after_90    > 0 and a.n_after_90    <= @min_cell_count then -@min_cell_count else a.n_after_90    end as n_within_90d_after,
    case when a.n_after_180   > 0 and a.n_after_180   <= @min_cell_count then -@min_cell_count else a.n_after_180   end as n_within_180d_after,
    case when a.n_after_365   > 0 and a.n_after_365   <= @min_cell_count then -@min_cell_count else a.n_after_365   end as n_within_365d_after,
    case when a.n_after_730   > 0 and a.n_after_730   <= @min_cell_count then -@min_cell_count else a.n_after_730   end as n_within_730d_after,
    case when a.n_after_ever  <= @min_cell_count then null else ma.median_days_after end as median_days_after
 from agg a
left join med_before mb
  on  mb.anchor_event = a.anchor_event
  and mb.event_family = a.event_family
  and mb.concept_id   = a.concept_id
left join med_after ma
  on  ma.anchor_event = a.anchor_event
  and ma.event_family = a.event_family
  and ma.concept_id   = a.concept_id
 order by  case when a.anchor_event = 'INDEX' then 0 else 1 end, a.event_family, a.n_ever desc, a.concept_id
 ;

