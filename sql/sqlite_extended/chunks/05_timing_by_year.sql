-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : sqlite extended
-- Translated     : 2026-05-07 06:29:51 BST
-- Source file    : sql/sql_server/chunks/05_timing_by_year.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

-- 5) Pairwise timing summary stratified by index year
--    Same structure as chunk 04 (final_timing_pairwise.csv) but grouped by
--    YEAR(index_date) instead of OVERALL.  Used for year-over-year plots and
--    for the per-year columns in the §06 stability matrix.
--
--    Only first_to_first timing is exported here (DX->MET, MET->L01 are the
--    primary year-over-year metrics).  Small-cell suppression applied.
SELECT
    x.timing_type,
    x.index_year,
    x.from_event,
    x.to_event,
    CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN -@min_cell_count ELSE x.n_patients_with_pair END AS n_patients_with_pair,
    CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p25_days  END AS p25_days,
    CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p50_days  END AS p50_days,
    CASE WHEN x.n_patients_with_pair <= @min_cell_count THEN NULL ELSE x.p75_days  END AS p75_days
FROM (
    -- first_to_first by year
    SELECT
        'first_to_first' AS timing_type,
        CAST(index_year_int AS TEXT) AS index_year,
        from_event,
        to_event,
        COUNT(*) AS n_patients_with_pair,
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS REAL) END) AS p25_days,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS REAL) END) AS p50_days,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS REAL) END) AS p75_days
    FROM (
        SELECT p.from_event, p.to_event, p.days_diff,
            YEAR(pc.index_date) AS index_year_int,
            ROW_NUMBER() OVER (PARTITION BY YEAR(pc.index_date), p.from_event, p.to_event ORDER BY p.days_diff) AS rn,
            COUNT(*)     OVER (PARTITION BY YEAR(pc.index_date), p.from_event, p.to_event)                    AS cnt
        FROM temp.patient_timing_pairs p
        JOIN temp.patient_char pc ON p.person_id = pc.person_id
    ) y
    GROUP BY index_year_int, from_event, to_event
    UNION ALL
    -- first_to_closest_after by year (for MET->L01 post-MET treatment timing)
    SELECT
        'first_to_closest_after' AS timing_type,
        CAST(index_year_int AS TEXT) AS index_year,
        from_event,
        to_event,
        COUNT(*) AS n_patients_with_pair,
        MIN(CASE WHEN 4.0 * rn >= cnt THEN CAST(days_diff AS REAL) END) AS p25_days,
        MIN(CASE WHEN 2.0 * rn >= cnt THEN CAST(days_diff AS REAL) END) AS p50_days,
        MIN(CASE WHEN 4.0 * rn >= 3 * cnt THEN CAST(days_diff AS REAL) END) AS p75_days
    FROM (
        SELECT p.from_event, p.to_event, p.days_diff,
            YEAR(pc.index_date) AS index_year_int,
            ROW_NUMBER() OVER (PARTITION BY YEAR(pc.index_date), p.from_event, p.to_event ORDER BY p.days_diff) AS rn,
            COUNT(*)     OVER (PARTITION BY YEAR(pc.index_date), p.from_event, p.to_event)                    AS cnt
        FROM temp.patient_timing_pairs_first_to_closest_after p
        JOIN temp.patient_char pc ON p.person_id = pc.person_id
    ) y
    GROUP BY index_year_int, from_event, to_event
) x
ORDER BY
    x.timing_type,
    x.from_event,
    x.to_event,
    TRY_CAST(x.index_year AS INT)
;

