-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : sqlite extended
-- Translated     : 2026-04-26 18:36:21 BST
-- Source file    : sql/sql_server/chunks/03_suppression_audit.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

-- 3) Suppressed-row audit for event_code_counts
SELECT
    event_family,
    CASE
        WHEN COUNT(*) BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
        ELSE COUNT(*)
    END AS n_concepts_total,
    CASE
        WHEN SUM(CASE WHEN n_patients <= @min_cell_count THEN 1 ELSE 0 END) BETWEEN 1 AND @min_cell_count THEN -@min_cell_count
        ELSE SUM(CASE WHEN n_patients <= @min_cell_count THEN 1 ELSE 0 END)
    END AS n_concepts_suppressed
FROM temp.event_code_counts
GROUP BY event_family
ORDER BY event_family
;

