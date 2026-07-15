-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/24_h_closest_treatment_placement.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 24) H. Metastasis-to-treatment timing, part 1. Where each patient's CLOSEST
--     antineoplastic treatment falls relative to the first Metastasis.
--     Each patient who carries an anchor Metastasis (MET) code (and therefore also
--     an anchor DX code) is placed in exactly one category by the side of the first
--     MET on which their single CLOSEST antineoplastic (L01) drug_exposure record
--     falls. "Closest" = the L01 record with the minimum absolute days-difference to
--     the first MET, signed:
--
--       CLOSEST_L01_BEFORE_MET   closest L01 record is before the first MET   (days_diff < 0)
--       CLOSEST_L01_ON_MET_DAY   closest L01 record is on the first MET date  (days_diff = 0, day 0)
--       CLOSEST_L01_AFTER_MET    closest L01 record is after the first MET    (days_diff > 0)
--       NO_L01_EVER              no antineoplastic drug_exposure record at all
--
--     days_diff = DATEDIFF(DAY, first_met_date, l01_event_date): negative = before,
--     0 = same calendar day as the first MET (day 0, its own explicit category,
--     never folded into "after"), positive = after. One value per patient. Ties in
--     absolute distance are broken by earlier event_date, the framework's CLOSEST
--     convention (ROW_NUMBER ... ORDER BY ABS(days_diff), event_date), so an
--     equidistant tie resolves to the before record.
--
--     Denominator (n_patients_met_total, repeated on each row):
--       all patients with >= 1 anchor MET measurement code AND >= 1 anchor DX code
--       at this site (before + day0 + after + never = this total).
--
--     POPULATION. Built from #met_events (00_setup.sql, section F):
--     @cdm_database_schema.measurement JOIN #met_concepts JOIN #anchor_person, so
--     every patient carries an anchor DX code. The cohort is DX-anchored; a MET code
--     is observed WITHIN that cohort, never as a separate entry point. There is no
--     "MET-only, no DX" patient: the MET concept set is generic across cancer types,
--     so a MET code without an anchor DX gives no evidence of the cancer of interest.
--     #anchor_person carries no observation-period-at-index gate (that is #cohort);
--     see the observation-period flag below. Identical DX-anchored population to
--     Analysis D (chunks 20-23).
--
--     L01 SOURCE. Antineoplastic records come from #l01_events (00_setup.sql,
--     section F): @cdm_database_schema.drug_exposure JOIN #l01_concepts JOIN
--     #anchor_person. #l01_events is gated to the same DX anchor cohort as the MET
--     population, so every MET patient's L01 records are present and none are missed.
--
--     JUDGMENT CALL / FLAG (observation period). Neither the MET population nor the
--     L01 records are restricted to an observation period. The population is anchored
--     on "has an anchor DX code" (#anchor_person), not "inside an observation period"
--     (#cohort). Observation-period coverage is characterized separately in Analysis
--     E (chunks 16-17). See the accompanying report for the reasoned recommendation.
--
--     Small-cell suppression: n_patients in (0, @min_cell_count] set to
--     -@min_cell_count. n_patients_met_total is an aggregate denominator, not
--     suppressed. A category with zero patients is absent (as in chunks 18-23).
with met_all as (
    -- DX-anchored MET population: earliest MET date per patient (#met_events is
    -- gated to #anchor_person and carries no observation-period gate).
     select person_id,
        min(event_date) as first_met_date
     from vcbo5u4zmet_events
     group by  1 ),
l01_all as (
    -- Antineoplastic drug_exposure records for the DX anchor cohort (#l01_events is
    -- gated to #anchor_person, the same cohort as the MET population).
    select
        person_id,
        event_date
    from vcbo5u4zl01_events
),
pair as (
    -- Signed L01-to-first-MET distance for every L01 record of a MET patient.
    select
        ma.person_id,
        DATE_DIFF(IF(SAFE_CAST(la.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(la.event_date  AS STRING)),SAFE_CAST(la.event_date  AS DATE)), IF(SAFE_CAST(ma.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ma.first_met_date  AS STRING)),SAFE_CAST(ma.first_met_date  AS DATE)), DAY) as days_diff,
        la.event_date
    from met_all ma
    join l01_all la
      on la.person_id = ma.person_id
),
closest as (
    -- Single closest L01 record per patient (framework CLOSEST convention).
    select
        person_id,
        days_diff,
        row_number() over (
            partition by person_id
            order by abs(days_diff), event_date
        ) as rn
    from pair
),
classified as (
    select
        ma.person_id,
        case
            when c.days_diff is null then 'NO_L01_EVER'
            when c.days_diff < 0     then 'CLOSEST_L01_BEFORE_MET'
            when c.days_diff = 0     then 'CLOSEST_L01_ON_MET_DAY'
            else                          'CLOSEST_L01_AFTER_MET'
        end as placement_category
    from met_all ma
    left join (select person_id, days_diff from closest where rn = 1) c
      on c.person_id = ma.person_id
),
totals as (
    select count(*) as n_patients_met_total from met_all
)
   select c.placement_category,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count
         else count(*) end as n_patients,
    t.n_patients_met_total
   from classified c
cross join totals t
  group by  c.placement_category, t.n_patients_met_total
   order by  case c.placement_category
        when 'CLOSEST_L01_BEFORE_MET' then 0
        when 'CLOSEST_L01_ON_MET_DAY' then 1
        when 'CLOSEST_L01_AFTER_MET'  then 2
        when 'NO_L01_EVER'            then 3
        else 9
    end
  ;

