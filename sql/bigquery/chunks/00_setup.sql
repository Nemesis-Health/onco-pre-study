-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-04-26 18:36:18 BST
-- Source file    : sql/sql_server/chunks/00_setup.sql
-- DO NOT EDIT — edit the sql_server source and re-run
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
-- Source: cohort_definitions/UC.json — ConceptSets id 7 "UC - Malignant neoplasm"
-- Expanded with concept_ancestor (includeDescendants / isExcluded match Atlas).
------------------------------------------------------------
drop table if exists x0brquscdx_anchor_include;
DROP TABLE IF EXISTS x0brquscdx_anchor_include;
CREATE TABLE x0brquscdx_anchor_include (
    concept_id INT64 not null,
    include_descendants smallint not null
);
insert into x0brquscdx_anchor_include (concept_id, include_descendants) values
    (197508, 1),      -- Malignant neoplasm of urinary bladder
    (4181357, 1),     -- Malignant tumor of renal pelvis
    (4177230, 1),     -- Malignant tumor of urethra
    (37163176, 1),    -- Transitional cell carcinoma of upper urinary tract
    (4178972, 1),     -- Malignant tumor of ureter
    (4091486, 0),     -- Malignant neoplasm of overlapping sites of urinary organs
    (44501785, 0),    -- Transitional cell carcinoma, NOS, of urinary system, NOS (ICDO3)
    (37110270, 1)     -- Primary urothelial carcinoma of overlapping sites of urinary organs
;
drop table if exists x0brquscdx_anchor_exclude;
DROP TABLE IF EXISTS x0brquscdx_anchor_exclude;
CREATE TABLE x0brquscdx_anchor_exclude (
    concept_id INT64 not null,
    include_descendants smallint not null
);
insert into x0brquscdx_anchor_exclude (concept_id, include_descendants) values
    (4280899, 1),
    (4289374, 1),
    (4280900, 1),
    (4283614, 1),
    (4289097, 1),
    (4280901, 1),
    (4289376, 1),
    (4280897, 1),
    (4200889, 1);
drop table if exists x0brquscdx_anchor_concepts;
DROP TABLE IF EXISTS x0brquscdx_anchor_concepts;
CREATE TABLE x0brquscdx_anchor_concepts (
    concept_id INT64
);
insert into x0brquscdx_anchor_concepts (concept_id)
select distinct ca.descendant_concept_id
from x0brquscdx_anchor_include i
join @cdm_database_schema.concept_ancestor ca
  on ca.ancestor_concept_id = i.concept_id
 and (i.include_descendants = 1 or ca.descendant_concept_id = i.concept_id);
delete from x0brquscdx_anchor_concepts
where exists (
    select 1
    from x0brquscdx_anchor_exclude e
    join @cdm_database_schema.concept_ancestor ca
      on ca.ancestor_concept_id = e.concept_id
     and x0brquscdx_anchor_concepts.concept_id = ca.descendant_concept_id
     and (e.include_descendants = 1 or ca.descendant_concept_id = e.concept_id)
);
------------------------------------------------------------
-- B) OTHER GENERALIZED CANCER DX CONCEPTS (GDX)
-- Default: distinct ancestors of DX anchor concepts, excluding anchor DX concepts themselves,
-- but constrained to descendants of 443392 (Malignant neoplastic disease) to avoid overly-broad ancestors.
-- (concept_ancestor includes self-links; we only want broader/generalized codes).
------------------------------------------------------------
drop table if exists x0brquscgen_cancer_concepts;
DROP TABLE IF EXISTS x0brquscgen_cancer_concepts;
CREATE TABLE x0brquscgen_cancer_concepts (
    concept_id INT64
);
insert into x0brquscgen_cancer_concepts (concept_id)
select distinct ca.ancestor_concept_id
from @cdm_database_schema.concept_ancestor ca
join x0brquscdx_anchor_concepts d
  on ca.descendant_concept_id = d.concept_id
join @cdm_database_schema.concept_ancestor malign
  on malign.ancestor_concept_id = 443392
 and malign.descendant_concept_id = ca.ancestor_concept_id
where not exists (
    select 1
    from x0brquscdx_anchor_concepts dx
    where dx.concept_id = ca.ancestor_concept_id
)
;
------------------------------------------------------------
-- C) OTHER CANCER DIAGNOSIS CONCEPTS (ODX)
-- Default: descendants of 443392 excluding DX + GDX sets.
------------------------------------------------------------
drop table if exists x0brquscother_dx_ancestor_concepts;
DROP TABLE IF EXISTS x0brquscother_dx_ancestor_concepts;
CREATE TABLE x0brquscother_dx_ancestor_concepts (
    ancestor_concept_id INT64
);
-- EDIT THIS LIST
insert into x0brquscother_dx_ancestor_concepts (ancestor_concept_id)
values
    (443392) -- Malignant neoplastic disease
;
drop table if exists x0brquscother_dx_concepts;
DROP TABLE IF EXISTS x0brquscother_dx_concepts;
CREATE TABLE x0brquscother_dx_concepts (
    concept_id INT64
);
insert into x0brquscother_dx_concepts (concept_id)
select distinct ca.descendant_concept_id
from @cdm_database_schema.concept_ancestor ca
join x0brquscother_dx_ancestor_concepts a
  on ca.ancestor_concept_id = a.ancestor_concept_id
left join x0brquscdx_anchor_concepts dx
  on dx.concept_id = ca.descendant_concept_id
left join x0brquscgen_cancer_concepts gdx
  on gdx.concept_id = ca.descendant_concept_id
where dx.concept_id is null
  and gdx.concept_id is null
