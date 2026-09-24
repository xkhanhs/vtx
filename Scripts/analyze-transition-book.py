#!/usr/bin/env python3
"""Score a beartype "sổ cú chuyển phím" export against the DH-Việt layout.

beartype (the practice site) logs how long each pair and triple of Telex keys
takes and how often it misses, per layout, and its "chép sổ" button copies that
page as JSON. This reads it and prints what docs/LAYOUT-TYPING-DATA.md explains:
how much the book is worth yet, the kinds of move, the slowest and most-missed
pairs with a rough confidence band, and what more rounds would buy.

    pbpaste | ./Scripts/analyze-transition-book.py
    ./Scripts/analyze-transition-book.py export.json
    ./Scripts/analyze-transition-book.py export.json --angle   # see --help

The board model is beartype's `transition-kinds.ts` (itself keybear's). Keep
ROWS in step with Scripts/make-dh-viet-layout.py and with beartype.
"""

import argparse
import json
import math
import sys

# Letter rows as beartype draws them, `.` for blanks; index = physical column.
ROWS = {
    "dh-viet": ["qwfgb.luyx", "ahstpmneoi", "jvrczkd..."],
    "dh-viet-vb": ["qwfgb.luyx", "ahstpmneoi", "jzrcvkd..."],
    "dh-viet-vt": ["qwfgv.luyx", "ahstpmneoi", "jbrczkd..."],
}
ROW_OFFSETS = [0, 0.25, 0.75]
# 0 left pinky .. 7 right pinky, by column, as beartype and keybear assume.
COLUMN_FINGERS = [0, 1, 2, 3, 3, 4, 4, 5, 6, 7]
# Angle-mod fingering of the bottom-left keys: Z by ring, X by middle, C and V
# by index. Beartype does NOT model this; --angle shows what changes if the
# hands really type that way (`tr` becomes a same-finger pair).
ANGLE_BOTTOM = [1, 2, 3, 3, 3]

DECAY = 0.98
MIN_TIMED = 6  # beartype ranks a move only once it is timed this often
# Spread of one move's time around its mean, for the confidence band. Assumed:
# the export keeps sums, not variances.
CV = 0.5


def places(layout, angle):
    out = {}
    for row, chars in enumerate(ROWS[layout]):
        for col, ch in enumerate(chars):
            if ch == ".":
                continue
            finger = COLUMN_FINGERS[col]
            if angle and row == 2 and col < len(ANGLE_BOTTOM):
                finger = ANGLE_BOTTOM[col]
            out[ch] = (row, col + ROW_OFFSETS[row], finger)
    return out


def bigram_kind(gram, pl):
    a, b = pl.get(gram[0]), pl.get(gram[1])
    if a is None or b is None:
        return None
    if gram[0] == gram[1]:
        return "repeat"
    left_a, left_b = a[2] < 4, b[2] < 4
    if left_a != left_b:
        return "alternate"
    if a[2] == b[2]:
        near = math.hypot(a[1] - b[1], a[0] - b[0]) < 1.3
        return "sfb-near" if near else "sfb-far"
    if abs(a[2] - b[2]) == 1 and a[0] != b[0]:
        lower, upper = (a, b) if a[0] > b[0] else (b, a)
        if lower[2] in (1, 2, 5, 6) and upper[2] not in (1, 2, 5, 6):
            return "scissor"
    inward = b[2] > a[2] if left_a else b[2] < a[2]
    return "roll-in" if inward else "roll-out"


def trigram_kind(gram, pl):
    a, b, c = (pl.get(ch) for ch in gram)
    if a is None or b is None or c is None:
        return None
    if gram[0] != gram[2] and a[2] == c[2] and b[2] != a[2]:
        return "sfs"
    ha, hb, hc = a[2] < 4, b[2] < 4, c[2] < 4
    if ha != hb and hb != hc:
        return "alternate"
    if ha == hb == hc and len({a[2], b[2], c[2]}) == 3:
        return "redirect" if (b[2] - a[2]) * (c[2] - b[2]) < 0 else "roll"
    return "split"


def effective(rounds):
    """How many rounds' worth the decayed book holds; tops out at 50."""
    return (1 - DECAY**rounds) / (1 - DECAY)


def band(timed):
    """Rough 95% half-width of a mean, as a fraction."""
    return 1.96 * CV / math.sqrt(timed) if timed > 0 else float("inf")


