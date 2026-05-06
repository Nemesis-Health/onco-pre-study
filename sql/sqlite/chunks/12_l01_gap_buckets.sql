-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : sqlite
-- Translated     : 2026-05-06 18:36:54 BST
-- Source file    : sql/sql_server/chunks/12_l01_gap_buckets.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

-- 12) L01 consecutive record gap distribution — bucketed histogram
--     Intermediate table #l01_consecutive_gaps is built in 00_setup.sql
--     (section L).  Same subgroups as chunk 11 (ALL_L01, MET_L01).
--
--     Output: one row per (subgroup, gap_bucket) for histogram rendering.
SELECT
    subgroup,
    CASE
        WHEN gap_days <  30  THEN 'lt30d'
        WHEN gap_days <  60  THEN '30_59d'
        WHEN gap_days <  90  THEN '60_89d'
        WHEN gap_days < 180  THEN '90_179d'
        WHEN gap_days < 365  THEN '180_364d'
        ELSE 'ge365d'
    END AS gap_bucket,
    COUNT(*) AS n_gaps
FROM temp.l01_consecutive_gaps
GROUP BY
    subgroup,
    CASE
        WHEN gap_days <  30  THEN 'lt30d'
        WHEN gap_days <  60  THEN '30_59d'
        WHEN gap_days <  90  THEN '60_89d'
        WHEN gap_days < 180  THEN '90_179d'
        WHEN gap_days < 365  THEN '180_364d'
        ELSE 'ge365d'
    END
ORDER BY
    subgroup,
    CASE
        WHEN gap_days <  30  THEN 1
        WHEN gap_days <  60  THEN 2
        WHEN gap_days <  90  THEN 3
        WHEN gap_days < 180  THEN 4
        WHEN gap_days < 365  THEN 5
        ELSE 6
    END
;

