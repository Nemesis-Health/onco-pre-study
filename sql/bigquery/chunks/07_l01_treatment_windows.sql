-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-05-07 12:03:59 BST
-- Source file    : sql/sql_server/chunks/07_l01_treatment_windows.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 7) L01 treatment exposure in 30-day windows around anchor dates
--    For each 30-day window k (window_start = anchor + 30*k days,
--    window_end = anchor + 30*(k+1) - 1 days), counts the number of
--    distinct patients with at least one L01 drug_exposure_start_date in
--    that window, as a fraction of the eligible denominator.
--
--    Two anchors:
--      INDEX    : all DX cohort patients; windows -12 to +48 (3 yr post-DX)
--      FIRST_MET: all patients with first_met_date; windows -6 to +24 (2 yr post-MET)
--
--    The denominator for each window is the number of patients whose
--    observation period covers the window midpoint (anchor + 30*k + 15 days).
--    This avoids deflating late windows due to censoring.
--    If observation_period data is unavailable, denominator = all anchor patients
--    (conservative; may underestimate late-window rates).
--
--    Output: one row per (anchor_event, window_index).
--    window_index: integer; window covers [anchor + 30*k, anchor + 30*(k+1) - 1].
--    Small-cell suppression on n_patients_with_l01.
with window_bounds as (
    -- All (anchor, patient, window_index) combinations in scope
    select
        'INDEX' as anchor_event,
        c.person_id,
        c.index_date as anchor_date,
        w.window_index
    from quyq3b3ecohort c
    cross join (
        select -12 as window_index union all select -11 union all select -10
        union all select -9  union all select -8  union all select -7
        union all select -6  union all select -5  union all select -4
        union all select -3  union all select -2  union all select -1
        union all select  0  union all select  1  union all select  2
        union all select  3  union all select  4  union all select  5
        union all select  6  union all select  7  union all select  8
        union all select  9  union all select 10  union all select 11
        union all select 12  union all select 13  union all select 14
        union all select 15  union all select 16  union all select 17
        union all select 18  union all select 19  union all select 20
        union all select 21  union all select 22  union all select 23
        union all select 24  union all select 25  union all select 26
        union all select 27  union all select 28  union all select 29
        union all select 30  union all select 31  union all select 32
        union all select 33  union all select 34  union all select 35
        union all select 36  union all select 37  union all select 38
        union all select 39  union all select 40  union all select 41
        union all select 42  union all select 43  union all select 44
        union all select 45  union all select 46  union all select 47
    ) w
    union all
    select
        'FIRST_MET' as anchor_event,
        ms.person_id,
        ms.first_met_date as anchor_date,
        w.window_index
    from quyq3b3emet_summary ms
    cross join (
        select -6  as window_index union all select -5  union all select -4
        union all select -3  union all select -2  union all select -1
        union all select  0  union all select  1  union all select  2
        union all select  3  union all select  4  union all select  5
        union all select  6  union all select  7  union all select  8
        union all select  9  union all select 10  union all select 11
        union all select 12  union all select 13  union all select 14
        union all select 15  union all select 16  union all select 17
        union all select 18  union all select 19  union all select 20
        union all select 21  union all select 22  union all select 23
    ) w
    where ms.first_met_date is not null
),
-- Mark which patients have at least one L01 exposure in each window
window_l01 as (
     select wb.anchor_event,
        wb.person_id,
        wb.window_index,
        wb.anchor_date,
        max(
            case
                when le.event_date >= DATE_ADD(IF(SAFE_CAST(wb.anchor_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(wb.anchor_date  AS STRING)),SAFE_CAST(wb.anchor_date  AS DATE)), INTERVAL 30 * wb.window_index DAY)
                 and le.event_date <  DATE_ADD(IF(SAFE_CAST(wb.anchor_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(wb.anchor_date  AS STRING)),SAFE_CAST(wb.anchor_date  AS DATE)), INTERVAL 30 * (wb.window_index + 1) DAY)
                then 1 else 0
            end
        ) as has_l01_in_window
     from window_bounds wb
    left join quyq3b3el01_events le
      on wb.person_id = le.person_id
     group by  wb.anchor_event, wb.person_id, wb.window_index, wb.anchor_date
 ),
-- Denominator: patients observed through the window midpoint
-- (anchor + 30*k + 15 days must be within at least one observation period)
window_denom as (
     select wb.anchor_event,
        wb.person_id,
        wb.window_index,
        wb.anchor_date,
        max(
            case
                when op.observation_period_start_date <= DATE_ADD(IF(SAFE_CAST(wb.anchor_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(wb.anchor_date  AS STRING)),SAFE_CAST(wb.anchor_date  AS DATE)), INTERVAL 30 * wb.window_index + 15 DAY)
                 and op.observation_period_end_date   >= DATE_ADD(IF(SAFE_CAST(wb.anchor_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(wb.anchor_date  AS STRING)),SAFE_CAST(wb.anchor_date  AS DATE)), INTERVAL 30 * wb.window_index + 15 DAY)
                then 1 else 0
            end
        ) as observed_at_midpoint
     from window_bounds wb
    left join @cdm_database_schema.observation_period op
      on op.person_id = wb.person_id
     group by  wb.anchor_event, wb.person_id, wb.window_index, wb.anchor_date
 ),
agg as (
     select wl.anchor_event,
        wl.window_index,
        count(*)                    as n_eligible,
        sum(wd.observed_at_midpoint) as n_observed,
        sum(wl.has_l01_in_window)   as n_patients_with_l01
     from window_l01 wl
    join window_denom wd
      on wd.anchor_event = wl.anchor_event
     and wd.person_id    = wl.person_id
     and wd.window_index = wl.window_index
     group by  wl.anchor_event, wl.window_index
 )
 select a.anchor_event,
    a.window_index,
    a.n_eligible,
    case when a.n_observed          <= @min_cell_count then -@min_cell_count else a.n_observed          end as n_observed,
    case when a.n_patients_with_l01 <= @min_cell_count then -@min_cell_count else a.n_patients_with_l01 end as n_patients_with_l01
 from agg a
 order by  a.anchor_event, a.window_index
 ;

