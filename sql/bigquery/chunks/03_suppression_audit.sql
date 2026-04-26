-- ============================================================
-- AUTO-TRANSLATED by SqlRender
-- Source dialect : sql server
-- Target dialect : bigquery
-- Translated     : 2026-04-26 18:36:18 BST
-- Source file    : sql/sql_server/chunks/03_suppression_audit.sql
-- DO NOT EDIT — edit the sql_server source and re-run
--   scripts/translate_sql_dialects.R
-- ============================================================
-- WARNING: This dialect (bigquery) does not support native session
--   temp tables.  Supply a tempEmulationSchema when calling
--   SqlRender::translate() / DatabaseConnector::executeSql().
--   Without it, #temp table references become permanent tables and
--   may cause permission errors or name collisions.

-- 3) Suppressed-row audit for event_code_counts
   select event_family,
    case
        when count(*) between 1 and @min_cell_count then -@min_cell_count
        else count(*)
    end as n_concepts_total,
    case
        when sum(case when n_patients <= @min_cell_count then 1 else 0 end) between 1 and @min_cell_count then -@min_cell_count
        else sum(case when n_patients <= @min_cell_count then 1 else 0 end)
    end as n_concepts_suppressed
   from x0brquscevent_code_counts
  group by  2  order by  1 ;

