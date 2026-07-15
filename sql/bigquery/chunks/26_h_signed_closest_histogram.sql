-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/26_h_signed_closest_histogram.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 26) H. Metastasis-to-treatment timing (Part 2, histogram) <U+2014> the signed
--     distribution of each treated patient's CLOSEST antineoplastic treatment
--     relative to the first Metastasis.
--     Over the treated MET patients (>= 1 L01 record), each patient is reduced to
--     the single signed days_diff of their CLOSEST L01 record (same value and
--     convention as chunk 24) and placed in one signed-day bin. Before and after
--     are separate; day 0 is its own central bin. bin_order runs left to right
--     along the signed axis (farthest before -> day 0 -> farthest after) so the
--     report renders the bars directly.
--
--       bin_order  side    day_range_label   contents (signed days_diff)
--          1       BEFORE   366+              days_diff <= -366
--          2       BEFORE   181-365           -365 .. -181
--          3       BEFORE   91-180            -180 .. -91
--          4       BEFORE   61-90             -90 .. -61
--          5       BEFORE   31-60             -60 .. -31
--          6       BEFORE   1-30              -30 .. -1
--          7       DAY0     Day 0             days_diff = 0
--          8       AFTER    1-30              1 .. 30
--          9       AFTER    31-60             31 .. 60
--         10       AFTER    61-90             61 .. 90
--         11       AFTER    91-180            91 .. 180
--         12       AFTER    181-365           181 .. 365
--         13       AFTER    366+              days_diff >= 366
--
--     The 366+ terminal bins carry everything beyond one year on each side. The bin
--     share (n_patients / n_treated_total) is what the report plots.
--
--     NOTE (relationship to the after-curve, chunk 28). This histogram is entirely
--     CLOSEST-based: the after bins (order 8-13) sum to the closest-after patients
--     (chunk 25 n_closest_after), NOT to the after-curve population (n_after_any).
--     The after-curve is intentionally over a broader population and is therefore
--     NOT the cumulative of these after bars. The before bins (order 1-6) sum to the
--     closest-before patients and DO agree with the before-curve (chunk 27).
--
--     Denominator (n_treated_total, repeated on each row):
--       treated MET patients = before + day0 + after (= chunk 24 sum of the three
--       treated categories; = chunk 25 n_treated).
--
--     Population, observation-period and L01-source notes: same as chunk 24
--     (DX-anchored MET population from #met_events; L01 from #l01_events, gated to the
--     same #anchor_person cohort; no observation-period gate). No change to 00_setup.sql.
--
--     Small-cell suppression: n_patients in (0, @min_cell_count] set to
--     -@min_cell_count. n_treated_total is an aggregate denominator, not
--     suppressed. A bin with zero patients is absent (as in chunks 18-25).
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
c1 as (
    select person_id, days_diff from closest where rn = 1
),
binned as (
    select
        person_id,
        case
            when days_diff = 0                          then 7
            when days_diff <= -366                       then 1
            when days_diff <= -181                       then 2
            when days_diff <= -91                        then 3
            when days_diff <= -61                        then 4
            when days_diff <= -31                        then 5
            when days_diff <= -1                         then 6
            when days_diff <= 30                         then 8
            when days_diff <= 60                         then 9
            when days_diff <= 90                         then 10
            when days_diff <= 180                        then 11
            when days_diff <= 365                        then 12
            else                                             13
        end as bin_order
    from c1
),
labelled as (
    select
        person_id,
        bin_order,
        case when bin_order <= 6 then 'BEFORE'
             when bin_order = 7  then 'DAY0'
             else                     'AFTER' end as side,
        case bin_order
            when 1  then '366+'
            when 2  then '181-365'
            when 3  then '91-180'
            when 4  then '61-90'
            when 5  then '31-60'
            when 6  then '1-30'
            when 7  then 'Day 0'
            when 8  then '1-30'
            when 9  then '31-60'
            when 10 then '61-90'
            when 11 then '91-180'
            when 12 then '181-365'
            else         '366+'
        end as day_range_label
    from binned
),
totals as (
    select count(*) as n_treated_total from c1
)
   select b.bin_order,
    b.side,
    b.day_range_label,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count
         else count(*) end as n_patients,
    t.n_treated_total
   from labelled b
cross join totals t
  group by  b.bin_order, b.side, b.day_range_label, t.n_treated_total
   order by  b.bin_order
  ;