;
------------------------------------------------------------
-- D) METASTASIS CONCEPTS (MEASUREMENT)
-- Define via ancestor IDs (descendants pulled from concept_ancestor)
------------------------------------------------------------
drop table if exists x0brquscmet_ancestor_concepts;
DROP TABLE IF EXISTS x0brquscmet_ancestor_concepts;
CREATE TABLE x0brquscmet_ancestor_concepts (
    ancestor_concept_id INT64
);
-- Default: concept set "Secondary malignancy" from cohort_definitions/Target_Cohort_2B.json
insert into x0brquscmet_ancestor_concepts (ancestor_concept_id)
values
    (1633308),  -- AJCC/UICC Stage 4
    (1635142),  -- AJCC/UICC M1 Category
    (36769180)  -- Metastasis
;
drop table if exists x0brquscmet_concepts;
DROP TABLE IF EXISTS x0brquscmet_concepts;
CREATE TABLE x0brquscmet_concepts (
    concept_id INT64
);
insert into x0brquscmet_concepts (concept_id)
select distinct ca.descendant_concept_id
from @cdm_database_schema.concept_ancestor ca
join x0brquscmet_ancestor_concepts a
  on ca.ancestor_concept_id = a.ancestor_concept_id
;
------------------------------------------------------------
-- E) L01 TREATMENT CONCEPTS (DRUG_EXPOSURE)
------------------------------------------------------------
drop table if exists x0brquscl01_ancestor_concepts;
DROP TABLE IF EXISTS x0brquscl01_ancestor_concepts;
CREATE TABLE x0brquscl01_ancestor_concepts (
    ancestor_concept_id INT64
);
-- EDIT THIS LIST
insert into x0brquscl01_ancestor_concepts (ancestor_concept_id)
values
    (21601387)
;
drop table if exists x0brquscl01_concepts;
DROP TABLE IF EXISTS x0brquscl01_concepts;
CREATE TABLE x0brquscl01_concepts (
    concept_id INT64
);
insert into x0brquscl01_concepts (concept_id)
select distinct ca.descendant_concept_id
from @cdm_database_schema.concept_ancestor ca
join x0brquscl01_ancestor_concepts a
  on ca.ancestor_concept_id = a.ancestor_concept_id
;
------------------------------------------------------------
-- F) EVENT TABLES
------------------------------------------------------------
drop table if exists x0brquscdx_events;
DROP TABLE IF EXISTS x0brquscdx_events;
CREATE TABLE x0brquscdx_events (
    person_id INT64,
    event_date date,
    concept_id INT64
);
insert into x0brquscdx_events (person_id, event_date, concept_id)
select
    co.person_id,
    co.condition_start_date,
    co.condition_concept_id
from @cdm_database_schema.condition_occurrence co
join x0brquscdx_anchor_concepts d
  on co.condition_concept_id = d.concept_id
;
-- Distinct anchor cohort persons; limits later F) pulls to rows that downstream joins to #cohort use anyway.
drop table if exists x0brquscanchor_person;
DROP TABLE IF EXISTS x0brquscanchor_person;
CREATE TABLE x0brquscanchor_person (
    person_id INT64
);
insert into x0brquscanchor_person (person_id)
select distinct person_id
from x0brquscdx_events
;
drop table if exists x0brquscother_dx_events;
DROP TABLE IF EXISTS x0brquscother_dx_events;
CREATE TABLE x0brquscother_dx_events (
    person_id INT64,
    event_date date,
    concept_id INT64
);
insert into x0brquscother_dx_events (person_id, event_date, concept_id)
select
    co.person_id,
    co.condition_start_date,
    co.condition_concept_id
from @cdm_database_schema.condition_occurrence co
join x0brquscanchor_person ap
  on co.person_id = ap.person_id
join x0brquscother_dx_concepts d
  on co.condition_concept_id = d.concept_id
;
drop table if exists x0brquscgen_cancer_events;
DROP TABLE IF EXISTS x0brquscgen_cancer_events;
CREATE TABLE x0brquscgen_cancer_events (
    person_id INT64,
    event_date date,
    concept_id INT64
);
insert into x0brquscgen_cancer_events (person_id, event_date, concept_id)
select
    co.person_id,
    co.condition_start_date,
    co.condition_concept_id
from @cdm_database_schema.condition_occurrence co
join x0brquscanchor_person ap
  on co.person_id = ap.person_id
join x0brquscgen_cancer_concepts g
  on co.condition_concept_id = g.concept_id
;
drop table if exists x0brquscmet_events;
DROP TABLE IF EXISTS x0brquscmet_events;
CREATE TABLE x0brquscmet_events (
    person_id INT64,
    event_date date,
    concept_id INT64
);
insert into x0brquscmet_events (person_id, event_date, concept_id)
select
    m.person_id,
    m.measurement_date,
    m.measurement_concept_id
from @cdm_database_schema.measurement m
join x0brquscanchor_person ap
  on m.person_id = ap.person_id
join x0brquscmet_concepts mc
  on m.measurement_concept_id = mc.concept_id
;
drop table if exists x0brquscl01_events;
DROP TABLE IF EXISTS x0brquscl01_events;
CREATE TABLE x0brquscl01_events (
    person_id INT64,
    event_date date,
    concept_id INT64
);
insert into x0brquscl01_events (person_id, event_date, concept_id)
select
    de.person_id,
    de.drug_exposure_start_date,
    de.drug_concept_id
from @cdm_database_schema.drug_exposure de
join x0brquscanchor_person ap
  on de.person_id = ap.person_id
join x0brquscl01_concepts l
  on de.drug_concept_id = l.concept_id
;
-- Ingredient-level L01 events used for concept-level code counts/timing.
drop table if exists x0brquscl01_ingredient_events;
DROP TABLE IF EXISTS x0brquscl01_ingredient_events;
CREATE TABLE x0brquscl01_ingredient_events (
    person_id INT64,
    event_date date,
    concept_id INT64
);
insert into x0brquscl01_ingredient_events (person_id, event_date, concept_id)
select distinct
    de.person_id,
    de.drug_exposure_start_date,
    ca.ancestor_concept_id
