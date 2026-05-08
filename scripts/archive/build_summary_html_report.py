from __future__ import annotations

import html
import math
import os
import re
import sys
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any, Literal

import pandas as pd
import plotly.graph_objects as go
from plotly.subplots import make_subplots

BASE_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE_DIR))


# ---------------------------------------------------------------------------
# Helpers (previously in build_quick_html_report.py)
# ---------------------------------------------------------------------------

def _find_column_case_insensitive(df: pd.DataFrame, target: str) -> str | None:
    target_lower = target.lower()
    for col in df.columns:
        if str(col).lower() == target_lower:
            return str(col)
    return None


def _infer_min_cell_from_sentinels(df: pd.DataFrame, cols: list[str | None]) -> int:
    """Infer small-cell threshold from negative sentinel values in the data."""
    env_raw = os.environ.get("MIN_CELL_COUNT")
    if env_raw is not None and env_raw.strip() != "":
        try:
            return max(0, int(env_raw))
        except ValueError:
            pass
    m = 0
    for col in cols:
        if not col or col not in df.columns:
            continue
        s = pd.to_numeric(df[col], errors="coerce")
        neg = s[s < 0]
        if not neg.empty:
            m = max(m, int((-neg).max()))
    return m


def _pct_cohort_rate(num: object, den: object, min_cell: int) -> Any:
    """Compute cohort rate %; return pd.NA for suppressed or missing values."""
    if den is None or (isinstance(den, float) and pd.isna(den)):
        return pd.NA
    if num is None or (isinstance(num, float) and pd.isna(num)):
        return pd.NA
    try:
        d = int(float(den))
        n = int(float(num))
    except (TypeError, ValueError):
        return pd.NA
    if d < 0 or d <= min_cell or n < 0:
        return pd.NA
    if n == 0:
        return 0.0
    return 100.0 * n / d


