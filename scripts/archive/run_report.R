# =============================================================================
# run_report.R — Configure and render summary_report.Rmd
# =============================================================================
# Edit the sections below, then source this file or run:
#   Rscript scripts/run_report.R
#
# Required packages: rmarkdown, DatabaseConnector, SqlRender, readr, dplyr,
#                    tidyr, ggplot2, knitr, kableExtra, scales

# ── Paths ─────────────────────────────────────────────────────────────────────

results_dir <- here::here("outputs")
rmd_file    <- here::here("scripts", "summary_report.Rmd")
output_file <- file.path(results_dir, "summary_report.html")

# ── Display options ───────────────────────────────────────────────────────────

# Counts at or below this value are suppressed (same rule as characterization SQL).
min_cell_count <- 5L

# Top N rows in the anchor DX concept rollup table.
anchor_dx_counts_top_n <- 10L

# Top N concepts per linked event-code-count table.
event_code_counts_top_n <- 5L

# Must match @event_code_timing_uses_closest in the characterization SQL.
# FALSE = FIRST occurrence timing columns; TRUE = CLOSEST occurrence columns.
# Only relevant when the event-code CSV does not have separate _FIRST / _CLOSEST columns.
event_code_timing_uses_closest <- FALSE

# ── Focus timing plots ────────────────────────────────────────────────────────
# Pairs shown in the "Timing pair focus" section, one boxplot each.
#
# Fields (all character unless noted):
#   from       – FROM_EVENT value in the timing CSV  (e.g. "DX", "MET")
#   to         – TO_EVENT value                       (e.g. "MET", "L01")
#   timing     – one of:
#                  "first_to_first"           (first DX → first TO)
#                  "first_to_closest"         (first DX → closest TO)
#                  "first_to_closest_before"  (first DX → closest TO, strictly before anchor)
#                  "first_to_closest_after"   (first DX → closest TO, on/after anchor)
#   commentary – (optional) plain text note shown under the pair heading

focus_timing_plots <- list(
  list(
    from       = "DX",
    to         = "MET",
    timing     = "first_to_first",
    commentary = "Pairwise timing uses first DX and first MET; linked codes use the FIRST rule."
  ),
  list(
    from       = "MET",
    to         = "DX",
    timing     = "first_to_closest",
    commentary = "TO uses closest DX to the MET anchor; linked DX rows use CLOSEST per concept."
  ),
  list(
    from       = "MET",
    to         = "ODX",
    timing     = "first_to_closest",
    commentary = "Pairwise slice is strictly before the anchor; ODX rows use CLOSEST within BEFORE."
  ),
  list(
    from       = "MET",
    to         = "GDX",
    timing     = "first_to_closest",
    commentary = "Pairwise slice is strictly before the anchor; GDX rows use CLOSEST within BEFORE."
  ),
  list(
    from       = "MET",
    to         = "L01",
    timing     = "first_to_closest_after",
    commentary = "Pairwise slice is on or after the anchor; L01 rows use CLOSEST within AFTER."
  )
)

# ── Database connection ───────────────────────────────────────────────────────
# Used only to look up concept names from the OMOP CDM concept table.
# Set connection_details <- NULL to skip concept-name enrichment.

connection_details <- DatabaseConnector::createConnectionDetails(
  dbms     = "sql server",                        # "postgresql", "redshift", "snowflake", …
  server   = Sys.getenv("DB_SERVER"),
  user     = Sys.getenv("DB_USER"),
  password = Sys.getenv("DB_PASSWORD"),
  port     = 1433
)
cdm_database_schema <- Sys.getenv("CDM_DATABASE_SCHEMA", unset = "cdm")

# Uncomment to disable concept-name lookup:
# connection_details <- NULL

# ── Render ────────────────────────────────────────────────────────────────────

rmarkdown::render(
  input       = rmd_file,
  output_file = output_file,
  params      = list(
    results_dir                    = results_dir,
    min_cell_count                 = min_cell_count,
    anchor_dx_counts_top_n         = anchor_dx_counts_top_n,
    event_code_counts_top_n        = event_code_counts_top_n,
    event_code_timing_uses_closest = event_code_timing_uses_closest,
    focus_timing_plots             = focus_timing_plots,
    connection_details             = connection_details,
    cdm_database_schema            = cdm_database_schema
  ),
  envir = new.env()
)

message("Report written to: ", output_file)
