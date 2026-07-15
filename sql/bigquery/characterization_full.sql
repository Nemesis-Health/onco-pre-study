-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:20 CEST
-- Source file    : sql/sql_server/characterization_full.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

/*
============================================================
 OMOP Characterization - SQL Server Base (SqlRender-ready)
  v2: dual concept-level event-code timing (FIRST + CLOSEST)
============================================================
UC ANCHOR VARIANT
-----------------
DX anchor follows cohort_definitions/UC.json concept set id 7
("UC - Malignant neoplasm"), built from #dx_anchor_include / #dx_anchor_exclude
and @cdm_database_schema.concept_ancestor.
Purpose
-------
Same cohort and pairwise timing as `v1_sqlserver_base_uc_malignant_neoplasm.sql`, but **concept-level**
event code timing exports **both** rules in one run (no `@event_code_timing_uses_closest`):
  - **FIRST:** earliest `event_date` per (anchor, family, concept, patient) [within TIME_RELATIVE stratum when applicable].
  - **CLOSEST:** minimum |days_diff| to anchor, tie-break `event_date`.
Final CSV columns include `lq_days_first` / `median_days_first` / `uq_days_first` and
`lq_days_closest` / `median_days_closest` / `uq_days_closest`. Legacy `lq_days` / `median_days` / `uq_days`
duplicate the **FIRST** triple for backward compatibility with older report code.
How to use
----------
1) Set @cdm_database_schema (or render via SqlRender).
2) Set privacy threshold below (small-cell suppression).
3) Edit concept-set INSERT blocks at top.
4) Run in SQL Server (or render+translate with SqlRender for target DB).
5) Export result sets from final SELECT statements (10 in this file, including per-concept anchor DX patient / patient-day counts).
Cross-dialect / SqlRender
-------------------------
- **Parameters (render):** `@cdm_database_schema`, `@min_cell_count` only.
- **Portable patterns:** same as v1 (SMALLINT, ordered-set percentiles + DISTINCT, etc.).
- **Validate:** `Rscript scripts/validate_characterization_sqlrender.R data_characterization/sql_versions/v2_sqlserver_base_uc_malignant_neoplasm_dual_event_code_timing.sql`
*/
------------------------------------------------------------
-- PARAMETERS (SqlRender style)
------------------------------------------------------------
-- Example:
-- DECLARE @cdm_database_schema VARCHAR(100) = 'cdm';
------------------------------------------------------------
-- PRIVACY CONTROLS
------------------------------------------------------------
-- Suppress small cells <= this threshold in final outputs.
-- SqlRender parameter (set during render, e.g. min_cell_count = 0).
-- Do not declare @min_cell_count here because SqlRender inlines @tokens.
------------------------------------------------------------
-- A) ANCHOR DIAGNOSIS CONCEPTS (DX)
-- Anchor cohort = patients with any of these condition_concept_id values
-- Source: cohort_definitions/UC.json <U+2014> ConceptSets id 7 "UC - Malignant neoplasm"
-- Expanded with concept_ancestor (includeDescendants / isExcluded match Atlas).
------------------------------------------------------------
drop table if exists vcbo5u4zdx_anchor_include;
DROP TABLE IF EXISTS vcbo5u4zdx_anchor_include;
CREATE TABLE vcbo5u4zdx_anchor_include (
    concept_id INT64 not null,
    include_descendants smallint not null
);
insert into vcbo5u4zdx_anchor_include (concept_id, include_descendants) values
    (197508, 1),      -- Malignant neoplasm of urinary bladder
    (4181357, 1),     -- Malignant tumor of renal pelvis
    (4177230, 1),     -- Malignant tumor of urethra
    (37163176, 1),    -- Transitional cell carcinoma of upper urinary tract
    (4178972, 1),     -- Malignant tumor of ureter
    (4091486, 0),     -- Malignant neoplasm of overlapping sites of urinary organs
    (44501785, 0),    -- Transitional cell carcinoma, NOS, of urinary system, NOS (ICDO3)
    (37110270, 1)     -- Primary urothelial carcinoma of overlapping sites of urinary organs
;
drop table if exists vcbo5u4zdx_anchor_exclude;
DROP TABLE IF EXISTS vcbo5u4zdx_anchor_exclude;
CREATE TABLE vcbo5u4zdx_anchor_exclude (
    concept_id INT64 not null,
    include_descendants smallint not null
);
insert into vcbo5u4zdx_anchor_exclude (concept_id, include_descendants) values
    (4280899, 1),
    (4289374, 1),
    (4280900, 1),
    (4283614, 1),
    (4289097, 1),
    (4280901, 1),
    (4289376, 1),
    (4280897, 1),
    (4200889, 1);
drop table if exists vcbo5u4zdx_anchor_concepts;
DROP TABLE IF EXISTS vcbo5u4zdx_anchor_concepts;
CREATE TABLE vcbo5u4zdx_anchor_concepts (
    concept_id INT64
);
insert into vcbo5u4zdx_anchor_concepts (concept_id)
select distinct ca.descendant_concept_id
from vcbo5u4zdx_anchor_include i
join @cdm_database_schema.concept_ancestor ca
  on ca.ancestor_concept_id = i.concept_id
 and (i.include_descendants = 1 or ca.descendant_concept_id = i.concept_id);
delete from vcbo5u4zdx_anchor_concepts
where exists (
    select 1
    from vcbo5u4zdx_anchor_exclude e
    join @cdm_database_schema.concept_ancestor ca
      on ca.ancestor_concept_id = e.concept_id
     and vcbo5u4zdx_anchor_concepts.concept_id = ca.descendant_concept_id
     and (e.include_descendants = 1 or ca.descendant_concept_id = e.concept_id)
);
------------------------------------------------------------
-- B) OTHER GENERALIZED CANCER DX CONCEPTS (GDX)
-- Default: distinct ancestors of DX anchor concepts, excluding anchor DX concepts themselves,
-- but constrained to descendants of 443392 (Malignant neoplastic disease) to avoid overly-broad ancestors.
-- (concept_ancestor includes self-links; we only want broader/generalized codes).
------------------------------------------------------------
drop table if exists vcbo5u4zgen_cancer_concepts;
DROP TABLE IF EXISTS vcbo5u4zgen_cancer_concepts;
CREATE TABLE vcbo5u4zgen_cancer_concepts (
    concept_id INT64
);
insert into vcbo5u4zgen_cancer_concepts (concept_id)
select distinct ca.ancestor_concept_id
from @cdm_database_schema.concept_ancestor ca
join vcbo5u4zdx_anchor_concepts d
  on ca.descendant_concept_id = d.concept_id
join @cdm_database_schema.concept_ancestor malign
  on malign.ancestor_concept_id = 443392
 and malign.descendant_concept_id = ca.ancestor_concept_id
where not exists (
    select 1
    from vcbo5u4zdx_anchor_concepts dx
    where dx.concept_id = ca.ancestor_concept_id
)
;
------------------------------------------------------------
-- C) OTHER CANCER DIAGNOSIS CONCEPTS (ODX)
-- Default: descendants of 443392 excluding DX + GDX sets.
------------------------------------------------------------
drop table if exists vcbo5u4zother_dx_ancestor_concepts;
DROP TABLE IF EXISTS vcbo5u4zother_dx_ancestor_concepts;
CREATE TABLE vcbo5u4zother_dx_ancestor_concepts (
    ancestor_concept_id INT64
);
-- EDIT THIS LIST
insert into vcbo5u4zother_dx_ancestor_concepts (ancestor_concept_id)
values
    (443392) -- Malignant neoplastic disease
;
drop table if exists vcbo5u4zother_dx_concepts;
DROP TABLE IF EXISTS vcbo5u4zother_dx_concepts;
CREATE TABLE vcbo5u4zother_dx_concepts (
    concept_id INT64
);
insert into vcbo5u4zother_dx_concepts (concept_id)
select distinct ca.descendant_concept_id
from @cdm_database_schema.concept_ancestor ca
join vcbo5u4zother_dx_ancestor_concepts a
  on ca.ancestor_concept_id = a.ancestor_concept_id
left join vcbo5u4zdx_anchor_concepts dx
  on dx.concept_id = ca.descendant_concept_id
left join vcbo5u4zgen_cancer_concepts gdx
  on gdx.concept_id = ca.descendant_concept_id
where dx.concept_id is null
  and gdx.concept_id is null
;
------------------------------------------------------------
-- D) METASTASIS CONCEPTS (MEASUREMENT)
-- Define via ancestor IDs (descendants pulled from concept_ancestor)
------------------------------------------------------------
drop table if exists vcbo5u4zmet_ancestor_concepts;
DROP TABLE IF EXISTS vcbo5u4zmet_ancestor_concepts;
CREATE TABLE vcbo5u4zmet_ancestor_concepts (
    ancestor_concept_id INT64
);
-- Default: concept set "Secondary malignancy" from cohort_definitions/Target_Cohort_2B.json
insert into vcbo5u4zmet_ancestor_concepts (ancestor_concept_id)
values
    (1633308),  -- AJCC/UICC Stage 4
    (1635142),  -- AJCC/UICC M1 Category
    (36769180)  -- Metastasis
;
drop table if exists vcbo5u4zmet_concepts;
DROP TABLE IF EXISTS vcbo5u4zmet_concepts;
CREATE TABLE vcbo5u4zmet_concepts (
    concept_id INT64
);
insert into vcbo5u4zmet_concepts (concept_id)
select distinct ca.descendant_concept_id
from @cdm_database_schema.concept_ancestor ca
join vcbo5u4zmet_ancestor_concepts a
  on ca.ancestor_concept_id = a.ancestor_concept_id
;
------------------------------------------------------------
-- E) L01 TREATMENT CONCEPTS (DRUG_EXPOSURE)
------------------------------------------------------------
drop table if exists vcbo5u4zl01_ancestor_concepts;
DROP TABLE IF EXISTS vcbo5u4zl01_ancestor_concepts;
CREATE TABLE vcbo5u4zl01_ancestor_concepts (
    ancestor_concept_id INT64
);
-- EDIT THIS LIST
insert into vcbo5u4zl01_ancestor_concepts (ancestor_concept_id)
values
    (21601387)
;
drop table if exists vcbo5u4zl01_concepts;
DROP TABLE IF EXISTS vcbo5u4zl01_concepts;
CREATE TABLE vcbo5u4zl01_concepts (
    concept_id INT64
);
insert into vcbo5u4zl01_concepts (concept_id)
select distinct ca.descendant_concept_id
from @cdm_database_schema.concept_ancestor ca
join vcbo5u4zl01_ancestor_concepts a
  on ca.ancestor_concept_id = a.ancestor_concept_id
;
------------------------------------------------------------
-- E2) DRUG THERAPY PROCEDURE CONCEPTS (PROCEDURE_OCCURRENCE)
--     Added for Analysis G. Antineoplastic treatment recorded as a procedure
--     rather than a drug_exposure. Four Drug Therapy procedure roots and their
--     descendants. Same ancestor-then-descendants build as the L01 concept set
--     in section E: #dtp_ancestor_concepts holds the roots; #dtp_concepts expands
--     to descendants via concept_ancestor (which includes each root itself at
--     level 0, so the roots are in #dtp_concepts too). This is the only concept
--     set that reads procedure_occurrence.
--
--     #dtp_concepts additionally carries the root each descendant maps to
--     (root_concept_id), so Analysis G can report per category (Chemotherapy /
--     Immunological therapy / Targeted chemotherapy for cancer / Hormone therapy).
--     This is a small extension of the plain concept-id list used for L01; it is
--     needed because G's Part 1b and Part 3 are per-concept. A descendant that
--     falls under more than one root appears once per root, so a patient can be
--     counted under more than one category and the per-category counts overlap
--     and need not sum, matching the approved mock.
--
--     No procedure event table is materialised here. Like Analyses D and H, G's
--     denominator is the full ungated population (all patients who carry a MET
--     code, or all patients who carry the procedure), so the G chunks read
--     procedure_occurrence directly rather than through a DX-cohort-gated event
--     table (the #*_events tables in section F are all gated to #anchor_person).
------------------------------------------------------------
drop table if exists vcbo5u4zdtp_ancestor_concepts;
DROP TABLE IF EXISTS vcbo5u4zdtp_ancestor_concepts;
CREATE TABLE vcbo5u4zdtp_ancestor_concepts (
    ancestor_concept_id INT64
);
-- EDIT THIS LIST
-- Chemotherapy 4273629, Immunological therapy 4295112,
-- Targeted chemotherapy for cancer 37158316, Hormone therapy 4061650.
insert into vcbo5u4zdtp_ancestor_concepts (ancestor_concept_id)
values
    (4273629),
    (4295112),
    (37158316),
    (4061650)
;
drop table if exists vcbo5u4zdtp_concepts;
DROP TABLE IF EXISTS vcbo5u4zdtp_concepts;
CREATE TABLE vcbo5u4zdtp_concepts (
    concept_id      INT64,
    root_concept_id INT64
);
insert into vcbo5u4zdtp_concepts (concept_id, root_concept_id)
select distinct ca.descendant_concept_id, a.ancestor_concept_id
from @cdm_database_schema.concept_ancestor ca
join vcbo5u4zdtp_ancestor_concepts a
  on ca.ancestor_concept_id = a.ancestor_concept_id
;
------------------------------------------------------------
-- F) EVENT TABLES
------------------------------------------------------------
drop table if exists vcbo5u4zdx_events;
DROP TABLE IF EXISTS vcbo5u4zdx_events;
CREATE TABLE vcbo5u4zdx_events (
    person_id INT64,
    event_date date,
    concept_id INT64
);
insert into vcbo5u4zdx_events (person_id, event_date, concept_id)
select
    co.person_id,
    co.condition_start_date,
    co.condition_concept_id
from @cdm_database_schema.condition_occurrence co
join vcbo5u4zdx_anchor_concepts d
  on co.condition_concept_id = d.concept_id
;
-- Distinct anchor cohort persons; limits later F) pulls to rows that downstream joins to #cohort use anyway.
drop table if exists vcbo5u4zanchor_person;
DROP TABLE IF EXISTS vcbo5u4zanchor_person;
CREATE TABLE vcbo5u4zanchor_person (
    person_id INT64
);
insert into vcbo5u4zanchor_person (person_id)
select distinct person_id
from vcbo5u4zdx_events
;
drop table if exists vcbo5u4zother_dx_events;
DROP TABLE IF EXISTS vcbo5u4zother_dx_events;
CREATE TABLE vcbo5u4zother_dx_events (
    person_id INT64,
    event_date date,
    concept_id INT64
);
insert into vcbo5u4zother_dx_events (person_id, event_date, concept_id)
select
    co.person_id,
    co.condition_start_date,
    co.condition_concept_id
from @cdm_database_schema.condition_occurrence co
join vcbo5u4zanchor_person ap
  on co.person_id = ap.person_id
join vcbo5u4zother_dx_concepts d
  on co.condition_concept_id = d.concept_id
;
drop table if exists vcbo5u4zgen_cancer_events;
DROP TABLE IF EXISTS vcbo5u4zgen_cancer_events;
CREATE TABLE vcbo5u4zgen_cancer_events (
    person_id INT64,
    event_date date,
    concept_id INT64
);
insert into vcbo5u4zgen_cancer_events (person_id, event_date, concept_id)
select
    co.person_id,
    co.condition_start_date,
    co.condition_concept_id
from @cdm_database_schema.condition_occurrence co
join vcbo5u4zanchor_person ap
  on co.person_id = ap.person_id
join vcbo5u4zgen_cancer_concepts g
  on co.condition_concept_id = g.concept_id
;
drop table if exists vcbo5u4zmet_events;
DROP TABLE IF EXISTS vcbo5u4zmet_events;
CREATE TABLE vcbo5u4zmet_events (
    person_id INT64,
    event_date date,
    concept_id INT64
);
insert into vcbo5u4zmet_events (person_id, event_date, concept_id)
select
    m.person_id,
    m.measurement_date,
    m.measurement_concept_id
from @cdm_database_schema.measurement m
join vcbo5u4zanchor_person ap
  on m.person_id = ap.person_id
join vcbo5u4zmet_concepts mc
  on m.measurement_concept_id = mc.concept_id
;
drop table if exists vcbo5u4zl01_events;
DROP TABLE IF EXISTS vcbo5u4zl01_events;
CREATE TABLE vcbo5u4zl01_events (
    person_id INT64,
    event_date date,
    concept_id INT64
);
insert into vcbo5u4zl01_events (person_id, event_date, concept_id)
select
    de.person_id,
    de.drug_exposure_start_date,
    de.drug_concept_id
from @cdm_database_schema.drug_exposure de
join vcbo5u4zanchor_person ap
  on de.person_id = ap.person_id
join vcbo5u4zl01_concepts l
  on de.drug_concept_id = l.concept_id
;
-- Ingredient-level L01 events used for concept-level code counts/timing.
drop table if exists vcbo5u4zl01_ingredient_events;
DROP TABLE IF EXISTS vcbo5u4zl01_ingredient_events;
CREATE TABLE vcbo5u4zl01_ingredient_events (
    person_id INT64,
    event_date date,
    concept_id INT64
);
insert into vcbo5u4zl01_ingredient_events (person_id, event_date, concept_id)
select distinct
    de.person_id,
    de.drug_exposure_start_date,
    ca.ancestor_concept_id
from @cdm_database_schema.drug_exposure de
join vcbo5u4zanchor_person ap
  on de.person_id = ap.person_id
join vcbo5u4zl01_concepts l
  on de.drug_concept_id = l.concept_id
join @cdm_database_schema.concept_ancestor ca
  on ca.descendant_concept_id = de.drug_concept_id
join @cdm_database_schema.concept ing
  on ing.concept_id = ca.ancestor_concept_id
 and ing.concept_class_id = 'Ingredient'
;
------------------------------------------------------------
-- G) COHORT ANCHOR + SUMMARIES
------------------------------------------------------------
-- Track attrition: count all patients with a qualifying DX before the
-- obs-period filter so the report can show how many were excluded.
drop table if exists vcbo5u4zcohort_attrition;
DROP TABLE IF EXISTS vcbo5u4zcohort_attrition;
CREATE TABLE vcbo5u4zcohort_attrition (
    stage      STRING,
    n_patients INT64
);
insert into vcbo5u4zcohort_attrition (stage, n_patients)
select 'dx_any', count(distinct person_id) from vcbo5u4zdx_events;
drop table if exists vcbo5u4zcohort;
DROP TABLE IF EXISTS vcbo5u4zcohort;
CREATE TABLE vcbo5u4zcohort (
    person_id INT64,
    index_date date
);
-- Index date = earliest qualifying DX that falls within an observation period.
-- Patients with no obs-period-covered DX are excluded entirely.
insert into vcbo5u4zcohort (person_id, index_date)
 select dx.person_id,
    min(dx.event_date) as index_date
 from vcbo5u4zdx_events dx
inner join @cdm_database_schema.observation_period op
    on  op.person_id = dx.person_id
    and dx.event_date between op.observation_period_start_date
                          and op.observation_period_end_date
 group by  dx.person_id
 ;
insert into vcbo5u4zcohort_attrition (stage, n_patients)
select 'dx_in_obs', count(*) from vcbo5u4zcohort;
drop table if exists vcbo5u4zdx_summary;
DROP TABLE IF EXISTS vcbo5u4zdx_summary;
CREATE TABLE vcbo5u4zdx_summary (
    person_id INT64,
    n_dx_records INT64,
    n_dx_codes INT64
);
insert into vcbo5u4zdx_summary (person_id, n_dx_records, n_dx_codes)
 select e.person_id,
    count(*) as n_dx_records,
    count(distinct e.concept_id) as n_dx_codes
 from vcbo5u4zdx_events e
join vcbo5u4zcohort c
  on e.person_id = c.person_id
 group by  e.person_id
 ;
drop table if exists vcbo5u4zother_dx_summary;
DROP TABLE IF EXISTS vcbo5u4zother_dx_summary;
CREATE TABLE vcbo5u4zother_dx_summary (
    person_id INT64,
    first_other_dx_date date,
    n_other_dx_records INT64,
    n_other_dx_codes INT64
);
insert into vcbo5u4zother_dx_summary (person_id, first_other_dx_date, n_other_dx_records, n_other_dx_codes)
 select e.person_id,
    min(e.event_date) as first_other_dx_date,
    count(*) as n_other_dx_records,
    count(distinct e.concept_id) as n_other_dx_codes
 from vcbo5u4zother_dx_events e
join vcbo5u4zcohort c
  on e.person_id = c.person_id
 group by  e.person_id
 ;
drop table if exists vcbo5u4zgen_cancer_summary;
DROP TABLE IF EXISTS vcbo5u4zgen_cancer_summary;
CREATE TABLE vcbo5u4zgen_cancer_summary (
    person_id INT64,
    first_gen_cancer_date date,
    n_gen_cancer_records INT64,
    n_gen_cancer_codes INT64
);
insert into vcbo5u4zgen_cancer_summary (person_id, first_gen_cancer_date, n_gen_cancer_records, n_gen_cancer_codes)
 select e.person_id,
    min(e.event_date) as first_gen_cancer_date,
    count(*) as n_gen_cancer_records,
    count(distinct e.concept_id) as n_gen_cancer_codes
 from vcbo5u4zgen_cancer_events e
join vcbo5u4zcohort c
  on e.person_id = c.person_id
 group by  e.person_id
 ;
drop table if exists vcbo5u4zmet_summary;
DROP TABLE IF EXISTS vcbo5u4zmet_summary;
CREATE TABLE vcbo5u4zmet_summary (
    person_id INT64,
    first_met_date date,
    n_met_records INT64
);
insert into vcbo5u4zmet_summary (person_id, first_met_date, n_met_records)
 select e.person_id,
    min(e.event_date) as first_met_date,
    count(*) as n_met_records
 from vcbo5u4zmet_events e
join vcbo5u4zcohort c
  on e.person_id = c.person_id
 group by  e.person_id
 ;
drop table if exists vcbo5u4zl01_summary;
DROP TABLE IF EXISTS vcbo5u4zl01_summary;
CREATE TABLE vcbo5u4zl01_summary (
    person_id INT64,
    first_l01_date date,
    n_l01_exposures INT64
);
insert into vcbo5u4zl01_summary (person_id, first_l01_date, n_l01_exposures)
 select e.person_id,
    min(e.event_date) as first_l01_date,
    count(*) as n_l01_exposures
 from vcbo5u4zl01_events e
join vcbo5u4zcohort c
  on e.person_id = c.person_id
 group by  e.person_id
 ;
-- H) EVENT CODE COUNTS (single table across event families)
------------------------------------------------------------
drop table if exists vcbo5u4zevent_code_counts;
DROP TABLE IF EXISTS vcbo5u4zevent_code_counts;
CREATE TABLE vcbo5u4zevent_code_counts (
    anchor_event STRING, -- INDEX or FIRST_MET
    event_family STRING,
    concept_id INT64,
    n_records INT64,
    n_patients INT64
);
insert into vcbo5u4zevent_code_counts (anchor_event, event_family, concept_id, n_records, n_patients)
 select 'INDEX', 'DX', concept_id, count(*), count(distinct person_id)
 from vcbo5u4zdx_events
where person_id in (select person_id from vcbo5u4zcohort)
 group by  concept_id
union all
 select 'INDEX', 'ODX', 3, 4, count(distinct person_id)
 from vcbo5u4zother_dx_events
where person_id in (select person_id from vcbo5u4zcohort)
 group by  concept_id
union all
 select 'INDEX', 'GDX', 3, 4, count(distinct person_id)
 from vcbo5u4zgen_cancer_events
where person_id in (select person_id from vcbo5u4zcohort)
 group by  concept_id
union all
 select 'INDEX', 'MET', 3, 4, count(distinct person_id)
 from vcbo5u4zmet_events
where person_id in (select person_id from vcbo5u4zcohort)
 group by  concept_id
union all
 select 'INDEX', 'L01', 3, 4, count(distinct person_id)
 from vcbo5u4zl01_ingredient_events
where person_id in (select person_id from vcbo5u4zcohort)
 group by  concept_id
union all
 select 'FIRST_MET', 2, 3, 4, count(distinct e.person_id)
 from vcbo5u4zdx_events e
join vcbo5u4zmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  concept_id
union all
 select 'FIRST_MET', 2, 3, 4, count(distinct e.person_id)
 from vcbo5u4zother_dx_events e
join vcbo5u4zmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  concept_id
union all
 select 'FIRST_MET', 2, 3, 4, count(distinct e.person_id)
 from vcbo5u4zgen_cancer_events e
join vcbo5u4zmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  concept_id
union all
 select 'FIRST_MET', 2, 3, 4, count(distinct e.person_id)
 from vcbo5u4zmet_events e
join vcbo5u4zmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  concept_id
union all
 select 'FIRST_MET', 2, 3, 4, count(distinct e.person_id)
 from vcbo5u4zl01_ingredient_events e
