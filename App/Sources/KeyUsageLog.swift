// KeyUsageLog.swift
//
// Đếm số lần NHẤN mỗi phím và mỗi tổ hợp (⌘Tab, ⌘⇧4, ⇧;, Enter, ⌫…) cùng số lần nhấn
// từng modifier trái/phải, gom theo ngày. Mục đích: sau vài ngày biết phím nào dùng
// nhiều để dành cho nó chỗ tốt trên Corne 36 phím (docs/keyboard/CORNE-LAYOUT.md).
//
// PRIVACY: chỉ có BỘ ĐẾM — `{tổ hợp: số lần}` mỗi ngày. Không ghi thứ tự, không ghi
// thời điểm từng phím, không ghi app, nên không dựng lại được nội dung đã gõ. Opt-in,
// mặc định TẮT (AppState.logKeyUsage), một file trong ~/Library/Application
// Support/VietTelex, không mạng. Lúc macOS bật Secure Input (ô mật khẩu) tap không
// nhận phím nào nên các phím đó tự nhiên không được đếm.
//
// MỘT điểm cắm: TerminalTapController.handle(). Tap thấy mọi phím vật lý của mọi app,
// với mọi input source (cả ABC), trước khi phím được chia về đường IMKit hay đường tap —
// nên không cần cắm thêm ở TelexInputController. Phím do phần mềm phát ra (của chính
// VTX, của PasteMe, của remote desktop) không được đếm: chỉ tính sự kiện từ phần cứng.

import CoreGraphics
import Foundation

final class KeyUsageLog {
    static let shared = KeyUsageLog()

    /// Ghi file trễ: gom trong RAM rồi flush sau `flushDelay`, hoặc ngay khi đã dồn
    /// `flushEvery` lần nhấn — tắt máy đột ngột chỉ mất vài giây cuối.
    private static let flushDelay: DispatchTimeInterval = .seconds(5)
    private static let flushEvery = 500

    /// Toàn bộ state sống trên queue này: tap chỉ `async` hai số nguyên sang, nên đường
    /// phím không chạm dictionary, file I/O hay bảng layout nào.
    private let io = DispatchQueue(label: "com.vtx.keyusage", qos: .utility)

    // MARK: State — io queue ONLY
    private var days: [String: Day] = [:]
    private var loaded = false
    private var unflushed = 0
    private var flushScheduled = false
    private var today = ""
    private var todayEnds = Date.distantPast

    struct Day: Codable, Equatable {
        /// "⌘Tab" → số lần. Khoá là nhãn của `comboLabel`.
        var combos: [String: Int] = [:]
        /// "⇧ trái" → số lần nhấn xuống. Khoá là nhãn của `modifierLabel`.
        var modifiers: [String: Int] = [:]
    }

    private init() {}

    // MARK: - Vị trí file

    /// Chỉ dùng trong test: trỏ sang file tạm để suite không ghi vào số liệu thật.
    nonisolated(unsafe) static var storeURLOverride: URL?
    /// Chỉ dùng trong test: đồng hồ giả để kiểm việc sang ngày.
    nonisolated(unsafe) static var now: () -> Date = { Date() }

    static var storeURL: URL {
        if let storeURLOverride { return storeURLOverride }
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("VietTelex/key-usage.json")
    }

    static var storeDisplayPath: String {
        (storeURL.path as NSString).abbreviatingWithTildeInPath
    }

    // MARK: - Nhãn (thuần, test trực tiếp)

    /// Phím có tên riêng, không phụ thuộc layout.
    private static let namedKeys: [UInt16: String] = [
        36: "Enter", 76: "Enter", 48: "Tab", 49: "Space", 51: "⌫", 117: "⌦", 53: "Esc",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        115: "Home", 119: "End", 116: "PgUp", 121: "PgDn",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
    ]

