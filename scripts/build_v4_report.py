#!/usr/bin/env python3
"""Build the v4 oncology characterisation HTML report."""
from __future__ import annotations

import html as _html
import math
import os
import sys
from pathlib import Path
from typing import Any

import pandas as pd
import plotly.graph_objects as go

BASE_DIR = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE_DIR))

# ── Output defaults ─────────────────────────────────────────────────────────────
OUTPUTS_DIR = BASE_DIR / "outputs_v2"
OUT_FILE = "summary_report_v4.html"

# ── Display constants ───────────────────────────────────────────────────────────
PREVALENCE_YEAR_MIN = 2010
SYMLOG_LINTHRESH = 180.0
ANCHOR_DX_TOP_N = 10
CODE_COUNTS_TOP_N = 15

# Direction category display order and labels
_DIR_ORDER = [
    "BEFORE_GT90", "BEFORE_1_90", "SAME_DAY",
    "AFTER_1_30", "AFTER_31_90", "AFTER_91_365", "AFTER_GT365", "NO_EVENT",
]
_DIR_LABELS = {
    "BEFORE_GT90":  ("before", "> 90 d before DX"),
    "BEFORE_1_90":  ("before", "1–90 d before DX"),
    "SAME_DAY":     ("same",   "Same calendar day"),
    "AFTER_1_30":   ("after",  "1–30 d after DX"),
    "AFTER_31_90":  ("after",  "31–365 d after DX"),
    "AFTER_91_365": ("after",  "31–365 d after DX"),
    "AFTER_GT365":  ("after",  "> 365 d after DX"),
    "NO_EVENT":     ("none",   "No event recorded"),
}
_MET_L01_DIR_LABELS = {
    "BEFORE_GT90":  ("before", "L01 > 90 d before MET"),
    "BEFORE_1_90":  ("before", "L01 1–90 d before MET"),
    "SAME_DAY":     ("same",   "Same day"),
    "AFTER_1_30":   ("after",  "L01 within 30 d after MET"),
    "AFTER_31_90":  ("after",  "L01 31–90 d after MET"),
    "AFTER_91_365": ("after",  "L01 91–365 d after MET"),
    "AFTER_GT365":  ("after",  "L01 > 365 d after MET"),
    "NO_EVENT":     ("none",   "No L01 ever recorded"),
}

# ── Column resolution ───────────────────────────────────────────────────────────

def _col(df: pd.DataFrame, name: str) -> str | None:
    nl = name.lower()
    for c in df.columns:
        if str(c).lower() == nl:
            return str(c)
    return None


def _read(rd: Path, fname: str) -> pd.DataFrame | None:
    p = rd / fname
    if not p.exists():
        return None
    try:
        return pd.read_csv(p)
    except Exception:
        return None


# ── Number utilities ────────────────────────────────────────────────────────────

def _infer_min_cell(df: pd.DataFrame, cols: list[str | None]) -> int:
    env = os.environ.get("MIN_CELL_COUNT", "").strip()
    if env:
        try:
            return max(0, int(env))
        except ValueError:
            pass
    m = 0
    for c in cols:
        if not c or c not in df.columns:
            continue
        s = pd.to_numeric(df[c], errors="coerce")
        neg = s[s < 0]
        if not neg.empty:
            m = max(m, int((-neg).max()))
    return m


def _safe_int(v: object) -> int | None:
    if v is None:
        return None
    try:
        if pd.isna(v):
            return None
    except TypeError:
        pass
    try:
        return int(float(v))
    except (TypeError, ValueError):
        return None


def _round_day(v: object) -> int | None:
    n = _safe_int(v)
    if n is None:
        return None
    try:
        x = float(v)  # type: ignore[arg-type]
        return int(round(x))
    except Exception:
        return None


def _symlog(v: float) -> float:
    t = SYMLOG_LINTHRESH
    ax = abs(v)
    if ax <= t:
        return v / t
    return (1.0 if v > 0 else -1.0) * (1.0 + math.log10(ax / t))


def _scaled_ticks(max_abs: float) -> tuple[list[float], list[str]]:
    anchors = [30, 60, 90, 180, 365, 730, 1460, 1920]
    raw = [float(a) for a in anchors if float(a) <= max_abs]
    raws = [-v for v in reversed(raw)] + [0.0] + raw
    return [_symlog(v) for v in raws], [str(int(v)) for v in raws]


def _fmt_n(n: object) -> str:
    i = _safe_int(n)
    if i is None or i < 0:
        return "—"
    return f"{i:,}"


def _fmt_pct(p: object, *, digits: int = 1) -> str:
    try:
        if pd.isna(p):
            return "—"
        return f"{float(p):.{digits}f}%"
    except Exception:
        return "—"


def _pct_of(n: object, den: object) -> str:
    ni = _safe_int(n)
    di = _safe_int(den)
    if ni is None or di is None or ni < 0 or di <= 0:
        return "—"
    return f"{100.0 * ni / di:.1f}%"


def _fmt_iqr(med: object, lq: object, uq: object) -> str:
    m = _round_day(med)
    l = _round_day(lq)
    u = _round_day(uq)
    if m is None:
        return "—"
    if l is None or u is None:
        return str(m)
    return f"{m:,} ({l:,}–{u:,})"


# ── Concept name lookup ─────────────────────────────────────────────────────────

def _fetch_concept_names(ids: list[int]) -> dict[int, str]:
    if not ids:
        return {}
    try:
        from db_adapter import get_adapter, get_connection  # type: ignore[import]
    except ImportError:
        return {}
    id_list = ", ".join(str(int(x)) for x in sorted(set(ids)))
    qc = get_adapter().qualified_table("concept")
    sql = f"SELECT concept_id, concept_name FROM {qc} WHERE concept_id IN ({id_list})"
    conn = get_connection()
    cur = conn.cursor()
    try:
        cur.execute(sql)
        return {int(r[0]): str(r[1]) for r in cur.fetchall()}
    except Exception:
        return {}
    finally:
        cur.close()
        conn.close()


# ── HTML component helpers ──────────────────────────────────────────────────────

def _e(s: object) -> str:
    return _html.escape(str(s))


def _stat_box(val: str, label: str, *, pct: str = "", cls: str = "") -> str:
    pct_html = f'<span class="stat-pct">{_e(pct)}</span>' if pct else ""
    cls_attr = f' {cls}' if cls else ""
    return (
        f'<div class="stat-box{cls_attr}">'
        f'<span class="stat-val">{_e(val)}</span>{pct_html}'
        f'<div class="stat-label">{_e(label)}</div></div>'
    )


def _signal(msg: str, *, cls: str = "blue", icon: str = "ℹ") -> str:
    return (
        f'<div class="signal {cls}">'
        f'<span class="signal-icon">{icon}</span>'
        f'<span>{msg}</span></div>'
    )


def _card(title: str, body: str) -> str:
    return (
        f'<div class="card">'
        f'<div class="card-title">{title}</div>'
        f'{body}</div>'
    )


def _card_grid(*cards: str, cols: int = 4) -> str:
    inner = "\n".join(cards)
    return f'<div class="card-grid card-grid-{cols}" style="margin-bottom:16px;">{inner}</div>'


def _plot_box(title: str, div: str, *, badge: str = "") -> str:
    badge_html = f' <span class="badge badge-new">{badge}</span>' if badge else ""
    return (
        f'<div class="plot-box">'
        f'<div class="plot-header">'
        f'<span class="plot-header-title">{_e(title)}{badge_html}</span>'
        f'</div>'
        f'<div class="plot-area">{div}</div>'
        f'</div>'
    )


def _section(num: str, title: str, desc: str, body: str, *, sid: str) -> str:
    return (
        f'<section class="section" id="{sid}">'
        f'<div class="section-header">'
        f'<span class="section-num">§ {num}</span>'
        f'<h2 class="section-title">{_e(title)}</h2>'
        f'</div>'
        f'<div class="section-divider"></div>'
        f'<p class="section-desc">{_e(desc)}</p>'
        f'{body}'
        f'</section>'
    )


def _tbl_wrap(inner: str) -> str:
    return f'<div class="tbl-wrap">{inner}</div>'


def _rt_table(headers: list[tuple[str, str]], rows: list[list[str]]) -> str:
    """Build a table.rt. headers: list of (text, css_class)."""
    th = "".join(f'<th class="{c}">{h}</th>' for h, c in headers)
    trs = ""
    for row in rows:
        trs += "<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>"
    return f'<table class="rt"><thead><tr>{th}</tr></thead><tbody>{trs}</tbody></table>'


def _dir_badge(cls: str, text: str) -> str:
    return f'<span class="dir-badge dir-{cls}">{_e(text)}</span>'


def _badge(text: str, cls: str = "new") -> str:
    return f'<span class="badge badge-{cls}">{_e(text)}</span>'


# ── Plotly utilities ────────────────────────────────────────────────────────────

_plotly_included = False


def _fig_div(fig: go.Figure) -> str:
    global _plotly_included
    inc = not _plotly_included
    if inc:
        _plotly_included = True
    return fig.to_html(
        include_plotlyjs="cdn" if inc else False,
        full_html=False,
        config={"displayModeBar": False, "responsive": True},
    )


def _plotly_base_layout() -> dict[str, Any]:
    return {
        "template": "plotly_white",
        "margin": dict(l=48, r=48, t=36, b=48),
        "legend": dict(orientation="h", yanchor="bottom", y=1.02, xanchor="right", x=1),
        "font": dict(family="IBM Plex Sans, sans-serif", size=12),
    }