join vcbo5u4zmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  concept_id
          ;
drop table if exists vcbo5u4zevent_code_counts_before_after;
DROP TABLE IF EXISTS vcbo5u4zevent_code_counts_before_after;
CREATE TABLE vcbo5u4zevent_code_counts_before_after (
    anchor_event STRING, -- INDEX
    event_family STRING,
    time_relative STRING, -- BEFORE or AFTER (relative to index_date)
    concept_id INT64,
    n_records INT64,
    n_patients INT64
);
insert into vcbo5u4zevent_code_counts_before_after (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
 select 'INDEX',
       'DX',
       case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end as time_relative,
       e.concept_id,
       count(*) as n_records,
       count(distinct e.person_id) as n_patients
 from vcbo5u4zdx_events e
join vcbo5u4zcohort c
  on e.person_id = c.person_id
 group by  3, e.concept_id
union all
 select 'INDEX', 'ODX', 3, e.concept_id, 5, count(distinct e.person_id)
 from vcbo5u4zother_dx_events e
join vcbo5u4zcohort c
  on e.person_id = c.person_id
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
union all
 select 'INDEX', 'GDX', 3, e.concept_id, 5, count(distinct e.person_id)
 from vcbo5u4zgen_cancer_events e
join vcbo5u4zcohort c
  on e.person_id = c.person_id
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
union all
 select 'INDEX', 'MET', 3, e.concept_id, 5, count(distinct e.person_id)
 from vcbo5u4zmet_events e
join vcbo5u4zcohort c
  on e.person_id = c.person_id
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
union all
 select 'INDEX', 'L01', 3, e.concept_id, 5, count(distinct e.person_id)
 from vcbo5u4zl01_ingredient_events e
join vcbo5u4zcohort c
  on e.person_id = c.person_id
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
     ;
drop table if exists vcbo5u4zevent_code_counts_before_after_first_met;
DROP TABLE IF EXISTS vcbo5u4zevent_code_counts_before_after_first_met;
CREATE TABLE vcbo5u4zevent_code_counts_before_after_first_met (
    anchor_event STRING, -- FIRST_MET
    event_family STRING,
    time_relative STRING, -- BEFORE or AFTER (relative to first_met_date)
    concept_id INT64,
    n_records INT64,
    n_patients INT64
);
insert into vcbo5u4zevent_code_counts_before_after_first_met (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
 select 'FIRST_MET',
       'DX',
       case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end as time_relative,
       e.concept_id,
       count(*) as n_records,
       count(distinct e.person_id) as n_patients
 from vcbo5u4zdx_events e
join vcbo5u4zmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  3, e.concept_id
union all
 select 'FIRST_MET', 'ODX', 3, e.concept_id, 5, count(distinct e.person_id)
 from vcbo5u4zother_dx_events e
join vcbo5u4zmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
union all
 select 'FIRST_MET', 'GDX', 3, e.concept_id, 5, count(distinct e.person_id)
 from vcbo5u4zgen_cancer_events e
join vcbo5u4zmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
union all
 select 'FIRST_MET', 'MET', 3, e.concept_id, 5, count(distinct e.person_id)
 from vcbo5u4zmet_events e
join vcbo5u4zmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
union all
 select 'FIRST_MET', 'L01', 3, e.concept_id, 5, count(distinct e.person_id)
 from vcbo5u4zl01_ingredient_events e
join vcbo5u4zmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
     ;
drop table if exists vcbo5u4zevent_code_all_events;
DROP TABLE IF EXISTS vcbo5u4zevent_code_all_events;
CREATE TABLE vcbo5u4zevent_code_all_events (
    anchor_event STRING,
    event_family STRING,
    concept_id INT64,
    person_id INT64,
    days_diff INT64,
    event_date date
);
insert into vcbo5u4zevent_code_all_events (
    anchor_event, event_family, concept_id, person_id, days_diff, event_date
)
select 'INDEX' as anchor_event, 'DX' as event_family, e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as days_diff, e.event_date
from vcbo5u4zdx_events e
join vcbo5u4zcohort c on e.person_id = c.person_id
union all
select 'INDEX', 'ODX', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY), e.event_date
from vcbo5u4zother_dx_events e
join vcbo5u4zcohort c on e.person_id = c.person_id
union all
select 'INDEX', 'GDX', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY), e.event_date
from vcbo5u4zgen_cancer_events e
join vcbo5u4zcohort c on e.person_id = c.person_id
union all
select 'INDEX', 'MET', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY), e.event_date
from vcbo5u4zmet_events e
join vcbo5u4zcohort c on e.person_id = c.person_id
union all
select 'INDEX', 'L01', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY), e.event_date
from vcbo5u4zl01_ingredient_events e
join vcbo5u4zcohort c on e.person_id = c.person_id
union all
select 'FIRST_MET', 'DX', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY), e.event_date
from vcbo5u4zdx_events e
join vcbo5u4zmet_summary ms on e.person_id = ms.person_id
where ms.first_met_date is not null
union all
select 'FIRST_MET', 'ODX', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY), e.event_date
from vcbo5u4zother_dx_events e
join vcbo5u4zmet_summary ms on e.person_id = ms.person_id
where ms.first_met_date is not null
union all
select 'FIRST_MET', 'GDX', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY), e.event_date
from vcbo5u4zgen_cancer_events e
join vcbo5u4zmet_summary ms on e.person_id = ms.person_id
where ms.first_met_date is not null
union all
select 'FIRST_MET', 'MET', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY), e.event_date
from vcbo5u4zmet_events e
join vcbo5u4zmet_summary ms on e.person_id = ms.person_id
where ms.first_met_date is not null
union all
select 'FIRST_MET', 'L01', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY), e.event_date
from vcbo5u4zl01_ingredient_events e
join vcbo5u4zmet_summary ms on e.person_id = ms.person_id
where ms.first_met_date is not null
;
drop table if exists vcbo5u4zevent_code_patient_chosen_first;
DROP TABLE IF EXISTS vcbo5u4zevent_code_patient_chosen_first;
CREATE TABLE vcbo5u4zevent_code_patient_chosen_first (
    anchor_event STRING,
    event_family STRING,
    concept_id INT64,
    person_id INT64,
    days_diff INT64
);
insert into vcbo5u4zevent_code_patient_chosen_first (anchor_event, event_family, concept_id, person_id, days_diff)
select anchor_event, event_family, concept_id, person_id, days_diff
from (
    select
        anchor_event,
        event_family,
        concept_id,
        person_id,
        days_diff,
        row_number() over (
            partition by anchor_event, event_family, concept_id, person_id
            order by DATE_DIFF(IF(SAFE_CAST(event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(event_date  AS STRING)),SAFE_CAST(event_date  AS DATE)), IF(SAFE_CAST(IF(SAFE_CAST('1900-01-01'  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast('1900-01-01'  AS STRING)),SAFE_CAST('1900-01-01'  AS DATE))  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(IF(SAFE_CAST('1900-01-01'  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast('1900-01-01'  AS STRING)),SAFE_CAST('1900-01-01'  AS DATE))  AS STRING)),SAFE_CAST(IF(SAFE_CAST('1900-01-01'  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast('1900-01-01'  AS STRING)),SAFE_CAST('1900-01-01'  AS DATE))  AS DATE)), DAY) asc, event_date asc
        ) as rn
    from vcbo5u4zevent_code_all_events
) x
where rn = 1
;
drop table if exists vcbo5u4zevent_code_patient_chosen_closest;
DROP TABLE IF EXISTS vcbo5u4zevent_code_patient_chosen_closest;
CREATE TABLE vcbo5u4zevent_code_patient_chosen_closest (
    anchor_event STRING,
    event_family STRING,
    concept_id INT64,
    person_id INT64,
    days_diff INT64
);
insert into vcbo5u4zevent_code_patient_chosen_closest (anchor_event, event_family, concept_id, person_id, days_diff)
select anchor_event, event_family, concept_id, person_id, days_diff
from (
    select
        anchor_event,
        event_family,
        concept_id,
        person_id,
        days_diff,
        row_number() over (
            partition by anchor_event, event_family, concept_id, person_id
            order by abs(days_diff) asc, event_date asc
        ) as rn
    from vcbo5u4zevent_code_all_events
) x
where rn = 1
;
drop table if exists vcbo5u4zevent_code_timing_summary;
DROP TABLE IF EXISTS vcbo5u4zevent_code_timing_summary;
CREATE TABLE vcbo5u4zevent_code_timing_summary (
    anchor_event STRING,
    event_family STRING,
    concept_id INT64,
    n_patients_with_code_timing INT64,
    lq_days_first FLOAT64,
    median_days_first FLOAT64,
    uq_days_first FLOAT64,
    lq_days_closest FLOAT64,
    median_days_closest FLOAT64,
    uq_days_closest FLOAT64
);
insert into vcbo5u4zevent_code_timing_summary (
    anchor_event,
    event_family,
    concept_id,
    n_patients_with_code_timing,
    lq_days_first,
    median_days_first,
    uq_days_first,
    lq_days_closest,
    median_days_closest,
    uq_days_closest
)
select
    f.anchor_event,
    f.event_family,
    f.concept_id,
    f.n_patients_with_code_timing,
    f.lq_days_first,
    f.median_days_first,
    f.uq_days_first,
    k.lq_days_closest,
    k.median_days_closest,
    k.uq_days_closest
from (
     select anchor_event,
        event_family,
        concept_id,
        count(*) as n_patients_with_code_timing,
        min(case when 4.0 * rn >= cnt then cast(days_diff  as float64) end) as lq_days_first,
        min(case when 2.0 * rn >= cnt then cast(days_diff  as float64) end) as median_days_first,
        min(case when 4.0 * rn >= 3 * cnt then cast(days_diff  as float64) end) as uq_days_first
     from (
        select anchor_event, event_family, concept_id, days_diff,
            row_number() over (partition by anchor_event, event_family, concept_id order by days_diff) as rn,
            count(*)     over (partition by anchor_event, event_family, concept_id)                    as cnt
        from vcbo5u4zevent_code_patient_chosen_first
    ) x
     group by  1, 2, 3 ) f
inner join (
     select anchor_event,
        event_family,
        concept_id,
        min(case when 4.0 * rn >= cnt then cast(days_diff  as float64) end) as lq_days_closest,
        min(case when 2.0 * rn >= cnt then cast(days_diff  as float64) end) as median_days_closest,
        min(case when 4.0 * rn >= 3 * cnt then cast(days_diff  as float64) end) as uq_days_closest
     from (
        select anchor_event, event_family, concept_id, days_diff,
            row_number() over (partition by anchor_event, event_family, concept_id order by days_diff) as rn,
            count(*)     over (partition by anchor_event, event_family, concept_id)                    as cnt
        from vcbo5u4zevent_code_patient_chosen_closest
    ) x
     group by  1, 2, 3 ) k
  on f.anchor_event = k.anchor_event
 and f.event_family = k.event_family
 and f.concept_id = k.concept_id
;
drop table if exists vcbo5u4zevent_code_ba_events;
DROP TABLE IF EXISTS vcbo5u4zevent_code_ba_events;
CREATE TABLE vcbo5u4zevent_code_ba_events (
    anchor_event STRING,
    event_family STRING,
    time_relative STRING,
    concept_id INT64,
    person_id INT64,
    days_diff INT64,
    event_date date
);
insert into vcbo5u4zevent_code_ba_events (
    anchor_event, event_family, time_relative, concept_id, person_id, days_diff, event_date
)
select
    anchor_event,
    event_family,
    case when days_diff < 0 then 'BEFORE' else 'AFTER' end,
    concept_id,
    person_id,
    days_diff,
    event_date
from vcbo5u4zevent_code_all_events
;
drop table if exists vcbo5u4zevent_code_patient_chosen_before_after_first;
DROP TABLE IF EXISTS vcbo5u4zevent_code_patient_chosen_before_after_first;
CREATE TABLE vcbo5u4zevent_code_patient_chosen_before_after_first (
    anchor_event STRING,
    event_family STRING,
    time_relative STRING,
    concept_id INT64,
    person_id INT64,
    days_diff INT64
);
insert into vcbo5u4zevent_code_patient_chosen_before_after_first (
    anchor_event, event_family, time_relative, concept_id, person_id, days_diff
)
select anchor_event, event_family, time_relative, concept_id, person_id, days_diff
from (
    select
        anchor_event,
        event_family,
        time_relative,
        concept_id,
        person_id,
        days_diff,
        row_number() over (
            partition by anchor_event, event_family, time_relative, concept_id, person_id
            order by DATE_DIFF(IF(SAFE_CAST(event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(event_date  AS STRING)),SAFE_CAST(event_date  AS DATE)), IF(SAFE_CAST(IF(SAFE_CAST('1900-01-01'  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast('1900-01-01'  AS STRING)),SAFE_CAST('1900-01-01'  AS DATE))  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(IF(SAFE_CAST('1900-01-01'  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast('1900-01-01'  AS STRING)),SAFE_CAST('1900-01-01'  AS DATE))  AS STRING)),SAFE_CAST(IF(SAFE_CAST('1900-01-01'  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast('1900-01-01'  AS STRING)),SAFE_CAST('1900-01-01'  AS DATE))  AS DATE)), DAY) asc, event_date asc
        ) as rn
    from vcbo5u4zevent_code_ba_events
) x
where rn = 1
;
drop table if exists vcbo5u4zevent_code_patient_chosen_before_after_closest;
DROP TABLE IF EXISTS vcbo5u4zevent_code_patient_chosen_before_after_closest;
CREATE TABLE vcbo5u4zevent_code_patient_chosen_before_after_closest (
    anchor_event STRING,
    event_family STRING,
    time_relative STRING,
    concept_id INT64,
    person_id INT64,
    days_diff INT64
);
insert into vcbo5u4zevent_code_patient_chosen_before_after_closest (
    anchor_event, event_family, time_relative, concept_id, person_id, days_diff
)
select anchor_event, event_family, time_relative, concept_id, person_id, days_diff
from (
    select
        anchor_event,
        event_family,
        time_relative,
        concept_id,
        person_id,
        days_diff,
        row_number() over (
            partition by anchor_event, event_family, time_relative, concept_id, person_id
            order by abs(days_diff) asc, event_date asc
        ) as rn
    from vcbo5u4zevent_code_ba_events
) x
where rn = 1
;
drop table if exists vcbo5u4zevent_code_timing_before_after_summary;
DROP TABLE IF EXISTS vcbo5u4zevent_code_timing_before_after_summary;
CREATE TABLE vcbo5u4zevent_code_timing_before_after_summary (
    anchor_event STRING,
    event_family STRING,
    time_relative STRING,
    concept_id INT64,
    n_patients_with_code_timing INT64,
    lq_days_first FLOAT64,
    median_days_first FLOAT64,
    uq_days_first FLOAT64,
    lq_days_closest FLOAT64,
    median_days_closest FLOAT64,
    uq_days_closest FLOAT64
);
insert into vcbo5u4zevent_code_timing_before_after_summary (
    anchor_event,
    event_family,
    time_relative,
    concept_id,
    n_patients_with_code_timing,
    lq_days_first,
    median_days_first,
    uq_days_first,
    lq_days_closest,
    median_days_closest,
    uq_days_closest
)
select
    f.anchor_event,
    f.event_family,
    f.time_relative,
    f.concept_id,
    f.n_patients_with_code_timing,
    f.lq_days_first,
    f.median_days_first,
    f.uq_days_first,
    k.lq_days_closest,
    k.median_days_closest,
    k.uq_days_closest
from (
     select anchor_event,
        event_family,
        time_relative,
        concept_id,
        count(*) as n_patients_with_code_timing,
        min(case when 4.0 * rn >= cnt then cast(days_diff  as float64) end) as lq_days_first,
        min(case when 2.0 * rn >= cnt then cast(days_diff  as float64) end) as median_days_first,
        min(case when 4.0 * rn >= 3 * cnt then cast(days_diff  as float64) end) as uq_days_first
     from (
        select anchor_event, event_family, time_relative, concept_id, days_diff,
            row_number() over (partition by anchor_event, event_family, time_relative, concept_id order by days_diff) as rn,
            count(*)     over (partition by anchor_event, event_family, time_relative, concept_id)                    as cnt
        from vcbo5u4zevent_code_patient_chosen_before_after_first
    ) x
     group by  1, 2, 3, 4 ) f
inner join (
     select anchor_event,
        event_family,
        time_relative,
        concept_id,
        min(case when 4.0 * rn >= cnt then cast(days_diff  as float64) end) as lq_days_closest,
        min(case when 2.0 * rn >= cnt then cast(days_diff  as float64) end) as median_days_closest,
        min(case when 4.0 * rn >= 3 * cnt then cast(days_diff  as float64) end) as uq_days_closest
     from (
        select anchor_event, event_family, time_relative, concept_id, days_diff,
            row_number() over (partition by anchor_event, event_family, time_relative, concept_id order by days_diff) as rn,
            count(*)     over (partition by anchor_event, event_family, time_relative, concept_id)                    as cnt
        from vcbo5u4zevent_code_patient_chosen_before_after_closest
    ) x
     group by  1, 2, 3, 4 ) k
  on f.anchor_event = k.anchor_event
 and f.event_family = k.event_family
 and f.time_relative = k.time_relative
 and f.concept_id = k.concept_id
