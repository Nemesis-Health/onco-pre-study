-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : sqlite extended
-- Translated     : 2026-05-07 12:40:26 BST
-- Source file    : sql/sql_server/chunks/06_windowed_odx_prevalence.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================

-- 6) Windowed ODX (and GDX) concept prevalence relative to anchor date
--    For each anchor / event family / concept, counts distinct patients with
--    at least one event in each time window around the anchor date.
--
--    Anchors:
--      INDEX     : DX index_date (all DX cohort)
--      FIRST_MET : first_met_date (MET subgroup only)
--
--    Windows (days = event_date - anchor_date):
--      pm30d      : -30 <= days <= 30
--      pm90d      : -90 <= days <= 90
--      pm180d     : -180 <= days <= 180
--      pm1yr      : -365 <= days <= 365
--      ever_before: days < 0
--      ever_after : days >= 0
--      ever       : any time
--
--    Covers ODX and GDX families (clinically relevant exclusion criteria).
--    Restricted to top concepts by overall patient count; report builder
--    will further limit to top N.
--
--    Small-cell suppression: each count <= @min_cell_count suppressed to -@min_cell_count.
WITH index_events  AS (SELECT  CAST('INDEX' as TEXT) AS anchor_event, 'ODX' AS event_family, e.concept_id, e.person_id,
        DATEDIFF(DAY, c.index_date, e.event_date) AS days_from_anchor
    FROM temp.other_dx_events e
    JOIN temp.cohort c ON e.person_id = c.person_id
    UNION ALL
    SELECT 'INDEX' AS anchor_event, 'GDX' AS event_family, e.concept_id, e.person_id,
        DATEDIFF(DAY, c.index_date, e.event_date) AS days_from_anchor
    FROM temp.gen_cancer_events e
    JOIN temp.cohort c ON e.person_id = c.person_id
),
met_events AS (
    SELECT 'FIRST_MET' AS anchor_event, 'ODX' AS event_family, e.concept_id, e.person_id,
        DATEDIFF(DAY, ms.first_met_date, e.event_date) AS days_from_anchor
    FROM temp.other_dx_events e
    JOIN temp.cohort c ON e.person_id = c.person_id
    JOIN temp.met_summary ms ON ms.person_id = c.person_id
    WHERE ms.first_met_date IS NOT NULL
    UNION ALL
    SELECT 'FIRST_MET' AS anchor_event, 'GDX' AS event_family, e.concept_id, e.person_id,
        DATEDIFF(DAY, ms.first_met_date, e.event_date) AS days_from_anchor
    FROM temp.gen_cancer_events e
    JOIN temp.cohort c ON e.person_id = c.person_id
    JOIN temp.met_summary ms ON ms.person_id = c.person_id
    WHERE ms.first_met_date IS NOT NULL
),
all_events AS (
    SELECT * FROM index_events
    UNION ALL
    SELECT * FROM met_events
),
windowed AS (
    SELECT
        anchor_event,
        event_family,
        concept_id,
        person_id,
        MAX(CASE WHEN days_from_anchor >= -30  AND days_from_anchor <= 30  THEN 1 ELSE 0 END) AS in_pm30d,
        MAX(CASE WHEN days_from_anchor >= -90  AND days_from_anchor <= 90  THEN 1 ELSE 0 END) AS in_pm90d,
        MAX(CASE WHEN days_from_anchor >= -180 AND days_from_anchor <= 180 THEN 1 ELSE 0 END) AS in_pm180d,
        MAX(CASE WHEN days_from_anchor >= -365 AND days_from_anchor <= 365 THEN 1 ELSE 0 END) AS in_pm1yr,
        MAX(CASE WHEN days_from_anchor < 0                                 THEN 1 ELSE 0 END) AS in_ever_before,
        MAX(CASE WHEN days_from_anchor >= 0                                THEN 1 ELSE 0 END) AS in_ever_after,
        1 AS in_ever
    FROM all_events
    GROUP BY anchor_event, event_family, concept_id, person_id
),
agg AS (
    SELECT
        anchor_event,
        event_family,
        concept_id,
        COUNT(*)            AS n_ever,
        SUM(in_pm30d)       AS n_pm30d,
        SUM(in_pm90d)       AS n_pm90d,
        SUM(in_pm180d)      AS n_pm180d,
        SUM(in_pm1yr)       AS n_pm1yr,
        SUM(in_ever_before) AS n_ever_before,
        SUM(in_ever_after)  AS n_ever_after
    FROM windowed
    GROUP BY anchor_event, event_family, concept_id
)
SELECT
    a.anchor_event,
    a.event_family,
    a.concept_id,
    CASE WHEN a.n_ever        > 0 AND a.n_ever        <= @min_cell_count THEN -@min_cell_count ELSE a.n_ever        END AS n_ever,
    CASE WHEN a.n_pm30d       > 0 AND a.n_pm30d       <= @min_cell_count THEN -@min_cell_count ELSE a.n_pm30d       END AS n_pm30d,
    CASE WHEN a.n_pm90d       > 0 AND a.n_pm90d       <= @min_cell_count THEN -@min_cell_count ELSE a.n_pm90d       END AS n_pm90d,
    CASE WHEN a.n_pm180d      > 0 AND a.n_pm180d      <= @min_cell_count THEN -@min_cell_count ELSE a.n_pm180d      END AS n_pm180d,
    CASE WHEN a.n_pm1yr       > 0 AND a.n_pm1yr       <= @min_cell_count THEN -@min_cell_count ELSE a.n_pm1yr       END AS n_pm1yr,
    CASE WHEN a.n_ever_before > 0 AND a.n_ever_before <= @min_cell_count THEN -@min_cell_count ELSE a.n_ever_before END AS n_ever_before,
    CASE WHEN a.n_ever_after  > 0 AND a.n_ever_after  <= @min_cell_count THEN -@min_cell_count ELSE a.n_ever_after  END AS n_ever_after
FROM agg a
ORDER BY
    CASE WHEN a.anchor_event = 'INDEX' THEN 0 ELSE 1 END,
    a.event_family,
    a.n_ever DESC,
    a.concept_id
;

