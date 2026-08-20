#!/usr/bin/env python3
"""Build the Colemak DH-Việt macOS keyboard layout bundle.

DH-Việt is Colemak-DH-angle retuned for the Telex keystream of Vietnamese: nine
letters move so that `kh` and `nh` — which between them open a quarter of all
Vietnamese words — stop landing on one finger. Measurement, corpus verification
and the rationale for each swap live in the keybear repo:

    docs/dh_viet_layout.md
    plans/reports/research-260820-2011-dh-viet-corpus-verification.md

WHY GENERATE INSTEAD OF HAND-WRITING A .keylayout: the source layout carries
eight modifier maps plus a dead-key action table (Option-accents). Retyping the
letters in one map and forgetting the other seven is how a layout ends up typing
`ñ` from the wrong key six months later. Here every map is permuted by the same
table, so a key's whole modifier column — plain, shift, option, caps — travels
with it and cannot drift apart.

The permutation is expressed as *destination keycode ← source keycode* over the
stock Colemak DH ANSI layout, which already includes the angle mod.

    ./Scripts/make-dh-viet-layout.py            # → ~/Library/Keyboard Layouts/
    ./Scripts/make-dh-viet-layout.py --out DIR  # somewhere else

A user-level bundle is registered immediately — no logout. Add it in System
Settings → Keyboard → Input Sources, then pin VTX to it in VTX Settings.
"""

import argparse
import plistlib
import re
import shutil
import sys
from pathlib import Path

SOURCE = Path("/Library/Keyboard Layouts/Colemak DH.bundle/Contents/Resources")
SOURCE_LAYOUT = SOURCE / "Colemak DH ANSI.keylayout"
SOURCE_ICON = SOURCE / "Colemak DH ANSI.icns"

NAME = "Colemak DH-Viet"
BUNDLE_ID = "com.vtx.keyboardlayout.colemakdhviet"

# macOS builds the input-source id from the <keyboard name=> with spaces stripped,
# NOT from the TISInputSourceID declared below — that key is only a hint and was
# measured being ignored (2026-08-20). So this string has to be derived the same
# way, or the id printed here is one nothing will resolve.
SOURCE_ID = f"{BUNDLE_ID}.keylayout.{NAME.replace(' ', '')}"

# Layout ids are a global namespace with no registry; a collision makes macOS
# serve the wrong layout. Picked from the private range and kept away from the
# stock layouts (-7379 is Colemak DH ANSI's).
LAYOUT_ID = "-25361"

# Only the ANSI map set is permuted. The other one (984) overrides JIS-only keys
# — ¥, the two kana keys — none of which carry a letter this layout moves.
ANSI_MAP_SET = "16c"

# destination keycode ← source keycode, over Colemak DH ANSI.
#
#   dst  gains  from  which held      why (see docs/dh_viet_layout.md)
#     1  h      46    right index h   kills `kh`/`nh`; h 69‰ earns a home key
#     8  r       1    left home r     r 30‰ steps down, Cmd+R stays one-handed
#    46  d       8    left bottom d   `dd`→đ is a repeat, so it costs nothing
#     7  v       9    right of it     c 42‰ to the index, v 11‰ to the ring
#     9  c       7
#     5  p      15    top row p       g 51‰ (from `ng` 44‰) leaves the stretch
#    15  g       5
#    37  o      41    right pinky o   o 131‰ is the heaviest Vietnamese letter
#    41  i      37
#     6  j      16    the old Y slot  frees `nj`/`mj`/`hj`
#    35  x       6    left bottom x   ngã is the rarest tone (5.5% of words)
#    16  ;      35    top row ;       see below
PERMUTATION = {
    1: 46, 8: 1, 46: 8,
    7: 9, 9: 7,
    5: 15, 15: 5,
    37: 41, 41: 37,
    6: 16, 35: 6, 16: 35,
}

# The one slot DH-Việt leaves empty is the old Y — right index, reaching up and
# in, the most expensive key on the board — and the optimiser preferred it bare
# over housing a letter there. `;` is what lands in it, because `;` is the only
# character the nine swaps orphan: its old key now types `i`, and the key that
# would have taken it now types `x`. Vietnamese barely uses `;`, code needs it,
# and this is the right price for a character that rare.


def permute(layout: str) -> str:
    """Apply PERMUTATION to every key map of the ANSI map set."""
    head, sep, rest = layout.partition(f'<keyMapSet id="{ANSI_MAP_SET}">')
    if not sep:
        sys.exit(f"{SOURCE_LAYOUT.name}: no key map set {ANSI_MAP_SET!r} — layout changed upstream?")
    body, sep2, tail = rest.partition("</keyMapSet>")

    def one_map(match: re.Match) -> str:
        block = match.group(0)
        # An attribute list, not just a character: `output="q"` and `action="14"`
        # (a dead key) both have to travel, or Option-accents follow the old key.
        attrs = dict(re.findall(r'<key code="(\d+)"([^/]*)/>', block))
        missing = [dst for dst, src in PERMUTATION.items() if str(src) not in attrs]
        if missing:
            sys.exit(f"key map is missing source keys for {missing} — cannot permute safely")

        def swap(key: re.Match) -> str:
            code = int(key.group(1))
            src = PERMUTATION.get(code)
            return key.group(0) if src is None else f'<key code="{code}"{attrs[str(src)]}/>'

        return re.sub(r'<key code="(\d+)"[^/]*/>', swap, block)

    body = re.sub(r"<keyMap index=\"\d+\">.*?</keyMap>", one_map, body, flags=re.S)
    return head + sep + body + sep2 + tail


def write_bundle(out: Path) -> Path:
    layout = SOURCE_LAYOUT.read_text(encoding="utf-8")
    layout = permute(layout)
    layout = re.sub(
        r'<keyboard group="(\d+)" id="-?\d+" name="[^"]*"',
        rf'<keyboard group="\1" id="{LAYOUT_ID}" name="{NAME}"',
        layout,
        count=1,
    )

    bundle = out / f"{NAME}.bundle"
    if bundle.exists():
        shutil.rmtree(bundle)
    resources = bundle / "Contents" / "Resources"
    resources.mkdir(parents=True)

    (resources / f"{NAME}.keylayout").write_text(layout, encoding="utf-8")
    if SOURCE_ICON.exists():
        shutil.copy2(SOURCE_ICON, resources / f"{NAME}.icns")

    info = {
        "CFBundleIdentifier": BUNDLE_ID,
        "CFBundleName": NAME,
        "CFBundleVersion": "1.0.0",
        "CFBundlePackageType": "BNDL",
        f"KLInfo_{NAME}": {
            "TISInputSourceID": SOURCE_ID,
            "TISIntendedLanguage": "en",
            "TICapsLockLanguageSwitchCapable": False,
        },
    }
    with (bundle / "Contents" / "Info.plist").open("wb") as handle:
        plistlib.dump(info, handle)
    return bundle


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=Path.home() / "Library" / "Keyboard Layouts")
    args = parser.parse_args()

    if not SOURCE_LAYOUT.exists():
        sys.exit(f"missing {SOURCE_LAYOUT} — install the Colemak DH layouts from colemakmods first")

    args.out.mkdir(parents=True, exist_ok=True)
    bundle = write_bundle(args.out)
    print(f"wrote {bundle}")
    print(f"input source id: {SOURCE_ID}")
    print("macOS registers it immediately; add it in System Settings → Keyboard → Input Sources")


if __name__ == "__main__":
    main()