;
------------------------------------------------------------
-- I) PATIENT-LEVEL TABLE
------------------------------------------------------------
drop table if exists vcbo5u4zpatient_char;
DROP TABLE IF EXISTS vcbo5u4zpatient_char;
CREATE TABLE vcbo5u4zpatient_char (
    person_id INT64,
    index_date date,
    n_dx_records INT64,
    n_dx_codes INT64,
    first_other_dx_date date,
    n_other_dx_records INT64,
    n_other_dx_codes INT64,
    first_gen_cancer_date date,
    n_gen_cancer_records INT64,
    n_gen_cancer_codes INT64,
    first_met_date date,
    n_met_records INT64,
    first_l01_date date,
    n_l01_exposures INT64,
    days_dx_to_met INT64,
    days_dx_to_l01 INT64,
    days_dx_to_other_dx INT64,
    days_dx_to_gen_cancer INT64,
    days_met_to_l01 INT64
);
insert into vcbo5u4zpatient_char (
    person_id,
    index_date,
    n_dx_records,
    n_dx_codes,
    first_other_dx_date,
    n_other_dx_records,
    n_other_dx_codes,
    first_gen_cancer_date,
    n_gen_cancer_records,
    n_gen_cancer_codes,
    first_met_date,
    n_met_records,
    first_l01_date,
    n_l01_exposures,
    days_dx_to_met,
    days_dx_to_l01,
    days_dx_to_other_dx,
    days_dx_to_gen_cancer,
    days_met_to_l01
)
select
    c.person_id,
    c.index_date,
    coalesce(cast(dx.n_dx_records as int64), 0),
    coalesce(cast(dx.n_dx_codes as int64), 0),
    odx.first_other_dx_date,
    coalesce(cast(odx.n_other_dx_records as int64), 0),
    coalesce(cast(odx.n_other_dx_codes as int64), 0),
    gdx.first_gen_cancer_date,
    coalesce(cast(gdx.n_gen_cancer_records as int64), 0),
    coalesce(cast(gdx.n_gen_cancer_codes as int64), 0),
    mt.first_met_date,
    coalesce(cast(mt.n_met_records as int64), 0),
    l01.first_l01_date,
    coalesce(cast(l01.n_l01_exposures as int64), 0),
    case when mt.first_met_date is not null then DATE_DIFF(IF(SAFE_CAST(mt.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(mt.first_met_date  AS STRING)),SAFE_CAST(mt.first_met_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) end as days_dx_to_met,
    case when l01.first_l01_date is not null then DATE_DIFF(IF(SAFE_CAST(l01.first_l01_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(l01.first_l01_date  AS STRING)),SAFE_CAST(l01.first_l01_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) end as days_dx_to_l01,
    case when odx.first_other_dx_date is not null then DATE_DIFF(IF(SAFE_CAST(odx.first_other_dx_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(odx.first_other_dx_date  AS STRING)),SAFE_CAST(odx.first_other_dx_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) end as days_dx_to_other_dx,
    case when gdx.first_gen_cancer_date is not null then DATE_DIFF(IF(SAFE_CAST(gdx.first_gen_cancer_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(gdx.first_gen_cancer_date  AS STRING)),SAFE_CAST(gdx.first_gen_cancer_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) end as days_dx_to_gen_cancer,
    case when mt.first_met_date is not null and l01.first_l01_date is not null then DATE_DIFF(IF(SAFE_CAST(l01.first_l01_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(l01.first_l01_date  AS STRING)),SAFE_CAST(l01.first_l01_date  AS DATE)), IF(SAFE_CAST(mt.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(mt.first_met_date  AS STRING)),SAFE_CAST(mt.first_met_date  AS DATE)), DAY) end as days_met_to_l01
from vcbo5u4zcohort c
left join vcbo5u4zdx_summary dx
       on c.person_id = dx.person_id
left join vcbo5u4zother_dx_summary odx
       on c.person_id = odx.person_id
left join vcbo5u4zgen_cancer_summary gdx
       on c.person_id = gdx.person_id
left join vcbo5u4zmet_summary mt
       on c.person_id = mt.person_id
left join vcbo5u4zl01_summary l01
       on c.person_id = l01.person_id
;
------------------------------------------------------------
-- J) FULL CROSSWISE TIMING PAIRS
------------------------------------------------------------
drop table if exists vcbo5u4zpatient_timing_pairs;
DROP TABLE IF EXISTS vcbo5u4zpatient_timing_pairs;
CREATE TABLE vcbo5u4zpatient_timing_pairs (
    person_id INT64,
    from_event STRING,
    to_event STRING,
    days_diff INT64
);
INSERT INTO vcbo5u4zpatient_timing_pairs (person_id, from_event, to_event, days_diff)
 WITH events as (
    select person_id, 'DX' as event_name, index_date as event_date from vcbo5u4zpatient_char
    union all
    select person_id, 'ODX', first_other_dx_date from vcbo5u4zpatient_char
    union all
    select person_id, 'GDX', first_gen_cancer_date from vcbo5u4zpatient_char
    union all
    select person_id, 'MET', first_met_date from vcbo5u4zpatient_char
    union all
    select person_id, 'L01', first_l01_date from vcbo5u4zpatient_char
)
 SELECT e1.person_id,
    e1.event_name as from_event,
    e2.event_name as to_event,
    DATE_DIFF(IF(SAFE_CAST(e2.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e2.event_date  AS STRING)),SAFE_CAST(e2.event_date  AS DATE)), IF(SAFE_CAST(e1.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e1.event_date  AS STRING)),SAFE_CAST(e1.event_date  AS DATE)), DAY) as days_diff
from events e1
join events e2
  on e1.person_id = e2.person_id
 and e1.event_name <> e2.event_name
where e1.event_date is not null
  and e2.event_date is not null
;
drop table if exists vcbo5u4ztiming_pair_summary;
DROP TABLE IF EXISTS vcbo5u4ztiming_pair_summary;
CREATE TABLE vcbo5u4ztiming_pair_summary (
    from_event STRING,
    to_event STRING,
    n_patients_with_pair INT64,
    p05_days FLOAT64,
    p10_days FLOAT64,
    p20_days FLOAT64,
    p25_days FLOAT64,
    p30_days FLOAT64,
    p40_days FLOAT64,
    p50_days FLOAT64,
    p60_days FLOAT64,
    p70_days FLOAT64,
    p75_days FLOAT64,
    p80_days FLOAT64,
    p90_days FLOAT64,
    p95_days FLOAT64
);
insert into vcbo5u4ztiming_pair_summary (
    from_event,
    to_event,
    n_patients_with_pair,
    p05_days,
    p10_days,
    p20_days,
    p25_days,
    p30_days,
    p40_days,
    p50_days,
    p60_days,
    p70_days,
    p75_days,
    p80_days,
    p90_days,
    p95_days
)
 select from_event,
    to_event,
    count(*) as n_patients_with_pair,
    min(case when 20.0 * rn >= cnt       then cast(days_diff  as float64) end) as p05_days,
    min(case when 10.0 * rn >= cnt       then cast(days_diff  as float64) end) as p10_days,
    min(case when  5.0 * rn >= cnt       then cast(days_diff  as float64) end) as p20_days,
    min(case when  4.0 * rn >= cnt       then cast(days_diff  as float64) end) as p25_days,
    min(case when 10.0 * rn >= 3 * cnt  then cast(days_diff  as float64) end) as p30_days,
    min(case when  5.0 * rn >= 2 * cnt  then cast(days_diff  as float64) end) as p40_days,
    min(case when  2.0 * rn >= cnt       then cast(days_diff  as float64) end) as p50_days,
    min(case when  5.0 * rn >= 3 * cnt  then cast(days_diff  as float64) end) as p60_days,
    min(case when 10.0 * rn >= 7 * cnt  then cast(days_diff  as float64) end) as p70_days,
    min(case when  4.0 * rn >= 3 * cnt  then cast(days_diff  as float64) end) as p75_days,
    min(case when  5.0 * rn >= 4 * cnt  then cast(days_diff  as float64) end) as p80_days,
    min(case when 10.0 * rn >= 9 * cnt  then cast(days_diff  as float64) end) as p90_days,
    min(case when 20.0 * rn >= 19 * cnt then cast(days_diff  as float64) end) as p95_days
 from (
    select from_event, to_event, days_diff,
        row_number() over (partition by from_event, to_event order by days_diff) as rn,
        count(*)     over (partition by from_event, to_event)                    as cnt
    from vcbo5u4zpatient_timing_pairs
) x
 group by  1, 2 ;
drop table if exists vcbo5u4zall_events_for_pairs;
DROP TABLE IF EXISTS vcbo5u4zall_events_for_pairs;
CREATE TABLE vcbo5u4zall_events_for_pairs (
    person_id INT64,
    event_family STRING,
    event_date date
);
insert into vcbo5u4zall_events_for_pairs (person_id, event_family, event_date)
select person_id, 'DX', event_date from vcbo5u4zdx_events
union all
select person_id, 'ODX', event_date from vcbo5u4zother_dx_events
union all
select person_id, 'GDX', event_date from vcbo5u4zgen_cancer_events
union all
select person_id, 'MET', event_date from vcbo5u4zmet_events
union all
select person_id, 'L01', event_date from vcbo5u4zl01_events
;
drop table if exists vcbo5u4zfirst_event_dates;
DROP TABLE IF EXISTS vcbo5u4zfirst_event_dates;
CREATE TABLE vcbo5u4zfirst_event_dates (
    person_id INT64,
    from_event STRING,
    from_first_date date
);
insert into vcbo5u4zfirst_event_dates (person_id, from_event, from_first_date)
select person_id, 'DX', index_date from vcbo5u4zpatient_char
union all
select person_id, 'ODX', first_other_dx_date from vcbo5u4zpatient_char where first_other_dx_date is not null
union all
select person_id, 'GDX', first_gen_cancer_date from vcbo5u4zpatient_char where first_gen_cancer_date is not null
union all
select person_id, 'MET', first_met_date from vcbo5u4zpatient_char where first_met_date is not null
union all
select person_id, 'L01', first_l01_date from vcbo5u4zpatient_char where first_l01_date is not null
;
drop table if exists vcbo5u4zpatient_timing_pairs_first_to_closest;
DROP TABLE IF EXISTS vcbo5u4zpatient_timing_pairs_first_to_closest;
CREATE TABLE vcbo5u4zpatient_timing_pairs_first_to_closest (
    person_id INT64,
    from_event STRING,
    to_event STRING,
    days_diff INT64
);
INSERT INTO vcbo5u4zpatient_timing_pairs_first_to_closest (person_id, from_event, to_event, days_diff)
 WITH ranked as (
    select
        f.person_id,
        f.from_event,
        a.event_family as to_event,
        DATE_DIFF(IF(SAFE_CAST(a.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(a.event_date  AS STRING)),SAFE_CAST(a.event_date  AS DATE)), IF(SAFE_CAST(f.from_first_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(f.from_first_date  AS STRING)),SAFE_CAST(f.from_first_date  AS DATE)), DAY) as days_diff,
        row_number() over (
            partition by f.person_id, f.from_event, a.event_family
            order by abs(DATE_DIFF(IF(SAFE_CAST(a.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(a.event_date  AS STRING)),SAFE_CAST(a.event_date  AS DATE)), IF(SAFE_CAST(f.from_first_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(f.from_first_date  AS STRING)),SAFE_CAST(f.from_first_date  AS DATE)), DAY)), a.event_date
        ) as rn
    from vcbo5u4zfirst_event_dates f
    join vcbo5u4zall_events_for_pairs a
      on f.person_id = a.person_id
     and f.from_event <> a.event_family
)
 SELECT person_id,
    from_event,
    to_event,
    days_diff
from ranked
where rn = 1
;
drop table if exists vcbo5u4ztiming_pair_summary_first_to_closest;
DROP TABLE IF EXISTS vcbo5u4ztiming_pair_summary_first_to_closest;
CREATE TABLE vcbo5u4ztiming_pair_summary_first_to_closest (
    from_event STRING,
    to_event STRING,
    n_patients_with_pair INT64,
    p05_days FLOAT64,
    p10_days FLOAT64,
    p20_days FLOAT64,
    p25_days FLOAT64,
    p30_days FLOAT64,
    p40_days FLOAT64,
    p50_days FLOAT64,
    p60_days FLOAT64,
    p70_days FLOAT64,
    p75_days FLOAT64,
    p80_days FLOAT64,
    p90_days FLOAT64,
    p95_days FLOAT64
);
insert into vcbo5u4ztiming_pair_summary_first_to_closest (
    from_event,
    to_event,
    n_patients_with_pair,
    p05_days,
    p10_days,
    p20_days,
    p25_days,
    p30_days,
    p40_days,
    p50_days,
    p60_days,
    p70_days,
    p75_days,
    p80_days,
    p90_days,
    p95_days
)
 select from_event,
    to_event,
    count(*) as n_patients_with_pair,
    min(case when 20.0 * rn >= cnt       then cast(days_diff  as float64) end) as p05_days,
    min(case when 10.0 * rn >= cnt       then cast(days_diff  as float64) end) as p10_days,
    min(case when  5.0 * rn >= cnt       then cast(days_diff  as float64) end) as p20_days,
    min(case when  4.0 * rn >= cnt       then cast(days_diff  as float64) end) as p25_days,
    min(case when 10.0 * rn >= 3 * cnt  then cast(days_diff  as float64) end) as p30_days,
    min(case when  5.0 * rn >= 2 * cnt  then cast(days_diff  as float64) end) as p40_days,
    min(case when  2.0 * rn >= cnt       then cast(days_diff  as float64) end) as p50_days,
    min(case when  5.0 * rn >= 3 * cnt  then cast(days_diff  as float64) end) as p60_days,
    min(case when 10.0 * rn >= 7 * cnt  then cast(days_diff  as float64) end) as p70_days,
    min(case when  4.0 * rn >= 3 * cnt  then cast(days_diff  as float64) end) as p75_days,
    min(case when  5.0 * rn >= 4 * cnt  then cast(days_diff  as float64) end) as p80_days,
    min(case when 10.0 * rn >= 9 * cnt  then cast(days_diff  as float64) end) as p90_days,
    min(case when 20.0 * rn >= 19 * cnt then cast(days_diff  as float64) end) as p95_days
 from (
    select from_event, to_event, days_diff,
        row_number() over (partition by from_event, to_event order by days_diff) as rn,
        count(*)     over (partition by from_event, to_event)                    as cnt
    from vcbo5u4zpatient_timing_pairs_first_to_closest
) x
 group by  1, 2 ;
drop table if exists vcbo5u4zpatient_timing_pairs_first_to_closest_before;
DROP TABLE IF EXISTS vcbo5u4zpatient_timing_pairs_first_to_closest_before;
CREATE TABLE vcbo5u4zpatient_timing_pairs_first_to_closest_before (
    person_id INT64,
    from_event STRING,
    to_event STRING,
    days_diff INT64
);
INSERT INTO vcbo5u4zpatient_timing_pairs_first_to_closest_before (person_id, from_event, to_event, days_diff)
 WITH ranked_before as (
    select
        f.person_id,
        f.from_event,
        a.event_family as to_event,
        DATE_DIFF(IF(SAFE_CAST(a.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(a.event_date  AS STRING)),SAFE_CAST(a.event_date  AS DATE)), IF(SAFE_CAST(f.from_first_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(f.from_first_date  AS STRING)),SAFE_CAST(f.from_first_date  AS DATE)), DAY) as days_diff,
        row_number() over (
            partition by f.person_id, f.from_event, a.event_family
            order by abs(DATE_DIFF(IF(SAFE_CAST(a.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(a.event_date  AS STRING)),SAFE_CAST(a.event_date  AS DATE)), IF(SAFE_CAST(f.from_first_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(f.from_first_date  AS STRING)),SAFE_CAST(f.from_first_date  AS DATE)), DAY)), a.event_date desc
        ) as rn
    from vcbo5u4zfirst_event_dates f
    join vcbo5u4zall_events_for_pairs a
      on f.person_id = a.person_id
     and f.from_event <> a.event_family
    where DATE_DIFF(IF(SAFE_CAST(a.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(a.event_date  AS STRING)),SAFE_CAST(a.event_date  AS DATE)), IF(SAFE_CAST(f.from_first_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(f.from_first_date  AS STRING)),SAFE_CAST(f.from_first_date  AS DATE)), DAY) < 0
)
 SELECT person_id,
    from_event,
    to_event,
    days_diff
from ranked_before
where rn = 1
;
drop table if exists vcbo5u4ztiming_pair_summary_first_to_closest_before;
DROP TABLE IF EXISTS vcbo5u4ztiming_pair_summary_first_to_closest_before;
CREATE TABLE vcbo5u4ztiming_pair_summary_first_to_closest_before (
    from_event STRING,
    to_event STRING,
    n_patients_with_pair INT64,
    p05_days FLOAT64,
    p10_days FLOAT64,
    p20_days FLOAT64,
    p25_days FLOAT64,
    p30_days FLOAT64,
    p40_days FLOAT64,
    p50_days FLOAT64,
    p60_days FLOAT64,
    p70_days FLOAT64,
    p75_days FLOAT64,
    p80_days FLOAT64,
    p90_days FLOAT64,
    p95_days FLOAT64
);
insert into vcbo5u4ztiming_pair_summary_first_to_closest_before (
    from_event,
    to_event,
    n_patients_with_pair,
    p05_days,
    p10_days,
    p20_days,
    p25_days,
    p30_days,
    p40_days,
    p50_days,
    p60_days,
    p70_days,
    p75_days,
    p80_days,
    p90_days,
    p95_days
)
 select from_event,
    to_event,
    count(*) as n_patients_with_pair,
    min(case when 20.0 * rn >= cnt       then cast(days_diff  as float64) end) as p05_days,
    min(case when 10.0 * rn >= cnt       then cast(days_diff  as float64) end) as p10_days,
    min(case when  5.0 * rn >= cnt       then cast(days_diff  as float64) end) as p20_days,
    min(case when  4.0 * rn >= cnt       then cast(days_diff  as float64) end) as p25_days,
    min(case when 10.0 * rn >= 3 * cnt  then cast(days_diff  as float64) end) as p30_days,
    min(case when  5.0 * rn >= 2 * cnt  then cast(days_diff  as float64) end) as p40_days,
    min(case when  2.0 * rn >= cnt       then cast(days_diff  as float64) end) as p50_days,
    min(case when  5.0 * rn >= 3 * cnt  then cast(days_diff  as float64) end) as p60_days,
    min(case when 10.0 * rn >= 7 * cnt  then cast(days_diff  as float64) end) as p70_days,
    min(case when  4.0 * rn >= 3 * cnt  then cast(days_diff  as float64) end) as p75_days,
    min(case when  5.0 * rn >= 4 * cnt  then cast(days_diff  as float64) end) as p80_days,
    min(case when 10.0 * rn >= 9 * cnt  then cast(days_diff  as float64) end) as p90_days,
    min(case when 20.0 * rn >= 19 * cnt then cast(days_diff  as float64) end) as p95_days
 from (
    select from_event, to_event, days_diff,
        row_number() over (partition by from_event, to_event order by days_diff) as rn,
        count(*)     over (partition by from_event, to_event)                    as cnt
    from vcbo5u4zpatient_timing_pairs_first_to_closest_before
) x
 group by  1, 2 ;
drop table if exists vcbo5u4zpatient_timing_pairs_first_to_closest_after;
DROP TABLE IF EXISTS vcbo5u4zpatient_timing_pairs_first_to_closest_after;
CREATE TABLE vcbo5u4zpatient_timing_pairs_first_to_closest_after (
    person_id INT64,
    from_event STRING,
    to_event STRING,
    days_diff INT64
);
INSERT INTO vcbo5u4zpatient_timing_pairs_first_to_closest_after (person_id, from_event, to_event, days_diff)
 WITH ranked_after as (
    select
        f.person_id,
        f.from_event,
        a.event_family as to_event,
        DATE_DIFF(IF(SAFE_CAST(a.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(a.event_date  AS STRING)),SAFE_CAST(a.event_date  AS DATE)), IF(SAFE_CAST(f.from_first_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(f.from_first_date  AS STRING)),SAFE_CAST(f.from_first_date  AS DATE)), DAY) as days_diff,
        row_number() over (
            partition by f.person_id, f.from_event, a.event_family
            order by DATE_DIFF(IF(SAFE_CAST(a.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(a.event_date  AS STRING)),SAFE_CAST(a.event_date  AS DATE)), IF(SAFE_CAST(f.from_first_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(f.from_first_date  AS STRING)),SAFE_CAST(f.from_first_date  AS DATE)), DAY), a.event_date
        ) as rn
    from vcbo5u4zfirst_event_dates f
    join vcbo5u4zall_events_for_pairs a
      on f.person_id = a.person_id
     and f.from_event <> a.event_family
    where DATE_DIFF(IF(SAFE_CAST(a.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(a.event_date  AS STRING)),SAFE_CAST(a.event_date  AS DATE)), IF(SAFE_CAST(f.from_first_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(f.from_first_date  AS STRING)),SAFE_CAST(f.from_first_date  AS DATE)), DAY) >= 0
)
 SELECT person_id,
    from_event,
    to_event,
    days_diff
from ranked_after
where rn = 1
;
drop table if exists vcbo5u4ztiming_pair_summary_first_to_closest_after;
DROP TABLE IF EXISTS vcbo5u4ztiming_pair_summary_first_to_closest_after;
CREATE TABLE vcbo5u4ztiming_pair_summary_first_to_closest_after (
    from_event STRING,
    to_event STRING,
    n_patients_with_pair INT64,
    p05_days FLOAT64,
    p10_days FLOAT64,
    p20_days FLOAT64,
    p25_days FLOAT64,
    p30_days FLOAT64,
    p40_days FLOAT64,
    p50_days FLOAT64,
    p60_days FLOAT64,
    p70_days FLOAT64,
    p75_days FLOAT64,
    p80_days FLOAT64,
    p90_days FLOAT64,
    p95_days FLOAT64
);
insert into vcbo5u4ztiming_pair_summary_first_to_closest_after (
    from_event,
    to_event,
    n_patients_with_pair,
    p05_days,
    p10_days,
    p20_days,
    p25_days,
    p30_days,
    p40_days,
    p50_days,
    p60_days,
    p70_days,
    p75_days,
    p80_days,
    p90_days,
    p95_days
)
 select from_event,
    to_event,
    count(*) as n_patients_with_pair,
    min(case when 20.0 * rn >= cnt       then cast(days_diff  as float64) end) as p05_days,
    min(case when 10.0 * rn >= cnt       then cast(days_diff  as float64) end) as p10_days,
    min(case when  5.0 * rn >= cnt       then cast(days_diff  as float64) end) as p20_days,
    min(case when  4.0 * rn >= cnt       then cast(days_diff  as float64) end) as p25_days,
    min(case when 10.0 * rn >= 3 * cnt  then cast(days_diff  as float64) end) as p30_days,
    min(case when  5.0 * rn >= 2 * cnt  then cast(days_diff  as float64) end) as p40_days,
    min(case when  2.0 * rn >= cnt       then cast(days_diff  as float64) end) as p50_days,
    min(case when  5.0 * rn >= 3 * cnt  then cast(days_diff  as float64) end) as p60_days,
    min(case when 10.0 * rn >= 7 * cnt  then cast(days_diff  as float64) end) as p70_days,
    min(case when  4.0 * rn >= 3 * cnt  then cast(days_diff  as float64) end) as p75_days,
    min(case when  5.0 * rn >= 4 * cnt  then cast(days_diff  as float64) end) as p80_days,
    min(case when 10.0 * rn >= 9 * cnt  then cast(days_diff  as float64) end) as p90_days,
    min(case when 20.0 * rn >= 19 * cnt then cast(days_diff  as float64) end) as p95_days
 from (
    select from_event, to_event, days_diff,
        row_number() over (partition by from_event, to_event order by days_diff) as rn,
        count(*)     over (partition by from_event, to_event)                    as cnt
    from vcbo5u4zpatient_timing_pairs_first_to_closest_after
) x
 group by  1, 2 ;
drop table if exists vcbo5u4zevent_presence;
DROP TABLE IF EXISTS vcbo5u4zevent_presence;
CREATE TABLE vcbo5u4zevent_presence (
    person_id INT64,
    has_dx INT64,
    has_odx INT64,
    has_gdx INT64,
    has_met INT64,
    has_l01 INT64
);
insert into vcbo5u4zevent_presence (
    person_id, has_dx, has_odx, has_gdx, has_met, has_l01
)
select
    person_id,
    1,
    case when first_other_dx_date is not null then 1 else 0 end,
    case when first_gen_cancer_date is not null then 1 else 0 end,
    case when first_met_date is not null then 1 else 0 end,
    case when first_l01_date is not null then 1 else 0 end
from vcbo5u4zpatient_char
;
------------------------------------------------------------
-- J-bis) DEATH TIMING FROM INDEX AND FIRST_MET ANCHORS
------------------------------------------------------------
-- Pre-compute each cohort patient's earliest death date and whether it
-- falls within any of their observation periods.
drop table if exists vcbo5u4zdeath_obs_status;
DROP TABLE IF EXISTS vcbo5u4zdeath_obs_status;
CREATE TABLE vcbo5u4zdeath_obs_status (
    person_id INT64,
    death_date date,
    death_in_obs smallint
);
insert into vcbo5u4zdeath_obs_status (person_id, death_date, death_in_obs)
select
    d.person_id,
    d.death_date,
    case when exists (
        select 1
        from @cdm_database_schema.observation_period op
        where op.person_id = d.person_id
          and d.death_date between op.observation_period_start_date
                               and op.observation_period_end_date
    ) then 1 else 0 end
from (
     select person_id, min(death_date) as death_date
     from @cdm_database_schema.death
     group by  1 ) d
where d.person_id in (select person_id from vcbo5u4zcohort)
;
drop table if exists vcbo5u4zdeath_index_long;
DROP TABLE IF EXISTS vcbo5u4zdeath_index_long;
CREATE TABLE vcbo5u4zdeath_index_long (
    prevalence_year STRING,
    days_to_death INT64
);
insert into vcbo5u4zdeath_index_long (prevalence_year, days_to_death)
select 'OVERALL', DATE_DIFF(IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY)
from vcbo5u4zcohort c
inner join vcbo5u4zdeath_obs_status dos on dos.person_id = c.person_id
where dos.death_date >= c.index_date
union all
select cast(EXTRACT(YEAR from c.index_date) as STRING), DATE_DIFF(IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY)
from vcbo5u4zcohort c
inner join vcbo5u4zdeath_obs_status dos on dos.person_id = c.person_id
where dos.death_date >= c.index_date
;
drop table if exists vcbo5u4zdeath_first_met_long;
DROP TABLE IF EXISTS vcbo5u4zdeath_first_met_long;
CREATE TABLE vcbo5u4zdeath_first_met_long (
    prevalence_year STRING,
    days_to_death INT64
);
insert into vcbo5u4zdeath_first_met_long (prevalence_year, days_to_death)
select 'OVERALL', DATE_DIFF(IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY)
from vcbo5u4zcohort c
inner join vcbo5u4zmet_summary ms on c.person_id = ms.person_id and ms.first_met_date is not null
inner join vcbo5u4zdeath_obs_status dos on dos.person_id = c.person_id
where dos.death_date >= ms.first_met_date
union all
select cast(EXTRACT(YEAR from ms.first_met_date) as STRING), DATE_DIFF(IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY)
from vcbo5u4zcohort c
inner join vcbo5u4zmet_summary ms on c.person_id = ms.person_id and ms.first_met_date is not null
inner join vcbo5u4zdeath_obs_status dos on dos.person_id = c.person_id
where dos.death_date >= ms.first_met_date
;
drop table if exists vcbo5u4zdeath_stratum_counts;
DROP TABLE IF EXISTS vcbo5u4zdeath_stratum_counts;
CREATE TABLE vcbo5u4zdeath_stratum_counts (
    prevalence_year STRING,
    anchor_event STRING,
    n_patients INT64,
    n_deaths INT64,
    n_deaths_in_obs INT64,
    n_deaths_out_obs INT64
);
insert into vcbo5u4zdeath_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths, n_deaths_in_obs, n_deaths_out_obs)
 select case
        when grouping(EXTRACT(YEAR from c.index_date)) = 1 then 'OVERALL'
        else cast(EXTRACT(YEAR from c.index_date) as STRING)
    end,
    'INDEX',
    count(*),
    sum(case when dos.death_date is not null and dos.death_date >= c.index_date then 1 else 0 end),
    sum(case when dos.death_date is not null and dos.death_date >= c.index_date and dos.death_in_obs = 1 then 1 else 0 end),
    sum(case when dos.death_date is not null and dos.death_date >= c.index_date and dos.death_in_obs = 0 then 1 else 0 end)
 from vcbo5u4zcohort c
left join vcbo5u4zdeath_obs_status dos on dos.person_id = c.person_id
 group by  grouping sets ((), (EXTRACT(YEAR from c.index_date)))
 ;
insert into vcbo5u4zdeath_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths, n_deaths_in_obs, n_deaths_out_obs)
 select case
        when grouping(EXTRACT(YEAR from ms.first_met_date)) = 1 then 'OVERALL'
        else cast(EXTRACT(YEAR from ms.first_met_date) as STRING)
    end,
    'FIRST_MET',
    count(*),
    sum(case when dos.death_date is not null and dos.death_date >= ms.first_met_date then 1 else 0 end),
    sum(case when dos.death_date is not null and dos.death_date >= ms.first_met_date and dos.death_in_obs = 1 then 1 else 0 end),
    sum(case when dos.death_date is not null and dos.death_date >= ms.first_met_date and dos.death_in_obs = 0 then 1 else 0 end)
 from vcbo5u4zcohort c
inner join vcbo5u4zmet_summary ms on c.person_id = ms.person_id and ms.first_met_date is not null
left join vcbo5u4zdeath_obs_status dos on dos.person_id = c.person_id
 group by  grouping sets ((), (EXTRACT(YEAR from ms.first_met_date)))
 ;
drop table if exists vcbo5u4zdeath_timing_long;
DROP TABLE IF EXISTS vcbo5u4zdeath_timing_long;
CREATE TABLE vcbo5u4zdeath_timing_long (
    prevalence_year STRING,
    anchor_event STRING,
    days_to_death INT64
);
insert into vcbo5u4zdeath_timing_long (prevalence_year, anchor_event, days_to_death)
select prevalence_year, 'INDEX', days_to_death from vcbo5u4zdeath_index_long
union all
select prevalence_year, 'FIRST_MET', days_to_death from vcbo5u4zdeath_first_met_long
;
drop table if exists vcbo5u4zdeath_timing_quantiles;
DROP TABLE IF EXISTS vcbo5u4zdeath_timing_quantiles;
CREATE TABLE vcbo5u4zdeath_timing_quantiles (
    prevalence_year STRING,
    anchor_event STRING,
    lq_days FLOAT64,
    median_days FLOAT64,
    uq_days FLOAT64
);
insert into vcbo5u4zdeath_timing_quantiles (
    prevalence_year,
    anchor_event,
    lq_days,
    median_days,
    uq_days
)
 select prevalence_year,
    anchor_event,
    min(case when 4.0 * rn >= cnt then cast(days_to_death  as float64) end) as lq_days,
    min(case when 2.0 * rn >= cnt then cast(days_to_death  as float64) end) as median_days,
    min(case when 4.0 * rn >= 3 * cnt then cast(days_to_death  as float64) end) as uq_days
 from (
    select prevalence_year, anchor_event, days_to_death,
        row_number() over (partition by prevalence_year, anchor_event order by days_to_death) as rn,
        count(*)     over (partition by prevalence_year, anchor_event)                        as cnt
    from vcbo5u4zdeath_timing_long
) x
 group by  1, 2 ;
-- Follow-up duration from anchor date to last observation period end,
-- for all patients with at least one observation period covering or after anchor.
drop table if exists vcbo5u4zfollowup_long;
DROP TABLE IF EXISTS vcbo5u4zfollowup_long;
CREATE TABLE vcbo5u4zfollowup_long (
    prevalence_year STRING,
    anchor_event STRING,
    followup_days INT64
);
insert into vcbo5u4zfollowup_long (prevalence_year, anchor_event, followup_days)
 select 'OVERALL', 'INDEX',
       DATE_DIFF(IF(SAFE_CAST(max(op.observation_period_end_date)  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(max(op.observation_period_end_date)  AS STRING)),SAFE_CAST(max(op.observation_period_end_date)  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY)
 from vcbo5u4zcohort c
inner join @cdm_database_schema.observation_period op
  on op.person_id = c.person_id
 and op.observation_period_end_date >= c.index_date
 group by  c.person_id, c.index_date
union all
 select cast(EXTRACT(YEAR from c.index_date) as STRING), 2, DATE_DIFF(IF(SAFE_CAST(max(op.observation_period_end_date)  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(max(op.observation_period_end_date)  AS STRING)),SAFE_CAST(max(op.observation_period_end_date)  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY)
 from vcbo5u4zcohort c
inner join @cdm_database_schema.observation_period op
  on op.person_id = c.person_id
 and op.observation_period_end_date >= c.index_date
 group by  c.person_id, c.index_date, EXTRACT(YEAR from c.index_date)
union all
 select 'OVERALL', 'FIRST_MET', DATE_DIFF(IF(SAFE_CAST(max(op.observation_period_end_date)  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(max(op.observation_period_end_date)  AS STRING)),SAFE_CAST(max(op.observation_period_end_date)  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY)
 from vcbo5u4zcohort c
inner join vcbo5u4zmet_summary ms on c.person_id = ms.person_id and ms.first_met_date is not null
inner join @cdm_database_schema.observation_period op
  on op.person_id = c.person_id
 and op.observation_period_end_date >= ms.first_met_date
 group by  c.person_id, ms.first_met_date
union all
 select cast(EXTRACT(YEAR from ms.first_met_date) as STRING), 2, DATE_DIFF(IF(SAFE_CAST(max(op.observation_period_end_date)  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(max(op.observation_period_end_date)  AS STRING)),SAFE_CAST(max(op.observation_period_end_date)  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY)
 from vcbo5u4zcohort c
inner join vcbo5u4zmet_summary ms on c.person_id = ms.person_id and ms.first_met_date is not null
inner join @cdm_database_schema.observation_period op
  on op.person_id = c.person_id
 and op.observation_period_end_date >= ms.first_met_date
 group by  c.person_id, ms.first_met_date, 1 ;
drop table if exists vcbo5u4zfollowup_quantiles;
DROP TABLE IF EXISTS vcbo5u4zfollowup_quantiles;
CREATE TABLE vcbo5u4zfollowup_quantiles (
    prevalence_year STRING,
    anchor_event STRING,
    lq_followup_days FLOAT64,
    median_followup_days FLOAT64,
    uq_followup_days FLOAT64
);
insert into vcbo5u4zfollowup_quantiles (
    prevalence_year,
    anchor_event,
    lq_followup_days,
    median_followup_days,
    uq_followup_days
)
 select prevalence_year,
    anchor_event,
    min(case when 4.0 * rn >= cnt then cast(followup_days  as float64) end) as lq_followup_days,
    min(case when 2.0 * rn >= cnt then cast(followup_days  as float64) end) as median_followup_days,
    min(case when 4.0 * rn >= 3 * cnt then cast(followup_days  as float64) end) as uq_followup_days
 from (
    select prevalence_year, anchor_event, followup_days,
        row_number() over (partition by prevalence_year, anchor_event order by followup_days) as rn,
        count(*)     over (partition by prevalence_year, anchor_event)                        as cnt
    from vcbo5u4zfollowup_long
) x
 group by  1, 2 ;
------------------------------------------------------------
-- L) L01 CONSECUTIVE GAP TABLES (used by chunks 11 and 12)
------------------------------------------------------------
-- Deduplicated L01 event days per patient (one row per patient-day)
drop table if exists vcbo5u4zl01_event_days;
DROP TABLE IF EXISTS vcbo5u4zl01_event_days;
CREATE TABLE vcbo5u4zl01_event_days (
    person_id  INT64,
    event_day  date
);
insert into vcbo5u4zl01_event_days (person_id, event_day)
select distinct person_id, event_date
from vcbo5u4zl01_events
where person_id in (select person_id from vcbo5u4zcohort)
;
-- Consecutive gaps between L01 event days per patient
drop table if exists vcbo5u4zl01_consecutive_gaps;
DROP TABLE IF EXISTS vcbo5u4zl01_consecutive_gaps;
CREATE TABLE vcbo5u4zl01_consecutive_gaps (
    person_id  INT64,
    subgroup   STRING,
    gap_days   INT64
);
INSERT INTO vcbo5u4zl01_consecutive_gaps (person_id, subgroup, gap_days)
 WITH ranked as (
    select
        e.person_id,
        e.event_day,
        lead(e.event_day) over (partition by e.person_id order by e.event_day) as next_day
    from vcbo5u4zl01_event_days e
),
gaps as (
    select
        person_id,
        DATE_DIFF(IF(SAFE_CAST(next_day  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(next_day  AS STRING)),SAFE_CAST(next_day  AS DATE)), IF(SAFE_CAST(event_day  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(event_day  AS STRING)),SAFE_CAST(event_day  AS DATE)), DAY) as gap_days
    from ranked
    where next_day is not null
)
 SELECT g.person_id, 'ALL_L01', g.gap_days from gaps g
union all
select g.person_id, 'MET_L01', g.gap_days
from gaps g
join vcbo5u4zmet_summary ms on g.person_id = ms.person_id and ms.first_met_date is not null
;
-- Max gap per patient (one row per patient; used for MAX-gap subgroups in chunks 11<U+2013>12)
insert into vcbo5u4zl01_consecutive_gaps (person_id, subgroup, gap_days)
 select person_id, 'ALL_L01_MAX', max(gap_days)
 from vcbo5u4zl01_consecutive_gaps
where subgroup = 'ALL_L01'
 group by  person_id
union all
 select person_id, 'MET_L01_MAX', max(gap_days)
 from vcbo5u4zl01_consecutive_gaps
where subgroup = 'MET_L01'
 group by  1 ;
------------------------------------------------------------
-- K) FINAL SELECTS (export to CSV from SQL client)
------------------------------------------------------------
-- 0b) Cohort attrition: patients with any qualifying DX vs those with a DX
--     that falls within an observation period (the study-eligible subset).
--     The difference is the number excluded by the obs-period filter.
select
    sum(case when stage = 'dx_any'    then n_patients else 0 end) as n_dx_any,
    sum(case when stage = 'dx_in_obs' then n_patients else 0 end) as n_dx_in_obs,
    sum(case when stage = 'dx_any'    then n_patients else 0 end)
    - sum(case when stage = 'dx_in_obs' then n_patients else 0 end)  as n_excluded_no_obs_dx
from vcbo5u4zcohort_attrition
;
-- 1) Population prevalence
with base as (
     select case
            when grouping(EXTRACT(YEAR from index_date)) = 1 then 'OVERALL'
            else cast(EXTRACT(YEAR from index_date) as STRING)
        end as prevalence_year,
        count(*) as n_patients,
        sum(case when first_other_dx_date is not null then 1 else 0 end) as n_with_other_dx,
        sum(case when first_gen_cancer_date is not null then 1 else 0 end) as n_with_gen_cancer_dx,
        sum(case when first_met_date is not null then 1 else 0 end) as n_with_met,
        sum(case when first_l01_date is not null then 1 else 0 end) as n_with_l01
     from vcbo5u4zpatient_char
     group by  grouping sets (
        (),
        (EXTRACT(YEAR from index_date))
    )
 )
 select prevalence_year,
    case when n_patients <= @min_cell_count then -@min_cell_count else n_patients end as n_dx,
    case
        when n_patients <= @min_cell_count then -@min_cell_count
        when n_with_other_dx between 1 and @min_cell_count then -@min_cell_count
        else n_with_other_dx
    end as n_odx,
    case
        when n_patients <= @min_cell_count then -@min_cell_count
        when n_with_gen_cancer_dx between 1 and @min_cell_count then -@min_cell_count
        else n_with_gen_cancer_dx
    end as n_gdx,
    case
        when n_patients <= @min_cell_count then -@min_cell_count
        when n_with_met between 1 and @min_cell_count then -@min_cell_count
        else n_with_met
    end as n_met,
    case
        when n_patients <= @min_cell_count then -@min_cell_count
        when n_with_l01 between 1 and @min_cell_count then -@min_cell_count
        else n_with_l01
    end as n_l01
 from base
 order by  case when prevalence_year = 'OVERALL' then 0 else 1 end, case when prevalence_year = 'OVERALL' then null else cast(prevalence_year  as int64) end
 ;
-- 2) Code-count summary: all three time windows combined (small-cell sentinel)
--    time_window: all | before | after
 select x.time_window,
    x.anchor_event,
    x.event_family,
    x.concept_id,
    case when x.n_patients <= @min_cell_count then -@min_cell_count else x.n_records end as n_records,
    case when x.n_patients <= @min_cell_count then -@min_cell_count else x.n_patients end as n_patients,
    case when x.n_patients <= @min_cell_count then -@min_cell_count else coalesce(ts.n_patients_with_code_timing, tba.n_patients_with_code_timing) end as n_patients_with_code_timing,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.lq_days_first,       tba.lq_days_first)       end as lq_days_first,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.median_days_first,   tba.median_days_first)   end as median_days_first,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.uq_days_first,       tba.uq_days_first)       end as uq_days_first,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.lq_days_closest,     tba.lq_days_closest)     end as lq_days_closest,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.median_days_closest, tba.median_days_closest) end as median_days_closest,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.uq_days_closest,     tba.uq_days_closest)     end as uq_days_closest,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.lq_days_first,       tba.lq_days_first)       end as lq_days,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.median_days_first,   tba.median_days_first)   end as median_days,
    case when x.n_patients <= @min_cell_count then null else coalesce(ts.uq_days_first,       tba.uq_days_first)       end as uq_days
 from (
    select 'all'    as time_window, anchor_event, event_family, concept_id, n_records, n_patients from vcbo5u4zevent_code_counts
    union all
    select 'before' as time_window, anchor_event, event_family, concept_id, n_records, n_patients from vcbo5u4zevent_code_counts_before_after         where time_relative = 'BEFORE'
    union all
    select 'after'  as time_window, anchor_event, event_family, concept_id, n_records, n_patients from vcbo5u4zevent_code_counts_before_after         where time_relative = 'AFTER'
    union all
    select 'before' as time_window, anchor_event, event_family, concept_id, n_records, n_patients from vcbo5u4zevent_code_counts_before_after_first_met where time_relative = 'BEFORE'
    union all
    select 'after'  as time_window, anchor_event, event_family, concept_id, n_records, n_patients from vcbo5u4zevent_code_counts_before_after_first_met where time_relative = 'AFTER'
) x
left join vcbo5u4zevent_code_timing_summary ts
  on x.time_window = 'all'
 and x.anchor_event = ts.anchor_event
 and x.event_family = ts.event_family
 and x.concept_id   = ts.concept_id
