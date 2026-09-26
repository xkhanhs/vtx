#!/usr/bin/env python3
"""Heatmap of Telex keystrokes per key, finger, row and hand, for each layout.

Counts what the hands press, not the letters on screen: "được" is `dduowcj`.
The counts come from keybear, whose scripts/vi-telex-ngrams.mjs turns a word
list into Telex keys (ư → uw, ươ → uow, â → aa, đ → dd, tone key last) and
writes two tables:

    corpus  OpenSubtitles 50k, real counts
    zipf    the practice app's word list, weighted 1/rank

Prints a load table per layout and, with --html, writes a page with one
heatmap per layout.

    ./Scripts/telex-heatmap.py
    ./Scripts/telex-heatmap.py --source zipf --html heatmap.html

The board model is one finger per column on an ANSI stagger; keep LAYOUTS in step with keybear's
packages/page-practice/lib/practice/keyboard-layouts.ts.
"""

import argparse
import json
import sys
from pathlib import Path

# Letter rows, `.` for a key that carries no Vietnamese letter; index = column.
LAYOUTS = {
    "dh-viet": ["qwfgb.luyx", "ahstpmneoi", "jvrczkd..."],
    "dh-viet-vb": ["qwfgb.luyx", "ahstpmneoi", "jzrcvkd..."],
    "dh-viet-vt": ["qwfgv.luyx", "ahstpmneoi", "jbrczkd..."],
    "dh-viet-8": ["qwfgp.luyx", "thsajmniob", "cvrezkd..."],
    # References: the layout DH-Việt was derived from, and the one before it.
    "colemak-dh": ["qwfpbjluy.", "arstgmneio", "xcdvzkh..."],
    "qwerty": ["qwertyuiop", "asdfghjkl.", "zxcvbnm..."],
}
ROW_OFFSETS = [0, 0.25, 0.75]
COLUMN_FINGERS = [0, 1, 2, 3, 3, 4, 4, 5, 6, 7]
FINGER_NAMES = ["út T", "áp út T", "giữa T", "trỏ T", "trỏ P", "giữa P", "áp út P", "út P"]
ROW_NAMES = ["trên", "nhà", "dưới"]

KEYBEAR_TABLES = Path(__file__).resolve().parents[2] / "keybear/docs/word-lists"


def load_unigrams(path):
    """{key: share of all keystrokes} from a vi-telex-ngrams table."""
    counts = {}
    for line in Path(path).read_text().splitlines():
        n, gram, _, weight = line.split("\t")
        if n == "1":
            counts[gram] = float(weight)
    total = sum(counts.values())
    return {k: w / total for k, w in counts.items()}


def load(rows, share):
    keys = []
    fingers = [0.0] * 8
    by_row = [0.0] * 3
    for r, row in enumerate(rows):
        for col, ch in enumerate(row):
            if ch == ".":
                continue
            s = share.get(ch, 0.0)
            keys.append({"key": ch, "row": r, "col": col, "share": s})
            fingers[COLUMN_FINGERS[col]] += s
            by_row[r] += s
    placed = {k["key"] for k in keys}
    missing = sorted(set(share) - placed)
    if missing:
        sys.exit(f"layout has no key for {missing}")
    return {
        "keys": keys,
        "fingers": fingers,
        "rows": by_row,
        "left": sum(fingers[:4]),
        "pinky": fingers[0] + fingers[7],
        "center": sum(k["share"] for k in keys if k["col"] in (4, 5)),
    }


def pct(x):
    return f"{x * 100:5.1f}"


def print_table(results):
    print(f"{'bố cục':<12} {'nhà':>5} {'trên':>5} {'dưới':>5} {'tay T':>5} "
          f"{'út':>5} {'cột giữa':>8}  tải từng ngón (út T … út P)")
    for name, m in results.items():
        fingers = " ".join(pct(f) for f in m["fingers"])
        print(f"{name:<12} {pct(m['rows'][1])} {pct(m['rows'][0])} {pct(m['rows'][2])} "
              f"{pct(m['left'])} {pct(m['pinky'])} {pct(m['center']):>8}  {fingers}")
    print("\n% trên tổng số phím Telex bấm; cột giữa = hai cột T/G/B và Y/H/N của QWERTY.")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--source", choices=["corpus", "zipf"], default="corpus")
    parser.add_argument("--table", help="vi-telex-ngrams TSV; overrides --source")
    parser.add_argument("--html", help="write a heatmap page for both sources here")
    args = parser.parse_args()

    table = args.table or KEYBEAR_TABLES / f"vi-telex-ngrams.{args.source}.tsv"
    share = load_unigrams(table)
    print_table({name: load(rows, share) for name, rows in LAYOUTS.items()})

    if args.html:
        sources = {"corpus": KEYBEAR_TABLES / "vi-telex-ngrams.corpus.tsv",
                   "zipf": KEYBEAR_TABLES / "vi-telex-ngrams.zipf.tsv"}
        if args.table:
            sources = {Path(args.table).stem: Path(args.table)}
        data = {
            "offsets": ROW_OFFSETS,
            "fingerNames": FINGER_NAMES,
            "rowNames": ROW_NAMES,
            "sources": {
                src: {name: load(rows, load_unigrams(path)) for name, rows in LAYOUTS.items()}
                for src, path in sources.items()
            },
        }
        template = Path(__file__).with_name("telex-heatmap.html").read_text()
        Path(args.html).write_text(template.replace("/*DATA*/null", json.dumps(data)))
        print(f"\nwrote {args.html}")


if __name__ == "__main__":
    main()
