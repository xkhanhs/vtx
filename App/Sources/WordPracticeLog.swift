// WordPracticeLog.swift
//
// Ghi lại những TỪ người dùng gõ bằng VTX Colemak: từ nào gõ nhiều, từ nào hay phải xoá
// gõ lại (kèm chữ gõ nhầm), từ nào gõ chậm. Mục đích: có danh sách từ thật để tập trên
// beartype, cả tiếng Việt lẫn tiếng Anh (merge, commit, files…). Bật trong tab Thử
// Nghiệm, đủ số liệu thì tắt.
//
// PRIVACY: khác KeyUsageLog, file này CÓ chứa chữ: mỗi từ là một khoá kèm bộ đếm. Không
// ghi thứ tự từ, không ghi câu, không ghi app, không ghi giờ — chỉ `{từ: số lần, số lần
// sai, tổng ms}` — nên không dựng lại được đoạn văn đã gõ, nhưng đọc được vốn từ. Opt-in,
// mặc định TẮT (AppState.logWordPractice), một file trong ~/Library/Application
// Support/VietTelex, không mạng. Ô mật khẩu bật Secure Input nên tap không thấy phím.
// Token có chữ số bị bỏ, nên mã, số điện thoại, mật khẩu kiểu `abc123` không vào file.
//
// CHỈ ĐO VTX COLEMAK: phím chỉ được tính khi VTX là input source VÀ đang dịch qua một
// layout ghim (`KeyboardLayoutOverride.translator != nil`). Với cấu hình của máy này
// Telex ghim ABC = layout sống nên không có translator; Colemak ghim DH-Việt nên có.
//
// MỘT điểm cắm, như KeyUsageLog: TerminalTapController.handle() thấy mọi phím vật lý của
// mọi app trước khi phím chia về đường IMKit hay đường tap. Từ được dựng lại bằng một
// TelexEngine riêng chạy cùng cờ với engine thật, nên "đường" hay "merge" ra đúng chữ
// trên màn hình (trừ chỗ engine thật dựa vào ngữ cảnh từ trước — sai lệch nhỏ, chấp nhận).

import CoreGraphics
import Foundation
import TelexCore

final class WordPracticeLog {
    static let shared = WordPracticeLog()

    private static let flushDelay: DispatchTimeInterval = .seconds(5)
    private static let flushEvery = 100

    /// Toàn bộ state sống trên queue này; tap chỉ `async` vài số nguyên sang.
    private let io = DispatchQueue(label: "com.vtx.wordpractice", qos: .utility)

    // MARK: State — io queue ONLY
    private var store = Store()
    private var tracker = WordTracker()
    private var loaded = false
    private var unflushed = 0
    private var flushScheduled = false

    struct Stat: Codable, Equatable {
        /// Số lần từ được gõ xong (chốt bằng dấu cách / dấu câu / Enter).
        var count = 0
        /// Số lần trong đó có ⌫ — xoá trong từ, hoặc xoá lùi qua dấu cách để sửa nó.
        var errors = 0
        /// Số lần đo được nhịp (không ⌫, không ngừng tay giữa chừng) và tổng của chúng.
        var timed = 0
        var totalMs = 0
        var totalKeys = 0
        /// Chữ trên màn hình lúc bấm ⌫ đầu tiên → số lần. Tối đa `maxMistakes` dạng.
        var mistakes: [String: Int] = [:]
    }

    struct Store: Codable, Equatable {
        /// Ngày → số từ đã gõ — chỉ để báo "N ngày (a → b)".
        var days: [String: Int] = [:]
        var words: [String: Stat] = [:]
    }

    static let maxMistakes = 5

    private init() {}

    // MARK: - Vị trí file

    nonisolated(unsafe) static var storeURLOverride: URL?
    nonisolated(unsafe) static var now: () -> Date = { Date() }

    static var storeURL: URL {
        if let storeURLOverride { return storeURLOverride }
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("VietTelex/word-practice.json")
    }

    static var storeDisplayPath: String {
        (storeURL.path as NSString).abbreviatingWithTildeInPath
    }

    // MARK: - Phân loại phím (thuần)