left join vcbo5u4zevent_code_timing_before_after_summary tba
  on x.time_window != 'all'
 and x.anchor_event = tba.anchor_event
 and x.event_family = tba.event_family
 and x.concept_id   = tba.concept_id
 and ((x.time_window = 'before' and tba.time_relative = 'BEFORE')
  or  (x.time_window = 'after'  and tba.time_relative = 'AFTER'))
 order by  x.time_window, x.anchor_event, x.event_family, x.n_patients desc, x.n_records desc, x.concept_id
 ;
-- 3) Temporal directionality buckets
--    Exact patient counts by direction category for key event pairs:
--      DX -> MET  (using index_date -> first_met_date from #patient_char)
--      DX -> L01  (using index_date -> first_l01_date from #patient_char)
--      MET -> L01 (using first_met_date -> first_l01_date from #patient_char)
--
--    Categories (days = TO_date - FROM_date):
--      BEFORE_GT90  : TO event > 90 days before FROM  (days < -90)
--      BEFORE_1_90  : TO event 1-90 days before FROM  (-90 <= days < 0)
--      SAME_DAY     : same calendar day                (days = 0)
--      AFTER_1_30   : 1-30 days after                  (1 <= days <= 30)
--      AFTER_31_90  : 31-90 days after                 (31 <= days <= 90)
--      AFTER_91_365 : 91-365 days after                (91 <= days <= 365)
--      AFTER_GT365  : > 365 days after                 (days > 365)
--      NO_EVENT     : FROM event present but TO event absent
--
--    Stratified by OVERALL and by anchor year:
--      DX_MET / DX_L01 use YEAR(index_date); MET_L01 uses YEAR(first_met_date).
--    Small-cell suppression: n suppressed to -@min_cell_count when <= @min_cell_count.
with dx_met_base as (
    select
        EXTRACT(YEAR from index_date) as index_year_int,
        case
            when first_met_date is null  then 'NO_EVENT'
            when days_dx_to_met < -90    then 'BEFORE_GT90'
            when days_dx_to_met < 0      then 'BEFORE_1_90'
            when days_dx_to_met = 0      then 'SAME_DAY'
            when days_dx_to_met <= 30    then 'AFTER_1_30'
            when days_dx_to_met <= 90    then 'AFTER_31_90'
            when days_dx_to_met <= 365   then 'AFTER_91_365'
            else 'AFTER_GT365'
        end as direction
    from vcbo5u4zpatient_char
),
dx_l01_base as (
    select
        EXTRACT(YEAR from index_date) as index_year_int,
        case
            when first_l01_date is null  then 'NO_EVENT'
            when days_dx_to_l01 < -90    then 'BEFORE_GT90'
            when days_dx_to_l01 < 0      then 'BEFORE_1_90'
            when days_dx_to_l01 = 0      then 'SAME_DAY'
            when days_dx_to_l01 <= 30    then 'AFTER_1_30'
            when days_dx_to_l01 <= 90    then 'AFTER_31_90'
            when days_dx_to_l01 <= 365   then 'AFTER_91_365'
            else 'AFTER_GT365'
        end as direction
    from vcbo5u4zpatient_char
),
met_l01_base as (
    select
        EXTRACT(YEAR from first_met_date) as index_year_int,
        case
            when first_l01_date is null  then 'NO_EVENT'
            when days_met_to_l01 < -90   then 'BEFORE_GT90'
            when days_met_to_l01 < 0     then 'BEFORE_1_90'
            when days_met_to_l01 = 0     then 'SAME_DAY'
            when days_met_to_l01 <= 30   then 'AFTER_1_30'
            when days_met_to_l01 <= 90   then 'AFTER_31_90'
            when days_met_to_l01 <= 365  then 'AFTER_91_365'
            else 'AFTER_GT365'
        end as direction
    from vcbo5u4zpatient_char
    where first_met_date is not null
)
 select x.pair,
    x.index_year,
    x.direction,
    case when x.n_patients <= @min_cell_count then -@min_cell_count else x.n_patients end as n_patients
 from (
    -- DX -> MET: OVERALL
     select 'DX_MET' as pair, 'OVERALL' as index_year, direction, count(*) as n_patients
     from dx_met_base
     group by  direction
    union all
    -- DX -> MET: by DX year
     select 'DX_MET' as pair, cast(index_year_int as STRING) as index_year, 3, count(*) as n_patients
     from dx_met_base
     group by  2, direction
    union all
    -- DX -> L01: OVERALL
     select 'DX_L01' as pair, 'OVERALL' as index_year, 3, count(*) as n_patients
     from dx_l01_base
     group by  direction
    union all
    -- DX -> L01: by DX year
     select 'DX_L01' as pair, cast(index_year_int as STRING) as index_year, 3, count(*) as n_patients
     from dx_l01_base
     group by  2, direction
    union all
    -- MET -> L01: OVERALL
     select 'MET_L01' as pair, 'OVERALL' as index_year, 3, count(*) as n_patients
     from met_l01_base
     group by  direction
    union all
    -- MET -> L01: by MET year
     select 'MET_L01' as pair, cast(index_year_int as STRING) as index_year, 3, count(*) as n_patients
     from met_l01_base
     group by  2, 3 ) x
 order by  x.pair, case when x.index_year = 'OVERALL' then 0 else 1 end, case when x.index_year = 'OVERALL' then null else cast(x.index_year  as int64) end, case x.direction
        when 'BEFORE_GT90'  then 1
        when 'BEFORE_1_90'  then 2
        when 'SAME_DAY'     then 3
        when 'AFTER_1_30'   then 4
        when 'AFTER_31_90'  then 5
        when 'AFTER_91_365' then 6
        when 'AFTER_GT365'  then 7
        when 'NO_EVENT'     then 8
        else 9
    end
 ;
-- 4) Pairwise timing summary: all four timing types combined (small-cell sentinel)
--    timing_type: first_to_first | first_to_closest | first_to_closest_before | first_to_closest_after
 select x.timing_type,
    x.from_event,
    x.to_event,
    case when x.n_patients_with_pair <= @min_cell_count then -@min_cell_count else x.n_patients_with_pair end as n_patients_with_pair,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p05_days end as p05_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p10_days end as p10_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p20_days end as p20_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p25_days end as p25_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p30_days end as p30_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p40_days end as p40_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p50_days end as p50_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p60_days end as p60_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p70_days end as p70_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p75_days end as p75_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p80_days end as p80_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p90_days end as p90_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p95_days end as p95_days
 from (
    select 'first_to_first'          as timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days from vcbo5u4ztiming_pair_summary
    union all
    select 'first_to_closest'        as timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days from vcbo5u4ztiming_pair_summary_first_to_closest
    union all
    select 'first_to_closest_before' as timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days from vcbo5u4ztiming_pair_summary_first_to_closest_before
    union all
    select 'first_to_closest_after'  as timing_type, from_event, to_event, n_patients_with_pair, p05_days, p10_days, p20_days, p25_days, p30_days, p40_days, p50_days, p60_days, p70_days, p75_days, p80_days, p90_days, p95_days from vcbo5u4ztiming_pair_summary_first_to_closest_after
) x
 order by  x.timing_type, x.from_event, x.to_event
 ;
-- 5) Pairwise timing summary stratified by anchor year
--    Same structure as chunk 04 (final_timing_pairwise.csv) but grouped by year.
--    Year is anchored on the from_event: DX-anchored pairs use YEAR(index_date),
--    MET-anchored pairs use YEAR(first_met_date).
--    Used for year-over-year plots and for the per-year columns in the <U+00A7>06 stability matrix.
--    Small-cell suppression applied.
 select x.timing_type,
    x.index_year,
    x.from_event,
    x.to_event,
    case when x.n_patients_with_pair <= @min_cell_count then -@min_cell_count else x.n_patients_with_pair end as n_patients_with_pair,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p25_days  end as p25_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p50_days  end as p50_days,
    case when x.n_patients_with_pair <= @min_cell_count then null else x.p75_days  end as p75_days
 from (
    -- first_to_first by anchor year
     select 'first_to_first' as timing_type,
        cast(index_year_int as STRING) as index_year,
        from_event,
        to_event,
        count(*) as n_patients_with_pair,
        min(case when 4.0 * rn >= cnt then cast(days_diff  as float64) end) as p25_days,
        min(case when 2.0 * rn >= cnt then cast(days_diff  as float64) end) as p50_days,
        min(case when 4.0 * rn >= 3 * cnt then cast(days_diff  as float64) end) as p75_days
     from (
        select p.from_event, p.to_event, p.days_diff,
            case when p.from_event = 'MET' then EXTRACT(YEAR from ms.first_met_date) else EXTRACT(YEAR from pc.index_date) end as index_year_int,
            row_number() over (partition by case when p.from_event = 'MET' then EXTRACT(YEAR from ms.first_met_date) else EXTRACT(YEAR from pc.index_date) end, p.from_event, p.to_event order by p.days_diff) as rn,
            count(*)     over (partition by case when p.from_event = 'MET' then EXTRACT(YEAR from ms.first_met_date) else EXTRACT(YEAR from pc.index_date) end, p.from_event, p.to_event)                    as cnt
        from vcbo5u4zpatient_timing_pairs p
        join vcbo5u4zpatient_char pc    on p.person_id = pc.person_id
        left join vcbo5u4zmet_summary ms on p.person_id = ms.person_id
    ) y
     group by  2, 3, to_event
    union all
    -- first_to_closest_after by anchor year (MET-anchored pairs use MET year)
     select 'first_to_closest_after' as timing_type, cast(index_year_int as STRING) as index_year, 3, 4, count(*) as n_patients_with_pair, min(case when 4.0 * rn >= cnt then cast(days_diff  as float64) end) as p25_days, min(case when 2.0 * rn >= cnt then cast(days_diff  as float64) end) as p50_days, min(case when 4.0 * rn >= 3 * cnt then cast(days_diff  as float64) end) as p75_days
     from (
        select p.from_event, p.to_event, p.days_diff,
            case when p.from_event = 'MET' then EXTRACT(YEAR from ms.first_met_date) else EXTRACT(YEAR from pc.index_date) end as index_year_int,
            row_number() over (partition by case when p.from_event = 'MET' then EXTRACT(YEAR from ms.first_met_date) else EXTRACT(YEAR from pc.index_date) end, p.from_event, p.to_event order by p.days_diff) as rn,
            count(*)     over (partition by case when p.from_event = 'MET' then EXTRACT(YEAR from ms.first_met_date) else EXTRACT(YEAR from pc.index_date) end, p.from_event, p.to_event)                    as cnt
        from vcbo5u4zpatient_timing_pairs_first_to_closest_after p
        join vcbo5u4zpatient_char pc    on p.person_id = pc.person_id
        left join vcbo5u4zmet_summary ms on p.person_id = ms.person_id
    ) y
     group by  2, 3, 2 ) x
 order by  x.timing_type, x.from_event, x.to_event, cast(x.index_year  as int64)
 ;
-- 6b) Directional ODX / GDX prevalence expressed CUMULATIVELY (CDF-style), so an
--     exclusion look-back (before) or follow-up (after) cutoff can be read off
--     directly. Cumulative companion to the disjoint bands in chunk 06; same
--     population, same closest-event-per-side construction, same two anchors.
--
--     For each anchor / event family / concept, the number of DISTINCT PATIENTS
--     whose closest event on a side sits WITHIN each day threshold of the anchor.
--     Because a patient counts as "within X" whenever ANY event on that side is
--     within X days of the anchor, n_within_Xd_before is exactly the number of
--     patients an X-day look-back exclusion would capture for this concept.
--     Counts are cumulative and monotonically non-decreasing across thresholds.
--
--     Anchors (both surfaced): INDEX (DX index_date, full DX cohort) and
--     FIRST_MET (first_met_date, MET subgroup only).
--     Families: ODX (other specific cancer dx), GDX (general / non-specific).
--     days = DATEDIFF(DAY, anchor_date, event_date); before = days <= -1,
--     after = days >= 1, day 0 its own category (never folded into a side).
--
--     Columns:
--       n_ever            : distinct patients with any event of the concept, any time.
--       n_before_ever     : distinct patients with any event before the anchor
--                           (the denominator for the before CDF; the tail beyond
--                           2 yr is n_before_ever - n_within_730d_before).
--       n_within_30d_before ... n_within_730d_before : cumulative before counts
--                           (patients with a before event within 30/90/180/365/730 days).
--       median_days_before: median of days-before over patients with any before
--                           event, days-before = distance of the closest-before
--                           event; framework ordered-set median convention
--                           (lower-middle for even n, as in chunks 16-17, 23, 27-28).
--       n_day0            : distinct patients with an event on the anchor day.
--       n_after_ever, n_within_30d_after ... n_within_730d_after, median_days_after:
--                           mirror of the before columns on the after side.
--
--     Covers ODX and GDX. All concepts reported; report builder limits to top N.
--
--     Small-cell suppression: each count in (0, @min_cell_count] set to
--     -@min_cell_count; a side median set to NULL when that side's denominator
--     (n_before_ever / n_after_ever) is <= @min_cell_count.
with events as (
    select 'INDEX' as anchor_event, 'ODX' as event_family, e.person_id, e.concept_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as days_from_anchor
    from vcbo5u4zother_dx_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
    union all
    select 'INDEX' as anchor_event, 'GDX' as event_family, e.person_id, e.concept_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as days_from_anchor
    from vcbo5u4zgen_cancer_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
    union all
    select 'FIRST_MET' as anchor_event, 'ODX' as event_family, e.person_id, e.concept_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) as days_from_anchor
    from vcbo5u4zother_dx_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
    join vcbo5u4zmet_summary ms on ms.person_id = c.person_id
    where ms.first_met_date is not null
    union all
    select 'FIRST_MET' as anchor_event, 'GDX' as event_family, e.person_id, e.concept_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) as days_from_anchor
    from vcbo5u4zgen_cancer_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
    join vcbo5u4zmet_summary ms on ms.person_id = c.person_id
    where ms.first_met_date is not null
),
per_person as (
     select anchor_event,
        event_family,
        concept_id,
        person_id,
        max(case when days_from_anchor = 0 then 1 else 0 end)      as has_day0,
        max(case when days_from_anchor < 0 then days_from_anchor end) as closest_before_days,
        min(case when days_from_anchor > 0 then days_from_anchor end) as closest_after_days
     from events
     group by  1, 2, 3, 4 ),
