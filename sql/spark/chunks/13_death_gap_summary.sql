-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-05-06 18:54:01 BST
-- Source file    : sql/sql_server/chunks/13_death_gap_summary.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH patient_obs AS (
 SELECT
 person_id,
 MIN(observation_period_start_date) AS first_obs_start,
 MAX(observation_period_end_date) AS last_obs_end
 FROM @cdm_database_schema.observation_period
 WHERE person_id IN (SELECT person_id FROM sqvhwkzfcohort)
 GROUP BY person_id
),
death_obs_gaps AS (
 SELECT
 c.person_id,
 c.index_date,
 ms.first_met_date,
 dos.death_date,
 po.first_obs_start,
 po.last_obs_end,
 CASE
 WHEN dos.death_date > po.last_obs_end
 THEN DATEDIFF(DAY, po.last_obs_end, dos.death_date)
 ELSE NULL
 END AS gap_death_after_obs,
 CASE
 WHEN dos.death_date < po.first_obs_start
 THEN 1
 ELSE 0
 END AS death_before_obs
 FROM sqvhwkzfcohort c
 INNER JOIN sqvhwkzfdeath_obs_status dos ON dos.person_id = c.person_id
 LEFT JOIN sqvhwkzfmet_summary ms ON ms.person_id = c.person_id
 LEFT JOIN patient_obs po ON po.person_id = c.person_id
)
SELECT
 'INDEX' AS anchor_event,
 SUM(CASE WHEN death_before_obs = 1 THEN 1 ELSE 0 END) AS n_death_before_obs,
 SUM(CASE WHEN gap_death_after_obs IS NOT NULL THEN 1 ELSE 0 END) AS n_death_after_obs,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 4.0 * rn >= non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS lq_gap_days,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 2.0 * rn >= non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS median_gap_days,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 4.0 * rn >= 3 * non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS uq_gap_days,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 10.0 * rn >= 9 * non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS p90_gap_days
FROM (
 SELECT death_before_obs, gap_death_after_obs,
 ROW_NUMBER() OVER (ORDER BY gap_death_after_obs) AS rn,
 SUM(CASE WHEN gap_death_after_obs IS NOT NULL THEN 1 ELSE 0 END) OVER () AS non_null_cnt
 FROM death_obs_gaps
 WHERE death_date IS NOT NULL
) x
UNION ALL
SELECT
 'FIRST_MET' AS anchor_event,
 SUM(CASE WHEN death_before_obs = 1 THEN 1 ELSE 0 END) AS n_death_before_obs,
 SUM(CASE WHEN gap_death_after_obs IS NOT NULL THEN 1 ELSE 0 END) AS n_death_after_obs,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 4.0 * rn >= non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS lq_gap_days,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 2.0 * rn >= non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS median_gap_days,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 4.0 * rn >= 3 * non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS uq_gap_days,
 MIN(CASE WHEN gap_death_after_obs IS NOT NULL AND 10.0 * rn >= 9 * non_null_cnt THEN CAST(gap_death_after_obs AS DOUBLE) END) AS p90_gap_days
FROM (
 SELECT death_before_obs, gap_death_after_obs,
 ROW_NUMBER() OVER (ORDER BY gap_death_after_obs) AS rn,
 SUM(CASE WHEN gap_death_after_obs IS NOT NULL THEN 1 ELSE 0 END) OVER () AS non_null_cnt
 FROM death_obs_gaps
 WHERE death_date IS NOT NULL
 AND first_met_date IS NOT NULL
) x;