from @cdm_database_schema.drug_exposure de
join x0brquscanchor_person ap
  on de.person_id = ap.person_id
join x0brquscl01_concepts l
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
drop table if exists x0brqusccohort;
DROP TABLE IF EXISTS x0brqusccohort;
CREATE TABLE x0brqusccohort (
    person_id INT64,
    index_date date
);
insert into x0brqusccohort (person_id, index_date)
 select person_id,
    min(event_date) as index_date
 from x0brquscdx_events
 group by  1 ;
drop table if exists x0brquscdx_summary;
DROP TABLE IF EXISTS x0brquscdx_summary;
CREATE TABLE x0brquscdx_summary (
    person_id INT64,
    n_dx_records INT64,
    n_dx_codes INT64
);
insert into x0brquscdx_summary (person_id, n_dx_records, n_dx_codes)
 select e.person_id,
    count(*) as n_dx_records,
    count(distinct e.concept_id) as n_dx_codes
 from x0brquscdx_events e
join x0brqusccohort c
  on e.person_id = c.person_id
 group by  e.person_id
 ;
drop table if exists x0brquscother_dx_summary;
DROP TABLE IF EXISTS x0brquscother_dx_summary;
CREATE TABLE x0brquscother_dx_summary (
    person_id INT64,
    first_other_dx_date date,
    n_other_dx_records INT64,
    n_other_dx_codes INT64
);
insert into x0brquscother_dx_summary (person_id, first_other_dx_date, n_other_dx_records, n_other_dx_codes)
 select e.person_id,
    min(e.event_date) as first_other_dx_date,
    count(*) as n_other_dx_records,
    count(distinct e.concept_id) as n_other_dx_codes
 from x0brquscother_dx_events e
join x0brqusccohort c
  on e.person_id = c.person_id
 group by  e.person_id
 ;
drop table if exists x0brquscgen_cancer_summary;
DROP TABLE IF EXISTS x0brquscgen_cancer_summary;
CREATE TABLE x0brquscgen_cancer_summary (
    person_id INT64,
    first_gen_cancer_date date,
    n_gen_cancer_records INT64,
    n_gen_cancer_codes INT64
);
insert into x0brquscgen_cancer_summary (person_id, first_gen_cancer_date, n_gen_cancer_records, n_gen_cancer_codes)
 select e.person_id,
    min(e.event_date) as first_gen_cancer_date,
    count(*) as n_gen_cancer_records,
    count(distinct e.concept_id) as n_gen_cancer_codes
 from x0brquscgen_cancer_events e
join x0brqusccohort c
  on e.person_id = c.person_id
 group by  e.person_id
 ;
drop table if exists x0brquscmet_summary;
DROP TABLE IF EXISTS x0brquscmet_summary;
CREATE TABLE x0brquscmet_summary (
    person_id INT64,
    first_met_date date,
    n_met_records INT64
);
insert into x0brquscmet_summary (person_id, first_met_date, n_met_records)
 select e.person_id,
    min(e.event_date) as first_met_date,
    count(*) as n_met_records
 from x0brquscmet_events e
join x0brqusccohort c
  on e.person_id = c.person_id
 group by  e.person_id
 ;
drop table if exists x0brquscl01_summary;
DROP TABLE IF EXISTS x0brquscl01_summary;
CREATE TABLE x0brquscl01_summary (
    person_id INT64,
    first_l01_date date,
    n_l01_exposures INT64
);
insert into x0brquscl01_summary (person_id, first_l01_date, n_l01_exposures)
 select e.person_id,
    min(e.event_date) as first_l01_date,
    count(*) as n_l01_exposures
 from x0brquscl01_events e
join x0brqusccohort c
  on e.person_id = c.person_id
 group by  e.person_id
 ;
-- H) EVENT CODE COUNTS (single table across event families)
------------------------------------------------------------
drop table if exists x0brquscevent_code_counts;
DROP TABLE IF EXISTS x0brquscevent_code_counts;
CREATE TABLE x0brquscevent_code_counts (
    anchor_event STRING, -- INDEX or FIRST_MET
    event_family STRING,
    concept_id INT64,
    n_records INT64,
    n_patients INT64
);
insert into x0brquscevent_code_counts (anchor_event, event_family, concept_id, n_records, n_patients)
 select 'INDEX', 'DX', concept_id, count(*), count(distinct person_id)
 from x0brquscdx_events
where person_id in (select person_id from x0brqusccohort)
 group by  concept_id
union all
 select 'INDEX', 'ODX', 3, 4, count(distinct person_id)
 from x0brquscother_dx_events
where person_id in (select person_id from x0brqusccohort)
 group by  concept_id
union all
 select 'INDEX', 'GDX', 3, 4, count(distinct person_id)
 from x0brquscgen_cancer_events
where person_id in (select person_id from x0brqusccohort)
 group by  concept_id
union all
 select 'INDEX', 'MET', 3, 4, count(distinct person_id)
 from x0brquscmet_events
where person_id in (select person_id from x0brqusccohort)
 group by  concept_id
union all
 select 'INDEX', 'L01', 3, 4, count(distinct person_id)
 from x0brquscl01_ingredient_events
where person_id in (select person_id from x0brqusccohort)
 group by  concept_id
union all
 select 'FIRST_MET', 2, 3, 4, count(distinct e.person_id)
 from x0brquscdx_events e
join x0brquscmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  concept_id
union all
 select 'FIRST_MET', 2, 3, 4, count(distinct e.person_id)
 from x0brquscother_dx_events e
join x0brquscmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  concept_id
union all
 select 'FIRST_MET', 2, 3, 4, count(distinct e.person_id)
 from x0brquscgen_cancer_events e