# ── Chart: yearly prevalence ─────────────────────────────────────────────────────

def _prevalence_chart(df: pd.DataFrame) -> go.Figure | None:
    yc = _col(df, "prevalence_year")
    nc = _col(df, "n_dx")
    if not yc or not nc:
        return None
    sub = df.copy()
    sub["__y"] = pd.to_numeric(sub[yc].astype(str), errors="coerce")
    sub = sub.dropna(subset=["__y"]).sort_values("__y")
    sub = sub[sub["__y"] >= PREVALENCE_YEAR_MIN]
    years = sub["__y"].astype(int)
    ndx = pd.to_numeric(sub[nc], errors="coerce")

    def _pct_series(col_name: str) -> pd.Series | None:
        c = _col(sub, col_name)
        if not c:
            return None
        num = pd.to_numeric(sub[c], errors="coerce")
        denom = pd.to_numeric(sub[nc], errors="coerce")
        return (num / denom * 100).where((num >= 0) & (denom > 0))

    fig = go.Figure()
    fig.add_trace(go.Bar(
        x=years, y=ndx, name="DX cohort (N)",
        marker_color="#1a3a5c", opacity=0.8,
    ))
    colors = {"n_met": ("#b45309", None), "n_l01": ("#166534", "dot"), "n_odx": ("#7c3aed", "dash")}
    names = {"n_met": "% Metastasis (MET)", "n_l01": "% Antineoplastic (L01)", "n_odx": "% Other cancer DX (ODX)"}
    for cname, (color, dash) in colors.items():
        s = _pct_series(cname)
        if s is None:
            continue
        line = dict(color=color, width=2)
        if dash:
            line["dash"] = dash
        fig.add_trace(go.Scatter(
            x=years, y=s, name=names[cname],
            mode="lines+markers", yaxis="y2", line=line,
            marker=dict(size=6, color=color),
        ))
    layout = _plotly_base_layout()
    layout.update({
        "yaxis": dict(title="N patients", gridcolor="#e5e7eb"),
        "yaxis2": dict(title="% of DX cohort", overlaying="y", side="right", showgrid=False, rangemode="tozero"),
        "xaxis": dict(title="Calendar year", dtick=2),
        "hovermode": "x unified",
        "height": 380,
    })
    fig.update_layout(**layout)
    return fig


# ── Chart: timing distribution ───────────────────────────────────────────────────

def _timing_box_chart(
    df: pd.DataFrame,
    pairs: list[tuple[str, str]],
    timing_type: str = "first_to_first",
    *,
    title: str = "",
) -> go.Figure | None:
    ttc = _col(df, "timing_type")
    fc = _col(df, "from_event")
    tc = _col(df, "to_event")
    if not fc or not tc:
        return None

    sub = df.copy()
    if ttc:
        sub = sub[sub[ttc].astype(str).str.lower() == timing_type.lower()]

    quantile_cols = ["p05_days", "p10_days", "p20_days", "p25_days", "p30_days",
                     "p40_days", "p50_days", "p60_days", "p70_days", "p75_days",
                     "p80_days", "p90_days", "p95_days"]

    fig = go.Figure()
    colors = ["#1a3a5c", "#b45309", "#166534", "#7c3aed", "#991b1b"]
    any_data = False
    all_raw: list[float] = []

    for i, (from_ev, to_ev) in enumerate(pairs):
        sel = sub[
            sub[fc].astype(str).str.upper().eq(from_ev.upper()) &
            sub[tc].astype(str).str.upper().eq(to_ev.upper())
        ]
        if sel.empty:
            continue
        row = sel.iloc[0]

        def _num(c: str) -> float | None:
            col = _col(sel, c)
            if not col:
                return None
            v = pd.to_numeric(row.get(col), errors="coerce")
            return None if pd.isna(v) else float(v)

        med = _num("p50_days")
        lq = _num("p25_days")
        uq = _num("p75_days")
        p10 = _num("p10_days")
        p90 = _num("p90_days")
        if med is None:
            continue

        color = colors[i % len(colors)]
        label = f"{from_ev} → {to_ev}"

        for v in [p10, lq, med, uq, p90]:
            if v is not None:
                all_raw.append(v)

        fig.add_trace(go.Box(
            name=label,
            q1=[lq] if lq is not None else [med],
            median=[med],
            q3=[uq] if uq is not None else [med],
            lowerfence=[p10] if p10 is not None else [lq or med],
            upperfence=[p90] if p90 is not None else [uq or med],
            mean=[med],
            orientation="h",
            marker_color=color,
            line_color=color,
            fillcolor=color,
            opacity=0.7,
        ))
        any_data = True

    if not any_data:
        return None

    max_abs = max((abs(v) for v in all_raw), default=365.0)
    tickvals, ticktext = _scaled_ticks(max_abs)

    layout = _plotly_base_layout()
    layout.update({
        "xaxis": dict(
            title="Days (negative = event before anchor)",
            tickmode="array", tickvals=tickvals, ticktext=ticktext,
            zeroline=True, zerolinecolor="#9ca3af", zerolinewidth=1.5,
            gridcolor="#e5e7eb",
        ),
        "height": max(200, 80 + len(pairs) * 60),
        "showlegend": False,
        "title": dict(text=title, font=dict(size=13)) if title else None,
    })
    fig.update_layout(**layout)
    return fig


# ── Chart: L01 treatment windows ────────────────────────────────────────────────

def _l01_windows_chart(df: pd.DataFrame) -> go.Figure | None:
    ac = _col(df, "anchor_event")
    wc = _col(df, "window_index")
    lc = _col(df, "n_patients_with_l01")
    oc = _col(df, "n_observed")
    if not ac or not wc or not lc:
        return None

    fig = go.Figure()
    colors = {"INDEX": "#1a3a5c", "FIRST_MET": "#b45309"}

    for anchor in ["INDEX", "FIRST_MET"]:
        sub = df[df[ac].astype(str).str.upper() == anchor].copy()
        if sub.empty:
            continue
        wi = pd.to_numeric(sub[wc], errors="coerce")
        nl01 = pd.to_numeric(sub[lc], errors="coerce")
        denom = pd.to_numeric(sub[oc], errors="coerce") if oc else None

        # Compute pct
        if denom is not None:
            pct = (nl01 / denom * 100).where((nl01 >= 0) & (denom > 0))
        else:
            pct = nl01.where(nl01 >= 0)

        valid = pd.DataFrame({"wi": wi, "pct": pct}).dropna()
        if valid.empty:
            continue

        fig.add_trace(go.Scatter(
            x=valid["wi"] * 30,
            y=valid["pct"],
            name=anchor,
            mode="lines+markers",
            marker=dict(size=5),
            line=dict(color=colors.get(anchor, "#1a3a5c"), width=2),
        ))

    layout = _plotly_base_layout()
    layout.update({
        "xaxis": dict(title="Days from anchor (DX or first MET)", zeroline=True, zerolinecolor="#9ca3af"),
        "yaxis": dict(title="% with ≥1 L01 in 30-day window", rangemode="tozero"),
        "height": 340,
    })
    fig.update_layout(**layout)
    return fig


# ── Chart: gap bucket bars ────────────────────────────────────────────────────

def _gap_bucket_chart(df: pd.DataFrame, *, n_col: str = "n_gaps", group_col: str | None = "subgroup") -> go.Figure | None:
    bc = _col(df, "gap_bucket")
    nc = _col(df, n_col) or _col(df, "n_patients")
    if not bc or not nc:
        return None

    bucket_order = ["lt30d", "30_59d", "60_89d", "90_179d", "180_364d", "365_729d", "ge365d", "ge730d"]

    fig = go.Figure()
    colors = {"ALL_L01": "#1a3a5c", "MET_L01": "#b45309", None: "#1a3a5c"}

    if group_col and _col(df, group_col):
        gc = _col(df, group_col)
        groups = df[gc].dropna().unique().tolist()
    else:
        groups = [None]
        gc = None

    for g in groups:
        sub = df[df[gc] == g].copy() if gc and g is not None else df.copy()
        vals = sub.set_index(bc)[nc] if bc in sub.columns else sub.set_index(_col(sub, "gap_bucket"))[nc]
        ordered_buckets = [b for b in bucket_order if b in vals.index]
        ordered_vals = [max(0, int(pd.to_numeric(vals.get(b, 0), errors="coerce") or 0)) for b in ordered_buckets]
        name = str(g) if g is not None else "all"
        fig.add_trace(go.Bar(
            x=ordered_buckets, y=ordered_vals,
            name=name, marker_color=colors.get(str(g) if g else None, "#166534"),
            opacity=0.85,
        ))

    layout = _plotly_base_layout()
    layout.update({
        "xaxis": dict(title="Gap bucket"),
        "yaxis": dict(title="N gaps", gridcolor="#e5e7eb"),
        "height": 300,
        "barmode": "group",
    })
    fig.update_layout(**layout)
    return fig


# ── Chart: deaths inside vs outside obs period ───────────────────────────────────