    /// Phím ngắt từ mà không chốt nó: con trỏ đã/ có thể đã đi chỗ khác.
    private static let breakKeys: Set<UInt16> = [
        53, 117, 123, 124, 125, 126, 115, 119, 116, 121,   // Esc ⌦ mũi tên Home End PgUp PgDn
    ]

    /// Ký tự chốt từ — dấu câu thường gặp sau một từ.
    private static let separators: Set<UInt8> = Set(" .,;:!?\"'()-/".utf8)

    /// Một keyDown vật lý → đầu vào cho `WordTracker`. `ascii` là ký tự layout ghim sinh ra
    /// (nil = VTX không dịch layout, tức không phải VTX Colemak → không đo).
    static func classify(keyCode: UInt16, flags: CGEventFlags, ascii: UInt8?) -> WordTracker.Input {
        if !flags.intersection([.maskCommand, .maskControl, .maskAlternate]).isEmpty { return .breakWord }
        switch keyCode {
        case 51: return .backspace
        case 49, 36, 76, 48: return .separator
        default: break
        }
        if breakKeys.contains(keyCode) { return .breakWord }
        guard let ascii else { return .breakWord }
        if (ascii >= 0x61 && ascii <= 0x7A) || (ascii >= 0x41 && ascii <= 0x5A) {
            return .letter(Character(UnicodeScalar(ascii)))
        }
        return separators.contains(ascii) ? .separator : .breakWord
    }

    // MARK: - Hot path (TAP thread)

    func noteKeyDown(_ event: CGEvent, vtxActive: Bool) {
        guard event.getIntegerValueField(.eventSourceUnixProcessID) == 0 else { return }
        let keyCode = UInt16(truncatingIfNeeded: event.getIntegerValueField(.keyboardEventKeycode))
        let flags = event.flags
        let ns = DispatchTime.now().uptimeNanoseconds
        io.async {
            let ascii = vtxActive
                ? KeyboardLayoutOverride.translator?.ascii(keyCode: keyCode,
                                                          shift: flags.contains(.maskShift))
                : nil
            self.feed(Self.classify(keyCode: keyCode, flags: flags, ascii: ascii), ns: ns)
        }
    }

    /// Click chuột: con trỏ đã đi chỗ khác.
    func noteBreak() {
        let ns = DispatchTime.now().uptimeNanoseconds
        io.async { self.feed(.breakWord, ns: ns) }
    }

    // MARK: - Lưu trữ (io queue)

    private func feed(_ input: WordTracker.Input, ns: UInt64) {
        if tracker.needsFlags { tracker.flags = AppState.shared.engineFlags() }
        tracker.autoRestore = AppState.shared.autoRestore
        record(tracker.handle(input, ns: ns))
    }