dir as (
    select
        anchor_event,
        event_family,
        concept_id,
        person_id,
        has_day0,
        case when closest_before_days is null then null else -closest_before_days end as days_before,
        closest_after_days as days_after
    from per_person
),
med_before as (
     select anchor_event,
        event_family,
        concept_id,
        min(case when 2.0 * rn >= cnt then cast(days_before  as float64) end) as median_days_before
     from (
        select
            anchor_event,
            event_family,
            concept_id,
            days_before,
            row_number() over (partition by anchor_event, event_family, concept_id order by days_before) as rn,
            count(*)     over (partition by anchor_event, event_family, concept_id)                      as cnt
        from dir
        where days_before is not null
    ) x
     group by  1, 2, 3 ),
med_after as (
     select anchor_event,
        event_family,
        concept_id,
        min(case when 2.0 * rn >= cnt then cast(days_after  as float64) end) as median_days_after
     from (
        select
            anchor_event,
            event_family,
            concept_id,
            days_after,
            row_number() over (partition by anchor_event, event_family, concept_id order by days_after) as rn,
            count(*)     over (partition by anchor_event, event_family, concept_id)                     as cnt
        from dir
        where days_after is not null
    ) x
     group by  1, 2, 3 ),
agg as (
     select anchor_event,
        event_family,
        concept_id,
        count(*)                                                       as n_ever,
        sum(case when days_before is not null then 1 else 0 end)       as n_before_ever,
        sum(case when days_before <= 30  then 1 else 0 end)            as n_before_30,
        sum(case when days_before <= 90  then 1 else 0 end)            as n_before_90,
        sum(case when days_before <= 180 then 1 else 0 end)            as n_before_180,
        sum(case when days_before <= 365 then 1 else 0 end)            as n_before_365,
        sum(case when days_before <= 730 then 1 else 0 end)            as n_before_730,
        sum(has_day0)                                                  as n_day0,
        sum(case when days_after is not null then 1 else 0 end)        as n_after_ever,
        sum(case when days_after <= 30  then 1 else 0 end)             as n_after_30,
        sum(case when days_after <= 90  then 1 else 0 end)             as n_after_90,
        sum(case when days_after <= 180 then 1 else 0 end)             as n_after_180,
        sum(case when days_after <= 365 then 1 else 0 end)             as n_after_365,
        sum(case when days_after <= 730 then 1 else 0 end)             as n_after_730
     from dir
     group by  1, 2, 3 )
 select a.anchor_event,
    a.event_family,
    a.concept_id,
    case when a.n_ever        > 0 and a.n_ever        <= @min_cell_count then -@min_cell_count else a.n_ever        end as n_ever,
    case when a.n_before_ever > 0 and a.n_before_ever <= @min_cell_count then -@min_cell_count else a.n_before_ever end as n_before_ever,
    case when a.n_before_30   > 0 and a.n_before_30   <= @min_cell_count then -@min_cell_count else a.n_before_30   end as n_within_30d_before,
    case when a.n_before_90   > 0 and a.n_before_90   <= @min_cell_count then -@min_cell_count else a.n_before_90   end as n_within_90d_before,
    case when a.n_before_180  > 0 and a.n_before_180  <= @min_cell_count then -@min_cell_count else a.n_before_180  end as n_within_180d_before,
    case when a.n_before_365  > 0 and a.n_before_365  <= @min_cell_count then -@min_cell_count else a.n_before_365  end as n_within_365d_before,
    case when a.n_before_730  > 0 and a.n_before_730  <= @min_cell_count then -@min_cell_count else a.n_before_730  end as n_within_730d_before,
    case when a.n_before_ever <= @min_cell_count then null else mb.median_days_before end as median_days_before,
    case when a.n_day0        > 0 and a.n_day0        <= @min_cell_count then -@min_cell_count else a.n_day0        end as n_day0,
    case when a.n_after_ever  > 0 and a.n_after_ever  <= @min_cell_count then -@min_cell_count else a.n_after_ever  end as n_after_ever,
    case when a.n_after_30    > 0 and a.n_after_30    <= @min_cell_count then -@min_cell_count else a.n_after_30    end as n_within_30d_after,
    case when a.n_after_90    > 0 and a.n_after_90    <= @min_cell_count then -@min_cell_count else a.n_after_90    end as n_within_90d_after,
    case when a.n_after_180   > 0 and a.n_after_180   <= @min_cell_count then -@min_cell_count else a.n_after_180   end as n_within_180d_after,
    case when a.n_after_365   > 0 and a.n_after_365   <= @min_cell_count then -@min_cell_count else a.n_after_365   end as n_within_365d_after,
    case when a.n_after_730   > 0 and a.n_after_730   <= @min_cell_count then -@min_cell_count else a.n_after_730   end as n_within_730d_after,
    case when a.n_after_ever  <= @min_cell_count then null else ma.median_days_after end as median_days_after
 from agg a
left join med_before mb
  on  mb.anchor_event = a.anchor_event
  and mb.event_family = a.event_family
  and mb.concept_id   = a.concept_id
left join med_after ma
  on  ma.anchor_event = a.anchor_event
  and ma.event_family = a.event_family
  and ma.concept_id   = a.concept_id
 order by  case when a.anchor_event = 'INDEX' then 0 else 1 end, a.event_family, a.n_ever desc, a.concept_id
 ;
-- 6) Directional ODX / GDX concept prevalence relative to the anchor date, at
--    fixed clinical time points, with before and after kept strictly separate and
--    day 0 as its own category. Replaces the earlier symmetric (+/-) windowed
--    output (the +/- windows conflated pre- and post-anchor coding, which have
--    different clinical meaning for exclusion-criteria design).
--
--    For each anchor / event family / concept this counts DISTINCT PATIENTS by
--    where the code sits in time relative to the anchor. Before and after are
--    never combined into a symmetric window. The event closest to the anchor on
--    each side places the patient into exactly one before band and/or one after
--    band, so within a side the bands partition that side's patients. This is the
--    disjoint-band "quick scan" companion to the cumulative CDF in chunk 06b.
--
--    Anchors (framework two-anchor convention, both surfaced):
--      INDEX     : DX index_date (full DX cohort, #cohort)
--      FIRST_MET : first_met_date (MET subgroup only; patients with a first MET)
--
--    Event families:
--      ODX : other specific cancer diagnoses (competing-cancer exclusion codes)
--      GDX : general / non-specific cancer diagnoses (broad ancestor codes)
--
--    days = DATEDIFF(DAY, anchor_date, event_date). Bands are placed on the event
--    CLOSEST to the anchor on each side (nearest-before for the before bands,
--    nearest-after for the after bands):
--      before side (days <= -1), by days-before = -days of the closest-before event:
--        n_before_gt730   : > 730 days before  (more than 2 yr)
--        n_before_366_730 : 366-730 days before (1-2 yr)
--        n_before_181_365 : 181-365 days before
--        n_before_91_180  : 91-180 days before
--        n_before_31_90   : 31-90 days before
--        n_before_1_30    : 1-30 days before
--      day 0 (its own category, never folded into before or after):
--        n_day0           : an event on the anchor day (days = 0)
--      after side (days >= 1), by days-after of the closest-after event:
--        n_after_1_30 ... n_after_gt730 : mirror of the before bands, forward
--    Side totals (each = the sum of that side's bands = any event on that side):
--        n_before_ever, n_after_ever
--    Overall:
--        n_ever : distinct patients with any event of the concept at any time.
--
--    n_ever is NOT the sum of the columns: one patient may have events before,
--    on, and after the anchor and so appear in a before band, in n_day0, and in
--    an after band. Within a single side the bands ARE a clean partition
--    (n_before_ever = sum of before bands; n_after_ever = sum of after bands).
--
--    Covers ODX and GDX. All concepts are reported; the report builder limits to
--    top N by n_ever.
--
--    Small-cell suppression: each count in (0, @min_cell_count] set to
--    -@min_cell_count.
with events as (
    select 'INDEX' as anchor_event, 'ODX' as event_family, e.person_id, e.concept_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as days_from_anchor
    from vcbo5u4zother_dx_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
    union all
    select 'INDEX' as anchor_event, 'GDX' as event_family, e.person_id, e.concept_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as days_from_anchor
    from vcbo5u4zgen_cancer_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
    union all
    select 'FIRST_MET' as anchor_event, 'ODX' as event_family, e.person_id, e.concept_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) as days_from_anchor
    from vcbo5u4zother_dx_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
    join vcbo5u4zmet_summary ms on ms.person_id = c.person_id
    where ms.first_met_date is not null
    union all
    select 'FIRST_MET' as anchor_event, 'GDX' as event_family, e.person_id, e.concept_id,
        DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) as days_from_anchor
    from vcbo5u4zgen_cancer_events e
    join vcbo5u4zcohort c on e.person_id = c.person_id
    join vcbo5u4zmet_summary ms on ms.person_id = c.person_id
    where ms.first_met_date is not null
),
per_person as (
    -- One row per (anchor, family, concept, person): day-0 flag, and the days
    -- offset of the closest event on each side (MAX of negatives = nearest before;
    -- MIN of positives = nearest after; NULL when that side has no event).
     select anchor_event,
        event_family,
        concept_id,
        person_id,
        max(case when days_from_anchor = 0 then 1 else 0 end)      as has_day0,
        max(case when days_from_anchor < 0 then days_from_anchor end) as closest_before_days,
        min(case when days_from_anchor > 0 then days_from_anchor end) as closest_after_days
     from events
     group by  1, 2, 3, 4 ),
dir as (
    select
        anchor_event,
        event_family,
        concept_id,
        person_id,
        has_day0,
        case when closest_before_days is null then null else -closest_before_days end as days_before,
        closest_after_days as days_after
    from per_person
),
agg as (
     select anchor_event,
        event_family,
        concept_id,
        count(*)                                                       as n_ever,
        sum(case when days_before is not null       then 1 else 0 end) as n_before_ever,
        sum(case when days_before > 730             then 1 else 0 end) as n_before_gt730,
        sum(case when days_before between 366 and 730 then 1 else 0 end) as n_before_366_730,
        sum(case when days_before between 181 and 365 then 1 else 0 end) as n_before_181_365,
        sum(case when days_before between 91  and 180 then 1 else 0 end) as n_before_91_180,
        sum(case when days_before between 31  and 90  then 1 else 0 end) as n_before_31_90,
        sum(case when days_before between 1   and 30  then 1 else 0 end) as n_before_1_30,
        sum(has_day0)                                                  as n_day0,
        sum(case when days_after between 1   and 30  then 1 else 0 end) as n_after_1_30,
        sum(case when days_after between 31  and 90  then 1 else 0 end) as n_after_31_90,
        sum(case when days_after between 91  and 180 then 1 else 0 end) as n_after_91_180,
        sum(case when days_after between 181 and 365 then 1 else 0 end) as n_after_181_365,
        sum(case when days_after between 366 and 730 then 1 else 0 end) as n_after_366_730,
        sum(case when days_after > 730              then 1 else 0 end) as n_after_gt730,
        sum(case when days_after is not null        then 1 else 0 end) as n_after_ever
     from dir
     group by  1, 2, 3 )
 select a.anchor_event,
    a.event_family,
    a.concept_id,
    case when a.n_ever           > 0 and a.n_ever           <= @min_cell_count then -@min_cell_count else a.n_ever           end as n_ever,
    case when a.n_before_ever    > 0 and a.n_before_ever    <= @min_cell_count then -@min_cell_count else a.n_before_ever    end as n_before_ever,
    case when a.n_before_gt730   > 0 and a.n_before_gt730   <= @min_cell_count then -@min_cell_count else a.n_before_gt730   end as n_before_gt730,
    case when a.n_before_366_730 > 0 and a.n_before_366_730 <= @min_cell_count then -@min_cell_count else a.n_before_366_730 end as n_before_366_730,
    case when a.n_before_181_365 > 0 and a.n_before_181_365 <= @min_cell_count then -@min_cell_count else a.n_before_181_365 end as n_before_181_365,
    case when a.n_before_91_180  > 0 and a.n_before_91_180  <= @min_cell_count then -@min_cell_count else a.n_before_91_180  end as n_before_91_180,
    case when a.n_before_31_90   > 0 and a.n_before_31_90   <= @min_cell_count then -@min_cell_count else a.n_before_31_90   end as n_before_31_90,
    case when a.n_before_1_30    > 0 and a.n_before_1_30    <= @min_cell_count then -@min_cell_count else a.n_before_1_30    end as n_before_1_30,
    case when a.n_day0           > 0 and a.n_day0           <= @min_cell_count then -@min_cell_count else a.n_day0           end as n_day0,
    case when a.n_after_1_30     > 0 and a.n_after_1_30     <= @min_cell_count then -@min_cell_count else a.n_after_1_30     end as n_after_1_30,
    case when a.n_after_31_90    > 0 and a.n_after_31_90    <= @min_cell_count then -@min_cell_count else a.n_after_31_90    end as n_after_31_90,
    case when a.n_after_91_180   > 0 and a.n_after_91_180   <= @min_cell_count then -@min_cell_count else a.n_after_91_180   end as n_after_91_180,
    case when a.n_after_181_365  > 0 and a.n_after_181_365  <= @min_cell_count then -@min_cell_count else a.n_after_181_365  end as n_after_181_365,
    case when a.n_after_366_730  > 0 and a.n_after_366_730  <= @min_cell_count then -@min_cell_count else a.n_after_366_730  end as n_after_366_730,
    case when a.n_after_gt730    > 0 and a.n_after_gt730    <= @min_cell_count then -@min_cell_count else a.n_after_gt730    end as n_after_gt730,
    case when a.n_after_ever     > 0 and a.n_after_ever     <= @min_cell_count then -@min_cell_count else a.n_after_ever     end as n_after_ever
 from agg a
 order by  case when a.anchor_event = 'INDEX' then 0 else 1 end, a.event_family, a.n_ever desc, a.concept_id
 ;
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
    from vcbo5u4zcohort c
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
    from vcbo5u4zmet_summary ms
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
    left join vcbo5u4zl01_events le
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
-- 8) Death timing from INDEX and FIRST_MET (stratified by calendar year of index date and OVERALL)
 select s.prevalence_year,
    s.anchor_event,
    case when s.n_patients <= @min_cell_count then -@min_cell_count else s.n_patients end as n_patients,
    case
        when s.n_patients <= @min_cell_count then -@min_cell_count
        when s.n_deaths between 1 and @min_cell_count then -@min_cell_count
        else s.n_deaths
    end as n_deaths,
    case when s.n_patients <= @min_cell_count or s.n_deaths <= @min_cell_count then null else s.n_deaths_in_obs end as n_deaths_in_obs,
    case when s.n_patients <= @min_cell_count or s.n_deaths <= @min_cell_count then null else s.n_deaths_out_obs end as n_deaths_out_obs,
    case when s.n_patients <= @min_cell_count or s.n_deaths <= @min_cell_count then null else q.lq_days end as lq_days,
    case when s.n_patients <= @min_cell_count or s.n_deaths <= @min_cell_count then null else q.median_days end as median_days,
    case when s.n_patients <= @min_cell_count or s.n_deaths <= @min_cell_count then null else q.uq_days end as uq_days,
    case when s.n_patients <= @min_cell_count then null else f.lq_followup_days end as lq_followup_days,
    case when s.n_patients <= @min_cell_count then null else f.median_followup_days end as median_followup_days,
    case when s.n_patients <= @min_cell_count then null else f.uq_followup_days end as uq_followup_days
 from vcbo5u4zdeath_stratum_counts s
left join vcbo5u4zdeath_timing_quantiles q
  on s.prevalence_year = q.prevalence_year
 and s.anchor_event = q.anchor_event
left join vcbo5u4zfollowup_quantiles f
  on s.prevalence_year = f.prevalence_year
 and s.anchor_event = f.anchor_event
 order by  case when s.prevalence_year = 'OVERALL' then 0 else 1 end, case when s.prevalence_year = 'OVERALL' then null else cast(s.prevalence_year  as int64) end, case when s.anchor_event = 'INDEX' then 0 else 1 end
 ;
-- 9) Demographics at anchor dates (INDEX = first DX, FIRST_MET = first MET)
-- Gender concept IDs (OMOP): 8507=Male, 8532=Female. Others treated as unknown.
with anchor_persons as (
    select
        'INDEX' as anchor_event,
        c.person_id,
        c.index_date as anchor_date
    from vcbo5u4zpatient_char c
    where c.index_date is not null
    union all
    select
        'FIRST_MET' as anchor_event,
        c.person_id,
        c.first_met_date as anchor_date
    from vcbo5u4zpatient_char c
    where c.first_met_date is not null
),
base as (
    select
        a.anchor_event,
        a.person_id,
        a.anchor_date,
        p.gender_concept_id,
        p.birth_datetime,
        p.year_of_birth
    from anchor_persons a
    join @cdm_database_schema.person p
      on a.person_id = p.person_id
),
ages as (
    select
        anchor_event,
        person_id,
        gender_concept_id,
        case
            when birth_datetime is not null
                then DATE_DIFF(IF(SAFE_CAST(anchor_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(anchor_date  AS STRING)),SAFE_CAST(anchor_date  AS DATE)), IF(SAFE_CAST(IF(SAFE_CAST(birth_datetime  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(birth_datetime  AS STRING)),SAFE_CAST(birth_datetime  AS DATE))  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(IF(SAFE_CAST(birth_datetime  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(birth_datetime  AS STRING)),SAFE_CAST(birth_datetime  AS DATE))  AS STRING)),SAFE_CAST(IF(SAFE_CAST(birth_datetime  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(birth_datetime  AS STRING)),SAFE_CAST(birth_datetime  AS DATE))  AS DATE)), DAY) / 365.25
            when year_of_birth is not null
                then DATE_DIFF(IF(SAFE_CAST(anchor_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(anchor_date  AS STRING)),SAFE_CAST(anchor_date  AS DATE)), IF(SAFE_CAST(DATE(year_of_birth, 7, 1)  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(DATE(year_of_birth, 7, 1)  AS STRING)),SAFE_CAST(DATE(year_of_birth, 7, 1)  AS DATE)), DAY) / 365.25
            else null
        end as age_years
    from base
)
 select agg.anchor_event,
    agg.n_patients,
    agg.n_male,
    agg.n_female,
    agg.pct_male,
    agg.pct_female,
    p.age_lq_years,
    p.age_median_years,
    p.age_uq_years
 from (
     select anchor_event,
        count(*) as n_patients,
        sum(case when gender_concept_id = 8507 then 1 else 0 end) as n_male,
        sum(case when gender_concept_id = 8532 then 1 else 0 end) as n_female,
        cast(100.0 * sum(case when gender_concept_id = 8507 then 1 else 0 end) / nullif(count(*), 0)  as float64) as pct_male,
        cast(100.0 * sum(case when gender_concept_id = 8532 then 1 else 0 end) / nullif(count(*), 0)  as float64) as pct_female
     from ages
    where age_years is not null
     group by  1 ) agg
join (
     select anchor_event,
        min(case when 4.0 * rn >= cnt then cast(age_years  as float64) end) as age_lq_years,
        min(case when 2.0 * rn >= cnt then cast(age_years  as float64) end) as age_median_years,
        min(case when 4.0 * rn >= 3 * cnt then cast(age_years  as float64) end) as age_uq_years
     from (
        select anchor_event, age_years,
            row_number() over (partition by anchor_event order by age_years) as rn,
            count(*)     over (partition by anchor_event)                    as cnt
        from ages
        where age_years is not null
    ) y
     group by  1 ) p
  on agg.anchor_event = p.anchor_event
 order by  case when agg.anchor_event = 'INDEX' then 0 else 1 end
 ;
-- 10) Anchor DX (main cohort) codes: distinct patients and distinct patient-days per condition_concept_id
--     Patient-day = one calendar day per person (multiple DX rows on the same day collapse to one).
with dx_days as (
    select distinct
        person_id,
        event_date,
        concept_id
    from vcbo5u4zdx_events
)
 select s.concept_id,
    case when s.n_distinct_patients <= @min_cell_count then -@min_cell_count else s.n_distinct_patients end as n_distinct_patients,
    case when s.n_distinct_patients <= @min_cell_count then null else s.n_distinct_patient_days end as n_distinct_patient_days
 from (
     select concept_id,
        count(distinct person_id) as n_distinct_patients,
        count(*) as n_distinct_patient_days
     from dx_days
     group by  1 ) s
 order by  s.n_distinct_patients desc, s.concept_id
 ;
-- 11) L01 consecutive record gap distribution <U+2014> decile summary
--     Intermediate tables #l01_event_days and #l01_consecutive_gaps are
--     built in 00_setup.sql (section L).
--
--     Two subgroups:
--       ALL_L01 : all DX cohort patients with any L01 record
--       MET_L01 : patients who also have a first_met_date
--
--     Output: one row per subgroup with gap-day deciles.
--     Small-cell suppression: n_gaps <= @min_cell_count suppresses percentiles to NULL
--     and replaces counts with -@min_cell_count.
   select subgroup,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count else count(*) end as n_gaps,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count else count(distinct person_id) end as n_patients_with_gaps,
    min(case when cnt > @min_cell_count and 10.0 * rn >= cnt      then cast(gap_days  as float64) end) as p10_days,
    min(case when cnt > @min_cell_count and  4.0 * rn >= cnt      then cast(gap_days  as float64) end) as p25_days,
    min(case when cnt > @min_cell_count and  2.0 * rn >= cnt      then cast(gap_days  as float64) end) as p50_days,
    min(case when cnt > @min_cell_count and  4.0 * rn >= 3 * cnt  then cast(gap_days  as float64) end) as p75_days,
    min(case when cnt > @min_cell_count and 10.0 * rn >= 9 * cnt  then cast(gap_days  as float64) end) as p90_days
   from (
    select subgroup, person_id, gap_days,
        row_number() over (partition by subgroup order by gap_days) as rn,
        count(*)     over (partition by subgroup)                   as cnt
    from vcbo5u4zl01_consecutive_gaps
) x
  group by  1   order by  1 ;
-- 12) L01 consecutive record gap distribution <U+2014> bucketed histogram
--     Intermediate table #l01_consecutive_gaps is built in 00_setup.sql
--     (section L).  Same subgroups as chunk 11 (ALL_L01, MET_L01).
--
--     Output: one row per (subgroup, gap_bucket) for histogram rendering.
--     Small-cell suppression: n_gaps <= @min_cell_count suppressed to -@min_cell_count.
   select subgroup,
    case
        when gap_days <  30  then 'lt30d'
        when gap_days <  60  then '30_59d'
        when gap_days <  90  then '60_89d'
        when gap_days < 180  then '90_179d'
        when gap_days < 365  then '180_364d'
        else 'ge365d'
    end as gap_bucket,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count else count(*) end as n_gaps
   from vcbo5u4zl01_consecutive_gaps
  group by  1, 2   order by  1, min(case
        when gap_days <  30  then 1
        when gap_days <  60  then 2
        when gap_days <  90  then 3
        when gap_days < 180  then 4
        when gap_days < 365  then 5
        else 6
    end)
  ;
-- 13) Death date vs observation period alignment <U+2014> summary counts
--     For patients in the DX cohort (and the FIRST_MET subgroup), reports:
--       - n_death_before_obs : death_date < first observation_period_start
--                              (data quality error <U+2014> rare but important)
--       - n_death_after_obs  : death_date > last  observation_period_end
--                              (gap distribution summarized in chunk 14)
--       - lq/median/uq/p90 percentiles of the post-obs gap (days).
--
--     Stratified by anchor (INDEX / FIRST_MET).
--     Small-cell suppression: n_death_before_obs and n_death_after_obs use -@min_cell_count
--     when suppressed; percentile columns are set to NULL when n_death_after_obs is suppressed.
with patient_obs as (
     select person_id,
        min(observation_period_start_date) as first_obs_start,
        max(observation_period_end_date)   as last_obs_end
     from @cdm_database_schema.observation_period
    where person_id in (select person_id from vcbo5u4zcohort)
     group by  1 ),