def _death_obs_chart(df: pd.DataFrame) -> go.Figure | None:
    yc = _col(df, "prevalence_year")
    ac = _col(df, "anchor_event")
    nc = _col(df, "n_patients")
    nd = _col(df, "n_deaths")
    nio = _col(df, "n_deaths_in_obs")
    noo = _col(df, "n_deaths_out_obs")
    if not yc or not ac or not nd or not nc:
        return None

    idx_sub = df[(df[ac].astype(str).str.upper() == "INDEX") & (df[yc].astype(str).str.upper() != "OVERALL")].copy()
    if idx_sub.empty:
        return None
    idx_sub["__y"] = pd.to_numeric(idx_sub[yc].astype(str), errors="coerce")
    idx_sub = idx_sub.dropna(subset=["__y"]).sort_values("__y")
    idx_sub = idx_sub[idx_sub["__y"] >= PREVALENCE_YEAR_MIN]
    years = idx_sub["__y"].astype(int)

    ndeath = pd.to_numeric(idx_sub[nd], errors="coerce")
    npat = pd.to_numeric(idx_sub[nc], errors="coerce")
    pct_dead = (ndeath / npat * 100).where((ndeath >= 0) & (npat > 0))

    fig = go.Figure()
    fig.add_trace(go.Bar(x=years, y=npat, name="N DX", marker_color="#1a3a5c", opacity=0.6))
    fig.add_trace(go.Scatter(x=years, y=pct_dead, name="% Deceased",
                             mode="lines+markers", yaxis="y2",
                             line=dict(color="#991b1b", width=2),
                             marker=dict(size=6, color="#991b1b")))

    if nio and noo:
        nin = pd.to_numeric(idx_sub[nio], errors="coerce")
        nout = pd.to_numeric(idx_sub[noo], errors="coerce")
        pct_in = (nin / ndeath * 100).where((nin >= 0) & (ndeath > 0))
        pct_out = (nout / ndeath * 100).where((nout >= 0) & (ndeath > 0))
        fig.add_trace(go.Scatter(x=years, y=pct_in, name="% Deaths in obs. period",
                                 mode="lines+markers", yaxis="y2",
                                 line=dict(color="#166534", width=2, dash="dot"),
                                 marker=dict(size=5, color="#166534")))
        fig.add_trace(go.Scatter(x=years, y=pct_out, name="% Deaths outside obs. period",
                                 mode="lines+markers", yaxis="y2",
                                 line=dict(color="#b45309", width=2, dash="dash"),
                                 marker=dict(size=5, color="#b45309")))

    layout = _plotly_base_layout()
    layout.update({
        "yaxis": dict(title="N patients", gridcolor="#e5e7eb"),
        "yaxis2": dict(title="%", overlaying="y", side="right", showgrid=False, rangemode="tozero"),
        "xaxis": dict(title="Index year", dtick=2),
        "hovermode": "x unified",
        "height": 360,
    })
    fig.update_layout(**layout)
    return fig


# ── Chart: timing metrics by year (multi-line) ──────────────────────────────────

def _timing_by_year_chart(df: pd.DataFrame) -> go.Figure | None:
    ttc = _col(df, "timing_type")
    fc = _col(df, "from_event")
    tc = _col(df, "to_event")
    yc = _col(df, "index_year")
    mc = _col(df, "p50_days")
    if not fc or not tc or not yc or not mc:
        return None

    fig = go.Figure()
    targets = [
        ("first_to_first", "DX", "MET", "#1a3a5c", None, "DX→MET (median)"),
        ("first_to_first", "MET", "L01", "#166534", "dot", "MET→L01 (median)"),
    ]
    any_data = False
    for ttype, from_ev, to_ev, color, dash, name in targets:
        sub = df.copy()
        if ttc:
            sub = sub[sub[ttc].astype(str).str.lower() == ttype]
        sub = sub[
            sub[fc].astype(str).str.upper().eq(from_ev) &
            sub[tc].astype(str).str.upper().eq(to_ev)
        ].copy()
        sub["__y"] = pd.to_numeric(sub[yc].astype(str), errors="coerce")
        sub = sub.dropna(subset=["__y"]).sort_values("__y")
        sub = sub[sub["__y"] >= PREVALENCE_YEAR_MIN]
        med = pd.to_numeric(sub[mc], errors="coerce")
        valid = pd.DataFrame({"y": sub["__y"].astype(int), "med": med}).dropna()
        if valid.empty:
            continue
        line_kw: dict[str, Any] = {"color": color, "width": 2}
        if dash:
            line_kw["dash"] = dash
        fig.add_trace(go.Scatter(
            x=valid["y"], y=valid["med"],
            name=name, mode="lines+markers",
            line=line_kw, marker=dict(size=6, color=color),
        ))
        any_data = True

    if not any_data:
        return None

    layout = _plotly_base_layout()
    layout.update({
        "xaxis": dict(title="Index year", dtick=2),
        "yaxis": dict(title="Median days (first→first)", gridcolor="#e5e7eb"),
        "height": 320,
        "hovermode": "x unified",
    })
    fig.update_layout(**layout)
    return fig


# ── Section 0: Overview ──────────────────────────────────────────────────────────

def _s00_overview(rd: Path) -> str:
    prev = _read(rd, "final_population_prevalence.csv")
    demo = _read(rd, "final_demographics_from_anchors.csv")
    dx_counts = _read(rd, "final_anchor_dx_concept_counts.csv")

    parts: list[str] = []

    # ── Stat boxes ──────────────────────────────────────────────────────────────
    n_dx = n_met = n_l01 = n_odx = n_gdx = None
    age_med = age_lq = age_uq = pct_male = None
    min_cell = 0

    if prev is not None:
        oc = _col(prev, "prevalence_year")
        if oc:
            overall = prev[prev[oc].astype(str).str.upper() == "OVERALL"]
            if not overall.empty:
                row = overall.iloc[0]
                min_cell = _infer_min_cell(prev, [_col(prev, c) for c in ["n_dx", "n_met", "n_l01", "n_odx", "n_gdx"]])
                n_dx = _safe_int(row.get(_col(prev, "n_dx")))
                n_met = _safe_int(row.get(_col(prev, "n_met")))
                n_l01 = _safe_int(row.get(_col(prev, "n_l01")))
                n_odx = _safe_int(row.get(_col(prev, "n_odx")))
                n_gdx = _safe_int(row.get(_col(prev, "n_gdx")))

    if demo is not None:
        ac = _col(demo, "anchor_event")
        if ac:
            idx_row = demo[demo[ac].astype(str).str.upper() == "INDEX"]
            if not idx_row.empty:
                r = idx_row.iloc[0]
                age_med = r.get(_col(demo, "age_median_years"))
                age_lq = r.get(_col(demo, "age_lq_years"))
                age_uq = r.get(_col(demo, "age_uq_years"))
                pm = _col(demo, "pct_male")
                pct_male = r.get(pm) if pm else None

    def _pct_str(n: int | None, d: int | None) -> str:
        if n and d and d > 0:
            return f"{100 * n / d:.1f}%"
        return ""

    no_l01_pct = ""
    if n_dx and n_l01 is not None and n_dx > 0:
        no_l01_pct = f"{100 * (n_dx - max(0, n_l01)) / n_dx:.1f}%"

    age_str = "—"
    if age_med is not None:
        try:
            y = int(round(float(age_med)))
            yl = int(round(float(age_lq))) if age_lq is not None else None
            yu = int(round(float(age_uq))) if age_uq is not None else None
            age_str = f"{y} yrs"
            age_iqr = f"IQR {yl}–{yu}" if yl and yu else ""
        except Exception:
            age_str, age_iqr = "—", ""
    else:
        age_iqr = ""

    male_str = _fmt_pct(pct_male) if pct_male is not None else "—"

    parts.append(_card_grid(
        _stat_box(f"{n_dx:,}" if n_dx else "—", "DX cohort", cls="highlight"),
        _stat_box(_fmt_n(n_met), "Metastasis (MET)", pct=_pct_str(n_met, n_dx)),
        _stat_box(_fmt_n(n_l01), "Any L01 treatment", pct=_pct_str(n_l01, n_dx)),
        _stat_box(no_l01_pct, "No L01 ever (DX cohort)", cls="warn"),
        cols=4,
    ))
    parts.append(_card_grid(
        _stat_box(_fmt_n(n_odx), "Co-occurring other cancer (ODX)", pct=_pct_str(n_odx, n_dx)),
        _stat_box(_fmt_n(n_gdx), "Broader/non-specific DX (GDX)", pct=_pct_str(n_gdx, n_dx)),
        _stat_box(age_str, "Median age at DX", pct=age_iqr),
        _stat_box(male_str, "Sex (DX cohort)", pct="male"),
        cols=4,
    ))

    # ── Yearly prevalence chart ─────────────────────────────────────────────────
    if prev is not None:
        oc = _col(prev, "prevalence_year")
        if oc:
            yearly = prev[prev[oc].astype(str).str.upper() != "OVERALL"].copy()
            fig = _prevalence_chart(yearly)
            if fig:
                parts.append(_plot_box("Figure 0.1 — Population prevalence by calendar year", _fig_div(fig), badge="new"))

    # ── Demographics table ──────────────────────────────────────────────────────
    if demo is not None:
        ac = _col(demo, "anchor_event")
        nm = _col(demo, "n_patients") or _col(demo, "n_male")
        if ac and nm:
            rows = []
            for _, r in demo.iterrows():
                anchor = str(r.get(ac, ""))
                np_ = _safe_int(r.get(_col(demo, "n_patients") or ""))
                age_m = r.get(_col(demo, "age_median_years") or "")
                age_l = r.get(_col(demo, "age_lq_years") or "")
                age_u = r.get(_col(demo, "age_uq_years") or "")
                pm_ = r.get(_col(demo, "pct_male") or "")
                pf_ = r.get(_col(demo, "pct_female") or "")

                age_disp = "—"
                try:
                    am = int(round(float(age_m)))
                    al = int(round(float(age_l)))
                    au = int(round(float(age_u)))
                    age_disp = f"{am} ({al}–{au})"
                except Exception:
                    pass

                label = "Cancer of interest — first DX" if anchor.upper() == "INDEX" else "Metastasis — first MET"
                row_cls = ' class="highlight"' if anchor.upper() == "INDEX" else ""
                rows.append(
                    f'<tr{row_cls}>'
                    f'<td>{_e(label)}</td>'
                    f'<td class="num">{_fmt_n(np_)}</td>'
                    f'<td class="num">{_e(age_disp)}</td>'
                    f'<td class="num">{_fmt_pct(pm_)}</td>'
                    f'<td class="num">{_fmt_pct(pf_)}</td>'
                    f'</tr>'
                )
            if rows:
                tbl = (
                    '<table class="rt"><thead><tr>'
                    '<th>Anchor cohort</th>'
                    '<th class="num">N</th>'
                    '<th class="num">Median age (IQR)</th>'
                    '<th class="num">% Male</th>'
                    '<th class="num">% Female</th>'
                    '</tr></thead><tbody>'
                    + "\n".join(rows) +
                    '</tbody></table>'
                )
                parts.append(_card("Table 0.1 — Demographics by anchor cohort", _tbl_wrap(tbl)))

    # ── Top DX concept counts ────────────────────────────────────────────────────
    if dx_counts is not None:
        cid_col = _col(dx_counts, "concept_id")
        np_col = _col(dx_counts, "n_distinct_patients")
        nd_col = _col(dx_counts, "n_distinct_patient_days")
        if cid_col and np_col:
            top = dx_counts.copy()
            top["__n"] = pd.to_numeric(top[np_col], errors="coerce")
            top = top[top["__n"] > 0].nlargest(ANCHOR_DX_TOP_N, "__n")
            if not top.empty:
                ids = [int(x) for x in top[cid_col].dropna().astype(int).tolist()]
                names_map = _fetch_concept_names(ids)
                rows = []
                for i, (_, r) in enumerate(top.iterrows(), 1):
                    cid = _safe_int(r.get(cid_col))
                    cname = names_map.get(cid, "") if cid else ""
                    np_ = _safe_int(r.get(np_col))
                    nd_ = _safe_int(r.get(nd_col)) if nd_col else None
                    pct_ = _pct_of(np_, n_dx) if n_dx else "—"
                    nd_str = f"{nd_:,}" if nd_ and nd_ > 0 else "—"
                    rows.append(
                        f"<tr><td>{i}</td>"
                        f'<td><code>{_e(str(cid))}</code></td>'
                        f"<td>{_e(cname)}</td>"
                        f'<td class="num">{_fmt_n(np_)}</td>'
                        f'<td class="num">{nd_str}</td>'
                        f'<td class="num">{_e(pct_)}</td>'
                        f"</tr>"
                    )
                tbl = (
                    '<table class="rt"><thead><tr>'
                    '<th>#</th><th>Concept ID</th><th>Concept name</th>'
                    '<th class="num">Patients</th><th class="num">Patient-days</th><th class="num">% of DX cohort</th>'
                    '</tr></thead><tbody>' + "\n".join(rows) + '</tbody></table>'
                )
                parts.append(_card(
                    f"Table 0.2 — Top {ANCHOR_DX_TOP_N} anchor DX concepts (condition_occurrence)",
                    _tbl_wrap(tbl),
                ))

    return _section(
        "00", "Cohort Overview & Population Prevalence",
        "High-level counts and demographic profile. All percentages denominated on N_DX. "
        "Age and sex reported at anchor date.",
        "\n".join(parts), sid="s0",
    )