join x0brquscmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  concept_id
union all
 select 'FIRST_MET', 2, 3, 4, count(distinct e.person_id)
 from x0brquscmet_events e
join x0brquscmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  concept_id
union all
 select 'FIRST_MET', 2, 3, 4, count(distinct e.person_id)
 from x0brquscl01_ingredient_events e
join x0brquscmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  concept_id
          ;
drop table if exists x0brquscevent_code_counts_before_after;
DROP TABLE IF EXISTS x0brquscevent_code_counts_before_after;
CREATE TABLE x0brquscevent_code_counts_before_after (
    anchor_event STRING, -- INDEX
    event_family STRING,
    time_relative STRING, -- BEFORE or AFTER (relative to index_date)
    concept_id INT64,
    n_records INT64,
    n_patients INT64
);
insert into x0brquscevent_code_counts_before_after (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
 select 'INDEX',
       'DX',
       case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end as time_relative,
       e.concept_id,
       count(*) as n_records,
       count(distinct e.person_id) as n_patients
 from x0brquscdx_events e
join x0brqusccohort c
  on e.person_id = c.person_id
 group by  3, e.concept_id
union all
 select 'INDEX', 'ODX', 3, e.concept_id, 5, count(distinct e.person_id)
 from x0brquscother_dx_events e
join x0brqusccohort c
  on e.person_id = c.person_id
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
union all
 select 'INDEX', 'GDX', 3, e.concept_id, 5, count(distinct e.person_id)
 from x0brquscgen_cancer_events e
join x0brqusccohort c
  on e.person_id = c.person_id
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
union all
 select 'INDEX', 'MET', 3, e.concept_id, 5, count(distinct e.person_id)
 from x0brquscmet_events e
join x0brqusccohort c
  on e.person_id = c.person_id
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
union all
 select 'INDEX', 'L01', 3, e.concept_id, 5, count(distinct e.person_id)
 from x0brquscl01_ingredient_events e
join x0brqusccohort c
  on e.person_id = c.person_id
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
     ;
drop table if exists x0brquscevent_code_counts_before_after_first_met;
DROP TABLE IF EXISTS x0brquscevent_code_counts_before_after_first_met;
CREATE TABLE x0brquscevent_code_counts_before_after_first_met (
    anchor_event STRING, -- FIRST_MET
    event_family STRING,
    time_relative STRING, -- BEFORE or AFTER (relative to first_met_date)
    concept_id INT64,
    n_records INT64,
    n_patients INT64
);
insert into x0brquscevent_code_counts_before_after_first_met (anchor_event, event_family, time_relative, concept_id, n_records, n_patients)
 select 'FIRST_MET',
       'DX',
       case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end as time_relative,
       e.concept_id,
       count(*) as n_records,
       count(distinct e.person_id) as n_patients
 from x0brquscdx_events e
join x0brquscmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  3, e.concept_id
union all
 select 'FIRST_MET', 'ODX', 3, e.concept_id, 5, count(distinct e.person_id)
 from x0brquscother_dx_events e
join x0brquscmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
union all
 select 'FIRST_MET', 'GDX', 3, e.concept_id, 5, count(distinct e.person_id)
 from x0brquscgen_cancer_events e
join x0brquscmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
union all
 select 'FIRST_MET', 'MET', 3, e.concept_id, 5, count(distinct e.person_id)
 from x0brquscmet_events e
join x0brquscmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
union all
 select 'FIRST_MET', 'L01', 3, e.concept_id, 5, count(distinct e.person_id)
 from x0brquscl01_ingredient_events e
join x0brquscmet_summary ms
  on e.person_id = ms.person_id
where ms.first_met_date is not null
 group by  case when DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY) < 0 then 'BEFORE' else 'AFTER' end, e.concept_id
     ;
