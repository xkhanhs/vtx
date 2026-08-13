// make_icon.swift — generate the menu-bar badge as a VECTOR PDF (MenuIcon.pdf),
// the format the system actually expects for input-method icons: Squirrel/RIME
// ships a single PDF (media box 22×16 pt) referenced by all three icon keys,
// and it renders crisp at every DPI and correctly in dark mode. Bitmap TIFFs
// with mismatched point sizes were the cause of the blurry/small/misaligned
// renders we went through.
//
// Design: SQUARE OUTLINE box (stroked border, transparent inside) filling a
// square canvas — matches the height of the system "US" badge, and since the
// menu icon slot is square, a square canvas maps 1:1 (no distortion). Solid "VX"
// inside (T = V/φ, shared baseline), auto-sized to fill both axes. Single black
// vector; the system handles dark-mode tinting.
//
// Why square (not golden-ratio): the input-source slot stretches the icon to a
// square with independent-axis scaling, so a wide box would be squished. Square
// canvas + square box = full height like "US", undistorted. (Chosen over a
// letterboxed golden box, which stays undistorted but renders shorter than "US".)
//
// Usage: swift make_icon.swift <resourcesDir>     → writes MenuIcon.pdf
// (The APP icon comes from assets/VietTelex-logo.png via Scripts/make_appicon.py.)

import AppKit
import CoreText

let phi: CGFloat = (1 + 5.0.squareRoot()) / 2

/// Outline path of one character at `size`, translated so its glyph bounding
/// box starts at `origin` (x) and sits on baseline `origin.y`.
func glyphPath(_ ch: Character, weight: NSFont.Weight, size: CGFloat,
               baselineY: CGFloat, leftX: CGFloat) -> (path: CGPath, width: CGFloat)? {
    let font = NSFont.systemFont(ofSize: size, weight: weight) as CTFont
    var chars = [UniChar](String(ch).utf16)
    var glyph = CGGlyph()
    guard CTFontGetGlyphsForCharacters(font, &chars, &glyph, 1) else { return nil }
    var bbox = CGRect.zero
    withUnsafeMutablePointer(to: &glyph) { g in
        bbox = CTFontGetBoundingRectsForGlyphs(font, .default, g, nil, 1)
    }
    var transform = CGAffineTransform(translationX: leftX - bbox.minX, y: baselineY)
    guard let path = CTFontCreatePathForGlyph(font, glyph, &transform) else { return nil }
    return (path, bbox.width)
}

let args = CommandLine.arguments
guard args.count >= 2 else { fputs("usage: make_icon.swift <resourcesDir>\n", stderr); exit(1) }
let outURL = URL(fileURLWithPath: args[1]).appendingPathComponent("MenuIcon.pdf")

// WIDE media box, 1.25:1 — NOT square.
//
// Upstream's note here said macOS stretches an input-source menu icon to a square
// (independent-axis scale), so a wide media box would be squished, and the canvas
// was made square to dodge that. Measured on macOS 26 and it does not happen: a
// 20x16 canvas renders undistorted.
//
// A square canvas is what made this badge read as "small" beside the system's.
// Measured off a screenshot of the open input menu, in device pixels:
//
//     A  (ABC)      badge 42x32   ink 16x17
//     CO (Colemak)  badge 40x32   ink 31x16
//     VX (ours, square canvas)    badge 30x32   ink 22x12
//
// macOS sizes the badge by ROW HEIGHT and keeps the canvas aspect, so a square
// canvas can only ever be 32 wide where the system's own are 40-42 — 25% narrower,
// with proportionally shorter letters. And a square badge cannot hold two letters
// at the system's cap height without running them edge to edge, which reads as
// cramped. The width has to come from the canvas; there is no margin trick that
// substitutes for it.
let SW: CGFloat = 20, SH: CGFloat = 16
let S: CGFloat = SH                                   // vertical reference for glyph sizing
var mediaBox = CGRect(x: 0, y: 0, width: SW, height: SH)
guard let ctx = CGContext(outURL as CFURL, mediaBox: &mediaBox, nil) else {
    fputs("cannot create PDF context\n", stderr); exit(1)
}
ctx.beginPDFPage(nil)

