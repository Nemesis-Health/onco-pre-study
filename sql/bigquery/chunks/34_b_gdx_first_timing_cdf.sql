-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-07-15 15:37:23 CEST
-- Source file    : sql/sql_server/chunks/34_b_gdx_first_timing_cdf.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

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

