-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : pdw
-- Translated     : 2026-05-06 18:36:45 BST
-- Source file    : sql/sql_server/chunks/06_windowed_odx_prevalence.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (pdw) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 6) Windowed ODX (and GDX) concept prevalence relative to DX index date
--    For each event family / concept, counts the number of distinct patients
--    with at least one event in each time window around index_date.
--
--    Windows (days = event_date - index_date):
--      pm30d      : -30 <= days <= 30
--      pm90d      : -90 <= days <= 90
--      pm180d     : -180 <= days <= 180
--      pm1yr      : -365 <= days <= 365
--      ever_before: days < 0
--      ever_after : days >= 0
--      ever       : any time (same as time_window='all' in chunk 02)
--
--    Only returns rows from the INDEX anchor (DX index date).
--    Covers ODX and GDX families (the clinically relevant exclusion criteria).
--    Restricted to top concepts by overall patient count to keep output size
--    manageable; the report builder will further limit to top N.
--
--    Small-cell suppression: counts <= @min_cell_count suppressed to -@min_cell_count.
WITH odx_gdx_events AS (
    -- ODX events with days relative to index_date
    SELECT
        'ODX' AS event_family,
        e.concept_id,
        e.person_id,
        DATEDIFF(DAY, c.index_date, e.event_date) AS days_from_index
    FROM #other_dx_events e
    JOIN #cohort c ON e.person_id = c.person_id
    UNION ALL
    -- GDX events with days relative to index_date
    SELECT
        'GDX' AS event_family,
        e.concept_id,
        e.person_id,
        DATEDIFF(DAY, c.index_date, e.event_date) AS days_from_index
    FROM #gen_cancer_events e
    JOIN #cohort c ON e.person_id = c.person_id
),
windowed AS (
    SELECT
        event_family,
        concept_id,
        person_id,
        MAX(CASE WHEN days_from_index >= -30  AND days_from_index <= 30  THEN 1 ELSE 0 END) AS in_pm30d,
        MAX(CASE WHEN days_from_index >= -90  AND days_from_index <= 90  THEN 1 ELSE 0 END) AS in_pm90d,
        MAX(CASE WHEN days_from_index >= -180 AND days_from_index <= 180 THEN 1 ELSE 0 END) AS in_pm180d,
        MAX(CASE WHEN days_from_index >= -365 AND days_from_index <= 365 THEN 1 ELSE 0 END) AS in_pm1yr,
        MAX(CASE WHEN days_from_index < 0                                THEN 1 ELSE 0 END) AS in_ever_before,
        MAX(CASE WHEN days_from_index >= 0                               THEN 1 ELSE 0 END) AS in_ever_after,
        1 AS in_ever
    FROM odx_gdx_events
    GROUP BY event_family, concept_id, person_id
),
agg AS (
    SELECT
        event_family,
        concept_id,
        COUNT(*)                        AS n_ever,
        SUM(in_pm30d)                   AS n_pm30d,
        SUM(in_pm90d)                   AS n_pm90d,
        SUM(in_pm180d)                  AS n_pm180d,
        SUM(in_pm1yr)                   AS n_pm1yr,
        SUM(in_ever_before)             AS n_ever_before,
        SUM(in_ever_after)              AS n_ever_after
    FROM windowed
    GROUP BY event_family, concept_id
)
SELECT
    a.event_family,
    a.concept_id,
    CASE WHEN a.n_ever          <= @min_cell_count THEN -@min_cell_count ELSE a.n_ever          END AS n_ever,
    CASE WHEN a.n_ever          <= @min_cell_count THEN NULL             ELSE a.n_pm30d         END AS n_pm30d,
    CASE WHEN a.n_ever          <= @min_cell_count THEN NULL             ELSE a.n_pm90d         END AS n_pm90d,
    CASE WHEN a.n_ever          <= @min_cell_count THEN NULL             ELSE a.n_pm180d        END AS n_pm180d,
    CASE WHEN a.n_ever          <= @min_cell_count THEN NULL             ELSE a.n_pm1yr         END AS n_pm1yr,
    CASE WHEN a.n_ever          <= @min_cell_count THEN NULL             ELSE a.n_ever_before   END AS n_ever_before,
    CASE WHEN a.n_ever          <= @min_cell_count THEN NULL             ELSE a.n_ever_after    END AS n_ever_after
FROM agg a
ORDER BY a.event_family, a.n_ever DESC, a.concept_id
;