def report(grams, kind_of, title, baseline_gram, top):
    base_ms = sum(v[1] for g, v in grams.items() if baseline_gram(g))
    base_n = sum(v[2] for g, v in grams.items() if baseline_gram(g))
    if base_n == 0:
        print(f"\n{title}: chưa có số đo")
        return
    base = base_ms / base_n
    total = sum(v[0] for g, v in grams.items() if kind_of(g))
    kinds = {}
    for g, v in grams.items():
        k = kind_of(g)
        if k is None:
            continue
        acc = kinds.setdefault(k, [0, 0, 0, 0])
        for i in range(4):
            acc[i] += v[i]
    print(f"\n== {title} — nhịp thường {base:.0f} ms ==")
    print(f"{'loại':10} {'tỉ phần':>7} {'ms':>5} {'so thường':>9} {'sai':>6}")
    for k, (seen, ms, timed, missed) in sorted(
        kinds.items(), key=lambda kv: -(kv[1][1] / kv[1][2] if kv[1][2] else 0)
    ):
        if timed == 0:
            continue
        print(
            f"{k:10} {seen / total:7.1%} {ms / timed:5.0f} "
            f"{ms / timed / base:9.2f} {missed / seen:6.1%}"
        )
    ranked = [
        (g, kind_of(g), v)
        for g, v in grams.items()
        if kind_of(g) and v[2] >= MIN_TIMED
    ]
    ranked.sort(key=lambda r: -(r[2][1] / r[2][2]))
    print(f"\nchậm nhất ({len(ranked)}/{len(grams)} đã đủ {MIN_TIMED} lần đo):")
    for g, k, (seen, ms, timed, missed) in ranked[:top]:
        rel = ms / timed / base
        spread = band(timed)
        sure = "chắc" if rel * (1 - spread) > 1.1 else "chưa chắc"
        print(
            f"  {g:4} {k:10} n={seen:6.1f} {ms / timed:4.0f} ms  x{rel:.2f} "
            f"(±{spread:.0%}, {sure})"
        )
    missed = sorted(
        ((g, kind_of(g), v) for g, v in grams.items() if v[3] > 0),
        key=lambda r: -r[2][3],
    )
    print("\nhay gõ sai nhất (theo số lần):")
    for g, k, (seen, _, _, miss) in missed[:top]:
        print(f"  {g:4} {k or '?':10} sai {miss:4.1f}/{seen:5.1f} = {miss / seen:.0%}")


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("file", nargs="?", help="JSON export; stdin if omitted")
    parser.add_argument(
        "--angle",
        action="store_true",
        help="finger the bottom-left keys angle-mod style (C key by index)",
    )
    parser.add_argument("--top", type=int, default=12)
    args = parser.parse_args()
    page = json.load(open(args.file) if args.file else sys.stdin)
    layout = page.get("variant", "dh-viet")
    pl = places(layout, args.angle)
    rounds = page["rounds"]
    now = effective(rounds)
    moves = sum(v[0] for v in page["bigrams"].values())
    print(f"bố cục {layout}, {rounds} bài, sổ đang nặng bằng {now:.1f} bài")
    print(f"~{moves / now:.0f} cặp phím mỗi bài; sổ giữ tối đa ~50 bài")
    if args.angle:
        print("ngón: angle mod (phím Z áp út, X giữa, C và V trỏ)")

    report(
        page["bigrams"],
        lambda g: bigram_kind(g, pl),
        "cặp phím",
        lambda g: len(set(g)) > 1,
        args.top,
    )
    report(
        page["trigrams"],
        lambda g: trigram_kind(g, pl),
        "bộ ba phím",
        lambda g: True,
        args.top,
    )

    print("\n== gõ thêm thì được gì ==")
    print("số lần mỗi cặp nhân lên, và số cặp đủ để xếp hạng:")
    for more in (0, 15, 35, 85):
        n = rounds + more
        grow = effective(n) / now
        ranked = sum(1 for v in page["bigrams"].values() if v[2] * grow >= MIN_TIMED)
        print(f"  {n:4} bài: x{grow:.1f}, {ranked} cặp xếp hạng")
    print("dải tin cậy của một cặp theo số lần đo:")
    print("  " + ", ".join(f"n={n}: ±{band(n):.0%}" for n in (6, 10, 20, 50, 100)))


if __name__ == "__main__":
    main()
