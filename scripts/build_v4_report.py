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

_DX_MET_INTERP = {
    "BEFORE_GT90":  "MET code precedes first DX code — data quality or staging workflow signal",
    "BEFORE_1_90":  "MET code precedes first DX code — data quality or staging workflow signal",
    "SAME_DAY":     "Simultaneous coding — likely staging encounter or data aggregation artifact",
    "AFTER_1_30":   "Near-simultaneous; consistent with staging at diagnosis",
    "AFTER_31_90":  "Early progression or delayed staging documentation",
    "AFTER_91_365": "Early progression or delayed staging documentation",
    "AFTER_GT365":  "Late progression — clinically most coherent phenotype",
    "NO_EVENT":     "No metastasis code ever recorded in observation period",
}

_MET_L01_IMPLICATION = {
    "BEFORE_GT90":  "Treatment-naive at MET assumption is incorrect for this group",
    "BEFORE_1_90":  "Recent prior treatment; washout logic applies",
    "SAME_DAY":     "Co-coded on staging encounter",
    "AFTER_1_30":   "Clinically coherent first-line initiation",
    "AFTER_31_90":  "Delayed initiation; may include trial screen failures",
    "AFTER_91_365": "Delayed initiation; extended washout period",
    "AFTER_GT365":  "Very late initiation; likely re-initiation after gap",
    "NO_EVENT":     "<strong>Investigational drug / trial enrollment signal</strong> — or true treatment-naive / supportive care only",
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


def _plot_box(title: str, div: str, *, badge: str = "", sub: str = "") -> str:
    badge_html = f' <span class="badge badge-new">{badge}</span>' if badge else ""
    sub_html = f'<span class="plot-header-sub">{_e(sub)}</span>' if sub else ""
    return (
        f'<div class="plot-box">'
        f'<div class="plot-header">'
        f'<span class="plot-header-title">{_e(title)}{badge_html}</span>'
        f'{sub_html}'
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

def _l01_windows_chart(df: pd.DataFrame, anchor_filter: str | None = None) -> go.Figure | None:
    ac = _col(df, "anchor_event")
    wc = _col(df, "window_index")
    lc = _col(df, "n_patients_with_l01")
    oc = _col(df, "n_observed")
    if not ac or not wc or not lc:
        return None

    fig = go.Figure()
    colors = {"INDEX": "#1a3a5c", "FIRST_MET": "#b45309"}

    anchors = [anchor_filter.upper()] if anchor_filter else ["INDEX", "FIRST_MET"]
    for anchor in anchors:
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
    colors = {
        "ALL_L01":     "#1a3a5c",
        "MET_L01":     "#b45309",
        "ALL_L01_MAX": "#4e86b8",
        "MET_L01_MAX": "#f0a030",
        None:          "#1a3a5c",
    }

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


# ── Chart: L01 distinct treatment day count ─────────────────────────────────────

def _day_count_chart(df: pd.DataFrame, subgroup: str) -> go.Figure | None:
    sc = _col(df, "subgroup")
    bc = _col(df, "days_bucket")
    nc = _col(df, "n_patients")
    if not sc or not bc or not nc:
        return None
    sub = df[df[sc].astype(str).str.upper() == subgroup.upper()].copy()
    if sub.empty:
        return None

    bucket_order = ["1", "2_6", "7_11", "12plus"]
    bucket_labels = {"1": "1 day", "2_6": "2–6 days", "7_11": "7–11 days", "12plus": "≥12 days"}
    color = "#1a3a5c" if subgroup.upper() == "ALL_L01" else "#b45309"

    vals_map = {
        str(r.get(bc, "")): max(0, int(pd.to_numeric(r.get(nc, 0), errors="coerce") or 0))
        for _, r in sub.iterrows()
    }
    xs = [bucket_labels.get(b, b) for b in bucket_order if b in vals_map]
    ys = [vals_map[b] for b in bucket_order if b in vals_map]
    if not xs:
        return None

    fig = go.Figure()
    fig.add_trace(go.Bar(x=xs, y=ys, marker_color=color, opacity=0.85, showlegend=False))
    layout = _plotly_base_layout()
    layout.update({
        "xaxis": dict(title="Distinct L01 treatment days"),
        "yaxis": dict(title="N patients", gridcolor="#e5e7eb"),
        "height": 280,
    })
    fig.update_layout(**layout)
    return fig


# ── Chart: deaths inside vs outside obs period ───────────────────────────────────

def _death_obs_chart(df: pd.DataFrame, anchor: str = "INDEX") -> go.Figure | None:
    yc = _col(df, "prevalence_year")
    ac = _col(df, "anchor_event")
    nc = _col(df, "n_patients")
    nd = _col(df, "n_deaths")
    nio = _col(df, "n_deaths_in_obs")
    noo = _col(df, "n_deaths_out_obs")
    if not yc or not ac or not nd or not nc:
        return None

    sub = df[(df[ac].astype(str).str.upper() == anchor.upper()) & (df[yc].astype(str).str.upper() != "OVERALL")].copy()
    if sub.empty:
        return None
    sub["__y"] = pd.to_numeric(sub[yc].astype(str), errors="coerce")
    sub = sub.dropna(subset=["__y"]).sort_values("__y")
    sub = sub[sub["__y"] >= PREVALENCE_YEAR_MIN]
    years = sub["__y"].astype(int)

    ndeath = pd.to_numeric(sub[nd], errors="coerce")
    npat = pd.to_numeric(sub[nc], errors="coerce")
    pct_dead = (ndeath / npat * 100).where((ndeath >= 0) & (npat > 0))

    is_met = anchor.upper() == "FIRST_MET"
    bar_color = "#4e86b8" if is_met else "#1a3a5c"
    n_label = "N MET" if is_met else "N DX"
    x_label = "Year of first MET" if is_met else "Year of first DX"

    fig = go.Figure()
    fig.add_trace(go.Bar(x=years, y=npat, name=n_label, marker_color=bar_color, opacity=0.6))
    fig.add_trace(go.Scatter(x=years, y=pct_dead, name="% Deceased",
                             mode="lines+markers", yaxis="y2",
                             line=dict(color="#991b1b", width=2),
                             marker=dict(size=6, color="#991b1b")))

    if nio and noo:
        nin = pd.to_numeric(sub[nio], errors="coerce")
        nout = pd.to_numeric(sub[noo], errors="coerce")
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
        "xaxis": dict(title=x_label, dtick=2),
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


# ── Chart: density histogram from percentile data ───────────────────────────────

def _density_histogram_chart(
    df: pd.DataFrame,
    from_ev: str,
    to_ev: str,
    timing_type: str = "first_to_first",
    *,
    height: int = 280,
    x_label: str | None = None,
    from_label: str | None = None,
    to_label: str | None = None,
    color_fill: str = "rgba(29,78,216,0.20)",
    color_line: str = "rgba(29,78,216,0.55)",
    neg_color_fill: str = "rgba(220,38,38,0.30)",
    neg_color_line: str = "rgba(220,38,38,0.65)",
) -> tuple[go.Figure | None, dict[str, Any] | None]:
    ttc = _col(df, "timing_type")
    fc = _col(df, "from_event")
    tc = _col(df, "to_event")
    if not fc or not tc:
        return None, None
    sub = df.copy()
    if ttc:
        sub = sub[sub[ttc].astype(str).str.lower() == timing_type.lower()]
    sel = sub[
        sub[fc].astype(str).str.upper().eq(from_ev.upper()) &
        sub[tc].astype(str).str.upper().eq(to_ev.upper())
    ]
    if sel.empty:
        return None, None
    row = sel.iloc[0]

    def _pv(col_name: str) -> float | None:
        c = _col(sel, col_name)
        if not c:
            return None
        v = pd.to_numeric(row.get(c), errors="coerce")
        return None if pd.isna(v) else float(v)

    p05 = _pv("p05_days"); p10 = _pv("p10_days"); p20 = _pv("p20_days")
    p25 = _pv("p25_days"); p30 = _pv("p30_days"); p40 = _pv("p40_days")
    p50 = _pv("p50_days"); p60 = _pv("p60_days"); p70 = _pv("p70_days")
    p75 = _pv("p75_days"); p80 = _pv("p80_days"); p90 = _pv("p90_days")
    p95 = _pv("p95_days")
    n_total = _safe_int(row.get(_col(sel, "n_patients_with_pair")))

    if any(x is None for x in [p05, p10, p20, p30, p40, p50, p60, p70, p80, p90, p95]):
        return None, None

    raw_bins: list[tuple[float, float, int]] = [
        (p05, p10, 5), (p10, p20, 10), (p20, p30, 10), (p30, p40, 10),
        (p40, p50, 10), (p50, p60, 10), (p60, p70, 10), (p70, p80, 10),
        (p80, p90, 10), (p90, p95, 5),
    ]
    # Merge zero-width bins into the next bin so no patients are silently dropped
    bins: list[tuple[float, float, int]] = []
    carry = 0
    for lo, hi, pct in raw_bins:
        carry += pct
        if abs(hi - lo) > 0.1:
            bins.append((lo, hi, carry))
            carry = 0
    if carry > 0 and bins:
        lo, hi, pct = bins[-1]
        bins[-1] = (lo, hi, pct + carry)
    if not bins:
        return None, None

    frm = from_label or from_ev
    too = to_label or to_ev
    xs = [(lo + hi) / 2.0 for lo, hi, _ in bins]
    ys = [pct / 100.0 / abs(hi - lo) for lo, hi, pct in bins]
    widths = [abs(hi - lo) for lo, hi, _ in bins]

    fills = []
    lines = []
    for lo, hi, _ in bins:
        if hi <= 0:
            fills.append(neg_color_fill)
            lines.append(neg_color_line)
        elif lo < 0 < hi:
            fills.append("rgba(139,92,246,0.22)")
            lines.append("rgba(139,92,246,0.55)")
        else:
            fills.append(color_fill)
            lines.append(color_line)

    pct_neg = sum(pct for lo, hi, pct in bins if hi <= 0)
    x_min = min(lo for lo, _, _ in bins)

    shapes: list[dict[str, Any]] = []
    annotations: list[dict[str, Any]] = []

    if pct_neg > 0 and x_min < 0:
        shapes.append(dict(
            type="rect", x0=x_min * 1.05, x1=0, y0=0, y1=1,
            yref="paper", fillcolor="rgba(220,38,38,0.05)", line=dict(width=0),
        ))

    shapes.append(dict(
        type="line", x0=0, x1=0, y0=0, y1=1, yref="paper",
        line=dict(color="#94a3b8", width=1.5),
    ))

    if p50 is not None:
        shapes.append(dict(
            type="line", x0=p50, x1=p50, y0=0, y1=1, yref="paper",
            line=dict(color="#f59e0b", dash="dot", width=2),
        ))
        iqr_str = ""
        if p25 is not None and p75 is not None:
            iqr_str = f" (IQR {int(round(p25))}–{int(round(p75))})"
        annotations.append(dict(
            x=p50, y=0.97, yref="paper",
            text=f"median {int(round(p50))}d{iqr_str}",
            showarrow=False, font=dict(size=10),
            xanchor="left", xshift=6,
            bgcolor="rgba(255,255,255,0.85)",
        ))

    if pct_neg > 0 and x_min < 0:
        ann_x = x_min * 0.55
        annotations.append(dict(
            x=ann_x, y=0.82, yref="paper",
            text=f"~{pct_neg}% of patients:<br>{too} code precedes {frm}",
            showarrow=True, arrowhead=2, arrowcolor="#dc2626",
            font=dict(size=10, color="#dc2626"),
            ax=0, ay=-30,
            bgcolor="rgba(255,255,255,0.85)",
        ))

    fig = go.Figure()
    fig.add_trace(go.Bar(
        x=xs, y=ys, width=widths,
        marker=dict(color=fills, line=dict(color=lines, width=1)),
        customdata=[[f"{lo:.0f}–{hi:.0f}d", f"{pct}%"] for lo, hi, pct in bins],
        hovertemplate="%{customdata[0]}<br>%{customdata[1]} of patients<extra></extra>",
        showlegend=False,
    ))

    x_lbl = x_label or f"Days ({frm} → {too}) · bar width = decile range in days"
    layout = _plotly_base_layout()
    layout.update({
        "height": height,
        "shapes": shapes,
        "annotations": annotations,
        "xaxis": dict(
            title=dict(text=x_lbl),
            zeroline=True, zerolinecolor="#94a3b8", zerolinewidth=1.5,
            gridcolor="#e5e7eb",
        ),
        "yaxis": dict(title=dict(text="Relative frequency (density)"), gridcolor="#e5e7eb"),
        "showlegend": False,
        "margin": dict(l=52, r=20, t=16, b=60),
    })
    fig.update_layout(**layout)

    stats = {
        "median": p50, "p25": p25, "p75": p75, "n": n_total, "pct_neg": pct_neg,
    }
    return fig, stats


def _windowed_odx_chart(windowed: pd.DataFrame, n_denom: int | None = None, anchor: str = "INDEX") -> go.Figure | None:
    """Grouped bar chart: top 5 ODX concepts × 6 time windows (% of anchor cohort)."""
    ac = _col(windowed, "anchor_event")
    fc = _col(windowed, "event_family")
    cid_col = _col(windowed, "concept_id")
    ne = _col(windowed, "n_ever")
    n30 = _col(windowed, "n_pm30d")
    n90 = _col(windowed, "n_pm90d")
    n180 = _col(windowed, "n_pm180d")
    n1y = _col(windowed, "n_pm1yr")
    neb = _col(windowed, "n_ever_before")
    nea = _col(windowed, "n_ever_after")
    if not all([fc, cid_col, ne]):
        return None
    df = windowed.copy()
    if ac:
        df = df[df[ac].astype(str).str.upper() == anchor.upper()]
    odx = df[df[fc].astype(str).str.upper() == "ODX"].copy()
    odx["__n"] = pd.to_numeric(odx[ne], errors="coerce")
    odx = odx[odx["__n"] > 0].nlargest(5, "__n")
    if odx.empty:
        return None
    ids = [int(x) for x in odx[cid_col].dropna().astype(int).tolist()]
    names_map = _fetch_concept_names(ids)
    windows: list[tuple[str, str | None]] = [
        ("±30d", n30), ("±90d", n90), ("±180d", n180), ("±1yr", n1y),
        ("Ever before", neb), ("Ever after", nea),
    ]
    windows = [(lbl, c) for lbl, c in windows if c]
    if not windows:
        return None
    win_labels = [lbl for lbl, _ in windows]
    anchor_label = "MET" if anchor.upper() == "FIRST_MET" else "DX"
    colors = ["#1d4ed8", "#7c3aed", "#ea580c", "#dc2626", "#16a34a"]
    fig = go.Figure()
    for i, (_, row) in enumerate(odx.iterrows()):
        cid = _safe_int(row.get(cid_col))
        name = names_map.get(cid, str(cid)) if cid else "?"
        short_name = name[:30] + "…" if len(name) > 30 else name
        ys = []
        for _, wcol in windows:
            n = pd.to_numeric(row.get(wcol), errors="coerce") if wcol else float("nan")
            pct = (float(n) / n_denom * 100.0) if n_denom and not math.isnan(n) and n_denom > 0 else float("nan")
            ys.append(round(pct, 2) if not math.isnan(pct) else None)
        fig.add_trace(go.Bar(
            name=short_name, x=win_labels, y=ys,
            marker=dict(color=colors[i % len(colors)], opacity=0.82),
            hovertemplate="%{x}: %{y:.1f}%<extra>" + short_name + "</extra>",
        ))
    layout = _plotly_base_layout()
    layout.update({
        "height": 300,
        "barmode": "group",
        "xaxis": dict(title=dict(text=f"Time window around {anchor_label} index"), gridcolor="#e5e7eb"),
        "yaxis": dict(title=dict(text=f"% of {anchor_label} cohort"), rangemode="tozero", gridcolor="#e5e7eb"),
    })
    fig.update_layout(**layout)
    return fig


def _overlay_density_histogram(
    df: pd.DataFrame,
    series_defs: list[tuple[str, str, str, str, str, str]],
    height: int = 310,
    x_label: str = "Days (negative = event before anchor)",
) -> go.Figure | None:
    """Overlay multiple density histograms.

    series_defs: list of (from_ev, to_ev, timing_type, fill_color, line_color, name)
    """
    ttc = _col(df, "timing_type")
    fc = _col(df, "from_event")
    tc = _col(df, "to_event")
    if not fc or not tc:
        return None

    fig = go.Figure()
    any_data = False
    all_shapes: list[dict[str, Any]] = []
    all_annotations: list[dict[str, Any]] = []
    all_mins: list[float] = []
    first_neg_region = True

    for from_ev, to_ev, timing_type, fill_c, line_c, name in series_defs:
        sub = df.copy()
        if ttc:
            sub = sub[sub[ttc].astype(str).str.lower() == timing_type.lower()]
        sel = sub[
            sub[fc].astype(str).str.upper().eq(from_ev.upper()) &
            sub[tc].astype(str).str.upper().eq(to_ev.upper())
        ]
        if sel.empty:
            continue
        row = sel.iloc[0]

        def _pv(col_name: str) -> float | None:
            c = _col(sel, col_name)
            if not c:
                return None
            v = pd.to_numeric(row.get(c), errors="coerce")
            return None if pd.isna(v) else float(v)

        p05 = _pv("p05_days"); p10 = _pv("p10_days"); p20 = _pv("p20_days")
        p30 = _pv("p30_days"); p40 = _pv("p40_days"); p50 = _pv("p50_days")
        p60 = _pv("p60_days"); p70 = _pv("p70_days"); p80 = _pv("p80_days")
        p90 = _pv("p90_days"); p95 = _pv("p95_days")
        if any(x is None for x in [p05, p10, p20, p30, p40, p50, p60, p70, p80, p90, p95]):
            continue

        raw_bins: list[tuple[float, float, int]] = [
            (p05, p10, 5), (p10, p20, 10), (p20, p30, 10), (p30, p40, 10),
            (p40, p50, 10), (p50, p60, 10), (p60, p70, 10), (p70, p80, 10),
            (p80, p90, 10), (p90, p95, 5),
        ]
        bins = [(lo, hi, pct) for lo, hi, pct in raw_bins if abs(hi - lo) > 0.1]
        if not bins:
            continue

        xs = [(lo + hi) / 2.0 for lo, hi, _ in bins]
        ys = [pct / 100.0 / abs(hi - lo) for lo, hi, pct in bins]
        widths = [abs(hi - lo) for lo, hi, _ in bins]
        fills = [fill_c if lo >= 0 else "rgba(220,38,38,0.28)" for lo, hi, _ in bins]
        lines_c = [line_c if lo >= 0 else "rgba(220,38,38,0.60)" for lo, hi, _ in bins]

        fig.add_trace(go.Bar(
            x=xs, y=ys, width=widths, name=name,
            marker=dict(color=fills, line=dict(color=lines_c, width=1)),
            customdata=[[f"{lo:.0f}–{hi:.0f}d", f"{pct}%"] for lo, hi, pct in bins],
            hovertemplate=f"%{{customdata[0]}}<br>%{{customdata[1]}} of patients<extra>{name}</extra>",
            showlegend=True,
            opacity=0.85,
        ))

        x_min_s = min(lo for lo, _, _ in bins)
        all_mins.append(x_min_s)
        pct_neg = sum(pct for lo, hi, pct in bins if hi <= 0)

        if p50 is not None:
            all_shapes.append(
                dict(type="line", x0=p50, x1=p50, y0=0, y1=1, yref="paper",
                     line=dict(color=line_c.replace("0.55", "0.85"), dash="dot", width=1.8))
            )
            p25v = _pv("p25_days"); p75v = _pv("p75_days")
            iqr_str = ""
            if p25v is not None and p75v is not None:
                iqr_str = f" (IQR {int(round(p25v))}–{int(round(p75v))})"
            all_annotations.append(
                dict(x=p50, y=0.97 if not any_data else 0.87, yref="paper",
                     text=f"{name}: median {int(round(p50))}d{iqr_str}",
                     showarrow=False, font=dict(size=10),
                     xanchor="left", xshift=6,
                     bgcolor="rgba(255,255,255,0.85)")
            )

        if first_neg_region and pct_neg > 0 and x_min_s < 0:
            all_shapes.insert(0,
                dict(type="rect", x0=x_min_s * 1.05, x1=0, y0=0, y1=1,
                     yref="paper", fillcolor="rgba(220,38,38,0.05)", line=dict(width=0))
            )
            first_neg_region = False

        any_data = True

    if not any_data:
        return None

    all_shapes.append(
        dict(type="line", x0=0, x1=0, y0=0, y1=1, yref="paper",
             line=dict(color="#94a3b8", width=1.5))
    )

    layout = _plotly_base_layout()
    layout.update({
        "height": height,
        "barmode": "overlay",
        "shapes": all_shapes,
        "annotations": all_annotations,
        "xaxis": dict(
            title=dict(text=x_label),
            zeroline=True, zerolinecolor="#94a3b8", zerolinewidth=1.5,
            gridcolor="#e5e7eb",
        ),
        "yaxis": dict(title=dict(text="Relative frequency (density)"), gridcolor="#e5e7eb"),
        "legend": dict(orientation="h", x=1, xanchor="right", y=1.02, yanchor="bottom"),
        "margin": dict(l=52, r=20, t=16, b=60),
    })
    fig.update_layout(**layout)
    return fig


# ── Section 0: Overview ──────────────────────────────────────────────────────────

def _s00_overview(rd: Path) -> str:
    prev = _read(rd, "final_population_prevalence.csv")
    demo = _read(rd, "final_demographics_from_anchors.csv")
    dx_counts = _read(rd, "final_anchor_dx_concept_counts.csv")
    attrition = _read(rd, "final_cohort_attrition.csv")

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

    # ── Cohort attrition note ───────────────────────────────────────────────────
    if attrition is not None:
        nc_any = _col(attrition, "n_dx_any")
        nc_excl = _col(attrition, "n_excluded_no_obs_dx")
        if nc_any and nc_excl and not attrition.empty:
            r = attrition.iloc[0]
            n_any = _safe_int(r.get(nc_any))
            n_excl = _safe_int(r.get(nc_excl))
            if n_any and n_excl is not None:
                pct_excl = f"{100.0 * n_excl / n_any:.1f}%" if n_any > 0 else ""
                excl_str = f"{_fmt_n(n_excl)} ({pct_excl})" if pct_excl else _fmt_n(n_excl)
                parts.append(
                    f'<p class="tbl-note" style="margin:-4px 0 20px;">'
                    f'Cohort eligibility: index date = earliest qualifying DX within an observation period '
                    f'({_fmt_n(n_any)} patients had a qualifying DX; {excl_str} excluded — no overlapping observation period).'
                    f'</p>'
                )

    # ── Yearly prevalence chart ─────────────────────────────────────────────────
    if prev is not None:
        oc = _col(prev, "prevalence_year")
        if oc:
            yearly = prev[prev[oc].astype(str).str.upper() != "OVERALL"].copy()
            fig = _prevalence_chart(yearly)
            if fig:
                parts.append(_plot_box("Figure 0.1 — Population prevalence by calendar year", _fig_div(fig)))

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
                for _, r in top.iterrows():
                    cid = _safe_int(r.get(cid_col))
                    cname = names_map.get(cid, "") if cid else ""
                    np_ = _safe_int(r.get(np_col))
                    nd_ = _safe_int(r.get(nd_col)) if nd_col else None
                    pct_ = _pct_of(np_, n_dx) if n_dx else "—"
                    nd_str = f"{nd_:,}" if nd_ and nd_ > 0 else "—"
                    rows.append(
                        f"<tr><td><code>{_e(str(cid))}</code> {_e(cname)}</td>"
                        f'<td class="num">{_fmt_n(np_)}</td>'
                        f'<td class="num">{nd_str}</td>'
                        f'<td class="num">{_e(pct_)}</td>'
                        f"</tr>"
                    )
                tbl = (
                    '<table class="rt"><thead><tr>'
                    '<th>Concept</th>'
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

def _directionality_table(
    df: pd.DataFrame,
    pair: str,
    dir_labels: dict,
    *,
    n_total: int | None = None,
    interp: dict[str, str] | None = None,
    col4_header: str = "Interpretation",
) -> str:
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
    denom = n_total if n_total and n_total > 0 else sum(v for v in sub_map.values() if v and v > 0)
    rows = []
    for key in _DIR_ORDER:
        css_cls, label = dir_labels.get(key, ("none", key))
        n = sub_map.get(key)
        if n is None:
            continue
        pct = "—" if key == "NO_EVENT" else (f"{100.0 * n / denom:.1f}%" if denom > 0 and n and n > 0 else "—")
        flag = " flag-red" if css_cls == "before" and n and n > 0 else (" flag-amber" if css_cls == "none" and n and n > 0 else "")
        badge_html = _dir_badge(css_cls, label)
        interp_cell = interp.get(key, "") if interp else ""
        if interp:
            rows.append(
                f"<tr><td>{badge_html}</td>"
                f'<td class="num{flag}">{_fmt_n(n)}</td>'
                f'<td class="num{flag}">{pct}</td>'
                f"<td>{interp_cell}</td></tr>"
            )
        else:
            rows.append(
                f"<tr><td>{badge_html}</td>"
                f'<td class="num{flag}">{_fmt_n(n)}</td>'
                f'<td class="num{flag}">{pct}</td></tr>'
            )
    if interp:
        n_label = f"N (of cohort, N={n_total:,})" if n_total else "N patients"
        tbl = (
            '<table class="rt"><thead><tr>'
            f'<th>Direction</th><th class="num">{n_label}</th>'
            f'<th class="num">%</th><th>{col4_header}</th>'
            '</tr></thead><tbody>' + "\n".join(rows) + '</tbody></table>'
        )
    else:
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

    # Load n_dx and n_met for denominators
    prev = _read(rd, "final_population_prevalence.csv")
    n_dx: int | None = None
    n_met: int | None = None
    if prev is not None:
        oc = _col(prev, "prevalence_year")
        if oc:
            ov = prev[prev[oc].astype(str).str.upper() == "OVERALL"]
            if not ov.empty:
                n_dx = _safe_int(ov.iloc[0].get(_col(prev, "n_dx")))
                n_met = _safe_int(ov.iloc[0].get(_col(prev, "n_met")))

    if directionality is not None:
        tbl = _directionality_table(
            directionality, "DX_MET", _DIR_LABELS,
            n_total=n_met, interp=_DX_MET_INTERP, col4_header="Interpretation",
        )
        if tbl:
            n_met_lbl = f"N={n_met:,}" if n_met else "DX+MET subgroup"
            parts.append(_card(
                f"Table 1.1 — DX ↔ MET temporal directionality (first to first)",
                tbl + f'<p class="tbl-note">DX patients with MET only ({n_met_lbl}). % denominated on DX+MET subgroup. Suppressed rows hidden.</p>',
            ))

    # DX→MET timing distribution — density histogram
    if timing is not None:
        fig, stats = _density_histogram_chart(timing, "DX", "MET", "first_to_first")
        if fig:
            sub_txt = ""
            if stats:
                med = stats.get("median")
                p25v = stats.get("p25")
                p75v = stats.get("p75")
                if med is not None:
                    iqr = f" (IQR {int(round(p25v))}–{int(round(p75v))})" if p25v and p75v else ""
                    sub_txt = (
                        f"Anchored on DX · days positive = MET after DX · "
                        f"median {int(round(med))}d{iqr}"
                    )
            parts.append(_plot_box(
                "Figure 1.1 — Time from first DX to first MET (full distribution)",
                _fig_div(fig), sub=sub_txt,
            ))

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

                    # Per-year n_dx from population prevalence
                    prev_ndx_yr: dict[int, int | None] = {}
                    if prev is not None:
                        ypc = _col(prev, "prevalence_year")
                        ndc = _col(prev, "n_dx")
                        if ypc and ndc:
                            for _, pr in prev.iterrows():
                                try:
                                    prev_ndx_yr[int(float(str(pr[ypc])))] = _safe_int(pr[ndc])
                                except (ValueError, TypeError):
                                    pass

                    # Per-year n_patients_with_pair from filtered sub
                    nwpc = _col(sub, "n_patients_with_pair")
                    pair_by_yr: dict[int, int | None] = {}
                    if nwpc:
                        for _, sr in sub.iterrows():
                            pair_by_yr[int(sr["__y"])] = _safe_int(sr[nwpc])

                    ndx_cells = "".join(
                        f'<td>{_fmt_n(prev_ndx_yr.get(y))}</td>' for y in years
                    )
                    pct_met_cells = "".join(
                        f'<td>{_pct_of(pair_by_yr.get(y), prev_ndx_yr.get(y))}</td>'
                        for y in years
                    )

                    tbl = (
                        '<div class="hm-wrap"><table class="hm-table"><thead><tr>'
                        f'<th class="row-head">DX→MET median days</th>{ths}'
                        f'</tr></thead><tbody>'
                        f'<tr><td class="hm-table" style="text-align:left;">N_DX</td>{ndx_cells}</tr>'
                        f'<tr><td class="hm-table" style="text-align:left;">%_MET</td>{pct_met_cells}</tr>'
                        f'<tr><td class="hm-table" style="text-align:left;">Median</td>{cells}</tr>'
                        '</tbody></table></div>'
                    )
                    parts.append(_card(
                        f"Figure 1.2a — DX→MET median days by index year (first to first)",
                        tbl,
                    ))

    # Figure 1.2b — MET→DX median days by year (mirror direction)
    if by_year is not None:
        ttc = _col(by_year, "timing_type")
        fc = _col(by_year, "from_event")
        tc = _col(by_year, "to_event")
        yc = _col(by_year, "index_year")
        mc = _col(by_year, "p50_days")
        if all([fc, tc, yc, mc]):
            sub_b = by_year.copy()
            if ttc:
                sub_b = sub_b[sub_b[ttc].astype(str).str.lower() == "first_to_first"]
            sub_b = sub_b[
                sub_b[fc].astype(str).str.upper().eq("MET") &
                sub_b[tc].astype(str).str.upper().eq("DX")
            ].copy()
            sub_b["__y"] = pd.to_numeric(sub_b[yc].astype(str), errors="coerce")
            sub_b = sub_b[sub_b["__y"] >= PREVALENCE_YEAR_MIN].sort_values("__y")
            if not sub_b.empty:
                years_b = sub_b["__y"].astype(int).tolist()
                meds_b = pd.to_numeric(sub_b[mc], errors="coerce").tolist()
                valid_meds_b = [m for m in meds_b if not pd.isna(m)]
                if valid_meds_b:
                    mn_b, mx_b = min(valid_meds_b), max(valid_meds_b)
                    span_b = max(1, mx_b - mn_b)

                    def _hm_cls_b(v: float | None) -> str:
                        if v is None or pd.isna(v):
                            return "hm-0"
                        idx = int(5 * (v - mn_b) / span_b)
                        return f"hm-{min(5, max(1, idx))}"

                    cells_b = "".join(
                        f'<td class="{_hm_cls_b(m)}">{_round_day(m) if m is not None and not pd.isna(m) else "—"}</td>'
                        for m in meds_b
                    )
                    ths_b = "".join(f"<th>{y}</th>" for y in years_b)
                    nwpc_b = _col(sub_b, "n_patients_with_pair")
                    npair_cells_b = "".join(
                        f'<td>{_fmt_n(_safe_int(r[nwpc_b])) if nwpc_b else "—"}</td>'
                        for _, r in sub_b.iterrows()
                    )
                    tbl_b = (
                        '<div class="hm-wrap"><table class="hm-table"><thead><tr>'
                        f'<th class="row-head">MET→DX median days</th>{ths_b}'
                        f'</tr></thead><tbody>'
                        f'<tr><td class="hm-table" style="text-align:left;">N_pairs</td>{npair_cells_b}</tr>'
                        f'<tr><td class="hm-table" style="text-align:left;">Median</td>{cells_b}</tr>'
                        '</tbody></table></div>'
                    )
                    parts.append(_card(
                        "Figure 1.2b — MET→DX median days by index year (first to first; negative = MET precedes DX)",
                        tbl_b,
                    ))

    if not parts:
        parts.append('<p style="color:var(--text-3);font-style:italic;">Timing data not yet available.</p>')

    return _section(
        "01", "Disease Code Timing & Sequencing",
        "Full distribution of time from first DX code to first MET code. "
        "Negative days = MET code precedes DX — a data provenance / staging workflow signal. "
        "The distribution shape reveals: (a) proportion staged at diagnosis, "
        "(b) early vs late progression phenotypes, (c) data quality outliers.",
        "\n".join(parts), sid="s1",
    )


# ── Section 2: GDX/ODX ──────────────────────────────────────────────────────────

def _s02_gdx_odx(rd: Path) -> str:
    code_counts = _read(rd, "final_code_counts.csv")
    windowed = _read(rd, "final_windowed_odx_prevalence.csv")
    timing = _read(rd, "final_timing_pairwise.csv")
    prev = _read(rd, "final_population_prevalence.csv")
    n_dx = None
    n_met = None
    if prev is not None:
        oc = _col(prev, "prevalence_year")
        if oc:
            o = prev[prev[oc].astype(str).str.upper() == "OVERALL"]
            if not o.empty:
                n_dx = _safe_int(o.iloc[0].get(_col(prev, "n_dx")))
                n_met = _safe_int(o.iloc[0].get(_col(prev, "n_met")))

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
                for _, r in gdx.iterrows():
                    cid = _safe_int(r.get(cid_col))
                    cname = names_map.get(cid, "") if cid else ""
                    np_ = _safe_int(r.get(np_col))
                    pct_ = _pct_of(np_, n_dx) if n_dx else "—"
                    rows.append(
                        f"<tr><td><code>{_e(str(cid))}</code> {_e(cname)}</td>"
                        f'<td class="num">{_fmt_n(np_)}</td>'
                        f'<td class="num">{pct_}</td></tr>'
                    )
                tbl = (
                    '<table class="rt"><thead><tr>'
                    '<th>Concept</th>'
                    '<th class="num">Patients (any time)</th><th class="num">% DX cohort</th>'
                    '</tr></thead><tbody>' + "\n".join(rows) + '</tbody></table>'
                )
                parts.append(_card(
                    f"Table 2.1 — Most frequent GDX concepts",
                    _tbl_wrap(tbl),
                ))

    # Tables 2.2a/b and Figures 2.1a/b — windowed ODX prevalence by anchor
    if windowed is not None:
        ac = _col(windowed, "anchor_event")
        fc = _col(windowed, "event_family")
        cid_col = _col(windowed, "concept_id")
        ne = _col(windowed, "n_ever")
        n30 = _col(windowed, "n_pm30d")
        n90 = _col(windowed, "n_pm90d")
        n180 = _col(windowed, "n_pm180d")
        n1y = _col(windowed, "n_pm1yr")
        neb = _col(windowed, "n_ever_before")
        nea = _col(windowed, "n_ever_after")

        def _odx_table(anchor_key: str, anchor_label: str, tbl_id: str) -> None:
            df = windowed.copy()
            if ac:
                df = df[df[ac].astype(str).str.upper() == anchor_key.upper()]
            if not all([fc, cid_col, ne]):
                return
            odx = df[df[fc].astype(str).str.upper() == "ODX"].copy()
            odx["__n"] = pd.to_numeric(odx[ne], errors="coerce")
            odx = odx[odx["__n"] > 0].nlargest(10, "__n")
            if odx.empty:
                return
            ids = [int(x) for x in odx[cid_col].dropna().astype(int).tolist()]
            names_map = _fetch_concept_names(ids)
            win_cols = [
                ("±30d", n30), ("±90d", n90), ("±180d", n180), ("±1yr", n1y),
                ("Ever before", neb), ("Ever after", nea), ("Ever", ne),
            ]
            win_cols = [(lbl, c) for lbl, c in win_cols if c]
            header = (
                '<table class="rt"><thead><tr><th>Concept</th>'
                + "".join(f'<th class="num">{l}</th>' for l, _ in win_cols)
                + '</tr></thead><tbody>'
            )
            rows = []
            for _, r in odx.iterrows():
                cid = _safe_int(r.get(cid_col))
                cname = names_map.get(cid, str(cid)) if cid else "?"
                cells = "".join(f'<td class="num">{_fmt_n(r.get(c))}</td>' for _, c in win_cols)
                rows.append(f"<tr><td><code>{cid}</code> {_e(cname)}</td>{cells}</tr>")
            tbl = header + "\n".join(rows) + "</tbody></table>"
            parts.append(_card(
                f"{tbl_id} — Windowed ODX prevalence relative to {anchor_label} index date",
                _tbl_wrap(tbl),
            ))

        _odx_table("INDEX",     "DX",  "Table 2.2a")
        _odx_table("FIRST_MET", "MET", "Table 2.2b")

        # Figures 2.1a/b — side by side grouped bar charts
        fig_21a = _windowed_odx_chart(windowed, n_denom=n_dx,  anchor="INDEX")
        fig_21b = _windowed_odx_chart(windowed, n_denom=n_met, anchor="FIRST_MET")
        if fig_21a or fig_21b:
            panels_21 = []
            if fig_21a:
                panels_21.append(_plot_box(
                    "Figure 2.1a — Windowed ODX prevalence: DX anchor (top 5 concepts)",
                    _fig_div(fig_21a),
                    sub="% of DX cohort with each ODX concept within each time window around DX index",
                ))
            if fig_21b:
                panels_21.append(_plot_box(
                    "Figure 2.1b — Windowed ODX prevalence: MET anchor (top 5 concepts)",
                    _fig_div(fig_21b),
                    sub="% of MET subgroup with each ODX concept within each time window around MET index",
                ))
            if len(panels_21) == 2:
                parts.append(f'<div class="card-grid card-grid-2" style="margin-bottom:16px;">{"".join(panels_21)}</div>')
            else:
                parts.extend(panels_21)

    # Figures 2.2a/b — ODX timing density histogram split by anchor (DX vs MET)
    if timing is not None:
        def _fig22_panel(from_ev: str, to_ev: str, fill: str, line: str, anchor_label: str) -> tuple[str, str]:
            fig22, stats22 = _density_histogram_chart(
                timing, from_ev, to_ev, "first_to_first",
                color_fill=fill, color_line=line,
                from_label=anchor_label, to_label="ODX",
            )
            if not fig22:
                return "", ""
            sub22 = ""
            if stats22:
                med22 = stats22.get("median")
                p25v22 = stats22.get("p25")
                p75v22 = stats22.get("p75")
                if med22 is not None:
                    iqr22 = f" (IQR {int(round(p25v22))}–{int(round(p75v22))})" if p25v22 and p75v22 else ""
                    sub22 = f"Anchored on {anchor_label} · days positive = ODX after {anchor_label} · median {int(round(med22))}d{iqr22}"
            return _fig_div(fig22), sub22

        div_a, sub_a = _fig22_panel("DX",  "ODX", "rgba(124,58,237,0.20)", "rgba(124,58,237,0.55)", "DX")
        div_b, sub_b = _fig22_panel("MET", "ODX", "rgba(180,83,9,0.20)",   "rgba(180,83,9,0.55)",   "MET")

        if div_a or div_b:
            panels = []
            if div_a:
                panels.append(_plot_box("Figure 2.2a — ODX timing relative to DX index (first to first)", div_a, sub=sub_a))
            if div_b:
                panels.append(_plot_box("Figure 2.2b — ODX timing relative to MET index (first to first)", div_b, sub=sub_b))
            if len(panels) == 2:
                parts.append(f'<div class="card-grid card-grid-2" style="margin-bottom:16px;">{"".join(panels)}</div>')
            else:
                parts.extend(panels)

    if not parts:
        parts.append('<p style="color:var(--text-3);font-style:italic;">GDX/ODX data not yet available.</p>')

    return _section(
        "02", "Broader & Co-occurring Cancer Codes (GDX / ODX)",
        "Frequency and timing of broader ancestor DX codes (GDX) and co-occurring other cancer codes "
        "(ODX) relative to the DX index date. Both are commonly used as exclusion criteria in "
        "metastatic cohort definitions. The windowed prevalence chart shows how often these codes "
        "appear within specific windows around the index date — a GDX code on the same day as DX "
        "is a fundamentally different phenomenon from one two years prior.",
        "\n".join(parts), sid="s2",
    )


# ── Section 3: Treatment Timing ──────────────────────────────────────────────────

def _s03_treatment_timing(rd: Path) -> str:
    timing = _read(rd, "final_timing_pairwise.csv")
    directionality = _read(rd, "final_directionality.csv")
    code_counts = _read(rd, "final_code_counts.csv")
    prev = _read(rd, "final_population_prevalence.csv")
    n_dx = None
    n_met_s3: int | None = None
    if prev is not None:
        oc = _col(prev, "prevalence_year")
        if oc:
            o = prev[prev[oc].astype(str).str.upper() == "OVERALL"]
            if not o.empty:
                n_dx = _safe_int(o.iloc[0].get(_col(prev, "n_dx")))
                n_met_s3 = _safe_int(o.iloc[0].get(_col(prev, "n_met")))

    # MET patients with L01 = sum of non-NO_EVENT rows for MET_L01 OVERALL
    n_met_l01: int | None = None
    if directionality is not None:
        pc = _col(directionality, "pair")
        yc = _col(directionality, "index_year")
        dc = _col(directionality, "direction")
        nc = _col(directionality, "n_patients")
        if pc and yc and dc and nc:
            sub = directionality[
                (directionality[pc].astype(str).str.upper() == "MET_L01") &
                (directionality[yc].astype(str).str.upper() == "OVERALL") &
                (directionality[dc].astype(str).str.upper() != "NO_EVENT")
            ]
            vals = pd.to_numeric(sub[nc], errors="coerce").dropna()
            total = int(vals[vals > 0].sum())
            if total > 0:
                n_met_l01 = total

    parts: list[str] = []

    # MET→L01 directionality
    if directionality is not None:
        tbl = _directionality_table(
            directionality, "MET_L01", _MET_L01_DIR_LABELS,
            n_total=n_met_l01, interp=_MET_L01_IMPLICATION, col4_header="Phenotype implication",
        )
        if tbl:
            n_lbl = f"N={n_met_l01:,}" if n_met_l01 else "MET+L01 subgroup"
            parts.append(_card(
                f"Table 3.1 — MET ↔ L01 temporal directionality (first to first)",
                tbl + f'<p class="tbl-note">MET patients with L01 only ({n_lbl}). % denominated on MET+L01 subgroup. NO_EVENT = patients with MET but no L01 ever.</p>',
            ))

    # MET→L01 timing distribution — two separate histograms
    if timing is not None:
        fig_a, stats_a = _density_histogram_chart(
            timing, "MET", "L01", "first_to_first",
            color_fill="rgba(29,78,216,0.20)", color_line="rgba(29,78,216,0.55)",
            from_label="MET", to_label="L01",
        )
        if fig_a:
            sub_a = ""
            if stats_a:
                med = stats_a.get("median")
                p25v = stats_a.get("p25")
                p75v = stats_a.get("p75")
                if med is not None:
                    iqr = f" (IQR {int(round(p25v))}–{int(round(p75v))})" if p25v and p75v else ""
                    sub_a = f"Anchored on first MET · includes L01 events before MET · median {int(round(med))}d{iqr}"
            parts.append(_plot_box(
                "Figure 3.1a — Time from first MET to first L01",
                _fig_div(fig_a), sub=sub_a,
            ))

        fig_b, stats_b = _density_histogram_chart(
            timing, "MET", "L01", "first_to_closest_after",
            color_fill="rgba(217,119,6,0.22)", color_line="rgba(217,119,6,0.55)",
            from_label="MET", to_label="L01",
        )
        if fig_b:
            sub_b = ""
            if stats_b:
                med = stats_b.get("median")
                p25v = stats_b.get("p25")
                p75v = stats_b.get("p75")
                if med is not None:
                    iqr = f" (IQR {int(round(p25v))}–{int(round(p75v))})" if p25v and p75v else ""
                    sub_b = f"Anchored on first MET · L01 on or after MET only · median {int(round(med))}d{iqr}"
            parts.append(_plot_box(
                "Figure 3.1b — Time from first MET to first L01 on or after MET",
                _fig_div(fig_b), sub=sub_b,
            ))

    # Drug-level L01 codes table (top 15 by FIRST_MET anchor) — with before/after breakdown
    if code_counts is not None:
        ac = _col(code_counts, "anchor_event")
        fc_col = _col(code_counts, "event_family")
        twc = _col(code_counts, "time_window")
        cid_col = _col(code_counts, "concept_id")
        np_col = _col(code_counts, "n_patients")
        med_first_c = _col(code_counts, "median_days_first")
        lq_first_c = _col(code_counts, "lq_days_first")
        uq_first_c = _col(code_counts, "uq_days_first")
        med_clos_c = _col(code_counts, "median_days_closest")
        lq_clos_c = _col(code_counts, "lq_days_closest")
        uq_clos_c = _col(code_counts, "uq_days_closest")
        if all([ac, fc_col, twc, cid_col, np_col]):
            def _l01_tw(tw: str) -> pd.DataFrame:
                return code_counts[
                    (code_counts[ac].astype(str).str.upper() == "FIRST_MET") &
                    (code_counts[fc_col].astype(str).str.upper() == "L01") &
                    (code_counts[twc].astype(str).str.lower() == tw)
                ].copy()
            l01_all = _l01_tw("all")
            l01_before = _l01_tw("before")
            l01_after = _l01_tw("after")
            l01_all["__n"] = pd.to_numeric(l01_all[np_col], errors="coerce")
            top_ids_df = l01_all[l01_all["__n"] > 0].nlargest(CODE_COUNTS_TOP_N, "__n")
            if not top_ids_df.empty:
                ids = [int(x) for x in top_ids_df[cid_col].dropna().astype(int).tolist()]
                names_map = _fetch_concept_names(ids)

                def _n_by_cid(df_tw: pd.DataFrame) -> dict[int, int]:
                    m: dict[int, int] = {}
                    for _, r in df_tw.iterrows():
                        cid = _safe_int(r.get(cid_col))
                        n = _safe_int(r.get(np_col))
                        if cid is not None and n is not None and n > 0:
                            m[cid] = n
                    return m

                before_map = _n_by_cid(l01_before)
                after_map = _n_by_cid(l01_after)

                def _iqr_after(cid_val: int | None) -> str:
                    if not cid_val or not med_clos_c:
                        return "—"
                    sub = l01_after[l01_after[cid_col].apply(_safe_int) == cid_val]
                    if sub.empty:
                        return "—"
                    r = sub.iloc[0]
                    return _fmt_iqr(r.get(med_clos_c), r.get(lq_clos_c) if lq_clos_c else None, r.get(uq_clos_c) if uq_clos_c else None)

                def _iqr_first(cid_val: int | None) -> str:
                    if not cid_val or not med_first_c:
                        return "—"
                    sub = l01_all[l01_all[cid_col].apply(_safe_int) == cid_val]
                    if sub.empty:
                        return "—"
                    r = sub.iloc[0]
                    return _fmt_iqr(r.get(med_first_c), r.get(lq_first_c) if lq_first_c else None, r.get(uq_first_c) if uq_first_c else None)

                rows = []
                for _, r in top_ids_df.iterrows():
                    cid = _safe_int(r.get(cid_col))
                    cname = names_map.get(cid, "") if cid else ""
                    np_ = _safe_int(r.get(np_col))
                    pct_met = _pct_of(np_, n_met_s3) if n_met_s3 else "—"
                    n_bef = before_map.get(cid, 0) if cid else 0
                    n_aft = after_map.get(cid, 0) if cid else 0
                    pct_bef = _pct_of(n_bef, np_) if np_ else "—"
                    pct_aft = _pct_of(n_aft, np_) if np_ else "—"
                    iqr_first_str = _iqr_first(cid)
                    iqr_after_str = _iqr_after(cid)
                    rows.append(
                        f"<tr><td><code>{_e(str(cid))}</code> {_e(cname)}</td>"
                        f'<td class="num">{_fmt_n(np_)}</td>'
                        f'<td class="num">{pct_met}</td>'
                        f'<td class="num">{pct_bef}</td>'
                        f'<td class="num">{pct_aft}</td>'
                        f'<td class="num">{_e(iqr_first_str)}</td>'
                        f'<td class="num">{_e(iqr_after_str)}</td></tr>'
                    )
                n_met_lbl = f"N={n_met_s3:,}" if n_met_s3 else "MET cohort"
                tbl = (
                    '<table class="rt"><thead><tr>'
                    '<th>Concept</th>'
                    f'<th class="num">N patients</th>'
                    f'<th class="num">% of MET cohort ({n_met_lbl})</th>'
                    '<th class="num">% with record before MET</th>'
                    '<th class="num">% with record after MET</th>'
                    '<th class="num">Median days (IQR) — first occurrence</th>'
                    '<th class="num">Median days (IQR) — closest after</th>'
                    '</tr></thead><tbody>' + "\n".join(rows) + '</tbody></table>'
                )
                parts.append(_card(
                    f"Table 3.2 — Drug-level L01 timing around MET (top {CODE_COUNTS_TOP_N})",
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
    day_count = _read(rd, "final_l01_day_count_buckets.csv")

    parts: list[str] = []

    # L01 treatment windows — side-by-side Figures 4.1 / 4.2
    if windows is not None:
        fig_41 = _l01_windows_chart(windows, anchor_filter="INDEX")
        fig_42 = _l01_windows_chart(windows, anchor_filter="FIRST_MET")
        if fig_41 or fig_42:
            parts.append(
                f'<div class="card-grid card-grid-2" style="margin-bottom:16px;">'
                + (_plot_box("Figure 4.1 — % cohort with L01 per 30-day window (DX anchor)", _fig_div(fig_41)) if fig_41 else "")
                + (_plot_box("Figure 4.2 — % MET subgroup with L01 per 30-day window (MET anchor)", _fig_div(fig_42)) if fig_42 else "")
                + "</div>"
            )

    # Figures 4.4a/b — distinct L01 treatment days per patient (DX cohort / MET subgroup)
    if day_count is not None:
        fig_44a = _day_count_chart(day_count, "ALL_L01")
        fig_44b = _day_count_chart(day_count, "MET_L01")
        if fig_44a or fig_44b:
            parts.append(
                f'<div class="card-grid card-grid-2" style="margin-bottom:16px;">'
                + (_plot_box(
                    "Figure 4.4a — Distinct L01 treatment days per patient (DX cohort)",
                    _fig_div(fig_44a),
                    sub="Patients with exactly 1 distinct day have no consecutive gap to measure",
                ) if fig_44a else "")
                + (_plot_box(
                    "Figure 4.4b — Distinct L01 treatment days per patient (MET subgroup)",
                    _fig_div(fig_44b),
                    sub="Patients with exactly 1 distinct day have no consecutive gap to measure",
                ) if fig_44b else "")
                + "</div>"
            )

    # Figure 4.3 — gap bucket distribution (all four subgroups)
    if gap_buckets is not None:
        fig = _gap_bucket_chart(gap_buckets)
        if fig:
            parts.append(_plot_box(
                "Figure 4.3 — Distribution of gaps between consecutive L01 records", _fig_div(fig),
                sub="All gaps (dark) vs largest gap per patient (light) · DX cohort (blue) and MET subgroup (amber)",
            ))

    # Fixed-row gap summary table (Table 4.1)
    prev_s4 = _read(rd, "final_population_prevalence.csv")
    n_l01_s4: int | None = None
    n_met_s4: int | None = None
    if prev_s4 is not None:
        oc4 = _col(prev_s4, "prevalence_year")
        if oc4:
            ov4 = prev_s4[prev_s4[oc4].astype(str).str.upper() == "OVERALL"]
            if not ov4.empty:
                n_l01_s4 = _safe_int(ov4.iloc[0].get(_col(prev_s4, "n_l01")))
                n_met_s4 = _safe_int(ov4.iloc[0].get(_col(prev_s4, "n_met")))

    n_l01_lbl = f"All L01 patients (N={n_l01_s4:,})" if n_l01_s4 else "All L01 patients"
    n_met_lbl = f"MET subgroup (N={n_met_s4:,})" if n_met_s4 else "MET subgroup"

    if gap_deciles is not None:
        sc = _col(gap_deciles, "subgroup")
        ng = _col(gap_deciles, "n_gaps")
        np_ = _col(gap_deciles, "n_patients_with_gaps")
        p25 = _col(gap_deciles, "p25_days")
        p50 = _col(gap_deciles, "p50_days")
        p75 = _col(gap_deciles, "p75_days")
        if sc and ng and p50:
            decile_map: dict[str, Any] = {}
            for _, r in gap_deciles.iterrows():
                sg = str(r.get(sc, "")).upper()
                decile_map[sg] = r

            def _dval(sg: str, col: str | None) -> str:
                r = decile_map.get(sg)
                if r is None or col is None:
                    return "—"
                return _fmt_n(r.get(col))

            def _diqr(sg: str) -> str:
                r = decile_map.get(sg)
                if r is None:
                    return "—"
                return _fmt_iqr(r.get(p50) if p50 else None,
                                r.get(p25) if p25 else None,
                                r.get(p75) if p75 else None)

            fixed_rows = [
                ("Patients with ≥2 L01 records (gap measurable)", _dval("ALL_L01", np_), _dval("MET_L01", np_)),
                ("Median gap, days (IQR)", _diqr("ALL_L01"), _diqr("MET_L01")),
            ]

            if gap_buckets is not None:
                bc = _col(gap_buckets, "gap_bucket")
                nc_gb = _col(gap_buckets, "n_gaps") or _col(gap_buckets, "n_patients")
                gc_gb = _col(gap_buckets, "subgroup")
                if bc and nc_gb:
                    def _bkt(sg_key: str, bkt: str) -> str:
                        if gc_gb:
                            sub_gb = gap_buckets[gap_buckets[gc_gb].astype(str).str.upper() == sg_key]
                        else:
                            sub_gb = gap_buckets
                        row_gb = sub_gb[sub_gb[bc].astype(str) == bkt]
                        if row_gb.empty:
                            return "—"
                        total_gaps_sg = _safe_int(decile_map.get(sg_key, {}).get(ng)) if ng else None
                        n_bkt = _safe_int(row_gb.iloc[0].get(nc_gb))
                        return _pct_of(n_bkt, total_gaps_sg)

                    for bkt, bkt_lbl in [("lt30d", "% gaps < 30d"), ("30_59d", "% gaps 30–59d"),
                                         ("60_89d", "% gaps 60–89d"), ("90_179d", "% gaps 90–179d"),
                                         ("ge180d", "% gaps ≥ 180d")]:
                        fixed_rows.append((bkt_lbl, _bkt("ALL_L01", bkt), _bkt("MET_L01", bkt)))

            tbl = (
                f'<table class="rt"><thead><tr>'
                f'<th>Metric</th><th class="num">{n_l01_lbl}</th><th class="num">{n_met_lbl}</th>'
                f'</tr></thead><tbody>'
                + "".join(
                    f'<tr><td>{_e(m)}</td><td class="num">{a}</td><td class="num">{b}</td></tr>'
                    for m, a, b in fixed_rows
                )
                + '</tbody></table>'
            )
            parts.append(_card(
                f"Table 4.1 — L01 gap distribution summary: all L01 patients vs MET subgroup",
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

    # ── Column handles ─────────────────────────────────────────────────────────
    ac_col  = _col(death, "anchor_event")       if death is not None else None
    yc_col  = _col(death, "prevalence_year")    if death is not None else None
    nc_col  = _col(death, "n_patients")         if death is not None else None
    nd_col  = _col(death, "n_deaths")           if death is not None else None
    nio_col = _col(death, "n_deaths_in_obs")    if death is not None else None
    noo_col = _col(death, "n_deaths_out_obs")   if death is not None else None
    medf_col = _col(death, "median_followup_days") if death is not None else None
    lqf_col  = _col(death, "lq_followup_days")    if death is not None else None
    uqf_col  = _col(death, "uq_followup_days")    if death is not None else None

    def _death_overall(anchor: str) -> Any | None:
        if death is None or not ac_col or not yc_col:
            return None
        rows = death[
            (death[ac_col].astype(str).str.upper() == anchor.upper()) &
            (death[yc_col].astype(str).str.upper() == "OVERALL")
        ]
        return rows.iloc[0] if not rows.empty else None

    def _obs_gap_iqr(anchor: str) -> str:
        if gap_summary is None:
            return "—"
        ac_gs = _col(gap_summary, "anchor_event")
        if not ac_gs:
            return "—"
        rows = gap_summary[gap_summary[ac_gs].astype(str).str.upper() == anchor.upper()]
        if rows.empty:
            return "—"
        gs_r = rows.iloc[0]
        return _fmt_iqr(
            gs_r.get(_col(gap_summary, "median_gap_days")),
            gs_r.get(_col(gap_summary, "lq_gap_days")),
            gs_r.get(_col(gap_summary, "uq_gap_days")),
        )

    # ── Stat boxes — DX cohort (4 boxes) ──────────────────────────────────────
    if death is not None and ac_col and nc_col and nd_col:
        r = _death_overall("INDEX")
        if r is not None:
            np_val  = _safe_int(r.get(nc_col))
            nd_val  = _safe_int(r.get(nd_col))
            nio_val = _safe_int(r.get(nio_col)) if nio_col else None
            noo_val = _safe_int(r.get(noo_col)) if noo_col else None
            pct_dead   = f"{100.0 * nd_val / np_val:.1f}%"   if nd_val  and np_val  and np_val  > 0 else "—"
            pct_in     = f"{100.0 * nio_val / nd_val:.1f}%"  if nio_val and nd_val  and nd_val  > 0 else "—"
            pct_out    = f"{100.0 * noo_val / nd_val:.1f}%"  if noo_val and nd_val  and nd_val  > 0 else "—"
            nd_bef_val = max(0, nd_val - (nio_val or 0) - (noo_val or 0)) if nd_val else None
            pct_before = f"{100.0 * nd_bef_val / nd_val:.1f}%" if nd_bef_val and nd_val and nd_val > 0 else "—"
            parts.append(_card_grid(
                _stat_box(_fmt_n(nd_val), "Deaths recorded (DX cohort)", pct=pct_dead),
                _stat_box(_fmt_n(nio_val) if nio_val else "—", "Death within obs. period", pct=pct_in, cls="highlight"),
                _stat_box(_fmt_n(noo_val) if noo_val else "—", "Death AFTER obs. period end", pct=pct_out, cls="alert"),
                _stat_box(_fmt_n(nd_bef_val) if nd_bef_val else "—", "Death BEFORE obs. period start", pct=pct_before, cls="warn"),
                cols=4,
            ))

    # ── Stat boxes — MET subgroup (3 boxes) ───────────────────────────────────
    if death is not None and ac_col and nc_col and nd_col:
        r = _death_overall("FIRST_MET")
        if r is not None:
            np_val_m  = _safe_int(r.get(nc_col))
            nd_val_m  = _safe_int(r.get(nd_col))
            nio_val_m = _safe_int(r.get(nio_col)) if nio_col else None
            noo_val_m = _safe_int(r.get(noo_col)) if noo_col else None
            pct_dead_m = f"{100.0 * nd_val_m / np_val_m:.1f}%" if nd_val_m and np_val_m and np_val_m > 0 else "—"
            pct_in_m   = f"{100.0 * nio_val_m / nd_val_m:.1f}%" if nio_val_m and nd_val_m and nd_val_m > 0 else "—"
            pct_out_m  = f"{100.0 * noo_val_m / nd_val_m:.1f}%" if noo_val_m and nd_val_m and nd_val_m > 0 else "—"
            parts.append(_card_grid(
                _stat_box(_fmt_n(nd_val_m), "Deaths recorded (MET subgroup)", pct=pct_dead_m),
                _stat_box(_fmt_n(nio_val_m) if nio_val_m else "—", "Death within obs. period", pct=pct_in_m, cls="highlight"),
                _stat_box(_fmt_n(noo_val_m) if noo_val_m else "—", "Death AFTER obs. period end", pct=pct_out_m, cls="alert"),
                cols=3,
            ))

    # ── Table 5.1 — death vs obs alignment, both anchors ──────────────────────
    if death is not None and ac_col and yc_col and nc_col and nd_col:
        r_i = _death_overall("INDEX")
        r_m = _death_overall("FIRST_MET")
        if r_i is not None:
            def _row_vals(r: Any | None) -> tuple:
                if r is None:
                    return None, None, None, None, None
                np_ = _safe_int(r.get(nc_col))
                nd_ = _safe_int(r.get(nd_col))
                nio_ = _safe_int(r.get(nio_col)) if nio_col else None
                noo_ = _safe_int(r.get(noo_col)) if noo_col else None
                return np_, nd_, nio_, noo_, max(0, nd_ - (nio_ or 0) - (noo_ or 0)) if nd_ else None

            np_i, nd_i, nio_i, noo_i, nbef_i = _row_vals(r_i)
            np_m, nd_m, nio_m, noo_m, nbef_m = _row_vals(r_m)

            def _dual_row(cat: str, cls: str,
                          n_i: str, pct_i: str, gap_i: str,
                          n_m: str, pct_m: str, gap_m: str,
                          imp: str) -> str:
                row_cls = ' class="highlight"' if cls == "highlight" else ""
                return (
                    f'<tr{row_cls}><td>{_e(cat)}</td>'
                    f'<td class="num">{n_i}</td><td class="num">{pct_i}</td><td class="num">{gap_i}</td>'
                    f'<td class="num">{n_m}</td><td class="num">{pct_m}</td><td class="num">{gap_m}</td>'
                    f'<td>{imp}</td></tr>'
                )

            rows_51 = [
                _dual_row("Death within obs. period", "highlight",
                          _fmt_n(nio_i), _pct_of(nio_i, np_i), "—",
                          _fmt_n(nio_m), _pct_of(nio_m, np_m), "—",
                          "Correctly censored; obs. period end is a valid study end point"),
                _dual_row("Death AFTER obs. period end", "warn",
                          _fmt_n(noo_i), _pct_of(noo_i, np_i), _obs_gap_iqr("INDEX"),
                          _fmt_n(noo_m), _pct_of(noo_m, np_m), _obs_gap_iqr("FIRST_MET"),
                          "Death missed by observation window — inflates apparent survival"),
                _dual_row("Death BEFORE obs. period start", "",
                          _fmt_n(nbef_i), _pct_of(nbef_i, np_i), "—",
                          _fmt_n(nbef_m), _pct_of(nbef_m, np_m), "—",
                          "Likely data entry error or retro-coded death date"),
            ]
            n_i_lbl = f"N (DX cohort, N={_fmt_n(np_i)})"
            n_m_lbl = f"N (MET subgroup, N={_fmt_n(np_m)})" if np_m else "N (MET subgroup)"
            tbl = (
                '<table class="rt"><thead><tr>'
                f'<th>Category</th>'
                f'<th class="num">{_e(n_i_lbl)}</th><th class="num">%</th><th class="num">Gap IQR (DX)</th>'
                f'<th class="num">{_e(n_m_lbl)}</th><th class="num">%</th><th class="num">Gap IQR (MET)</th>'
                f'<th>Implication</th>'
                '</tr></thead><tbody>' + "".join(rows_51) + '</tbody></table>'
            )
            parts.append(_card("Table 5.1 — Death vs observation period alignment", _tbl_wrap(tbl)))

    # ── Table 5.2 — year-by-year deaths, both anchors interleaved ─────────────
    if death is not None and ac_col and yc_col and nc_col and nd_col:
        def _yearly(anchor: str) -> pd.DataFrame:
            df_ = death[
                (death[ac_col].astype(str).str.upper() == anchor.upper()) &
                (death[yc_col].astype(str).str.upper() != "OVERALL")
            ].copy()
            df_["__y"] = pd.to_numeric(df_[yc_col].astype(str), errors="coerce")
            df_ = df_.dropna(subset=["__y"]).sort_values("__y")
            return df_[df_["__y"] >= PREVALENCE_YEAR_MIN]

        yi = _yearly("INDEX")
        ym = _yearly("FIRST_MET")

        if not yi.empty:
            ov_i = _death_overall("INDEX")
            ov_m = _death_overall("FIRST_MET")
            all_years = sorted(set(yi["__y"].tolist()) | set(ym["__y"].tolist()))

            all_52: list[tuple] = []
            if ov_i is not None:
                all_52.append(("Overall", ov_i, "INDEX", True))
            if ov_m is not None:
                all_52.append(("", ov_m, "FIRST_MET", True))
            for y in all_years:
                ri = yi[yi["__y"] == y]
                rm = ym[ym["__y"] == y]
                if not ri.empty:
                    all_52.append((str(int(y)), ri.iloc[0], "INDEX", False))
                if not rm.empty:
                    all_52.append(("", rm.iloc[0], "FIRST_MET", False))

            rows_52 = []
            for yr_lbl, r, anch, is_overall in all_52:
                anchor_lbl = "Index DX" if anch == "INDEX" else "First MET"
                np_ = _safe_int(r.get(nc_col))
                nd_ = _safe_int(r.get(nd_col))
                nio_ = _safe_int(r.get(nio_col)) if nio_col else None
                noo_ = _safe_int(r.get(noo_col)) if noo_col else None
                pct_dead = f"{100.0 * nd_ / np_:.1f}%" if nd_ and np_ and np_ > 0 else "—"
                pct_out  = f"{100.0 * noo_ / nd_:.1f}%" if noo_ and nd_ and nd_ > 0 else "—"
                fup = _fmt_iqr(r.get(medf_col) if medf_col else None,
                               r.get(lqf_col)  if lqf_col  else None,
                               r.get(uqf_col)  if uqf_col  else None)
                row_cls = ' class="highlight"' if is_overall and anch == "INDEX" else ""
                rows_52.append(
                    f'<tr{row_cls}>'
                    f'<td>{_e(yr_lbl)}</td><td>{_e(anchor_lbl)}</td>'
                    f'<td class="num">{_fmt_n(np_)}</td>'
                    f'<td class="num">{_fmt_n(nd_)} ({pct_dead})</td>'
                    f'<td class="num">{_fmt_n(nio_)}</td>'
                    f'<td class="num">{_fmt_n(noo_)} ({pct_out})</td>'
                    f'<td class="num">{_e(fup)}</td>'
                    f'</tr>'
                )

            tbl = (
                '<table class="rt"><thead><tr>'
                '<th>Year</th><th>Anchor</th><th class="num">N</th>'
                '<th class="num">Deaths (%)</th>'
                '<th class="num">Deaths in obs. period</th>'
                '<th class="num">Deaths outside obs. period</th>'
                '<th class="num">Follow-up days (IQR)</th>'
                '</tr></thead><tbody>' + "\n".join(rows_52) + '</tbody></table>'
            )
            parts.append(_card(
                "Table 5.2 — Deaths by year: inside vs outside observation period",
                _tbl_wrap(tbl),
            ))

    # ── Figures 5.1a/b — death gap bucket histograms ──────────────────────────
    if gap_buckets is not None:
        ac_gb = _col(gap_buckets, "anchor_event")
        if ac_gb:
            gb_i = gap_buckets[gap_buckets[ac_gb].astype(str).str.upper() == "INDEX"]
            gb_m = gap_buckets[gap_buckets[ac_gb].astype(str).str.upper() == "FIRST_MET"]
        else:
            gb_i = gap_buckets
            gb_m = pd.DataFrame()
        fig_51a = _gap_bucket_chart(gb_i, n_col="n_patients", group_col=None) if not gb_i.empty else None
        fig_51b = _gap_bucket_chart(gb_m, n_col="n_patients", group_col=None) if not gb_m.empty else None
        if fig_51a or fig_51b:
            parts.append(
                f'<div class="card-grid card-grid-2" style="margin-bottom:16px;">'
                + (_plot_box("Figure 5.1a — Death gap: DX cohort", _fig_div(fig_51a),
                             sub="Days from obs. period end to death · DX cohort") if fig_51a else "")
                + (_plot_box("Figure 5.1b — Death gap: MET subgroup", _fig_div(fig_51b),
                             sub="Days from obs. period end to death · MET subgroup") if fig_51b else "")
                + "</div>"
            )

    # ── Figures 5.2a/b — deaths by calendar year ──────────────────────────────
    if death is not None:
        fig_52a = _death_obs_chart(death, anchor="INDEX")
        fig_52b = _death_obs_chart(death, anchor="FIRST_MET")
        if fig_52a or fig_52b:
            parts.append(
                f'<div class="card-grid card-grid-2" style="margin-bottom:16px;">'
                + (_plot_box("Figure 5.2a — Deaths by calendar year: DX cohort", _fig_div(fig_52a),
                             sub="% deaths outside obs. period is the key data quality signal") if fig_52a else "")
                + (_plot_box("Figure 5.2b — Deaths by calendar year: MET subgroup", _fig_div(fig_52b),
                             sub="% deaths outside obs. period is the key data quality signal") if fig_52b else "")
                + "</div>"
            )

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
    prev = _read(rd, "final_population_prevalence.csv")
    death = _read(rd, "final_death_from_anchors.csv")

    parts: list[str] = []

    # Table 6.1 — year-by-year timing matrix with N(DX), N(MET), % death outside obs.
    prev_by_year: dict[int, Any] = {}
    if prev is not None:
        yc_p = _col(prev, "prevalence_year")
        if yc_p:
            for _, r in prev.iterrows():
                yr_str = str(r.get(yc_p, "")).upper()
                if yr_str != "OVERALL":
                    try:
                        yr = int(float(yr_str))
                        if yr >= PREVALENCE_YEAR_MIN:
                            prev_by_year[yr] = r
                    except (ValueError, TypeError):
                        pass

    death_by_year: dict[int, Any] = {}
    if death is not None:
        ac_d = _col(death, "anchor_event")
        yc_d = _col(death, "prevalence_year")
        if ac_d and yc_d:
            for _, r in death.iterrows():
                if str(r.get(ac_d, "")).upper() != "INDEX":
                    continue
                yr_str = str(r.get(yc_d, "")).upper()
                if yr_str != "OVERALL":
                    try:
                        yr = int(float(yr_str))
                        if yr >= PREVALENCE_YEAR_MIN:
                            death_by_year[yr] = r
                    except (ValueError, TypeError):
                        pass

    all_years = sorted(set(prev_by_year.keys()) | set(death_by_year.keys()))

    # Timing medians from by_year if available
    timing_by_yr: dict[tuple[str, str], dict[int, float | None]] = {}
    if by_year is not None:
        ttc = _col(by_year, "timing_type")
        fc = _col(by_year, "from_event")
        tc = _col(by_year, "to_event")
        yc = _col(by_year, "index_year")
        mc = _col(by_year, "p50_days")
        if all([fc, tc, yc, mc]):
            for pair in [("DX", "MET"), ("MET", "L01")]:
                sub = by_year.copy()
                if ttc:
                    sub = sub[sub[ttc].astype(str).str.lower() == "first_to_first"]
                sub = sub[
                    sub[fc].astype(str).str.upper().eq(pair[0]) &
                    sub[tc].astype(str).str.upper().eq(pair[1])
                ].copy()
                sub["__y"] = pd.to_numeric(sub[yc].astype(str), errors="coerce")
                sub = sub.dropna(subset=["__y"])
                timing_by_yr[pair] = {
                    int(r["__y"]): pd.to_numeric(r.get(mc), errors="coerce")
                    for _, r in sub.iterrows()
                }

    # Directionality % by year
    dir_by_yr_before: dict[int, str] = {}
    dir_by_yr_no_l01: dict[int, str] = {}
    if directionality is not None:
        pc = _col(directionality, "pair")
        yc_dir = _col(directionality, "index_year")
        dc = _col(directionality, "direction")
        nc_dir = _col(directionality, "n_patients")
        if all([pc, yc_dir, dc, nc_dir]):
            for pair_key, dir_key, target_dict in [
                ("DX_MET", "BEFORE_GT90", dir_by_yr_before),
                ("MET_L01", "NO_EVENT", dir_by_yr_no_l01),
            ]:
                sub = directionality[
                    (directionality[pc].astype(str).str.upper() == pair_key) &
                    (directionality[dc].astype(str).str.upper() == dir_key) &
                    (directionality[yc_dir].astype(str).str.upper() != "OVERALL")
                ].copy()
                sub["__y"] = pd.to_numeric(sub[yc_dir].astype(str), errors="coerce")
                for _, r in sub.dropna(subset=["__y"]).iterrows():
                    yr = int(r["__y"])
                    if yr >= PREVALENCE_YEAR_MIN:
                        n_dir = _safe_int(r.get(nc_dir))
                        prev_r = prev_by_year.get(yr)
                        denom = _safe_int(prev_r.get(_col(prev, "n_met"))) if prev_r is not None and prev is not None else None
                        target_dict[yr] = _pct_of(n_dir, denom)

    if all_years:
        rows = []
        for yr in all_years:
            prev_r = prev_by_year.get(yr)
            death_r = death_by_year.get(yr)
            n_dx_yr = _fmt_n(_safe_int(prev_r.get(_col(prev, "n_dx"))) if prev_r is not None and prev is not None else None)
            n_met_yr = _fmt_n(_safe_int(prev_r.get(_col(prev, "n_met"))) if prev_r is not None and prev is not None else None)
            pct_met_before = dir_by_yr_before.get(yr, "—")
            dx_met_med = timing_by_yr.get(("DX", "MET"), {}).get(yr)
            dx_met_str = f"{int(round(dx_met_med))}d" if dx_met_med is not None and not (isinstance(dx_met_med, float) and pd.isna(dx_met_med)) else "—"
            pct_l01_before = dir_by_yr_no_l01.get(yr, "—")
            met_l01_med = timing_by_yr.get(("MET", "L01"), {}).get(yr)
            met_l01_str = f"{int(round(met_l01_med))}d" if met_l01_med is not None and not (isinstance(met_l01_med, float) and pd.isna(met_l01_med)) else "—"
            pct_no_l01 = "—"
            pct_death_out = "—"
            if death_r is not None and death is not None:
                nd_ = _safe_int(death_r.get(_col(death, "n_deaths")))
                noo_ = _safe_int(death_r.get(_col(death, "n_deaths_out_obs"))) if _col(death, "n_deaths_out_obs") else None
                pct_death_out = _pct_of(noo_, nd_)
            rows.append(
                f"<tr><td>{yr}</td>"
                f'<td class="num">{n_dx_yr}</td>'
                f'<td class="num">{n_met_yr}</td>'
                f'<td class="num">{pct_met_before}</td>'
                f'<td class="num">{dx_met_str}</td>'
                f'<td class="num">{pct_l01_before}</td>'
                f'<td class="num">{met_l01_str}</td>'
                f'<td class="num">{pct_no_l01}</td>'
                f'<td class="num">{pct_death_out}</td>'
                f'</tr>'
            )
        tbl = (
            '<table class="rt"><thead><tr>'
            '<th>Year</th>'
            '<th class="num">N (DX)</th>'
            '<th class="num">N (MET)</th>'
            '<th class="num">% MET before DX</th>'
            '<th class="num">DX→MET median (d)</th>'
            '<th class="num">% L01 before MET</th>'
            '<th class="num">MET→L01 median (d)</th>'
            '<th class="num">% no L01 (MET cohort)</th>'
            '<th class="num">% death outside obs.</th>'
            '</tr></thead><tbody>' + "\n".join(rows) + '</tbody></table>'
        )
        parts.append(_card(
            f"Table 6.1 — Timing summary matrix by index year",
            tbl,
        ))

    # Multi-line timing by year chart
    if by_year is not None:
        fig = _timing_by_year_chart(by_year)
        if fig:
            parts.append(_plot_box(
                "Figure 6.1 — Key timing metrics by index year",
                _fig_div(fig),
                sub="DX→MET and MET→L01 median days by index year · trend shifts indicate coding or guideline changes",
            ))

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
            years_dir = sorted(dx_met["__y"].dropna().astype(int).unique().tolist())
            directions = [d for d in _DIR_ORDER if d != "SAME_DAY"]
            if years_dir and not dx_met.empty:
                ths = "".join(f"<th>{y}</th>" for y in years_dir)
                rows2 = []
                for d in directions:
                    sub_d = dx_met[dx_met[dc].astype(str).str.upper() == d]
                    year_counts = dict(zip(
                        sub_d["__y"].astype(int).tolist(),
                        pd.to_numeric(sub_d[nc], errors="coerce").tolist(),
                    ))
                    _, label = _DIR_LABELS.get(d, ("none", d))
                    cells = "".join(
                        f'<td class="num">{_fmt_n(year_counts.get(y))}</td>'
                        for y in years_dir
                    )
                    rows2.append(f"<tr><td>{_e(label)}</td>{cells}</tr>")
                if rows2:
                    tbl2 = (
                        '<div class="hm-wrap"><table class="rt"><thead><tr>'
                        f'<th>Direction (DX→MET)</th>{ths}'
                        '</tr></thead><tbody>' + "\n".join(rows2) + '</tbody></table></div>'
                    )
                    parts.append(_card(
                        f"Table 6.2 — DX→MET directionality by index year",
                        tbl2,
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
        "Key phenotyping metrics stratified by index year. "
        "N(DX) and N(MET) are populated from population prevalence data; timing medians and "
        "directionality % require the full SQL run. Stable metrics suggest consistent coding "
        "behaviour; abrupt shifts may indicate EHR migrations, guideline changes, or selection artefacts.",
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
  .report-header::after { content: ''; position: absolute; bottom: -40px; left: 200px; width: 200px; height: 200px; border-radius: 50%; background: rgba(255,255,255,0.03); }
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
  .plot-header-sub { font-size: 11px; color: var(--text-3); }
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
  .wbars { display: flex; flex-direction: column; gap: 4px; }
  .wbar-row { display: flex; align-items: center; gap: 8px; font-size: 12px; }
  .wbar-label { width: 120px; text-align: right; color: var(--text-2); font-family: var(--mono); font-size: 11px; flex-shrink: 0; }
  .wbar-track { flex: 1; background: var(--surface2); border-radius: 3px; height: 14px; overflow: hidden; }
  .wbar-fill { height: 100%; background: var(--accent); border-radius: 3px; opacity: 0.75; }
  .wbar-val { width: 48px; text-align: right; font-family: var(--mono); font-size: 11px; color: var(--text-3); }
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

def build_report(outputs_dir: str | Path) -> Path:
    import datetime
    global _plotly_included
    _plotly_included = False

    rd = Path(outputs_dir).expanduser().resolve()
    out = rd / OUT_FILE

    generated_at = datetime.datetime.now().strftime("%Y-%m-%d %H:%M")

    # Populate header stats from prevalence CSV
    n_dx_hdr: int | None = None
    n_met_hdr: int | None = None
    year_range_hdr = "—"
    prev_hdr = _read(rd, "final_population_prevalence.csv")
    if prev_hdr is not None:
        yc_h = _col(prev_hdr, "prevalence_year")
        if yc_h:
            ov_h = prev_hdr[prev_hdr[yc_h].astype(str).str.upper() == "OVERALL"]
            if not ov_h.empty:
                n_dx_hdr = _safe_int(ov_h.iloc[0].get(_col(prev_hdr, "n_dx")))
                n_met_hdr = _safe_int(ov_h.iloc[0].get(_col(prev_hdr, "n_met")))
            yr_rows = prev_hdr[prev_hdr[yc_h].astype(str).str.upper() != "OVERALL"].copy()
            yr_rows["__y"] = pd.to_numeric(yr_rows[yc_h].astype(str), errors="coerce")
            ndx_c = _col(prev_hdr, "n_dx")
            if ndx_c:
                yr_rows = yr_rows[pd.to_numeric(yr_rows[ndx_c], errors="coerce") > 0]
            yr_rows = yr_rows.dropna(subset=["__y"])
            if not yr_rows.empty:
                mn_yr = int(yr_rows["__y"].min())
                mx_yr = int(yr_rows["__y"].max())
                year_range_hdr = f"{mn_yr}–{mx_yr}"

    n_dx_str = f"{n_dx_hdr:,}" if n_dx_hdr else "—"
    n_met_str = f"{n_met_hdr:,}" if n_met_hdr else "—"
    met_pct_str = f" ({100.0*n_met_hdr/n_dx_hdr:.1f}%)" if n_met_hdr and n_dx_hdr and n_dx_hdr > 0 else ""

    header = f"""
<header class="report-header">
  <div class="header-tag">Oncology Phenotype Characterisation</div>
  <h1 class="report-title">Data Characterisation Report</h1>
  <p class="report-subtitle">OMOP CDM · ATC L01 Antineoplastics · Metastasis cohort</p>
  <div class="header-meta">
    <div class="meta-item"><strong>Source database</strong>{_e(str(rd))}</div>
    <div class="meta-item"><strong>DX cohort (N)</strong>{n_dx_str}</div>
    <div class="meta-item"><strong>MET subgroup (N)</strong>{n_met_str}{met_pct_str}</div>
    <div class="meta-item"><strong>Index years</strong>{year_range_hdr}</div>
    <div class="meta-item"><strong>Generated</strong>{generated_at}</div>
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
    if len(sys.argv) != 2:
        print("Usage: python3 build_v4_report.py <outputs_dir>", file=sys.stderr)
        sys.exit(1)
    build_report(sys.argv[1])
