-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/06_odx_gdx_directional_prevalence.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 6) Directional ODX / GDX concept prevalence relative to the anchor date, at
--    fixed clinical time points, with before and after kept strictly separate and
--    day 0 as its own category. Replaces the earlier symmetric (+/-) windowed
--    output (the +/- windows conflated pre- and post-anchor coding, which have
--    different clinical meaning for exclusion-criteria design).
--
--    For each anchor / event family / concept this counts DISTINCT PATIENTS by
--    where the code sits in time relative to the anchor. Before and after are
--    never combined into a symmetric window. The event closest to the anchor on
--    each side places the patient into exactly one before band and/or one after
--    band, so within a side the bands partition that side's patients. This is the
--    disjoint-band "quick scan" companion to the cumulative CDF in chunk 06b.
--
--    Anchors (framework two-anchor convention, both surfaced):
--      INDEX     : DX index_date (full DX cohort, #cohort)
--      FIRST_MET : first_met_date (MET subgroup only; patients with a first MET)
--
--    Event families:
--      ODX : other specific cancer diagnoses (competing-cancer exclusion codes)
--      GDX : general / non-specific cancer diagnoses (broad ancestor codes)
--
--    days = DATEDIFF(DAY, anchor_date, event_date). Bands are placed on the event
--    CLOSEST to the anchor on each side (nearest-before for the before bands,
--    nearest-after for the after bands):
--      before side (days <= -1), by days-before = -days of the closest-before event:
--        n_before_gt730   : > 730 days before  (more than 2 yr)
--        n_before_366_730 : 366-730 days before (1-2 yr)
--        n_before_181_365 : 181-365 days before
--        n_before_91_180  : 91-180 days before
--        n_before_31_90   : 31-90 days before
--        n_before_1_30    : 1-30 days before
--      day 0 (its own category, never folded into before or after):
--        n_day0           : an event on the anchor day (days = 0)
--      after side (days >= 1), by days-after of the closest-after event:
--        n_after_1_30 ... n_after_gt730 : mirror of the before bands, forward
--    Side totals (each = the sum of that side's bands = any event on that side):
--        n_before_ever, n_after_ever
--    Overall:
--        n_ever : distinct patients with any event of the concept at any time.
--
--    n_ever is NOT the sum of the columns: one patient may have events before,
--    on, and after the anchor and so appear in a before band, in n_day0, and in
--    an after band. Within a single side the bands ARE a clean partition
--    (n_before_ever = sum of before bands; n_after_ever = sum of after bands).
--
--    Covers ODX and GDX. All concepts are reported; the report builder limits to
--    top N by n_ever.
--
--    Small-cell suppression: each count in (0, @min_cell_count] set to
--    -@min_cell_count.
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
    -- One row per (anchor, family, concept, person): day-0 flag, and the days
    -- offset of the closest event on each side (MAX of negatives = nearest before;
    -- MIN of positives = nearest after; NULL when that side has no event).
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
agg as (
     select anchor_event,
        event_family,
        concept_id,
        count(*)                                                       as n_ever,
        sum(case when days_before is not null       then 1 else 0 end) as n_before_ever,
        sum(case when days_before > 730             then 1 else 0 end) as n_before_gt730,
        sum(case when days_before between 366 and 730 then 1 else 0 end) as n_before_366_730,
        sum(case when days_before between 181 and 365 then 1 else 0 end) as n_before_181_365,
        sum(case when days_before between 91  and 180 then 1 else 0 end) as n_before_91_180,
        sum(case when days_before between 31  and 90  then 1 else 0 end) as n_before_31_90,
        sum(case when days_before between 1   and 30  then 1 else 0 end) as n_before_1_30,
        sum(has_day0)                                                  as n_day0,
        sum(case when days_after between 1   and 30  then 1 else 0 end) as n_after_1_30,
        sum(case when days_after between 31  and 90  then 1 else 0 end) as n_after_31_90,
        sum(case when days_after between 91  and 180 then 1 else 0 end) as n_after_91_180,
        sum(case when days_after between 181 and 365 then 1 else 0 end) as n_after_181_365,
        sum(case when days_after between 366 and 730 then 1 else 0 end) as n_after_366_730,
        sum(case when days_after > 730              then 1 else 0 end) as n_after_gt730,
        sum(case when days_after is not null        then 1 else 0 end) as n_after_ever
     from dir
     group by  1, 2, 3 )
 select a.anchor_event,
    a.event_family,
    a.concept_id,
    case when a.n_ever           > 0 and a.n_ever           <= @min_cell_count then -@min_cell_count else a.n_ever           end as n_ever,
    case when a.n_before_ever    > 0 and a.n_before_ever    <= @min_cell_count then -@min_cell_count else a.n_before_ever    end as n_before_ever,
    case when a.n_before_gt730   > 0 and a.n_before_gt730   <= @min_cell_count then -@min_cell_count else a.n_before_gt730   end as n_before_gt730,
    case when a.n_before_366_730 > 0 and a.n_before_366_730 <= @min_cell_count then -@min_cell_count else a.n_before_366_730 end as n_before_366_730,
    case when a.n_before_181_365 > 0 and a.n_before_181_365 <= @min_cell_count then -@min_cell_count else a.n_before_181_365 end as n_before_181_365,
    case when a.n_before_91_180  > 0 and a.n_before_91_180  <= @min_cell_count then -@min_cell_count else a.n_before_91_180  end as n_before_91_180,
    case when a.n_before_31_90   > 0 and a.n_before_31_90   <= @min_cell_count then -@min_cell_count else a.n_before_31_90   end as n_before_31_90,
    case when a.n_before_1_30    > 0 and a.n_before_1_30    <= @min_cell_count then -@min_cell_count else a.n_before_1_30    end as n_before_1_30,
    case when a.n_day0           > 0 and a.n_day0           <= @min_cell_count then -@min_cell_count else a.n_day0           end as n_day0,
    case when a.n_after_1_30     > 0 and a.n_after_1_30     <= @min_cell_count then -@min_cell_count else a.n_after_1_30     end as n_after_1_30,
    case when a.n_after_31_90    > 0 and a.n_after_31_90    <= @min_cell_count then -@min_cell_count else a.n_after_31_90    end as n_after_31_90,
    case when a.n_after_91_180   > 0 and a.n_after_91_180   <= @min_cell_count then -@min_cell_count else a.n_after_91_180   end as n_after_91_180,
    case when a.n_after_181_365  > 0 and a.n_after_181_365  <= @min_cell_count then -@min_cell_count else a.n_after_181_365  end as n_after_181_365,
    case when a.n_after_366_730  > 0 and a.n_after_366_730  <= @min_cell_count then -@min_cell_count else a.n_after_366_730  end as n_after_366_730,
    case when a.n_after_gt730    > 0 and a.n_after_gt730    <= @min_cell_count then -@min_cell_count else a.n_after_gt730    end as n_after_gt730,
    case when a.n_after_ever     > 0 and a.n_after_ever     <= @min_cell_count then -@min_cell_count else a.n_after_ever     end as n_after_ever
 from agg a
 order by  case when a.anchor_event = 'INDEX' then 0 else 1 end, a.event_family, a.n_ever desc, a.concept_id
 ;

