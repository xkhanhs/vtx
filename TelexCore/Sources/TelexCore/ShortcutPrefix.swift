// ShortcutPrefix.swift
// Gõ tắt có tiền tố dấu câu: "/shop" + space → nội dung đã soạn.
//
// Dấu câu là RANH GIỚI từ, nên engine chỉ thấy "shop" — khoá "/shop" trong bảng gõ
// tắt không bao giờ khớp nếu chỉ tra từ. Struct này nhớ ký tự ranh giới gõ NGAY
// TRƯỚC chữ đầu tiên của từ, để lúc chốt từ tra thêm "<ký tự>" + từ, và xoá lùi
// thêm đúng một ký tự (chính dấu "/" đó) khi khớp.
//
// "Ngay trước" là chặt: bất kỳ phím nào khác xen giữa (⌫, mũi tên, phím tắt, click)
// đều xoá tiền tố. Người gọi làm điều đó bằng cách `takePending()` ở MỌI phím thật,
// và chỉ trả nó lại cho `startWord` khi phím đó mở đầu một từ.

public struct ShortcutPrefix {
    /// Ký tự ranh giới vừa gõ, chưa có chữ nào theo sau.
    private var pending: Character?
    /// Tiền tố của từ đang gõ (nil = không có).
    public private(set) var current: Character?

    public init() {}

    /// Gọi ở đầu mỗi phím thật. Trả về tiền tố mà CHÍNH phím này có thể dùng.
    public mutating func takePending() -> Character? {
        defer { pending = nil }
        return pending
    }

    /// Phím chữ đầu tiên của một từ mới: `prefix` là giá trị `takePending()` của nó.
    public mutating func startWord(_ prefix: Character?) {
        current = prefix
    }

    /// Phím ranh giới vừa được xử lý xong (sau khi từ trước đã chốt).
    public mutating func boundaryKey(_ ch: Character?) {
        current = nil
        pending = ch.flatMap { Self.isCandidate($0) ? $0 : nil }
    }

    /// Caret đã rời chỗ cũ (click, đổi ô, bỏ composition).
    public mutating func reset() {
        pending = nil
        current = nil
    }

    /// Dấu câu / ký hiệu ASCII in được, trừ khoảng trắng — "/", ";", "@", "!"…
    static func isCandidate(_ ch: Character) -> Bool {
        guard let a = ch.asciiValue, a > 0x20, a < 0x7F else { return false }
        return !ch.isLetter && !ch.isNumber
    }

    /// Tra bảng gõ tắt cho từ vừa chốt. Khoá có tiền tố được ưu tiên — "/shop" thắng
    /// "shop" khi người dùng thực sự gõ "/shop". `extraBackspaces` = 1 khi khớp khoá
    /// có tiền tố (xoá luôn dấu "/" trên màn hình), 0 khi khớp từ trần.
    ///
    /// `bareAllowed == false` khi từ dính liền sau một ký tự MỞ TOKEN (chữ số "5h",
    /// hay "/" "#" "@" của slash command / hashtag / mention): lúc đó nó không phải
    /// một từ đứng riêng nên khoá TRẦN không được nở ("/h3" phải giữ nguyên dù "h"
    /// có trong bảng). Khoá CÓ TIỀN TỐ vẫn nở: người dùng đăng ký hẳn "/shop" thì
    /// dấu "/" là một phần của khoá, không phải ngữ cảnh lạ (VTX #87).
    public static func lookup(word: String, raw: String, prefix: Character?,
                              bareAllowed: Bool = true,
                              in shortcuts: [String: String])
        -> (expansion: String, extraBackspaces: Int)? {
        if let p = prefix {
            let lead = String(p)
            if !word.isEmpty, let e = shortcuts[lead + word] { return (e, 1) }
            if let e = shortcuts[lead + raw] { return (e, 1) }
        }
        guard bareAllowed else { return nil }
        if !word.isEmpty, let e = shortcuts[word] { return (e, 0) }
        if let e = shortcuts[raw] { return (e, 0) }
        return nil
    }
}
