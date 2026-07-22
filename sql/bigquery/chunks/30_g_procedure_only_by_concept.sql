-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/30_g_procedure_only_by_concept.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 30) G. Drug Therapy procedure characterization, part 1b. Which Drug Therapy
--     procedure concept drives the procedure-only group.
--     Among the procedure-only patients defined in chunk 29 (a Drug Therapy
--     procedure on or after the first Metastasis, but NO antineoplastic
--     drug_exposure on or after the first Metastasis), how many carry each of the
--     four Drug Therapy procedure roots:
--
--       root_concept_id 4273629  Chemotherapy
--       root_concept_id 4295112  Immunological therapy
--       root_concept_id 37158316 Targeted chemotherapy for cancer
--       root_concept_id 4061650  Hormone therapy
--
--     A patient counts under every root they carry a procedure for (on or after
--     the first MET), so the per-root counts OVERLAP and do NOT sum to the
--     procedure-only total. Only procedures on or after the first MET are counted,
--     consistent with the chunk-29 procedure-only definition.
--
--     Denominator (n_procedure_only_total, repeated on each row):
--       the DTP_ONLY_ON_OR_AFTER_MET group of chunk 29 (procedure on or after MET,
--       no drug_exposure on or after MET). Re-derived here from the same source
--       logic so the two chunks stay consistent.
--
--     Population, observation-period and source notes: same as chunk 29 (DX-anchored
--     MET population from #met_events; L01 from #l01_events, gated to #anchor_person;
--     Drug Therapy procedures from procedure_occurrence + #dtp_concepts restricted to
--     the same cohort by the join to met_all; no observation-period gate). Per-root
--     n_patients in (0, @min_cell_count] set to -@min_cell_count; n_procedure_only_total
--     is an aggregate denominator, not suppressed. A root carried by zero
--     procedure-only patients is absent.
with met_all as (
     select person_id,
        min(event_date) as first_met_date
     from vcbo5u4zmet_events
     group by  1 ),
drugexp_flag as (
    -- MET patients with an antineoplastic drug_exposure on or after the first MET.
    select distinct ma.person_id
    from met_all ma
    join vcbo5u4zl01_events le
      on le.person_id = ma.person_id
    where le.event_date >= ma.first_met_date
),
proc_on_after as (
    -- Every Drug Therapy procedure on or after the first MET, tagged with its root.
    select distinct
        ma.person_id,
        dtp.root_concept_id
    from met_all ma
    join @cdm_database_schema.procedure_occurrence po
      on po.person_id = ma.person_id
    join vcbo5u4zdtp_concepts dtp
      on po.procedure_concept_id = dtp.concept_id
    where po.procedure_date >= ma.first_met_date
),
proc_only as (
    -- Procedure-only group: a procedure on or after MET, and NOT in drugexp_flag.
    select p.person_id, p.root_concept_id
    from proc_on_after p
    left join drugexp_flag d on d.person_id = p.person_id
    where d.person_id is null
),
totals as (
    select count(distinct person_id) as n_procedure_only_total from proc_only
)
   select po.root_concept_id,
    case when count(distinct po.person_id) > 0
          and count(distinct po.person_id) <= @min_cell_count then -@min_cell_count
         else count(distinct po.person_id) end as n_patients,
    t.n_procedure_only_total
   from proc_only po
cross join totals t
  group by  po.root_concept_id, t.n_procedure_only_total
   order by  2 desc, po.root_concept_id
  ;