death_obs_gaps as (
    select
        c.person_id,
        c.index_date,
        ms.first_met_date,
        dos.death_date,
        po.first_obs_start,
        po.last_obs_end,
        case
            when dos.death_date > po.last_obs_end
                then DATE_DIFF(IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), IF(SAFE_CAST(po.last_obs_end  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(po.last_obs_end  AS STRING)),SAFE_CAST(po.last_obs_end  AS DATE)), DAY)
            else null
        end as gap_death_after_obs,
        case
            when dos.death_date < po.first_obs_start
                then 1
            else 0
        end as death_before_obs
    from vcbo5u4zcohort c
    inner join vcbo5u4zdeath_obs_status dos on dos.person_id = c.person_id
    left join vcbo5u4zmet_summary ms on ms.person_id = c.person_id
    left join patient_obs po  on po.person_id  = c.person_id
)
select
    anchor_event,
    case when n_death_before_obs > 0 and n_death_before_obs <= @min_cell_count then -@min_cell_count else n_death_before_obs end as n_death_before_obs,
    case when n_death_after_obs  > 0 and n_death_after_obs  <= @min_cell_count then -@min_cell_count else n_death_after_obs  end as n_death_after_obs,
    case when n_death_after_obs  > 0 and n_death_after_obs  <= @min_cell_count then null else lq_gap_days     end as lq_gap_days,
    case when n_death_after_obs  > 0 and n_death_after_obs  <= @min_cell_count then null else median_gap_days end as median_gap_days,
    case when n_death_after_obs  > 0 and n_death_after_obs  <= @min_cell_count then null else uq_gap_days     end as uq_gap_days,
    case when n_death_after_obs  > 0 and n_death_after_obs  <= @min_cell_count then null else p90_gap_days    end as p90_gap_days
from (
    select
        'INDEX' as anchor_event,
        sum(case when death_before_obs = 1 then 1 else 0 end) as n_death_before_obs,
        sum(case when gap_death_after_obs is not null then 1 else 0 end) as n_death_after_obs,
        min(case when gap_death_after_obs is not null and  4.0 * rn >= non_null_cnt then cast(gap_death_after_obs  as float64) end) as lq_gap_days,
        min(case when gap_death_after_obs is not null and  2.0 * rn >= non_null_cnt then cast(gap_death_after_obs  as float64) end) as median_gap_days,
        min(case when gap_death_after_obs is not null and  4.0 * rn >= 3 * non_null_cnt then cast(gap_death_after_obs  as float64) end) as uq_gap_days,
        min(case when gap_death_after_obs is not null and 10.0 * rn >= 9 * non_null_cnt then cast(gap_death_after_obs  as float64) end) as p90_gap_days
    from (
        select death_before_obs, gap_death_after_obs,
            row_number() over (order by gap_death_after_obs) as rn,
            sum(case when gap_death_after_obs is not null then 1 else 0 end) over () as non_null_cnt
        from death_obs_gaps
        where death_date is not null
    ) x
    union all
    select
        'FIRST_MET' as anchor_event,
        sum(case when death_before_obs = 1 then 1 else 0 end) as n_death_before_obs,
        sum(case when gap_death_after_obs is not null then 1 else 0 end) as n_death_after_obs,
        min(case when gap_death_after_obs is not null and  4.0 * rn >= non_null_cnt then cast(gap_death_after_obs  as float64) end) as lq_gap_days,
        min(case when gap_death_after_obs is not null and  2.0 * rn >= non_null_cnt then cast(gap_death_after_obs  as float64) end) as median_gap_days,
        min(case when gap_death_after_obs is not null and  4.0 * rn >= 3 * non_null_cnt then cast(gap_death_after_obs  as float64) end) as uq_gap_days,
        min(case when gap_death_after_obs is not null and 10.0 * rn >= 9 * non_null_cnt then cast(gap_death_after_obs  as float64) end) as p90_gap_days
    from (
        select death_before_obs, gap_death_after_obs,
            row_number() over (order by gap_death_after_obs) as rn,
            sum(case when gap_death_after_obs is not null then 1 else 0 end) over () as non_null_cnt
        from death_obs_gaps
        where death_date is not null
          and first_met_date is not null
    ) x
) agg
;
-- 14) Death date vs observation period <U+2014> bucketed gap histogram
--     Restricted to patients where death_date > obs_period_end_date.
--     Exported for both INDEX (all DX cohort) and FIRST_MET (MET subgroup)
--     so that each can be shown as a separate figure in the report.
with patient_obs as (
     select person_id,
        min(observation_period_start_date) as first_obs_start,
        max(observation_period_end_date)   as last_obs_end
     from @cdm_database_schema.observation_period
    where person_id in (select person_id from vcbo5u4zcohort)
     group by  1 ),
death_obs_gaps as (
    select
        c.person_id,
        ms.first_met_date,
        case
            when dos.death_date > po.last_obs_end
                then DATE_DIFF(IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), IF(SAFE_CAST(po.last_obs_end  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(po.last_obs_end  AS STRING)),SAFE_CAST(po.last_obs_end  AS DATE)), DAY)
            else null
        end as gap_death_after_obs
    from vcbo5u4zcohort c
    inner join vcbo5u4zdeath_obs_status dos on dos.person_id = c.person_id
    left join vcbo5u4zmet_summary ms        on ms.person_id  = c.person_id
    left join patient_obs po         on po.person_id  = c.person_id
),
bucketed as (
    select
        person_id,
        first_met_date,
        case
            when gap_death_after_obs <   30 then 'lt30d'
            when gap_death_after_obs <   60 then '30_59d'
            when gap_death_after_obs <   90 then '60_89d'
            when gap_death_after_obs <  180 then '90_179d'
            when gap_death_after_obs <  365 then '180_364d'
            when gap_death_after_obs <  730 then '365_729d'
            else 'ge730d'
        end as gap_bucket,
        case
            when gap_death_after_obs <   30 then 1
            when gap_death_after_obs <   60 then 2
            when gap_death_after_obs <   90 then 3
            when gap_death_after_obs <  180 then 4
            when gap_death_after_obs <  365 then 5
            when gap_death_after_obs <  730 then 6
            else 7
        end as sort_key
    from death_obs_gaps
    where gap_death_after_obs is not null
)
 select anchor_event, gap_bucket, n_patients
 from (
     select 'INDEX' as anchor_event, gap_bucket,
        case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count else count(*) end as n_patients,
        min(sort_key) as sort_key
     from bucketed
     group by  gap_bucket
    union all
     select 'FIRST_MET' as anchor_event, 2, case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count else count(*) end as n_patients, min(sort_key) as sort_key
     from bucketed
    where first_met_date is not null
     group by  gap_bucket
  ) x
 order by  case when anchor_event = 'INDEX' then 0 else 1 end, sort_key
 ;
-- 15) Distribution of distinct L01 event days per patient
--     Shows how many patients have 1, 2-6, 7-11, or 12+ distinct L01 days.
--     Patients with exactly 1 day cannot contribute to gap analyses (chunks 11-12).
--     Source: #l01_event_days (built in 00_setup.sql section L).
--
--     Two subgroups:
--       ALL_L01 : all DX cohort patients with any L01 record
--       MET_L01 : patients who also have a first_met_date
--     Small-cell suppression: n_patients <= @min_cell_count suppressed to -@min_cell_count.
   select subgroup,
    case
        when n_days =  1 then '1'
        when n_days <= 6 then '2_6'
        when n_days <= 11 then '7_11'
        else '12plus'
    end as days_bucket,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count else count(*) end as n_patients
   from (
     select e.person_id, count(*) as n_days, 'ALL_L01' as subgroup
     from vcbo5u4zl01_event_days e
     group by  e.person_id
    union all
     select e.person_id, count(*) as n_days, 'MET_L01' as subgroup
     from vcbo5u4zl01_event_days e
    join vcbo5u4zmet_summary ms on e.person_id = ms.person_id and ms.first_met_date is not null
     group by  e.person_id
  ) x
  group by  2, 2   order by  1, min(n_days)
  ;
-- 16) E. Observation-period characterization <U+2014> observability around the index
--     How much observable time each patient has BEFORE the index (look-back) and
--     AFTER the index (follow-up), reported as cumulative day-threshold counts:
--     the number of patients with fewer than 30 / 90 / 180 / 365 days of
--     observation on each side of the index. Look-back and follow-up are kept
--     strictly separate (one row per side); day 0 sits on the follow-up side
--     (follow-up = days from the index to the observation-period end, >= 0).
--
--     Observable time is measured inside the single observation period that
--     CONTAINS the anchor date, so both sides are contiguous observable time:
--       look-back_days = index_date - observation_period_start_date
--       follow-up_days = observation_period_end_date - index_date
--     A patient contributes only if the anchor date falls within one of their
--     observation periods. For INDEX this holds for every cohort patient by
--     construction (see #cohort in 00_setup.sql); for FIRST_MET it holds only
--     for patients whose first metastasis date is inside an observation period.
--
--     Two anchors: INDEX (first qualifying DX = cohort index date) and FIRST_MET
--     (first metastasis date). Source: #cohort, #met_summary (00_setup.sql) and
--     @cdm_database_schema.observation_period.
--     Small-cell suppression: threshold counts in (0, @min_cell_count] are set to
--     -@min_cell_count; median set to NULL when the group denominator is suppressed.
--     n_patients is an aggregate cohort denominator and is not suppressed, matching
--     the existing death/prevalence chunks.
with obs_around_anchor as (
    -- INDEX anchor: index_date is guaranteed to fall inside an observation period.
    select
        'INDEX' as anchor_event,
        c.person_id,
        DATE_DIFF(IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), IF(SAFE_CAST(op.observation_period_start_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(op.observation_period_start_date  AS STRING)),SAFE_CAST(op.observation_period_start_date  AS DATE)), DAY) as lookback_days,
        DATE_DIFF(IF(SAFE_CAST(op.observation_period_end_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(op.observation_period_end_date  AS STRING)),SAFE_CAST(op.observation_period_end_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY)   as followup_days
    from vcbo5u4zcohort c
    inner join @cdm_database_schema.observation_period op
        on  op.person_id = c.person_id
        and c.index_date between op.observation_period_start_date
                             and op.observation_period_end_date
    union all
    -- FIRST_MET anchor: only patients whose first metastasis date is inside a period.
    select
        'FIRST_MET' as anchor_event,
        c.person_id,
        DATE_DIFF(IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), IF(SAFE_CAST(op.observation_period_start_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(op.observation_period_start_date  AS STRING)),SAFE_CAST(op.observation_period_start_date  AS DATE)), DAY) as lookback_days,
        DATE_DIFF(IF(SAFE_CAST(op.observation_period_end_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(op.observation_period_end_date  AS STRING)),SAFE_CAST(op.observation_period_end_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY)   as followup_days
    from vcbo5u4zcohort c
    inner join vcbo5u4zmet_summary ms
        on ms.person_id = c.person_id and ms.first_met_date is not null
    inner join @cdm_database_schema.observation_period op
        on  op.person_id = c.person_id
        and ms.first_met_date between op.observation_period_start_date
                                  and op.observation_period_end_date
),
obs_sided as (
    select anchor_event, person_id, 'LOOKBACK_BEFORE_ANCHOR' as observation_side, lookback_days as obs_days
    from obs_around_anchor
    union all
    select anchor_event, person_id, 'FOLLOWUP_AFTER_ANCHOR'  as observation_side, followup_days as obs_days
    from obs_around_anchor
),
ranked as (
    select
        anchor_event,
        observation_side,
        obs_days,
        row_number() over (partition by anchor_event, observation_side order by obs_days) as rn,
        count(*)     over (partition by anchor_event, observation_side)                    as cnt
    from obs_sided
),
agg as (
     select anchor_event,
        observation_side,
        count(*) as n_patients,
        sum(case when obs_days < 30  then 1 else 0 end) as n_lt_30d,
        sum(case when obs_days < 90  then 1 else 0 end) as n_lt_90d,
        sum(case when obs_days < 180 then 1 else 0 end) as n_lt_180d,
        sum(case when obs_days < 365 then 1 else 0 end) as n_lt_365d,
        min(case when 2.0 * rn >= cnt then cast(obs_days  as float64) end) as median_days
     from ranked
     group by  1, 2 )
 select anchor_event,
    observation_side,
    n_patients,
    case when n_lt_30d  > 0 and n_lt_30d  <= @min_cell_count then -@min_cell_count else n_lt_30d  end as n_lt_30d,
    case when n_lt_90d  > 0 and n_lt_90d  <= @min_cell_count then -@min_cell_count else n_lt_90d  end as n_lt_90d,
    case when n_lt_180d > 0 and n_lt_180d <= @min_cell_count then -@min_cell_count else n_lt_180d end as n_lt_180d,
    case when n_lt_365d > 0 and n_lt_365d <= @min_cell_count then -@min_cell_count else n_lt_365d end as n_lt_365d,
    case when n_patients <= @min_cell_count then null else median_days end as median_days
 from agg
 order by  case anchor_event when 'INDEX' then 0 else 1 end, case observation_side when 'LOOKBACK_BEFORE_ANCHOR' then 0 else 1 end
 ;
-- 17) E. Observation-period characterization <U+2014> integrity checks
--     Whether the observation period behaves the way a phenotype would assume.
--     Long format: one row per (anchor_event, metric, stratum). Metrics:
--
--       PERIOD_TYPE_CONCEPT              (anchor_event = 'ALL')
--           How the period is defined at this site. One row per distinct
--           observation_period.period_type_concept_id among cohort patients.
--           n_numerator   = distinct cohort patients with a period of this type
--           n_denominator = distinct cohort patients with any period
--           (states the definition/source: claims-enrollment vs EHR-estimated
--            period types resolve to different concept ids; label upstream).
--
--       PATIENTS_WITH_MULTIPLE_OBS_PERIODS   (per anchor)
--           n_numerator   = patients with more than one observation period (a gap)
--           n_denominator = patients in this anchor's cohort
--
--       DEATHS_OUTSIDE_OBS_PERIOD            (per anchor)
--           n_numerator   = deaths on/after the anchor recorded outside any period
--           n_denominator = deaths on/after the anchor
--           (read straight from #death_stratum_counts OVERALL rows.)
--
--       DECEDENTS_PERIOD_ENDS_AFTER_DEATH    (per anchor)
--           n_numerator   = decedents whose last observation_period_end_date is
--                           AFTER the death date (period runs past death)
--           n_denominator = decedents (deaths on/after the anchor)
--
--       MEDIAN_DAYS_PERIOD_ENDS_PAST_DEATH   (per anchor)
--           median_days   = median (last_obs_end - death_date) among the decedents
--                           counted in DECEDENTS_PERIOD_ENDS_AFTER_DEATH
--           n_denominator = count of those decedents
--
--     Anchors: INDEX (cohort index date) and FIRST_MET (first metastasis date).
--     Sources: #cohort, #met_summary, #death_obs_status, #death_stratum_counts
--     (00_setup.sql) and @cdm_database_schema.observation_period.
--     Small-cell suppression: n_numerator in (0, @min_cell_count] set to
--     -@min_cell_count; median set to NULL when its decedent denominator is
--     suppressed. Aggregate cohort/death denominators are not suppressed.
with patient_obs as (
     select person_id,
        max(observation_period_end_date) as last_obs_end,
        count(*)                         as n_periods
     from @cdm_database_schema.observation_period
    where person_id in (select person_id from vcbo5u4zcohort)
     group by  1 ),
period_type_patients as (
     select op.period_type_concept_id,
        count(distinct op.person_id) as n_patients
     from @cdm_database_schema.observation_period op
    where op.person_id in (select person_id from vcbo5u4zcohort)
     group by  op.period_type_concept_id
 ),
period_type_total as (
    select count(distinct person_id) as n_patients_any_period
    from @cdm_database_schema.observation_period
    where person_id in (select person_id from vcbo5u4zcohort)
),
-- Anchor cohorts: INDEX = full DX cohort; FIRST_MET = cohort with a metastasis.
anchor_cohort as (
    select 'INDEX' as anchor_event, c.person_id, po.n_periods
    from vcbo5u4zcohort c
    left join patient_obs po on po.person_id = c.person_id
    union all
    select 'FIRST_MET' as anchor_event, c.person_id, po.n_periods
    from vcbo5u4zcohort c
    inner join vcbo5u4zmet_summary ms on ms.person_id = c.person_id and ms.first_met_date is not null
    left join patient_obs po on po.person_id = c.person_id
),
-- Decedents relative to each anchor, with whether the period runs past death.
decedent_anchor as (
    select
        'INDEX' as anchor_event,
        dos.death_date,
        case when po.last_obs_end > dos.death_date then 1 else 0 end as period_ends_after_death,
        case when po.last_obs_end > dos.death_date
             then DATE_DIFF(IF(SAFE_CAST(po.last_obs_end  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(po.last_obs_end  AS STRING)),SAFE_CAST(po.last_obs_end  AS DATE)), IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), DAY) end  as days_past_death
    from vcbo5u4zcohort c
    inner join vcbo5u4zdeath_obs_status dos on dos.person_id = c.person_id
    left join patient_obs po on po.person_id = c.person_id
    where dos.death_date >= c.index_date
    union all
    select
        'FIRST_MET' as anchor_event,
        dos.death_date,
        case when po.last_obs_end > dos.death_date then 1 else 0 end,
        case when po.last_obs_end > dos.death_date
             then DATE_DIFF(IF(SAFE_CAST(po.last_obs_end  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(po.last_obs_end  AS STRING)),SAFE_CAST(po.last_obs_end  AS DATE)), IF(SAFE_CAST(dos.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dos.death_date  AS STRING)),SAFE_CAST(dos.death_date  AS DATE)), DAY) end
    from vcbo5u4zcohort c
    inner join vcbo5u4zmet_summary ms on ms.person_id = c.person_id and ms.first_met_date is not null
    inner join vcbo5u4zdeath_obs_status dos on dos.person_id = c.person_id
    left join patient_obs po on po.person_id = c.person_id
    where dos.death_date >= ms.first_met_date
),
decedent_days_ranked as (
    -- Rank ONLY the decedents whose period runs past death (days_past_death
    -- populated). Ranking over the full decedent set would let the NULL rows
    -- (period does not run past death) consume the lowest row numbers, since
    -- SQL Server sorts NULLs first, and the ordered-set median filter below would
    -- then pick the minimum rather than the true median. Match the non-NULL-inside
    -- pattern used by chunks 06b, 23, 27, 28, 34.
    select
        anchor_event,
        days_past_death,
        row_number() over (partition by anchor_event order by days_past_death) as rn,
        count(*)     over (partition by anchor_event)                          as non_null_cnt
    from decedent_anchor
    where days_past_death is not null
),
metrics as (
    -- (1) period definition: period_type distribution (site-level)
     select 'ALL' as anchor_event,
        'PERIOD_TYPE_CONCEPT' as metric,
        cast(ptp.period_type_concept_id as STRING) as stratum,
        ptp.n_patients as n_numerator,
        ptt.n_patients_any_period as n_denominator,
        cast(null  as float64) as median_days
     from period_type_patients ptp
    cross join period_type_total ptt
    union all
    -- (2) patients with more than one observation period (a gap)
     select anchor_event,
        'PATIENTS_WITH_MULTIPLE_OBS_PERIODS',
        '',
        sum(case when n_periods > 1 then 1 else 0 end),
        count(*),
        cast(null  as float64)
     from anchor_cohort
      group by  anchor_event
    union all
    -- (3) deaths recorded outside any observation period
     select anchor_event, 'DEATHS_OUTSIDE_OBS_PERIOD', 3, n_deaths_out_obs, n_deaths, cast(null  as float64)
     from vcbo5u4zdeath_stratum_counts
    where prevalence_year = 'OVERALL'
    union all
    -- (4) decedents whose observation period ends after the death date
     select anchor_event, 'DECEDENTS_PERIOD_ENDS_AFTER_DEATH', 3, sum(period_ends_after_death), 5, cast(null  as float64)
     from decedent_anchor
      group by  anchor_event
    union all
    -- (5) median days the period runs past death, among those decedents
     select anchor_event, 'MEDIAN_DAYS_PERIOD_ENDS_PAST_DEATH', 3, cast(null  as int64), max(non_null_cnt), min(case when 2.0 * rn >= non_null_cnt
                 then cast(days_past_death  as float64) end)
     from decedent_days_ranked
     group by  1 )
 select anchor_event,
    metric,
    stratum,
    case when n_numerator is not null and n_numerator > 0 and n_numerator <= @min_cell_count
         then -@min_cell_count else n_numerator end as n_numerator,
    n_denominator,
    case when median_days is not null and n_denominator is not null and n_denominator <= @min_cell_count
         then null else median_days end as median_days
 from metrics
 order by  case metric
        when 'PERIOD_TYPE_CONCEPT'                 then 0
        when 'PATIENTS_WITH_MULTIPLE_OBS_PERIODS'  then 1
        when 'DEATHS_OUTSIDE_OBS_PERIOD'           then 2
        when 'DECEDENTS_PERIOD_ENDS_AFTER_DEATH'   then 3
        when 'MEDIAN_DAYS_PERIOD_ENDS_PAST_DEATH'  then 4
        else 9
    end, case anchor_event when 'ALL' then 0 when 'INDEX' then 1 else 2 end, 3 ;
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
-- 23) D. MET-first subgroup, part 3b. The same MET-to-first-specific-DX gap as
--     chunk 22, expressed cumulatively (CDF) so a linking cutoff can be read off
--     directly, plus the median gap.
--     For the MET_FIRST_THEN_DX group of chunk 20, the number of patients whose
--     first specific DX has ARRIVED BY each day threshold after the first MET.
--     Cumulative and monotonically non-decreasing across thresholds:
--
--       n_arrived_by_30d, _45d, _60d, _90d, _180d, _365d
--
--     Thresholds 30/45/60/90 are the candidate cutoffs; 180/365 give the longer
--     shape. All time is AFTER the first MET by construction, so there is no before
--     side and no day-0 mass. Patients whose specific DX arrives after 365 days are
--     the >1-year tail, derivable as n_patients_reaching_dx_total - n_arrived_by_365d.
--
--     median_days_met_to_dx: median gap (days) among the same patients, using the
--     framework's ordered-set median convention (lower-middle value for even n, as
--     in chunks 16-17 and 00_setup.sql).
--
--     Denominator (n_patients_reaching_dx_total):
--       MET-first patients who reach a specific DX (same as chunk 22). Under the
--       corrected DX-anchored population every MET-first patient reaches a specific
--       DX, so this equals the full MET-first subgroup.
--
--     Population and observation-period notes: same as chunk 20 (DX-anchored MET
--     population from #met_events, first specific DX from #dx_events, anchored on
--     #anchor_person, no observation-period gate).
--
--     Small-cell suppression: each cumulative count in (0, @min_cell_count] set to
--     -@min_cell_count; median set to NULL when its denominator is suppressed.
--     n_patients_reaching_dx_total is an aggregate denominator, not suppressed.
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
    select
        ma.person_id,
        DATE_DIFF(IF(SAFE_CAST(dx.first_dx_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(dx.first_dx_date  AS STRING)),SAFE_CAST(dx.first_dx_date  AS DATE)), IF(SAFE_CAST(ma.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ma.first_met_date  AS STRING)),SAFE_CAST(ma.first_met_date  AS DATE)), DAY) as gap_days
    from met_all ma
    join dx_all dx
      on dx.person_id = ma.person_id
    where ma.first_met_date < dx.first_dx_date
),
med as (
    select min(case when 2.0 * rn >= cnt then cast(gap_days  as float64) end) as median_days
    from (
        select
            gap_days,
            row_number() over (order by gap_days) as rn,
            count(*)     over ()                  as cnt
        from gap
    ) x
),
agg as (
    select
        count(*)                                          as n_total,
        sum(case when gap_days <= 30  then 1 else 0 end)  as n_by_30,
        sum(case when gap_days <= 45  then 1 else 0 end)  as n_by_45,
        sum(case when gap_days <= 60  then 1 else 0 end)  as n_by_60,
        sum(case when gap_days <= 90  then 1 else 0 end)  as n_by_90,
        sum(case when gap_days <= 180 then 1 else 0 end)  as n_by_180,
        sum(case when gap_days <= 365 then 1 else 0 end)  as n_by_365
    from gap
)
select
    a.n_total as n_patients_reaching_dx_total,
    case when a.n_by_30  > 0 and a.n_by_30  <= @min_cell_count then -@min_cell_count else a.n_by_30  end as n_arrived_by_30d,
    case when a.n_by_45  > 0 and a.n_by_45  <= @min_cell_count then -@min_cell_count else a.n_by_45  end as n_arrived_by_45d,
    case when a.n_by_60  > 0 and a.n_by_60  <= @min_cell_count then -@min_cell_count else a.n_by_60  end as n_arrived_by_60d,
    case when a.n_by_90  > 0 and a.n_by_90  <= @min_cell_count then -@min_cell_count else a.n_by_90  end as n_arrived_by_90d,
    case when a.n_by_180 > 0 and a.n_by_180 <= @min_cell_count then -@min_cell_count else a.n_by_180 end as n_arrived_by_180d,
    case when a.n_by_365 > 0 and a.n_by_365 <= @min_cell_count then -@min_cell_count else a.n_by_365 end as n_arrived_by_365d,
    case when a.n_total <= @min_cell_count then null else m.median_days end as median_days_met_to_dx
