#!/usr/bin/env Rscript
# =============================================================================
# build_summary_html_report.R
# =============================================================================
# Reads characterization CSVs from outputs/ and writes outputs/summary_report.html
#
# Usage:
#   Rscript scripts/build_summary_html_report.R
#   Rscript scripts/build_summary_html_report.R --results-dir /path/to/csvs
#
# Required packages:
#   install.packages(c("dplyr", "plotly", "htmltools"))
#
# Optional (OMOP concept name lookup):
#   install.packages("DatabaseConnector")   # OHDSI standard connector
#   # Then set env vars: OMOP_DBMS, OMOP_SERVER, OMOP_USER, OMOP_PASSWORD,
#   #                    OMOP_PORT (default 1433), OMOP_CDM_SCHEMA (default "cdm")
#   # Supported dbms values: "sql server", "postgresql", "snowflake", "sqlite"
# =============================================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(plotly)
  library(htmltools)
})

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
.args <- commandArgs(trailingOnly = TRUE)
results_dir_arg <- NULL
i <- 1L
while (i <= length(.args)) {
  if (.args[i] %in% c("--results-dir", "-d") && i < length(.args)) {
    results_dir_arg <- .args[i + 1L]
    i <- i + 2L
  } else {
    i <- i + 1L
  }
}

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
.script_file <- tryCatch({
  f <- sub("--file=", "", commandArgs(FALSE)[grep("--file=", commandArgs(FALSE))])
  if (length(f) == 0 || nchar(f) == 0) NULL else normalizePath(f)
}, error = function(e) NULL)

BASE_DIR <- if (!is.null(.script_file)) {
  normalizePath(file.path(dirname(.script_file), ".."), mustWork = FALSE)
} else {
  getwd()
}

RESULTS_DIR <- if (!is.null(results_dir_arg)) {
  normalizePath(results_dir_arg, mustWork = FALSE)
} else {
  Sys.getenv("CHARACTERIZATION_RESULTS_DIR",
    unset = file.path(BASE_DIR, "outputs"))
}

OUTPUT_PATH <- file.path(RESULTS_DIR, "summary_report.html")

# ---------------------------------------------------------------------------
# DatabaseConnector config (optional — concept name lookup only)
# ---------------------------------------------------------------------------
OMOP_CDM_SCHEMA       <- Sys.getenv("OMOP_CDM_SCHEMA", unset = "cdm")
OMOP_CONNECTION_DETAILS <- NULL  # populated below if env vars are set

.omop_dbms <- Sys.getenv("OMOP_DBMS", unset = "")
if (nchar(.omop_dbms) > 0 && requireNamespace("DatabaseConnector", quietly = TRUE)) {
  .port <- suppressWarnings(as.integer(Sys.getenv("OMOP_PORT", unset = "1433")))
  OMOP_CONNECTION_DETAILS <- tryCatch(
    DatabaseConnector::createConnectionDetails(
      dbms     = .omop_dbms,
      server   = Sys.getenv("OMOP_SERVER",   unset = ""),
      user     = Sys.getenv("OMOP_USER",     unset = ""),
      password = Sys.getenv("OMOP_PASSWORD", unset = ""),
      port     = if (!is.na(.port)) .port else 1433L
    ),
    error = function(e) { message("DatabaseConnector config error: ", e$message); NULL }
  )
}

# ---------------------------------------------------------------------------
# Report constants
# ---------------------------------------------------------------------------
TIMING_LINTHRESH_DAYS   <- 180.0
EVENT_CODE_COUNTS_TOP_N <- 5L
ANCHOR_DX_COUNTS_TOP_N  <- 10L
TICK_ANCHOR_DAYS        <- c(30, 60, 90, 180, 365, 730, 1460, 1920)

TIMING_VARIANTS <- list(
  first_to_first = list(
    title = "First occurrence → first occurrence",
    file  = "final_timing_pair_summary_first_to_first.csv",
    short = "First→first",
    time_relative = NULL
  ),
  first_to_closest = list(
    title = "First occurrence → closest occurrence",
    file  = "final_timing_pair_summary_first_to_closest.csv",
    short = "First→closest",
    time_relative = NULL
  ),
  first_to_closest_before = list(
    title = "First → closest (strictly before anchor)",
    file  = "final_timing_pair_summary_first_to_closest_before.csv",
    short = "Before anchor",
    time_relative = "BEFORE"
  ),
  first_to_closest_after = list(
    title = "First → closest (on or after anchor)",
    file  = "final_timing_pair_summary_first_to_closest_after.csv",
    short = "On/after anchor",
    time_relative = "AFTER"
  )
)

FOCUS_TIMING_PLOTS <- list(
  list(from = "DX",  to = "MET", timing = "first_to_first",
       commentary = "Pairwise timing uses first DX and first MET."),
  list(from = "MET", to = "DX",  timing = "first_to_closest",
       commentary = "TO uses closest DX to the MET anchor."),
  list(from = "MET", to = "ODX", timing = "first_to_closest",
       commentary = "Before-anchor slice; linked ODX rows use CLOSEST within BEFORE stratum."),
  list(from = "MET", to = "GDX", timing = "first_to_closest",
       commentary = "Before-anchor slice; linked GDX rows use CLOSEST within BEFORE stratum."),
  list(from = "MET", to = "L01", timing = "first_to_closest_after",
       commentary = "On/after-anchor slice; linked L01 rows use CLOSEST within AFTER stratum.")
)

TIMING_VARIANTS_ORDER <- c(
  "first_to_first", "first_to_closest",
  "first_to_closest_before", "first_to_closest_after"
)

# ---------------------------------------------------------------------------
# CSS
# ---------------------------------------------------------------------------
REPORT_CSS <- '
body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Arial, sans-serif;
       margin: 28px; color: #111827; max-width: 1100px; }
