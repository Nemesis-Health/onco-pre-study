# onco-pre-study

OMOP characterization scripts for urothelial carcinoma (UC) malignant neoplasm cohorts.
Produces population prevalence, event code counts, pairwise timing, and death metrics
across anchor families (DX, ODX, GDX, MET, L01).

## Repository layout

```
sql/
└── sql_server/
    ├── characterization_full.sql     # Complete monolithic query (SqlRender-ready)
    └── chunks/
        ├── 00_setup.sql              # Concept tables, event tables, cohort, summaries (no return)
        ├── 01_population_prevalence.sql
        ├── 02_event_code_counts.sql
        ├── 03_suppression_audit.sql
        ├── 03b_event_code_counts_before_after.sql
        ├── 04_timing_first_to_first.sql
        ├── 05_timing_first_to_closest.sql
        ├── 06_timing_first_to_closest_before.sql
        ├── 07_timing_first_to_closest_after.sql
        ├── 08_death_timing.sql
        ├── 09_demographics.sql
        └── 10_anchor_dx_codes.sql

scripts/
├── build_summary_html_report.R       # R report (OHDSI DatabaseConnector; recommended)
└── build_summary_html_report.py      # Python report (pandas + plotly)

outputs/                  # CSV results land here; summary_report.html is generated here
```

## Generating the report

Place the 11 characterization CSVs in `outputs/` (see [Result chunks](#result-chunks) for filenames), then run either script.

### R (recommended — OHDSI standard)

```r
install.packages(c("dplyr", "plotly", "htmltools"))
# optional — only needed to resolve OMOP concept names:
install.packages("DatabaseConnector")
```

```bash
# From repo root — reads outputs/*.csv, writes outputs/summary_report.html
Rscript scripts/build_summary_html_report.R

# Point at a different folder
Rscript scripts/build_summary_html_report.R --results-dir /path/to/csvs
```

To enable concept name lookup via DatabaseConnector, set env vars before running:

| Env var | Description |
|---------|-------------|
| `OMOP_DBMS` | `"sql server"`, `"postgresql"`, `"snowflake"`, `"sqlite"` |
| `OMOP_SERVER` | Server address |
| `OMOP_USER` | Username |
| `OMOP_PASSWORD` | Password |
| `OMOP_PORT` | Port (default 1433) |
| `OMOP_CDM_SCHEMA` | Schema containing the `concept` table (default `"cdm"`) |

If `OMOP_DBMS` is not set the report renders fully — concept IDs just won't be resolved to names.

### Python (alternative)

```bash
pip install pandas plotly
python scripts/build_summary_html_report.py
python scripts/build_summary_html_report.py --results-dir /path/to/csvs
```

## SQL dialect

The primary dialect is **SQL Server** (T-SQL) with [SqlRender](https://github.com/OHDSI/SqlRender)-style
parameters (`@cdm_database_schema`, `@min_cell_count`). Translations to other dialects
(Snowflake, PostgreSQL, etc.) are planned under `sql/<dialect>/`.

To render for a specific target database:
```r
library(SqlRender)
sql <- readSql("sql/sql_server/characterization_full.sql")
rendered <- render(sql, cdm_database_schema = "cdm", min_cell_count = 5)
translated <- translate(rendered, targetDialect = "postgresql")
```

## The characterization query

**Version:** v2 — dual concept-level event-code timing (FIRST + CLOSEST)

**Cohort anchor:** UC malignant neoplasm (UC.json concept set id 7), expanded via
`concept_ancestor`. Excludes renal pelvis / ureteral / overlapping-site concepts
per the exclusion list in section A.

**Event families tracked:**
| Label | Source table | Description |
|-------|-------------|-------------|
| DX | condition_occurrence | Anchor UC diagnosis concepts |
| ODX | condition_occurrence | Other malignant neoplasm diagnoses |
| GDX | condition_occurrence | Generalized cancer ancestors of DX |
| MET | measurement | Metastasis / AJCC stage 4 / M1 concepts |
| L01 | drug_exposure | L01 antineoplastic drugs (ingredient level) |

**Timing rules (both computed per run):**
- **FIRST** — earliest `event_date` per (anchor, family, concept, patient)
- **CLOSEST** — minimum `|days_diff|` to anchor date, tie-break by event_date

**Privacy:** small cells ≤ `@min_cell_count` are replaced with `-@min_cell_count` sentinels.

### Setup chunk (`00_setup.sql`)

Builds all temp tables (no result returned). Sections:

| Section | Tables created |
|---------|---------------|
| A | `#dx_anchor_include/exclude/concepts` |
| B | `#gen_cancer_concepts` |
| C | `#other_dx_concepts` |
| D | `#met_concepts` |
| E | `#l01_concepts` |
| F | Event tables: `#dx_events`, `#other_dx_events`, `#gen_cancer_events`, `#met_events`, `#l01_events`, `#l01_ingredient_events`, `#anchor_person` |
| G | Cohort + summaries: `#cohort`, `#dx_summary`, `#other_dx_summary`, `#gen_cancer_summary`, `#met_summary`, `#l01_summary` |
| H | Code counts + timing: `#event_code_counts`, `#event_code_counts_before_after`, `#event_code_timing_summary`, etc. |
| I | `#patient_char` (one row per patient) |
| J | `#patient_timing_pairs`, `#timing_pair_summary` (first-to-first and first-to-closest variants) |
| J-bis | Death timing: `#death_timing_long`, `#death_timing_quantiles`, `#death_stratum_counts` |

### Result chunks

| File | Result | Saved as |
|------|--------|---------|
| `01_population_prevalence.sql` | Cohort size + prevalence by family, by year | `final_population_prevalence.csv` |
| `02_event_code_counts.sql` | Per-concept counts + dual timing (FIRST/CLOSEST) | `final_event_code_counts.csv` |
| `03_suppression_audit.sql` | Count of suppressed concept rows per family | `final_event_code_counts_suppression_audit.csv` |
| `03b_event_code_counts_before_after.sql` | Counts split BEFORE / AFTER anchor date | `final_event_code_counts_before_after.csv` |
| `04_timing_first_to_first.sql` | Pairwise timing: first→first, full percentile range | `final_timing_pair_summary_first_to_first.csv` |
| `05_timing_first_to_closest.sql` | Pairwise timing: first→closest | `final_timing_pair_summary_first_to_closest.csv` |
| `06_timing_first_to_closest_before.sql` | Pairwise timing: first→closest before anchor | `final_timing_pair_summary_first_to_closest_before.csv` |
| `07_timing_first_to_closest_after.sql` | Pairwise timing: first→closest on/after anchor | `final_timing_pair_summary_first_to_closest_after.csv` |
| `08_death_timing.sql` | Death counts + day quantiles from INDEX & FIRST_MET, by year | `final_death_from_anchors.csv` |
| `09_demographics.sql` | Gender split + age quantiles at INDEX and FIRST_MET | `final_demographics_from_anchors.csv` |
| `10_anchor_dx_codes.sql` | Distinct patients and patient-days per DX concept_id | `final_anchor_dx_concept_counts.csv` |

## Planned additions

- `sql/snowflake/` — Snowflake-translated versions (SqlRender output)
- `sql/postgresql/` — PostgreSQL-translated versions
- A runner script targeting SQL Server directly (DatabaseConnector / pyodbc)
