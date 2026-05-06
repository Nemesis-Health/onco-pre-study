-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-06 18:36:52 BST
-- Source file    : sql/sql_server/chunks/06_windowed_odx_prevalence.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 6) Windowed ODX (and GDX) concept prevalence relative to DX index date
--    For each event family / concept, counts the number of distinct patients
--    with at least one event in each time window around index_date.
--
--    Windows (days = event_date - index_date):
--      pm30d      : -30 <= days <= 30
--      pm90d      : -90 <= days <= 90
--      pm180d     : -180 <= days <= 180
--      pm1yr      : -365 <= days <= 365
--      ever_before: days < 0
--      ever_after : days >= 0
--      ever       : any time (same as time_window='all' in chunk 02)
--
--    Only returns rows from the INDEX anchor (DX index date).
--    Covers ODX and GDX families (the clinically relevant exclusion criteria).
--    Restricted to top concepts by overall patient count to keep output size
--    manageable; the report builder will further limit to top N.
--
--    Small-cell suppression: counts <= @min_cell_count suppressed to -@min_cell_count.
with odx_gdx_events as (
    -- ODX events with days relative to index_date
    select
        'ODX' as event_family,
        e.concept_id,
        e.person_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as days_from_index
    from ldpw47q6other_dx_events e
    join ldpw47q6cohort c on e.person_id = c.person_id
    union all
    -- GDX events with days relative to index_date
    select
        'GDX' as event_family,
        e.concept_id,
        e.person_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as days_from_index
    from ldpw47q6gen_cancer_events e
    join ldpw47q6cohort c on e.person_id = c.person_id
),
windowed as (
     select event_family,
        concept_id,
        person_id,
        max(case when days_from_index >= -30  and days_from_index <= 30  then 1 else 0 end) as in_pm30d,
        max(case when days_from_index >= -90  and days_from_index <= 90  then 1 else 0 end) as in_pm90d,
        max(case when days_from_index >= -180 and days_from_index <= 180 then 1 else 0 end) as in_pm180d,
        max(case when days_from_index >= -365 and days_from_index <= 365 then 1 else 0 end) as in_pm1yr,
        max(case when days_from_index < 0                                then 1 else 0 end) as in_ever_before,
        max(case when days_from_index >= 0                               then 1 else 0 end) as in_ever_after,
        1 as in_ever
     from odx_gdx_events
     group by  1, 2, 3 ),
agg as (
     select event_family,
        concept_id,
        count(*)                        as n_ever,
        sum(in_pm30d)                   as n_pm30d,
        sum(in_pm90d)                   as n_pm90d,
        sum(in_pm180d)                  as n_pm180d,
        sum(in_pm1yr)                   as n_pm1yr,
        sum(in_ever_before)             as n_ever_before,
        sum(in_ever_after)              as n_ever_after
     from windowed
     group by  1, 2 )
 select a.event_family,
    a.concept_id,
    case when a.n_ever          <= @min_cell_count then -@min_cell_count else a.n_ever          end as n_ever,
    case when a.n_ever          <= @min_cell_count then null             else a.n_pm30d         end as n_pm30d,
    case when a.n_ever          <= @min_cell_count then null             else a.n_pm90d         end as n_pm90d,
    case when a.n_ever          <= @min_cell_count then null             else a.n_pm180d        end as n_pm180d,
    case when a.n_ever          <= @min_cell_count then null             else a.n_pm1yr         end as n_pm1yr,
    case when a.n_ever          <= @min_cell_count then null             else a.n_ever_before   end as n_ever_before,
    case when a.n_ever          <= @min_cell_count then null             else a.n_ever_after    end as n_ever_after
 from agg a
 order by  a.event_family, a.n_ever desc, a.concept_id
 ;

