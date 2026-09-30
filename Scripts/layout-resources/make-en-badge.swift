// make-en-badge.swift — the DH-Việt layout's "EN" badge, drawn by the SAME code as
// VTX Telex's "VX" (Scripts/make_icon.swift, letters swapped), written as an iconset
// (alpha only — a template image) for `iconutil` to pack into a REAL .icns.
//
// The 20x16 badge fills the square's width, centred vertically. A keyboard layout's
// icon reaches the menu through IconServices, which decodes by format: the 20x16
// TIFF saved under the .icns name (2026-09-29) drew for a day, then came back fully
// transparent (measured 2026-09-30: IconRef with 0 opaque pixels, blank in the
// menu). A square icon draws a little smaller than VX, but it draws.
//
//   swift Scripts/make_icon.swift "$TMPDIR" EN EN.pdf
//   swift Scripts/layout-resources/make-en-badge.swift "$TMPDIR/EN.pdf" "$TMPDIR/EN.iconset"
//   iconutil -c icns "$TMPDIR/EN.iconset" -o Scripts/layout-resources/DH-Viet.icns

import AppKit

let args = CommandLine.arguments
guard args.count == 3, let pdf = NSImage(contentsOfFile: args[1]) else {
    fputs("usage: make-en-badge.swift <EN.pdf> <out.iconset>\n", stderr); exit(1)
}
try FileManager.default.createDirectory(atPath: args[2], withIntermediateDirectories: true)
for pt in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let px = pt * scale
        let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                                   bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                                   isPlanar: false, colorSpaceName: .deviceRGB,
                                   bytesPerRow: 0, bitsPerPixel: 0)!
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        let side = CGFloat(px), height = side * 16 / 20
        pdf.draw(in: NSRect(x: 0, y: (side - height) / 2, width: side, height: height))
        NSGraphicsContext.restoreGraphicsState()
        let name = scale == 1 ? "icon_\(pt)x\(pt).png" : "icon_\(pt)x\(pt)@2x.png"
        guard let png = rep.representation(using: .png, properties: [:]) else {
            fputs("PNG encoding failed\n", stderr); exit(1)
        }
        try png.write(to: URL(fileURLWithPath: "\(args[2])/\(name)"))
    }
}
