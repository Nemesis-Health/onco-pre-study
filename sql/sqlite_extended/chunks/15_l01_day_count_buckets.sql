-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : sqlite extended
-- Translated     : 2026-05-07 06:29:51 BST
-- Source file    : sql/sql_server/chunks/15_l01_day_count_buckets.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

-- 15) Distribution of distinct L01 event days per patient
--     Shows how many patients have 1, 2-6, 7-11, or 12+ distinct L01 days.
--     Patients with exactly 1 day cannot contribute to gap analyses (chunks 11-12).
--     Source: #l01_event_days (built in 00_setup.sql section L).
--
--     Two subgroups:
--       ALL_L01 : all DX cohort patients with any L01 record
--       MET_L01 : patients who also have a first_met_date
SELECT
    subgroup,
    CASE
        WHEN n_days =  1 THEN '1'
        WHEN n_days <= 6 THEN '2_6'
        WHEN n_days <= 11 THEN '7_11'
        ELSE '12plus'
    END AS days_bucket,
    COUNT(*) AS n_patients
FROM (
    SELECT e.person_id, COUNT(*) AS n_days, 'ALL_L01' AS subgroup
    FROM temp.l01_event_days e
    GROUP BY e.person_id
    UNION ALL
    SELECT e.person_id, COUNT(*) AS n_days, 'MET_L01' AS subgroup
    FROM temp.l01_event_days e
    JOIN temp.met_summary ms ON e.person_id = ms.person_id AND ms.first_met_date IS NOT NULL
    GROUP BY e.person_id
) x
GROUP BY
    subgroup,
    CASE
        WHEN n_days =  1 THEN '1'
        WHEN n_days <= 6 THEN '2_6'
        WHEN n_days <= 11 THEN '7_11'
        ELSE '12plus'
    END
ORDER BY
    subgroup,
    MIN(n_days)
;