drop table if exists x0brquscevent_code_all_events;
DROP TABLE IF EXISTS x0brquscevent_code_all_events;
CREATE TABLE x0brquscevent_code_all_events (
    anchor_event STRING,
    event_family STRING,
    concept_id INT64,
    person_id INT64,
    days_diff INT64,
    event_date date
);
insert into x0brquscevent_code_all_events (
    anchor_event, event_family, concept_id, person_id, days_diff, event_date
)
select 'INDEX' as anchor_event, 'DX' as event_family, e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY) as days_diff, e.event_date
from x0brquscdx_events e
join x0brqusccohort c on e.person_id = c.person_id
union all
select 'INDEX', 'ODX', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY), e.event_date
from x0brquscother_dx_events e
join x0brqusccohort c on e.person_id = c.person_id
union all
select 'INDEX', 'GDX', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY), e.event_date
from x0brquscgen_cancer_events e
join x0brqusccohort c on e.person_id = c.person_id
union all
select 'INDEX', 'MET', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY), e.event_date
from x0brquscmet_events e
join x0brqusccohort c on e.person_id = c.person_id
union all
select 'INDEX', 'L01', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY), e.event_date
from x0brquscl01_ingredient_events e
join x0brqusccohort c on e.person_id = c.person_id
union all
select 'FIRST_MET', 'DX', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY), e.event_date
from x0brquscdx_events e
join x0brquscmet_summary ms on e.person_id = ms.person_id
where ms.first_met_date is not null
union all
select 'FIRST_MET', 'ODX', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY), e.event_date
from x0brquscother_dx_events e
join x0brquscmet_summary ms on e.person_id = ms.person_id
where ms.first_met_date is not null
union all
select 'FIRST_MET', 'GDX', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY), e.event_date
from x0brquscgen_cancer_events e
join x0brquscmet_summary ms on e.person_id = ms.person_id
where ms.first_met_date is not null
union all
select 'FIRST_MET', 'MET', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY), e.event_date
from x0brquscmet_events e
join x0brquscmet_summary ms on e.person_id = ms.person_id
where ms.first_met_date is not null
union all
select 'FIRST_MET', 'L01', e.concept_id, e.person_id, DATE_DIFF(IF(SAFE_CAST(e.event_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(e.event_date  AS STRING)),SAFE_CAST(e.event_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY), e.event_date
from x0brquscl01_ingredient_events e
join x0brquscmet_summary ms on e.person_id = ms.person_id
where ms.first_met_date is not null
;
drop table if exists x0brquscevent_code_patient_chosen_first;
DROP TABLE IF EXISTS x0brquscevent_code_patient_chosen_first;
CREATE TABLE x0brquscevent_code_patient_chosen_first (
    anchor_event STRING,
    event_family STRING,
    concept_id INT64,
    person_id INT64,
    days_diff INT64
);
insert into x0brquscevent_code_patient_chosen_first (anchor_event, event_family, concept_id, person_id, days_diff)
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
    from x0brquscevent_code_all_events
) x
where rn = 1
;
drop table if exists x0brquscevent_code_patient_chosen_closest;
DROP TABLE IF EXISTS x0brquscevent_code_patient_chosen_closest;
CREATE TABLE x0brquscevent_code_patient_chosen_closest (
    anchor_event STRING,
    event_family STRING,
    concept_id INT64,
    person_id INT64,
    days_diff INT64
);
insert into x0brquscevent_code_patient_chosen_closest (anchor_event, event_family, concept_id, person_id, days_diff)
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
    from x0brquscevent_code_all_events
) x
where rn = 1
;
drop table if exists x0brquscevent_code_timing_summary;
DROP TABLE IF EXISTS x0brquscevent_code_timing_summary;
CREATE TABLE x0brquscevent_code_timing_summary (
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
insert into x0brquscevent_code_timing_summary (
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
        percentile_cont(0.25) within group (order by days_diff) as lq_days_first,
        percentile_cont(0.50) within group (order by days_diff) as median_days_first,
        percentile_cont(0.75) within group (order by days_diff) as uq_days_first
     from x0brquscevent_code_patient_chosen_first
     group by  1, 2, 3 ) f
inner join (
     select anchor_event,
        event_family,
        concept_id,
        percentile_cont(0.25) within group (order by days_diff) as lq_days_closest,
        percentile_cont(0.50) within group (order by days_diff) as median_days_closest,
        percentile_cont(0.75) within group (order by days_diff) as uq_days_closest
     from x0brquscevent_code_patient_chosen_closest
     group by  1, 2, 3 ) k
  on f.anchor_event = k.anchor_event
 and f.event_family = k.event_family
 and f.concept_id = k.concept_id
;
drop table if exists x0brquscevent_code_ba_events;
DROP TABLE IF EXISTS x0brquscevent_code_ba_events;
CREATE TABLE x0brquscevent_code_ba_events (
    anchor_event STRING,
    event_family STRING,
    time_relative STRING,
    concept_id INT64,
    person_id INT64,
    days_diff INT64,
    event_date date
);
insert into x0brquscevent_code_ba_events (
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
from x0brquscevent_code_all_events
;
drop table if exists x0brquscevent_code_patient_chosen_before_after_first;
DROP TABLE IF EXISTS x0brquscevent_code_patient_chosen_before_after_first;
CREATE TABLE x0brquscevent_code_patient_chosen_before_after_first (
    anchor_event STRING,
    event_family STRING,
    time_relative STRING,
    concept_id INT64,
    person_id INT64,
    days_diff INT64
);
insert into x0brquscevent_code_patient_chosen_before_after_first (
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
    from x0brquscevent_code_ba_events
) x
where rn = 1
;
drop table if exists x0brquscevent_code_patient_chosen_before_after_closest;
DROP TABLE IF EXISTS x0brquscevent_code_patient_chosen_before_after_closest;
CREATE TABLE x0brquscevent_code_patient_chosen_before_after_closest (
    anchor_event STRING,
    event_family STRING,
    time_relative STRING,
    concept_id INT64,
    person_id INT64,
    days_diff INT64
);
insert into x0brquscevent_code_patient_chosen_before_after_closest (
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
    from x0brquscevent_code_ba_events
) x
where rn = 1
;
drop table if exists x0brquscevent_code_timing_before_after_summary;
DROP TABLE IF EXISTS x0brquscevent_code_timing_before_after_summary;
CREATE TABLE x0brquscevent_code_timing_before_after_summary (
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
insert into x0brquscevent_code_timing_before_after_summary (
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
        percentile_cont(0.25) within group (order by days_diff) as lq_days_first,
        percentile_cont(0.50) within group (order by days_diff) as median_days_first,
        percentile_cont(0.75) within group (order by days_diff) as uq_days_first
     from x0brquscevent_code_patient_chosen_before_after_first
     group by  1, 2, 3, 4 ) f
inner join (
     select anchor_event,
        event_family,
        time_relative,
        concept_id,
        percentile_cont(0.25) within group (order by days_diff) as lq_days_closest,
        percentile_cont(0.50) within group (order by days_diff) as median_days_closest,
        percentile_cont(0.75) within group (order by days_diff) as uq_days_closest
     from x0brquscevent_code_patient_chosen_before_after_closest
     group by  1, 2, 3, 4 ) k
  on f.anchor_event = k.anchor_event
 and f.event_family = k.event_family
 and f.time_relative = k.time_relative
 and f.concept_id = k.concept_id
;
------------------------------------------------------------
-- I) PATIENT-LEVEL TABLE
------------------------------------------------------------
drop table if exists x0brquscpatient_char;
DROP TABLE IF EXISTS x0brquscpatient_char;
CREATE TABLE x0brquscpatient_char (
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
insert into x0brquscpatient_char (
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
from x0brqusccohort c
left join x0brquscdx_summary dx
       on c.person_id = dx.person_id
left join x0brquscother_dx_summary odx
       on c.person_id = odx.person_id
left join x0brquscgen_cancer_summary gdx
       on c.person_id = gdx.person_id
left join x0brquscmet_summary mt
       on c.person_id = mt.person_id
left join x0brquscl01_summary l01
       on c.person_id = l01.person_id
;
------------------------------------------------------------
-- J) FULL CROSSWISE TIMING PAIRS
------------------------------------------------------------
drop table if exists x0brquscpatient_timing_pairs;
DROP TABLE IF EXISTS x0brquscpatient_timing_pairs;
CREATE TABLE x0brquscpatient_timing_pairs (
    person_id INT64,
    from_event STRING,
    to_event STRING,
    days_diff INT64
);
INSERT INTO x0brquscpatient_timing_pairs (person_id, from_event, to_event, days_diff)
 WITH events as (
    select person_id, 'DX' as event_name, index_date as event_date from x0brquscpatient_char
    union all
    select person_id, 'ODX', first_other_dx_date from x0brquscpatient_char
    union all
    select person_id, 'GDX', first_gen_cancer_date from x0brquscpatient_char
    union all
    select person_id, 'MET', first_met_date from x0brquscpatient_char
    union all
    select person_id, 'L01', first_l01_date from x0brquscpatient_char
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
drop table if exists x0brqusctiming_pair_summary;
DROP TABLE IF EXISTS x0brqusctiming_pair_summary;
CREATE TABLE x0brqusctiming_pair_summary (
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
insert into x0brqusctiming_pair_summary (
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
    percentile_cont(0.05) within group (order by days_diff) as p05_days,
    percentile_cont(0.10) within group (order by days_diff) as p10_days,
    percentile_cont(0.20) within group (order by days_diff) as p20_days,
    percentile_cont(0.25) within group (order by days_diff) as p25_days,
    percentile_cont(0.30) within group (order by days_diff) as p30_days,
    percentile_cont(0.40) within group (order by days_diff) as p40_days,
    percentile_cont(0.50) within group (order by days_diff) as p50_days,
    percentile_cont(0.60) within group (order by days_diff) as p60_days,
    percentile_cont(0.70) within group (order by days_diff) as p70_days,
    percentile_cont(0.75) within group (order by days_diff) as p75_days,
    percentile_cont(0.80) within group (order by days_diff) as p80_days,
    percentile_cont(0.90) within group (order by days_diff) as p90_days,
    percentile_cont(0.95) within group (order by days_diff) as p95_days
 from x0brquscpatient_timing_pairs
 group by  1, 2 ;
drop table if exists x0brquscall_events_for_pairs;
DROP TABLE IF EXISTS x0brquscall_events_for_pairs;
CREATE TABLE x0brquscall_events_for_pairs (
    person_id INT64,
    event_family STRING,
    event_date date
);
insert into x0brquscall_events_for_pairs (person_id, event_family, event_date)
select person_id, 'DX', event_date from x0brquscdx_events
union all
select person_id, 'ODX', event_date from x0brquscother_dx_events
union all
select person_id, 'GDX', event_date from x0brquscgen_cancer_events
union all
select person_id, 'MET', event_date from x0brquscmet_events
union all
select person_id, 'L01', event_date from x0brquscl01_events
;
drop table if exists x0brquscfirst_event_dates;
DROP TABLE IF EXISTS x0brquscfirst_event_dates;
CREATE TABLE x0brquscfirst_event_dates (
    person_id INT64,
    from_event STRING,
    from_first_date date
);
insert into x0brquscfirst_event_dates (person_id, from_event, from_first_date)
select person_id, 'DX', index_date from x0brquscpatient_char
union all
select person_id, 'ODX', first_other_dx_date from x0brquscpatient_char where first_other_dx_date is not null
union all
select person_id, 'GDX', first_gen_cancer_date from x0brquscpatient_char where first_gen_cancer_date is not null
union all
select person_id, 'MET', first_met_date from x0brquscpatient_char where first_met_date is not null
union all
select person_id, 'L01', first_l01_date from x0brquscpatient_char where first_l01_date is not null
;
drop table if exists x0brquscpatient_timing_pairs_first_to_closest;
DROP TABLE IF EXISTS x0brquscpatient_timing_pairs_first_to_closest;
CREATE TABLE x0brquscpatient_timing_pairs_first_to_closest (
    person_id INT64,
    from_event STRING,
    to_event STRING,
    days_diff INT64
);
INSERT INTO x0brquscpatient_timing_pairs_first_to_closest (person_id, from_event, to_event, days_diff)
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
    from x0brquscfirst_event_dates f
    join x0brquscall_events_for_pairs a
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
drop table if exists x0brqusctiming_pair_summary_first_to_closest;
DROP TABLE IF EXISTS x0brqusctiming_pair_summary_first_to_closest;
CREATE TABLE x0brqusctiming_pair_summary_first_to_closest (
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
insert into x0brqusctiming_pair_summary_first_to_closest (
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
    percentile_cont(0.05) within group (order by days_diff) as p05_days,
    percentile_cont(0.10) within group (order by days_diff) as p10_days,
    percentile_cont(0.20) within group (order by days_diff) as p20_days,
    percentile_cont(0.25) within group (order by days_diff) as p25_days,
    percentile_cont(0.30) within group (order by days_diff) as p30_days,
    percentile_cont(0.40) within group (order by days_diff) as p40_days,
    percentile_cont(0.50) within group (order by days_diff) as p50_days,
    percentile_cont(0.60) within group (order by days_diff) as p60_days,
    percentile_cont(0.70) within group (order by days_diff) as p70_days,
    percentile_cont(0.75) within group (order by days_diff) as p75_days,
    percentile_cont(0.80) within group (order by days_diff) as p80_days,
    percentile_cont(0.90) within group (order by days_diff) as p90_days,
    percentile_cont(0.95) within group (order by days_diff) as p95_days
 from x0brquscpatient_timing_pairs_first_to_closest
 group by  1, 2 ;
drop table if exists x0brquscpatient_timing_pairs_first_to_closest_before;
DROP TABLE IF EXISTS x0brquscpatient_timing_pairs_first_to_closest_before;
CREATE TABLE x0brquscpatient_timing_pairs_first_to_closest_before (
    person_id INT64,
    from_event STRING,
    to_event STRING,
    days_diff INT64
);
INSERT INTO x0brquscpatient_timing_pairs_first_to_closest_before (person_id, from_event, to_event, days_diff)
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
    from x0brquscfirst_event_dates f
    join x0brquscall_events_for_pairs a
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
drop table if exists x0brqusctiming_pair_summary_first_to_closest_before;
DROP TABLE IF EXISTS x0brqusctiming_pair_summary_first_to_closest_before;
CREATE TABLE x0brqusctiming_pair_summary_first_to_closest_before (
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
insert into x0brqusctiming_pair_summary_first_to_closest_before (
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
    percentile_cont(0.05) within group (order by days_diff) as p05_days,
    percentile_cont(0.10) within group (order by days_diff) as p10_days,
    percentile_cont(0.20) within group (order by days_diff) as p20_days,
    percentile_cont(0.25) within group (order by days_diff) as p25_days,
    percentile_cont(0.30) within group (order by days_diff) as p30_days,
    percentile_cont(0.40) within group (order by days_diff) as p40_days,
    percentile_cont(0.50) within group (order by days_diff) as p50_days,
    percentile_cont(0.60) within group (order by days_diff) as p60_days,
    percentile_cont(0.70) within group (order by days_diff) as p70_days,
    percentile_cont(0.75) within group (order by days_diff) as p75_days,
    percentile_cont(0.80) within group (order by days_diff) as p80_days,
    percentile_cont(0.90) within group (order by days_diff) as p90_days,
    percentile_cont(0.95) within group (order by days_diff) as p95_days
 from x0brquscpatient_timing_pairs_first_to_closest_before
 group by  1, 2 ;
drop table if exists x0brquscpatient_timing_pairs_first_to_closest_after;
DROP TABLE IF EXISTS x0brquscpatient_timing_pairs_first_to_closest_after;
CREATE TABLE x0brquscpatient_timing_pairs_first_to_closest_after (
    person_id INT64,
    from_event STRING,
    to_event STRING,
    days_diff INT64
);
INSERT INTO x0brquscpatient_timing_pairs_first_to_closest_after (person_id, from_event, to_event, days_diff)
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
    from x0brquscfirst_event_dates f
    join x0brquscall_events_for_pairs a
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
drop table if exists x0brqusctiming_pair_summary_first_to_closest_after;
DROP TABLE IF EXISTS x0brqusctiming_pair_summary_first_to_closest_after;
CREATE TABLE x0brqusctiming_pair_summary_first_to_closest_after (
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
insert into x0brqusctiming_pair_summary_first_to_closest_after (
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
    percentile_cont(0.05) within group (order by days_diff) as p05_days,
    percentile_cont(0.10) within group (order by days_diff) as p10_days,
    percentile_cont(0.20) within group (order by days_diff) as p20_days,
    percentile_cont(0.25) within group (order by days_diff) as p25_days,
    percentile_cont(0.30) within group (order by days_diff) as p30_days,
    percentile_cont(0.40) within group (order by days_diff) as p40_days,
    percentile_cont(0.50) within group (order by days_diff) as p50_days,
    percentile_cont(0.60) within group (order by days_diff) as p60_days,
    percentile_cont(0.70) within group (order by days_diff) as p70_days,
    percentile_cont(0.75) within group (order by days_diff) as p75_days,
    percentile_cont(0.80) within group (order by days_diff) as p80_days,
    percentile_cont(0.90) within group (order by days_diff) as p90_days,
    percentile_cont(0.95) within group (order by days_diff) as p95_days
 from x0brquscpatient_timing_pairs_first_to_closest_after
 group by  1, 2 ;
drop table if exists x0brquscevent_presence;
DROP TABLE IF EXISTS x0brquscevent_presence;
CREATE TABLE x0brquscevent_presence (
    person_id INT64,
    has_dx INT64,
    has_odx INT64,
    has_gdx INT64,
    has_met INT64,
    has_l01 INT64
);
insert into x0brquscevent_presence (
    person_id, has_dx, has_odx, has_gdx, has_met, has_l01
)
select
    person_id,
    1,
    case when first_other_dx_date is not null then 1 else 0 end,
    case when first_gen_cancer_date is not null then 1 else 0 end,
    case when first_met_date is not null then 1 else 0 end,
    case when first_l01_date is not null then 1 else 0 end
from x0brquscpatient_char
;
------------------------------------------------------------
-- J-bis) DEATH TIMING FROM INDEX AND FIRST_MET ANCHORS
------------------------------------------------------------
drop table if exists x0brquscdeath_index_long;
DROP TABLE IF EXISTS x0brquscdeath_index_long;
CREATE TABLE x0brquscdeath_index_long (
    prevalence_year STRING,
    days_to_death INT64
);
insert into x0brquscdeath_index_long (prevalence_year, days_to_death)
select 'OVERALL', DATE_DIFF(IF(SAFE_CAST(d.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(d.death_date  AS STRING)),SAFE_CAST(d.death_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY)
from x0brqusccohort c
inner join (
     select person_id, min(death_date) as death_date
     from @cdm_database_schema.death
     group by  1 ) d on d.person_id = c.person_id
where d.death_date >= c.index_date
union all
select cast(EXTRACT(YEAR from c.index_date) as STRING), DATE_DIFF(IF(SAFE_CAST(d.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(d.death_date  AS STRING)),SAFE_CAST(d.death_date  AS DATE)), IF(SAFE_CAST(c.index_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(c.index_date  AS STRING)),SAFE_CAST(c.index_date  AS DATE)), DAY)
from x0brqusccohort c
inner join (
     select person_id, min(death_date) as death_date
     from @cdm_database_schema.death
     group by  1 ) d on d.person_id = c.person_id
where d.death_date >= c.index_date
;
drop table if exists x0brquscdeath_first_met_long;
DROP TABLE IF EXISTS x0brquscdeath_first_met_long;
CREATE TABLE x0brquscdeath_first_met_long (
    prevalence_year STRING,
    days_to_death INT64
);
insert into x0brquscdeath_first_met_long (prevalence_year, days_to_death)
select 'OVERALL', DATE_DIFF(IF(SAFE_CAST(d.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(d.death_date  AS STRING)),SAFE_CAST(d.death_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY)
from x0brqusccohort c
inner join x0brquscmet_summary ms on c.person_id = ms.person_id and ms.first_met_date is not null
inner join (
     select person_id, min(death_date) as death_date
     from @cdm_database_schema.death
     group by  1 ) d on d.person_id = c.person_id
where d.death_date >= ms.first_met_date
union all
select cast(EXTRACT(YEAR from c.index_date) as STRING), DATE_DIFF(IF(SAFE_CAST(d.death_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(d.death_date  AS STRING)),SAFE_CAST(d.death_date  AS DATE)), IF(SAFE_CAST(ms.first_met_date  AS DATE) IS NULL,PARSE_DATE('%Y%m%d', cast(ms.first_met_date  AS STRING)),SAFE_CAST(ms.first_met_date  AS DATE)), DAY)
from x0brqusccohort c
inner join x0brquscmet_summary ms on c.person_id = ms.person_id and ms.first_met_date is not null
inner join (
     select person_id, min(death_date) as death_date
     from @cdm_database_schema.death
     group by  1 ) d on d.person_id = c.person_id
where d.death_date >= ms.first_met_date
;
drop table if exists x0brquscdeath_stratum_counts;
DROP TABLE IF EXISTS x0brquscdeath_stratum_counts;
CREATE TABLE x0brquscdeath_stratum_counts (
    prevalence_year STRING,
    anchor_event STRING,
    n_patients INT64,
    n_deaths INT64
);
insert into x0brquscdeath_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths)
 select case
        when grouping(EXTRACT(YEAR from c.index_date)) = 1 then 'OVERALL'
        else cast(EXTRACT(YEAR from c.index_date) as STRING)
    end,
    'INDEX',
    count(*),
    sum(case when d.death_date is not null and d.death_date >= c.index_date then 1 else 0 end)
 from x0brqusccohort c
left join (
     select person_id, min(death_date) as death_date
     from @cdm_database_schema.death
     group by  1 ) d on d.person_id = c.person_id
 group by  grouping sets ((), (EXTRACT(YEAR from c.index_date)))
 ;
insert into x0brquscdeath_stratum_counts (prevalence_year, anchor_event, n_patients, n_deaths)
 select case
        when grouping(EXTRACT(YEAR from c.index_date)) = 1 then 'OVERALL'
        else cast(EXTRACT(YEAR from c.index_date) as STRING)
    end,
    'FIRST_MET',
    count(*),
    sum(case when d.death_date is not null and d.death_date >= ms.first_met_date then 1 else 0 end)
 from x0brqusccohort c
inner join x0brquscmet_summary ms on c.person_id = ms.person_id and ms.first_met_date is not null
left join (
     select person_id, min(death_date) as death_date
     from @cdm_database_schema.death
     group by  1 ) d on d.person_id = c.person_id
 group by  grouping sets ((), (EXTRACT(YEAR from c.index_date)))
 ;
drop table if exists x0brquscdeath_timing_long;
DROP TABLE IF EXISTS x0brquscdeath_timing_long;
CREATE TABLE x0brquscdeath_timing_long (
    prevalence_year STRING,
    anchor_event STRING,
    days_to_death INT64
);
insert into x0brquscdeath_timing_long (prevalence_year, anchor_event, days_to_death)
select prevalence_year, 'INDEX', days_to_death from x0brquscdeath_index_long
union all
select prevalence_year, 'FIRST_MET', days_to_death from x0brquscdeath_first_met_long
;
drop table if exists x0brquscdeath_timing_quantiles;
DROP TABLE IF EXISTS x0brquscdeath_timing_quantiles;
CREATE TABLE x0brquscdeath_timing_quantiles (
    prevalence_year STRING,
    anchor_event STRING,
    n_deaths_in_dist INT64,
    p05_days FLOAT64,
    p10_days FLOAT64,
    lq_days FLOAT64,
    median_days FLOAT64,
    uq_days FLOAT64,
    p90_days FLOAT64,
    p95_days FLOAT64
);
insert into x0brquscdeath_timing_quantiles (
    prevalence_year,
    anchor_event,
    n_deaths_in_dist,
    p05_days,
    p10_days,
    lq_days,
    median_days,
    uq_days,
    p90_days,
    p95_days
)
 select prevalence_year,
    anchor_event,
    count(*) as n_deaths_in_dist,
    percentile_cont(0.05) within group (order by days_to_death) as p05_days,
    percentile_cont(0.10) within group (order by days_to_death) as p10_days,
    percentile_cont(0.25) within group (order by days_to_death) as lq_days,
    percentile_cont(0.50) within group (order by days_to_death) as median_days,
    percentile_cont(0.75) within group (order by days_to_death) as uq_days,
    percentile_cont(0.90) within group (order by days_to_death) as p90_days,
    percentile_cont(0.95) within group (order by days_to_death) as p95_days
 from x0brquscdeath_timing_long
 group by  1, 2 ;
------------------------------------------------------------
-- K) FINAL SELECTS (export to CSV from SQL client)
------------------------------------------------------------