// FULL BLEED. The badge used to be inset by half a border width, left over from
// when it was a stroked outline and the stroke had to sit inside the canvas. A
// solid badge has no stroke to fit, and next to the system's own A / CO badges
// even that ~6% made ours read as the small one.
let box = CGRect(x: 0, y: 0, width: SW, height: SH)
let radius = box.height * 0.28                        // like the system "A" badge

// "V" and "X" are EQUAL partners, the way macOS draws its own two-letter badges
// ("CO" for Colemak, "AB" for ABC) — a full-size letter with a tiny subscript is
// upstream's "Vt" lockup, where the t was a diminutive of "telex". "VX" is an
// abbreviation, so both letters carry the same weight.
//
// Sized by WIDTH, not cap height: two full letters are ~2.4× wider than one, so
// the height rule that fit a single "V" would overflow the square. Measure the
// pair at a probe size, then scale so it fills a fixed share of the box width —
// and clamp on cap height too, in case a future glyph pair is unusually narrow.
let probeSize: CGFloat = 20
let weight: NSFont.Weight = .bold
guard let vProbe = glyphPath("V", weight: weight, size: probeSize, baselineY: 0, leftX: 0),
      let xProbe = glyphPath("X", weight: weight, size: probeSize, baselineY: 0, leftX: 0)
else { fputs("glyph path failed\n", stderr); exit(1) }

let gapRatio: CGFloat = -0.06                                      // slight negative tracking: V's open top tucks under X
let pairWidthPerPt = (vProbe.width + xProbe.width + probeSize * gapRatio) / probeSize
let capPerPt = vProbe.path.boundingBox.height / probeSize          // cap height per point
// Padding is deliberate, not leftover space. The system's own badges keep a wide
// margin around their letters, so letters run edge-to-edge here read as cramped
// next to "A" and "CO" — tried at 0.94 and rejected on sight. The badge is already
// full-bleed (see box above); this is the breathing room INSIDE it.
// Matched to the measured "CO": ink spans 78% of the badge width and 50% of its
// height. The extra room comes from the wider canvas, not from thinner margins.
let byWidth = box.width * 0.78 / pairWidthPerPt
let byHeight = box.height * 0.50 / capPerPt
let size = min(byWidth, byHeight)
let gap = size * gapRatio

// Final glyph widths, to center the VX pair horizontally.
guard let vW = glyphPath("V", weight: weight, size: size, baselineY: 0, leftX: 0),
      let xW = glyphPath("X", weight: weight, size: size, baselineY: 0, leftX: 0)
else { fputs("glyph path failed\n", stderr); exit(1) }
let totalW = vW.width + gap + xW.width
let capV = vW.path.boundingBox.height
let baselineY = box.minY + (box.height - capV) / 2
let leftX = box.minX + (box.width - totalW) / 2

guard let v = glyphPath("V", weight: weight, size: size, baselineY: baselineY, leftX: leftX),
      let x = glyphPath("X", weight: weight, size: size, baselineY: baselineY,
                        leftX: leftX + v.width + gap)
else { fputs("glyph path failed\n", stderr); exit(1) }

// Solid badge with the letters KNOCKED OUT, matching how macOS draws its own
// keyboard badges ("A" for ABC, "CO" for Colemak) — upstream's outlined box read
// as a foreign object sitting between them in the input menu.
//
// One path (rounded rect + both glyphs) filled with the EVEN-ODD rule, so the
// glyph interiors stay transparent instead of being painted over. This is a
// TEMPLATE image: black = painted in the menu's tint colour, transparent = not
// painted, so the menu background shows through the letters and the badge
// inverts correctly in light and dark mode alike.
//
// No separate stroke on the letters: that existed to keep the old tiny subscript
// "t" from vanishing beside a full-size V. Equal-size letters at one weight need
// no compensation, and a stroke here would thicken the knockout and close up the
// counters at 16pt.
let badge = CGMutablePath()
badge.addPath(CGPath(roundedRect: box, cornerWidth: radius, cornerHeight: radius, transform: nil))
badge.addPath(v.path)
badge.addPath(x.path)
ctx.setFillColor(CGColor.black)
ctx.addPath(badge)
ctx.fillPath(using: .evenOdd)

ctx.endPDFPage()
ctx.closePDF()
print("MenuIcon.pdf written (16x16 pt vector)")
