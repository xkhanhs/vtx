// WordLog.swift
//
// TẠM THỜI — tính năng có hạn dùng. Gom danh sách "từ hay gõ" kèm tần suất, cục bộ,
// để đổ sang beartype luyện trên layout Colemak-DH-Việt. Khi đã có danh sách thì
// revert 4 commit `feat(wordlog)` là hết dấu vết (plans/260912-typing-word-logger).
//
// PRIVACY: đây là thứ DUY NHẤT trong VTX ghi lại chữ người dùng gõ, nên mọi thứ
// quanh nó phải thắt: opt-in, mặc định TẮT (AppState.logTypedWords), chỉ ghi vào một
// file trong ~/Library/Application Support/VietTelex, không mạng, không sync. Trái
// hẳn hợp đồng của DebugLog ("never pass user-typed text") — đừng bao giờ trộn hai
// cái này vào nhau.
//
// Điểm cắm: đúng hai chỗ "một từ vừa chốt" — TelexInputController.boundary(_:) và
// TerminalTap.emitBoundary(...). Không cắm ở tầng insertText (nhiều đường
// rewrite/backspace, một từ sẽ bị đếm nhiều lần).

import Foundation
import UserNotifications

/// Corpus `{từ: số_lần}` tích luỹ cục bộ khi người dùng bật "Ghi từ hay gõ".
///
/// Toàn bộ state sống trên `io` (serial queue, QoS utility): `note(_:)` chỉ lọc chuỗi
/// rồi `async` sang đó, nên đường phím không bao giờ chạm tới dictionary, file I/O hay
/// lock nào. Một lần dispatch mỗi RANH GIỚI TỪ (không phải mỗi phím) là rẻ.
///
/// Giới hạn đã biết: ⌫ trên ký tự ranh giới mở lại từ vừa chốt (`reopenLastCommit`),
/// từ đó sẽ được đếm lần nữa khi chốt lại. Corpus là bảng tần suất để luyện gõ, nhiễu
/// mức đó không đáng đánh đổi thêm state.
final class WordLog {
    static let shared = WordLog()

    /// Đạt tổng token này thì bắn thông báo "đã đủ mẫu" (một lần duy nhất).
    static let sampleTarget = 20_000

    /// Hai chặn nhiễu thay cho việc hỏi engine: từ tiếng Việt/Anh gõ liền mạch đều
    /// ngắn, còn từ `overflowed` (engine mất đồng bộ sau 32 phím) luôn dài hơn ngưỡng
    /// trên nên bị loại mà không cần biết cờ overflow của engine.
    private static let minLength = 2
    private static let maxLength = 20

    /// Ghi file trễ: gom trong RAM rồi flush sau `flushDelay`, hoặc ngay khi đã dồn
    /// `flushEvery` token — đủ để tắt máy đột ngột chỉ mất vài giây gõ cuối.
    private static let flushDelay: DispatchTimeInterval = .seconds(5)
    private static let flushEvery = 200

    private let io = DispatchQueue(label: "com.vtx.wordlog", qos: .utility)

    // MARK: State — io queue ONLY
    private var counts: [String: Int] = [:]
    private var total = 0
    private var milestoneNotified = false
    private var loaded = false
    private var unflushed = 0
    private var flushScheduled = false

    private init() {}

    // MARK: - Vị trí file

    /// Chỉ dùng trong test: trỏ corpus sang file tạm để suite không ghi vào corpus
    /// thật của người dùng.
    nonisolated(unsafe) static var storeURLOverride: URL?

    static var storeURL: URL {
        if let storeURLOverride { return storeURLOverride }
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        return base.appendingPathComponent("VietTelex/typing-corpus.json")
    }

    /// Đường dẫn hiển thị trong Cài đặt, để người dùng biết xoá cái gì khi gỡ tính năng.
    static var storeDisplayPath: String {
        (storeURL.path as NSString).abbreviatingWithTildeInPath
    }

    // MARK: - Lọc (thuần, test trực tiếp)

