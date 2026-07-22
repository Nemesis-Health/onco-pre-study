-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : hive
-- Translated     : 2026-07-15 15:37:39 CEST
-- Source file    : sql/sql_server/chunks/18_f_index_event_record_counts.sql
-- DO NOT EDIT <e2><80><94> edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (hive) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

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
WITH family_counts AS (
    SELECT 'DX'  AS event_family, person_id, n_dx_records  AS n_records FROM dx_summary
    UNION ALL
    SELECT 'MET' AS event_family, person_id, n_met_records AS n_records FROM met_summary
),
bucketed AS (
    SELECT
        event_family,
        person_id,
        CASE
            WHEN event_family = 'DX'  AND n_records = 1  THEN '1'
            WHEN event_family = 'DX'  AND n_records <= 5 THEN '2_5'
            WHEN event_family = 'DX'                     THEN '6plus'
            WHEN event_family = 'MET' AND n_records = 1  THEN '1'
            ELSE '2plus'
        END AS record_count_bucket,
        CASE
            WHEN event_family = 'DX'  AND n_records = 1  THEN 1
            WHEN event_family = 'DX'  AND n_records <= 5 THEN 2
            WHEN event_family = 'DX'                     THEN 3
            WHEN event_family = 'MET' AND n_records = 1  THEN 1
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
    MIN(b.bucket_order)
;

