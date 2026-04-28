# =============================================================================
# translate_sql_dialects.R
# Translate all SQL Server queries to every dialect SqlRender supports.
# Output: sql/<dialect>/ mirroring the sql/sql_server/ directory layout.
# =============================================================================
# Usage: Rscript scripts/translate_sql_dialects.R

library(SqlRender)

# ── Paths ─────────────────────────────────────────────────────────────────────

# Works both via Rscript and source()
repo_root <- tryCatch({
  script_path <- commandArgs(trailingOnly = FALSE)
  script_path <- sub("--file=", "", script_path[grep("--file=", script_path)])
  if (length(script_path) == 1 && nzchar(script_path))
    normalizePath(file.path(dirname(script_path), ".."), mustWork = FALSE)
  else
    normalizePath(".")
}, error = function(e) normalizePath("."))

src_dir    <- file.path(repo_root, "sql", "sql_server")
sql_dir    <- file.path(repo_root, "sql")

# ── Dialects ──────────────────────────────────────────────────────────────────

all_dialects <- listSupportedDialects()$dialect

# Skip the source dialect itself.
target_dialects <- all_dialects[all_dialects != "sql server"]

# Dialects that require a temp-table emulation schema because they lack native
# session-scoped temp tables.  SqlRender rewrites #temp → a permanent table in
# this schema, so callers MUST supply tempEmulationSchema when executing.
temp_emulation_required <- c("oracle", "bigquery", "spark", "hive",
                              "impala", "pdw", "netezza", "impala")

# Convert dialect names to safe directory names (spaces → underscores).
dialect_to_dir <- function(d) gsub(" ", "_", d, fixed = TRUE)

# ── Pattern checks (per-file, post-translation) ───────────────────────────────
#
# We run these on the TRANSLATED sql (after SqlRender has had its go) so we
# catch anything SqlRender left behind that a given dialect cannot execute.

checks <- list(

  # SqlRender rewrites PERCENTILE_CONT...WITHIN GROUP (ORDER BY)...OVER(...) for
  # many dialects, but support is uneven.  Flag any residual occurrence.
  list(
    id      = "PERCENTILE_CONT_WITHIN_OVER",
    pattern = "PERCENTILE_CONT\\s*\\(.*?\\)\\s*WITHIN\\s+GROUP\\s*\\(.*?\\)\\s*OVER\\s*\\(",
    message = paste0(
      "PERCENTILE_CONT...WITHIN GROUP...OVER() is SQL Server ordered-set window ",
      "function syntax. Check that the translated form is valid for this dialect. ",
      "PostgreSQL/Redshift support PERCENTILE_CONT only as a plain aggregate ",
      "(no OVER); BigQuery uses a window-function form without WITHIN GROUP; ",
      "SQLite has no native percentile function."
    )
  ),

  # TRY_CAST is silently rewritten to plain CAST on most targets, losing the
  # error-tolerance that protects against bad data in source CDMs.
  list(
    id      = "TRY_CAST",
    pattern = "TRY_CAST\\s*\\(",
    message = paste0(
      "TRY_CAST was left in translated SQL. SqlRender should rewrite it, but ",
      "if it remains, the query will fail on dialects that don't support it. ",
      "Even when rewritten to CAST, invalid values will raise errors rather than ",
      "returning NULL — validate upstream data quality."
    )
  ),

  # DATEFROMPARTS is SQL-Server–specific; SqlRender rewrites it but the result
  # can look unusual on some targets.
  list(
    id      = "DATEFROMPARTS",
    pattern = "DATEFROMPARTS\\s*\\(",
    message = paste0(
      "DATEFROMPARTS was not rewritten by SqlRender. This function is ",
      "SQL Server–specific and will fail on this dialect."
    )
  ),

  # DATEDIFF with three arguments is SQL Server style.
  list(
    id      = "DATEDIFF_3ARG",
    pattern = "DATEDIFF\\s*\\(\\s*DAY\\s*,",
    message = paste0(
      "DATEDIFF(DAY, start, end) was not rewritten. Most dialects use ",
      "date subtraction or their own function instead."
    )
  ),

  # YEAR() is broadly supported but not universal.
  list(
    id      = "YEAR_FUNC",
    pattern = "\\bYEAR\\s*\\(",
    message = "YEAR() function may need to be rewritten as EXTRACT(YEAR FROM ...) on some dialects."
  ),

  # DELETE...FROM...WHERE EXISTS is standard SQL but some dialects (e.g. BigQuery)
  # require a different form (MERGE or subquery DELETE).
  list(
    id      = "DELETE_FROM_EXISTS",
    pattern = "DELETE\\s+FROM\\s+\\S+\\s*WHERE\\s+EXISTS\\s*\\(",
    message = paste0(
      "DELETE FROM ... WHERE EXISTS(...) may not be supported. ",
      "BigQuery requires DELETE ... WHERE ... without a correlated subquery ",
      "in the same form; verify or rewrite as MERGE."
    )
  ),

  # Bare #temp table references — should be gone after translation for dialects
  # that use temp emulation, but residual # prefixes mean translation was skipped.
  # Skip pdw, redshift, and synapse: all are SQL Server-derived engines that
  # support #temp natively, so SqlRender correctly leaves the # prefix intact.
  list(
    id           = "RESIDUAL_HASH_TEMP",
    pattern      = "(?<!['\"])#[a-zA-Z]",
    skip_dialects = c("pdw", "redshift", "synapse"),
    message      = paste0(
      "Residual #temp_table reference. SqlRender should have rewritten these. ",
      "If they remain, confirm SqlRender version >= 1.6 and that the source SQL ",
      "uses the standard #temp pattern."
    )
  )
)