    /// Khoá đếm của một từ vừa chốt, hoặc `nil` nếu không đáng ghi.
    ///
    /// Bỏ: rỗng, quá ngắn ("à", "ơ" — nhiễu), quá dài (overflow), và mọi thứ chứa ký
    /// tự không phải chữ cái (số `2026`, dấu câu, chord). Hạ chữ thường để
    /// `Trường`/`trường` gộp một khoá; GIỮ NGUYÊN dấu tiếng Việt — đó chính là đầu ra
    /// mong muốn, nên không bao giờ bỏ dấu để gộp.
    static func normalize(_ raw: String) -> String? {
        guard !raw.isEmpty else { return nil }
        let word = raw.lowercased()
        let length = word.count
        guard length >= minLength, length <= maxLength else { return nil }
        for ch in word where !ch.isLetter { return nil }
        return word
    }

    // MARK: - Hot path

    /// Ghi nhận một từ VỪA CHỐT. No-op khi toggle tắt. Gọi được từ luồng nào cũng được
    /// (IMKit chạy trên main, TerminalTap trên luồng tap riêng).
    func note(_ raw: String) {
        guard AppState.shared.logTypedWords else { return }
        guard let word = Self.normalize(raw) else { return }
        io.async { self.record(word) }
    }

    // MARK: - io queue

    private func record(_ word: String) {
        loadIfNeeded()
        counts[word, default: 0] += 1
        total += 1
        unflushed += 1
        // Mốc mẫu: ghi cờ ra file NGAY (không chờ debounce) rồi mới báo, để một lần
        // tắt máy ngay sau đó không làm thông báo bắn lại ở lần chạy sau.
        if !milestoneNotified, total >= Self.sampleTarget {
            milestoneNotified = true
            save()
            Self.onMilestone()
            return
        }
        if unflushed >= Self.flushEvery { save(); return }
        guard !flushScheduled else { return }
        flushScheduled = true
        io.asyncAfter(deadline: .now() + Self.flushDelay) {
            self.flushScheduled = false
            if self.unflushed > 0 { self.save() }
        }
    }

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let data = try? Data(contentsOf: Self.storeURL),
              let stored = try? JSONDecoder().decode(Store.self, from: data) else { return }
        counts = stored.words
        total = stored.total
        milestoneNotified = stored.milestoneNotified
    }

    private func save() {
        unflushed = 0
        let url = Self.storeURL
        let store = Store(words: counts, total: total, milestoneNotified: milestoneNotified)
        guard let data = try? JSONEncoder().encode(store) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    private struct Store: Codable {
        var words: [String: Int]
        var total: Int
        var milestoneNotified: Bool
    }

    // MARK: - Đọc & export (main thread, Cài đặt)

    /// Tổng token + số từ khác nhau, cho dòng trạng thái trong Cài đặt.
    func stats() -> (total: Int, unique: Int) {
        io.sync { loadIfNeeded(); return (total, counts.count) }
    }

    // MARK: - Test seam

    /// Hành động khi đạt mốc mẫu. Là biến để test kiểm được "bắn đúng một lần" mà
    /// không phải xin quyền thông báo của hệ thống.
    nonisolated(unsafe) static var onMilestone: () -> Void = {
        DispatchQueue.main.async { WordLogNotifier.postMilestone() }
    }

    /// Quên hết state trong RAM để lần ghi kế tiếp đọc lại file — mô phỏng một lần
    /// khởi động mới của app. Chỉ dùng trong test.
    func resetForTestingByReloadingStore() {
        io.sync {
            loaded = false
            counts = [:]
            total = 0
            milestoneNotified = false
            unflushed = 0
        }
    }

    /// Nạp state trực tiếp, bỏ qua file — chỉ dùng trong test.
    func resetForTesting(words: [String: Int] = [:], total: Int = 0,
                         milestoneNotified: Bool = false) {
        io.sync {
            loaded = true
            counts = words
            self.total = total
            self.milestoneNotified = milestoneNotified
            unflushed = 0
        }
    }
}

/// Thông báo "đã đủ mẫu" — đúng MỘT lần cho cả vòng đời corpus (cờ nằm trong file, nên
/// khởi động lại app không bắn lại). Cùng dáng với `UpdateNotifier`: xin quyền lười,
/// bị từ chối thì im lặng — dòng trạng thái trong Cài đặt là bề mặt dự phòng.
enum WordLogNotifier {
    static let requestID = "viettelex.wordlog.milestone"

    @MainActor static func postMilestone() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = VTLocalized("VietTelex: enough typing samples collected")
            content.body = VTLocalized("Open Settings → Experimental to export your most-typed words.")
            let req = UNNotificationRequest(identifier: requestID, content: content, trigger: nil)
            center.add(req, withCompletionHandler: nil)
        }
    }
}
