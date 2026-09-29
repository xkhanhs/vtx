// make-en-badge.swift — vẽ icon "EN" cho layout DH-Việt, cùng kiểu huy hiệu VX của
// VTX Telex: ô đen bo góc, chữ khoét rỗng. Ảnh là template (chỉ kênh alpha có
// nghĩa), nên macOS tự tô theo thanh menu sáng/tối.
//
//   swift Scripts/layout-resources/make-en-badge.swift Scripts/layout-resources/DH-Viet.icns

import AppKit

let out = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = FileManager.default.temporaryDirectory.appendingPathComponent("DH-Viet.iconset")
try? FileManager.default.removeItem(at: iconset)
try! FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

func badge(_ px: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                               bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    let s = CGFloat(px)
    // Cùng tỉ lệ ô của MenuIcon.pdf: rộng hơn cao, góc bo lớn.
    let rect = NSRect(x: 0, y: s * 0.14, width: s, height: s * 0.72)
    NSColor.black.setFill()
    NSBezierPath(roundedRect: rect, xRadius: s * 0.2, yRadius: s * 0.2).fill()
    ctx.compositingOperation = .destinationOut
    let font = NSFont.systemFont(ofSize: s * 0.5, weight: .heavy)
    let text = NSAttributedString(string: "EN", attributes: [.font: font, .foregroundColor: NSColor.black])
    let size = text.size()
    text.draw(at: NSPoint(x: (s - size.width) / 2, y: rect.midY - size.height / 2))
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for (name, px) in [("16x16", 16), ("16x16@2x", 32), ("32x32", 32), ("32x32@2x", 64),
                   ("128x128", 128), ("128x128@2x", 256)] {
    try! badge(px).write(to: iconset.appendingPathComponent("icon_\(name).png"))
}
let p = Process()
p.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
p.arguments = ["-c", "icns", iconset.path, "-o", out.path]
try! p.run(); p.waitUntilExit()
exit(p.terminationStatus)