def _with_prevalence_pct_for_report(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty or any(str(c).upper().startswith("PCT_") for c in df.columns):
        return df
    y = _find_column_case_insensitive(df, "prevalence_year")
    ndx = _find_column_case_insensitive(df, "n_dx")
    if not ndx:
        return df
    pairs = [
        (_find_column_case_insensitive(df, "n_odx"), "PCT_ODX"),
        (_find_column_case_insensitive(df, "n_gdx"), "PCT_GDX"),
        (_find_column_case_insensitive(df, "n_met"), "PCT_MET"),
        (_find_column_case_insensitive(df, "n_l01"), "PCT_L01"),
    ]
    num_cols = [p[0] for p in pairs if p[0]]
    min_cell = _infer_min_cell_from_sentinels(df, [ndx] + num_cols)
    out = df.copy()
    ndx_num = pd.to_numeric(out[ndx], errors="coerce")

    def _pct_dx_cell(v: object) -> Any:
        if pd.isna(v):
            return pd.NA
        try:
            d = int(float(v))
        except (TypeError, ValueError):
            return pd.NA
        if d < 0:
            return pd.NA
        return 100.0 if d > min_cell else pd.NA

    out["PCT_DX"] = ndx_num.map(_pct_dx_cell)
    for ncol, pct_name in pairs:
        if not ncol:
            continue
        out[pct_name] = [
            _pct_cohort_rate(r[ncol], r[ndx], min_cell) for _, r in out.iterrows()
        ]
    year_first = [y] if y else []
    ordered = year_first + [ndx, "PCT_DX"]
    for ncol, pct_name in pairs:
        if ncol:
            ordered.extend([ncol, pct_name])
    rest = [c for c in out.columns if c not in ordered]
    return out[ordered + rest]


def _with_death_pct_for_report(df: pd.DataFrame) -> pd.DataFrame:
    if df.empty or _find_column_case_insensitive(df, "pct_deaths"):
        return df
    npat = _find_column_case_insensitive(df, "n_patients")
    ndeath = _find_column_case_insensitive(df, "n_deaths")
    if not npat or not ndeath:
        return df
    min_cell = _infer_min_cell_from_sentinels(df, [ndeath, npat])
    out = df.copy()
    out["PCT_DEATHS"] = [
        _pct_cohort_rate(r[ndeath], r[npat], min_cell) for _, r in out.iterrows()
    ]
    anchor = _find_column_case_insensitive(out, "anchor_event")
    year_col = _find_column_case_insensitive(out, "prevalence_year")
    head = [c for c in [year_col, anchor, npat, ndeath] if c]
    tail = [c for c in out.columns if c not in head and c != "PCT_DEATHS"]
    return out[head + ["PCT_DEATHS"] + tail]


def _qualified_cdm_table(table: str) -> str:
    from db_adapter import get_adapter  # noqa: PLC0415
    return get_adapter().qualified_table(table)


def _fetch_concept_name_map(concept_ids: list[int]) -> dict[int, str]:
    if not concept_ids:
        return {}
    try:
        from db_adapter import get_connection  # noqa: PLC0415
    except ImportError:
        return {}
    id_list = ", ".join(str(int(x)) for x in sorted(set(concept_ids)))
    qc = _qualified_cdm_table("concept")
    sql = f"SELECT concept_id, concept_name FROM {qc} WHERE concept_id IN ({id_list})"
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(sql)
        rows = cur.fetchall()
        return {int(r[0]): str(r[1]) for r in rows}
    finally:
        cur.close()
        conn.close()

RESULTS_DIR = BASE_DIR / "outputs"

def _round_day_int(v: object) -> int | None:
    """Nearest whole day for display (not ceiling)."""
    try:
        if pd.isna(v):
            return None
        x = float(v)
        if math.isnan(x):
            return None
        return int(round(x))
    except Exception:
        return None


def _day_label(v: object) -> str:
    """Whole-day label for hovers/tables; em dash when missing."""
    ri = _round_day_int(v)
    return "—" if ri is None else str(ri)


def _quantile_bin_density_bars(
    *,
    p05: float,
    p10: float,
    lq: float,
    med: float,
    uq: float,
    p90: float,
    p95: float,
) -> tuple[list[float], list[float], list[float], list[str], list[str]]:
    """
    Quantile-binned "histogram" as piecewise-uniform density between adjacent quantiles.
    Returns (x_centers_scaled, widths_scaled, densities_raw, bin_labels, bin_bounds_hover)
    where bin_bounds_hover entries are raw-day bounds for the hover text.
    """
    cuts = [p05, p10, lq, med, uq, p90, p95]
    probs = [0.05, 0.15, 0.25, 0.25, 0.15, 0.05]
    labels = [
        "P05–P10 (5%)",
        "P10–Q1 (15%)",
        "Q1–median (25%)",
        "median–Q3 (25%)",
        "Q3–P90 (15%)",
        "P90–P95 (5%)",
    ]
    if any(pd.isna(x) for x in cuts):
        return [], [], [], [], []

    xs: list[float] = []
    ws: list[float] = []
    ys: list[float] = []
    bounds: list[str] = []
    for (a, b), pr, _ in zip(zip(cuts[:-1], cuts[1:]), probs, labels):
        lo = float(min(a, b))
        hi = float(max(a, b))
        y, x, w = _quantile_histogram_bin_bar_metrics(lo, hi, pr)
        xs.append(x)
        ws.append(w)
        ys.append(y)
        bounds.append(f"{_day_label(lo)} – {_day_label(hi)} days")
    return xs, ws, ys, labels, bounds


def _decile_bin_density_bars(
    *,
    p05: float,
    p10: float,
    p20: float,
    p30: float,
    p40: float,
    p50: float,
    p60: float,
    p70: float,
    p80: float,
    p90: float,
    p95: float,
) -> tuple[list[float], list[float], list[float], list[str], list[str]]:
    """
    Piecewise-uniform density from P05 through P95, aligned with boxplot whiskers:
    P05–P10 and P90–P95 are 5% mass each; P10–P20 … P80–P90 are 10% each (10 bins, 100% between P05 and P95).
    Returns (x_centers_scaled, widths_scaled, densities_raw, bin_labels, bin_bounds_hover).
    """
    cuts = [p05, p10, p20, p30, p40, p50, p60, p70, p80, p90, p95]
    probs = [0.05, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.10, 0.05]
    if any(pd.isna(x) for x in cuts):
        return [], [], [], [], []
    labels = [
        "P05–P10 (5%)",
        "P10–P20 (10%)",
        "P20–P30 (10%)",
        "P30–P40 (10%)",
        "P40–P50 (10%)",
        "P50–P60 (10%)",
        "P60–P70 (10%)",
        "P70–P80 (10%)",
        "P80–P90 (10%)",
        "P90–P95 (5%)",
    ]
    xs: list[float] = []
    ws: list[float] = []
    ys: list[float] = []
    bounds: list[str] = []
    for (a, b), pr in zip(zip(cuts[:-1], cuts[1:]), probs):
        lo = float(min(a, b))
        hi = float(max(a, b))
        y, x, w = _quantile_histogram_bin_bar_metrics(lo, hi, pr)
        xs.append(x)
        ws.append(w)
        ys.append(y)
        bounds.append(f"{_day_label(lo)} – {_day_label(hi)} days")
    return xs, ws, ys, labels, bounds


_EVENT_DISPLAY_NAMES: dict[str, str] = {
    "DX":  "Cancer of interest",
    "MET": "Metastasis",
    "L01": "Antineoplastic treatment",
    "ODX": "Co-occurring other cancer DX",
    "GDX": "Broader/non-specific DX",
}

# Labels used on pairwise plot axes (compact codes).
_EVENT_PAIRWISE_LABELS: dict[str, str] = {
    "DX":  "DX",
    "MET": "MET",
    "ODX": "ODX",
    "GDX": "GDX",
    "L01": "L01",
}


def _event_display_name(code: object) -> str:
    key = str(code).strip().upper()
    return _EVENT_DISPLAY_NAMES.get(key, str(code))


def _event_pairwise_label(code: object) -> str:
    key = str(code).strip().upper()
    return _EVENT_PAIRWISE_LABELS.get(key, _EVENT_DISPLAY_NAMES.get(key, str(code)))


def _event_family_display_name(family: object) -> str:
    return _event_display_name(family)


def _legend_table_html() -> str:
    rows = [
        ("DX", "Cancer of interest concepts (the cohort's target cancer dx set)."),
        (
            "GDX",
            "Broader/non-specific DX concepts: ancestors of DX (broader codes), constrained to descendants of 443392 (Malignant neoplastic disease).",
        ),
        ("ODX", "Co-occurring other cancer DX concepts: malignancies excluding DX and GDX."),
        ("MET", "Metastasis occurrence."),
        ("L01", "Antineoplastic treatment (ATC L01 descendants; from drug_exposure)."),
        ("ANCHOR_EVENT = INDEX", "Anchored to first DX date."),
        ("ANCHOR_EVENT = FIRST_MET", "Anchored to first MET date."),
        ("time_window = before", "Event date occurs before the anchor date."),
        ("time_window = after", "Event date occurs on/after the anchor date."),
    ]
    body = "\n".join(
        f"<tr><td><code>{html.escape(k)}</code></td><td>{html.escape(v)}</td></tr>"
        for k, v in rows
    )
    return (
        "<table class='report-table'>"
        "<thead><tr><th>Label</th><th>Meaning</th></tr></thead>"
        f"<tbody>{body}</tbody></table>"
    )


def _plot_abbrev_note_html() -> str:
    return (
        "<p class='subtle'>Abbreviations: "
        "<code>DX</code> cancer of interest; "
        "<code>GDX</code> broader/non-specific DX (ancestors of DX within malignant neoplastic disease); "
        "<code>ODX</code> co-occurring other cancer DX; "
        "<code>MET</code> metastasis; "
        "<code>L01</code> antineoplastic treatment (ATC L01).</p>"
    )

TIMING_DAYS_SCALE: str = "symlog10"
"""
Timing-day x-axis scale.

- 'linear': raw days.
- 'signed_log10': plot signed log transform sign(x)*log10(1+|x|) so negative/positive
  days remain visible (since true log10 is undefined for <= 0).
- 'symlog10': symmetric log with a linear region around 0. This is usually best when IQR is
  tight but tails are huge. Controlled by `SYMLOG_LINTHRESH_DAYS`.
"""

# For symlog10: linear-ish region is [-linthresh, +linthresh] (in raw days).
SYMLOG_LINTHRESH_DAYS: float = 180.0

# When adjacent reported quantiles tie (e.g. P05=P10=0), bin width is zero and density ~ mass/ε
# explodes and bar width on the transformed axis vanishes. Use at least this many raw days for display.
MIN_EFFECTIVE_BIN_WIDTH_DAYS: float = 1.0


def _quantile_histogram_bin_bar_metrics(lo: float, hi: float, pr: float) -> tuple[float, float, float]:
    """
    Piecewise-uniform bin: probability pr over [lo, hi] (already ordered, lo <= hi).
    Returns (density, x_center_transformed, bar_width_transformed).
    Tied quantiles (hi <= lo): extend display interval to the right by MIN_EFFECTIVE_BIN_WIDTH_DAYS.
    """
    span = float(hi) - float(lo)
    if span <= 0:
        span_eff = float(MIN_EFFECTIVE_BIN_WIDTH_DAYS)
        hi_plot = float(lo) + span_eff
    else:
        span_eff = span
        hi_plot = float(hi)
    y = float(pr) / span_eff
    slo = _transform_days(float(lo))
    shi = _transform_days(hi_plot)
    x = 0.5 * (slo + shi)
    w = max(1e-9, abs(shi - slo))
    return y, x, w

# Raw-day tick anchors used when TIMING_DAYS_SCALE='signed_log10'.
# The axis is still transformed, but tick labels show these raw day values (both signs).
SIGNED_LOG10_TICK_DAYS: list[int] = [30, 60, 90, 180, 365, 730, 1460, 1920]

# Synthetic histogram (quantile-based pseudo-samples) shown in focus section.
SHOW_SYNTHETIC_HISTOGRAM_IN_FOCUS: bool = False
SYNTHETIC_HIST_SAMPLES: int = 4000
SYNTHETIC_HIST_NBINS: int = 60

# How many concepts to show in linked event-code-count tables.
EVENT_CODE_COUNTS_TOP_N: int = 5
PREVALENCE_YEAR_MIN: int = 2010

# Main anchor DX code rollup (`final_anchor_dx_concept_counts.csv`): rows in summary report.
ANCHOR_DX_COUNTS_TOP_N: int = 10
ANCHOR_DX_COUNTS_CSV: str = "final_anchor_dx_concept_counts.csv"

# Must match @event_code_timing_uses_closest in the characterization SQL (0 = FIRST, 1 = CLOSEST).
# Exports typically have a single median_days / lq / uq per row; that triple follows this rule only —
# not the "first vs closest" wording of the pairwise timing_pair_summary CSV used for the plot above.
# Override at runtime: env CHARACTERIZATION_EVENT_CODE_TIMING_USES_CLOSEST=1
EVENT_CODE_TIMING_USES_CLOSEST: bool = False

# Timing export variants available in output folder.
# Key -> (Display title, CSV filename, short label).
TIMING_VARIANTS: dict[str, tuple[str, str, str]] = {
    "first_to_first": (
        "First occurrence → first occurrence",
        "final_timing_pairwise.csv",
        "First→first",
    ),
    "first_to_closest": (
        "First occurrence → closest occurrence",
        "final_timing_pairwise.csv",
        "First→closest",
    ),
    "first_to_closest_before": (
        "First → closest (strictly before anchor)",
        "final_timing_pairwise.csv",
        "Before anchor",
    ),
    "first_to_closest_after": (
        "First → closest (on or after anchor)",
        "final_timing_pairwise.csv",
        "On/after anchor",
    ),
}

# Order used for the full "Timing pairs" section.
TIMING_VARIANTS_ORDER: list[str] = [
    "first_to_first",
    "first_to_closest",
    "first_to_closest_before",
    "first_to_closest_after",
]

# ---------------------------------------------------------------------------
# Focus section: timing pairs to plot (edit this list only).
#
# Each entry is one plot + one linked "Event code counts" appendix block.
#   from, to   — FROM_EVENT / TO_EVENT in the timing_pair_summary CSVs.
#   timing     — key into TIMING_VARIANTS (selects which timing CSV + quantiles).
#   ecc        — optional dict overriding the default link to event_code_counts:
#                  export: "all" | "before" | "after"
#                  column_family: "FIRST" | "CLOSEST"
#                  anchor: "INDEX" | "FIRST_MET" (default: from FROM — DX→INDEX, MET→FIRST_MET)
#   commentary — optional plain text shown under the pair heading (how to read the pair, caveats).
#                Newlines preserved; HTML is escaped (no tags).
#
# Default ecc (when ``ecc`` omitted) is _ecc_link_spec_default_for_timing(timing): picks time_window +
# column_family to align with the pairwise plot. ``column_family`` only matters if the CSV has
# separate *_FIRST / *_CLOSEST columns; otherwise medians come from the single triple governed by
# EVENT_CODE_TIMING_USES_CLOSEST / @event_code_timing_uses_closest.
# ---------------------------------------------------------------------------
FOCUS_TIMING_PLOTS: list[dict[str, Any]] = [
    {
        "from": "DX",
        "to": "MET",
        "timing": "first_to_first",
        "commentary": "First DX to first MET; days positive = MET after DX.",
    },
    {
        "from": "MET",
        "to": "DX",
        "timing": "first_to_closest",
        "reverse": True,
        "x_range": (-90, 90),
        "commentary": "Closest DX to first MET anchor (reversed to read DX → MET); zoomed to ±30 days.",
    },
    {
        "from": "MET",
        "to": "ODX",
        "timing": "first_to_closest",
        "reverse": True,
        "x_range": (-90, 90),
        "commentary": "Closest other-DX to first MET anchor (reversed to read ODX → MET); zoomed to ±30 days.",
    },
    {
        "from": "MET",
        "to": "L01",
        "timing": "first_to_first",
        "commentary": "First MET to first L01; days positive = L01 after MET.",
    },
    {
        "from": "MET",
        "to": "L01",
        "timing": "first_to_closest_after",
        "x_range": (0, 365),
        "commentary": "First MET to closest L01 on or after MET; zoomed to 0–365 days.",
    },
]

_PREV_COLS = (
    ("Cancer of interest (DX)",            "n_dx",  "PCT_DX"),
    ("Metastasis (MET)",                    "n_met", "PCT_MET"),
    ("Antineoplastic treatment (L01)",      "n_l01", "PCT_L01"),
    ("Co-occurring other cancer DX (ODX)", "n_odx", "PCT_ODX"),
    ("Broader/non-specific DX (GDX)",      "n_gdx", "PCT_GDX"),
)


def _resolve_col(df: pd.DataFrame, logical: str) -> str | None:
    return _find_column_case_insensitive(df, logical)


def _fmt_n_pct(n: object, pct: object) -> str:
    if n is None or (isinstance(n, float) and pd.isna(n)):
        return "—"
    try:
        ni = int(float(n))
    except (TypeError, ValueError):
        return "—"
    if ni < 0:
        return "—"
    if pct is None or (isinstance(pct, float) and pd.isna(pct)):
        return f"{ni:,}"
    try:
        p = float(pct)
    except (TypeError, ValueError):
        return f"{ni:,}"
    if pd.isna(p):
        return f"{ni:,}"
    return f"{ni:,} ({p:.1f}%)"


def _overall_summary_rows(overall: pd.DataFrame) -> pd.DataFrame:
    """One row per OVERALL record (e.g. per anchor), columns DX … GDX as N (%)."""
    rows_out: list[dict[str, Any]] = []
    anchor_col = _resolve_col(overall, "anchor_event")
    for _, row in overall.iterrows():
        out: dict[str, Any] = {}
        if anchor_col:
            out["Anchor"] = str(row[anchor_col])
        for label, n_key, pct_key in _PREV_COLS:
            nc = _resolve_col(overall, n_key)
            pc = _resolve_col(overall, pct_key.lower())
            if not nc:
                out[label] = "—"
                continue
            n_val = row[nc]
            p_val = row[pc] if pc else None
            out[label] = _fmt_n_pct(n_val, p_val)
        rows_out.append(out)
    col_order = (["Anchor"] if anchor_col else []) + [p[0] for p in _PREV_COLS]
    return pd.DataFrame(rows_out)[col_order]


def _yearly_prevalence_figure(yearly: pd.DataFrame) -> go.Figure | None:
    if yearly.empty:
        return None
    yc = _resolve_col(yearly, "prevalence_year")
    ndx = _resolve_col(yearly, "n_dx")
    if not yc or not ndx:
        return None
    sub = yearly.copy()
    sub["__y"] = pd.to_numeric(sub[yc].astype(str), errors="coerce")
    sub = sub.dropna(subset=["__y"]).sort_values("__y")
    years = sub["__y"].astype(int)
    n_dx = pd.to_numeric(sub[ndx], errors="coerce")

    pct_met_col = _resolve_col(sub, "PCT_MET")
    pct_l01_col = _resolve_col(sub, "PCT_L01")
    pct_odx_col = _resolve_col(sub, "PCT_ODX")
    if pct_met_col is None:
        pct_met_col = "PCT_MET" if "PCT_MET" in sub.columns else None
    if pct_l01_col is None:
        pct_l01_col = "PCT_L01" if "PCT_L01" in sub.columns else None
    if pct_odx_col is None:
        pct_odx_col = "PCT_ODX" if "PCT_ODX" in sub.columns else None

    pct_met = pd.to_numeric(sub[pct_met_col], errors="coerce") if pct_met_col else None
    pct_l01 = pd.to_numeric(sub[pct_l01_col], errors="coerce") if pct_l01_col else None
    pct_odx = pd.to_numeric(sub[pct_odx_col], errors="coerce") if pct_odx_col else None

    fig = go.Figure()
    fig.add_trace(
        go.Bar(
            x=years,
            y=n_dx,
            name=f"N (Cancer of interest cohort) (DX)",
            marker_color="#1d4ed8",
            opacity=0.85,
        )
    )
    if pct_met is not None:
        fig.add_trace(
            go.Scatter(
                x=years,
                y=pct_met,
                name="% with Metastasis (MET)",
                mode="lines+markers",
                yaxis="y2",
                line=dict(color="#d97706", width=2.2),
                marker=dict(size=7, color="#d97706", line=dict(width=0)),
                hovertemplate="Year %{x}<br>% Metastasis %{y:.1f}%<extra></extra>",
            )
        )
    if pct_l01 is not None:
        fig.add_trace(
            go.Scatter(
                x=years,
                y=pct_l01,
                name="% with Antineoplastic treatment (L01)",
                mode="lines+markers",
                yaxis="y2",
                line=dict(color="#16a34a", width=2.2, dash="dot"),
                marker=dict(size=7, color="#16a34a", line=dict(width=0)),
                hovertemplate="Year %{x}<br>% Antineoplastic treatment %{y:.1f}%<extra></extra>",
            )
        )
    if pct_odx is not None:
        fig.add_trace(
            go.Scatter(
                x=years,
                y=pct_odx,
                name="% with Co-occurring other cancer DX (ODX)",
                mode="lines+markers",
                yaxis="y2",
                line=dict(color="#7c3aed", width=2.2, dash="dash"),
                marker=dict(size=7, color="#7c3aed", line=dict(width=0), symbol="diamond"),
                hovertemplate="Year %{x}<br>% Co-occurring other cancer DX %{y:.1f}%<extra></extra>",
            )
        )

    fig.update_layout(
        template="plotly_white",
        margin=dict(l=48, r=56, t=40, b=48),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        yaxis=dict(title="Patients (N)", gridcolor="#e5e7eb"),
        yaxis2=dict(
            title="Share of cohort (%)",
            overlaying="y",
            side="right",
            showgrid=False,
            rangemode="tozero",
        ),
        xaxis=dict(
            title="Calendar year",
            dtick=1,
            range=[PREVALENCE_YEAR_MIN - 0.5, int(years.max()) + 0.5],
        ),
        hovermode="x unified",
        height=420,
    )
    return fig


def _fig_to_div(fig: go.Figure, *, include_plotlyjs: bool) -> str:
    return fig.to_html(
        include_plotlyjs="cdn" if include_plotlyjs else False,
        full_html=False,
        config={"displayModeBar": False, "responsive": True},
    )

def _signed_log10_days(v: float) -> float:
    # sign(x) * log10(1+|x|) keeps 0 -> 0 and supports negatives.
    if pd.isna(v):
        return v
    x = float(v)
    if x == 0:
        return 0.0
    import math

    return (1.0 if x > 0 else -1.0) * math.log10(1.0 + abs(x))


def _symlog10_days(v: float, linthresh: float) -> float:
    """
    Symmetric log with a linear region around 0 (symlog).

    For |x| <= linthresh: f(x) = x / linthresh
    For |x| >  linthresh: f(x) = sign(x) * (1 + log10(|x|/linthresh))

    This keeps small values readable while compressing large tails.
    """
    if pd.isna(v):
        return v
    x = float(v)
    t = float(linthresh) if linthresh and linthresh > 0 else 1.0
    ax = abs(x)
    if ax <= t:
        return x / t
    import math

    return (1.0 if x > 0 else -1.0) * (1.0 + math.log10(ax / t))


def _transform_days(v: float) -> float:
    if TIMING_DAYS_SCALE == "linear":
        return v
    if TIMING_DAYS_SCALE == "signed_log10":
        return _signed_log10_days(v)
    if TIMING_DAYS_SCALE == "symlog10":
        return _symlog10_days(v, SYMLOG_LINTHRESH_DAYS)
    return v


def _scale_days_series(s: pd.Series, scale: str) -> pd.Series:
    if scale == "linear":
        return s
    if scale == "signed_log10":
        return s.map(_signed_log10_days)
    if scale == "symlog10":
        return s.map(lambda x: _symlog10_days(x, SYMLOG_LINTHRESH_DAYS))
    return s


def _scaled_ticks(max_abs_days: float) -> tuple[list[float], list[str]]:
    """
    Create symmetric tick positions for transformed timing axes, but label them as raw days.

    We use a small configurable set of anchors to keep the axis readable.
    """
    if not (max_abs_days and max_abs_days > 0) or pd.isna(max_abs_days):
        raw = []
    else:
        lim = float(max_abs_days)
        raw = [float(v) for v in SIGNED_LOG10_TICK_DAYS if float(v) <= lim]

    raw_ticks = [-v for v in reversed(raw)] + [0.0] + raw
    tickvals = [_transform_days(v) for v in raw_ticks]
    ticktext = [f"{int(v):d}" for v in raw_ticks]
    return tickvals, ticktext


def _apply_signed_log10_axis_ticks(fig: go.Figure, *, raw_values: pd.Series, axis: str) -> None:
    vals = pd.to_numeric(raw_values, errors="coerce")
    max_abs = float(vals.abs().max()) if not vals.empty else 0.0
    tickvals, ticktext = _scaled_ticks(max_abs)
    if axis == "x":
        fig.update_xaxes(tickmode="array", tickvals=tickvals, ticktext=ticktext)
    elif axis == "x2":
        fig.update_xaxes(tickmode="array", tickvals=tickvals, ticktext=ticktext, xaxis="x2")


def _synthetic_samples_from_quantiles(
    *,
    p05: float,
    p10: float,
    lq: float,
    med: float,
    uq: float,
    p90: float,
    p95: float,
    n: int,
    seed: int,
) -> list[float]:
    """
    Build pseudo-samples consistent with the reported quantiles by sampling uniformly within
    each interval between adjacent quantiles.

    Mass allocation (by definition): [P05,P10]=5%, [P10,LQ]=15%, [LQ,MED]=25%, [MED,UQ]=25%,
    [UQ,P90]=15%, [P90,P95]=5%. Tails outside P05/P95 are not modeled.
    """
    import random

    if n <= 0:
        return []
    rng = random.Random(int(seed) & 0xFFFFFFFF)
    cuts = [p05, p10, lq, med, uq, p90, p95]
    probs = [0.05, 0.15, 0.25, 0.25, 0.15, 0.05]
    out: list[float] = []
    # Defensive: if any cuts are NaN, bail.
    if any(pd.isna(x) for x in cuts):
        return out
    for (a, b), pr in zip(zip(cuts[:-1], cuts[1:]), probs):
        k = int(round(n * pr))
        if k <= 0:
            continue
        lo = float(min(a, b))
        hi = float(max(a, b))
        if lo == hi:
            out.extend([lo] * k)
        else:
            out.extend([lo + (hi - lo) * rng.random() for _ in range(k)])
    # Adjust to exact n with median-point padding if rounding drift.
    while len(out) < n:
        out.append(float(med))
    if len(out) > n:
        out = out[:n]
    return out


def _timing_pair_focus_hist_figure(
    rd: Path, from_ev: str, to_ev: str, variant_keys: list[str]
) -> go.Figure | None:
    """
    Synthetic histogram view for a focus pair, using quantile-based pseudo-samples.
    Panels match the chosen timing variants and share the x scale.
    """
    if not SHOW_SYNTHETIC_HISTOGRAM_IN_FOCUS:
        return None
    pair_label = f"{_event_pairwise_label(from_ev)} → {_event_pairwise_label(to_ev)}"
    chosen = [(k, TIMING_VARIANTS[k]) for k in variant_keys if k in TIMING_VARIANTS]
    if not chosen:
        return None

    fig = make_subplots(
        rows=1,
        cols=len(chosen),
        subplot_titles=[short for _, (_, _, short) in chosen],
        horizontal_spacing=0.07,
        shared_xaxes=True,
    )
    any_data = False
    raw_for_ticks: list[float] = []

    for j, (key, (_, fname, _short)) in enumerate(chosen, start=1):
        path = rd / fname
        if not path.exists():
            fig.add_annotation(
                text="File not found",
                row=1,
                col=j,
                showarrow=False,
                font=dict(size=12, color="#9ca3af"),
            )
            continue
        df = pd.read_csv(path)
        # Filter to the correct timing_type stratum in the consolidated CSV.
        _ttc = _resolve_col(df, "timing_type")
        if _ttc:
            df = df[df[_ttc].astype(str).str.lower().eq(key.lower())].copy()
        from_c = _resolve_col(df, "from_event")
        to_c = _resolve_col(df, "to_event")
        qcols = {
            "p05": _resolve_col(df, "p05_days"),
            "p10": _resolve_col(df, "p10_days"),
            "lq": _resolve_col(df, "lq_days"),
            "med": _resolve_col(df, "median_days"),
            "uq": _resolve_col(df, "uq_days"),
            "p90": _resolve_col(df, "p90_days"),
            "p95": _resolve_col(df, "p95_days"),
        }
        if not from_c or not to_c or any(v is None for v in qcols.values()):
            fig.add_annotation(
                text="Missing columns",
                row=1,
                col=j,
                showarrow=False,
                font=dict(size=12, color="#9ca3af"),
            )
            continue
        sel = df[
            df[from_c].astype(str).str.upper().eq(from_ev.upper())
            & df[to_c].astype(str).str.upper().eq(to_ev.upper())
        ]
        if sel.empty:
            fig.add_annotation(
                text="No row for this pair",
                row=1,
                col=j,
                showarrow=False,
                font=dict(size=12, color="#9ca3af"),
            )
            continue
        row = sel.iloc[0]
        any_data = True

        def _num(c: str) -> float:
            v = row[c]
            if pd.isna(v):
                return float("nan")
            return float(v)

        p05 = _num(qcols["p05"])
        p10 = _num(qcols["p10"])
        lq = _num(qcols["lq"])
        med = _num(qcols["med"])
        uq = _num(qcols["uq"])
        p90 = _num(qcols["p90"])
        p95 = _num(qcols["p95"])
        raw_for_ticks.extend([p05, p10, lq, med, uq, p90, p95])

        samples = _synthetic_samples_from_quantiles(
            p05=p05,
            p10=p10,
            lq=lq,
            med=med,
            uq=uq,
            p90=p90,
            p95=p95,
            n=int(SYNTHETIC_HIST_SAMPLES),
            seed=hash((from_ev, to_ev, key)) & 0xFFFFFFFF,
        )
        if TIMING_DAYS_SCALE == "signed_log10":
            xs = [_signed_log10_days(x) for x in samples]
            qx = [_signed_log10_days(x) for x in [p05, p10, lq, med, uq, p90, p95]]
        else:
            xs = samples
            qx = [p05, p10, lq, med, uq, p90, p95]

        fig.add_trace(
            go.Histogram(
                x=xs,
                nbinsx=int(SYNTHETIC_HIST_NBINS),
                name="Synthetic histogram",
                marker_color="rgba(37, 99, 235, 0.35)",
                marker_line=dict(color="rgba(29, 78, 216, 0.5)", width=1),
                showlegend=(j == 1),
                hovertemplate="x=%{x}<br>count=%{y}<extra></extra>",
            ),
            row=1,
            col=j,
        )

        # Quantile markers (subtle vertical lines).
        names = ["P05", "P10", "LQ", "MED", "UQ", "P90", "P95"]
        colors = ["#cbd5e1", "#94a3b8", "#64748b", "#111827", "#64748b", "#94a3b8", "#cbd5e1"]
        for name, x0, colr in zip(names, qx, colors):
            fig.add_trace(
                go.Scatter(
                    x=[x0, x0],
                    y=[0, 1],
                    mode="lines",
                    name=name,
                    showlegend=False,
                    line=dict(color=colr, width=1.4),
                    hovertemplate=f"{pair_label}<br>{name} = {x0:.3f}<extra></extra>",
                ),
                row=1,
                col=j,
            )

        fig.update_yaxes(title_text="Count", row=1, col=j)

    if not any_data:
        return None

    fig.update_layout(
        template="plotly_white",
        height=420,
        margin=dict(l=12, r=20, t=72, b=56),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        barmode="overlay",
    )
    fig.update_xaxes(title_text="Days (TO − FROM)", row=1, col=len(chosen))
    if TIMING_DAYS_SCALE == "signed_log10":
        raw_all = pd.Series(raw_for_ticks)
        tickvals, ticktext = _signed_log10_ticks(float(pd.to_numeric(raw_all, errors="coerce").abs().max()))
        fig.update_xaxes(tickmode="array", tickvals=tickvals, ticktext=ticktext)
    return fig


def _overall_from_event_denominators(rd: Path) -> dict[str, int]:
    """
    Map event-family label -> OVERALL patient count from final_population_prevalence.csv.
    Returns only non-suppressed non-negative counts.
    """
    path = rd / "final_population_prevalence.csv"
    if not path.exists():
        return {}
    df = pd.read_csv(path)
    y = _resolve_col(df, "prevalence_year")
    if not y:
        return {}
    overall = df[df[y].astype(str).str.upper().eq("OVERALL")]
    if overall.empty:
        return {}
    row = overall.iloc[0]
    out: dict[str, int] = {}
    mapping = {
        "DX": _resolve_col(df, "n_dx"),
        "MET": _resolve_col(df, "n_met"),
        "L01": _resolve_col(df, "n_l01"),
        "ODX": _resolve_col(df, "n_odx"),
        "GDX": _resolve_col(df, "n_gdx"),
    }
    for k, col in mapping.items():
        if not col or col not in row.index:
            continue
        try:
            v = int(float(row[col]))
        except (TypeError, ValueError):
            continue
        if v >= 0:
            out[k] = v
    return out


def _fmt_n_pct_from_den(n: object, den: object) -> str:
    """
    Format as N (pct%) where pct = N/den. If either missing, fallback to N.
    Negative N treated as suppressed.
    """
    if n is None or (isinstance(n, float) and pd.isna(n)):
        return "—"
    try:
        ni = int(float(n))
    except (TypeError, ValueError):
        return "—"
    if ni < 0:
        return "—"
    if den is None or (isinstance(den, float) and pd.isna(den)):
        return f"{ni:,}"
    try:
        di = int(float(den))
    except (TypeError, ValueError):
        return f"{ni:,}"
    if di <= 0:
        return f"{ni:,}"
    pct = 100.0 * ni / di
    return f"{ni:,} ({pct:.1f}%)"


_TIMING_VARIANT_LEGACY_FILES: dict[str, str] = {
    "first_to_first":          "final_timing_pair_summary_first_to_first.csv",
    "first_to_closest":        "final_timing_pair_summary_first_to_closest.csv",
    "first_to_closest_before": "final_timing_pair_summary_first_to_closest_before.csv",
    "first_to_closest_after":  "final_timing_pair_summary_first_to_closest_after.csv",
}


def _read_timing_variant_df(
    rd: Path, key: str, consolidated_fname: str
) -> tuple[pd.DataFrame | None, str | None]:
    """
    Load the timing-pair DataFrame for `key`, trying the consolidated file first.

    Returns (df, None) on success, (None, error_message) when no file is found.
    The returned df always has a `timing_type` column equal to `key` for the
    legacy single-variant files (which never had that column).
    """
    consolidated = rd / consolidated_fname
    if consolidated.exists():
        df = pd.read_csv(consolidated)
        ttc = _resolve_col(df, "timing_type")
        if ttc:
            df = df[df[ttc].astype(str).str.lower().eq(key.lower())].copy()
        return df, None
    legacy_fname = _TIMING_VARIANT_LEGACY_FILES.get(key)
    if legacy_fname:
        legacy = rd / legacy_fname
        if legacy.exists():
            df = pd.read_csv(legacy)
            if _resolve_col(df, "timing_type") is None:
                df.insert(0, "timing_type", key)
            return df, None
    return None, consolidated_fname


def _timing_pair_csv_quantile_cols(df: pd.DataFrame) -> dict[str, str | None]:
    """
    Column names for timing-pair summary CSVs.

    Newer exports use p25_days / p50_days / p75_days; older ones use lq_days / median_days / uq_days.
    Decile columns p20_days … p80_days are optional (used for P05–P95 histogram bins with interior deciles).
    """
    return {
        "p05": _resolve_col(df, "p05_days"),
        "p10": _resolve_col(df, "p10_days"),
        "p20": _resolve_col(df, "p20_days"),
        "p30": _resolve_col(df, "p30_days"),
        "p40": _resolve_col(df, "p40_days"),
        "p50": _resolve_col(df, "p50_days"),
        "p60": _resolve_col(df, "p60_days"),
        "p70": _resolve_col(df, "p70_days"),
        "p80": _resolve_col(df, "p80_days"),
        "p90": _resolve_col(df, "p90_days"),
        "p95": _resolve_col(df, "p95_days"),
        "lq": _resolve_col(df, "lq_days") or _resolve_col(df, "p25_days"),
        "med": _resolve_col(df, "median_days") or _resolve_col(df, "p50_days"),
        "uq": _resolve_col(df, "uq_days") or _resolve_col(df, "p75_days"),
    }


def _timing_pair_summary_row_html(
    *,
    from_ev: str,
    to_ev: str,
    n_from: int | None,
    n_pair: object,
    median_iqr: str | None = None,
) -> str:
    row = {
        "FROM": _event_display_name(from_ev),
        "N FROM": "—" if n_from is None else f"{int(n_from):,}",
        "TO": _event_display_name(to_ev),
        "N TO (%)": _fmt_n_pct_from_den(n_pair, n_from),
        "MEDIAN (IQR)": "—" if not median_iqr else median_iqr,
    }
    df = pd.DataFrame([row])
    tbl = df.to_html(index=False, border=0, classes="report-table")
    return tbl.replace('class="dataframe report-table"', 'class="report-table"', 1)


def _timing_pair_single_row_plot(
    df: pd.DataFrame,
    *,
    from_ev: str,
    to_ev: str,
    plot_mode: str = "hist",
    reverse: bool = False,
    x_range: tuple[float, float] | None = None,
) -> go.Figure | None:
    """
    Build a single-row timing visualization for a specific FROM→TO pair.

    plot_mode:
    - 'box': boxplot only
    - 'hist': quantile-binned density (P05–P95: tail bins 5%, decile bins 10%) when p20…p80 exist; else legacy IQR bins
    - 'both': histogram + boxplot
    """
    if df.empty:
        return None
    from_c = _resolve_col(df, "from_event")
    to_c = _resolve_col(df, "to_event")
    cols = _timing_pair_csv_quantile_cols(df)
    need_always = ("p05", "p10", "lq", "med", "uq", "p90", "p95")
    if not from_c or not to_c or any(cols[k] is None for k in need_always):
        return None
    sel = df[
        df[from_c].astype(str).str.upper().eq(from_ev.upper())
        & df[to_c].astype(str).str.upper().eq(to_ev.upper())
    ]
    if sel.empty:
        return None
    row = sel.iloc[0]

    def _num(c: str) -> float:
        v = row[c]
        if pd.isna(v):
            return float("nan")
        return float(v)

    p05 = _num(cols["p05"])
    p10 = _num(cols["p10"])
    lq = _num(cols["lq"])
    med = _num(cols["med"])
    uq = _num(cols["uq"])
    p90 = _num(cols["p90"])
    p95 = _num(cols["p95"])

    if reverse:
        p05, p10, lq, med, uq, p90, p95 = -p95, -p90, -uq, -med, -lq, -p10, -p05

    # transformed x positions
    p05s = _transform_days(p05)
    p10s = _transform_days(p10)
    lqs = _transform_days(lq)
    meds = _transform_days(med)
    uqs = _transform_days(uq)
    p90s = _transform_days(p90)
    p95s = _transform_days(p95)

    n_c = _resolve_col(df, "n_patients_with_pair")
    customdata = None
    if n_c and n_c in row.index and pd.notna(row[n_c]):
        customdata = [[int(float(row[n_c]))]]

    pair_label = (
        f"{_event_pairwise_label(to_ev)} → {_event_pairwise_label(from_ev)}"
        if reverse
        else f"{_event_pairwise_label(from_ev)} → {_event_pairwise_label(to_ev)}"
    )
    mode = str(plot_mode or "hist").strip().lower()
    if mode not in ("box", "hist", "both"):
        mode = "hist"
    want_box = mode in ("box", "both")
    want_hist = mode in ("hist", "both")
    use_subplots = want_box and want_hist
    hlabels: list[str] | None = None
    hbounds: list[str] | None = None

    if use_subplots:
        fig = make_subplots(
            rows=2,
            cols=1,
            shared_xaxes=True,
            vertical_spacing=0.10,
            row_heights=[0.62, 0.38],
        )
    else:
        fig = go.Figure()

    def _add_trace(t: go.BaseTraceType, *, row: int | None = None, col: int | None = None) -> None:
        if use_subplots and row is not None and col is not None:
            fig.add_trace(t, row=row, col=col)
        else:
            fig.add_trace(t)

    if want_hist:
        decile_keys = ("p10", "p20", "p30", "p40", "p50", "p60", "p70", "p80", "p90")
        if all(cols[k] is not None for k in decile_keys):
            dvs = {k: _num(cols[k]) for k in decile_keys}
            hx, hw, hy, hlabels, hbounds = _decile_bin_density_bars(
                p05=p05,
                p10=dvs["p10"],
                p20=dvs["p20"],
                p30=dvs["p30"],
                p40=dvs["p40"],
                p50=dvs["p50"],
                p60=dvs["p60"],
                p70=dvs["p70"],
                p80=dvs["p80"],
                p90=dvs["p90"],
                p95=p95,
            )
        else:
            hx, hw, hy, hlabels, hbounds = _quantile_bin_density_bars(
                p05=p05, p10=p10, lq=lq, med=med, uq=uq, p90=p90, p95=p95
            )
        if hx:
            _add_trace(
                go.Bar(
                    x=hx,
                    y=hy,
                    width=hw,
                    marker_color="rgba(29, 78, 216, 0.25)",
                    marker_line=dict(color="rgba(29, 78, 216, 0.55)", width=1),
                    hovertemplate=(
                        "<b>%{customdata[0]}</b><br>%{customdata[1]}<br>Density=%{y:.4f}<extra></extra>"
                        if hlabels and hbounds
                        else "Density=%{y:.4f}<extra></extra>"
                    ),
                    customdata=list(zip(hlabels, hbounds)) if hlabels and hbounds else None,
                    showlegend=False,
                ),
                row=(2 if use_subplots else None),
                col=(1 if use_subplots else None),
            )
            if meds is not None:
                fig.add_vline(
                    x=meds,
                    line=dict(color="red", width=1.5, dash="dot"),
                    row=(2 if use_subplots else "all"),
                    col=(1 if use_subplots else "all"),
                )

    if want_box:
        _add_trace(
            go.Box(
            orientation="h",
            y=[pair_label],
            q1=[lqs],
            median=[meds],
            q3=[uqs],
            lowerfence=[p05s],
            upperfence=[p95s],
            name="IQR + whiskers (P05–P95)",
            fillcolor="rgba(37, 99, 235, 0.35)",
            line=dict(color="#1d4ed8", width=1.2),
            whiskerwidth=0.65,
            marker=dict(outliercolor="rgba(0,0,0,0)", opacity=0),
            customdata=customdata,
            meta=[
                [
                    _day_label(p05),
                    _day_label(p10),
                    _day_label(lq),
                    _day_label(med),
                    _day_label(uq),
                    _day_label(p90),
                    _day_label(p95),
                ]
            ],
            hovertemplate=(
                "%{y}"
                "<br>Median (IQR): %{meta[3]} (%{meta[2]}–%{meta[4]}) days"
                "<br>P10–P90: %{meta[1]}–%{meta[5]} days"
                + ("<br>n: %{customdata[0]}" if customdata else "")
                + "<extra></extra>"
            ),
            showlegend=False,
            ),
            row=(1 if use_subplots else None),
            col=(1 if use_subplots else None),
        )
        _add_trace(
            go.Scatter(
                x=[p10s],
                y=[pair_label],
                mode="markers",
                name="P10",
                customdata=[_day_label(p10)],
                marker=dict(
                    symbol="line-ns",
                    size=12,
                    line=dict(width=1.6, color="#78716c"),
                    opacity=0.75,
                ),
                hovertemplate="<b>%{y}</b><br>P10: <b>%{customdata}</b> days<extra></extra>",
                showlegend=False,
            ),
            row=(1 if use_subplots else None),
            col=(1 if use_subplots else None),
        )
        _add_trace(
            go.Scatter(
                x=[p90s],
                y=[pair_label],
                mode="markers",
                name="P90",
                customdata=[_day_label(p90)],
                marker=dict(
                    symbol="line-ns",
                    size=12,
                    line=dict(width=1.6, color="#a8a29e"),
                    opacity=0.75,
                ),
                hovertemplate="<b>%{y}</b><br>P90: <b>%{customdata}</b> days<extra></extra>",
                showlegend=False,
            ),
            row=(1 if use_subplots else None),
            col=(1 if use_subplots else None),
        )

    # Do NOT add extra vertical "decision lines" (median/UQ/etc). The boxplot already encodes these.

    fig.update_layout(
        template="plotly_white",
        height=(340 if use_subplots else 280),
        margin=dict(l=12, r=20, t=10, b=56),
        xaxis=dict(
            title="Days",
            zeroline=True,
            zerolinewidth=1,
            zerolinecolor="#cbd5e1",
            gridcolor="#e5e7eb",
        ),
        yaxis=dict(title="", automargin=True),
        hovermode="closest",
    )
    if use_subplots:
        fig.update_yaxes(title_text="", row=1, col=1)
        fig.update_yaxes(title_text="Density (approx)", row=2, col=1, gridcolor="#e5e7eb")
    elif want_hist and not want_box:
        fig.update_yaxes(title_text="Density (approx)", gridcolor="#e5e7eb")
    if TIMING_DAYS_SCALE in ("signed_log10", "symlog10"):
        raw_list = [p05, p10, lq, med, uq, p90, p95]
        if want_hist and hlabels and hbounds:
            raw_list.extend(
                [_num(cols[k]) for k in ("p20", "p30", "p40", "p50", "p60", "p70", "p80") if cols.get(k)]
            )
        raw_all = pd.Series(raw_list)
        tickvals, ticktext = _scaled_ticks(float(pd.to_numeric(raw_all, errors="coerce").abs().max()))
        fig.update_xaxes(tickmode="array", tickvals=tickvals, ticktext=ticktext)
    if x_range is not None:
        x0 = _transform_days(float(x_range[0]))
        x1 = _transform_days(float(x_range[1]))
        fig.update_xaxes(range=[x0, x1])
    return fig


def _timing_pairs_figure(df: pd.DataFrame) -> go.Figure | None:
    """
    Horizontal distribution summary per FROM→TO pair: IQR + whiskers (P05–P95) via Plotly Box,
    plus small P10 / P90 markers so all seven reported quantiles are visible.
    """
    if df.empty:
        return None
    from_c = _resolve_col(df, "from_event")
    to_c = _resolve_col(df, "to_event")
    cols = _timing_pair_csv_quantile_cols(df)
    need_always = ("p05", "p10", "lq", "med", "uq", "p90", "p95")
    if not from_c or not to_c or any(cols[k] is None for k in need_always):
        return None

    sub = df.copy()
    sub["__pair"] = (
        sub[from_c].astype(str).apply(_event_pairwise_label)
        + " → "
        + sub[to_c].astype(str).apply(_event_pairwise_label)
    )
    sub = sub.sort_values(["__pair"]).reset_index(drop=True)
    labels = sub["__pair"].tolist()

    p05 = pd.to_numeric(sub[cols["p05"]], errors="coerce")
    p10 = pd.to_numeric(sub[cols["p10"]], errors="coerce")
    lq = pd.to_numeric(sub[cols["lq"]], errors="coerce")
    med = pd.to_numeric(sub[cols["med"]], errors="coerce")
    uq = pd.to_numeric(sub[cols["uq"]], errors="coerce")
    p90 = pd.to_numeric(sub[cols["p90"]], errors="coerce")
    p95 = pd.to_numeric(sub[cols["p95"]], errors="coerce")

    p05s = _scale_days_series(p05, TIMING_DAYS_SCALE)
    p10s = _scale_days_series(p10, TIMING_DAYS_SCALE)
    lqs = _scale_days_series(lq, TIMING_DAYS_SCALE)
    meds = _scale_days_series(med, TIMING_DAYS_SCALE)
    uqs = _scale_days_series(uq, TIMING_DAYS_SCALE)
    p90s = _scale_days_series(p90, TIMING_DAYS_SCALE)
    p95s = _scale_days_series(p95, TIMING_DAYS_SCALE)

    n_c = _resolve_col(sub, "n_patients_with_pair")
    customdata = sub[n_c].to_numpy().reshape(-1, 1) if n_c else None

    fig = go.Figure()
    meta_rows = [
        [
            _day_label(p05.iloc[i]),
            _day_label(p10.iloc[i]),
            _day_label(lq.iloc[i]),
            _day_label(med.iloc[i]),
            _day_label(uq.iloc[i]),
            _day_label(p90.iloc[i]),
            _day_label(p95.iloc[i]),
        ]
        for i in range(len(labels))
    ]
    fig.add_trace(
        go.Box(
            orientation="h",
            y=labels,
            q1=lqs,
            median=meds,
            q3=uqs,
            lowerfence=p05s,
            upperfence=p95s,
            name="IQR + whiskers (P05–P95)",
            fillcolor="rgba(37, 99, 235, 0.35)",
            line=dict(color="#1d4ed8", width=1.2),
            whiskerwidth=0.65,
            marker=dict(outliercolor="rgba(0,0,0,0)", opacity=0),
            customdata=customdata,
            meta=meta_rows,
            hovertemplate=(
                "%{y}"
                "<br>Median (IQR): %{meta[3]} (%{meta[2]}–%{meta[4]}) days"
                "<br>P10–P90: %{meta[1]}–%{meta[5]} days"
                + ("<br>n: %{customdata[0]}" if n_c else "")
                + "<extra></extra>"
            ),
        )
    )
    fig.add_trace(
        go.Scatter(
            x=p10s,
            y=labels,
            mode="markers",
            name="P10",
            customdata=[_day_label(v) for v in p10],
            marker=dict(
                symbol="line-ns",
                size=12,
                line=dict(width=1.6, color="#78716c"),
                opacity=0.75,
            ),
            hovertemplate=(
                    "%{y}<br>P10: %{customdata} days<extra></extra>"
            ),
        )
    )
    fig.add_trace(
        go.Scatter(
            x=p90s,
            y=labels,
            mode="markers",
            name="P90",
            customdata=[_day_label(v) for v in p90],
            marker=dict(
                symbol="line-ns",
                size=12,
                line=dict(width=1.6, color="#a8a29e"),
                opacity=0.75,
            ),
            hovertemplate=(
                    "%{y}<br>P90: %{customdata} days<extra></extra>"
            ),
        )
    )

    h = max(380, min(900, 32 * len(labels) + 120))
    x_title = "Days"
    fig.update_layout(
        template="plotly_white",
        height=h,
        margin=dict(l=24, r=28, t=8, b=48),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        xaxis=dict(
            title=x_title,
            zeroline=True,
            zerolinewidth=1,
            zerolinecolor="#cbd5e1",
            gridcolor="#e5e7eb",
        ),
        yaxis=dict(title="", automargin=True),
        hovermode="closest",
    )
    if TIMING_DAYS_SCALE in ("signed_log10", "symlog10"):
        raw_all = pd.concat([p05, p10, lq, med, uq, p90, p95], axis=0)
        _apply_signed_log10_axis_ticks(fig, raw_values=raw_all, axis="x")
    return fig


def _deaths_by_anchor_figure(df: pd.DataFrame, *, anchor_event: str) -> go.Figure | None:
    if df.empty:
        return None
    y = _resolve_col(df, "prevalence_year")
    a = _resolve_col(df, "anchor_event")
    npat = _resolve_col(df, "n_patients")
    ndeath = _resolve_col(df, "n_deaths")
    pct = _resolve_col(df, "pct_deaths")
    lq = _resolve_col(df, "lq_days")
    med = _resolve_col(df, "median_days")
    uq = _resolve_col(df, "uq_days")
    if not y or not a or not npat or not ndeath or not lq or not med or not uq:
        return None

    sub = df[df[a].astype(str).str.upper().eq(str(anchor_event).upper())].copy()
    if sub.empty:
        return None
    years = pd.to_numeric(sub[y].astype(str), errors="coerce")
    sub = sub.assign(__year=years).dropna(subset=["__year"]).sort_values("__year")
    x = sub["__year"].astype(int)

    n_pat = pd.to_numeric(sub[npat], errors="coerce")
    n_d = pd.to_numeric(sub[ndeath], errors="coerce")
    if pct and pct in sub.columns:
        pct_d = pd.to_numeric(sub[pct], errors="coerce")
    else:
        pct_d = 100.0 * n_d / n_pat

    lqv = pd.to_numeric(sub[lq], errors="coerce")
    medv = pd.to_numeric(sub[med], errors="coerce")
    uqv = pd.to_numeric(sub[uq], errors="coerce")

    fig = make_subplots(
        rows=2,
        cols=1,
        shared_xaxes=True,
        vertical_spacing=0.10,
        row_heights=[0.48, 0.52],
    )
    # % deaths (top)
    fig.add_trace(
        go.Scatter(
            x=x,
            y=pct_d,
            mode="lines+markers",
            name="% deaths",
            line=dict(color="#111827", width=2),
            marker=dict(size=6, color="#111827"),
            hovertemplate="Year %{x}<br>% deaths %{y:.1f}%<extra></extra>",
        ),
        row=1,
        col=1,
    )
    # IQR band + median (bottom, days)
    fig.add_trace(
        go.Scatter(
            x=x,
            y=uqv,
            mode="lines",
            name="UQ",
            line=dict(color="rgba(37, 99, 235, 0.0)"),
            showlegend=False,
            hoverinfo="skip",
        ),
        row=2,
        col=1,
    )
    fig.add_trace(
        go.Scatter(
            x=x,
            y=lqv,
            mode="lines",
            name="IQR (LQ–UQ)",
            line=dict(color="rgba(37, 99, 235, 0.0)"),
            fill="tonexty",
            fillcolor="rgba(37, 99, 235, 0.18)",
            hoverinfo="skip",
        ),
        row=2,
        col=1,
    )
    fig.add_trace(
        go.Scatter(
            x=x,
            y=medv,
            mode="lines+markers",
            name="Median days to death",
            line=dict(color="#2563eb", width=2),
            marker=dict(size=6, color="#2563eb"),
            customdata=pd.concat([lqv, uqv], axis=1).to_numpy(),
            hovertemplate="Year %{x}<br>Median %{y:.0f}d<br>IQR %{customdata[0]:.0f}–%{customdata[1]:.0f}d<extra></extra>",
        ),
        row=2,
        col=1,
    )

    fig.update_layout(
        template="plotly_white",
        height=460,
        margin=dict(l=40, r=24, t=10, b=56),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        hovermode="x unified",
    )
    fig.update_xaxes(title="Year", dtick=1, row=2, col=1)
    fig.update_yaxes(title="% deaths", rangemode="tozero", gridcolor="#e5e7eb", row=1, col=1)
    fig.update_yaxes(
        title="Days to death (median + IQR)",
        rangemode="tozero",
        gridcolor="#e5e7eb",
        row=2,
        col=1,
    )
    return fig


def _death_timing_table_html(df: pd.DataFrame) -> str:
    """
    Table of death counts, in/out-obs splits, and median (IQR) for time to death
    and observation follow-up.  Includes OVERALL and years >= 2015.
    """
    year_col = _resolve_col(df, "prevalence_year")
    anchor_col = _resolve_col(df, "anchor_event")
    npat_col = _resolve_col(df, "n_patients")
    ndeath_col = _resolve_col(df, "n_deaths")
    in_obs_col = _resolve_col(df, "n_deaths_in_obs")
    out_obs_col = _resolve_col(df, "n_deaths_out_obs")
    lq_col = _resolve_col(df, "lq_days")
    med_col = _resolve_col(df, "median_days")
    uq_col = _resolve_col(df, "uq_days")
    lq_fu_col = _resolve_col(df, "lq_followup_days")
    med_fu_col = _resolve_col(df, "median_followup_days")
    uq_fu_col = _resolve_col(df, "uq_followup_days")

    if not year_col or not anchor_col or not npat_col or not ndeath_col:
        return ""

    overall_mask = df[year_col].astype(str).str.upper().eq("OVERALL")
    year_num = pd.to_numeric(df[year_col], errors="coerce")
    sub = df[overall_mask | (year_num >= 2015)].copy()
    if sub.empty:
        return ""

    # Overall rows first (by anchor), then non-Overall sorted by anchor then year.
    sub["__overall_sort"] = sub[year_col].apply(
        lambda v: 0 if str(v).upper() == "OVERALL" else 1
    )
    sub["__anchor_sort"] = sub[anchor_col].apply(
        lambda v: 0 if str(v).upper() == "INDEX" else 1
    )
    sub["__year_sort"] = sub[year_col].apply(
        lambda v: -1 if str(v).upper() == "OVERALL" else pd.to_numeric(v, errors="coerce")
    )
    sub = sub.sort_values(["__overall_sort", "__anchor_sort", "__year_sort"])

    min_cell = _infer_min_cell_from_sentinels(df, [npat_col, ndeath_col])

    def _safe_int(v: object) -> int | None:
        try:
            if pd.isna(v):
                return None
            x = int(float(v))
            return None if x < 0 else x
        except Exception:
            return None

    def _fmt_count(v: object) -> str:
        x = _safe_int(v)
        return "—" if x is None else f"{x:,}"

    def _fmt_deaths(ndeath: object, npat: object) -> str:
        nd = _safe_int(ndeath)
        np_ = _safe_int(npat)
        if nd is None:
            return "—"
        if np_ is None or np_ <= min_cell:
            return f"{nd:,}"
        return f"{nd:,} ({100.0 * nd / np_:.1f}%)"

    def _fmt_obs_deaths(count: object, total_deaths: object) -> str:
        n = _safe_int(count)
        td = _safe_int(total_deaths)
        if n is None:
            return "—"
        if td is None or td == 0:
            return f"{n:,}"
        return f"{n:,} ({100.0 * n / td:.1f}%)"

    def _median_iqr(med: object, lq: object, uq: object) -> str:
        m, lo, hi = _day_label(med), _day_label(lq), _day_label(uq)
        if m == "—":
            return "—"
        if lo == "—" or hi == "—":
            return m
        return f"{m} ({lo}–{hi})"

    _anchor_labels = {"INDEX": "Index Dx", "FIRST_MET": "First Met"}

    rows_out = []
    for _, row in sub.iterrows():
        anchor_raw = str(row[anchor_col]).upper()
        y = str(row[year_col])
        nd_val = row[ndeath_col]
        rows_out.append({
            "Year": "Overall" if y.upper() == "OVERALL" else y,
            "Anchor": _anchor_labels.get(anchor_raw, anchor_raw),
            "Patients": _fmt_count(row[npat_col]),
            "Deaths": _fmt_deaths(nd_val, row[npat_col]),
            "Deaths in obs. period": _fmt_obs_deaths(row[in_obs_col], nd_val) if in_obs_col else "—",
            "Deaths outside obs. period": _fmt_obs_deaths(row[out_obs_col], nd_val) if out_obs_col else "—",
            "Days to death, median (IQR)": _median_iqr(
                row.get(med_col), row.get(lq_col), row.get(uq_col)
            ),
            "Obs. follow-up, median (IQR)": _median_iqr(
                row.get(med_fu_col), row.get(lq_fu_col), row.get(uq_fu_col)
            ),
        })

    tbl = pd.DataFrame(rows_out).to_html(index=False, border=0, classes="report-table")
    tbl = tbl.replace('class="dataframe report-table"', 'class="report-table"', 1)
    tbl = re.sub(r"(<tr>)(\s*<td>Overall</td>)", r"<tr style='background-color:#dbeafe'>\2", tbl)
    return tbl


def _timing_pair_focus_figure(
    rd: Path, from_ev: str, to_ev: str, variant_keys: list[str]
) -> go.Figure | None:
    """
    One row of panels: same FROM→TO pair across chosen timing CSVs, shared horizontal scale.
    """
    pair_label = f"{_event_pairwise_label(from_ev)} → {_event_pairwise_label(to_ev)}"
    chosen = [(k, TIMING_VARIANTS[k]) for k in variant_keys if k in TIMING_VARIANTS]
    if not chosen:
        return None
    subplot_titles = [short for _, (_, _, short) in chosen]
    fig = make_subplots(
        rows=1,
        cols=len(chosen),
        subplot_titles=subplot_titles,
        horizontal_spacing=0.07,
        shared_xaxes=True,
        shared_yaxes=False,
    )
    any_data = False
    for j, (vkey, (_, fname, _)) in enumerate(chosen, start=1):
        path = rd / fname
        if not path.exists():
            fig.add_annotation(
                text="File not found",
                row=1,
                col=j,
                showarrow=False,
                font=dict(size=12, color="#9ca3af"),
            )
            continue
        df = pd.read_csv(path)
        # Filter to the correct timing_type stratum in the consolidated CSV.
        ttc = _resolve_col(df, "timing_type")
        if ttc:
            df = df[df[ttc].astype(str).str.lower().eq(vkey.lower())].copy()
        from_c = _resolve_col(df, "from_event")
        to_c = _resolve_col(df, "to_event")
        cols = _timing_pair_csv_quantile_cols(df)
        need_always = ("p05", "p10", "lq", "med", "uq", "p90", "p95")
        if not from_c or not to_c or any(cols[k] is None for k in need_always):
            fig.add_annotation(
                text="Missing columns",
                row=1,
                col=j,
                showarrow=False,
                font=dict(size=12, color="#9ca3af"),
            )
            continue
        sel = df[
            df[from_c].astype(str).str.upper().eq(from_ev.upper())
            & df[to_c].astype(str).str.upper().eq(to_ev.upper())
        ]
        if sel.empty:
            fig.add_annotation(
                text="No row for this pair",
                row=1,
                col=j,
                showarrow=False,
                font=dict(size=12, color="#9ca3af"),
            )
            continue
        row = sel.iloc[0]
        any_data = True
        show_leg = j == 1

        def _num(c: str) -> float:
            v = row[c]
            if pd.isna(v):
                return float("nan")
            return float(v)

        p05 = _num(cols["p05"])
        p10 = _num(cols["p10"])
        lq = _num(cols["lq"])
        med = _num(cols["med"])
        uq = _num(cols["uq"])
        p90 = _num(cols["p90"])
        p95 = _num(cols["p95"])

        p05s = _transform_days(p05)
        p10s = _transform_days(p10)
        lqs = _transform_days(lq)
        meds = _transform_days(med)
        uqs = _transform_days(uq)
        p90s = _transform_days(p90)
        p95s = _transform_days(p95)

        n_c = _resolve_col(df, "n_patients_with_pair")
        customdata = None
        if n_c and n_c in row.index and pd.notna(row[n_c]):
            customdata = [[int(float(row[n_c]))]]

        fig.add_trace(
            go.Box(
                orientation="h",
                y=[pair_label],
                q1=[lqs],
                median=[meds],
                q3=[uqs],
                lowerfence=[p05s],
                upperfence=[p95s],
                name="IQR + whiskers (P05–P95)",
                legendgroup="box",
                showlegend=show_leg,
                fillcolor="rgba(37, 99, 235, 0.35)",
                line=dict(color="#1d4ed8", width=1.2),
                whiskerwidth=0.65,
                marker=dict(outliercolor="rgba(0,0,0,0)", opacity=0),
                customdata=customdata,
                meta=[
                    [
                        _day_label(p05),
                        _day_label(p10),
                        _day_label(lq),
                        _day_label(med),
                        _day_label(uq),
                        _day_label(p90),
                        _day_label(p95),
                    ]
                ],
                hovertemplate=(
                    "<b>%{y}</b><br>"
                    "<span style='font-size:11px;color:#4b5563'>Lag in <b>whole days</b>: "
                    "TO − FROM. Negative = TO before FROM.</span><br><br>"
                    "<b>Box</b>: Q1–Q3 · <b>line</b>: median · <b>whiskers</b>: ~P5–P95<br><br>"
                    "<b>Quantiles (rounded)</b><br>"
                    "P5 %{meta[0]} · P10 %{meta[1]} · Q1 %{meta[2]} · "
                    "Median %{meta[3]} · Q3 %{meta[4]} · P90 %{meta[5]} · P95 %{meta[6]}"
                    + (
                        "<br><br>Patients with pair: %{customdata[0]}"
                        if customdata
                        else ""
                    )
                    + "<extra></extra>"
                ),
            ),
            row=1,
            col=j,
        )
        fig.add_trace(
            go.Scatter(
                x=[p10s],
                y=[pair_label],
                mode="markers",
                name="P10",
                legendgroup="p10",
                showlegend=show_leg,
                customdata=[_day_label(p10)],
                marker=dict(
                    symbol="line-ns",
                    size=12,
                    line=dict(width=1.6, color="#78716c"),
                    opacity=0.75,
                ),
                hovertemplate=(
                    "<b>%{y}</b><br><b>P10</b>: %{customdata} days (rounded)<extra></extra>"
                ),
            ),
            row=1,
            col=j,
        )
        fig.add_trace(
            go.Scatter(
                x=[p90s],
                y=[pair_label],
                mode="markers",
                name="P90",
                legendgroup="p90",
                showlegend=show_leg,
                customdata=[_day_label(p90)],
                marker=dict(
                    symbol="line-ns",
                    size=12,
                    line=dict(width=1.6, color="#a8a29e"),
                    opacity=0.75,
                ),
                hovertemplate=(
                    "<b>%{y}</b><br><b>P90</b>: %{customdata} days (rounded)<extra></extra>"
                ),
            ),
            row=1,
            col=j,
        )

    if not any_data:
        return None

    fig.update_layout(
        template="plotly_white",
        height=440,
        margin=dict(l=12, r=20, t=72, b=56),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        hovermode="closest",
    )
    x_title = "Days"
    fig.update_xaxes(
        title=dict(
            text=x_title,
            font=dict(size=12),
        ),
        zeroline=True,
        zerolinewidth=1,
        zerolinecolor="#cbd5e1",
        gridcolor="#e5e7eb",
        row=1,
        col=len(chosen),
    )
    if TIMING_DAYS_SCALE in ("signed_log10", "symlog10"):
        raw_all = pd.Series([p05, p10, lq, med, uq, p90, p95])
        tickvals, ticktext = _scaled_ticks(float(pd.to_numeric(raw_all, errors="coerce").abs().max()))
        # Apply to all subplot x-axes.
        fig.update_xaxes(tickmode="array", tickvals=tickvals, ticktext=ticktext)
    fig.update_yaxes(automargin=True, row=1, col=1, title_text="Pair")
    for c in range(2, len(chosen) + 1):
        fig.update_yaxes(showticklabels=False, row=1, col=c)
    return fig


def _deaths_pct_compare_figure(df: pd.DataFrame) -> go.Figure | None:
    """
    By-year % deaths for INDEX vs FIRST_MET anchors on one plot.
    """
    if df.empty:
        return None
    y = _resolve_col(df, "prevalence_year")
    a = _resolve_col(df, "anchor_event")
    npat = _resolve_col(df, "n_patients")
    ndeath = _resolve_col(df, "n_deaths")
    pct = _resolve_col(df, "pct_deaths")
    if not y or not a or not npat or not ndeath:
        return None

    sub = df.copy()
    sub["__year"] = pd.to_numeric(sub[y].astype(str), errors="coerce")
    sub = sub.dropna(subset=["__year"]).sort_values("__year")

    def _series(anchor: str) -> pd.DataFrame:
        s = sub[sub[a].astype(str).str.upper().eq(anchor.upper())].copy()
        if s.empty:
            return s
        n_pat = pd.to_numeric(s[npat], errors="coerce")
        n_d = pd.to_numeric(s[ndeath], errors="coerce")
        if pct and pct in s.columns:
            s["__pct"] = pd.to_numeric(s[pct], errors="coerce")
        else:
            s["__pct"] = 100.0 * n_d / n_pat
        return s

    dx = _series("INDEX")
    met = _series("FIRST_MET")
    if dx.empty and met.empty:
        return None

    fig = go.Figure()
    if not dx.empty:
        fig.add_trace(
            go.Scatter(
                x=dx["__year"].astype(int),
                y=dx["__pct"],
                mode="lines+markers",
                name=f"% deaths ({_event_display_name('DX')} index)",
                line=dict(color="#111827", width=2),
                marker=dict(size=6, color="#111827"),
                hovertemplate="Year %{x}<br>% deaths %{y:.1f}%<extra></extra>",
            )
        )
    if not met.empty:
        fig.add_trace(
            go.Scatter(
                x=met["__year"].astype(int),
                y=met["__pct"],
                mode="lines+markers",
                name=f"% deaths ({_event_display_name('MET')} index)",
                line=dict(color="#2563eb", width=2),
                marker=dict(size=6, color="#2563eb"),
                hovertemplate="Year %{x}<br>% deaths %{y:.1f}%<extra></extra>",
            )
        )

    fig.update_layout(
        template="plotly_white",
        height=340,
        margin=dict(l=40, r=24, t=10, b=56),
        legend=dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        xaxis=dict(title="Year", dtick=1),
        yaxis=dict(title="% deaths", rangemode="tozero", gridcolor="#e5e7eb"),
        hovermode="x unified",
    )
    return fig


def _timing_variant_heading_word(vkey: str) -> str:
    """
    Short, human-friendly timing word used in focus headings.
    """
    k = str(vkey).strip().lower()
    if k == "first_to_first":
        return "First"
    if k == "first_to_closest":
        return "Closest"
    if k in ("first_to_closest_before",):
        return "Closest (before)"
    if k == "first_to_closest_after":
        return "Closest (after)"
    return "Timing"


def _anchor_for_from_event(from_ev: str) -> str:
    """
    Map FROM event family to event-code-count anchor.
    User rule:
    - FROM=DX -> ANCHOR_EVENT=INDEX
    - FROM=MET -> ANCHOR_EVENT=FIRST_MET (called "MET" colloquially)
    """
    fe = str(from_ev).strip().upper()
    if fe == "DX":
        return "INDEX"
    if fe == "MET":
        return "FIRST_MET"
    return "INDEX"


def _timing_suffix_for_variant(vkey: str) -> str:
    """
    Event-code-count timing columns have *_FIRST and *_CLOSEST variants.
    We map our timing variants to the closest available column family.
    """
    k = str(vkey).strip().lower()
    if k == "first_to_first":
        return "FIRST"
    # closest/before/after all use CLOSEST in event_code_counts outputs
    return "CLOSEST"


def _time_window_for_variant(vkey: str) -> str:
    """
    Return the time_window value for the consolidated final_code_counts.csv.
    """
    k = str(vkey).strip().lower()
    if k in ("first_to_closest_before",):
        return "before"
    if k in ("first_to_closest_after",):
        return "after"
    return "all"


@dataclass(frozen=True)
class EccLinkSpec:
    """
    Which event-code-count rows to join to a focus timing plot.

    time_window
        "all"    -> final_code_counts.csv rows where time_window == "all".
        "before" -> final_code_counts.csv rows where time_window == "before".
        "after"  -> final_code_counts.csv rows where time_window == "after".
    column_family
        Which suffixed timing columns to prefer when the export has MEDIAN_DAYS_FIRST / _CLOSEST.
        Many pipelines emit only median_days (one triple), determined by SQL @event_code_timing_uses_closest.
    anchor
        INDEX or FIRST_MET; None means DX→INDEX, MET→FIRST_MET (same as timing FROM).
    """

    time_window: Literal["all", "before", "after"]
    column_family: Literal["FIRST", "CLOSEST"]
    anchor: str | None = None


def _ecc_link_spec_default_for_timing(timing_key: str) -> EccLinkSpec:
    """
    Default event-code-count link for a timing variant (matches pre-refactor report behavior).

    - first_to_first -> time_window="all", FIRST timing columns.
    - first_to_closest (undirected) -> time_window="all", CLOSEST columns.
    - first_to_closest_before -> time_window="before", CLOSEST columns.
    - first_to_closest_after  -> time_window="after",  CLOSEST columns.
    """
    k = str(timing_key).strip().lower()
    tw = _time_window_for_variant(k)
    if k == "first_to_first":
        return EccLinkSpec(time_window="all", column_family="FIRST", anchor=None)
    if tw in ("before", "after"):
        return EccLinkSpec(time_window=tw, column_family="CLOSEST", anchor=None)
    return EccLinkSpec(time_window="all", column_family="CLOSEST", anchor=None)


def _ecc_link_spec_with_overrides(base: EccLinkSpec, ov: dict[str, Any] | None) -> EccLinkSpec:
    """Merge optional user overrides from a plot dict's ``ecc`` key."""
    if not ov:
        return base
    kw: dict[str, Any] = {}
    if "export" in ov:
        e = str(ov["export"]).strip().lower()
        if e in ("all", "before", "after"):
            kw["time_window"] = e
    if "time_window" in ov:
        tw = str(ov["time_window"]).strip().lower()
        if tw in ("all", "before", "after"):
            kw["time_window"] = tw
    if "column_family" in ov:
        cf = str(ov["column_family"]).strip().upper()
        if cf in ("FIRST", "CLOSEST"):
            kw["column_family"] = cf
    if "anchor" in ov and ov["anchor"] is not None:
        kw["anchor"] = str(ov["anchor"]).strip().upper()
    return replace(base, **kw) if kw else base


def _ecc_event_code_counts_path(rd: Path, ecc_spec: EccLinkSpec) -> Path:
    return rd / "final_code_counts.csv"


def _ecc_export_has_dual_timing_columns(rd: Path, ecc_spec: EccLinkSpec) -> bool:
    path = _ecc_event_code_counts_path(rd, ecc_spec)
    if not path.exists():
        return False
    hdr = pd.read_csv(path, nrows=0)
    return _resolve_col(hdr, "median_days_first") is not None and _resolve_col(
        hdr, "median_days_closest"
    ) is not None


def _results_have_dual_event_code_timing(rd: Path) -> bool:
    spec = EccLinkSpec(time_window="all", column_family="FIRST")
    return _ecc_export_has_dual_timing_columns(rd, spec)


def _ecc_timing_triple_columns_for_suffix(
    sub: pd.DataFrame, column_family: str
) -> tuple[str | None, str | None, str | None]:
    """Resolve LQ/MEDIAN/UQ column names for FIRST or CLOSEST when present."""
    cf = column_family.strip().upper()
    if cf not in ("FIRST", "CLOSEST"):
        cf = "CLOSEST"
    lo = cf.lower()
    med = _resolve_col(sub, f"median_days_{lo}")
    lq = _resolve_col(sub, f"lq_days_{lo}")
    uq = _resolve_col(sub, f"uq_days_{lo}")
    if med and lq and uq:
        return med, lq, uq
    return None, None, None


def _focus_pair_commentary_html(note: object) -> str:
    """
    Optional per-plot notes under the pair heading: plain text only (escaped), newlines kept.
    """
    if note is None:
        return ""
    text = str(note).strip()
    if not text:
        return ""
    return (
        "<p class='subtle focus-pair-commentary' style='white-space: pre-line'>"
        + html.escape(text)
        + "</p>"
    )


def _event_code_timing_uses_closest_effective() -> bool:
    """True if SQL used @event_code_timing_uses_closest=1; env overrides module constant."""
    raw = os.environ.get("CHARACTERIZATION_EVENT_CODE_TIMING_USES_CLOSEST")
    if raw is None or str(raw).strip() == "":
        return bool(EVENT_CODE_TIMING_USES_CLOSEST)
    return str(raw).strip().lower() in ("1", "true", "yes", "on")


def _event_code_occurrence_rule_sentences() -> tuple[str, str]:
    """(rule sentence, note on pairwise vs concept-level) as HTML fragments."""
    if _event_code_timing_uses_closest_effective():
        rule = (
            "Per-concept medians use the occurrence with <b>minimum |days|</b> to the anchor (CLOSEST), "
            "per SQL <code>@event_code_timing_uses_closest=1</code>."
        )
    else:
        rule = (
            "Per-concept medians use the <b>earliest</b> event in the stratum (FIRST), "
            "per SQL <code>@event_code_timing_uses_closest=0</code>."
        )
    note = (
        'The focus plot title (e.g. "Closest (before)") refers to the <i>pairwise</i> timing definition in its CSV; '
        'this table follows the global concept-level rule above, which may differ.'
    )
    return rule, note


def _ecc_link_caption_html(ecc_spec: EccLinkSpec, from_ev: str, rd: Path | None = None) -> str:
    """HTML description of the linked event-code-count slice (file, stratum, timing rule)."""
    anchor = ecc_spec.anchor or _anchor_for_from_event(from_ev)
    file_lbl = "<code>final_code_counts.csv</code>"
    tr_bit = f", <code>time_window</code>={html.escape(ecc_spec.time_window)}"
    dual = rd is not None and _ecc_export_has_dual_timing_columns(rd, ecc_spec)
    if dual:
        cf = ecc_spec.column_family
        if cf == "FIRST":
            rule = (
                "Concept-level medians use <b>FIRST</b> (earliest <code>event_date</code> per patient per concept): "
                f"<code>LQ/MEDIAN/UQ_DAYS_{cf}</code>, aligned with pairwise <i>first</i> timing."
            )
        else:
            rule = (
                "Concept-level medians use <b>CLOSEST</b> (minimum |days| to anchor per patient per concept): "
                f"<code>LQ/MEDIAN/UQ_DAYS_{cf}</code>, aligned with pairwise <i>closest</i> timing."
            )
        xnote = (
            " Export includes both FIRST and CLOSEST triples; this table selects the triple that matches the plot variant."
        )
    else:
        rule, xnote = _event_code_occurrence_rule_sentences()
        xnote = f" {xnote}"
    return (
        f"Anchor={html.escape(anchor)}, file={file_lbl}{tr_bit}. "
        f"{rule}{xnote}"
    )


def _slug(*parts: str) -> str:
    s = "_".join(str(p) for p in parts)
    out = []
    for ch in s:
        if ch.isalnum():
            out.append(ch.lower())
        elif ch in (" ", "-", ">", "_"):
            out.append("_")
    cleaned = "".join(out)
    while "__" in cleaned:
        cleaned = cleaned.replace("__", "_")
    return cleaned.strip("_")


def _event_code_counts_topn_for_timing_pair(
    rd: Path,
    *,
    from_ev: str,
    to_ev: str,
    ecc_spec: EccLinkSpec,
    to_denoms: dict[str, int],
    denom_override: int | None = None,
    top_n: int = 5,
) -> pd.DataFrame | None:
    """
    Return top N event code counts for the TO event family for a resolved EccLinkSpec.
    Includes CONCEPT_NAME if available via CDM lookup (best-effort).
    """
    path = rd / "final_code_counts.csv"
    if not path.exists():
        return None
    df = pd.read_csv(path)
    a = _resolve_col(df, "anchor_event")
    ef = _resolve_col(df, "event_family")
    twc = _resolve_col(df, "time_window")
    cid = _resolve_col(df, "concept_id")
    nrec = _resolve_col(df, "n_records")
    npat = _resolve_col(df, "n_patients")
    if not a or not ef or not cid or not nrec or not npat:
        return None

    anchor = ecc_spec.anchor or _anchor_for_from_event(from_ev)
    fam = str(to_ev).strip().upper()
    sub = df[
        df[a].astype(str).str.upper().eq(anchor.upper())
        & df[ef].astype(str).str.upper().eq(fam)
    ].copy()
    if twc:
        sub = sub[sub[twc].astype(str).str.lower().eq(ecc_spec.time_window.lower())].copy()
    if sub.empty:
        return None

    medc, lqc, uqc = _ecc_timing_triple_columns_for_suffix(sub, ecc_spec.column_family)
    if not medc or not lqc or not uqc:
        # Legacy exports: single triple (FIRST in v2 dual re-exports as LQ_DAYS / MEDIAN_DAYS / UQ_DAYS too).
        medc = _resolve_col(sub, "median_days")
        lqc = _resolve_col(sub, "lq_days")
        uqc = _resolve_col(sub, "uq_days")
    if not medc or not lqc or not uqc:
        return None

    # Top N by N_PATIENTS then N_RECORDS (matching the full report sort).
    sub[npat] = pd.to_numeric(sub[npat], errors="coerce")
    sub[nrec] = pd.to_numeric(sub[nrec], errors="coerce")
    n_show = max(1, int(top_n))
    sub = (
        sub.sort_values(by=[npat, nrec], ascending=[False, False])
        .head(n_show)
        .reset_index(drop=True)
    )

    # Best-effort concept name lookup (may fail if DB not available).
    concept_ids: list[int] = (
        pd.to_numeric(sub[cid], errors="coerce").dropna().astype(int).tolist()
    )
    name_map: dict[int, str] = {}
    try:
        name_map = _fetch_concept_name_map(concept_ids)
    except Exception:
        name_map = {}

    to_denom = int(denom_override) if denom_override is not None and denom_override > 0 else to_denoms.get(fam)
    def _n_pat_cell(v: object) -> str:
        return _fmt_n_pct_from_den(v, to_denom)

    medv = pd.to_numeric(sub[medc], errors="coerce")
    lqv = pd.to_numeric(sub[lqc], errors="coerce")
    uqv = pd.to_numeric(sub[uqc], errors="coerce")
    timing_txt = []
    for m, lq, uq in zip(medv, lqv, uqv):
        if pd.isna(m) or pd.isna(lq) or pd.isna(uq):
            timing_txt.append("—")
        else:
            cm = _round_day_int(m)
            clq = _round_day_int(lq)
            cuq = _round_day_int(uq)
            if cm is None or clq is None or cuq is None:
                timing_txt.append("—")
            else:
                timing_txt.append(f"{cm:d} ({clq:d}–{cuq:d})")

    out = pd.DataFrame(
        {
            "CONCEPT_ID": sub[cid].astype(str),
            "CONCEPT_NAME": [name_map.get(int(float(x)), "") if str(x).strip() != "" else "" for x in sub[cid]],
            "N_RECORDS": sub[nrec].map(lambda x: "—" if pd.isna(x) or float(x) < 0 else f"{int(float(x)):,}"),
            "N_PATIENTS": sub[npat].map(_n_pat_cell),
            "MEDIAN (IQR)": timing_txt,
        }
    )
    return out


_DEMO_ANCHOR_ORDER: tuple[tuple[str, str], ...] = (
    ("INDEX", "Cancer of interest (first)"),
    ("FIRST_MET", "Metastasis (first)"),
)


def _fmt_pct_cell(v: object, *, ndigits: int = 1) -> str:
    try:
        if pd.isna(v):
            return "—"
        x = float(v)
        if math.isnan(x):
            return "—"
        return f"{x:.{ndigits}f}%"
    except (TypeError, ValueError):
        return "—"


def _demographics_section_html(rd: Path) -> list[str]:
    """
    Blocks for the Demographics section: heading, note, table (or missing-data note).
    Placed after population prevalence and before deaths.
    """
    path = rd / "final_demographics_from_anchors.csv"
    out: list[str] = [
        "<h2>Demographics</h2>",
        "<p class='subtle'>By anchor cohort: count, age at anchor in years (median and IQR), and sex. "
        "<code>INDEX</code> = main cancer diagnosis index date; <code>FIRST_MET</code> = first metastasis.</p>",
    ]
    if not path.exists():
        out.append(
            "<p class='subtle'><i>Not found: <code>final_demographics_from_anchors.csv</code></i></p>"
        )
        return out

    df = pd.read_csv(path)
    anchor_c = _resolve_col(df, "anchor_event")
    n_c = _resolve_col(df, "n_patients")
    pct_m_c = _resolve_col(df, "pct_male")
    pct_f_c = _resolve_col(df, "pct_female")
    nm_c = _resolve_col(df, "n_male")
    nf_c = _resolve_col(df, "n_female")
    alq_c = _resolve_col(df, "age_lq_years")
    amed_c = _resolve_col(df, "age_median_years")
    auq_c = _resolve_col(df, "age_uq_years")
    if not anchor_c or not n_c or not alq_c or not amed_c or not auq_c:
        out.append("<p class='subtle'><i>Demographics file missing required columns.</i></p>")
        return out

    rows_out: list[dict[str, str]] = []
    for raw_anchor, label in _DEMO_ANCHOR_ORDER:
        sel = df[df[anchor_c].astype(str).str.upper().eq(raw_anchor)]
        if sel.empty:
            continue
        r = sel.iloc[0]
        try:
            n_val = int(float(r[n_c]))
            n_str = f"{n_val:,}" if n_val >= 0 else "—"
        except (TypeError, ValueError):
            n_str = "—"

        med = _round_day_int(r[amed_c]) if amed_c in r.index else None
        lq = _round_day_int(r[alq_c]) if alq_c in r.index else None
        uq = _round_day_int(r[auq_c]) if auq_c in r.index else None
        if med is not None and lq is not None and uq is not None:
            age_str = f"{med:d} ({lq:d}–{uq:d})"
        else:
            age_str = "—"

        pct_m = "—"
        if pct_m_c and pct_m_c in r.index and pd.notna(r[pct_m_c]):
            pct_m = _fmt_pct_cell(r[pct_m_c])
        elif nm_c and nf_c and nm_c in r.index and nf_c in r.index:
            try:
                nm = int(float(r[nm_c]))
                nf = int(float(r[nf_c]))
                tot = nm + nf
                if tot > 0:
                    pct_m = f"{100.0 * nm / tot:.1f}%"
            except (TypeError, ValueError):
                pass

        pct_f = "—"
        if pct_f_c and pct_f_c in r.index and pd.notna(r[pct_f_c]):
            pct_f = _fmt_pct_cell(r[pct_f_c])
        elif nm_c and nf_c and nm_c in r.index and nf_c in r.index:
            try:
                nm = int(float(r[nm_c]))
                nf = int(float(r[nf_c]))
                tot = nm + nf
                if tot > 0:
                    pct_f = f"{100.0 * nf / tot:.1f}%"
            except (TypeError, ValueError):
                pass

        rows_out.append(
            {
                "Index (DX / MET)": label,
                "Count": n_str,
                "Age (IQR)": age_str,
                "% male": pct_m,
                "% female": pct_f,
            }
        )

    if not rows_out:
        out.append("<p class='subtle'><i>No INDEX or FIRST_MET rows in demographics file.</i></p>")
        return out

    tbl = pd.DataFrame(rows_out).to_html(index=False, border=0, classes="report-table")
    tbl = tbl.replace('class="dataframe report-table"', 'class="report-table"', 1)
    out.append(tbl)
    return out


def _fmt_anchor_dx_count_cell(v: object) -> str:
    """Format integer counts; suppression sentinels and NA → em dash."""
    if v is None or (isinstance(v, float) and pd.isna(v)):
        return "—"
    try:
        x = float(v)
    except (TypeError, ValueError):
        return "—"
    if pd.isna(x):
        return "—"
    if x < 0:
        return "—"
    return f"{int(round(x)):,}"


def _anchor_dx_concept_counts_section_html(
    rd: Path, *, top_n: int = ANCHOR_DX_COUNTS_TOP_N
) -> list[str]:
    """
    Top-N anchor DX concepts (distinct patients and patient-days), from final export query 10.
    Inserted before the Deaths section.
    """
    path = rd / ANCHOR_DX_COUNTS_CSV
    out: list[str] = [
        "<h2>Main cohort diagnosis codes</h2>",
        "<p class='subtle'>Most frequent <b>anchor DX</b> condition concepts in "
        "<code>condition_occurrence</code> (cohort definition / malignant neoplasm set). "
        "<b>Patients</b> = distinct persons with at least one row; "
        "<b>Patient-days</b> = distinct (person, calendar day) pairs. "
        f"Showing top {int(max(1, top_n))} by patient count.</p>",
    ]
    if not path.exists():
        out.append(
            f"<p class='subtle'><i>Not found: <code>{html.escape(ANCHOR_DX_COUNTS_CSV)}</code></i></p>"
        )
        return out

    df = pd.read_csv(path)
    cid = _resolve_col(df, "concept_id")
    npat_c = _resolve_col(df, "n_distinct_patients")
    ndays_c = _resolve_col(df, "n_distinct_patient_days")
    if not cid or not npat_c or not ndays_c:
        out.append("<p class='subtle'><i>Anchor DX counts file missing required columns.</i></p>")
        return out

    work = df[[cid, npat_c, ndays_c]].copy()
    work["_npat"] = pd.to_numeric(work[npat_c], errors="coerce")
    work["_cid"] = pd.to_numeric(work[cid], errors="coerce")
    work = work.sort_values(["_npat", "_cid"], ascending=[False, True], na_position="last")
    work = work.head(int(max(1, top_n)))

    concept_ids: list[int] = (
        pd.to_numeric(work[cid], errors="coerce").dropna().astype(int).tolist()
    )
    name_map: dict[int, str] = {}
    try:
        name_map = _fetch_concept_name_map(concept_ids)
    except Exception:
        name_map = {}

    rows_html: list[str] = []
    for rank, (_, r) in enumerate(work.iterrows(), start=1):
        raw_id = r[cid]
        try:
            iid = int(float(raw_id))
        except (TypeError, ValueError):
            iid = None
        nm = name_map.get(iid, "") if iid is not None else ""
        nm_disp = html.escape(nm) if nm else "—"
        rows_html.append(
            "<tr>"
            f"<td>{rank:d}</td>"
            f"<td><code>{html.escape(str(raw_id))}</code></td>"
            f"<td>{nm_disp}</td>"
            f'<td class="num">{_fmt_anchor_dx_count_cell(r[npat_c])}</td>'
            f'<td class="num">{_fmt_anchor_dx_count_cell(r[ndays_c])}</td>'
            "</tr>"
        )

    thead = (
        "<thead><tr>"
        "<th>#</th>"
        "<th>Concept ID</th>"
        "<th>Concept name</th>"
        '<th class="num">Patients</th>'
        '<th class="num">Patient-days</th>'
        "</tr></thead>"
    )
    tbody = "<tbody>" + "".join(rows_html) + "</tbody>"
    out.append(f'<table class="report-table anchor-dx-table">{thead}{tbody}</table>')
    return out


def build_summary_report(
    results_dir: Path | str | None = None,
    *,
    focus_timing_plot: str = "hist",
) -> Path:
    rd = Path(results_dir).expanduser().resolve() if results_dir else RESULTS_DIR
    csv_path = rd / "final_population_prevalence.csv"
    out_path = rd / "summary_report.html"
    need_plotly_cdn = True

    parts: list[str] = [
        "<!doctype html>",
        "<html>",
        "<head>",
        '<meta charset="utf-8" />',
        "<title>Data characterization summary</title>",
        "<style>",
        "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; "
        "margin: 28px; color: #111827; max-width: 1100px; }",
        "h1 { margin: 0 0 6px; letter-spacing: -0.02em; }",
        "h2 { margin: 0 0 10px; letter-spacing: -0.01em; }",
        "h3 { margin: 18px 0 10px; }",
        "h4 { margin: 14px 0 8px; font-size: 15px; }",
        "p { line-height: 1.5; margin: 8px 0; }",
        ".meta { color: #4b5563; margin: 6px 0 18px; }",
        ".section { margin-top: 26px; }",
        ".card { background: #ffffff; border: 1px solid #e5e7eb; border-radius: 12px; padding: 14px 14px; }",
        ".stack > * + * { margin-top: 12px; }",
        ".subtle { color: #6b7280; font-size: 12px; }",
        ".report-table { border-collapse: collapse; width: 100%; font-size: 13px; }",
        ".report-table th, .report-table td { border: 1px solid #e5e7eb; padding: 7px 9px; text-align: left !important; }",
        ".report-table th.num, .report-table td.num { text-align: right !important; font-variant-numeric: tabular-nums; }",
        ".report-table th { background: #f9fafb; font-weight: 650; }",
        ".report-table td { background: #ffffff; }",
        ".anchor-dx-table { margin-top: 4px; }",
        "code { background: #f3f4f6; padding: 1px 4px; border-radius: 4px; }",
        ".plot-wrap { padding-top: 6px; }",
        ".focus-pair-commentary { margin: 4px 0 14px 0; max-width: 900px; line-height: 1.55; }",
        "</style>",
        "</head>",
        "<body>",
        "<h1>Data characterization summary</h1>",
        f'<p class="meta">Source: <code>{html.escape(str(rd))}</code></p>',
        # "<div class='section card stack'>",
        # "<h2>Legend</h2>",
        # "<p class='subtle'>Abbreviations used throughout the tables and plots.</p>",
        # _legend_table_html(),
        # "</div>",
        "<div class='section card stack'>",
        "<h2>Population prevalence</h2>",
        "<p class='subtle'>Denominator for percentages is N_DX (cancer of interest cohort). "
        "Small-cell suppression uses the same rules as the characterization SQL.</p>",
    ]

    if not csv_path.exists():
        parts.append(f"<p class='subtle'><i>Missing <code>{html.escape(csv_path.name)}</code>.</i></p>")
    else:
        df = pd.read_csv(csv_path)
        df = _with_prevalence_pct_for_report(df)
        yc = _resolve_col(df, "prevalence_year")
        if yc is None:
            parts.append("<p><i>No prevalence year column.</i></p>")
        else:
            year_text = df[yc].astype(str)
            is_overall = year_text.str.upper().eq("OVERALL")
            overall_df = df[is_overall].reset_index(drop=True)
            yearly_df = df[~is_overall].reset_index(drop=True)

            parts.append("<h3>Overall</h3>")
            if overall_df.empty:
                parts.append("<p class='subtle'><i>No OVERALL row.</i></p>")
            else:
                summary = _overall_summary_rows(overall_df)
                tbl = summary.fillna("—").to_html(index=False, border=0, classes="report-table")
                tbl = tbl.replace('class="dataframe report-table"', 'class="report-table"', 1)
                parts.append(tbl)

            parts.append("<h3>By year</h3>")
            if yearly_df.empty:
                parts.append("<p class='subtle'><i>No year-level rows.</i></p>")
            else:
                fig_p = _yearly_prevalence_figure(yearly_df)
                if fig_p is None:
                    parts.append("<p class='subtle'><i>Could not build chart (missing columns).</i></p>")
                else:
                    parts.append(
                        "<div class='plot-wrap'>"
                        + _fig_to_div(fig_p, include_plotlyjs=need_plotly_cdn)
                        + "</div>"
                    )
                    parts.append(_plot_abbrev_note_html())
                    need_plotly_cdn = False

    parts.extend(_demographics_section_html(rd))

    parts.extend(_anchor_dx_concept_counts_section_html(rd))

    parts.append("</div>")

    parts.append("<div class='section'>")
    parts.append("<h2>Timing pair focus</h2>")
    parts.append(
        "<p class='subtle'>Selected pairs, shown one plot at a time. "
        "Each plot is preceded by a one-row summary table with counts and percentages. "
        "When the timing CSV includes decile columns, the optional density strip spans P05–P95 (same range as whiskers): "
        "5% in P05–P10 and P90–P95, 10% in each interior decile bin. "
        "Configure plots, optional per-pair <code>commentary</code>, and linked event-code-count slices in "
        "<code>FOCUS_TIMING_PLOTS</code> in <code>build_summary_html_report.py</code>.</p>"
    )

    # Group focus rows by FROM event (see FOCUS_TIMING_PLOTS at top of this module).
    grouped: dict[str, list[dict[str, Any]]] = {}
    order: list[str] = []
    for row in FOCUS_TIMING_PLOTS:
        from_ev = str(row.get("from", "")).strip()
        to_ev = str(row.get("to", "")).strip()
        timing = str(row.get("timing", "")).strip()
        if not from_ev or not to_ev or not timing:
            continue
        key = from_ev.upper()
        if key not in grouped:
            grouped[key] = []
            order.append(key)
        grouped[key].append(row)

    from_denoms = _overall_from_event_denominators(rd)
    to_denoms = from_denoms  # same source file, but interpreted as TO denominators by event family
    ecc_blocks: list[tuple[str, str]] = []  # (anchor_id, html)
    for from_key in order:
        items = grouped.get(from_key, [])
        if not items:
            continue
        parts.append("<div class='section card stack'>")
        parts.append(f"<h3>Timings from first {html.escape(_event_display_name(from_key))}</h3>")
        for plot_row in items:
            from_ev = str(plot_row["from"]).strip()
            to_ev = str(plot_row["to"]).strip()
            vkey = str(plot_row["timing"]).strip()
            do_reverse = bool(plot_row.get("reverse", False))
            x_range = plot_row.get("x_range")  # None or (lo_days, hi_days)
            ecc_ov = plot_row.get("ecc")
            ecc_ov = ecc_ov if isinstance(ecc_ov, dict) else None
            ecc_spec = _ecc_link_spec_with_overrides(_ecc_link_spec_default_for_timing(vkey), ecc_ov)
            n_from = from_denoms.get(from_ev.upper())
            if vkey not in TIMING_VARIANTS:
                continue
            vtitle, vfile, _vshort = TIMING_VARIANTS[vkey]
            hword = _timing_variant_heading_word(vkey)
            hword_lc = hword.lower()
            if do_reverse:
                _lq, _lev, _rq, _rev = hword_lc, to_ev, "first", from_ev
            else:
                _lq, _lev, _rq, _rev = "first", from_ev, hword_lc, to_ev
            parts.append(
                f"<h4>Time from {html.escape(_lq)} {html.escape(_event_pairwise_label(_lev))}"
                f" to {html.escape(_rq)} {html.escape(_event_pairwise_label(_rev))}"
                f" (anchored on {html.escape(_event_pairwise_label(from_ev))})</h4>"
            )
            c_html = _focus_pair_commentary_html(plot_row.get("commentary"))
            if c_html:
                parts.append(c_html)
            tdf, _missing = _read_timing_variant_df(rd, vkey, vfile)
            if tdf is None:
                parts.append(
                    f"<p class='subtle'><i>Not found: <code>{html.escape(_missing or vfile)}</code></i></p>"
                )
                continue
            fc = _resolve_col(tdf, "from_event")
            tc = _resolve_col(tdf, "to_event")
            if not fc or not tc:
                parts.append("<p class='subtle'><i>Missing FROM/TO columns.</i></p>")
                continue
            sel = tdf[
                tdf[fc].astype(str).str.upper().eq(from_ev.upper())
                & tdf[tc].astype(str).str.upper().eq(to_ev.upper())
            ]
            if sel.empty:
                parts.append("<p class='subtle'><i>No row for this pair in this timing export.</i></p>")
                continue
            r = sel.iloc[0]
            n_pair_c = _resolve_col(tdf, "n_patients_with_pair")
            med_c = _resolve_col(tdf, "median_days") or _resolve_col(tdf, "p50_days")
            lq_c = _resolve_col(tdf, "lq_days") or _resolve_col(tdf, "p25_days")
            uq_c = _resolve_col(tdf, "uq_days") or _resolve_col(tdf, "p75_days")
            median_iqr_txt: str | None = None
            if med_c and lq_c and uq_c and med_c in r.index and lq_c in r.index and uq_c in r.index:
                rm = _round_day_int(r[med_c])
                rlq = _round_day_int(r[lq_c])
                ruq = _round_day_int(r[uq_c])
                if rm is not None and rlq is not None and ruq is not None:
                    if do_reverse:
                        rm, rlq, ruq = -rm, -ruq, -rlq
                    median_iqr_txt = f"{rm:d} ({rlq:d}–{ruq:d})"
            parts.append(
                _timing_pair_summary_row_html(
                    from_ev=to_ev if do_reverse else from_ev,
                    to_ev=from_ev if do_reverse else to_ev,
                    n_from=n_from,
                    n_pair=(r[n_pair_c] if n_pair_c and n_pair_c in r.index else pd.NA),
                    median_iqr=median_iqr_txt,
                )
            )
            n_pair_val: int | None = None
            try:
                if n_pair_c and n_pair_c in r.index and pd.notna(r[n_pair_c]):
                    tmp = int(float(r[n_pair_c]))
                    if tmp > 0:
                        n_pair_val = tmp
            except Exception:
                n_pair_val = None
            fig_one = _timing_pair_single_row_plot(
                tdf,
                from_ev=from_ev,
                to_ev=to_ev,
                plot_mode=focus_timing_plot,
                reverse=do_reverse,
                x_range=x_range,
            )
            if fig_one is None:
                parts.append("<p class='subtle'><i>Could not build plot.</i></p>")
                continue
            ecc_id = "ecc_" + _slug(from_ev, to_ev, vkey)
            parts.append(
                f"<p class='subtle'><a href='#{html.escape(ecc_id)}'>Event code counts (top {int(EVENT_CODE_COUNTS_TOP_N)}) →</a></p>"
            )
            parts.append(
                "<div class='plot-wrap'>"
                + _fig_to_div(fig_one, include_plotlyjs=need_plotly_cdn)
                + "</div>"
            )
            parts.append(_plot_abbrev_note_html())
            need_plotly_cdn = False

            ecc_df = _event_code_counts_topn_for_timing_pair(
                rd,
                from_ev=from_ev,
                to_ev=to_ev,
                ecc_spec=ecc_spec,
                to_denoms=to_denoms,
                denom_override=n_pair_val,
                top_n=EVENT_CODE_COUNTS_TOP_N,
            )
            if ecc_df is None or ecc_df.empty:
                ecc_html = "<p class='subtle'><i>No matching event code counts available.</i></p>"
            else:
                tbl = ecc_df.to_html(index=False, border=0, classes="report-table")
                tbl = tbl.replace('class="dataframe report-table"', 'class="report-table"', 1)
                ecc_html = tbl
            ecc_blocks.append(
                (
                    ecc_id,
                    f"<div id='{html.escape(ecc_id)}' class='card stack'>"
                    f"<h3>Event code counts (top {int(EVENT_CODE_COUNTS_TOP_N)}): {html.escape(_event_display_name(from_ev))} → {html.escape(hword)} {html.escape(_event_display_name(to_ev))}</h3>"
                    f"<p class='subtle'>{_ecc_link_caption_html(ecc_spec, from_ev, rd)}. "
                    f"Family={html.escape(to_ev.upper())}. "
                    f"% is N_PATIENTS / N(pair) from the timing-pair row "
                    f"({html.escape(_event_display_name(from_ev))}→{html.escape(_event_display_name(to_ev))}; {html.escape(vtitle)})."
                    f"</p>"
                    f"{ecc_html}</div>",
                )
            )
        parts.append("</div>")

    parts.append("</div>")

    # Appendix: linked event-code-count tables.
    parts.append("<div class='section card stack'>")
    parts.append("<h2>Event code counts (linked)</h2>")
    dual_ecc = _results_have_dual_event_code_timing(rd)
    if dual_ecc:
        parts.append(
            f"<p class='subtle'>These tables are linked from the focus timing plots above. Top {int(EVENT_CODE_COUNTS_TOP_N)} concepts only.</p>"
            "<p class='subtle'><b>Concept-level timing:</b> CSVs include both <b>FIRST</b> and <b>CLOSEST</b> triples. "
            "Each linked table picks the triple that matches its timing variant (see per-table caption). "
            "In before/after time windows the per-patient choice is made separately within each "
            "<code>time_window</code> stratum. One patient can appear on multiple concept rows.</p>"
        )
    else:
        _rule, _xnote = _event_code_occurrence_rule_sentences()
        parts.append(
            f"<p class='subtle'>These tables are linked from the focus timing plots above. Top {int(EVENT_CODE_COUNTS_TOP_N)} concepts only.</p>"
            f"<p class='subtle'><b>Concept-level timing:</b> {_rule} "
            f"{_xnote} "
            "Align this report with your run via <code>EVENT_CODE_TIMING_USES_CLOSEST</code> in "
            "<code>build_summary_html_report.py</code> or env <code>CHARACTERIZATION_EVENT_CODE_TIMING_USES_CLOSEST</code>. "
            "In before/after time windows the per-patient choice is made separately within each "
            "<code>time_window</code> stratum. One patient can appear on multiple concept rows.</p>"
        )
    if not ecc_blocks:
        parts.append("<p class='subtle'><i>No linked tables generated.</i></p>")
    else:
        for _id, block_html in ecc_blocks:
            parts.append(block_html)
    parts.append("</div>")

    # Deaths
    parts.append("<div class='section card stack'>")
    parts.append("<h2>Deaths</h2>")
    parts.append(
        "<p class='subtle'>By year: % deaths for main cancer diagnosis index (INDEX) vs metastasis index (FIRST_MET).</p>"
    )
    deaths_path = rd / "final_death_from_anchors.csv"
    if not deaths_path.exists():
        parts.append("<p class='subtle'><i>Not found: <code>final_death_from_anchors.csv</code></i></p>")
    else:
        ddf = pd.read_csv(deaths_path)
        ddf = _with_death_pct_for_report(ddf)
        year_col = _resolve_col(ddf, "prevalence_year")
        if year_col:
            overall_mask = ddf[year_col].astype(str).str.upper().eq("OVERALL")
            by_year = ddf[~overall_mask].copy()
        else:
            by_year = ddf.copy()

        fig_cmp = _deaths_pct_compare_figure(by_year)
        if fig_cmp is None:
            parts.append("<p class='subtle'><i>Could not build plot.</i></p>")
        else:
            parts.append(
                "<div class='plot-wrap'>"
                + _fig_to_div(fig_cmp, include_plotlyjs=need_plotly_cdn)
                + "</div>"
            )
            parts.append(_plot_abbrev_note_html())
            need_plotly_cdn = False
        tbl_html = _death_timing_table_html(ddf)
        if tbl_html:
            parts.append(
                "<p class='subtle'>Overall and 2015 onwards. "
                "Deaths in/outside observation period; timing from anchor date. "
                "Suppressed cells shown as —.</p>"
            )
            parts.append(tbl_html)
    parts.append("</div>")

    parts.extend(["</body></html>"])
    out_path.write_text("\n".join(parts), encoding="utf-8")
    return out_path


if __name__ == "__main__":
    import argparse

    ap = argparse.ArgumentParser(
        description="Build a readable HTML summary (figures + compact tables) from characterization CSVs."
    )
    ap.add_argument(
        "--results-dir",
        default=None,
        metavar="DIR",
        help="Folder containing final_*.csv (default: outputs/). "
        "Overrides env CHARACTERIZATION_RESULTS_DIR when set.",
    )
    ap.add_argument(
        "--focus-timing-plot",
        default="hist",
        choices=["box", "hist", "both"],
        help="Focus timing plot style: boxplot only (box), P05–P95 decile density (hist, default) when columns allow, or both.",
    )
    ap.add_argument(
        "--event-code-timing-uses-closest",
        action="store_true",
        help="Assume SQL was run with @event_code_timing_uses_closest=1 (concept-level CLOSEST). "
        "Sets env CHARACTERIZATION_EVENT_CODE_TIMING_USES_CLOSEST=1 for this run.",
    )
    args = ap.parse_args()
    if args.event_code_timing_uses_closest:
        os.environ["CHARACTERIZATION_EVENT_CODE_TIMING_USES_CLOSEST"] = "1"
    results_dir = args.results_dir or os.environ.get("CHARACTERIZATION_RESULTS_DIR")
    path = build_summary_report(results_dir=results_dir, focus_timing_plot=args.focus_timing_plot)
    print(f"Wrote: {path}")