from agg a
cross join med m
;
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
-- 25) H. Metastasis-to-treatment timing (Part 1 support) <U+2014> reconciliation of the
--     two treated-patient populations Part 2 uses, and the bilateral-treatment
--     count referenced in the Part 1 caption.
--     Part 2 deliberately reads its two cumulative curves over DIFFERENT
--     denominators (AA's decision, 13 Jul 2026): the before-curve and the signed
--     histogram are CLOSEST-based, while the after-curve is over EVERY patient with
--     any antineoplastic (L01) record strictly after the first Metastasis. This
--     chunk quantifies exactly how those populations relate, so the after-curve's
--     superset construction is auditable rather than asserted. One row.
--
--     Over the treated MET patients (>= 1 L01 record), per-patient side flags are
--     built from the signed L01-to-first-MET distances:
--       has_before = any L01 record strictly before the first MET (days_diff < 0)
--       has_day0   = any L01 record on the first MET date        (days_diff = 0)
--       has_after  = any L01 record strictly after the first MET (days_diff > 0)
--     and each treated patient's CLOSEST side (BEFORE / DAY0 / AFTER) is taken from
--     the single closest record (same convention as chunk 24).
--
--     Columns (each a patient count over the treated subgroup):
--       n_treated                   before + day0 + after treated patients
--                                   (= chunk 24 before + day0 + after)
--       n_closest_after             treated patients whose CLOSEST record is after
--                                   the first MET (the histogram's after bars, and
--                                   the old closest-after after-curve population)
--       n_after_any                 treated patients with ANY strictly-after L01
--                                   record (the Part 2 after-curve denominator);
--                                   a SUPERSET of n_closest_after
--       n_after_any_added           n_after_any - n_closest_after: patients added to
--                                   the after-curve by re-basing it on any-after
--                                   rather than closest-after (their closest record
--                                   is before or on the MET day, but they also have
--                                   a real after-MET record)
--       n_bilateral                 treated patients with a record on BOTH sides
--                                   (has_before = 1 AND has_after = 1)
--       n_bilateral_closest_before  bilateral patients whose CLOSEST record is
--                                   before the MET (collapsed to the before side by
--                                   the closest-only view; these are the core of
--                                   n_after_any_added)
--       n_bilateral_closest_after   bilateral patients whose CLOSEST record is after
--                                   the MET (already inside n_closest_after)
--
--     JUDGMENT CALL / FLAG (after = strictly after, day 0 excluded). The after-curve
--     population is patients with any record with days_diff > 0. Day 0 is its own
--     explicit category and belongs to NEITHER curve, per the locked design
--     principle and the approved mock. The task prose phrased this as "on or after,"
--     but the mock (source of truth) and the day-0-explicit rule make it strictly
--     after; day-0 treatment is not counted toward the after-curve. Flagged rather
--     than silently decided.
--
--     JUDGMENT CALL / FLAG (superset arithmetic). n_after_any_added collects
--     every treated patient with an after-MET record whose closest record is NOT
--     after: closest-before-with-after (= n_bilateral_closest_before) plus the
--     residual closest-on-day-0-with-after. The mock modelled the added group as
--     40 closest-before patients only and assumed no day-0-closest patient also has
--     a later after-MET record; in real data that day-0 residual may be non-zero,
--     so n_after_any is computed directly as "any strictly-after record" and will
--     be >= the mock's 392 + 40 decomposition. n_after_any_added minus
--     n_bilateral_closest_before is that day-0 residual.
--
--     Population, observation-period and L01-source notes: same as chunk 24
--     (DX-anchored MET population from #met_events; L01 from #l01_events, gated to the
--     same #anchor_person cohort; no observation-period gate). No change to 00_setup.sql.
--
--     Small-cell suppression: each count in (0, @min_cell_count] set to
--     -@min_cell_count.
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
flags as (
    -- Per treated patient: which sides of the first MET carry any L01 record.
     select person_id,
        max(case when days_diff < 0 then 1 else 0 end) as has_before,
        max(case when days_diff = 0 then 1 else 0 end) as has_day0,
        max(case when days_diff > 0 then 1 else 0 end) as has_after
     from pair
     group by  1 ),
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
closest_side as (
    select
        person_id,
        case when days_diff < 0 then 'BEFORE'
             when days_diff = 0 then 'DAY0'
             else                    'AFTER' end as cside
    from closest
    where rn = 1
),
combined as (
    select
        f.person_id,
        f.has_before,
        f.has_after,
        cs.cside
    from flags f
    join closest_side cs
      on cs.person_id = f.person_id
),
agg as (
    select
        count(*)                                                                       as n_treated,
        sum(case when cside = 'AFTER' then 1 else 0 end)                               as n_closest_after,
        sum(has_after)                                                                 as n_after_any,
        sum(case when has_before = 1 and has_after = 1 then 1 else 0 end)              as n_bilateral,
        sum(case when has_before = 1 and has_after = 1 and cside = 'BEFORE' then 1 else 0 end) as n_bilateral_closest_before,
        sum(case when has_before = 1 and has_after = 1 and cside = 'AFTER'  then 1 else 0 end) as n_bilateral_closest_after
    from combined
)
select
    case when n_treated                  > 0 and n_treated                  <= @min_cell_count then -@min_cell_count else n_treated                  end as n_treated,
    case when n_closest_after            > 0 and n_closest_after            <= @min_cell_count then -@min_cell_count else n_closest_after            end as n_closest_after,
    case when n_after_any                > 0 and n_after_any                <= @min_cell_count then -@min_cell_count else n_after_any                end as n_after_any,
    case when (n_after_any - n_closest_after) > 0 and (n_after_any - n_closest_after) <= @min_cell_count then -@min_cell_count else (n_after_any - n_closest_after) end as n_after_any_added,
    case when n_bilateral                > 0 and n_bilateral                <= @min_cell_count then -@min_cell_count else n_bilateral                end as n_bilateral,
    case when n_bilateral_closest_before > 0 and n_bilateral_closest_before <= @min_cell_count then -@min_cell_count else n_bilateral_closest_before end as n_bilateral_closest_before,
    case when n_bilateral_closest_after  > 0 and n_bilateral_closest_after  <= @min_cell_count then -@min_cell_count else n_bilateral_closest_after  end as n_bilateral_closest_after
from agg
;
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
-- 27) H. Metastasis-to-treatment timing (Part 2, before-curve) <U+2014> cumulative reach
--     of the CLOSEST-before treatment, over the closest-before patients.
--     Over the patients whose CLOSEST antineoplastic (L01) record is strictly
--     before the first Metastasis (chunk 24 CLOSEST_L01_BEFORE_MET), the number
--     whose closest-before record sits WITHIN each day threshold before the first
--     MET. Cumulative and monotonically non-decreasing across thresholds. Reads
--     "how far back the nearest before-MET treatment sits":
--
--       n_within_30d_before, _60d, _90d, _180d, _365d
--
--     days_before = ABS(days_diff) of the closest record (all values >= 1 by
--     construction; day 0 is a separate central category, not on this curve). The
--     curve is CLOSEST-based, so it agrees with the histogram's before bars
--     (chunk 26, bin_order 1-6). Patients whose closest-before treatment is more
--     than 365 days before the MET are the earlier-than-one-year tail, derivable as
--     n_before_total - n_within_365d_before.
--
--     median_days_before_closest: median days_before among the same patients, using
--     the framework's ordered-set median convention (lower-middle value for even n,
--     as in chunks 16-17, 23 and 00_setup.sql).
--
--     Denominator (n_before_total):
--       closest-before patients (= chunk 24 CLOSEST_L01_BEFORE_MET n_patients).
--
--     NOTE (direction). This is the BEFORE curve. It reads leftward (backward in
--     time) from the first MET and uses its own directional denominator; it is
--     never combined with the after-curve into a symmetric window.
--
--     Population, observation-period and L01-source notes: same as chunk 24
--     (DX-anchored MET population from #met_events; L01 from #l01_events, gated to the
--     same #anchor_person cohort; no observation-period gate). No change to 00_setup.sql.
--
--     Small-cell suppression: each cumulative count in (0, @min_cell_count] set to
--     -@min_cell_count; median set to NULL when its denominator is suppressed.
--     n_before_total is an aggregate denominator, not suppressed.
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
before_closest as (
    -- Closest record is strictly before the first MET.
    select
        person_id,
        abs(days_diff) as days_before
    from closest
    where rn = 1
      and days_diff < 0
),
med as (
    select min(case when 2.0 * rn >= cnt then cast(days_before  as float64) end) as median_days
    from (
        select
            days_before,
            row_number() over (order by days_before) as rn,
            count(*)     over ()                     as cnt
        from before_closest
    ) x
),
agg as (
    select
        count(*)                                           as n_total,
        sum(case when days_before <= 30  then 1 else 0 end) as n_30,
        sum(case when days_before <= 60  then 1 else 0 end) as n_60,
        sum(case when days_before <= 90  then 1 else 0 end) as n_90,
        sum(case when days_before <= 180 then 1 else 0 end) as n_180,
        sum(case when days_before <= 365 then 1 else 0 end) as n_365
    from before_closest
)
select
    a.n_total as n_before_total,
    case when a.n_30  > 0 and a.n_30  <= @min_cell_count then -@min_cell_count else a.n_30  end as n_within_30d_before,
    case when a.n_60  > 0 and a.n_60  <= @min_cell_count then -@min_cell_count else a.n_60  end as n_within_60d_before,
    case when a.n_90  > 0 and a.n_90  <= @min_cell_count then -@min_cell_count else a.n_90  end as n_within_90d_before,
    case when a.n_180 > 0 and a.n_180 <= @min_cell_count then -@min_cell_count else a.n_180 end as n_within_180d_before,
    case when a.n_365 > 0 and a.n_365 <= @min_cell_count then -@min_cell_count else a.n_365 end as n_within_365d_before,
    case when a.n_total <= @min_cell_count then null else m.median_days end as median_days_before_closest
from agg a
cross join med m
;
-- 28) H. Metastasis-to-treatment timing (Part 2, after-curve) <U+2014> cumulative reach
--     of the FIRST after-Metastasis treatment, over EVERY patient with any
--     after-Metastasis treatment (the re-based after population, AA's decision
--     13 Jul 2026).
--     Over the patients who have ANY antineoplastic (L01) record strictly after the
--     first Metastasis (days_diff > 0), timed by that patient's FIRST such record
--     (the minimum positive days_diff), the number whose first after-MET treatment
--     has arrived WITHIN each day threshold after the first MET. Cumulative and
--     monotonically non-decreasing:
--
--       n_within_30d_after, _60d, _90d, _180d, _365d
--
--     This is the forward attribution window: for any forward window it reads the
--     share of everyone eventually treated after the MET who is captured by that
--     window. Patients whose first after-MET treatment is more than 365 days out
--     are the later-than-one-year tail, derivable as
--     n_after_any_total - n_within_365d_after.
--
--     median_days_after_first: median first-after-MET days among the same patients,
--     framework ordered-set median convention (lower-middle for even n, as in
--     chunks 16-17, 23, 27 and 00_setup.sql).
--
--     Denominator (n_after_any_total):
--       patients with any strictly-after L01 record (= chunk 25 n_after_any). This
--       is a SUPERSET of the closest-after patients (chunk 25 n_closest_after and
--       the histogram after bars, chunk 26): it adds patients whose closest record
--       is before or on the MET day but who also have a genuine after-MET record.
--       Consequently this curve is NOT the cumulative of the histogram's after bars,
--       by design.
--
--     JUDGMENT CALL / FLAG (population definition, differs from before-curve and
--     histogram). Unlike the CLOSEST-based before-curve (chunk 27) and histogram
--     (chunk 26), this after-curve is over the ANY-strictly-after population and is
--     timed by each patient's FIRST after-MET record, not their closest record.
--       - Day 0 is excluded (strictly after, days_diff > 0), consistent with the
--         locked day-0-explicit principle; day-0 treatment is on neither curve. The
--         task prose said "on or after," reconciled here to strictly after per the
--         mock (source of truth) and the day-0 rule.
--       - A patient with treatment ONLY before the MET and none strictly after
--         correctly falls OUT of this curve (no positive days_diff, so absent from
--         the WHERE days_diff > 0 set).
--       - A closest-before patient who ALSO has an after-MET record is INCLUDED
--         here (via their after record) while remaining on the before side of the
--         histogram and before-curve; this is the intended superset behaviour.
--
--     Population, observation-period and L01-source notes: same as chunk 24
--     (DX-anchored MET population from #met_events; L01 from #l01_events, gated to the
--     same #anchor_person cohort; no observation-period gate). No change to 00_setup.sql.
--
--     Small-cell suppression: each cumulative count in (0, @min_cell_count] set to
--     -@min_cell_count; median set to NULL when its denominator is suppressed.
--     n_after_any_total is an aggregate denominator, not suppressed.
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
        DATE_DIFF(IF(SAFE_CAST(la.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(la.event_date  AS STRING)),SAFE_CAST(la.event_date  AS DATE)), IF(SAFE_CAST(ma.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ma.first_met_date  AS STRING)),SAFE_CAST(ma.first_met_date  AS DATE)), DAY) as days_diff
    from met_all ma
    join l01_all la
      on la.person_id = ma.person_id
),
after_first as (
    -- One row per patient with any strictly-after record: their first after-MET day.
     select person_id,
        min(days_diff) as first_after_days
     from pair
    where days_diff > 0
     group by  1 ),
med as (
    select min(case when 2.0 * rn >= cnt then cast(first_after_days  as float64) end) as median_days
    from (
        select
            first_after_days,
            row_number() over (order by first_after_days) as rn,
            count(*)     over ()                          as cnt
        from after_first
    ) x
),
agg as (
    select
        count(*)                                                as n_total,
        sum(case when first_after_days <= 30  then 1 else 0 end) as n_30,
        sum(case when first_after_days <= 60  then 1 else 0 end) as n_60,
        sum(case when first_after_days <= 90  then 1 else 0 end) as n_90,
        sum(case when first_after_days <= 180 then 1 else 0 end) as n_180,
        sum(case when first_after_days <= 365 then 1 else 0 end) as n_365
    from after_first
)
select
    a.n_total as n_after_any_total,
    case when a.n_30  > 0 and a.n_30  <= @min_cell_count then -@min_cell_count else a.n_30  end as n_within_30d_after,
    case when a.n_60  > 0 and a.n_60  <= @min_cell_count then -@min_cell_count else a.n_60  end as n_within_60d_after,
    case when a.n_90  > 0 and a.n_90  <= @min_cell_count then -@min_cell_count else a.n_90  end as n_within_90d_after,
    case when a.n_180 > 0 and a.n_180 <= @min_cell_count then -@min_cell_count else a.n_180 end as n_within_180d_after,
    case when a.n_365 > 0 and a.n_365 <= @min_cell_count then -@min_cell_count else a.n_365 end as n_within_365d_after,
    case when a.n_total <= @min_cell_count then null else m.median_days end as median_days_after_first
from agg a
cross join med m
;
-- 29) G. Drug Therapy procedure characterization, part 1a. Where each patient's
--     antineoplastic treatment signal lives, ON OR AFTER the first Metastasis.
--     Each patient who carries an anchor Metastasis (MET) code (and therefore also
--     an anchor DX code) is placed in exactly one category by the source of their
--     treatment signal on or after their first MET date:
--
--       DRUG_EXPOSURE_ON_OR_AFTER_MET  >= 1 antineoplastic (L01) drug_exposure
--                                        record on or after the first MET
--                                        (captured by the current L01 analysis,
--                                        whether or not a procedure is also present)
--       DTP_ONLY_ON_OR_AFTER_MET       no such drug_exposure, but >= 1 Drug Therapy
--                                        procedure on or after the first MET
--                                        (procedure-only; missed by the current
--                                        L01 analysis)
--       NEITHER_ON_OR_AFTER_MET        no treatment signal of either kind on or
--                                        after the first MET (includes patients
--                                        treated only BEFORE the first MET)
--
--     "On or after" = event_date >= first_met_date. Day 0 (a record on the first
--     MET date) counts on the on-or-after side, its own explicit inclusion, never
--     treated as before. The window is unbounded on the right (no end cap),
--     confirmed with AA. The DTP_ONLY group is the completeness signal: these
--     patients received metastatic-disease treatment yet look treatment-naive in
--     the drug-level analysis.
--
--     WHY ON-OR-AFTER-MET AND NOT WHOLE-RECORD (design note). G exists to size
--     procedure-only capture of metastatic-disease treatment specifically. An
--     unanchored whole-record check would hide it: a patient with adjuvant
--     drug_exposure years before ever developing metastatic disease, then only
--     procedure codes near their metastatic treatment, would read as
--     "drug_exposure present" and look fully captured. Scoping to on or after the
--     first MET places that patient in DTP_ONLY where they belong. Treatment
--     before the first MET is a different quantity and is held in NEITHER, the
--     same convention Analysis H (chunk 24) uses for pre-MET treatment.
--
--     Denominator (n_patients_met_total, repeated on each row):
--       all patients with >= 1 anchor MET measurement code AND >= 1 anchor DX code
--       at this site (the three categories sum to this total). This is the same
--       DX-anchored first-Metastasis cohort used in Analyses D and H.
--
--     POPULATION. The MET population is built from #met_events (00_setup.sql, section
--     F): @cdm_database_schema.measurement JOIN #met_concepts JOIN #anchor_person, so
--     every patient carries an anchor DX code. The cohort is DX-anchored; a MET code
--     is observed WITHIN it, never as a separate entry point. A generic MET code
--     without an anchor DX gives no evidence of the cancer of interest, so no
--     "MET-only, no DX" patient exists. Identical DX-anchored population to Analyses
--     D and H (chunks 20-28).
--
--     L01 AND DTP SOURCES. Antineoplastic drug_exposure records come from #l01_events
--     (drug_exposure JOIN #l01_concepts JOIN #anchor_person, 00_setup.sql section F),
--     gated to the same DX anchor cohort as the MET population. Drug Therapy
--     procedures come from @cdm_database_schema.procedure_occurrence JOIN
--     #dtp_concepts; there is no procedure event table in setup, so the join to the
--     DX-anchored met_all restricts them to the same cohort. Both signals are
--     therefore evaluated over exactly the DX-anchored MET patients.
--
--     JUDGMENT CALL / FLAG (observation period). Neither the MET population nor the
--     treatment records are restricted to an observation period. The population is
--     anchored on "has an anchor DX code" (#anchor_person), not "inside an
--     observation period" (#cohort). Observation-period coverage is characterized
--     separately in Analysis E (chunks 16-17). See the report for the recommendation.
--
--     Small-cell suppression: n_patients in (0, @min_cell_count] set to
--     -@min_cell_count. n_patients_met_total is an aggregate denominator, not
--     suppressed. A category with zero patients is absent (as in chunks 20-28).
with met_all as (
    -- DX-anchored MET population: earliest MET date per patient (#met_events is
    -- gated to #anchor_person and carries no observation-period gate).
     select person_id,
        min(event_date) as first_met_date
     from vcbo5u4zmet_events
     group by  1 ),
drugexp_flag as (
    -- MET patients with >= 1 antineoplastic drug_exposure on or after the first MET.
    -- #l01_events is gated to #anchor_person, the same cohort as met_all.
    select distinct ma.person_id
    from met_all ma
    join vcbo5u4zl01_events le
      on le.person_id = ma.person_id
    where le.event_date >= ma.first_met_date
),
dtp_flag as (
    -- MET patients with >= 1 Drug Therapy procedure on or after the first MET.
    -- No procedure event table exists in setup; the join to the DX-anchored met_all
    -- restricts procedure_occurrence to the same cohort.
    select distinct ma.person_id
    from met_all ma
    join @cdm_database_schema.procedure_occurrence po
      on po.person_id = ma.person_id
    join vcbo5u4zdtp_concepts dtp
      on po.procedure_concept_id = dtp.concept_id
    where po.procedure_date >= ma.first_met_date
),
classified as (
    select
        ma.person_id,
        case
            when d.person_id is not null then 'DRUG_EXPOSURE_ON_OR_AFTER_MET'
            when p.person_id is not null then 'DTP_ONLY_ON_OR_AFTER_MET'
            else                              'NEITHER_ON_OR_AFTER_MET'
        end as signal_source
    from met_all ma
    left join drugexp_flag d on d.person_id = ma.person_id
    left join dtp_flag     p on p.person_id = ma.person_id
),
totals as (
    select count(*) as n_patients_met_total from met_all
)
   select c.signal_source,
    case when count(*) > 0 and count(*) <= @min_cell_count then -@min_cell_count
         else count(*) end as n_patients,
    t.n_patients_met_total
   from classified c
cross join totals t
  group by  c.signal_source, t.n_patients_met_total
   order by  case c.signal_source
        when 'DRUG_EXPOSURE_ON_OR_AFTER_MET' then 0
        when 'DTP_ONLY_ON_OR_AFTER_MET'      then 1
        when 'NEITHER_ON_OR_AFTER_MET'       then 2
        else 9
    end
  ;
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
-- 32) G. Drug Therapy procedure characterization, part 3. Does an antineoplastic
--     drug_exposure sit near the Drug Therapy procedure, per procedure concept.
--     For patients who carry a Drug Therapy procedure (DTP) of a given concept root,
--     the number who also have an antineoplastic (L01) drug_exposure record within a
--     fixed window of the procedure date. Directional: a drug_exposure in the window
--     BEFORE the procedure, ON the procedure day (day 0), and in the window AFTER the
--     procedure are counted separately and never combined into one symmetric window.
--     All candidate window widths are emitted in one row so the report / UI can read
--     off any before/after pair:
--
--       n_patients_with_procedure   patients carrying this DTP concept root
--                                    (the row denominator)
--       n_drugexp_le{7,14,30,90}d_before
--                                    of those, how many have an L01 record whose
--                                    closest occurrence before a procedure of this
--                                    root is within 7 / 14 / 30 / 90 days
--       n_drugexp_on_day0            how many have an L01 record on a procedure day
--       n_drugexp_le{7,14,30,90}d_after
--                                    closest L01 after a procedure within 7/14/30/90 d
--       n_drugexp_ever               how many have any L01 record at any time (context)
--
--     Timing is measured from EACH procedure of the root: a patient counts in the
--     "within N days before" column if any of their L01 records falls 1..N days
--     before any of their procedures of that root (via the closest such record).
--     The before / day-0 / after columns can overlap for a patient, so they need not
--     sum. A high share means the procedure is corroborated by the drug table and
--     adds little new capture; a low share means the procedure is largely the only
--     record that treatment happened for that concept.
--
--     Denominator (n_patients_with_procedure, per row):
--       patients who carry a Drug Therapy procedure of this concept root WITHIN the
--       DX-anchored cohort (they also carry an anchor DX code). Part 3 characterizes
--       procedure/drug redundancy per concept root, across the cohort rather than
--       only the metastatic subset, so its per-concept denominators exceed the MET
--       count but are still bounded by the DX-anchored cohort.
--
--     JUDGMENT CALL / FLAG (DX-anchoring, changed in this revision). This chunk now
--     restricts both the DTP procedures and the L01 records to the DX-anchored cohort
--     (#anchor_person), the same entry point as every other analysis in the package.
--     Previously it read procedure_occurrence and drug_exposure UNGATED over all
--     persons, including patients with no anchor cancer DX at all. Under the corrected
--     foundational principle (every patient in this analysis carries an anchor DX code
--     by construction), a Drug Therapy procedure or L01 record in a patient with no
--     anchor DX gives no evidence about the cancer of interest's coding, the same
--     argument that governs the Metastasis population in Analyses D, G-part-1 and H.
--     Restricting to #anchor_person makes G-part-3 consistent with that principle.
--     Note this does change the per-concept denominators versus the earlier ungated
--     output: they are now smaller (cohort-only). This chunk does NOT use the MET
--     population; MET-scoping would be wrong for a general procedure/drug redundancy
--     check, so the correct anchoring here is the DX cohort, not the MET subset. If
--     the intent is instead a cohort-independent instrument check (redundancy of the
--     procedure concept itself across the whole database), revert the three
--     #anchor_person joins below; flagged for AA rather than assumed.
--
--     JUDGMENT CALL / FLAG (observation period). Not restricted to an observation
--     period, consistent with the rest of Analyses D, G and H. Anchored on
--     #anchor_person (has an anchor DX code), not #cohort (DX inside an observation
--     period). See the report for the recommendation.
--
--     JUDGMENT CALL / FLAG (suppression of the per-concept denominator).
--     n_patients_with_procedure is itself a per-concept patient count, so it is
--     suppressed like the other per-concept cells (chunk 06 convention): a value in
--     (0, @min_cell_count] is set to -@min_cell_count. When it is suppressed the
--     report cannot form a share for that row, the intended disclosure-control
--     behaviour. Every co-occurrence count is suppressed the same way. A root carried
--     by zero patients is absent.
with proc_carriers as (
    -- Distinct patients carrying each DTP concept root (row denominator), restricted
    -- to the DX-anchored cohort (#anchor_person).
    select distinct
        po.person_id,
        dtp.root_concept_id
    from @cdm_database_schema.procedure_occurrence po
    join vcbo5u4zanchor_person ap
      on ap.person_id = po.person_id
    join vcbo5u4zdtp_concepts dtp
      on po.procedure_concept_id = dtp.concept_id
),
proc_dates as (
    -- Distinct (patient, root, procedure_date) for the timing comparison, restricted
    -- to the DX-anchored cohort.
    select distinct
        po.person_id,
        dtp.root_concept_id,
        po.procedure_date
    from @cdm_database_schema.procedure_occurrence po
    join vcbo5u4zanchor_person ap
      on ap.person_id = po.person_id
    join vcbo5u4zdtp_concepts dtp
      on po.procedure_concept_id = dtp.concept_id
),
l01_dates as (
    -- Distinct antineoplastic drug_exposure dates per patient. #l01_events is already
    -- gated to #anchor_person (drug_exposure JOIN #l01_concepts JOIN #anchor_person).
    select distinct
        person_id,
        event_date as l01_date
    from vcbo5u4zl01_events
),
pairs as (
    -- Signed gap from each procedure to each L01 record of the same patient.
    -- gap_days = DATEDIFF(procedure_date, l01_date): negative = L01 before the
    -- procedure, 0 = same day, positive = L01 after the procedure.
    select
        pd.person_id,
        pd.root_concept_id,
        DATE_DIFF(IF(SAFE_CAST(ld.l01_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ld.l01_date  AS STRING)),SAFE_CAST(ld.l01_date  AS DATE)), IF(SAFE_CAST(pd.procedure_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(pd.procedure_date  AS STRING)),SAFE_CAST(pd.procedure_date  AS DATE)), DAY) as gap_days
    from proc_dates pd
    join l01_dates ld
      on ld.person_id = pd.person_id
),
per_patient as (
    -- Per (patient, root): closest L01 on each side and any-ever flag.
     select person_id,
        root_concept_id,
        min(case when gap_days < 0 then -gap_days end) as closest_before_days,
        max(case when gap_days = 0 then 1 else 0 end)  as has_day0,
        min(case when gap_days > 0 then gap_days end)  as closest_after_days,
        1                                              as has_l01_ever
     from pairs
     group by  1, 2 ),
joined as (
    -- All procedure carriers; co-occurrence attributes NULL when the patient has
    -- no L01 record at all (still counted in the denominator, contributes 0).
    select
        c.person_id,
        c.root_concept_id,
        pp.closest_before_days,
        pp.has_day0,
        pp.closest_after_days,
        pp.has_l01_ever
    from proc_carriers c
    left join per_patient pp
      on pp.person_id = c.person_id
     and pp.root_concept_id = c.root_concept_id
),
agg as (
     select root_concept_id,
        count(*)                                                          as n_with_proc,
        sum(case when closest_before_days <= 7   then 1 else 0 end)        as n_before_7d,
        sum(case when closest_before_days <= 14  then 1 else 0 end)        as n_before_14d,
        sum(case when closest_before_days <= 30  then 1 else 0 end)        as n_before_30d,
        sum(case when closest_before_days <= 90  then 1 else 0 end)        as n_before_90d,
        sum(case when has_day0 = 1               then 1 else 0 end)        as n_day0,
        sum(case when closest_after_days <= 7    then 1 else 0 end)        as n_after_7d,
        sum(case when closest_after_days <= 14   then 1 else 0 end)        as n_after_14d,
        sum(case when closest_after_days <= 30   then 1 else 0 end)        as n_after_30d,
        sum(case when closest_after_days <= 90   then 1 else 0 end)        as n_after_90d,
        sum(case when has_l01_ever = 1           then 1 else 0 end)        as n_ever
     from joined
     group by  1 )
 select a.root_concept_id,
    case when a.n_with_proc  > 0 and a.n_with_proc  <= @min_cell_count then -@min_cell_count else a.n_with_proc  end as n_patients_with_procedure,
    case when a.n_before_7d  > 0 and a.n_before_7d  <= @min_cell_count then -@min_cell_count else a.n_before_7d  end as n_drugexp_le7d_before,
    case when a.n_before_14d > 0 and a.n_before_14d <= @min_cell_count then -@min_cell_count else a.n_before_14d end as n_drugexp_le14d_before,
    case when a.n_before_30d > 0 and a.n_before_30d <= @min_cell_count then -@min_cell_count else a.n_before_30d end as n_drugexp_le30d_before,
    case when a.n_before_90d > 0 and a.n_before_90d <= @min_cell_count then -@min_cell_count else a.n_before_90d end as n_drugexp_le90d_before,
    case when a.n_day0       > 0 and a.n_day0       <= @min_cell_count then -@min_cell_count else a.n_day0       end as n_drugexp_on_day0,
    case when a.n_after_7d   > 0 and a.n_after_7d   <= @min_cell_count then -@min_cell_count else a.n_after_7d   end as n_drugexp_le7d_after,
    case when a.n_after_14d  > 0 and a.n_after_14d  <= @min_cell_count then -@min_cell_count else a.n_after_14d  end as n_drugexp_le14d_after,
    case when a.n_after_30d  > 0 and a.n_after_30d  <= @min_cell_count then -@min_cell_count else a.n_after_30d  end as n_drugexp_le30d_after,
    case when a.n_after_90d  > 0 and a.n_after_90d  <= @min_cell_count then -@min_cell_count else a.n_after_90d  end as n_drugexp_le90d_after,
    case when a.n_ever       > 0 and a.n_ever       <= @min_cell_count then -@min_cell_count else a.n_ever       end as n_drugexp_ever
 from agg a
 order by  a.n_with_proc desc, a.root_concept_id
 ;
-- 33) B. General cancer diagnosis (GDX) coding trajectory <U+2014> part 1, categorical
--     trajectory breakdown. Every patient in the anchor cohort (INDEX = first
--     specific Diagnosis, #cohort.index_date) is placed in exactly one category by
--     where their General cancer diagnosis (broad / non-specific "any malignant
--     neoplasm"-type ancestor) codes fall relative to that first specific Diagnosis:
--
--       NONE                          no general cancer diagnosis code anywhere
--       GENERAL_BEFORE_ONLY           general code(s) only strictly before the
--                                       first specific Diagnosis (days < 0):
--                                       pre-diagnostic / workup coding
--       GENERAL_BOTH_BEFORE_AND_AFTER general code(s) on both sides: at least one
--                                       strictly before AND at least one at or
--                                       after the first specific Diagnosis
--       GENERAL_AFTER_ONLY            general code(s) only at or after the first
--                                       specific Diagnosis (days >= 0): reversion
--                                       to non-specific coding once specific
--
--     Purpose: exclusion-criteria safety. A phenotype that excludes "any malignant
--     neoplasm" via general codes would drop the BEFORE_ONLY and BOTH patients,
--     whose general code appears before their specific Diagnosis and is really the
--     same disease being worked up. This chunk quantifies that population.
--
--     Denominator (n_cohort_total, repeated on each row):
--       the full anchor cohort = every patient with a first specific Diagnosis
--       inside an observation period (#cohort, the INDEX population).
--
--     JUDGMENT CALL / FLAG (day-0 convention in the four categories). The four
--     categories use the same before(days < 0) / at-or-after(days >= 0) split as the
--     approved V3 mock and chunk 06's ever_before / ever_after convention, so the
--     category counts reconcile exactly to the validated HUS numbers (of 618
--     patients with a general code: before-only 74 / both 186 / after-only 358). A
--     general code falling exactly on the first-Diagnosis date (day 0) is therefore
--     counted on the at-or-after side. To honour the framework's day-0-explicit
--     principle WITHOUT changing those validated totals, the extra column
--     n_general_at_day0 reports, within each category, how many patients carry a
--     general code exactly at day 0. The fully day-0-separated timing (before / at
--     day 0 / after as distinct masses) is delivered in chunks 34 (first-general
--     timing CDF) and 35 (per-concept windowed counts). If a pure four-column
--     breakdown is preferred, the n_general_at_day0 column can be dropped without
--     affecting the category counts.
--
--     JUDGMENT CALL / FLAG (anchor). This trajectory is anchored to the first
--     specific Diagnosis (INDEX) only, matching Analysis B's spec ("relative to the
--     first specific DX") and the approved V3 mock. A first-Metastasis-anchored
--     variant is not part of B; general-code prevalence around the first Metastasis
--     is covered generically by chunk 06.
--
--     Population note. #gen_cancer_events is restricted to anchor-cohort persons in
--     00_setup.sql; #cohort is the observation-period-gated DX cohort and is a
--     subset of those persons, so the join is complete. General-code dates are not
--     themselves restricted to an observation period, matching the mock ("anywhere
--     in the record" relative to the first specific Diagnosis).
--
--     Small-cell suppression: n_patients and n_general_at_day0 in (0, @min_cell_count]
--     set to -@min_cell_count. n_cohort_total is an aggregate denominator, not
--     suppressed. A category with zero patients is absent.
with gdx_flags as (
    -- Per anchor-cohort patient with >= 1 general cancer diagnosis code:
    -- flags for whether any code sits strictly before, exactly at, or strictly
    -- after the first specific Diagnosis.
     select g.person_id,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) <  0 then 1 else 0 end) as has_before,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) =  0 then 1 else 0 end) as has_day0,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) >  0 then 1 else 0 end) as has_after_strict
     from vcbo5u4zgen_cancer_events g
    join vcbo5u4zcohort c
      on g.person_id = c.person_id
     group by  g.person_id
 ),
