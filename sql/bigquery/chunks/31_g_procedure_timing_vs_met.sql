-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/31_g_procedure_timing_vs_met.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 31) G. Drug Therapy procedure characterization (Part 2) <U+2014> timing of the first
--     Drug Therapy procedure relative to the first Metastasis, directional.
--     For patients who carry BOTH an anchor Metastasis (MET) code and a Drug
--     Therapy procedure (DTP), the gap in days from the first MET to the first DTP
--     is placed in exactly one directional bucket. Before and after the MET are
--     kept separate; day 0 is its own explicit category, never folded into after:
--
--       DTP_GT90D_BEFORE_MET     first DTP more than 90 days before the first MET
--       DTP_1_90D_BEFORE_MET     first DTP 1 to 90 days before the first MET
--       DTP_ON_MET_DAY           first DTP on the first MET date (day 0)
--       DTP_1_90D_AFTER_MET      first DTP 1 to 90 days after the first MET
--       DTP_91_365D_AFTER_MET    first DTP 91 to 365 days after the first MET
--       DTP_GT365D_AFTER_MET     first DTP more than 365 days after the first MET
--
--     gap_days = DATEDIFF(DAY, first_met_date, first_dtp_date): negative = before,
--     0 = day 0, positive = after. One value per patient (first MET vs first DTP).
--
--     Denominator (n_patients_both_total, repeated on each row):
--       patients who carry both an anchor MET code and at least one Drug Therapy
--       procedure, over the DX-anchored MET population. "Patients with both events"
--       within the DX-anchored cohort.
--
--     Population and observation-period notes: same as chunk 29 (DX-anchored MET
--     population from #met_events; Drug Therapy procedures from procedure_occurrence +
--     #dtp_concepts, restricted to the same cohort by the inner join to met_all; no
--     observation-period gate). The DTP here is any Drug Therapy procedure regardless
--     of concept root; the per-concept view is in chunks 30 and 32.
--
--     Small-cell suppression: n_patients in (0, @min_cell_count] set to
--     -@min_cell_count. n_patients_both_total is an aggregate denominator, not
--     suppressed. A bucket with zero patients is absent (as in chunks 22, 24).
with met_all as (
     select person_id,
        min(event_date) as first_met_date
     from vcbo5u4zmet_events
     group by  1 ),
dtp_all as (
    -- Earliest Drug Therapy procedure date per patient (any concept root). The inner
    -- join to the DX-anchored met_all below restricts this to the same cohort, so no
    -- separate DX gate is needed here.
     select po.person_id,
        min(po.procedure_date) as first_dtp_date
     from @cdm_database_schema.procedure_occurrence po
    join vcbo5u4zdtp_concepts dtp
      on po.procedure_concept_id = dtp.concept_id
     group by  po.person_id
 ),
gap as (
    -- Patients with BOTH events; signed gap from first MET to first DTP.
    select
        ma.person_id,
        DATE_DIFF(IF(SAFE_CAST(da.first_dtp_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(da.first_dtp_date  AS STRING)),SAFE_CAST(da.first_dtp_date  AS DATE)), IF(SAFE_CAST(ma.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ma.first_met_date  AS STRING)),SAFE_CAST(ma.first_met_date  AS DATE)), DAY) as gap_days
    from met_all ma
    join dtp_all da
      on da.person_id = ma.person_id
),
bucketed as (
    select
        person_id,
        case
            when gap_days < -90                  then 'DTP_GT90D_BEFORE_MET'
            when gap_days < 0                    then 'DTP_1_90D_BEFORE_MET'
            when gap_days = 0                    then 'DTP_ON_MET_DAY'
            when gap_days <= 90                  then 'DTP_1_90D_AFTER_MET'
            when gap_days <= 365                 then 'DTP_91_365D_AFTER_MET'
            else                                      'DTP_GT365D_AFTER_MET'
        end as timing_bucket,
        case
            when gap_days < -90                  then 1
            when gap_days < 0                    then 2
            when gap_days = 0                    then 3
            when gap_days <= 90                  then 4
            when gap_days <= 365                 then 5
            else                                      6
        end as bucket_order
    from gap
),
totals as (
    select count(*) as n_patients_both_total from bucketed
)
   select b.timing_bucket,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count
         else count(*) end as n_patients,
    t.n_patients_both_total
   from bucketed b
cross join totals t
  group by  b.timing_bucket, t.n_patients_both_total
   order by  min(b.bucket_order)
  ;

