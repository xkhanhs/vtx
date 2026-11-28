import XCTest
@testable import VietTelex

// ⌥ phải trên AULA + mũi tên/End thành phím media. Sai một ca là hoặc ⌥←/⌥→ (nhảy từ)
// trên MacBook bị nuốt, hoặc một chord ⌥⇧/⌘⌥ thật thành chỉnh âm lượng.
final class MediaKeyChordTests: XCTestCase {

    /// ⌥ phải: maskAlternate + bit thiết bị 0x40.
    private let rightOption = CGEventFlags(rawValue: CGEventFlags.maskAlternate.rawValue | 0x40)
    /// ⌥ trái: maskAlternate + bit thiết bị 0x20.
    private let leftOption = CGEventFlags(rawValue: CGEventFlags.maskAlternate.rawValue | 0x20)

    private func key(_ code: Int64, _ flags: CGEventFlags, onTarget: Bool = true) -> MediaKeyChord.Key? {
        MediaKeyChord.key(keycode: code, flags: flags, rightOptionOnTarget: onTarget)
    }

    func testMapping() {
        XCTAssertEqual(key(126, rightOption), .volumeUp)
        XCTAssertEqual(key(125, rightOption), .volumeDown)
        XCTAssertEqual(key(123, rightOption), .brightnessDown)
        XCTAssertEqual(key(124, rightOption), .brightnessUp)
        XCTAssertEqual(key(119, rightOption), .mute)
        XCTAssertNil(key(0, rightOption))   // phím chữ: không đụng
    }

    func testArrowFlagsDoNotBreakTheMatch() {
        // Mũi tên luôn mang cờ Fn + numpad từ hệ thống.
        let arrow = rightOption.union([.maskSecondaryFn, .maskNumericPad])
        XCTAssertEqual(key(126, arrow), .volumeUp)
    }

    func testOnlyRightOptionOnTheTargetKeyboard() {
        XCTAssertNil(key(126, leftOption))                       // ⌥ trái = nhảy từ
        XCTAssertNil(key(126, rightOption, onTarget: false))     // MacBook, Klor/Corne
        XCTAssertNil(key(126, []))
    }

    func testOtherModifiersCancel() {
        XCTAssertNil(key(123, rightOption.union(.maskShift)))    // ⌥⇧← = chọn theo từ
        XCTAssertNil(key(123, rightOption.union(.maskCommand)))
        XCTAssertNil(key(123, rightOption.union(.maskControl)))
    }

    func testOnlyMuteSkipsAutorepeat() {
        XCTAssertTrue(MediaKeyChord.Key.volumeUp.repeats)
        XCTAssertTrue(MediaKeyChord.Key.brightnessDown.repeats)
        XCTAssertFalse(MediaKeyChord.Key.mute.repeats)
    }
}
