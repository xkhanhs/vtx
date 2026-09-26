#!/usr/bin/env python3
"""Predict a variant layout's pair times from the current layout's typing book.

The same hand motion costs the same time whatever letter is printed on the
key. So for each Telex pair that a variant moves, look up how long the typist
already takes for that motion on the current layout: a hand-alternating pair
is proxied by every alternating pair landing on the same target key (which
finger the other hand left from hardly matters); a same-hand pair needs a
timed pair on exactly those two keys. Pairs with no proxy are listed as
uncovered rather than guessed.

    pbpaste | ./Scripts/proxy-transition-book.py --to dh-viet-8
    ./Scripts/proxy-transition-book.py export.json --from dh-viet --to dh-viet-8

Read docs/LAYOUT-TYPING-DATA.md, "Giả lập bản 8 phím bằng sổ DH-Việt", before
trusting a number: proxies that only ever open a word (`he`, `te`, `be` on
DH-Việt) run slow for reasons that have nothing to do with the layout.
"""

import argparse
import json
import sys
from pathlib import Path

import importlib.util

_spec = importlib.util.spec_from_file_location(
    "analyze_transition_book", Path(__file__).with_name("analyze-transition-book.py"))
_atb = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_atb)
ROWS = _atb.ROWS

KEYBEAR_TABLE = Path(__file__).resolve().parents[2] / "keybear/docs/word-lists/vi-telex-ngrams.corpus.tsv"
QWERTY = "QWERTYUIOPASDFGHJKL;ZXCVBNM,./"
MIN_TIMED = 6  # a proxy needs this many timed hits, like analyze's ranking


def cells(layout):
    return {ch: (r, c) for r, row in enumerate(ROWS[layout]) for c, ch in enumerate(row) if ch != "."}


def left(cell):
    return cell[1] < 5


def load_bigram_shares(path):
    shares = {}
    for line in Path(path).read_text().splitlines():
        n, gram, _, weight = line.split("\t")
        if n == "2":
            shares[gram] = float(weight)
    total = sum(shares.values())
    return {g: w / total for g, w in shares.items()}


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("file", nargs="?", help="JSON export of the CURRENT layout's book; stdin if omitted")
    parser.add_argument("--from", dest="src", default="dh-viet", choices=sorted(ROWS))
    parser.add_argument("--to", dest="dst", required=True, choices=sorted(ROWS))
    parser.add_argument("--top", type=int, default=25)
    args = parser.parse_args()

    book = json.load(open(args.file) if args.file else sys.stdin)
    if book.get("variant") not in (None, args.src):
        sys.exit(f"book is for {book['variant']}, not {args.src}")
    grams = book["bigrams"]
    old, new = cells(args.src), cells(args.dst)
    moved = {ch for ch in old if old[ch] != new.get(ch)}

    # Measured motions on the current layout: by exact key pair, and, for
    # alternating pairs, pooled by target key.
    exact, onto = {}, {}
    for g, (_seen, ms, timed, _missed) in grams.items():
        if timed < 1 or g[0] == g[1]:
            continue
        a, b = old[g[0]], old[g[1]]
        e = exact.setdefault((a, b), [0.0, 0.0, []])
        e[0] += ms; e[1] += timed; e[2].append(g)
        if left(a) != left(b):
            t = onto.setdefault(b, [0.0, 0.0, []])
            t[0] += ms; t[1] += timed; t[2].append(g)

    shares = load_bigram_shares(KEYBEAR_TABLE)
    rows, uncovered = [], []
    for g, w in shares.items():
        if g[0] == g[1] or not (set(g) & moved) or g not in grams or grams[g][2] < 3:
            continue
        now = grams[g][1] / grams[g][2]
        a, b = new[g[0]], new[g[1]]
        if left(a) != left(b) and b in onto and onto[b][1] >= MIN_TIMED:
            src, how = onto[b], f"đổi tay → phím {QWERTY[b[0] * 10 + b[1]]}"
        elif left(a) == left(b) and (a, b) in exact and exact[(a, b)][1] >= MIN_TIMED:
            src, how = exact[(a, b)], "đúng hai phím"
        else:
            uncovered.append((w, g))
            continue
        rows.append((w, g, now, src[0] / src[1], src[1], how, ",".join(src[2][:3]), left(a) != left(b)))

    covered = sum(r[0] for r in rows)
    uncov = sum(w for w, _ in uncovered)
    print(f"{args.src} → {args.dst}: dời {''.join(sorted(moved))}; phủ {covered / (covered + uncov) * 100:.0f}% "
          f"trọng số cặp đổi ({len(rows)} cặp), {len(uncovered)} cặp không có proxy")
    print(f"\n{'cặp':4} {'‰':>5} {'nay':>5} {'dự':>5} {'n':>4}  proxy")
    for w, g, now, pred, n, how, ex, _ in sorted(rows, reverse=True)[:args.top]:
        print(f"{g:4} {w * 1000:5.1f} {now:5.0f} {pred:5.0f} {n:4.0f}  {how} ({ex})")

    groups = {}
    for w, g, now, pred, _n, _how, _ex, alt in rows:
        k = "đổi tay" if alt else "cùng tay"
        acc = groups.setdefault(k, [0.0, 0.0, 0.0])
        acc[0] += w; acc[1] += now * w; acc[2] += pred * w
    saved = sum((now - pred) * w for w, _g, now, pred, *_ in rows)
    print(f"\ntiết kiệm dự đoán trên phần phủ: {saved * 1000:+.0f} ms mỗi 1000 phím")
    for k, (w, a, b) in groups.items():
        print(f"  {k:10} {w * 1000:4.0f}‰  nay {a / w:4.0f} → dự {b / w:4.0f} ms")
    print("\nkhông có proxy (nặng nhất):", " ".join(g for _, g in sorted(uncovered, reverse=True)[:15]))


if __name__ == "__main__":
    main()
