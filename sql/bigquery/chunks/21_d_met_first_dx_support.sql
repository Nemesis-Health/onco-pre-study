-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/21_d_met_first_dx_support.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 21) D. MET-first subgroup, part 2. Whether, and how well supported, the specific
--     Diagnosis anchor is within the MET-first subgroup.
--     For the MET-first patients (first MET strictly before the first specific DX,
--     the MET_FIRST_THEN_DX group of chunk 20), a phenotype would still have to
--     anchor on their specific Diagnosis once it arrives. This part places each such
--     patient in exactly one bucket by how their specific-Diagnosis coding is
--     supported:
--
--       SPECIFIC_DX_SINGLE_DAY   specific DX on exactly one distinct day (unconfirmed anchor)
--       SPECIFIC_DX_2PLUS_DAYS   specific DX on 2 or more distinct days (repeated anchor)
--
--     There is NO "no specific DX ever" bucket. Under the corrected DX-anchored
--     population every patient carries an anchor DX code by construction (see chunk
--     20), so the reliability question here is single (unconfirmed) versus repeated
--     anchor, not present versus absent. The two buckets together are the
--     MET_FIRST_THEN_DX group of chunk 20.
--
--     Denominator (n_patients_subgroup_total, repeated on each row):
--       the MET-first subgroup = patients with a MET code whose first MET precedes
--       their first specific DX (the shaded row of chunk 20).
--
--     JUDGMENT CALL / FLAG (records vs distinct days). The reliability question is a
--     rule-of-two (two codes on two separate encounters), so this chunk measures
--     DISTINCT specific-DX DAYS, not raw records: two same-day administrative
--     duplicates should not count as a confirmed repeated anchor. This matches the
--     distinct-day treatment in chunk 19. To count raw records instead, change
--     COUNT(DISTINCT event_date) to COUNT(*) in dx_all; that would move some
--     same-day-duplicate patients from SPECIFIC_DX_SINGLE_DAY into
--     SPECIFIC_DX_2PLUS_DAYS.
--
--     Population and observation-period notes: same as chunk 20 (DX-anchored MET
--     population from #met_events, first specific DX from #dx_events, anchored on
--     #anchor_person, no observation-period gate).
--
--     Small-cell suppression: n_patients in (0, @min_cell_count] set to
--     -@min_cell_count. n_patients_subgroup_total is an aggregate denominator,
--     not suppressed. A bucket with zero patients is absent (as in chunks 18-19).
with met_all as (
     select person_id,
        min(event_date) as first_met_date
     from vcbo5u4zmet_events
     group by  1 ),
dx_all as (
     select person_id,
        min(event_date)            as first_dx_date,
        count(distinct event_date) as n_dx_days
     from vcbo5u4zdx_events
     group by  1 ),
subgroup as (
    -- MET-first subgroup: the first MET strictly precedes the first specific DX.
    -- Every patient has a specific DX (DX-anchored cohort), so the only remaining
    -- distinction is how well supported that DX anchor is.
    select
        ma.person_id,
        dx.n_dx_days
    from met_all ma
    join dx_all dx
      on dx.person_id = ma.person_id
    where ma.first_met_date < dx.first_dx_date
),
bucketed as (
    select
        person_id,
        case
            when n_dx_days = 1 then 'SPECIFIC_DX_SINGLE_DAY'
            else                    'SPECIFIC_DX_2PLUS_DAYS'
        end as dx_support_bucket
    from subgroup
),
totals as (
    select count(*) as n_patients_subgroup_total from bucketed
)
   select b.dx_support_bucket,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count
         else count(*) end as n_patients,
    t.n_patients_subgroup_total
   from bucketed b
cross join totals t
  group by  b.dx_support_bucket, t.n_patients_subgroup_total
   order by  case b.dx_support_bucket
        when 'SPECIFIC_DX_SINGLE_DAY' then 1
        when 'SPECIFIC_DX_2PLUS_DAYS' then 2
        else 9
    end
  ;