run_checks <- function(sql, dialect, file_label) {
  warnings <- character(0)
  for (chk in checks) {
    if (!is.null(chk$skip_dialects) && dialect %in% chk$skip_dialects) next
    if (grepl(chk$pattern, sql, perl = TRUE, ignore.case = TRUE)) {
      warnings <- c(warnings,
                    sprintf("[%s] %s: %s", file_label, chk$id, chk$message))
    }
  }
  warnings
}

# ── Translation ───────────────────────────────────────────────────────────────

# Discover all .sql source files relative to src_dir.
sql_files <- list.files(src_dir, pattern = "\\.sql$", recursive = TRUE,
                         full.names = FALSE)

if (length(sql_files) == 0)
  stop("No .sql files found under ", src_dir)

cat(sprintf("Found %d SQL file(s) under %s\n", length(sql_files), src_dir))
cat(sprintf("Translating to %d dialect(s): %s\n\n",
            length(target_dialects), paste(target_dialects, collapse = ", ")))

all_warnings <- list()

for (dialect in target_dialects) {

  dir_name   <- dialect_to_dir(dialect)
  out_base   <- file.path(sql_dir, dir_name)
  needs_temp <- dialect %in% temp_emulation_required

  cat(sprintf("── %s (%s) ──\n", dialect, dir_name))

  for (rel_path in sql_files) {

    in_path  <- file.path(src_dir, rel_path)
    out_path <- file.path(out_base, rel_path)

    # Ensure output directory exists.
    dir.create(dirname(out_path), recursive = TRUE, showWarnings = FALSE)

    sql_src <- readChar(in_path, file.info(in_path)$size, useBytes = FALSE)

    translated <- tryCatch(
      SqlRender::translate(
        sql            = sql_src,
        targetDialect  = dialect,
        # tempEmulationSchema left NULL: we emit a header comment reminding
        # the caller to supply it at execution time when required.
        tempEmulationSchema = NULL
      ),
      error = function(e) {
        cat(sprintf("  ERROR translating %s: %s\n", rel_path, conditionMessage(e)))
        NULL
      }
    )

    if (is.null(translated)) next

    # Prepend a dialect header and, where relevant, a temp-emulation warning.
    temp_note <- if (needs_temp) {
      paste0(
        "-- WARNING: This dialect (", dialect, ") does not support native session\n",
        "--   temp tables.  Supply a tempEmulationSchema when calling\n",
        "--   SqlRender::translate() / DatabaseConnector::executeSql().\n",
        "--   Without it, #temp table references become permanent tables and\n",
        "--   may cause permission errors or name collisions.\n"
      )
    } else ""

    header <- paste0(
      "-- ============================================================\n",
      "-- AUTO-TRANSLATED by SqlRender\n",
      "-- Source dialect : sql server\n",
      "-- Target dialect : ", dialect, "\n",
      "-- Translated     : ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"), "\n",
      "-- Source file    : sql/sql_server/", rel_path, "\n",
      "-- DO NOT EDIT — edit the sql_server source and re-run\n",
      "--   scripts/translate_sql_dialects.R\n",
      "-- ============================================================\n",
      temp_note,
      "\n"
    )

    writeLines(paste0(header, translated), out_path)

    # Run pattern checks on the translated output.
    warns <- run_checks(translated, dialect, rel_path)
    if (length(warns) > 0) {
      key <- paste0(dir_name, "/", rel_path)
      all_warnings[[key]] <- c(all_warnings[[key]], warns)
      for (w in warns) cat("  WARN:", w, "\n")
    } else {
      cat(sprintf("  OK  %s\n", rel_path))
    }
  }
  cat("\n")
}

# ── Summary report ────────────────────────────────────────────────────────────

report_path <- file.path(sql_dir, "_translation_report.md")

report_lines <- c(
  "# SQL Translation Report",
  "",
  sprintf("Generated: %s", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  sprintf("Source: `sql/sql_server/`"),
  sprintf("Dialects: %s", paste(target_dialects, collapse = ", ")),
  "",
  "## Dialect notes",
  "",
  paste0(
    "Dialects requiring `tempEmulationSchema` at execution time (no native ",
    "session temp tables): **",
    paste(intersect(temp_emulation_required, target_dialects), collapse = ", "),
    "**."
  ),
  "",
  "## Pattern warnings",
  ""
)

if (length(all_warnings) == 0) {
  report_lines <- c(report_lines, "No pattern warnings detected.")
} else {
  for (file_key in names(all_warnings)) {
    report_lines <- c(report_lines, sprintf("### %s", file_key), "")
    for (w in all_warnings[[file_key]]) {
      report_lines <- c(report_lines, paste0("- ", w))
    }
    report_lines <- c(report_lines, "")
  }
}

writeLines(report_lines, report_path)
cat(sprintf("Report written to %s\n", report_path))

if (length(all_warnings) > 0) {
  cat(sprintf("\n%d file(s) had warnings — review %s\n",
              length(all_warnings), report_path))
} else {
  cat("All translations passed pattern checks.\n")
}