# ── Section 1: DX→MET Timing ────────────────────────────────────────────────────

def _directionality_table(df: pd.DataFrame, pair: str, dir_labels: dict) -> str:
    pc = _col(df, "pair")
    yc = _col(df, "index_year")
    dc = _col(df, "direction")
    nc = _col(df, "n_patients")
    if not all([pc, yc, dc, nc]):
        return ""
    sub = df[
        (df[pc].astype(str).str.upper() == pair.upper()) &
        (df[yc].astype(str).str.upper() == "OVERALL")
    ].copy()
    if sub.empty:
        return ""
    sub_map: dict[str, int] = {}
    for _, r in sub.iterrows():
        d = str(r[dc]).upper()
        n = _safe_int(r.get(nc))
        if d and n is not None:
            sub_map[d] = n
    total = sum(v for v in sub_map.values() if v and v > 0)
    rows = []
    for key in _DIR_ORDER:
        css_cls, label = dir_labels.get(key, ("none", key))
        n = sub_map.get(key)
        if n is None:
            continue
        pct = f"{100.0 * n / total:.1f}%" if total > 0 and n > 0 else ("—" if n == 0 else "—")
        badge_html = _dir_badge(css_cls, label)
        rows.append(
            f"<tr><td>{badge_html}</td>"
            f'<td class="num">{_fmt_n(n)}</td>'
            f'<td class="num">{pct}</td></tr>'
        )
    tbl = (
        '<table class="rt"><thead><tr>'
        '<th>Direction</th><th class="num">N patients</th><th class="num">% of pair</th>'
        '</tr></thead><tbody>' + "\n".join(rows) + '</tbody></table>'
    )
    return _tbl_wrap(tbl)


def _s01_dx_met_timing(rd: Path) -> str:
    timing = _read(rd, "final_timing_pairwise.csv")
    directionality = _read(rd, "final_directionality.csv")
    by_year = _read(rd, "final_timing_by_year.csv")

    parts: list[str] = []

    # Directionality table
    if directionality is not None:
        tbl = _directionality_table(directionality, "DX_MET", _DIR_LABELS)
        if tbl:
            parts.append(_card(
                f"Table 1.1 — DX ↔ MET temporal directionality {_badge('new')}",
                tbl + '<p class="tbl-note">OVERALL cohort. Suppressed rows hidden.</p>',
            ))

    # DX→MET timing distribution
    if timing is not None:
        fig = _timing_box_chart(timing, [("DX", "MET")], "first_to_first")
        if fig:
            parts.append(_plot_box("Figure 1.1 — DX → MET timing (first→first, IQR box)", _fig_div(fig)))

    # By-year heatmap (HTML table using hm-* classes)
    if by_year is not None:
        ttc = _col(by_year, "timing_type")
        fc = _col(by_year, "from_event")
        tc = _col(by_year, "to_event")
        yc = _col(by_year, "index_year")
        mc = _col(by_year, "p50_days")
        if all([fc, tc, yc, mc]):
            sub = by_year.copy()
            if ttc:
                sub = sub[sub[ttc].astype(str).str.lower() == "first_to_first"]
            sub = sub[
                sub[fc].astype(str).str.upper().eq("DX") &
                sub[tc].astype(str).str.upper().eq("MET")
            ].copy()
            sub["__y"] = pd.to_numeric(sub[yc].astype(str), errors="coerce")
            sub = sub[sub["__y"] >= PREVALENCE_YEAR_MIN].sort_values("__y")
            if not sub.empty:
                years = sub["__y"].astype(int).tolist()
                meds = pd.to_numeric(sub[mc], errors="coerce").tolist()
                valid_meds = [m for m in meds if not pd.isna(m)]
                if valid_meds:
                    mn, mx = min(valid_meds), max(valid_meds)
                    span = max(1, mx - mn)

                    def _hm_cls(v: float | None) -> str:
                        if v is None or pd.isna(v):
                            return "hm-0"
                        idx = int(5 * (v - mn) / span)
                        return f"hm-{min(5, max(1, idx))}"

                    cells = "".join(
                        f'<td class="{_hm_cls(m)}">{_round_day(m) if m is not None and not pd.isna(m) else "—"}</td>'
                        for m in meds
                    )
                    ths = "".join(f"<th>{y}</th>" for y in years)
                    tbl = (
                        '<div class="hm-wrap"><table class="hm-table"><thead><tr>'
                        f'<th class="row-head">DX→MET median days</th>{ths}'
                        f'</tr></thead><tbody><tr><td class="hm-table" style="text-align:left;">Median</td>{cells}</tr>'
                        '</tbody></table></div>'
                    )
                    parts.append(_card(
                        f"Figure 1.2 — DX→MET median days by index year {_badge('new')}",
                        tbl,
                    ))

    if not parts:
        parts.append('<p style="color:var(--text-3);font-style:italic;">Timing data not yet available.</p>')

    return _section(
        "01", "Disease Code Timing & Sequencing",
        "Temporal relationship between first cancer DX code and first metastasis code. "
        "Negative days = MET code precedes DX — a data provenance signal. "
        "Directionality counts show the clinical sequencing distribution.",
        "\n".join(parts), sid="s1",
    )


# ── Section 2: GDX/ODX ──────────────────────────────────────────────────────────

