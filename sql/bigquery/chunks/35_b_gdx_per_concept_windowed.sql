-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/35_b_gdx_per_concept_windowed.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

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

