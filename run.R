library(DatabaseConnector)
library(SqlRender)

# ── Configuration ─────────────────────────────────────────────────────────────

target_dialect        <- "sql server"
cdm_database_schema   <- Sys.getenv("CDM_DATABASE_SCHEMA", unset = "cdm")
temp_emulation_schema <- NULL  # set for dialects needing temp table emulation
min_cell_count        <- 5L
output_dir            <- here::here("outputs")
sql_dir               <- here::here("sql", "sql_server", "chunks")

connection_details <- DatabaseConnector::createConnectionDetails(...)

result_files <- sort(setdiff(list.files(sql_dir, pattern = "\\.sql$"),
                             "00_setup.sql"))

# ── Helpers ───────────────────────────────────────────────────────────────────

render_and_translate <- function(sql_path) {
  sql <- SqlRender::readSql(sql_path)
  rendered <- SqlRender::render(sql,
                                cdm_database_schema = cdm_database_schema,
                                min_cell_count      = min_cell_count)
  SqlRender::translate(rendered,
                       targetDialect       = target_dialect,
                       tempEmulationSchema = temp_emulation_schema)
}

# ── Execute ───────────────────────────────────────────────────────────────────

connection <- DatabaseConnector::connect(connection_details)
on.exit(DatabaseConnector::disconnect(connection), add = TRUE)

message("Executing setup (00_setup.sql) ...")
setup_sql <- render_and_translate(file.path(sql_dir, "00_setup.sql"))
DatabaseConnector::executeSql(connection, setup_sql)
message("Setup complete.\n")

dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

for (f in result_files) {
  out_path <- file.path(output_dir, sub("\\.sql$", ".csv", f))
  translated <- render_and_translate(file.path(sql_dir, f))
  message(sprintf("Running %s", f))
  result <- DatabaseConnector::querySql(connection, translated,
                                        snakeCaseToCamelCase = FALSE)
  readr::write_csv(result, out_path)
  message(sprintf("  %d rows, %d cols\n", nrow(result), ncol(result)))
}

message("Done. Results written to: ", output_dir)
