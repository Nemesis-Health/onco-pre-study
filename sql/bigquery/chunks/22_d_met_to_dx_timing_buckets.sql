-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/22_d_met_to_dx_timing_buckets.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 22) D. MET-first subgroup, part 3a. Time from the first Metastasis to the first
--     specific Diagnosis, bucketed, for the MET-first patients.
--     For the MET_FIRST_THEN_DX group of chunk 20, the gap in days from the first
--     MET to the first specific DX, placed in one bucket:
--
--       LTE30D    1 to 30 days      D91_180   91 to 180 days
--       D31_60    31 to 60 days     D181_365  181 to 365 days
--       D61_90    61 to 90 days     GT365D    366 days or more
--
--     All of this time is AFTER the first MET by construction (MET-first subgroup),
--     so the gap is >= 1 day and the first bucket contains 1-30 days. Day 0 cannot
--     occur: those patients are the SAME_DAY category of chunk 20, excluded here.
--
--     Denominator (n_patients_reaching_dx_total, repeated on each row):
--       MET-first patients who reach a specific DX = the MET_FIRST_THEN_DX group of
--       chunk 20 (the two SPECIFIC_DX_* buckets of chunk 21). Under the corrected
--       DX-anchored population every MET-first patient reaches a specific DX, so this
--       denominator equals the full MET-first subgroup.
--
--     Population and observation-period notes: same as chunk 20 (DX-anchored MET
--     population from #met_events, first specific DX from #dx_events, anchored on
--     #anchor_person, no observation-period gate).
--
--     Small-cell suppression: n_patients in (0, @min_cell_count] set to
--     -@min_cell_count. n_patients_reaching_dx_total is an aggregate denominator,
--     not suppressed. A bucket with zero patients is absent (as in chunks 18-19).
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
    -- MET-first-then-DX only: first MET strictly before the first specific DX.
    select
        ma.person_id,
        DATE_DIFF(IF(SAFE_CAST(dx.first_dx_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dx.first_dx_date  AS STRING)),SAFE_CAST(dx.first_dx_date  AS DATE)), IF(SAFE_CAST(ma.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ma.first_met_date  AS STRING)),SAFE_CAST(ma.first_met_date  AS DATE)), DAY) as gap_days
    from met_all ma
    join dx_all dx
      on dx.person_id = ma.person_id
    where ma.first_met_date < dx.first_dx_date
),
bucketed as (
    select
        person_id,
        case
            when gap_days <= 30  then 'LTE30D'
            when gap_days <= 60  then 'D31_60'
            when gap_days <= 90  then 'D61_90'
            when gap_days <= 180 then 'D91_180'
            when gap_days <= 365 then 'D181_365'
            else                      'GT365D'
        end as timing_bucket,
        case
            when gap_days <= 30  then 1
            when gap_days <= 60  then 2
            when gap_days <= 90  then 3
            when gap_days <= 180 then 4
            when gap_days <= 365 then 5
            else                      6
        end as bucket_order
    from gap
),
totals as (
    select count(*) as n_patients_reaching_dx_total from bucketed
)
   select b.timing_bucket,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count
         else count(*) end as n_patients,
    t.n_patients_reaching_dx_total
   from bucketed b
cross join totals t
  group by  b.timing_bucket, t.n_patients_reaching_dx_total
   order by  min(b.bucket_order)
  ;