    /// US ANSI — dùng khi VTX không tự dịch layout (ABC, hoặc Telex không ghim layout).
    /// Đúng với mọi máy mà layout hệ thống là QWERTY; một layout hệ thống khác QWERTY mà
    /// không ghim qua VTX sẽ ra nhãn theo vị trí QWERTY.
    private static let usKeys: [UInt16: Character] = [
        0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x", 8: "c", 9: "v",
        11: "b", 12: "q", 13: "w", 14: "e", 15: "r", 16: "y", 17: "t", 18: "1", 19: "2",
        20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8",
        29: "0", 30: "]", 31: "o", 32: "u", 33: "[", 34: "i", 35: "p", 37: "l", 38: "j",
        39: "'", 40: "k", 41: ";", 42: "\\", 43: ",", 44: "/", 45: "n", 46: "m", 47: ".",
        50: "`",
    ]

    /// Ký tự ⇧ sinh ra từ một phím ký hiệu — chỉ để chú thích trong báo cáo ("⇧/ (?)").
    private static let shifted: [Character: Character] = [
        "1": "!", "2": "@", "3": "#", "4": "$", "5": "%", "6": "^", "7": "&", "8": "*",
        "9": "(", "0": ")", "-": "_", "=": "+", "[": "{", "]": "}", "\\": "|", ";": ":",
        "'": "\"", ",": "<", ".": ">", "/": "?", "`": "~",
    ]

    private static let modifierGlyphs: Set<Character> = ["⌃", "⌥", "⇧", "⌘"]

    /// Nhãn một lần nhấn: modifier theo thứ tự chuẩn của Apple (⌃⌥⇧⌘) rồi tên phím.
    /// `pinned` là ký tự KHÔNG shift mà layout VTX đang ghim đặt ở phím đó (nil = VTX
    /// không dịch) — trên DH-Việt phím vật lý P là `;`, và nhãn phải nói `;`.
    static func comboLabel(keyCode: UInt16, flags: CGEventFlags, pinned: UInt8?) -> String {
        var label = ""
        if flags.contains(.maskControl) { label += "⌃" }
        if flags.contains(.maskAlternate) { label += "⌥" }
        if flags.contains(.maskShift) { label += "⇧" }
        if flags.contains(.maskCommand) { label += "⌘" }
        if let name = namedKeys[keyCode] {
            label += name
        } else if let pinned {
            label += String(UnicodeScalar(pinned)).uppercased()
        } else if let us = usKeys[keyCode] {
            label += String(us).uppercased()
        } else {
            label += "key\(keyCode)"
        }
        return label
    }

    /// Nhãn một phím modifier theo keycode của sự kiện flagsChanged, nil nếu không phải.
    static func modifierLabel(keyCode: UInt16) -> String? {
        switch keyCode {
        case 56: return "⇧ trái"
        case 60: return "⇧ phải"
        case 55: return "⌘ trái"
        case 54: return "⌘ phải"
        case 58: return "⌥ trái"
        case 61: return "⌥ phải"
        case 59: return "⌃ trái"
        case 62: return "⌃ phải"
        case 63: return "fn"
        default: return nil
        }
    }

    /// Phân biệt NHẤN với NHẢ cho flagsChanged, vốn chỉ báo "cờ đã đổi". TAP-thread
    /// confined (một instance trong TerminalTapController).
    struct ModifierPressTracker {
        private var down: Set<UInt16> = []

        private static func flag(for keyCode: UInt16) -> CGEventFlags? {
            switch keyCode {
            case 56, 60: return .maskShift
            case 55, 54: return .maskCommand
            case 58, 61: return .maskAlternate
            case 59, 62: return .maskControl
            case 63: return .maskSecondaryFn
            default: return nil
            }
        }

        /// true đúng một lần cho mỗi lần phím modifier đi xuống.
        mutating func isPress(keyCode: UInt16, flags: CGEventFlags) -> Bool {
            guard let flag = Self.flag(for: keyCode) else { return false }
            // Cờ chung đã tắt = cả hai bên trái/phải đều đã nhả. Xoá cả cặp, để một lần
            // nhả bị lỡ (tap tắt giữa chừng) không làm lệch lần nhấn kế tiếp.
            guard flags.contains(flag) else {
                down = down.filter { Self.flag(for: $0) != flag }
                return false
            }
            // Cờ còn bật mà phím này đang ghi là xuống = nó vừa nhả, bên kia còn giữ.
            if down.remove(keyCode) != nil { return false }
            down.insert(keyCode)
            return true
        }
    }

