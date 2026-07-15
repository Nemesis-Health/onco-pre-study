-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/19_f_dx_intercode_timing.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 19) F. Index event record counts (part 2) <U+2014> on what timescale the code repeats
--     For patients with more than one Diagnosis code, the time between
--     consecutive Diagnosis codes, for the first two transitions only:
--       DX_1_TO_2 : first Diagnosis day  -> second Diagnosis day
--       DX_2_TO_3 : second Diagnosis day -> third  Diagnosis day
--     bucketed by timeframe: within 30 days / 31 to 90 / 91 to 365 / more than a year.
--
--     JUDGMENT CALL (flag for review): "consecutive codes" is measured between
--     DISTINCT Diagnosis DAYS, not raw records. Same-day duplicate records are
--     collapsed first (SELECT DISTINCT person_id, event_date), mirroring the L01
--     gap methodology (#l01_event_days in 00_setup.sql). Counting raw records
--     instead would make almost every first-to-second gap 0 days (same-day
--     administrative duplicates) and hide the coding timescale. Consequently
--     every gap is >= 1 day and the "within 30 days" bucket is 1-30 days.
--     Part 1 (chunk 18) counts records; this part measures timing between days.
--
--     Denominators (n_transitions_total, per transition = patients, since each
--     patient contributes at most one gap per transition):
--       DX_1_TO_2 = patients with >= 2 distinct Diagnosis days
--       DX_2_TO_3 = patients with >= 3 distinct Diagnosis days
--     Source: #dx_events restricted to #cohort (00_setup.sql).
--     Small-cell suppression: n_transitions in (0, @min_cell_count] set to
--     -@min_cell_count. n_transitions_total is an aggregate denominator, not suppressed.
with dx_days as (
    select distinct e.person_id, e.event_date as event_day
    from vcbo5u4zdx_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
),
ranked as (
    select
        person_id,
        event_day,
        row_number() over (partition by person_id order by event_day)      as day_rank,
        lead(event_day) over (partition by person_id order by event_day)   as next_day
    from dx_days
),
transitions as (
    select
        case day_rank when 1 then 'DX_1_TO_2' when 2 then 'DX_2_TO_3' end as transition,
        DATE_DIFF(IF(SAFE_CAST(next_day  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(next_day  AS STRING)),SAFE_CAST(next_day  AS DATE)), IF(SAFE_CAST(event_day  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(event_day  AS STRING)),SAFE_CAST(event_day  AS DATE)), DAY) as gap_days
    from ranked
    where day_rank in (1, 2)
      and next_day is not null
),
bucketed as (
    select
        transition,
        case
            when gap_days <= 30  then 'lte30d'
            when gap_days <= 90  then '31_90d'
            when gap_days <= 365 then '91_365d'
            else 'gt365d'
        end as gap_bucket,
        case
            when gap_days <= 30  then 1
            when gap_days <= 90  then 2
            when gap_days <= 365 then 3
            else 4
        end as bucket_order
    from transitions
),
totals as (
     select transition, count(*) as n_transitions_total
     from bucketed
     group by  1 )
   select b.transition,
    b.gap_bucket,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count else count(*) end as n_transitions,
    t.n_transitions_total
   from bucketed b
join totals t on t.transition = b.transition
  group by  b.transition, b.gap_bucket, t.n_transitions_total
   order by  b.transition, min(b.bucket_order)
  ;