classified as (
    -- Every cohort patient placed in exactly one category. at_or_after folds the
    -- day-0 mass onto the after side to reconcile with the validated HUS counts;
    -- has_day0 is retained separately for the explicit day-0 column.
    select
        c.person_id,
        case
            when g.person_id is null                                      then 'NONE'
            when g.has_before = 1 and (g.has_day0 = 1 or g.has_after_strict = 1) then 'GENERAL_BOTH_BEFORE_AND_AFTER'
            when g.has_before = 1                                         then 'GENERAL_BEFORE_ONLY'
            else                                                               'GENERAL_AFTER_ONLY'
        end as trajectory_category,
        case when g.has_day0 = 1 then 1 else 0 end as at_day0
    from vcbo5u4zcohort c
    left join gdx_flags g
      on g.person_id = c.person_id
),
totals as (
    select count(*) as n_cohort_total from vcbo5u4zcohort
)
   select c.trajectory_category,
    case when count(*) > 0 and count(*) <= @min_cell_count
         then -@min_cell_count else count(*) end as n_patients,
    case when sum(c.at_day0) > 0 and sum(c.at_day0) <= @min_cell_count
         then -@min_cell_count else sum(c.at_day0) end as n_general_at_day0,
    t.n_cohort_total
   from classified c
cross join totals t
  group by  c.trajectory_category, t.n_cohort_total
   order by  case c.trajectory_category
        when 'NONE'                          then 0
        when 'GENERAL_BEFORE_ONLY'           then 1
        when 'GENERAL_BOTH_BEFORE_AND_AFTER' then 2
        when 'GENERAL_AFTER_ONLY'            then 3
        else 9
    end
  ;
-- 34) B. General cancer diagnosis (GDX) coding trajectory <U+2014> part 2, timing of the
--     FIRST general cancer diagnosis code relative to the first specific Diagnosis
--     (INDEX = #cohort.index_date), directional and CDF-style, with day 0 explicit.
--     Over the anchor-cohort patients who carry at least one general cancer
--     diagnosis code, each patient contributes one signed gap:
--
--       signed_days = first_general_code_date - first_specific_diagnosis_date
--
--     negative = the first general code precedes the first specific Diagnosis
--     (pre-diagnostic / workup coding); zero = same calendar day; positive = the
--     first general code follows the first specific Diagnosis.
--
--     Three directional masses (mutually exclusive, sum to n_with_general_code):
--       n_first_general_before   signed_days < 0
--       n_first_general_day0     signed_days = 0   (explicit central category)
--       n_first_general_after    signed_days > 0
--
--     Cumulative (CDF) reach on each side, counted outward from day 0 and
--     monotonically non-decreasing across thresholds:
--       before side (subset of n_first_general_before):
--         n_first_general_within_30d_before   -30 <= signed_days <= -1
--         _90d, _180d, _365d                  wider look-back windows
--         tail earlier than 1 year before = n_first_general_before - within_365d_before
--       after side (subset of n_first_general_after):
--         n_first_general_within_30d_after     1 <= signed_days <= 30
--         _90d, _180d, _365d                   wider follow-up windows
--         tail later than 1 year after = n_first_general_after - within_365d_after
--
--     median_signed_days_first_general: median of signed_days over all patients with
--     a general code (single value; positive means the first general code typically
--     follows the first specific Diagnosis). Framework ordered-set median convention
--     (lower-middle value for even n, as in chunks 16-17, 23, 27 and 00_setup.sql).
--     Validation reference: the approved V3 mock reports a first-general-to-first-
--     Diagnosis median of +11 days at HUS with a long pre-diagnostic (before) tail.
--
--     NOTE (direction). Before and after use their own outward-cumulative counts and
--     are never combined into a symmetric window; day 0 is its own mass, not folded
--     into the after side.
--
--     Denominator (n_with_general_code, repeated on the single row):
--       anchor-cohort patients with >= 1 general cancer diagnosis code (the union of
--       the three trajectory categories in chunk 33; validated HUS total = 618).
--
--     Population note. Uses #gen_cancer_summary.first_gen_cancer_date, the earliest
--     general-code date per cohort patient (built in 00_setup.sql over
--     #gen_cancer_events joined to #cohort). General-code dates are not restricted to
--     an observation period, matching the mock.
--
--     Small-cell suppression: each directional/cumulative count in (0, @min_cell_count]
--     set to -@min_cell_count; median set to NULL when its denominator
--     (n_with_general_code) is suppressed. n_with_general_code is an aggregate
--     denominator, not suppressed.
with first_general as (
    -- Signed gap from the first specific Diagnosis to the patient's first general
    -- cancer diagnosis code, one row per cohort patient who carries a general code.
    select
        gs.person_id,
        DATE_DIFF(IF(SAFE_CAST(gs.first_gen_cancer_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(gs.first_gen_cancer_date  AS STRING)),SAFE_CAST(gs.first_gen_cancer_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as signed_days
    from vcbo5u4zgen_cancer_summary gs
    join vcbo5u4zcohort c
      on gs.person_id = c.person_id
    where gs.first_gen_cancer_date is not null
),
med as (
    select min(case when 2.0 * rn >= cnt then cast(signed_days  as float64) end) as median_days
    from (
        select
            signed_days,
            row_number() over (order by signed_days) as rn,
            count(*)     over ()                     as cnt
        from first_general
    ) x
),
agg as (
    select
        count(*) as n_total,
        sum(case when signed_days <  0 then 1 else 0 end) as n_before,
        sum(case when signed_days =  0 then 1 else 0 end) as n_day0,
        sum(case when signed_days >  0 then 1 else 0 end) as n_after,
        sum(case when signed_days >= -30  and signed_days <= -1 then 1 else 0 end) as n_b30,
        sum(case when signed_days >= -90  and signed_days <= -1 then 1 else 0 end) as n_b90,
        sum(case when signed_days >= -180 and signed_days <= -1 then 1 else 0 end) as n_b180,
        sum(case when signed_days >= -365 and signed_days <= -1 then 1 else 0 end) as n_b365,
        sum(case when signed_days >= 1   and signed_days <= 30  then 1 else 0 end) as n_a30,
        sum(case when signed_days >= 1   and signed_days <= 90  then 1 else 0 end) as n_a90,
        sum(case when signed_days >= 1   and signed_days <= 180 then 1 else 0 end) as n_a180,
        sum(case when signed_days >= 1   and signed_days <= 365 then 1 else 0 end) as n_a365
    from first_general
)
select
    a.n_total as n_with_general_code,
    case when a.n_before > 0 and a.n_before <= @min_cell_count then -@min_cell_count else a.n_before end as n_first_general_before,
    case when a.n_b30    > 0 and a.n_b30    <= @min_cell_count then -@min_cell_count else a.n_b30    end as n_first_general_within_30d_before,
    case when a.n_b90    > 0 and a.n_b90    <= @min_cell_count then -@min_cell_count else a.n_b90    end as n_first_general_within_90d_before,
    case when a.n_b180   > 0 and a.n_b180   <= @min_cell_count then -@min_cell_count else a.n_b180   end as n_first_general_within_180d_before,
    case when a.n_b365   > 0 and a.n_b365   <= @min_cell_count then -@min_cell_count else a.n_b365   end as n_first_general_within_365d_before,
    case when a.n_day0   > 0 and a.n_day0   <= @min_cell_count then -@min_cell_count else a.n_day0   end as n_first_general_day0,
    case when a.n_after  > 0 and a.n_after  <= @min_cell_count then -@min_cell_count else a.n_after  end as n_first_general_after,
    case when a.n_a30    > 0 and a.n_a30    <= @min_cell_count then -@min_cell_count else a.n_a30    end as n_first_general_within_30d_after,
    case when a.n_a90    > 0 and a.n_a90    <= @min_cell_count then -@min_cell_count else a.n_a90    end as n_first_general_within_90d_after,
    case when a.n_a180   > 0 and a.n_a180   <= @min_cell_count then -@min_cell_count else a.n_a180   end as n_first_general_within_180d_after,
    case when a.n_a365   > 0 and a.n_a365   <= @min_cell_count then -@min_cell_count else a.n_a365   end as n_first_general_within_365d_after,
    case when a.n_total <= @min_cell_count then null else m.median_days end as median_signed_days_first_general
from agg a
cross join med m
;
-- 35) B. General cancer diagnosis (GDX) coding trajectory <U+2014> part 3, per-concept
--     directional windowed counts. One row per general cancer diagnosis (broad /
--     non-specific ancestor) concept carried by the anchor cohort, with the number
--     of distinct cohort patients holding a code of that concept in each window
--     relative to the first specific Diagnosis (INDEX = #cohort.index_date). All
--     timing is directional with day 0 explicit:
--
--       days = general_code_date - first_specific_diagnosis_date
--
--     Columns (distinct patients holding >= 1 code of the concept in the region;
--     the three regions overlap, so before + at day 0 + after can exceed n_patients
--     because one patient may hold codes on more than one side):
--       n_patients        any time (the concept's overall patient count)
--       before side (strictly before, days < 0), cumulative outward from day 0:
--         n_before_30d   -30 <= days <= -1
--         n_before_90d, n_before_180d, n_before_365d
--         n_ever_before  days < 0 (no upper look-back bound)
--       n_at_day0         days = 0 (explicit central category)
--       after side (strictly after, days > 0), cumulative outward from day 0:
--         n_after_30d     1 <= days <= 30
--         n_after_90d, n_after_180d, n_after_365d
--         n_ever_after   days > 0 (no upper follow-up bound)
--
--     Purpose: exclusion-criteria safety at the concept level. Concepts carried
--     mostly BEFORE the first specific Diagnosis (high n_ever_before) are the ones a
--     naive "any malignant neoplasm" exclusion would wrongly remove; the report
--     builds an adjustable capture window from these directional counts.
--
--     JUDGMENT CALL / FLAG (directional vs the mock's modelled split). The approved
--     V3 mock supplied REAL HUS patient counts per concept (n_patients / ever, and
--     ever-before / ever-after) but MODELLED the by-window before/after split from
--     symmetric +/-30/90/180/365 counts because a directional windowed output did
--     not yet exist. This chunk produces that directional output directly: the
--     before and after windows are true strictly-before and strictly-after counts,
--     not a modelled split of a symmetric window, and day 0 is its own separate
--     mass. Two columns reconcile exactly to the mock's real counts: n_patients
--     matches the mock "ever" (e.g. Malignant tumor of kidney 368, Primary malignant
--     neoplasm of urinary system 57) and n_ever_before matches the mock ever-before
--     (kidney 164, urinary system 14). n_ever_after here is strictly after (days > 0)
--     with day 0 carved out into n_at_day0, so it is <= the mock's ever-after, which
--     used days >= 0; this is the intended day-0-explicit correction.
--
--     JUDGMENT CALL / FLAG (concept coverage and the >10 filter). All general
--     cancer diagnosis concepts present in the cohort are emitted, each cell
--     small-cell suppressed, matching chunk 06's behaviour. The approved mock's
--     "more than 10 patients" cut-off is an adjustable DISPLAY threshold applied by
--     the report builder, not a hard filter here, so the report can raise or lower
--     it without re-running SQL.
--
--     JUDGMENT CALL / FLAG (anchor). INDEX (first specific Diagnosis) only, matching
--     Analysis B's spec and the approved mock. General-code prevalence around the
--     first Metastasis is covered generically by chunk 06.
--
--     Denominator: n_patients per concept (on the row); the anchor-cohort total
--     (chunk 33 n_cohort_total) is the population base for the report's
--     percent-of-cohort figures.
--
--     Population note. #gen_cancer_events is restricted to anchor-cohort persons in
--     00_setup.sql and joined to #cohort here; general-code dates are not restricted
--     to an observation period, matching the mock.
--
--     Small-cell suppression: every count in (0, @min_cell_count] set to
--     -@min_cell_count.
with patient_concept as (
    -- Per (concept, patient): flags for each directional window. days is the
    -- general code date minus the first specific Diagnosis date.
     select g.concept_id,
        g.person_id,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) >= -30  and DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) <= -1 then 1 else 0 end) as in_before_30d,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) >= -90  and DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) <= -1 then 1 else 0 end) as in_before_90d,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) >= -180 and DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) <= -1 then 1 else 0 end) as in_before_180d,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) >= -365 and DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) <= -1 then 1 else 0 end) as in_before_365d,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) <  0 then 1 else 0 end) as in_ever_before,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) =  0 then 1 else 0 end) as in_day0,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) >= 1 and DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) <= 30  then 1 else 0 end) as in_after_30d,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) >= 1 and DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) <= 90  then 1 else 0 end) as in_after_90d,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) >= 1 and DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) <= 180 then 1 else 0 end) as in_after_180d,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) >= 1 and DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) <= 365 then 1 else 0 end) as in_after_365d,
        max(case when DATE_DIFF(IF(SAFE_CAST(g.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(g.event_date  AS STRING)),SAFE_CAST(g.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) >  0 then 1 else 0 end) as in_ever_after
     from vcbo5u4zgen_cancer_events g
    join vcbo5u4zcohort c
      on g.person_id = c.person_id
     group by  g.concept_id, g.person_id
 ),
agg as (
     select concept_id,
        count(*)               as n_patients,
        sum(in_before_30d)     as n_before_30d,
        sum(in_before_90d)     as n_before_90d,
        sum(in_before_180d)    as n_before_180d,
        sum(in_before_365d)    as n_before_365d,
        sum(in_ever_before)    as n_ever_before,
        sum(in_day0)           as n_at_day0,
        sum(in_after_30d)      as n_after_30d,
        sum(in_after_90d)      as n_after_90d,
        sum(in_after_180d)     as n_after_180d,
        sum(in_after_365d)     as n_after_365d,
        sum(in_ever_after)     as n_ever_after
     from patient_concept
     group by  1 )
 select a.concept_id,
    case when a.n_patients    > 0 and a.n_patients    <= @min_cell_count then -@min_cell_count else a.n_patients    end as n_patients,
    case when a.n_before_30d  > 0 and a.n_before_30d  <= @min_cell_count then -@min_cell_count else a.n_before_30d  end as n_before_30d,
    case when a.n_before_90d  > 0 and a.n_before_90d  <= @min_cell_count then -@min_cell_count else a.n_before_90d  end as n_before_90d,
    case when a.n_before_180d > 0 and a.n_before_180d <= @min_cell_count then -@min_cell_count else a.n_before_180d end as n_before_180d,
    case when a.n_before_365d > 0 and a.n_before_365d <= @min_cell_count then -@min_cell_count else a.n_before_365d end as n_before_365d,
    case when a.n_ever_before > 0 and a.n_ever_before <= @min_cell_count then -@min_cell_count else a.n_ever_before end as n_ever_before,
    case when a.n_at_day0     > 0 and a.n_at_day0     <= @min_cell_count then -@min_cell_count else a.n_at_day0     end as n_at_day0,
    case when a.n_after_30d   > 0 and a.n_after_30d   <= @min_cell_count then -@min_cell_count else a.n_after_30d   end as n_after_30d,
    case when a.n_after_90d   > 0 and a.n_after_90d   <= @min_cell_count then -@min_cell_count else a.n_after_90d   end as n_after_90d,
    case when a.n_after_180d  > 0 and a.n_after_180d  <= @min_cell_count then -@min_cell_count else a.n_after_180d  end as n_after_180d,
    case when a.n_after_365d  > 0 and a.n_after_365d  <= @min_cell_count then -@min_cell_count else a.n_after_365d  end as n_after_365d,
    case when a.n_ever_after  > 0 and a.n_ever_after  <= @min_cell_count then -@min_cell_count else a.n_ever_after  end as n_ever_after
 from agg a
 order by  a.n_patients desc, a.concept_id
 ;

