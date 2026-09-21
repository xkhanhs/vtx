import XCTest
@testable import TelexCore

// Gõ tắt có tiền tố "/shop": tiền tố chỉ tính khi dấu câu đứng NGAY TRƯỚC chữ đầu
// của từ, và khớp khoá có tiền tố thì xoá lùi thêm đúng một ký tự.
final class ShortcutPrefixTests: XCTestCase {

    private let table = ["/shop": "https://shop", "shop": "cửa hàng", "vn": "Việt Nam",
                         ";sig": "chữ ký", "/ddc": "được"]

    /// Mô phỏng chuỗi phím như controller xử lý: dấu câu là ranh giới, chữ là từ.
    private func prefixOfWord(after keys: String) -> Character? {
        var p = ShortcutPrefix()
        var inWord = false
        for ch in keys {
            let taken = p.takePending()
            if ch.isLetter {
                if !inWord { p.startWord(taken); inWord = true }
            } else {
                inWord = false
                p.boundaryKey(ch)
            }
        }
        return p.current
    }

    func testSlashImmediatelyBeforeWordIsPrefix() {
        XCTAssertEqual(prefixOfWord(after: "/shop"), "/")
        XCTAssertEqual(prefixOfWord(after: "abc/shop"), "/")
        XCTAssertEqual(prefixOfWord(after: ";sig"), ";")
    }

    func testSpaceOrNothingIsNotPrefix() {
        XCTAssertNil(prefixOfWord(after: "shop"))
        XCTAssertNil(prefixOfWord(after: "/ shop"))
    }

    func testAnyKeyBetweenPrefixAndWordClearsIt() {
        var p = ShortcutPrefix()
        _ = p.takePending(); p.boundaryKey("/")
        _ = p.takePending()                 // ⌫ / mũi tên / ⌘-phím xen giữa
        p.startWord(p.takePending())
        XCTAssertNil(p.current)
    }

    func testResetClearsPendingPrefix() {
        var p = ShortcutPrefix()
        p.boundaryKey("/")
        p.reset()                           // click chuột
        p.startWord(p.takePending())
        XCTAssertNil(p.current)
    }

    func testPrefixedKeyWinsAndDeletesTheSlash() {
        let hit = ShortcutPrefix.lookup(word: "shop", raw: "shop", prefix: "/", in: table)
        XCTAssertEqual(hit?.expansion, "https://shop")
        XCTAssertEqual(hit?.extraBackspaces, 1)
    }

    func testPlainWordStillExpandsWithoutPrefix() {
        let hit = ShortcutPrefix.lookup(word: "shop", raw: "shop", prefix: nil, in: table)
        XCTAssertEqual(hit?.expansion, "cửa hàng")
        XCTAssertEqual(hit?.extraBackspaces, 0)
    }

    func testPrefixFallsBackToPlainKey() {
        // "/vn" không có trong bảng nhưng "vn" có: vẫn bung như cũ, KHÔNG xoá dấu "/".
        let hit = ShortcutPrefix.lookup(word: "vn", raw: "vn", prefix: "/", in: table)
        XCTAssertEqual(hit?.expansion, "Việt Nam")
        XCTAssertEqual(hit?.extraBackspaces, 0)
    }

    func testPrefixedRawKeystrokesMatch() {
        // "ddc" ghép thành "đc" — khoá viết bằng phím thô vẫn phải khớp.
        let hit = ShortcutPrefix.lookup(word: "đc", raw: "ddc", prefix: "/", in: table)
        XCTAssertEqual(hit?.expansion, "được")
        XCTAssertEqual(hit?.extraBackspaces, 1)
    }

    func testNoMatch() {
        XCTAssertNil(ShortcutPrefix.lookup(word: "abc", raw: "abc", prefix: "/", in: table))
    }

    // MARK: VTX #87 — khoá trần không nở sau ký tự mở token, khoá có tiền tố thì có

    func testBareKeyBlockedAfterTokenOpenerButPrefixedKeyStillExpands() {
        // "/h3" kiểu Lark: "h" có trong bảng nhưng đây là slash command, không được nở.
        XCTAssertNil(ShortcutPrefix.lookup(word: "vn", raw: "vn", prefix: "/",
                                           bareAllowed: false, in: table))
        // Nhưng khoá người dùng đăng ký hẳn có dấu "/" thì dấu đó LÀ khoá — vẫn nở,
        // và vẫn xoá luôn dấu "/" trên màn hình. Đây là đường gõ tắt chính của fork.
        let hit = ShortcutPrefix.lookup(word: "shop", raw: "shop", prefix: "/",
                                        bareAllowed: false, in: table)
        XCTAssertEqual(hit?.expansion, table["/shop"])
        XCTAssertEqual(hit?.extraBackspaces, 1)
        // Không có tiền tố (ví dụ "5h"): chặn sạch.
        XCTAssertNil(ShortcutPrefix.lookup(word: "vn", raw: "vn", prefix: nil,
                                           bareAllowed: false, in: table))
    }

    func testCandidates() {
        XCTAssertTrue(ShortcutPrefix.isCandidate("/"))
        XCTAssertTrue(ShortcutPrefix.isCandidate(";"))
        XCTAssertFalse(ShortcutPrefix.isCandidate(" "))
        XCTAssertFalse(ShortcutPrefix.isCandidate("1"))
        XCTAssertFalse(ShortcutPrefix.isCandidate("\n"))
    }
}