def _s02_gdx_odx(rd: Path) -> str:
    code_counts = _read(rd, "final_code_counts.csv")
    windowed = _read(rd, "final_windowed_odx_prevalence.csv")
    timing = _read(rd, "final_timing_pairwise.csv")
    prev = _read(rd, "final_population_prevalence.csv")
    n_dx = None
    if prev is not None:
        oc = _col(prev, "prevalence_year")
        if oc:
            o = prev[prev[oc].astype(str).str.upper() == "OVERALL"]
            if not o.empty:
                n_dx = _safe_int(o.iloc[0].get(_col(prev, "n_dx")))

    parts: list[str] = []

    # Top GDX concepts table from code_counts
    if code_counts is not None:
        ac = _col(code_counts, "anchor_event")
        fc = _col(code_counts, "event_family")
        twc = _col(code_counts, "time_window")
        cid_col = _col(code_counts, "concept_id")
        np_col = _col(code_counts, "n_patients")
        if all([ac, fc, twc, cid_col, np_col]):
            gdx = code_counts[
                (code_counts[ac].astype(str).str.upper() == "INDEX") &
                (code_counts[fc].astype(str).str.upper() == "GDX") &
                (code_counts[twc].astype(str).str.lower() == "all")
            ].copy()
            gdx["__n"] = pd.to_numeric(gdx[np_col], errors="coerce")
            gdx = gdx[gdx["__n"] > 0].nlargest(CODE_COUNTS_TOP_N, "__n")
            if not gdx.empty:
                ids = [int(x) for x in gdx[cid_col].dropna().astype(int).tolist()]
                names_map = _fetch_concept_names(ids)
                rows = []
                for i, (_, r) in enumerate(gdx.iterrows(), 1):
                    cid = _safe_int(r.get(cid_col))
                    cname = names_map.get(cid, "") if cid else ""
                    np_ = _safe_int(r.get(np_col))
                    pct_ = _pct_of(np_, n_dx) if n_dx else "—"
                    rows.append(
                        f"<tr><td>{i}</td>"
                        f'<td><code>{_e(str(cid))}</code></td>'
                        f"<td>{_e(cname)}</td>"
                        f'<td class="num">{_fmt_n(np_)}</td>'
                        f'<td class="num">{pct_}</td></tr>'
                    )
                tbl = (
                    '<table class="rt"><thead><tr>'
                    '<th>#</th><th>Concept ID</th><th>Concept name</th>'
                    '<th class="num">Patients (any time)</th><th class="num">% DX cohort</th>'
                    '</tr></thead><tbody>' + "\n".join(rows) + '</tbody></table>'
                )
                parts.append(_card(
                    f"Table 2.1 — Most frequent GDX concepts {_badge('new')}",
                    _tbl_wrap(tbl),
                ))

    # Windowed ODX prevalence table
    if windowed is not None:
        fc = _col(windowed, "event_family")
        cid_col = _col(windowed, "concept_id")
        ne = _col(windowed, "n_ever")
        n30 = _col(windowed, "n_pm30d")
        n90 = _col(windowed, "n_pm90d")
        n180 = _col(windowed, "n_pm180d")
        n1y = _col(windowed, "n_pm1yr")
        neb = _col(windowed, "n_ever_before")
        nea = _col(windowed, "n_ever_after")
        if all([fc, cid_col, ne]):
            odx = windowed[windowed[fc].astype(str).str.upper() == "ODX"].copy()
            odx["__n"] = pd.to_numeric(odx[ne], errors="coerce")
            odx = odx[odx["__n"] > 0].nlargest(10, "__n")
            if not odx.empty:
                ids = [int(x) for x in odx[cid_col].dropna().astype(int).tolist()]
                names_map = _fetch_concept_names(ids)
                win_cols = [
                    ("±30d", n30), ("±90d", n90), ("±180d", n180), ("±1yr", n1y),
                    ("Ever before", neb), ("Ever after", nea), ("Ever", ne),
                ]
                win_cols = [(lbl, c) for lbl, c in win_cols if c]
                header = (
                    '<table class="rt"><thead><tr>'
                    '<th>Concept</th>'
                    + "".join(f'<th class="num">{l}</th>' for l, _ in win_cols) +
                    '</tr></thead><tbody>'
                )
                rows = []
                for _, r in odx.iterrows():
                    cid = _safe_int(r.get(cid_col))
                    cname = names_map.get(cid, str(cid)) if cid else "?"
                    cells = "".join(
                        f'<td class="num">{_fmt_n(r.get(c))}</td>'
                        for _, c in win_cols
                    )
                    rows.append(f"<tr><td><code>{cid}</code> {_e(cname)}</td>{cells}</tr>")
                tbl = header + "\n".join(rows) + "</tbody></table>"
                parts.append(_card(
                    f"Table 2.2 — Windowed ODX prevalence relative to DX index date {_badge('new')}",
                    _tbl_wrap(tbl),
                ))

    # ODX timing distribution
    if timing is not None:
        fig = _timing_box_chart(timing, [("DX", "ODX"), ("ODX", "DX")], "first_to_first",
                                title="DX ↔ ODX (first→first)")
        if fig:
            parts.append(_plot_box("Figure 2.1 — DX ↔ ODX timing distribution", _fig_div(fig)))

    if not parts:
        parts.append('<p style="color:var(--text-3);font-style:italic;">GDX/ODX data not yet available.</p>')

    return _section(
        "02", "Broader & Co-occurring Cancer Codes (GDX / ODX)",
        "GDX (ancestor/broader codes of the DX concept set within malignant neoplastic disease) and ODX "
        "(co-occurring other cancer diagnoses, excluding DX and GDX). "
        "High ODX rates indicate patients with multiple malignancies; windowed prevalence shows "
        "whether co-occurring cancers cluster around the DX index date.",
        "\n".join(parts), sid="s2",
    )


# ── Section 3: Treatment Timing ──────────────────────────────────────────────────

def _s03_treatment_timing(rd: Path) -> str:
    timing = _read(rd, "final_timing_pairwise.csv")
    directionality = _read(rd, "final_directionality.csv")
    code_counts = _read(rd, "final_code_counts.csv")
    prev = _read(rd, "final_population_prevalence.csv")
    n_dx = None
    if prev is not None:
        oc = _col(prev, "prevalence_year")
        if oc:
            o = prev[prev[oc].astype(str).str.upper() == "OVERALL"]
            if not o.empty:
                n_dx = _safe_int(o.iloc[0].get(_col(prev, "n_dx")))

    parts: list[str] = []

    # MET→L01 directionality
    if directionality is not None:
        tbl = _directionality_table(directionality, "MET_L01", _MET_L01_DIR_LABELS)
        if tbl:
            parts.append(_card(
                f"Table 3.1 — MET ↔ L01 temporal directionality {_badge('new')}",
                tbl + '<p class="tbl-note">MET subgroup only. NO_EVENT = patients with MET but no L01 ever.</p>',
            ))

    # MET→L01 timing distribution
    if timing is not None:
        fig = _timing_box_chart(
            timing,
            [("MET", "L01"), ("MET", "L01")],
            "first_to_first",
        )
        if fig:
            parts.append(_plot_box("Figure 3.1 — MET → L01 timing (first→first)", _fig_div(fig)))

    # Drug-level L01 codes table (top 15 by FIRST_MET anchor)
    if code_counts is not None:
        ac = _col(code_counts, "anchor_event")
        fc = _col(code_counts, "event_family")
        twc = _col(code_counts, "time_window")
        cid_col = _col(code_counts, "concept_id")
        np_col = _col(code_counts, "n_patients")
        med_c = _col(code_counts, "median_days_first") or _col(code_counts, "median_days")
        lq_c = _col(code_counts, "lq_days_first") or _col(code_counts, "lq_days")
        uq_c = _col(code_counts, "uq_days_first") or _col(code_counts, "uq_days")
        if all([ac, fc, twc, cid_col, np_col]):
            l01 = code_counts[
                (code_counts[ac].astype(str).str.upper() == "FIRST_MET") &
                (code_counts[fc].astype(str).str.upper() == "L01") &
                (code_counts[twc].astype(str).str.lower() == "all")
            ].copy()
            l01["__n"] = pd.to_numeric(l01[np_col], errors="coerce")
            l01 = l01[l01["__n"] > 0].nlargest(CODE_COUNTS_TOP_N, "__n")
            if not l01.empty:
                ids = [int(x) for x in l01[cid_col].dropna().astype(int).tolist()]
                names_map = _fetch_concept_names(ids)
                rows = []
                for i, (_, r) in enumerate(l01.iterrows(), 1):
                    cid = _safe_int(r.get(cid_col))
                    cname = names_map.get(cid, "") if cid else ""
                    np_ = _safe_int(r.get(np_col))
                    pct_ = _pct_of(np_, n_dx) if n_dx else "—"
                    med = r.get(med_c) if med_c else None
                    lq = r.get(lq_c) if lq_c else None
                    uq = r.get(uq_c) if uq_c else None
                    iqr_str = _fmt_iqr(med, lq, uq)
                    rows.append(
                        f"<tr><td>{i}</td>"
                        f'<td><code>{_e(str(cid))}</code></td>'
                        f"<td>{_e(cname)}</td>"
                        f'<td class="num">{_fmt_n(np_)}</td>'
                        f'<td class="num">{pct_}</td>'
                        f'<td class="num">{_e(iqr_str)}</td></tr>'
                    )
                tbl = (
                    '<table class="rt"><thead><tr>'
                    '<th>#</th><th>Concept ID</th><th>Drug name</th>'
                    '<th class="num">N patients</th><th class="num">% DX cohort</th>'
                    '<th class="num">Median days (IQR) from MET</th>'
                    '</tr></thead><tbody>' + "\n".join(rows) + '</tbody></table>'
                )
                parts.append(_card(
                    f"Table 3.2 — Drug-level treatment timing around MET (top {CODE_COUNTS_TOP_N}) {_badge('expanded', 'partial')}",
                    _tbl_wrap(tbl),
                ))

    if not parts:
        parts.append('<p style="color:var(--text-3);font-style:italic;">Treatment timing data not yet available.</p>')

    return _section(
        "03", "Treatment Timing & Data Provenance Signals",
        "Full distribution of time from first MET to first antineoplastic treatment (ATC L01). "
        "The proportion where treatment was already underway before MET, and patients with no L01, "
        "are provenance signals — high 'no L01' likely reflects clinical trial enrollment "
        "where investigational drugs are invisible.",
        "\n".join(parts), sid="s3",
    )