    // MARK: - Hot path (TAP thread)

    /// Một keyDown vật lý. `vtxActive` = VTX đang là input source: chỉ khi đó bảng layout
    /// ghim mới phản ánh thứ người dùng thật sự gõ (ở ABC bảng đó còn nguyên từ lần trước).
    func noteKeyDown(_ event: CGEvent, vtxActive: Bool) {
        guard event.getIntegerValueField(.keyboardEventAutorepeat) == 0,
              event.getIntegerValueField(.eventSourceUnixProcessID) == 0 else { return }
        let keyCode = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        io.async {
            let pinned = vtxActive
                ? KeyboardLayoutOverride.translator?.ascii(keyCode: keyCode, shift: false) : nil
            let label = Self.comboLabel(keyCode: keyCode, flags: flags, pinned: pinned)
            self.record { $0.combos[label, default: 0] += 1 }
        }
    }

    /// Một phím modifier vừa đi xuống (đã qua `ModifierPressTracker`).
    func noteModifierPress(keyCode: UInt16) {
        guard let label = Self.modifierLabel(keyCode: keyCode) else { return }
        io.async { self.record { $0.modifiers[label, default: 0] += 1 } }
    }

    // MARK: - Lưu trữ (io queue)

    private func record(_ change: (inout Day) -> Void) {
        loadIfNeeded()
        let now = Self.now()
        if now >= todayEnds {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: now)
            todayEnds = calendar.date(byAdding: .day, value: 1, to: start) ?? now.addingTimeInterval(86_400)
            today = Self.dayKey(start)
        }
        change(&days[today, default: Day()])
        unflushed += 1
        if unflushed >= Self.flushEvery {
            save()
        } else if !flushScheduled {
            flushScheduled = true
            io.asyncAfter(deadline: .now() + Self.flushDelay) {
                self.flushScheduled = false
                if self.unflushed > 0 { self.save() }
            }
        }
    }

    static func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let data = try? Data(contentsOf: Self.storeURL),
              let stored = try? JSONDecoder().decode(Store.self, from: data) else { return }
        days = stored.days
    }

    private func save() {
        unflushed = 0
        let url = Self.storeURL
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(Store(days: days)) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private struct Store: Codable {
        var days: [String: Day]
    }

    // MARK: - Đọc (main thread, Cài đặt)

    /// Ảnh chụp số liệu hiện có, đã gồm phần chưa kịp ghi ra file.
    func snapshot() -> [String: Day] {
        io.sync { loadIfNeeded(); return days }
    }

    /// Ghi ngay phần còn trong RAM — gọi khi tắt toggle.
    func flush() {
        io.sync { if unflushed > 0 { save() } }
    }

    /// Xoá sạch — RAM **và** file. Xoá mỗi file thì lần flush kế tiếp ghi nó trở lại.
    func reset() {
        io.sync {
            loaded = true
            days = [:]
            unflushed = 0
            try? FileManager.default.removeItem(at: Self.storeURL)
        }
    }

    /// Quên state trong RAM để lần ghi kế tiếp đọc lại file — mô phỏng một lần khởi động
    /// mới của app. Chỉ dùng trong test.
    func resetForTestingByReloadingStore() {
        io.sync {
            loaded = false
            days = [:]
            unflushed = 0
            today = ""
            todayEnds = .distantPast
        }
    }

    // MARK: - Báo cáo (thuần)

    struct Row: Equatable {
        let label: String
        let count: Int
    }

    struct Summary: Equatable {
        var dayCount = 0
        var firstDay = ""
        var lastDay = ""
        /// Mọi keyDown, không tính lần nhấn modifier.
        var total = 0
        /// Có ⌘, ⌃ hoặc ⌥.
        var shortcuts: [Row] = []
        /// Phím có tên, chữ số, ký hiệu — trần hoặc chỉ kèm ⇧.
        var keys: [Row] = []
        var modifiers: [Row] = []
        /// Chữ cái trần và ⇧+chữ: gộp một con số, vì chỗ của chúng trên layout đã chốt.
        var letters = 0
        var shiftedLetters = 0
    }

    static func summarize(_ days: [String: Day]) -> Summary {
        var summary = Summary()
        let names = days.keys.sorted()
        summary.dayCount = names.count
        summary.firstDay = names.first ?? ""
        summary.lastDay = names.last ?? ""

        var shortcuts: [String: Int] = [:]
        var keys: [String: Int] = [:]
        var modifiers: [String: Int] = [:]
        for day in days.values {
            for (label, count) in day.modifiers { modifiers[label, default: 0] += count }
            for (label, count) in day.combos {
                summary.total += count
                let key = label.drop(while: { modifierGlyphs.contains($0) })
                let mods = label.dropLast(key.count)
                if mods.contains(where: { $0 != "⇧" }) {
                    shortcuts[label, default: 0] += count
                } else if key.count == 1, key.first?.isLetter == true {
                    summary.letters += count
                    if !mods.isEmpty { summary.shiftedLetters += count }
                } else {
                    keys[label, default: 0] += count
                }
            }
        }
        // Đồng hạng sắp theo nhãn để hai lần xuất cùng số liệu ra cùng một bảng.
        func rows(_ counts: [String: Int]) -> [Row] {
            counts.map { Row(label: $0.key, count: $0.value) }
                .sorted { $0.count == $1.count ? $0.label < $1.label : $0.count > $1.count }
        }
        summary.shortcuts = rows(shortcuts)
        summary.keys = rows(keys)
        summary.modifiers = rows(modifiers)
        return summary
    }

    /// "⇧/" → "⇧/ (?)"; nhãn khác giữ nguyên.
    static func annotated(_ label: String) -> String {
        guard label.count == 2, label.first == "⇧", let base = label.last,
              let glyph = shifted[Character(base.lowercased())] else { return label }
        return "\(label) (\(glyph))"
    }

    /// Bảng chữ thuần để dán vào chat hoặc ghi chú.
    static func report(_ days: [String: Day]) -> String {
        let summary = summarize(days)
        guard summary.dayCount > 0 else { return "Chưa có số liệu." }
        let perDay = { (count: Int) in
            String(format: "%.1f", Double(count) / Double(summary.dayCount))
        }
        var lines = ["VTX — số lần nhấn phím, \(summary.dayCount) ngày "
            + "(\(summary.firstDay) → \(summary.lastDay)), \(summary.total) lần nhấn"]
        func section(_ title: String, _ rows: [Row]) {
            guard !rows.isEmpty else { return }
            lines.append("")
            lines.append(title.padding(toLength: 30, withPad: " ", startingAt: 0) + "    lần    /ngày")
            for row in rows {
                let label = annotated(row.label).padding(toLength: 30, withPad: " ", startingAt: 0)
                let count = String(row.count).leftPadded(to: 7)
                lines.append("\(label)\(count)\(perDay(row.count).leftPadded(to: 9))")
            }
        }
        section("PHÍM TẮT (có ⌘ ⌃ ⌥)", summary.shortcuts)
        section("PHÍM RIÊNG, SỐ, KÝ HIỆU", summary.keys)
        section("MODIFIER (lần nhấn xuống)", summary.modifiers)
        lines.append("")
        lines.append("CHỮ CÁI: \(summary.letters) lần, trong đó ⇧+chữ \(summary.shiftedLetters)")
        return lines.joined(separator: "\n")
    }
}

private extension String {
    func leftPadded(to width: Int) -> String {
        count >= width ? self : String(repeating: " ", count: width - count) + self
    }
}
