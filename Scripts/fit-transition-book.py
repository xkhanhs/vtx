#!/usr/bin/env python3
"""Fit the typing book to layout features, to see what the layout costs by hand.

Companion to analyze-transition-book.py, which ranks pairs one by one. This
answers the other question: taken together, what does each kind of move cost
this typist, once the things a layout cannot change (tone keys, `e`, the `w`
mark) are held apart. Weighted ridge regression over pairs timed ≥ 3 times.
Read docs/LAYOUT-TYPING-DATA.md, "Mốc 40 bài: thiết kế lại?", before trusting
a coefficient: 40 rounds gave R² ≈ 0.7 on ~130 pairs, enough for group means,
not enough to drive a 20-key redesign.

    pbpaste | ./Scripts/fit-transition-book.py
    ./Scripts/fit-transition-book.py export.json

Needs numpy. `start` = share of a pair's corpus hits that open a word (from
keybear's word list); pass --start-frac to supply it, else 0.5 everywhere.
"""

import argparse
import json
import math
import sys

import numpy as np

import importlib.util
from pathlib import Path

_spec = importlib.util.spec_from_file_location(
    "analyze_transition_book", Path(__file__).with_name("analyze-transition-book.py"))
_mod = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_mod)
places = _mod.places

VOWELS = "aeiouy"
NAMES = [
    "const", "start", "sameHand", "sfb", "sfbDist", "rollOut", "rowJump",
    "scissor", "toPinky", "toRing", "fromPinky", "centerCol",
    "R_cons→vowel", "R_vowel→vowel", "R_other", "toOffHome",
    "toTone", "toE", "fromW", "toW",
]


def feats(g, pl, start):
    a, b = pl[g[0]], pl[g[1]]
    ha, hb = a[2] < 4, b[2] < 4
    same = ha == hb
    sfb = same and a[2] == b[2]
    d = math.hypot(a[1] - b[1], a[0] - b[0])
    inward = (b[2] > a[2]) if ha else (b[2] < a[2])
    lower, upper = (a, b) if a[0] > b[0] else (b, a)
    scissor = (same and not sfb and abs(a[2] - b[2]) == 1 and a[0] != b[0]
               and lower[2] in (1, 2, 5, 6) and upper[2] not in (1, 2, 5, 6))
    right = same and not ha
    cv = right and g[0] not in VOWELS and g[1] in VOWELS
    vv = right and g[0] in VOWELS and g[1] in VOWELS
    col_a, col_b = round(a[1] - [0, 0.25, 0.75][a[0]]), round(b[1] - [0, 0.25, 0.75][b[0]])
    return [
        1, start.get(g, 0.5), same, sfb, d if sfb else 0, same and not sfb and not inward,
        abs(a[0] - b[0]) if same else 0, scissor, b[2] in (0, 7), b[2] in (1, 6),
        a[2] in (0, 7), col_a in (4, 5) or col_b in (4, 5),
        cv, vv, right and not cv and not vv, b[0] != 1,
        g[1] in "sfrxj" and g[0] in "aeiouyctpmngh", g[1] == "e", g[0] == "w", g[1] == "w",
    ]


def group_table(book, pl):
    def grp(pred):
        ms = t = n = 0
        for g, v in book.items():
            if g[0] == g[1] or g[0] not in pl or g[1] not in pl or not v[2]:
                continue
            if pred(g, pl[g[0]], pl[g[1]]):
                ms, t, n = ms + v[1], t + v[2], n + v[0]
        return f"{ms / t:4.0f} ms  n={n:4.0f}" if t else "   —"

    def right(a, b): return a[2] >= 4 and b[2] >= 4
    def left(a, b): return a[2] < 4 and b[2] < 4
    def alt(a, b): return (a[2] < 4) != (b[2] < 4)
    rows = [
        ("tay phải, phụ âm → nguyên âm", lambda g, a, b: right(a, b) and g[0] not in VOWELS and g[1] in VOWELS),
        ("tay phải, nguyên âm → nguyên âm", lambda g, a, b: right(a, b) and g[0] in VOWELS and g[1] in VOWELS),
        ("tay phải, còn lại (→ n m d k)", lambda g, a, b: right(a, b) and g[1] not in VOWELS),
        ("tay trái, phụ âm → phụ âm", lambda g, a, b: left(a, b) and g[1] not in VOWELS + "w"),
        ("tay trái, phụ âm → a", lambda g, a, b: left(a, b) and g[1] == "a"),
        ("đổi tay, phụ âm → nguyên âm", lambda g, a, b: alt(a, b) and g[0] not in VOWELS and g[1] in VOWELS),
        ("đổi tay, nguyên âm → nguyên âm", lambda g, a, b: alt(a, b) and g[0] in VOWELS and g[1] in VOWELS),
    ]
    print("== nhóm cú chuyển (ms trung bình) ==")
    for name, pred in rows:
        print(f"  {name:34} {grp(pred)}")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("file", nargs="?")
    parser.add_argument("--start-frac", help="JSON {pair: share of word-initial hits}")
    parser.add_argument("--min-timed", type=float, default=3)
    args = parser.parse_args()
    page = json.load(open(args.file) if args.file else sys.stdin)
    start = json.load(open(args.start_frac)) if args.start_frac else {}
    pl = places(page.get("variant", "dh-viet"))
    book = page["bigrams"]

    group_table(book, pl)

    X, y, w, gs = [], [], [], []
    for g, (seen, ms, t, miss) in book.items():
        if g[0] == g[1] or t < args.min_timed or g[0] not in pl or g[1] not in pl:
            continue
        X.append([float(v) for v in feats(g, pl, start)])
        y.append(ms / t)
        w.append(t)
        gs.append(g)
    X, y, W = np.array(X), np.array(y), np.array(w)
    lam = np.eye(X.shape[1]) * 5
    lam[0, 0] = 0
    XW = X * W[:, None]
    beta = np.linalg.solve(XW.T @ X + lam, XW.T @ y)
    pred = X @ beta
    r2 = 1 - np.sum(W * (y - pred) ** 2) / np.sum(W * (y - np.average(y, weights=W)) ** 2)
    print(f"\n== hồi quy: ms thêm cho mỗi đặc điểm (n={len(gs)} cặp, R²={r2:.2f}) ==")
    for name, b in zip(NAMES, beta):
        print(f"  {name:16} {b:7.1f}")
    resid = sorted(zip(gs, y, pred, W), key=lambda r: -(r[1] - r[2]) * math.sqrt(r[3]))
    print("\nchậm hơn mô hình đoán:", ", ".join(f"{g} {a:.0f}/{p:.0f}" for g, a, p, _ in resid[:8]))
    print("nhanh hơn mô hình đoán:", ", ".join(f"{g} {a:.0f}/{p:.0f}" for g, a, p, _ in resid[-6:]))


if __name__ == "__main__":
    main()
