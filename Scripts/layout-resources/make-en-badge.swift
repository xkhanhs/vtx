// make-en-badge.swift — the DH-Việt layout's "EN" badge, drawn by the SAME code as
// VTX Telex's "VX" (Scripts/make_icon.swift, letters swapped) and rasterized to a
// 20x16 pt TIFF (1x + 2x, alpha only — a template image).
//
// Why a TIFF and not an .icns: an .icns is square, and the input menu sizes an
// icon by ROW HEIGHT keeping its aspect, so a square badge renders narrower and
// shorter than the 20x16 "VX" beside it. The layout bundle must still NAME the
// file "<layout>.icns" (Scripts/make-dh-viet-layout.py copies it that way); macOS
// reads it by content and honours the 20x16 size. Verified in the menu 2026-09-29.
//
//   swift Scripts/make_icon.swift "$TMPDIR" EN EN.pdf
//   swift Scripts/layout-resources/make-en-badge.swift "$TMPDIR/EN.pdf" Scripts/layout-resources/DH-Viet.tiff

import AppKit

let args = CommandLine.arguments
guard args.count == 3, let pdf = NSImage(contentsOfFile: args[1]) else {
    fputs("usage: make-en-badge.swift <EN.pdf> <out.tiff>\n", stderr); exit(1)
}
let reps: [NSBitmapImageRep] = [1, 2].map { scale in
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 20 * scale, pixelsHigh: 16 * scale,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: 20, height: 16)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    pdf.draw(in: NSRect(x: 0, y: 0, width: 20, height: 16))
    NSGraphicsContext.restoreGraphicsState()
    return rep
}
guard let tiff = NSBitmapImageRep.tiffRepresentationOfImageReps(in: reps, using: .lzw, factor: 0) else {
    fputs("TIFF encoding failed\n", stderr); exit(1)
}
try tiff.write(to: URL(fileURLWithPath: args[2]))
