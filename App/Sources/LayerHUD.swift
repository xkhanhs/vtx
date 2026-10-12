// LayerHUD.swift
//
// Bảng nhỏ ghim ở góc màn hình, vẽ các tầng của bàn phím Corne (NAV, FN…) để nhìn mà
// bấm trong lúc chưa thuộc. Thử nghiệm, mặc định TẮT (AppState.layerHUD).
//
// GHIM CỐ ĐỊNH, không bật theo phím tầng: phím tầng của ZMK (`&mo`) được xử lý trong
// firmware và không gửi gì về máy, nên VTX không có sự kiện nào để biết NAV đang giữ.
// Muốn HUD chỉ hiện lúc giữ NAV thì firmware phải gửi kèm một phím báo hiệu.
//
// SƠ ĐỒ LÀ BẢN CHÉP TAY. VTX không đọc được keymap trong bàn phím; nội dung nằm ở
// `~/Library/Application Support/VietTelex/layer-hud.json`, tạo từ `LayerHUDLayout.seed`
// lần đầu bật. Đổi ô trong ZMK Studio thì sửa file đó rồi tắt/bật lại toggle.
//
// MAIN THREAD ONLY. Không dính tới đường phím: panel không bao giờ thành key window, nên
// không lấy focus của app đang gõ. Nó NHẬN chuột để kéo đi chỗ khác được, cái giá là
// không bấm xuyên qua nó tới thứ nằm bên dưới.

import AppKit
import SwiftUI

struct LayerHUDLayout: Codable, Equatable {
    struct Layer: Codable, Equatable {
        var name: String
        /// Ba hàng, mỗi hàng 10 ô: 5 ô tay trái rồi 5 ô tay phải. "" là ô trống.
        var rows: [[String]]
        /// 6 ô ngón cái: 3 trái rồi 3 phải.
        var thumbs: [String]
    }

    var layers: [Layer]

    static let columnsPerHand = 5
    static let thumbsPerHand = 3

    /// Keymap đọc từ bàn phím ngày 12/10/2026 (docs/keyboard/CORNE-LAYOUT.md).
    static let seed = LayerHUDLayout(layers: [
        Layer(name: "NAV",
              rows: [["Esc", "[", "↑", "]", "Tab", "/", "7", "8", "9", "-"],
                     ["⌘", "←", "↓", "→", "⌘Tab", "*", "4", "5", "6", "+"],
                     ["⇧", "⇧⌘2", "⇧⌘3", "⇧⌘4", "FN", "=", "1", "2", "3", "."]],
              thumbs: ["⌘", "NAV", "Space", "⌥⌫", "0", "⇧Enter"]),
        Layer(name: "FN",
              rows: [["", "", "", "", "", "", "Sáng−", "Sáng+", "", ""],
                     ["", "", "", "", "", "", "Mute", "Vol−", "Vol+", "Play"],
                     ["", "", "", "", "FN", "", "⌃C", "", "", ""]],
              thumbs: ["", "NAV", "", "", "", ""]),
    ])

    /// Một file sửa tay dễ lệch số ô; vẽ một lưới lệch còn tệ hơn không vẽ.
    var isWellFormed: Bool {
        !layers.isEmpty && layers.allSatisfy { layer in
            layer.rows.count == 3
                && layer.rows.allSatisfy { $0.count == Self.columnsPerHand * 2 }
                && layer.thumbs.count == Self.thumbsPerHand * 2
        }
    }

    // MARK: - File

    /// Chỉ dùng trong test.
    nonisolated(unsafe) static var storeURLOverride: URL?

    static var storeURL: URL {
        if let storeURLOverride { return storeURLOverride }
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("VietTelex/layer-hud.json")
    }

    static var storeDisplayPath: String {
        (storeURL.path as NSString).abbreviatingWithTildeInPath
    }

    /// Sơ đồ trong file; chưa có file thì ghi `seed` ra đó để có cái mà sửa. File hỏng
    /// hoặc lệch số ô thì dùng `seed` và ĐỂ NGUYÊN file — không ghi đè công sửa tay.
    static func load() -> LayerHUDLayout {
        let url = storeURL
        guard let data = try? Data(contentsOf: url) else {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
            if let seeded = try? encoder.encode(seed) {
                try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                         withIntermediateDirectories: true)
                try? seeded.write(to: url, options: .atomic)
            }
            return seed
        }
        guard let stored = try? JSONDecoder().decode(LayerHUDLayout.self, from: data),
              stored.isWellFormed else {
            DebugLog.log("layer-hud: \(url.lastPathComponent) unreadable or malformed → built-in layout")
            return seed
        }
        return stored
    }
}

final class LayerHUDController {
    static let shared = LayerHUDController()

    private static let margin: CGFloat = 16