h1 { margin: 0 0 6px; letter-spacing: -0.02em; }
h2 { margin: 24px 0 10px; letter-spacing: -0.01em; }
h3 { margin: 18px 0 10px; }
h4 { margin: 14px 0 8px; font-size: 15px; }
p  { line-height: 1.5; margin: 8px 0; }
.meta    { color: #4b5563; margin: 6px 0 18px; }
.section { margin-top: 26px; }
.card    { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 14px; }
.stack > * + * { margin-top: 12px; }
.subtle  { color: #6b7280; font-size: 12px; }
.report-table { border-collapse: collapse; width: 100%; font-size: 13px; }
.report-table th, .report-table td
         { border: 1px solid #e5e7eb; padding: 7px 9px; text-align: left; }
.report-table th { background: #f9fafb; font-weight: 600; }
.report-table td { background: #ffffff; }
code { background: #f3f4f6; padding: 1px 4px; border-radius: 4px; font-size: 12px; }
.plot-wrap { padding-top: 6px; }
.commentary { margin: 4px 0 14px; max-width: 900px; line-height: 1.55; color: #374151; font-size: 13px; }
'

# ---------------------------------------------------------------------------
# Helper utilities
# ---------------------------------------------------------------------------

read_csv_safe <- function(path) {
  if (!file.exists(path)) return(NULL)
  tryCatch(
    read.csv(path, stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) { warning("Cannot read: ", path, " — ", e$message); NULL }
  )
}

# Case-insensitive column lookup; returns actual column name or NA_character_
col_ci <- function(df, name) {
  idx <- which(tolower(names(df)) == tolower(name))
  if (length(idx) == 0) NA_character_ else names(df)[idx[1L]]
}

# Symmetric-log10 transform: linear near 0, log-compressed in tails.
symlog10 <- function(x, linthresh = TIMING_LINTHRESH_DAYS) {
  ax <- abs(x)
  ifelse(is.na(x), NA_real_,
    ifelse(ax <= linthresh, x / linthresh,
           sign(x) * (1 + log10(ax / linthresh))))
}

scaled_tick_marks <- function(raw_vals) {
  max_abs <- max(abs(raw_vals), na.rm = TRUE)
  if (!is.finite(max_abs) || max_abs <= 0) return(list(vals = 0, text = "0"))
  raw <- TICK_ANCHOR_DAYS[TICK_ANCHOR_DAYS <= max_abs]
  all_raw <- c(-rev(raw), 0, raw)
  list(vals = symlog10(all_raw), text = as.character(as.integer(all_raw)))
}

infer_min_cell <- function(df, col_names) {
  env_val <- suppressWarnings(as.integer(Sys.getenv("MIN_CELL_COUNT", unset = "")))
  if (!is.na(env_val)) return(max(0L, env_val))
  m <- 0L
  for (cn in col_names) {
    if (is.na(cn) || !cn %in% names(df)) next
    v <- suppressWarnings(as.numeric(df[[cn]]))
    negs <- v[!is.na(v) & v < 0]
    if (length(negs) > 0) m <- max(m, as.integer(max(-negs)))
  }
  m
}

pct_rate <- function(num, den, min_cell = 0L) {
  num <- suppressWarnings(as.numeric(num))
  den <- suppressWarnings(as.numeric(den))
  ifelse(is.na(den) | den < 0 | den <= min_cell | is.na(num) | num < 0,
         NA_real_, 100 * num / den)
}

fmt_n <- function(x) {
  v <- suppressWarnings(as.numeric(x))
  ifelse(is.na(v) | v < 0, "—",
         formatC(as.integer(round(v)), format = "d", big.mark = ","))
}

fmt_n_pct <- function(n, pct) {
  nv <- suppressWarnings(as.numeric(n))
  pv <- suppressWarnings(as.numeric(pct))
  ifelse(is.na(nv) | nv < 0, "—",
    ifelse(is.na(pv),
      formatC(as.integer(round(nv)), format = "d", big.mark = ","),
      sprintf("%s (%.1f%%)", formatC(as.integer(round(nv)), format = "d", big.mark = ","), pv)))
}

day_label <- function(v) {
  rv <- suppressWarnings(round(as.numeric(v)))
  ifelse(is.na(rv), "—", as.character(as.integer(rv)))
}

family_display <- function(f) {
  m <- c(DX  = "Cancer Dx (main)",
         GDX = "Cancer Dx (generalized)",
         ODX = "Cancer Dx (other malignancies)",
         MET = "Metastasis / Stage IV",
         L01 = "Antineoplastic exposure (ATC L01)")
  lbl <- m[toupper(trimws(as.character(f)))]
  ifelse(is.na(lbl), as.character(f), lbl)
}

df_to_html_table <- function(df, css_class = "report-table") {
  if (is.null(df) || nrow(df) == 0) return("<p class='subtle'><i>No data.</i></p>")
  th <- paste(sprintf("<th>%s</th>", htmlEscape(names(df))), collapse = "")
  rows <- apply(df, 1L, function(row) {
    cells <- paste(sprintf("<td>%s</td>", htmlEscape(as.character(row))), collapse = "")
    paste0("<tr>", cells, "</tr>")
  })
  sprintf('<table class="%s"><thead><tr>%s</tr></thead><tbody>%s</tbody></table>',
          css_class, th, paste(rows, collapse = "\n"))
}

apply_timing_xaxis <- function(fig, raw_vals) {
  tks <- scaled_tick_marks(raw_vals)
  fig %>% layout(xaxis = list(
    tickmode = "array", tickvals = tks$vals, ticktext = tks$text,
    zeroline = TRUE, zerolinewidth = 1, zerolinecolor = "#cbd5e1",
    gridcolor = "#e5e7eb", title = "Days"
  ))
}

# Resolve quantile column names (supports lq/median/uq or p25/p50/p75)
resolve_quantile_cols <- function(df) {
  list(
    p05 = col_ci(df, "p05_days"),
    p10 = col_ci(df, "p10_days"),
    lq  = coalesce(col_ci(df, "lq_days"),     col_ci(df, "p25_days")),
    med = coalesce(col_ci(df, "median_days"),  col_ci(df, "p50_days")),
    uq  = coalesce(col_ci(df, "uq_days"),      col_ci(df, "p75_days")),
    p90 = col_ci(df, "p90_days"),
    p95 = col_ci(df, "p95_days")
  )
}

# ---------------------------------------------------------------------------
# DatabaseConnector: concept name lookup
# ---------------------------------------------------------------------------
fetch_concept_names <- function(concept_ids) {
  if (is.null(OMOP_CONNECTION_DETAILS) || length(concept_ids) == 0) {
    return(setNames(rep(NA_character_, length(concept_ids)), as.character(concept_ids)))
  }
  tryCatch({
    conn <- DatabaseConnector::connect(OMOP_CONNECTION_DETAILS)
    on.exit(DatabaseConnector::disconnect(conn), add = TRUE)
    sql <- sprintf(
      "SELECT concept_id, concept_name FROM %s.concept WHERE concept_id IN (%s)",
      OMOP_CDM_SCHEMA, paste(as.integer(concept_ids), collapse = ", ")
    )
    res <- DatabaseConnector::querySql(conn, sql)
    setNames(as.character(res$CONCEPT_NAME), as.character(res$CONCEPT_ID))
  }, error = function(e) {
    message("Concept name lookup failed: ", conditionMessage(e))
    setNames(rep(NA_character_, length(concept_ids)), as.character(concept_ids))
  })
}

# ---------------------------------------------------------------------------
# Plot helpers
# ---------------------------------------------------------------------------

# Single-row horizontal boxplot for one timing pair (focus section)
timing_single_row_plot <- function(df, from_ev, to_ev) {
  if (is.null(df) || nrow(df) == 0) return(NULL)
  fc  <- col_ci(df, "from_event")
  tc  <- col_ci(df, "to_event")
  qcs <- resolve_quantile_cols(df)
  need <- c("p05", "p10", "lq", "med", "uq", "p90", "p95")
  if (is.na(fc) || is.na(tc) || any(is.na(unlist(qcs[need])))) return(NULL)

  sel <- df[toupper(df[[fc]]) == toupper(from_ev) & toupper(df[[tc]]) == toupper(to_ev), ]
  if (nrow(sel) == 0) return(NULL)
  r <- sel[1L, ]

  get_num <- function(cn) suppressWarnings(as.numeric(r[[cn]]))
  p05 <- get_num(qcs$p05); p10 <- get_num(qcs$p10)
  lq  <- get_num(qcs$lq);  med <- get_num(qcs$med); uq <- get_num(qcs$uq)
  p90 <- get_num(qcs$p90); p95 <- get_num(qcs$p95)
  raw_vals <- c(p05, p10, lq, med, uq, p90, p95)

  p05s <- symlog10(p05); p10s <- symlog10(p10)
  lqs  <- symlog10(lq);  meds <- symlog10(med);  uqs <- symlog10(uq)
  p90s <- symlog10(p90); p95s <- symlog10(p95)
  lbl  <- paste(from_ev, "→", to_ev)

  nc <- col_ci(df, "n_patients_with_pair")
  n_val <- if (!is.na(nc)) suppressWarnings(as.integer(r[[nc]])) else NA_integer_

  ht <- paste0(
    "%{y}<br>",
    sprintf("Median (IQR): %s (%s–%s) days<br>",
            day_label(med), day_label(lq), day_label(uq)),
    sprintf("P10–P90: %s–%s days", day_label(p10), day_label(p90)),
    if (!is.na(n_val)) sprintf("<br>n: %s", formatC(n_val, format = "d", big.mark = ",")) else "",
    "<extra></extra>"
  )

  fig <- plot_ly() %>%
    add_trace(
      type        = "box",
      orientation = "h",
      y           = list(lbl),
      q1          = list(lqs),
      median      = list(meds),
      q3          = list(uqs),
      lowerfence  = list(p05s),
      upperfence  = list(p95s),
      fillcolor   = "rgba(37, 99, 235, 0.35)",
      line        = list(color = "#1d4ed8", width = 1.2),
      whiskerwidth = 0.65,
      hovertemplate = ht,
      showlegend  = FALSE
    ) %>%
    add_trace(
      type = "scatter", mode = "markers",
      x = p10s, y = lbl, name = "P10",
      marker = list(symbol = "line-ns", size = 12,
                    line = list(width = 1.6, color = "#78716c"), opacity = 0.75),
      hovertemplate = sprintf("P10: %s days<extra></extra>", day_label(p10)),
      showlegend = FALSE
    ) %>%
    add_trace(
      type = "scatter", mode = "markers",
      x = p90s, y = lbl, name = "P90",
      marker = list(symbol = "line-ns", size = 12,
                    line = list(width = 1.6, color = "#a8a29e"), opacity = 0.75),
      hovertemplate = sprintf("P90: %s days<extra></extra>", day_label(p90)),
      showlegend = FALSE
    ) %>%
    layout(
      template = "plotly_white",
      height   = 240,
      margin   = list(l = 12, r = 20, t = 10, b = 56),
      yaxis    = list(title = "", automargin = TRUE),
      hovermode = "closest"
    ) %>%
    apply_timing_xaxis(raw_vals)

  fig
}

# Multi-row horizontal box chart: all FROM→TO pairs in one figure
timing_pairs_overview_plot <- function(df) {
  if (is.null(df) || nrow(df) == 0) return(NULL)
  fc  <- col_ci(df, "from_event")
  tc  <- col_ci(df, "to_event")
  qcs <- resolve_quantile_cols(df)
  need <- c("p05", "p10", "lq", "med", "uq", "p90", "p95")
  if (is.na(fc) || is.na(tc) || any(is.na(unlist(qcs[need])))) return(NULL)

  sub <- df %>%
    mutate(.pair = paste(.data[[fc]], "→", .data[[tc]])) %>%
    arrange(.pair)

  get_col <- function(cn) suppressWarnings(as.numeric(sub[[cn]]))
  p05 <- get_col(qcs$p05); p10 <- get_col(qcs$p10)
  lq  <- get_col(qcs$lq);  med <- get_col(qcs$med); uq <- get_col(qcs$uq)
  p90 <- get_col(qcs$p90); p95 <- get_col(qcs$p95)
  raw_vals <- c(p05, p10, lq, med, uq, p90, p95)

  p05s <- symlog10(p05); p10s <- symlog10(p10)
  lqs  <- symlog10(lq);  meds <- symlog10(med);  uqs <- symlog10(uq)
  p90s <- symlog10(p90); p95s <- symlog10(p95)
  labels <- sub$.pair

  nc <- col_ci(sub, "n_patients_with_pair")
  ht_n <- if (!is.na(nc)) "<br>n: %{customdata[0]}" else ""

  ht <- paste0(
    "%{y}<br>",
    "Median (IQR): %{meta[4]} (%{meta[3]}–%{meta[5]}) days<br>",
    "P10–P90: %{meta[2]}–%{meta[6]} days",
    ht_n, "<extra></extra>"
  )

  meta_rows <- lapply(seq_along(labels), function(i)
    list(day_label(p05[i]), day_label(p10[i]), day_label(lq[i]),
         day_label(med[i]), day_label(uq[i]), day_label(p90[i]), day_label(p95[i])))

  h <- max(380L, min(900L, 32L * nrow(sub) + 120L))

  fig <- plot_ly() %>%
    add_trace(
      type        = "box",
      orientation = "h",
      y           = labels,
      q1          = lqs,
      median      = meds,
      q3          = uqs,
      lowerfence  = p05s,
      upperfence  = p95s,
      fillcolor   = "rgba(37, 99, 235, 0.35)",
      line        = list(color = "#1d4ed8", width = 1.2),
      whiskerwidth = 0.65,
      meta        = meta_rows,
      hovertemplate = ht,
      showlegend  = FALSE
    ) %>%
    add_trace(
      type = "scatter", mode = "markers",
      x = p10s, y = labels, name = "P10",
      marker = list(symbol = "line-ns", size = 12,
                    line = list(width = 1.6, color = "#78716c"), opacity = 0.75),
      customdata = day_label(p10),
      hovertemplate = "%{y}<br>P10: %{customdata} days<extra></extra>"
    ) %>%
    add_trace(
      type = "scatter", mode = "markers",
      x = p90s, y = labels, name = "P90",
      marker = list(symbol = "line-ns", size = 12,
                    line = list(width = 1.6, color = "#a8a29e"), opacity = 0.75),
      customdata = day_label(p90),
      hovertemplate = "%{y}<br>P90: %{customdata} days<extra></extra>"
    ) %>%
    layout(
      template  = "plotly_white",
      height    = h,
      margin    = list(l = 24, r = 28, t = 8, b = 48),
      legend    = list(orientation = "h", yanchor = "bottom", y = 1.02,
                       xanchor = "right", x = 1),
      yaxis     = list(title = "", automargin = TRUE),
      hovermode = "closest"
    ) %>%
    apply_timing_xaxis(raw_vals)

  fig
}

# ---------------------------------------------------------------------------
# Section: Legend
# ---------------------------------------------------------------------------
section_legend <- function() {
  rows <- list(
    c("DX",  "Main cancer diagnosis concepts (the cohort's target cancer dx set)."),
    c("GDX", "Generalized cancer diagnosis concepts: ancestors of DX within malignant neoplastic disease."),
    c("ODX", "Other cancer diagnosis concepts: malignancies excluding DX and GDX."),
    c("MET", "Metastasis / Stage IV occurrence."),
    c("L01", "Exposure to antineoplastic agents (ATC L01 descendants; from drug_exposure)."),
    c("ANCHOR_EVENT = INDEX",      "Anchored to first DX date."),
    c("ANCHOR_EVENT = FIRST_MET",  "Anchored to first MET date."),
    c("TIME_RELATIVE = BEFORE",    "Event date occurs before the anchor date."),
    c("TIME_RELATIVE = AFTER",     "Event date occurs on/after the anchor date.")
  )
  trs <- sapply(rows, function(r)
    sprintf("<tr><td><code>%s</code></td><td>%s</td></tr>",
            htmlEscape(r[1]), htmlEscape(r[2])))
  tbl <- sprintf(
    '<table class="report-table"><thead><tr><th>Label</th><th>Meaning</th></tr></thead><tbody>%s</tbody></table>',
    paste(trs, collapse = "\n"))
  div(class = "section card stack",
    tags$h2("Legend"),
    tags$p(class = "subtle", "Abbreviations used throughout the tables and plots."),
    HTML(tbl)
  )
}

# ---------------------------------------------------------------------------
# Section: Population Prevalence
# ---------------------------------------------------------------------------
section_prevalence <- function(rd) {
  df <- read_csv_safe(file.path(rd, "final_population_prevalence.csv"))
  if (is.null(df)) {
    return(div(class = "section card stack",
      tags$h2("Population prevalence"),
      tags$p(class = "subtle", tags$i("Missing final_population_prevalence.csv"))
    ))
  }

  yc     <- col_ci(df, "prevalence_year")
  ndx_c  <- col_ci(df, "n_dx")
  nmet_c <- col_ci(df, "n_met")
  nl01_c <- col_ci(df, "n_l01")
  nodx_c <- col_ci(df, "n_odx")
  ngdx_c <- col_ci(df, "n_gdx")
  min_cell <- infer_min_cell(df, c(ndx_c, nmet_c, nl01_c, nodx_c, ngdx_c))

  if (is.na(yc)) {
    return(div(class = "section card stack",
      tags$h2("Population prevalence"),
      tags$p("No prevalence_year column found.")
    ))
  }

  is_overall <- toupper(as.character(df[[yc]])) == "OVERALL"
  overall_df <- df[is_overall, , drop = FALSE]
  yearly_df  <- df[!is_overall, , drop = FALSE]

  # Overall summary table
  overall_html <- "<p class='subtle'><i>No OVERALL row.</i></p>"
  if (nrow(overall_df) > 0 && !is.na(ndx_c)) {
    r <- overall_df[1L, ]
    ndx_v <- suppressWarnings(as.numeric(r[[ndx_c]]))
    tbl_df <- data.frame(
      "DX"  = fmt_n_pct(ndx_v, ifelse(!is.na(ndx_v) & ndx_v > min_cell, 100, NA)),
      "MET" = if (!is.na(nmet_c)) fmt_n_pct(r[[nmet_c]], pct_rate(r[[nmet_c]], ndx_v, min_cell)) else "—",
      "L01" = if (!is.na(nl01_c)) fmt_n_pct(r[[nl01_c]], pct_rate(r[[nl01_c]], ndx_v, min_cell)) else "—",
      "ODX" = if (!is.na(nodx_c)) fmt_n_pct(r[[nodx_c]], pct_rate(r[[nodx_c]], ndx_v, min_cell)) else "—",
      "GDX" = if (!is.na(ngdx_c)) fmt_n_pct(r[[ngdx_c]], pct_rate(r[[ngdx_c]], ndx_v, min_cell)) else "—",
      stringsAsFactors = FALSE, check.names = FALSE
    )
    overall_html <- df_to_html_table(tbl_df)
  }

  # Yearly chart
  yearly_plot <- NULL
  if (nrow(yearly_df) > 0 && !is.na(ndx_c)) {
    yearly_df$.__y <- suppressWarnings(as.numeric(as.character(yearly_df[[yc]])))
    yearly_df <- yearly_df[!is.na(yearly_df$.__y), ]
    yearly_df <- yearly_df[order(yearly_df$.__y), ]
    years  <- as.integer(yearly_df$.__y)
    ndx_v  <- pmax(0, suppressWarnings(as.numeric(yearly_df[[ndx_c]])), na.rm = FALSE)
    ndx_v[ndx_v < 0] <- NA

    fig <- plot_ly() %>%
      add_trace(type = "bar", x = years, y = ndx_v,
                name = paste0("N (", family_display("DX"), ")"),
                marker = list(color = "#1d4ed8", opacity = 0.85))

    if (!is.na(nmet_c)) {
      pct_met <- pct_rate(yearly_df[[nmet_c]], yearly_df[[ndx_c]], min_cell)
      fig <- fig %>% add_trace(
        type = "scatter", mode = "lines+markers",
        x = years, y = pct_met,
        name = paste0("% with ", family_display("MET")), yaxis = "y2",
        line = list(color = "#d97706", width = 2.2),
        marker = list(size = 7, color = "#d97706"))
    }
    if (!is.na(nl01_c)) {
      pct_l01 <- pct_rate(yearly_df[[nl01_c]], yearly_df[[ndx_c]], min_cell)
      fig <- fig %>% add_trace(
        type = "scatter", mode = "lines+markers",
        x = years, y = pct_l01,
        name = paste0("% with ", family_display("L01")), yaxis = "y2",
        line = list(color = "#16a34a", width = 2.2, dash = "dot"),
        marker = list(size = 7, color = "#16a34a"))
    }
    if (!is.na(nodx_c)) {
      pct_odx <- pct_rate(yearly_df[[nodx_c]], yearly_df[[ndx_c]], min_cell)
      fig <- fig %>% add_trace(
        type = "scatter", mode = "lines+markers",
        x = years, y = pct_odx,
        name = "% with other Cancer Dx (ODX)", yaxis = "y2",
        line = list(color = "#7c3aed", width = 2.2, dash = "dash"),
        marker = list(size = 7, color = "#7c3aed", symbol = "diamond"))
    }
    yearly_plot <- fig %>% layout(
      template  = "plotly_white",
      height    = 420,
      margin    = list(l = 48, r = 56, t = 40, b = 48),
      legend    = list(orientation = "h", yanchor = "bottom", y = 1.02,
                       xanchor = "right", x = 1),
      yaxis     = list(title = "Patients (N_DX)", gridcolor = "#e5e7eb"),
      yaxis2    = list(title = "Share of cohort (%)", overlaying = "y", side = "right",
                       showgrid = FALSE, rangemode = "tozero"),
      xaxis     = list(title = "Calendar year", dtick = 1),
      hovermode = "x unified"
    )
  }

  div(class = "section card stack",
    tags$h2("Population prevalence"),
    tags$p(class = "subtle",
      "Denominator for percentages is N_DX. Suppressed cells (small N) shown as —."),
    tags$h3("Overall"),
    HTML(overall_html),
    tags$h3("By year"),
    if (!is.null(yearly_plot))
      tagList(div(class = "plot-wrap", yearly_plot),
              tags$p(class = "subtle",
                "DX = main cancer dx; GDX = generalized; ODX = other malignancies; MET = metastasis/stage IV; L01 = antineoplastic."))
    else
      tags$p(class = "subtle", tags$i("No yearly data available."))
  )
}

# ---------------------------------------------------------------------------
# Section: Demographics
# ---------------------------------------------------------------------------
section_demographics <- function(rd) {
  df <- read_csv_safe(file.path(rd, "final_demographics_from_anchors.csv"))

  anchor_c <- if (!is.null(df)) col_ci(df, "anchor_event") else NA_character_
  np_c     <- if (!is.null(df)) col_ci(df, "n_patients")   else NA_character_
  nm_c     <- if (!is.null(df)) col_ci(df, "n_male")       else NA_character_
  nf_c     <- if (!is.null(df)) col_ci(df, "n_female")     else NA_character_
  alq_c    <- if (!is.null(df)) col_ci(df, "age_lq_years")     else NA_character_
  amed_c   <- if (!is.null(df)) col_ci(df, "age_median_years") else NA_character_
  auq_c    <- if (!is.null(df)) col_ci(df, "age_uq_years")     else NA_character_

  body <- if (is.null(df) || is.na(anchor_c) || is.na(np_c)) {
    tags$p(class = "subtle", tags$i(
      if (is.null(df)) "Missing final_demographics_from_anchors.csv."
      else "Required columns not found."))
  } else {
    anchor_order <- c("INDEX" = "DX index (INDEX)", "FIRST_MET" = "MET index (FIRST_MET)")
    rows <- lapply(names(anchor_order), function(aname) {
      sel <- df[toupper(df[[anchor_c]]) == aname, , drop = FALSE]
      if (nrow(sel) == 0) return(NULL)
      r    <- sel[1L, ]
      n_v  <- suppressWarnings(as.numeric(r[[np_c]]))
      n_s  <- if (!is.na(n_v) && n_v >= 0) formatC(as.integer(n_v), format = "d", big.mark = ",") else "—"
      age_s <- if (!is.na(amed_c) && !is.na(alq_c) && !is.na(auq_c)) {
        med <- suppressWarnings(round(as.numeric(r[[amed_c]]), 1))
        lq  <- suppressWarnings(round(as.numeric(r[[alq_c]]),  1))
        uq  <- suppressWarnings(round(as.numeric(r[[auq_c]]),  1))
        if (all(!is.na(c(med, lq, uq)))) sprintf("%.1f (%.1f–%.1f)", med, lq, uq) else "—"
      } else "—"
      pct_m_s <- if (!is.na(nm_c) && !is.na(nf_c)) {
        nm <- suppressWarnings(as.numeric(r[[nm_c]]))
        nf <- suppressWarnings(as.numeric(r[[nf_c]]))
        tot <- nm + nf
        if (!is.na(tot) && tot > 0) sprintf("%.1f%%", 100 * nm / tot) else "—"
      } else "—"
      pct_f_s <- if (!is.na(nm_c) && !is.na(nf_c)) {
        nm <- suppressWarnings(as.numeric(r[[nm_c]]))
        nf <- suppressWarnings(as.numeric(r[[nf_c]]))
        tot <- nm + nf
        if (!is.na(tot) && tot > 0) sprintf("%.1f%%", 100 * nf / tot) else "—"
      } else "—"
      list(`Index` = anchor_order[[aname]], `N` = n_s,
           `Median age, yr (IQR)` = age_s, `% male` = pct_m_s, `% female` = pct_f_s)
    })
    rows <- Filter(Negate(is.null), rows)
    if (length(rows) == 0) {
      tags$p(class = "subtle", tags$i("No INDEX or FIRST_MET rows found."))
    } else {
      HTML(df_to_html_table(as.data.frame(do.call(rbind, lapply(rows, as.data.frame,
                                                                 stringsAsFactors = FALSE)),
                                           stringsAsFactors = FALSE, check.names = FALSE)))
    }
  }

  div(class = "section card stack",
    tags$h2("Demographics"),
    tags$p(class = "subtle",
      "Patients and age distribution at each anchor. Age (years) at anchor date."),
    body
  )
}

# ---------------------------------------------------------------------------
# Section: Anchor DX concept counts
# ---------------------------------------------------------------------------
section_anchor_dx_counts <- function(rd, top_n = ANCHOR_DX_COUNTS_TOP_N) {
  df <- read_csv_safe(file.path(rd, "final_anchor_dx_concept_counts.csv"))
  body <- if (is.null(df)) {
    tags$p(class = "subtle", tags$i("Missing final_anchor_dx_concept_counts.csv."))
  } else {
    cid_c  <- col_ci(df, "concept_id")
    npat_c <- col_ci(df, "n_distinct_patients")
    nday_c <- col_ci(df, "n_distinct_patient_days")
    if (is.na(cid_c) || is.na(npat_c) || is.na(nday_c)) {
      tags$p(class = "subtle", tags$i("Required columns not found."))
    } else {
      work <- df
      work$.__npat <- suppressWarnings(as.numeric(work[[npat_c]]))
      work$.__cid  <- suppressWarnings(as.numeric(work[[cid_c]]))
      work <- work[order(-work$.__npat, work$.__cid, na.last = TRUE), ]
      work <- head(work, top_n)

      cids <- suppressWarnings(as.integer(work[[cid_c]]))
      name_map <- fetch_concept_names(cids[!is.na(cids)])

      rows <- lapply(seq_len(nrow(work)), function(i) {
        r    <- work[i, ]
        cid  <- suppressWarnings(as.integer(r[[cid_c]]))
        nm   <- if (!is.na(cid) && as.character(cid) %in% names(name_map))
                  name_map[[as.character(cid)]] else NA_character_
        list(
          `#`              = i,
          `Concept ID`     = as.character(r[[cid_c]]),
          `Concept name`   = if (!is.na(nm)) nm else "—",
          `Patients`       = fmt_n(r[[npat_c]]),
          `Patient-days`   = fmt_n(r[[nday_c]])
        )
      })
      HTML(df_to_html_table(
        as.data.frame(do.call(rbind, lapply(rows, as.data.frame,
                                            stringsAsFactors = FALSE)), check.names = FALSE)
      ))
    }
  }
  div(class = "section card stack",
    tags$h2("Main cohort diagnosis codes"),
    tags$p(class = "subtle",
      sprintf(
        "Most frequent anchor DX condition concepts. ",
        "Patients = distinct persons; Patient-days = distinct (person, calendar day) pairs. ",
        "Showing top %d by patient count.%s",
        as.integer(top_n),
        if (is.null(OMOP_CONNECTION_DETAILS)) " (Concept names not resolved: no DB connection.)" else ""
      )
    ),
    body
  )
}

# ---------------------------------------------------------------------------
# Section: Deaths
# ---------------------------------------------------------------------------
section_deaths <- function(rd) {
  df <- read_csv_safe(file.path(rd, "final_death_from_anchors.csv"))
  body <- if (is.null(df)) {
    tags$p(class = "subtle", tags$i("Missing final_death_from_anchors.csv."))
  } else {
    yc      <- col_ci(df, "prevalence_year")
    aev_c   <- col_ci(df, "anchor_event")
    np_c    <- col_ci(df, "n_patients")
    nd_c    <- col_ci(df, "n_deaths")
    if (is.na(yc) || is.na(aev_c) || is.na(np_c) || is.na(nd_c)) {
      tags$p(class = "subtle", tags$i("Required columns not found."))
    } else {
      is_overall <- toupper(as.character(df[[yc]])) == "OVERALL"
      by_year <- df[!is_overall, , drop = FALSE]
      by_year$.__y <- suppressWarnings(as.numeric(as.character(by_year[[yc]])))
      by_year <- by_year[!is.na(by_year$.__y), ]
      by_year <- by_year[order(by_year$.__y, by_year[[aev_c]]), ]

      min_cell <- infer_min_cell(df, c(np_c, nd_c))
      anchors  <- unique(toupper(by_year[[aev_c]]))
      colors   <- c(INDEX = "#1d4ed8", FIRST_MET = "#d97706")
      dashes   <- c(INDEX = "solid",   FIRST_MET = "dash")

      fig <- plot_ly()
      any_trace <- FALSE
      for (anch in anchors) {
        sub  <- by_year[toupper(by_year[[aev_c]]) == anch, ]
        if (nrow(sub) == 0) next
        pct  <- pct_rate(sub[[nd_c]], sub[[np_c]], min_cell)
        col  <- if (anch %in% names(colors)) colors[[anch]] else "#6b7280"
        dash <- if (anch %in% names(dashes)) dashes[[anch]] else "solid"
        fig  <- fig %>% add_trace(
          type = "scatter", mode = "lines+markers",
          x = as.integer(sub$.__y), y = pct,
          name = sprintf("%% deaths (%s)", anch),
          line = list(color = col, width = 2.2, dash = dash),
          marker = list(size = 7, color = col),
          hovertemplate = paste0("Year %{x}<br>% deaths: %{y:.1f}%<extra></extra>")
        )
        any_trace <- TRUE
      }
      if (!any_trace) {
        tags$p(class = "subtle", tags$i("No data to plot."))
      } else {
        fig <- fig %>% layout(
          template  = "plotly_white",
          height    = 380,
          margin    = list(l = 48, r = 24, t = 24, b = 48),
          legend    = list(orientation = "h", yanchor = "bottom", y = 1.02,
                           xanchor = "right", x = 1),
          xaxis     = list(title = "Calendar year", dtick = 1),
          yaxis     = list(title = "% deaths", rangemode = "tozero", gridcolor = "#e5e7eb"),
          hovermode = "x unified"
        )
        div(class = "plot-wrap", fig)
      }
    }
  }

  div(class = "section card stack",
    tags$h2("Deaths"),
    tags$p(class = "subtle",
      "Percentage of cohort who died, by year and anchor (INDEX = first DX; FIRST_MET = first MET)."),
    body
  )
}

# ---------------------------------------------------------------------------
# Section: Focus timing plots + linked event code counts
# ---------------------------------------------------------------------------

# Read the overall N for each event family (denominator for pair %)
read_from_event_denominators <- function(rd) {
  df <- read_csv_safe(file.path(rd, "final_population_prevalence.csv"))
  if (is.null(df)) return(list())
  yc  <- col_ci(df, "prevalence_year")
  if (is.na(yc)) return(list())
  overall <- df[toupper(as.character(df[[yc]])) == "OVERALL", , drop = FALSE]
  if (nrow(overall) == 0) return(list())
  r <- overall[1L, ]
  pairs <- list(DX = "n_dx", MET = "n_met", L01 = "n_l01", ODX = "n_odx", GDX = "n_gdx")
  out <- list()
  for (fam in names(pairs)) {
    cn <- col_ci(df, pairs[[fam]])
    if (!is.na(cn)) {
      v <- suppressWarnings(as.integer(r[[cn]]))
      if (!is.na(v) && v > 0) out[[fam]] <- v
    }
  }
  out
}

# Return top-N event codes for a focus pair as a data.frame
ecc_top_n <- function(rd, from_ev, to_ev, timing_key,
                      n_pair = NULL, top_n = EVENT_CODE_COUNTS_TOP_N) {
  vinfo      <- TIMING_VARIANTS[[timing_key]]
  time_rel   <- vinfo$time_relative   # NULL | "BEFORE" | "AFTER"
  anchor_ev  <- if (toupper(from_ev) == "DX") "INDEX" else "FIRST_MET"
  family     <- toupper(to_ev)

  if (!is.null(time_rel)) {
    df <- read_csv_safe(file.path(rd, "final_event_code_counts_before_after.csv"))
  } else {
    df <- read_csv_safe(file.path(rd, "final_event_code_counts.csv"))
  }
  if (is.null(df)) return(NULL)

  aev_c  <- col_ci(df, "anchor_event")
  fam_c  <- col_ci(df, "event_family")
  cid_c  <- col_ci(df, "concept_id")
  np_c   <- col_ci(df, "n_patients")
  tr_c   <- if (!is.null(time_rel)) col_ci(df, "time_relative") else NA_character_
  med_c  <- coalesce(col_ci(df, "median_days_closest"), col_ci(df, "median_days"))

  if (is.na(aev_c) || is.na(fam_c) || is.na(cid_c) || is.na(np_c)) return(NULL)

  mask <- toupper(df[[aev_c]]) == anchor_ev & toupper(df[[fam_c]]) == family
  if (!is.null(time_rel) && !is.na(tr_c)) {
    mask <- mask & toupper(df[[tr_c]]) == time_rel
  }
  sub <- df[mask, , drop = FALSE]
  if (nrow(sub) == 0) return(NULL)

  sub$.__np <- suppressWarnings(as.numeric(sub[[np_c]]))
  sub <- sub[!is.na(sub$.__np) & sub$.__np >= 0, ]
  sub <- sub[order(-sub$.__np), ]
  sub <- head(sub, top_n)
  if (nrow(sub) == 0) return(NULL)

  cids <- suppressWarnings(as.integer(sub[[cid_c]]))
  name_map <- fetch_concept_names(cids[!is.na(cids)])

  rows <- lapply(seq_len(nrow(sub)), function(i) {
    r   <- sub[i, ]
    cid <- suppressWarnings(as.integer(r[[cid_c]]))
    nm  <- if (!is.na(cid) && as.character(cid) %in% names(name_map))
             name_map[[as.character(cid)]] else NA_character_
    np_v <- suppressWarnings(as.numeric(r[[np_c]]))
    pct_s <- if (!is.null(n_pair) && !is.na(n_pair) && n_pair > 0 && !is.na(np_v) && np_v >= 0)
               sprintf("%.1f%%", 100 * np_v / n_pair)
             else "—"
    med_s <- if (!is.na(med_c) && med_c %in% names(r))
               day_label(r[[med_c]])
             else "—"
    list(
      `Concept ID`   = as.character(r[[cid_c]]),
      `Concept name` = if (!is.na(nm)) nm else "—",
      `N patients`   = fmt_n(np_v),
      `% of pair`    = pct_s,
      `Median days`  = med_s
    )
  })
  as.data.frame(do.call(rbind, lapply(rows, as.data.frame,
                                       stringsAsFactors = FALSE)), check.names = FALSE)
}

section_focus_timing <- function(rd) {
  from_denoms <- read_from_event_denominators(rd)
  ecc_blocks  <- list()
  focus_items <- list()

  for (plot_row in FOCUS_TIMING_PLOTS) {
    from_ev <- toupper(trimws(plot_row$from))
    to_ev   <- toupper(trimws(plot_row$to))
    vkey    <- plot_row$timing
    vinfo   <- TIMING_VARIANTS[[vkey]]
    if (is.null(vinfo)) next

    tpath <- file.path(rd, vinfo$file)
    tdf   <- read_csv_safe(tpath)
    fig   <- if (!is.null(tdf)) timing_single_row_plot(tdf, from_ev, to_ev) else NULL

    nc <- if (!is.null(tdf)) col_ci(tdf, "n_patients_with_pair") else NA_character_
    n_pair <- if (!is.null(tdf) && !is.na(nc)) {
      fc <- col_ci(tdf, "from_event"); tc <- col_ci(tdf, "to_event")
      if (!is.na(fc) && !is.na(tc)) {
        sel <- tdf[toupper(tdf[[fc]]) == from_ev & toupper(tdf[[tc]]) == to_ev, ]
        if (nrow(sel) > 0) suppressWarnings(as.integer(sel[[nc]][1L])) else NA_integer_
      } else NA_integer_
    } else NA_integer_

    pair_id  <- gsub("[^A-Za-z0-9]", "_", paste(from_ev, to_ev, vkey, sep = "_"))
    ecc_id   <- paste0("ecc_", pair_id)
    ecc_data <- ecc_top_n(rd, from_ev, to_ev, vkey, n_pair = n_pair)

    hword <- switch(vkey,
      first_to_first          = "first",
      first_to_closest        = "closest",
      first_to_closest_before = "closest (before)",
      first_to_closest_after  = "closest (after)",
      vkey)

    focus_items[[length(focus_items) + 1L]] <- list(
      from_ev = from_ev, to_ev = to_ev, hword = hword,
      commentary = plot_row$commentary,
      n_from = from_denoms[[from_ev]], n_pair = n_pair,
      fig = fig, ecc_id = ecc_id
    )
    ecc_blocks[[length(ecc_blocks) + 1L]] <- list(
      id = ecc_id,
      heading = sprintf("Event code counts (top %d): %s → %s %s",
                        EVENT_CODE_COUNTS_TOP_N, from_ev, hword, to_ev),
      caption = sprintf("Family = %s; anchor = %s; timing = %s.",
                        to_ev, if (from_ev == "DX") "INDEX" else "FIRST_MET", vinfo$title),
      df = ecc_data
    )
  }

  # Group focus items by FROM event
  groups <- list()
  for (it in focus_items) {
    key <- it$from_ev
    if (is.null(groups[[key]])) groups[[key]] <- list()
    groups[[key]][[length(groups[[key]]) + 1L]] <- it
  }

  focus_html <- tagList(
    div(class = "section",
      tags$h2("Timing pair focus"),
      tags$p(class = "subtle",
        "Selected pairs. Box spans IQR (Q1–Q3); whiskers at P05–P95. ",
        "Tick marks at P10 and P90. Days = TO − FROM (negative = TO before FROM)."),
      lapply(names(groups), function(from_key) {
        items <- groups[[from_key]]
        div(class = "section card stack",
          tags$h3(sprintf("Timings from first %s", from_key)),
          lapply(items, function(it) {
            tagList(
              tags$h4(sprintf("%s → %s %s", it$from_ev, it$hword, it$to_ev)),
              if (!is.null(it$commentary) && nchar(it$commentary) > 0)
                tags$p(class = "commentary", it$commentary)
              else NULL,
              if (!is.null(it$fig))
                tagList(
                  tags$p(class = "subtle",
                    tags$a(href = paste0("#", it$ecc_id),
                           sprintf("Event code counts (top %d) →", EVENT_CODE_COUNTS_TOP_N))),
                  div(class = "plot-wrap", it$fig)
                )
              else
                tags$p(class = "subtle", tags$i("No data for this pair."))
            )
          })
        )
      })
    )
  )

  ecc_html <- div(class = "section card stack",
    tags$h2("Event code counts (linked)"),
    tags$p(class = "subtle",
      sprintf("Linked from focus timing plots above. Top %d concepts by N patients.",
              EVENT_CODE_COUNTS_TOP_N)),
    lapply(ecc_blocks, function(blk) {
      div(id = blk$id, class = "card stack",
        tags$h3(blk$heading),
        tags$p(class = "subtle", blk$caption),
        HTML(df_to_html_table(blk$df))
      )
    })
  )

  tagList(focus_html, ecc_html)
}

# ---------------------------------------------------------------------------
# Section: Timing pairs overview (all 4 variant exports)
# ---------------------------------------------------------------------------
section_timing_pairs <- function(rd) {
  children <- lapply(TIMING_VARIANTS_ORDER, function(key) {
    vinfo <- TIMING_VARIANTS[[key]]
    tdf   <- read_csv_safe(file.path(rd, vinfo$file))
    fig   <- if (!is.null(tdf)) timing_pairs_overview_plot(tdf) else NULL
    tagList(
      tags$h3(vinfo$title),
      if (!is.null(fig))
        div(class = "plot-wrap", fig)
      else
        tags$p(class = "subtle", tags$i(sprintf("Not found: %s", vinfo$file)))
    )
  })
  div(class = "section card stack",
    tags$h2("Timing pairs"),
    tags$p(class = "subtle",
      "Each row is a FROM → TO event pair. Blue box spans IQR (Q1–Q3); ",
      "whiskers at P05 and P95. Tick marks at P10 and P90. ",
      "Days = TO − FROM (negative = TO before FROM). Four timing export variants shown."),
    children
  )
}

# ---------------------------------------------------------------------------
# Main: assemble and write report
# ---------------------------------------------------------------------------
build_report <- function(results_dir = RESULTS_DIR, output_path = OUTPUT_PATH) {
  cat(sprintf("Reading CSVs from: %s\n", results_dir))

  page <- tagList(
    tags$html(lang = "en",
      tags$head(
        tags$meta(charset = "utf-8"),
        tags$title("Data characterization summary"),
        tags$style(HTML(REPORT_CSS))
      ),
      tags$body(
        tags$h1("Data characterization summary"),
        tags$p(class = "meta",
          sprintf("Source: %s | Generated: %s",
                  results_dir, format(Sys.time(), "%Y-%m-%d %H:%M"))),
        section_legend(),
        section_prevalence(results_dir),
        section_demographics(results_dir),
        section_anchor_dx_counts(results_dir),
        section_deaths(results_dir),
        section_focus_timing(results_dir),
        section_timing_pairs(results_dir)
      )
    )
  )

  htmltools::save_html(page, file = output_path)
  cat(sprintf("Report written: %s\n", output_path))
  invisible(output_path)
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------
if (!interactive()) {
  build_report(results_dir = RESULTS_DIR, output_path = OUTPUT_PATH)
}