    private func record(_ done: [WordTracker.Finished]) {
        guard !done.isEmpty else { return }
        loadIfNeeded()
        let day = KeyUsageLog.dayKey(Self.now())
        for word in done {
            Self.add(word, to: &store)
            store.days[day, default: 0] += 1
            unflushed += 1
        }
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

    static func add(_ word: WordTracker.Finished, to store: inout Store) {
        var stat = store.words[word.text, default: Stat()]
        stat.count += 1
        if word.errored { stat.errors += 1 }
        if let mistake = word.mistake, mistake != word.text,
           stat.mistakes[mistake] != nil || stat.mistakes.count < maxMistakes {
            stat.mistakes[mistake, default: 0] += 1
        }
        if let ms = word.ms {
            stat.timed += 1
            stat.totalMs += ms
            stat.totalKeys += word.keys
        }
        store.words[word.text] = stat
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let data = try? Data(contentsOf: Self.storeURL),
              let stored = try? JSONDecoder().decode(Store.self, from: data) else { return }
        store = stored
    }

    private func save() {
        unflushed = 0
        let url = Self.storeURL
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(store) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    // MARK: - Đọc (main thread, Cài đặt)

    func snapshot() -> Store {
        io.sync { loadIfNeeded(); return store }
    }

    /// Chốt từ đang chờ và ghi ngay — gọi khi tắt toggle.
    func flush() {
        io.sync {
            record(tracker.handle(.breakWord, ns: 0))
            if unflushed > 0 { save() }
        }
    }

    /// Chỉ dùng trong test: ghi thẳng các từ đã gõ xong, như tap sẽ ghi.
    func recordForTesting(_ done: [WordTracker.Finished]) { io.sync { record(done) } }

    func reset() {
        io.sync {
            loaded = true
            store = Store()
            tracker = WordTracker()
            unflushed = 0
            try? FileManager.default.removeItem(at: Self.storeURL)
        }
    }

    /// Chỉ dùng trong test: quên RAM để lần ghi kế tiếp đọc lại file.
    func resetForTestingByReloadingStore() {
        io.sync {
            loaded = false
            store = Store()
            tracker = WordTracker()
            unflushed = 0
        }
    }

    // MARK: - Báo cáo (thuần)

    struct Row: Equatable {
        let word: String
        let stat: Stat
        var msPerKey: Double? { stat.timed > 0 && stat.totalKeys > 0
            ? Double(stat.totalMs) / Double(stat.totalKeys) : nil }
        var errorRate: Double { stat.count > 0 ? Double(stat.errors) / Double(stat.count) : 0 }
    }

    /// Ngưỡng để một từ được xếp hạng — dưới mức này một lần trượt tay đã đủ đẩy từ lên đầu.
    static let minErrors = 2
    /// 3 lần đo để lọt cả mẩu như `tp`, `hh`, `gg` lên đầu bảng từ chậm (số liệu 15–22/10/2026);
    /// từ 8 lần trở lên chỉ còn từ thật như claude, lark, merge.
    static let minTimed = 8

    /// Nhịp trung bình ms/phím trên mọi lần đo được.
    static func baselineMsPerKey(_ store: Store) -> Double? {
        let (ms, keys) = store.words.values.reduce((0, 0)) { ($0.0 + $1.totalMs, $0.1 + $1.totalKeys) }
        return keys > 0 ? Double(ms) / Double(keys) : nil
    }

    static func errorRows(_ store: Store) -> [Row] {
        store.words.map { Row(word: $0.key, stat: $0.value) }
            .filter { $0.stat.errors >= minErrors }
            .sorted { ($0.stat.errors, $1.word) > ($1.stat.errors, $0.word) }
    }

    static func slowRows(_ store: Store) -> [Row] {
        store.words.map { Row(word: $0.key, stat: $0.value) }
            .filter { $0.stat.timed >= minTimed }
            .sorted { ($0.msPerKey ?? 0, $1.word) > ($1.msPerKey ?? 0, $0.word) }
    }

    static func frequentRows(_ store: Store) -> [Row] {
        store.words.map { Row(word: $0.key, stat: $0.value) }
            .sorted { ($0.stat.count, $1.word) > ($1.stat.count, $0.word) }
    }

    /// Từ nên tập, theo thứ tự ưu tiên: hay sai trước, rồi chậm hơn nhịp trung bình 30%,
    /// mỗi từ một lần.
    static func practiceWords(_ store: Store, limit: Int = 60) -> [String] {
        var out: [String] = []
        var seen = Set<String>()
        for row in errorRows(store) where seen.insert(row.word).inserted { out.append(row.word) }
        if let base = baselineMsPerKey(store) {
            for row in slowRows(store) where (row.msPerKey ?? 0) > base * 1.3
                && seen.insert(row.word).inserted { out.append(row.word) }
        }
        return Array(out.prefix(limit))
    }

    // MARK: - Cặp phím hay nhầm (thuần)

    /// Keycode của ba hàng chữ bàn phím ANSI, mỗi hàng 10 ô từ trái sang phải.
    static let letterKeyCodes: [UInt16] = [
        12, 13, 14, 15, 17, 16, 32, 34, 31, 35,   // Q W E R T Y U I O P
        0, 1, 2, 3, 5, 4, 38, 40, 37, 41,         // A S D F G H J K L ;
        6, 7, 8, 9, 11, 45, 46, 43, 47, 44,       // Z X C V B N M , . /
    ]
    /// Chữ in trên 30 ô đó theo QWERTY: nơi tay quen tìm tới.
    static let qwertyLetters = Array("qwertyuiopasdfghjkl;zxcvbnm,./")

    /// 30 chữ một layout sinh ra trên 30 ô đó, nil nếu thiếu ô nào.
    static func letters(of translator: KeyboardLayoutTranslator) -> [Character]? {
        let out = letterKeyCodes.compactMap { translator.character(keyCode: $0, shift: false) }
        return out.count == letterKeyCodes.count ? out.map { Character($0.lowercased()) } : nil
    }

    enum Confusion: String {
        /// Ngón tìm về ô của chữ đó trên QWERTY.
        case qwertyHabit = "thói QWERTY"
        /// Ngón bên cạnh, cùng hàng, cùng tay.
        case neighbour = "ngón kề"
        /// Cùng một ngón, lệch ô.
        case sameFinger = "cùng ngón"
    }

    struct ConfusionRow: Equatable {
        let wanted: Character
        let typed: Character
        let kind: Confusion
        let count: Int
    }

    /// Phím sai đầu tiên của mỗi lần gõ nhầm, xếp loại theo vị trí trên `layout` (30 chữ
    /// theo `letterKeyCodes`). So trên chữ đã bỏ dấu, nên "có" gõ nhầm thành "cho" là muốn
    /// `o` mà gõ `h`. Lần nhầm chỉ dừng sớm (gõ đúng nhưng chưa xong) thì không có phím
    /// sai; lần bỏ sót một phím và lần nhầm không thuộc ba loại trên thì không xếp.
    static func confusions(_ store: Store, layout: [Character]) -> [ConfusionRow] {
        guard layout.count == 30 else { return [] }
        var slot: [Character: Int] = [:]
        for (i, ch) in layout.enumerated() where slot[ch] == nil { slot[ch] = i }
        // Ngón theo cột: hai cột giữa thuộc ngón trỏ của tay bên đó.
        func finger(_ col: Int) -> Int { col == 4 ? 3 : col == 5 ? 6 : col }
        func kind(_ wanted: Character, _ typed: Character) -> Confusion? {
            guard let w = slot[wanted], let t = slot[typed] else { return nil }
            if let q = qwertyLetters.firstIndex(of: wanted), layout[q] == typed { return .qwertyHabit }
            let (fw, ft) = (finger(w % 10), finger(t % 10))
            if fw == ft { return .sameFinger }
            if w / 10 == t / 10, (fw < 5) == (ft < 5), abs(fw - ft) == 1 { return .neighbour }
            return nil
        }
        var counts: [String: (Character, Character, Confusion, Int)] = [:]
        for (word, stat) in store.words {
            let want = Array(plainLetters(word))
            for (mistake, n) in stat.mistakes {
                let got = Array(plainLetters(mistake))
                guard let i = want.indices.first(where: { $0 < got.count && want[$0] != got[$0] }),
                      // Phím sau bị gõ sớm = bỏ sót một phím, không phải nhầm ô.
                      !(i + 1 < want.count && got[i] == want[i + 1]),
                      let k = kind(want[i], got[i]) else { continue }
                let key = String([want[i], got[i]])
                counts[key, default: (want[i], got[i], k, 0)].3 += n
            }
        }
        return counts.values.map { ConfusionRow(wanted: $0.0, typed: $0.1, kind: $0.2, count: $0.3) }
            .sorted { ($0.count, String([$1.wanted, $1.typed])) > ($1.count, String([$0.wanted, $0.typed])) }
    }

    /// "rồi" → "roi", "được" → "duoc": chữ cái gốc, như phím đã bấm.
    static func plainLetters(_ text: String) -> String {
        String(text.replacingOccurrences(of: "đ", with: "d")
            .decomposedStringWithCanonicalMapping.unicodeScalars
            .filter { !(0x300...0x36F).contains($0.value) }
            .map(Character.init))
    }

    static func report(_ store: Store, top: Int = 40, layout: [Character]? = nil) -> String {
        let total = store.words.values.reduce(0) { $0 + $1.count }
        guard total > 0 else { return "Chưa có số liệu." }
        let days = store.days.keys.sorted()
        let errors = store.words.values.reduce(0) { $0 + $1.errors }
        var lines = ["VTX Colemak — từ đã gõ, \(days.count) ngày "
            + "(\(days.first ?? "") → \(days.last ?? "")), \(total) từ, "
            + "\(store.words.count) từ khác nhau, \(errors) lần phải sửa "
            + "(\(percent(Double(errors) / Double(total))))"]
        let base = baselineMsPerKey(store)
        if let base {
            // Một "phím" ở đây là một phím Telex (dd, aa, s…), không phải một ký tự ra màn hình.
            lines.append("Nhịp trung bình: \(Int(base.rounded())) ms/phím "
                + "(≈ \(Int((60_000 / (base * 5)).rounded())) wpm tính theo 5 phím/từ)")
        }

        func ms(_ row: Row) -> String { row.msPerKey.map { String(Int($0.rounded())) } ?? "-" }
        func table(_ title: String, _ header: String, _ rows: [Row], _ cells: (Row) -> String) {
            guard !rows.isEmpty else { return }
            lines.append("")
            lines.append(title.padding(toLength: 24, withPad: " ", startingAt: 0) + header)
            for row in rows.prefix(top) {
                lines.append(row.word.padding(toLength: 24, withPad: " ", startingAt: 0) + cells(row))
            }
        }

        table("TỪ HAY SAI", "   lần   sai  tỉ lệ  gõ nhầm thành", errorRows(store)) { row in
            let typos = row.stat.mistakes.sorted { ($0.value, $1.key) > ($1.value, $0.key) }
                .map { "\($0.key)×\($0.value)" }.joined(separator: " ")
            return row.stat.count.padded(6) + row.stat.errors.padded(6)
                + percent(row.errorRate).leftPadded(7) + "  " + typos
        }
        table("TỪ CHẬM (≥\(minTimed) lần đo)", "   lần  ms/phím  so với TB", slowRows(store)) { row in
            let ratio = base.flatMap { b in row.msPerKey.map { String(format: "×%.2f", $0 / b) } } ?? ""
            return row.stat.count.padded(6) + ms(row).leftPadded(9) + ratio.leftPadded(11)
        }
        table("TỪ GÕ NHIỀU NHẤT", "   lần  ms/phím   sai", frequentRows(store)) { row in
            row.stat.count.padded(6) + ms(row).leftPadded(9) + row.stat.errors.padded(6)
        }

        if let layout {
            let rows = confusions(store, layout: layout)
            if !rows.isEmpty {
                let byKind = [Confusion.qwertyHabit, .neighbour, .sameFinger].map { kind in
                    "\(kind.rawValue) \(rows.filter { $0.kind == kind }.reduce(0) { $0 + $1.count })"
                }
                lines.append("")
                lines.append("CẶP PHÍM HAY NHẦM (muốn → gõ): " + byKind.joined(separator: " · "))
                for row in rows.prefix(top / 2) {
                    lines.append("\(row.wanted) → \(row.typed)".padding(toLength: 24, withPad: " ", startingAt: 0)
                        + row.count.padded(6) + "  " + row.kind.rawValue)
                }
            }
        }

        let practice = practiceWords(store)
        if !practice.isEmpty {
            lines.append("")
            lines.append("DÒNG TẬP (dán vào beartype):")
            lines.append(practice.joined(separator: " "))
        }
        return lines.joined(separator: "\n")
    }

    private static func percent(_ value: Double) -> String { "\(Int((value * 100).rounded()))%" }
}

// MARK: - Dựng từ từ chuỗi phím (thuần, io queue)

/// Biến chuỗi phím thành các từ đã gõ xong, mỗi từ kèm: có phải sửa không, chữ gõ nhầm,
/// và thời gian gõ nếu đo được.
///
/// Từ vừa chốt được giữ "chờ" cho tới phím chữ kế tiếp: ⌫ lùi qua dấu cách mở lại nó
/// (đánh dấu sai), như người dùng thật sự làm khi thấy từ trước gõ nhầm.
struct WordTracker {
    enum Input: Equatable {
        case letter(Character)
        case backspace
        /// Dấu cách, Enter, Tab, dấu câu — chốt từ.
        case separator
        /// ⌘/⌃/⌥, mũi tên, Esc, click, chữ số, phím ngoài layout — bỏ từ đang gõ dở.
        case breakWord
    }

    struct Finished: Equatable {
        let text: String
        let errored: Bool
        let mistake: String?
        /// Từ phím chữ đầu tới phím chốt, nil nếu không đo được.
        let ms: Int?
        let keys: Int
    }

    /// Ngừng tay lâu hơn chừng này giữa hai phím = đang nghĩ, không phải gõ chậm.
    static let stallNs: UInt64 = 2_000_000_000
    static let maxKeys = 30

    var flags = AppState.EngineFlags()
    var autoRestore = true
    /// true khi sắp bắt đầu một từ mới — lúc đó mới cần đọc cờ engine.
    var needsFlags: Bool { word.keys == 0 && !word.errored }

    private struct Attempt {
        var engine = TelexEngine()
        var keys = 0
        var startNs: UInt64 = 0
        var lastNs: UInt64 = 0
        var errored = false
        var stalled = false
        var mistake: String?
    }

    private var word = Attempt()
    /// Từ vừa chốt (trạng thái TRƯỚC khi chốt) + số ký tự chốt đã gõ sau nó.
    private var pending: (attempt: Attempt, text: String, ms: Int?)?
    private var separatorsAfter = 0

    mutating func handle(_ input: Input, ns: UInt64) -> [Finished] {
        var out: [Finished] = []
        switch input {
        case .letter(let ch):
            if let done = takePending() { out.append(done) }
            if word.keys == 0 && !word.errored { word.engine.apply(flags) }
            if word.keys == 0 { word.startNs = ns }
            else if ns &- word.lastNs > Self.stallNs { word.stalled = true }
            word.lastNs = ns
            word.keys += 1
            _ = word.engine.feed(ch)
        case .backspace:
            if word.keys > 0 {
                if !word.errored { word.mistake = word.engine.composed.lowercased() }
                word.errored = true
                _ = word.engine.backspace()
                if word.engine.isEmpty { word.keys = 0 }
            } else if pending != nil, separatorsAfter > 0 {
                separatorsAfter -= 1
                if separatorsAfter == 0, let reopened = pending {
                    pending = nil
                    word = reopened.attempt
                    if !word.errored { word.mistake = reopened.text }
                    word.errored = true
                }
            }
        case .separator:
            if word.keys > 0 {
                if let done = takePending() { out.append(done) }
                var engine = word.engine
                let text = engine.commitText(autoRestore: autoRestore).lowercased()
                let timed = !word.errored && !word.stalled && word.keys >= 2
                    && ns &- word.lastNs <= Self.stallNs
                pending = (word, text, timed ? Int((ns &- word.startNs) / 1_000_000) : nil)
                separatorsAfter = 1
                word = Attempt()
            } else {
                // Cả từ đã bị xoá hết rồi chốt: lần thử đó bỏ, đừng để dấu "sai" của nó
                // dính sang từ sau.
                word = Attempt()
                if pending != nil { separatorsAfter += 1 }
            }
        case .breakWord:
            if let done = takePending() { out.append(done) }
            word = Attempt()
        }
        return out
    }

    private mutating func takePending() -> Finished? {
        guard let pending else { return nil }
        self.pending = nil
        separatorsAfter = 0
        let a = pending.attempt
        guard pending.text.count >= 2, a.keys <= Self.maxKeys,
              pending.text.allSatisfy(\.isLetter) else { return nil }
        return Finished(text: pending.text, errored: a.errored,
                        mistake: a.errored ? a.mistake : nil, ms: pending.ms, keys: a.keys)
    }
}

private extension Int {
    func padded(_ width: Int) -> String { String(self).leftPadded(width) }
}

private extension String {
    func leftPadded(_ width: Int) -> String {
        count >= width ? self : String(repeating: " ", count: width - count) + self
    }
}
