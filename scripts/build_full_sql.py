#!/usr/bin/env python3
"""
Rebuild characterization_full.sql from the canonical chunk files.

Usage:
    python scripts/build_full_sql.py

The chunks directory is the source of truth:
  sql/sql_server/chunks/00_setup.sql   — all temp-table setup (sections A–J)
  sql/sql_server/chunks/NN_*.sql       — final SELECT exports (one per output)

The monolithic characterization_full.sql is a concatenation of all chunks in
numeric order.  It is checked in for users who want a single-file run but is
never edited directly — edit the chunks instead.

After running this script, regenerate other dialect translations with:
    Rscript scripts/translate_sql_dialects.R
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[1]
CHUNKS_DIR = BASE_DIR / "sql" / "sql_server" / "chunks"
OUT_FILE = BASE_DIR / "sql" / "sql_server" / "characterization_full.sql"


def _chunk_sort_key(path: Path) -> int:
    m = re.match(r"^(\d+)", path.stem)
    return int(m.group(1)) if m else 999


def main() -> None:
    chunks = sorted(
        [p for p in CHUNKS_DIR.glob("*.sql") if p.is_file()],
        key=_chunk_sort_key,
    )
    if not chunks:
        sys.exit(f"No .sql files found in {CHUNKS_DIR}")

    print(f"Building {OUT_FILE.relative_to(BASE_DIR)} from {len(chunks)} chunk(s):")
    parts: list[str] = []
    for chunk in chunks:
        print(f"  {chunk.name}")
        parts.append(chunk.read_text(encoding="utf-8").rstrip("\n"))

    combined = "\n\n".join(parts) + "\n"
    OUT_FILE.write_text(combined, encoding="utf-8")
    print(f"\nWritten: {OUT_FILE} ({len(combined.splitlines())} lines)")
    print("Next: Rscript scripts/translate_sql_dialects.R")


if __name__ == "__main__":
    main()
