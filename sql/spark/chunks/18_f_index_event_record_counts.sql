-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : spark
-- Translated     : 2026-07-15 15:37:26 CEST
-- Source file    : sql/sql_server/chunks/18_f_index_event_record_counts.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (spark) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

WITH family_counts  AS (SELECT  CAST('DX' as STRING) AS event_family, person_id, n_dx_records AS n_records FROM vcbo5u4zdx_summary
 UNION ALL
 SELECT 'MET' AS event_family, person_id, n_met_records AS n_records FROM vcbo5u4zmet_summary
),
bucketed AS (
 SELECT
 event_family,
 person_id,
 CASE
 WHEN event_family = 'DX' AND n_records = 1 THEN '1'
 WHEN event_family = 'DX' AND n_records <= 5 THEN '2_5'
 WHEN event_family = 'DX' THEN '6plus'
 WHEN event_family = 'MET' AND n_records = 1 THEN '1'
 ELSE '2plus'
 END AS record_count_bucket,
 CASE
 WHEN event_family = 'DX' AND n_records = 1 THEN 1
 WHEN event_family = 'DX' AND n_records <= 5 THEN 2
 WHEN event_family = 'DX' THEN 3
 WHEN event_family = 'MET' AND n_records = 1 THEN 1
 ELSE 2
 END AS bucket_order
 FROM family_counts
),
totals AS (
 SELECT event_family, COUNT(*) AS n_patients_total
 FROM bucketed
 GROUP BY event_family
)
SELECT
 b.event_family,
 b.record_count_bucket,
 CASE WHEN COUNT(*) > 0 AND COUNT(*) <= @min_cell_count THEN -@min_cell_count ELSE COUNT(*) END AS n_patients,
 t.n_patients_total
FROM bucketed b
JOIN totals t ON t.event_family = b.event_family
GROUP BY b.event_family, b.record_count_bucket, t.n_patients_total
ORDER BY
 CASE b.event_family WHEN 'DX' THEN 0 ELSE 1 END,
 MIN(b.bucket_order);
