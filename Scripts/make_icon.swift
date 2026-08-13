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

// SQUARE media box. macOS stretches the input-source menu icon to a SQUARE
// (independent-axis scale), so a wide media box gets squished to square. We make
// the canvas square — the stretch is then a 1:1 no-op — and letterbox the
// golden-ratio box inside it (transparent margins top/bottom). The box keeps its
// true φ proportions and is never distorted. Trade-off dictated by the OS: a wide
// box can only be ~1/φ of the square's height, so it sits shorter than a
// full-height square badge (that shorter-but-undistorted is the point).
let S: CGFloat = 16                                   // square canvas (menu-icon standard)
var mediaBox = CGRect(x: 0, y: 0, width: S, height: S)
guard let ctx = CGContext(outURL as CFURL, mediaBox: &mediaBox, nil) else {
    fputs("cannot create PDF context\n", stderr); exit(1)
}
ctx.beginPDFPage(nil)

// Square box, near-full-bleed (border flush to the square canvas edges).
let borderWidth: CGFloat = 1.0
let box = CGRect(x: borderWidth / 2, y: borderWidth / 2,
                 width: S - borderWidth, height: S - borderWidth)
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
let byWidth = box.width * 0.74 / pairWidthPerPt                    // pair spans 74% of the box
let byHeight = box.height * 0.56 / capPerPt                        // …unless that would out-grow the box vertically
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

// Stroked border (crisp vector outline, transparent inside)…
ctx.setStrokeColor(CGColor.black)
ctx.setLineWidth(borderWidth)
ctx.addPath(CGPath(roundedRect: box, cornerWidth: radius, cornerHeight: radius, transform: nil))
ctx.strokePath()

// …and solid VX glyphs inside.
let glyphs = CGMutablePath()
glyphs.addPath(v.path)
glyphs.addPath(x.path)
ctx.setFillColor(CGColor.black)
ctx.addPath(glyphs)
ctx.fillPath()

// No extra stroke on either letter: that existed to stop the tiny subscript "t"
// from disappearing next to a full-size V. Equal-size letters at the same weight
// need no compensation, and stroking them here would just blur the pair at 16pt.

ctx.endPDFPage()
ctx.closePDF()
print("MenuIcon.pdf written (16x16 pt vector)")
