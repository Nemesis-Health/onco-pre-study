-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/18_f_index_event_record_counts.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 18) F. Index event record counts (part 1) <U+2014> how often the code repeats
--     Distribution of the number of records per patient, for the anchor
--     Diagnosis and the anchor Metastasis. This counts RECORDS (rows in the
--     source table), not distinct days <U+2014> a heavily repeated code shows up here.
--     (Part 2, chunk 19, measures the timescale between distinct Diagnosis days.)
--
--       DX  buckets: exactly 1 / 2 to 5 / 6 or more records per patient
--       MET buckets: exactly 1 / 2 or more records per patient
--
--     Denominators (n_patients_total, repeated on each row of the family):
--       DX  = cohort patients carrying the anchor Diagnosis (all of #dx_summary,
--             one row per cohort patient, every cohort patient has >= 1 DX record)
--       MET = cohort patients carrying an anchor Metastasis (all of #met_summary)
--     A patient falls in exactly one bucket per family.
--     Source: #dx_summary.n_dx_records, #met_summary.n_met_records (00_setup.sql).
--     Small-cell suppression: n_patients in (0, @min_cell_count] set to
--     -@min_cell_count. n_patients_total is an aggregate denominator, not suppressed.
with family_counts as (
    select 'DX'  as event_family, person_id, n_dx_records  as n_records from vcbo5u4zdx_summary
    union all
    select 'MET' as event_family, person_id, n_met_records as n_records from vcbo5u4zmet_summary
),
bucketed as (
    select
        event_family,
        person_id,
        case
            when event_family = 'DX'  and n_records = 1  then '1'
            when event_family = 'DX'  and n_records <= 5 then '2_5'
            when event_family = 'DX'                     then '6plus'
            when event_family = 'MET' and n_records = 1  then '1'
            else '2plus'
        end as record_count_bucket,
        case
            when event_family = 'DX'  and n_records = 1  then 1
            when event_family = 'DX'  and n_records <= 5 then 2
            when event_family = 'DX'                     then 3
            when event_family = 'MET' and n_records = 1  then 1
            else 2
        end as bucket_order
    from family_counts
),
totals as (
     select event_family, count(*) as n_patients_total
     from bucketed
     group by  1 )
   select b.event_family,
    b.record_count_bucket,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count else count(*) end as n_patients,
    t.n_patients_total
   from bucketed b
join totals t on t.event_family = b.event_family
  group by  b.event_family, b.record_count_bucket, t.n_patients_total
   order by  case b.event_family when 'DX' then 0 else 1 end, min(b.bucket_order)
  ;

