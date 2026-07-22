-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/33_b_gdx_trajectory_categories.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

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

