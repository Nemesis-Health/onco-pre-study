# =============================================================================
# execute_characterization.R
# Render, translate, and execute sql/sql_server characterization chunks
# against any DatabaseConnector-supported dialect; write results to outputs/.
# =============================================================================
# Required packages: DatabaseConnector, SqlRender, readr, here
#
# Usage:
#   Rscript scripts/execute_characterization.R
#   or source("scripts/execute_characterization.R")

library(DatabaseConnector)
library(SqlRender)

# ── Configuration ─────────────────────────────────────────────────────────────

# Target SQL dialect passed to SqlRender::translate().
# Supported values: "sql server", "postgresql", "redshift", "snowflake",
#                   "bigquery", "oracle", "spark", "sqlite", "synapse"
target_dialect <- "sql server"

cdm_database_schema <- Sys.getenv("CDM_DATABASE_SCHEMA", unset = "cdm")

# Required for dialects that don't support native temp tables (Oracle, BigQuery).
# Set the TEMP_EMULATION_SCHEMA env var or assign directly; leave NULL to skip.
temp_emulation_schema <- {
  v <- Sys.getenv("TEMP_EMULATION_SCHEMA", unset = "")
  if (nzchar(v)) v else NULL
}

min_cell_count <- 5L
output_dir     <- here::here("outputs")
sql_dir        <- here::here("sql", "sql_server", "chunks")

connection_details <- DatabaseConnector::createConnectionDetails(
  dbms     = target_dialect,
  server   = Sys.getenv("DB_SERVER"),
  user     = Sys.getenv("DB_USER"),
  password = Sys.getenv("DB_PASSWORD"),
  port     = as.integer(Sys.getenv("DB_PORT", unset = "1433"))
)

# ── Chunk → output-file mapping ───────────────────────────────────────────────
#
# One chunk = one final SELECT = one CSV output.  Keep this invariant when
# adding chunks: split any multi-statement export into separate chunk files
# rather than emitting multiple CSVs from a single chunk.

result_chunks <- list(
  list(file = "01_population_prevalence.sql",   output = "final_population_prevalence.csv"),
  list(file = "02_code_counts.sql",             output = "final_code_counts.csv"),
  list(file = "03_directionality_buckets.sql",  output = "final_directionality.csv"),
  list(file = "04_timing_pairwise.sql",         output = "final_timing_pairwise.csv"),
  list(file = "05_timing_by_year.sql",          output = "final_timing_by_year.csv"),
  list(file = "06_windowed_odx_prevalence.sql", output = "final_windowed_odx_prevalence.csv"),
  list(file = "07_l01_treatment_windows.sql",   output = "final_l01_treatment_windows.csv"),
  list(file = "08_death_timing.sql",            output = "final_death_from_anchors.csv"),
  list(file = "09_demographics.sql",            output = "final_demographics_from_anchors.csv"),
  list(file = "10_anchor_dx_codes.sql",         output = "final_anchor_dx_concept_counts.csv"),
  list(file = "11_l01_gap_deciles.sql",         output = "final_l01_gap_deciles.csv"),
  list(file = "12_l01_gap_buckets.sql",         output = "final_l01_gap_buckets.csv"),
  list(file = "13_death_gap_summary.sql",       output = "final_death_gap_summary.csv"),
  list(file = "14_death_gap_buckets.sql",       output = "final_death_gap_buckets.csv")
)

# ── Helpers ───────────────────────────────────────────────────────────────────

render_and_translate <- function(sql_path) {
  sql      <- SqlRender::readSql(sql_path)
  rendered <- SqlRender::render(
    sql,
    cdm_database_schema = cdm_database_schema,
    min_cell_count      = min_cell_count
  )
  SqlRender::translate(
    rendered,
    targetDialect        = target_dialect,
    tempEmulationSchema  = temp_emulation_schema
  )
}

# ── Execute ───────────────────────────────────────────────────────────────────

connection <- DatabaseConnector::connect(connection_details)
on.exit(DatabaseConnector::disconnect(connection), add = TRUE)

# Setup: DDL + temp table population (no result set)
message("Executing setup (00_setup.sql) ...")
setup_sql <- render_and_translate(file.path(sql_dir, "00_setup.sql"))
DatabaseConnector::executeSql(connection, setup_sql)
message("Setup complete.\n")

# Result chunks: translate, query, save
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

for (chunk in result_chunks) {
  sql_path <- file.path(sql_dir, chunk$file)
  out_path <- file.path(output_dir, chunk$output)

  message(sprintf("Running %-47s -> %s", chunk$file, basename(out_path)))

  translated <- render_and_translate(sql_path)
  result     <- DatabaseConnector::querySql(connection, translated, snakeCaseToCamelCase = FALSE)

  readr::write_csv(result, out_path)
  message(sprintf("  %d rows, %d cols\n", nrow(result), ncol(result)))
}

message("Done. Results written to: ", output_dir)
