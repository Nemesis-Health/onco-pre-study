-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/20_d_met_first_ordering.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 20) D. MET-first subgroup, part 1. Ordering of the first Metastasis and the
--     first specific Diagnosis, among patients who carry a Metastasis code within
--     the DX-anchored cohort.
--     Every patient in this framework carries an anchor Diagnosis (DX) code by
--     construction. The cohort is DX-anchored: a Diagnosis code from the anchor
--     concept set is the entry point, and Metastasis is observed WITHIN that cohort,
--     never as a separate way to enter it. Each patient who carries an anchor
--     Metastasis (MET) measurement code (and therefore also an anchor DX code) is
--     placed in exactly one category by which of two events is recorded first: the
--     first MET and the first specific (anchor) DX. Same-day is its own category,
--     never folded into either side.
--
--       DX_FIRST            first specific DX date < first MET date
--       SAME_DAY            first specific DX date = first MET date
--       MET_FIRST_THEN_DX   first MET date < first specific DX date
--                           (the MET code predates the existing DX code; the DX code
--                            always exists, it simply arrives later)
--
--     There is NO "Metastasis-only, never Diagnosis" category. A patient with a
--     generic Metastasis code but no anchor DX code is not in this cohort at all.
--     The MET concept set (AJCC/UICC stage 4, M1, Metastasis) is generic across
--     cancer types, so a MET code without an anchor DX gives no evidence the patient
--     has the cancer of interest. Only MET_FIRST_THEN_DX (is_met_first_subgroup = 1)
--     is carried into parts 2 and 3.
--
--     Denominator (n_patients_met_total, repeated on each row):
--       all patients with >= 1 anchor MET measurement code AND >= 1 anchor DX code
--       at this site (the three categories sum to this total).
--
--     POPULATION. Built from #met_events (00_setup.sql, section F), which is
--     @cdm_database_schema.measurement JOIN #met_concepts JOIN #anchor_person, so
--     every person already carries an anchor DX code. #anchor_person is the
--     DX-anchored cohort WITHOUT the observation-period-at-index gate that #cohort
--     adds, so this count sits at or above Analysis F's #met_summary count (DX plus
--     observation period at the index DX) and at or below a count of all MET carriers
--     regardless of DX. The first specific DX per patient comes from #dx_events (all
--     anchor-DX events, no observation-period gate), consistent with anchoring on
--     #anchor_person. Because every #met_events person is in #anchor_person and hence
--     in #dx_events, the DX join below matches every patient (no null-DX branch).
--
--     JUDGMENT CALL / FLAG (observation period). The population is anchored on
--     "has an anchor DX code" (#anchor_person), NOT on "has an anchor DX code inside
--     an observation period" (#cohort). Observation-period coverage is a separate,
--     still-open decision, characterized on its own in Analysis E (chunks 16-17); it
--     is deliberately not imposed here. See the accompanying report for the reasoned
--     recommendation.
--
--     JUDGMENT CALL / FLAG (same-day). SAME_DAY = the first specific DX and the
--     first MET fall on the identical calendar date; neither precedes the other.
--
--     Small-cell suppression: n_patients in (0, @min_cell_count] set to
--     -@min_cell_count. n_patients_met_total is an aggregate denominator, not
--     suppressed. A category with zero patients is absent (as in chunks 18-19).
with met_all as (
    -- DX-anchored MET population: earliest MET date per patient. #met_events is
    -- already restricted to patients who carry an anchor DX code (#anchor_person)
    -- and carries no observation-period gate.
     select person_id,
        min(event_date) as first_met_date
     from vcbo5u4zmet_events
     group by  1 ),
dx_all as (
    -- First specific (anchor) DX per patient, over all anchor-DX events (no
    -- observation-period gate). Every met_all patient appears here by construction.
     select person_id,
        min(event_date) as first_dx_date
     from vcbo5u4zdx_events
     group by  1 ),
classified as (
    select
        ma.person_id,
        case
            when dx.first_dx_date < ma.first_met_date then 'DX_FIRST'
            when dx.first_dx_date = ma.first_met_date then 'SAME_DAY'
            else                                           'MET_FIRST_THEN_DX'
        end as ordering_category
    from met_all ma
    join dx_all dx
      on dx.person_id = ma.person_id
),
totals as (
    select count(*) as n_patients_met_total from classified
)
   select c.ordering_category,
    case when c.ordering_category = 'MET_FIRST_THEN_DX'
         then 1 else 0 end as is_met_first_subgroup,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count
         else count(*) end as n_patients,
    t.n_patients_met_total
   from classified c
cross join totals t
  group by  c.ordering_category, t.n_patients_met_total
   order by  case c.ordering_category
        when 'DX_FIRST'          then 0
        when 'SAME_DAY'          then 1
        when 'MET_FIRST_THEN_DX' then 2
        else 9
    end
  ;