# ── Section 4: Longitudinal Exposure ────────────────────────────────────────────

def _s04_longitudinal(rd: Path) -> str:
    windows = _read(rd, "final_l01_treatment_windows.csv")
    gap_deciles = _read(rd, "final_l01_gap_deciles.csv")
    gap_buckets = _read(rd, "final_l01_gap_buckets.csv")

    parts: list[str] = []

    # L01 treatment windows chart
    if windows is not None:
        fig = _l01_windows_chart(windows)
        if fig:
            parts.append(_card_grid(
                _plot_box("Figure 4.1 — % cohort with L01 per 30-day window", _fig_div(fig), badge="new"),
                cols=1,
            ))

    # Gap bucket distribution chart
    if gap_buckets is not None:
        fig = _gap_bucket_chart(gap_buckets)
        if fig:
            parts.append(_plot_box("Figure 4.2 — Distribution of gaps between consecutive L01 records", _fig_div(fig), badge="new"))

    # Gap decile summary table
    if gap_deciles is not None:
        sc = _col(gap_deciles, "subgroup")
        ng = _col(gap_deciles, "n_gaps")
        np_ = _col(gap_deciles, "n_patients_with_gaps")
        p10 = _col(gap_deciles, "p10_days")
        p25 = _col(gap_deciles, "p25_days")
        p50 = _col(gap_deciles, "p50_days")
        p75 = _col(gap_deciles, "p75_days")
        p90 = _col(gap_deciles, "p90_days")
        if sc and ng and p50:
            rows = []
            for _, r in gap_deciles.iterrows():
                sg = str(r.get(sc, ""))
                rows.append(
                    f"<tr><td><code>{_e(sg)}</code></td>"
                    f'<td class="num">{_fmt_n(r.get(ng))}</td>'
                    f'<td class="num">{_fmt_n(r.get(np_)) if np_ else "—"}</td>'
                    f'<td class="num">{_fmt_n(r.get(p10)) if p10 else "—"}</td>'
                    f'<td class="num">{_fmt_n(r.get(p25)) if p25 else "—"}</td>'
                    f'<td class="num">{_fmt_n(r.get(p50))}</td>'
                    f'<td class="num">{_fmt_n(r.get(p75)) if p75 else "—"}</td>'
                    f'<td class="num">{_fmt_n(r.get(p90)) if p90 else "—"}</td>'
                    f"</tr>"
                )
            tbl = (
                '<table class="rt"><thead><tr>'
                '<th>Subgroup</th><th class="num">N gaps</th><th class="num">N patients</th>'
                '<th class="num">P10</th><th class="num">P25</th><th class="num">P50</th>'
                '<th class="num">P75</th><th class="num">P90</th>'
                '</tr></thead><tbody>' + "\n".join(rows) + '</tbody></table>'
            )
            parts.append(_card(
                f"Table 4.1 — L01 gap distribution: all L01 patients vs MET subgroup {_badge('new')}",
                _tbl_wrap(tbl),
            ))

    if not parts:
        parts.append(
            _signal(
                "L01 treatment window and gap data require running new SQL chunks 07 and 11. "
                "Re-run the characterization query and export <code>final_l01_treatment_windows.csv</code>, "
                "<code>final_l01_gap_deciles.csv</code>, and <code>final_l01_gap_buckets.csv</code>.",
                cls="amber", icon="⚠",
            )
        )

    return _section(
        "04", "Longitudinal Treatment Exposure",
        "Prevalence of antineoplastic treatment (L01) in successive 30-day windows around anchor dates, "
        "and distribution of gaps between consecutive L01 records. The window chart reveals "
        "treatment initiation patterns; the gap distribution characterises treatment continuity.",
        "\n".join(parts), sid="s4",
    )


# ── Section 5: Observation Period & Death ───────────────────────────────────────

def _s05_obs_death(rd: Path) -> str:
    death = _read(rd, "final_death_from_anchors.csv")
    gap_summary = _read(rd, "final_death_gap_summary.csv")
    gap_buckets = _read(rd, "final_death_gap_buckets.csv")

    parts: list[str] = []

    # Stat boxes from death CSV
    if death is not None:
        ac = _col(death, "anchor_event")
        nc = _col(death, "n_patients")
        nd = _col(death, "n_deaths")
        nio = _col(death, "n_deaths_in_obs")
        noo = _col(death, "n_deaths_out_obs")
        if ac and nc and nd:
            yc_death = _col(death, "prevalence_year")
            if yc_death:
                o = death[(death[ac].astype(str).str.upper() == "INDEX") & (death[yc_death].astype(str).str.upper() == "OVERALL")]
            else:
                o = death[death[ac].astype(str).str.upper() == "INDEX"].head(1)
            if not o.empty:
                r = o.iloc[0]
                np_val = _safe_int(r.get(nc))
                nd_val = _safe_int(r.get(nd))
                nio_val = _safe_int(r.get(nio)) if nio else None
                noo_val = _safe_int(r.get(noo)) if noo else None
                pct_dead = f"{100.0 * nd_val / np_val:.1f}%" if nd_val and np_val and np_val > 0 else "—"
                pct_in = f"{100.0 * nio_val / nd_val:.1f}%" if nio_val and nd_val and nd_val > 0 else "—"
                pct_out = f"{100.0 * noo_val / nd_val:.1f}%" if noo_val and nd_val and nd_val > 0 else "—"
                parts.append(_card_grid(
                    _stat_box(_fmt_n(np_val), "DX cohort (INDEX)", cls="highlight"),
                    _stat_box(_fmt_n(nd_val), "Deceased (any)", pct=pct_dead),
                    _stat_box(_fmt_n(nio_val) if nio_val else "—", "Deaths inside obs. period", pct=pct_in),
                    _stat_box(_fmt_n(noo_val) if noo_val else "—", "Deaths outside obs. period", pct=pct_out, cls="alert" if noo_val else ""),
                    cols=4,
                ))

    # Death/obs summary table
    if death is not None:
        ac = _col(death, "anchor_event")
        yc = _col(death, "prevalence_year")
        nc = _col(death, "n_patients")
        nd = _col(death, "n_deaths")
        nio = _col(death, "n_deaths_in_obs")
        noo = _col(death, "n_deaths_out_obs")
        med_f = _col(death, "median_followup_days")
        lq_f = _col(death, "lq_followup_days")
        uq_f = _col(death, "uq_followup_days")
        if ac and yc and nc and nd:
            overall = death[
                (death[ac].astype(str).str.upper() == "INDEX") &
                (death[yc].astype(str).str.upper() == "OVERALL")
            ]
            if not overall.empty:
                rows = []
                for _, r in overall.iterrows():
                    anch = str(r.get(ac, ""))
                    np_ = _safe_int(r.get(nc))
                    nd_ = _safe_int(r.get(nd))
                    nio_ = _safe_int(r.get(nio)) if nio else None
                    noo_ = _safe_int(r.get(noo)) if noo else None
                    pct_dead = f"{100.0 * nd_ / np_:.1f}%" if nd_ and np_ and np_ > 0 else "—"
                    pct_out = f"{100.0 * noo_ / nd_:.1f}%" if noo_ and nd_ and nd_ > 0 else "—"
                    fup = _fmt_iqr(r.get(med_f) if med_f else None,
                                   r.get(lq_f) if lq_f else None,
                                   r.get(uq_f) if uq_f else None)
                    rows.append(
                        f"<tr>"
                        f"<td>{_e(anch)}</td>"
                        f'<td class="num">{_fmt_n(np_)}</td>'
                        f'<td class="num">{_fmt_n(nd_)} ({pct_dead})</td>'
                        f'<td class="num">{_fmt_n(nio_)}</td>'
                        f'<td class="num">{_fmt_n(noo_)} ({pct_out})</td>'
                        f'<td class="num">{_e(fup)}</td>'
                        f"</tr>"
                    )
                if rows:
                    tbl = (
                        '<table class="rt"><thead><tr>'
                        '<th>Anchor</th><th class="num">N</th>'
                        '<th class="num">Deceased (%)</th>'
                        '<th class="num">Deaths in obs. period</th>'
                        '<th class="num">Deaths outside obs. period (%)</th>'
                        '<th class="num">Follow-up median (IQR), days</th>'
                        '</tr></thead><tbody>' + "\n".join(rows) + '</tbody></table>'
                    )
                    parts.append(_card(
                        "Table 5.1 — Observation period / death alignment summary",
                        _tbl_wrap(tbl),
                    ))

    # Death gap distribution (new)
    if gap_summary is not None:
        ac = _col(gap_summary, "anchor_event")
        nd_after = _col(gap_summary, "n_death_after_obs")
        nd_before = _col(gap_summary, "n_death_before_obs")
        med_g = _col(gap_summary, "median_gap_days")
        lq_g = _col(gap_summary, "lq_gap_days")
        uq_g = _col(gap_summary, "uq_gap_days")
        if ac and nd_after:
            rows = []
            for _, r in gap_summary.iterrows():
                anch = str(r.get(ac, ""))
                nafter = _safe_int(r.get(nd_after))
                nbefore = _safe_int(r.get(nd_before)) if nd_before else None
                gap_iqr = _fmt_iqr(r.get(med_g) if med_g else None,
                                    r.get(lq_g) if lq_g else None,
                                    r.get(uq_g) if uq_g else None)
                rows.append(
                    f"<tr><td>{_e(anch)}</td>"
                    f'<td class="num">{_fmt_n(nafter)}</td>'
                    f'<td class="num">{_fmt_n(nbefore)}</td>'
                    f'<td class="num">{_e(gap_iqr)}</td></tr>'
                )
            if rows:
                tbl = (
                    '<table class="rt"><thead><tr>'
                    '<th>Anchor</th>'
                    '<th class="num">Deaths after obs. period end</th>'
                    '<th class="num">Deaths before obs. period start</th>'
                    '<th class="num">Gap: median (IQR), days</th>'
                    '</tr></thead><tbody>' + "\n".join(rows) + '</tbody></table>'
                )
                parts.append(_card(
                    f"Table 5.2 — Death date vs obs. period alignment {_badge('new')}",
                    _tbl_wrap(tbl),
                ))

    if gap_buckets is not None:
        fig = _gap_bucket_chart(gap_buckets, n_col="n_patients", group_col=None)
        if fig:
            parts.append(_plot_box("Figure 5.1 — Gap distribution: death date − obs. period end", _fig_div(fig), badge="new"))

    # Deaths by year chart
    if death is not None:
        fig = _death_obs_chart(death)
        if fig:
            parts.append(_plot_box("Figure 5.2 — Deaths by calendar year: inside vs outside obs. period", _fig_div(fig), badge="expanded"))

    if not parts:
        parts.append('<p style="color:var(--text-3);font-style:italic;">Death/obs data not yet available.</p>')

    return _section(
        "05", "Observation Period, Death & Survival Validity",
        "Alignment between death dates and observation period end dates. Deaths occurring after the "
        "observation period ends are a common data quality issue that inflates survival estimates. "
        "Deaths before the observation period start are a harder error. "
        "Follow-up distributions characterise censoring patterns.",
        "\n".join(parts), sid="s5",
    )


