-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:27 CEST
-- Source file    : sql/sql_server/chunks/34_b_gdx_first_timing_cdf.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH first_general AS (
 -- Signed gap from the first specific Diagnosis to the patient's first general
 -- cancer diagnosis code, one row per cohort patient who carries a general code.
 SELECT
 gs.person_id,
 DATEDIFF(DAY, c.index_date, gs.first_gen_cancer_date) AS signed_days
 FROM vcbo5u4zgen_cancer_summary gs
 JOIN vcbo5u4zcohort c
 ON gs.person_id = c.person_id
 WHERE gs.first_gen_cancer_date IS NOT NULL
),
med AS (
 SELECT MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(signed_days AS FLOAT) END) AS median_days
 FROM (
 SELECT
 signed_days,
 ROW_NUMBER() OVER (ORDER BY signed_days) AS rn,
 COUNT(*) OVER () AS cnt
 FROM first_general
 ) x
),
agg AS (
 SELECT
 COUNT(*) AS n_total,
 SUM(CASE WHEN signed_days < 0 THEN 1 ELSE 0 END) AS n_before,
 SUM(CASE WHEN signed_days = 0 THEN 1 ELSE 0 END) AS n_day0,
 SUM(CASE WHEN signed_days > 0 THEN 1 ELSE 0 END) AS n_after,
 SUM(CASE WHEN signed_days >= -30 AND signed_days <= -1 THEN 1 ELSE 0 END) AS n_b30,
 SUM(CASE WHEN signed_days >= -90 AND signed_days <= -1 THEN 1 ELSE 0 END) AS n_b90,
 SUM(CASE WHEN signed_days >= -180 AND signed_days <= -1 THEN 1 ELSE 0 END) AS n_b180,
 SUM(CASE WHEN signed_days >= -365 AND signed_days <= -1 THEN 1 ELSE 0 END) AS n_b365,
 SUM(CASE WHEN signed_days >= 1 AND signed_days <= 30 THEN 1 ELSE 0 END) AS n_a30,
 SUM(CASE WHEN signed_days >= 1 AND signed_days <= 90 THEN 1 ELSE 0 END) AS n_a90,
 SUM(CASE WHEN signed_days >= 1 AND signed_days <= 180 THEN 1 ELSE 0 END) AS n_a180,
 SUM(CASE WHEN signed_days >= 1 AND signed_days <= 365 THEN 1 ELSE 0 END) AS n_a365
 FROM first_general
)
SELECT
 a.n_total AS n_with_general_code,
 CASE WHEN a.n_before > 0 AND a.n_before <= @min_cell_count THEN -@min_cell_count ELSE a.n_before END AS n_first_general_before,
 CASE WHEN a.n_b30 > 0 AND a.n_b30 <= @min_cell_count THEN -@min_cell_count ELSE a.n_b30 END AS n_first_general_within_30d_before,
 CASE WHEN a.n_b90 > 0 AND a.n_b90 <= @min_cell_count THEN -@min_cell_count ELSE a.n_b90 END AS n_first_general_within_90d_before,
 CASE WHEN a.n_b180 > 0 AND a.n_b180 <= @min_cell_count THEN -@min_cell_count ELSE a.n_b180 END AS n_first_general_within_180d_before,
 CASE WHEN a.n_b365 > 0 AND a.n_b365 <= @min_cell_count THEN -@min_cell_count ELSE a.n_b365 END AS n_first_general_within_365d_before,
 CASE WHEN a.n_day0 > 0 AND a.n_day0 <= @min_cell_count THEN -@min_cell_count ELSE a.n_day0 END AS n_first_general_day0,
 CASE WHEN a.n_after > 0 AND a.n_after <= @min_cell_count THEN -@min_cell_count ELSE a.n_after END AS n_first_general_after,
 CASE WHEN a.n_a30 > 0 AND a.n_a30 <= @min_cell_count THEN -@min_cell_count ELSE a.n_a30 END AS n_first_general_within_30d_after,
 CASE WHEN a.n_a90 > 0 AND a.n_a90 <= @min_cell_count THEN -@min_cell_count ELSE a.n_a90 END AS n_first_general_within_90d_after,
 CASE WHEN a.n_a180 > 0 AND a.n_a180 <= @min_cell_count THEN -@min_cell_count ELSE a.n_a180 END AS n_first_general_within_180d_after,
 CASE WHEN a.n_a365 > 0 AND a.n_a365 <= @min_cell_count THEN -@min_cell_count ELSE a.n_a365 END AS n_first_general_within_365d_after,
 CASE WHEN a.n_total <= @min_cell_count THEN NULL ELSE m.median_days END AS median_signed_days_first_general
FROM agg a
CROSS JOIN med m;
