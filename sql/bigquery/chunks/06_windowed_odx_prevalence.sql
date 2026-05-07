-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-07 12:40:20 BST
-- Source file    : sql/sql_server/chunks/06_windowed_odx_prevalence.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 6) Windowed ODX (and GDX) concept prevalence relative to anchor date
--    For each anchor / event family / concept, counts distinct patients with
--    at least one event in each time window around the anchor date.
--
--    Anchors:
--      INDEX     : DX index_date (all DX cohort)
--      FIRST_MET : first_met_date (MET subgroup only)
--
--    Windows (days = event_date - anchor_date):
--      pm30d      : -30 <= days <= 30
--      pm90d      : -90 <= days <= 90
--      pm180d     : -180 <= days <= 180
--      pm1yr      : -365 <= days <= 365
--      ever_before: days < 0
--      ever_after : days >= 0
--      ever       : any time
--
--    Covers ODX and GDX families (clinically relevant exclusion criteria).
--    Restricted to top concepts by overall patient count; report builder
--    will further limit to top N.
--
--    Small-cell suppression: each count <= @min_cell_count suppressed to -@min_cell_count.
with index_events as (
    select 'INDEX' as anchor_event, 'ODX' as event_family, e.concept_id, e.person_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as days_from_anchor
    from a9of9doxother_dx_events e
    join a9of9doxcohort c on e.person_id = c.person_id
    union all
    select 'INDEX' as anchor_event, 'GDX' as event_family, e.concept_id, e.person_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as days_from_anchor
    from a9of9doxgen_cancer_events e
    join a9of9doxcohort c on e.person_id = c.person_id
),
met_events as (
    select 'FIRST_MET' as anchor_event, 'ODX' as event_family, e.concept_id, e.person_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) as days_from_anchor
    from a9of9doxother_dx_events e
    join a9of9doxcohort c on e.person_id = c.person_id
    join a9of9doxmet_summary ms on ms.person_id = c.person_id
    where ms.first_met_date is not null
    union all
    select 'FIRST_MET' as anchor_event, 'GDX' as event_family, e.concept_id, e.person_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) as days_from_anchor
    from a9of9doxgen_cancer_events e
    join a9of9doxcohort c on e.person_id = c.person_id
    join a9of9doxmet_summary ms on ms.person_id = c.person_id
    where ms.first_met_date is not null
),
all_events as (
    select * from index_events
    union all
    select * from met_events
),
windowed as (
     select anchor_event,
        event_family,
        concept_id,
        person_id,
        max(case when days_from_anchor >= -30  and days_from_anchor <= 30  then 1 else 0 end) as in_pm30d,
        max(case when days_from_anchor >= -90  and days_from_anchor <= 90  then 1 else 0 end) as in_pm90d,
        max(case when days_from_anchor >= -180 and days_from_anchor <= 180 then 1 else 0 end) as in_pm180d,
        max(case when days_from_anchor >= -365 and days_from_anchor <= 365 then 1 else 0 end) as in_pm1yr,
        max(case when days_from_anchor < 0                                 then 1 else 0 end) as in_ever_before,
        max(case when days_from_anchor >= 0                                then 1 else 0 end) as in_ever_after,
        1 as in_ever
     from all_events
     group by  1, 2, 3, 4 ),
agg as (
     select anchor_event,
        event_family,
        concept_id,
        count(*)            as n_ever,
        sum(in_pm30d)       as n_pm30d,
        sum(in_pm90d)       as n_pm90d,
        sum(in_pm180d)      as n_pm180d,
        sum(in_pm1yr)       as n_pm1yr,
        sum(in_ever_before) as n_ever_before,
        sum(in_ever_after)  as n_ever_after
     from windowed
     group by  1, 2, 3 )
 select a.anchor_event,
    a.event_family,
    a.concept_id,
    case when a.n_ever        > 0 and a.n_ever        <= @min_cell_count then -@min_cell_count else a.n_ever        end as n_ever,
    case when a.n_pm30d       > 0 and a.n_pm30d       <= @min_cell_count then -@min_cell_count else a.n_pm30d       end as n_pm30d,
    case when a.n_pm90d       > 0 and a.n_pm90d       <= @min_cell_count then -@min_cell_count else a.n_pm90d       end as n_pm90d,
    case when a.n_pm180d      > 0 and a.n_pm180d      <= @min_cell_count then -@min_cell_count else a.n_pm180d      end as n_pm180d,
    case when a.n_pm1yr       > 0 and a.n_pm1yr       <= @min_cell_count then -@min_cell_count else a.n_pm1yr       end as n_pm1yr,
    case when a.n_ever_before > 0 and a.n_ever_before <= @min_cell_count then -@min_cell_count else a.n_ever_before end as n_ever_before,
    case when a.n_ever_after  > 0 and a.n_ever_after  <= @min_cell_count then -@min_cell_count else a.n_ever_after  end as n_ever_after
 from agg a
 order by  case when a.anchor_event = 'INDEX' then 0 else 1 end, a.event_family, a.n_ever desc, a.concept_id
 ;