# ── Section 6: Year-over-Year Stability ─────────────────────────────────────────

def _s06_yoy(rd: Path) -> str:
    by_year = _read(rd, "final_timing_by_year.csv")
    directionality = _read(rd, "final_directionality.csv")

    parts: list[str] = []

    # Timing matrix by year (HTML table)
    if by_year is not None:
        ttc = _col(by_year, "timing_type")
        fc = _col(by_year, "from_event")
        tc = _col(by_year, "to_event")
        yc = _col(by_year, "index_year")
        n_col = _col(by_year, "n_patients_with_pair")
        mc = _col(by_year, "p50_days")
        if all([fc, tc, yc, mc]):
            sub = by_year.copy()
            if ttc:
                sub = sub[sub[ttc].astype(str).str.lower() == "first_to_first"]
            sub["__y"] = pd.to_numeric(sub[yc].astype(str), errors="coerce")
            sub = sub[sub["__y"] >= PREVALENCE_YEAR_MIN].copy()
            years = sorted(sub["__y"].dropna().astype(int).unique().tolist())
            pairs = [("DX", "MET"), ("MET", "L01"), ("DX", "L01")]

            if years and pairs:
                ths = "".join(f"<th>{y}</th>" for y in years)
                rows = []
                for from_ev, to_ev in pairs:
                    sel = sub[
                        sub[fc].astype(str).str.upper().eq(from_ev) &
                        sub[tc].astype(str).str.upper().eq(to_ev)
                    ].copy().set_index("__y")
                    meds = [sel[mc].get(y) if y in sel.index else None for y in years]
                    valid_meds = [m for m in meds if m is not None and not pd.isna(m)]
                    mn_v = min(valid_meds) if valid_meds else 0
                    mx_v = max(valid_meds) if valid_meds else 1
                    span = max(1, mx_v - mn_v)

                    def _cls(v: Any) -> str:
                        if v is None or (isinstance(v, float) and pd.isna(v)):
                            return "hm-0"
                        idx = int(5 * (float(v) - mn_v) / span)
                        return f"hm-{min(5, max(1, idx))}"

                    cells = "".join(
                        f'<td class="{_cls(m)}">{_round_day(m) if m is not None and not (isinstance(m, float) and pd.isna(m)) else "—"}</td>'
                        for m in meds
                    )
                    label = f"{from_ev} → {to_ev} (days)"
                    rows.append(f'<tr><th class="row-head">{label}</th>{cells}</tr>')

                tbl = (
                    '<div class="hm-wrap"><table class="hm-table"><thead><tr>'
                    f'<th class="row-head">Pair</th>{ths}'
                    f'</tr></thead><tbody>' + "\n".join(rows) +
                    '</tbody></table></div>'
                )
                parts.append(_card(
                    f"Table 6.1 — Timing summary matrix by index year (median days, first→first) {_badge('new')}",
                    tbl,
                ))

    # Multi-line timing by year chart
    if by_year is not None:
        fig = _timing_by_year_chart(by_year)
        if fig:
            parts.append(_plot_box("Figure 6.1 — Key timing metrics by index year", _fig_div(fig), badge="new"))

    # Directionality by year table
    if directionality is not None:
        pc = _col(directionality, "pair")
        yc = _col(directionality, "index_year")
        dc = _col(directionality, "direction")
        nc = _col(directionality, "n_patients")
        if all([pc, yc, dc, nc]):
            dx_met = directionality[
                (directionality[pc].astype(str).str.upper() == "DX_MET") &
                (directionality[yc].astype(str).str.upper() != "OVERALL")
            ].copy()
            dx_met["__y"] = pd.to_numeric(dx_met[yc].astype(str), errors="coerce")
            dx_met = dx_met[dx_met["__y"] >= PREVALENCE_YEAR_MIN].copy()
            years = sorted(dx_met["__y"].dropna().astype(int).unique().tolist())
            directions = [d for d in _DIR_ORDER if d != "SAME_DAY"]
            if years and not dx_met.empty:
                ths = "".join(f"<th>{y}</th>" for y in years)
                rows = []
                for d in directions:
                    sub_d = dx_met[dx_met[dc].astype(str).str.upper() == d]
                    year_counts = dict(zip(
                        sub_d["__y"].astype(int).tolist(),
                        pd.to_numeric(sub_d[nc], errors="coerce").tolist(),
                    ))
                    _, label = _DIR_LABELS.get(d, ("none", d))
                    cells = "".join(
                        f'<td class="num">{_fmt_n(year_counts.get(y))}</td>'
                        for y in years
                    )
                    rows.append(f"<tr><td>{_e(label)}</td>{cells}</tr>")
                if rows:
                    tbl = (
                        '<div class="hm-wrap"><table class="rt"><thead><tr>'
                        f'<th>Direction (DX→MET)</th>{ths}'
                        '</tr></thead><tbody>' + "\n".join(rows) + '</tbody></table></div>'
                    )
                    parts.append(_card(
                        f"Table 6.2 — DX→MET directionality by index year {_badge('new')}",
                        tbl,
                    ))

    if not parts:
        parts.append(
            _signal(
                "Year-over-year data requires <code>final_timing_by_year.csv</code> and "
                "<code>final_directionality.csv</code> from SQL chunks 05 and 03.",
                cls="amber", icon="⚠",
            )
        )

    return _section(
        "06", "Year-over-Year Stability",
        "Timing metrics and directionality patterns stratified by index year. "
        "Stable metrics suggest consistent coding behaviour; abrupt shifts may indicate "
        "EHR migrations, guideline changes, or selection artefacts.",
        "\n".join(parts), sid="s6",
    )


# ── CSS ──────────────────────────────────────────────────────────────────────────