    private var panel: NSPanel?
    private var screenObserver: NSObjectProtocol?
    private var moveObserver: NSObjectProtocol?
    /// Đang tự đặt vị trí: didMove lúc này không phải người dùng kéo, đừng lưu.
    private var placing = false

    private init() {}

    /// Góc dưới phải của vùng dùng được (trên Dock, dưới menu bar). Thuần, test trực tiếp.
    static func origin(for size: CGSize, in visibleFrame: CGRect) -> CGPoint {
        CGPoint(x: visibleFrame.maxX - size.width - margin, y: visibleFrame.minY + margin)
    }

    /// Chỗ người dùng đã kéo tới, nếu bảng ở đó còn nằm trọn trong một màn hình; không
    /// thì về góc mặc định. Rút màn hình ngoài mà giữ toạ độ cũ là mất bảng.
    static func origin(saved: CGPoint?, size: CGSize, screens: [CGRect], main: CGRect) -> CGPoint {
        if let saved, screens.contains(where: { $0.contains(CGRect(origin: saved, size: size)) }) {
            return saved
        }
        return origin(for: size, in: main)
    }

    /// Hiện hoặc ẩn theo toggle. Gọi lại khi đang hiện thì đọc lại file sơ đồ.
    func apply(enabled: Bool) {
        guard enabled else { hide(); return }
        let host = DraggableHostingView(rootView: LayerHUDView(layout: LayerHUDLayout.load()))
        let size = host.fittingSize
        let panel = self.panel ?? makePanel()
        panel.contentView = host
        panel.setContentSize(size)
        self.panel = panel
        reposition()
        panel.orderFrontRegardless()
        if screenObserver == nil {
            screenObserver = NotificationCenter.default.addObserver(
                forName: NSApplication.didChangeScreenParametersNotification,
                object: nil, queue: .main) { [weak self] _ in self?.reposition() }
        }
        if moveObserver == nil {
            moveObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didMoveNotification, object: panel, queue: .main) { [weak self] _ in
                guard let self, !self.placing, let panel = self.panel else { return }
                AppState.shared.layerHUDOrigin = NSStringFromPoint(panel.frame.origin)
            }
        }
    }

    private func hide() {
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
        if let moveObserver { NotificationCenter.default.removeObserver(moveObserver) }
        screenObserver = nil
        moveObserver = nil
        panel?.orderOut(nil)
        panel = nil
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                            backing: .buffered, defer: true)
        panel.isReleasedWhenClosed = false
        panel.level = .statusBar
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
        return panel
    }

    private func reposition() {
        guard let panel, let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let saved = AppState.shared.layerHUDOrigin.map(NSPointFromString)
        placing = true
        panel.setFrameOrigin(Self.origin(saved: saved, size: panel.frame.size,
                                         screens: NSScreen.screens.map(\.visibleFrame),
                                         main: screen.visibleFrame))
        placing = false
    }
}

/// SwiftUI content không tự cho kéo cửa sổ; bảng không có control nào nên cả mặt bảng
/// là tay nắm.
private final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { true }
}

private struct LayerHUDView: View {
    let layout: LayerHUDLayout

    private static let keySize = CGSize(width: 38, height: 24)
    private static let gap: CGFloat = 3
    private static let handGap: CGFloat = 12

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(layout.layers.enumerated()), id: \.offset) { _, layer in
                VStack(alignment: .leading, spacing: Self.gap) {
                    Text(layer.name)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    ForEach(Array(layer.rows.enumerated()), id: \.offset) { _, row in
                        hands(row, perHand: LayerHUDLayout.columnsPerHand)
                    }
                    hands(layer.thumbs, perHand: LayerHUDLayout.thumbsPerHand)
                }
            }
        }
        .padding(10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 10))
        .fixedSize()
    }

    /// Một hàng chia hai tay. Hàng ngón cái ít ô hơn nên dồn về phía khe giữa.
    private func hands(_ cells: [String], perHand: Int) -> some View {
        let handWidth = CGFloat(LayerHUDLayout.columnsPerHand) * (Self.keySize.width + Self.gap) - Self.gap
        return HStack(spacing: Self.handGap) {
            HStack(spacing: Self.gap) {
                ForEach(0..<perHand, id: \.self) { key(cells[$0]) }
            }
            .frame(width: handWidth, alignment: .trailing)
            HStack(spacing: Self.gap) {
                ForEach(perHand..<perHand * 2, id: \.self) { key(cells[$0]) }
            }
            .frame(width: handWidth, alignment: .leading)
        }
    }

    private func key(_ label: String) -> some View {
        Text(label)
            .font(.system(size: 11))
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: Self.keySize.width, height: Self.keySize.height)
            .background(RoundedRectangle(cornerRadius: 4)
                .fill(Color.primary.opacity(label.isEmpty ? 0.03 : 0.10)))
    }
}