_CSS = """
  :root {
    --bg: #f7f6f3;
    --surface: #ffffff;
    --surface2: #f0efe9;
    --border: #dddbd3;
    --border-strong: #b8b5aa;
    --text: #1a1917;
    --text-2: #4a4843;
    --text-3: #7a7772;
    --accent: #1a3a5c;
    --accent-light: #e8eef5;
    --amber: #b45309;
    --amber-light: #fef3c7;
    --red: #991b1b;
    --red-light: #fee2e2;
    --green: #166534;
    --green-light: #dcfce7;
    --blue: #1e40af;
    --blue-light: #dbeafe;
    --mono: 'IBM Plex Mono', monospace;
    --sans: 'IBM Plex Sans', sans-serif;
    --serif: 'Fraunces', serif;
  }
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: var(--sans); background: var(--bg); color: var(--text); font-size: 14px; line-height: 1.6; }
  .report-header { background: var(--accent); color: white; padding: 40px 48px 36px; position: relative; overflow: hidden; }
  .report-header::before { content: ''; position: absolute; top: -60px; right: -60px; width: 300px; height: 300px; border-radius: 50%; background: rgba(255,255,255,0.04); }
  .header-tag { font-family: var(--mono); font-size: 11px; font-weight: 500; letter-spacing: 0.12em; text-transform: uppercase; opacity: 0.6; margin-bottom: 12px; }
  .report-title { font-family: var(--serif); font-size: 32px; font-weight: 300; line-height: 1.2; margin-bottom: 8px; }
  .report-subtitle { font-size: 15px; opacity: 0.75; font-weight: 300; margin-bottom: 24px; }
  .header-meta { display: flex; gap: 32px; flex-wrap: wrap; }
  .meta-item { font-family: var(--mono); font-size: 11px; opacity: 0.6; }
  .meta-item strong { display: block; font-size: 13px; opacity: 1; font-weight: 500; margin-bottom: 2px; font-family: var(--sans); }
  .toc-bar { background: var(--surface); border-bottom: 1px solid var(--border); padding: 0 48px; display: flex; gap: 0; overflow-x: auto; position: sticky; top: 0; z-index: 100; }
  .toc-item { font-size: 12px; font-weight: 500; color: var(--text-3); padding: 14px 16px; text-decoration: none; white-space: nowrap; border-bottom: 2px solid transparent; transition: color 0.15s, border-color 0.15s; font-family: var(--mono); letter-spacing: 0.02em; }
  .toc-item:hover { color: var(--accent); border-bottom-color: var(--accent); }
  .toc-num { opacity: 0.45; margin-right: 4px; }
  .report-body { max-width: 1120px; margin: 0 auto; padding: 40px 48px 80px; }
  .section { margin-bottom: 56px; }
  .section-header { display: flex; align-items: baseline; gap: 14px; margin-bottom: 6px; }
  .section-num { font-family: var(--mono); font-size: 11px; color: var(--text-3); letter-spacing: 0.08em; flex-shrink: 0; }
  .section-title { font-family: var(--serif); font-size: 22px; font-weight: 300; color: var(--text); }
  .section-desc { font-size: 13px; color: var(--text-2); line-height: 1.65; margin-bottom: 24px; padding-left: 40px; max-width: 820px; font-style: italic; }
  .section-divider { height: 1px; background: var(--border); margin: 8px 0 24px; }
  .card { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 20px 24px; margin-bottom: 16px; }
  .card-title { font-family: var(--mono); font-size: 11px; letter-spacing: 0.08em; text-transform: uppercase; color: var(--text-3); margin-bottom: 14px; }
  .card-grid { display: grid; gap: 16px; }
  .card-grid-1 { grid-template-columns: 1fr; }
  .card-grid-2 { grid-template-columns: 1fr 1fr; }
  .card-grid-3 { grid-template-columns: 1fr 1fr 1fr; }
  .card-grid-4 { grid-template-columns: repeat(4, 1fr); }
  .signal { border-radius: 6px; padding: 12px 16px; font-size: 13px; line-height: 1.55; margin-bottom: 14px; display: flex; gap: 10px; align-items: flex-start; }
  .signal-icon { font-size: 15px; flex-shrink: 0; margin-top: 1px; }
  .signal.amber { background: var(--amber-light); border-left: 3px solid var(--amber); color: #78350f; }
  .signal.red { background: var(--red-light); border-left: 3px solid var(--red); color: #7f1d1d; }
  .signal.blue { background: var(--blue-light); border-left: 3px solid var(--blue); color: #1e3a8a; }
  .signal.green { background: var(--green-light); border-left: 3px solid var(--green); color: #14532d; }
  .signal strong { font-weight: 600; }
  .stat-box { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; padding: 18px 20px; text-align: center; }
  .stat-val { font-family: var(--serif); font-size: 28px; font-weight: 600; color: var(--accent); display: block; line-height: 1.1; }
  .stat-pct { font-family: var(--mono); font-size: 13px; color: var(--text-3); }
  .stat-label { font-size: 11px; color: var(--text-3); margin-top: 6px; font-family: var(--mono); letter-spacing: 0.04em; text-transform: uppercase; }
  .stat-box.highlight { background: var(--accent-light); border-color: #93afc9; }
  .stat-box.warn { background: var(--amber-light); border-color: #fcd34d; }
  .stat-box.alert { background: var(--red-light); border-color: #fca5a5; }
  .tbl-wrap { overflow-x: auto; }
  table.rt { border-collapse: collapse; width: 100%; font-size: 13px; }
  table.rt th { background: var(--surface2); font-weight: 600; padding: 9px 11px; border: 1px solid var(--border); text-align: left; font-size: 12px; color: var(--text-2); font-family: var(--mono); letter-spacing: 0.03em; }
  table.rt td { padding: 8px 11px; border: 1px solid var(--border); background: var(--surface); vertical-align: top; }
  table.rt tr.highlight td { background: var(--accent-light); }
  table.rt tr.warn td { background: var(--amber-light); }
  table.rt .num { text-align: right; font-family: var(--mono); font-size: 12px; }
  table.rt .flag-red { color: var(--red); font-weight: 600; }
  table.rt .flag-amber { color: var(--amber); font-weight: 600; }
  .tbl-note { font-size: 11px; color: var(--text-3); margin-top: 6px; font-family: var(--mono); }
  code { font-family: var(--mono); background: var(--surface2); border: 1px solid var(--border); padding: 1px 5px; border-radius: 3px; font-size: 11px; color: var(--accent); }
  .plot-box { background: var(--surface); border: 1px solid var(--border); border-radius: 8px; overflow: hidden; margin-bottom: 16px; }
  .plot-header { padding: 12px 18px; border-bottom: 1px solid var(--border); display: flex; justify-content: space-between; align-items: center; }
  .plot-header-title { font-family: var(--mono); font-size: 11px; letter-spacing: 0.06em; text-transform: uppercase; color: var(--text-2); }
  .plot-area { padding: 8px 4px 4px; }
  .dir-badge { display: inline-block; padding: 2px 8px; border-radius: 10px; font-size: 11px; font-weight: 600; font-family: var(--mono); }
  .dir-before { background: #fee2e2; color: #991b1b; }
  .dir-same { background: #fef9c3; color: #713f12; }
  .dir-after { background: #dcfce7; color: #166534; }
  .dir-none { background: #f1f5f9; color: #475569; }
  .hm-wrap { overflow-x: auto; }
  .hm-table { border-collapse: collapse; font-size: 12px; width: 100%; }
  .hm-table th { font-family: var(--mono); font-size: 10px; letter-spacing: 0.05em; color: var(--text-3); padding: 5px 8px; text-align: center; border: 1px solid var(--border); background: var(--surface2); }
  .hm-table th.row-head { text-align: left; }
  .hm-table td { padding: 6px 8px; text-align: center; border: 1px solid var(--border); font-family: var(--mono); font-size: 11px; font-weight: 500; }
  .hm-0 { background: #f0efe9; color: var(--text-3); }
  .hm-1 { background: #dbeafe; color: #1e3a8a; }
  .hm-2 { background: #bfdbfe; color: #1e40af; }
  .hm-3 { background: #93c5fd; color: #1d4ed8; }
  .hm-4 { background: #3b82f6; color: white; }
  .hm-5 { background: #1d4ed8; color: white; }
  .badge { display: inline-block; font-family: var(--mono); font-size: 10px; letter-spacing: 0.06em; padding: 2px 7px; border-radius: 3px; text-transform: uppercase; font-weight: 500; }
  .badge-new { background: #d1fae5; color: #065f46; border: 1px solid #6ee7b7; }
  .badge-gap { background: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; }
  .badge-partial { background: #fef3c7; color: #92400e; border: 1px solid #fcd34d; }
  @media (max-width: 700px) {
    .report-header { padding: 24px; }
    .report-body { padding: 20px; }
    .card-grid-2, .card-grid-3, .card-grid-4 { grid-template-columns: 1fr; }
    .toc-bar { padding: 0 16px; }
  }
"""

_GOOGLE_FONTS = (
    '<link rel="preconnect" href="https://fonts.googleapis.com">'
    '<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>'
    '<link href="https://fonts.googleapis.com/css2?family=Fraunces:wght@300;600&'
    'family=IBM+Plex+Mono:wght@400;500&family=IBM+Plex+Sans:wght@300;400;500;600&display=swap" rel="stylesheet">'
)


# ── Main build ───────────────────────────────────────────────────────────────────

def build_report(outputs_dir: str | Path | None = None) -> Path:
    import datetime
    global _plotly_included
    _plotly_included = False

    rd = Path(outputs_dir).expanduser().resolve() if outputs_dir else OUTPUTS_DIR
    out = rd / OUT_FILE

    generated_at = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

    header = f"""
<header class="report-header">
  <div class="header-tag">Oncology Phenotype Characterisation</div>
  <div class="report-title">Data Characterisation Report</div>
  <div class="report-subtitle">OMOP CDM · ATC L01 Antineoplastics · Metastasis cohort</div>
  <div class="header-meta">
    <div class="meta-item"><strong>Generated</strong>{generated_at}</div>
    <div class="meta-item"><strong>Source</strong>{_e(str(rd))}</div>
  </div>
</header>
"""

    nav = """
<nav class="toc-bar">
  <a class="toc-item" href="#s0"><span class="toc-num">0.</span> Overview</a>
  <a class="toc-item" href="#s1"><span class="toc-num">1.</span> DX → MET Timing</a>
  <a class="toc-item" href="#s2"><span class="toc-num">2.</span> GDX / ODX Codes</a>
  <a class="toc-item" href="#s3"><span class="toc-num">3.</span> Treatment Timing</a>
  <a class="toc-item" href="#s4"><span class="toc-num">4.</span> Longitudinal Exposure</a>
  <a class="toc-item" href="#s5"><span class="toc-num">5.</span> Obs. Period &amp; Death</a>
  <a class="toc-item" href="#s6"><span class="toc-num">6.</span> Year-over-Year</a>
</nav>
"""

    sections = [
        _s00_overview(rd),
        _s01_dx_met_timing(rd),
        _s02_gdx_odx(rd),
        _s03_treatment_timing(rd),
        _s04_longitudinal(rd),
        _s05_obs_death(rd),
        _s06_yoy(rd),
    ]

    doc = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>Oncology Phenotype Characterisation Report</title>
{_GOOGLE_FONTS}
<style>{_CSS}</style>
</head>
<body>
{header}
{nav}
<main class="report-body">
{"".join(sections)}
</main>
</body>
</html>
"""

    out.write_text(doc, encoding="utf-8")
    print(f"Written: {out}")
    return out


if __name__ == "__main__":
    build_report(sys.argv[1] if len(sys.argv) > 1 else None)
