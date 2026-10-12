import XCTest
import CoreGraphics
@testable import VietTelex

final class KeyUsageLogTests: XCTestCase {

    private var storeURL: URL!

    override func setUp() {
        super.setUp()
        storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("key-usage-\(UUID().uuidString).json")
        KeyUsageLog.storeURLOverride = storeURL
        KeyUsageLog.shared.resetForTestingByReloadingStore()
    }

    override func tearDown() {
        KeyUsageLog.shared.reset()
        KeyUsageLog.storeURLOverride = nil
        KeyUsageLog.now = { Date() }
        super.tearDown()
    }

    // MARK: - Nhãn

    func testModifiersComeInAppleOrderBeforeTheKey() {
        XCTAssertEqual(KeyUsageLog.comboLabel(keyCode: 48, flags: .maskCommand, pinned: nil), "⌘Tab")
        XCTAssertEqual(KeyUsageLog.comboLabel(keyCode: 21, flags: [.maskCommand, .maskShift], pinned: nil), "⇧⌘4")
        XCTAssertEqual(KeyUsageLog.comboLabel(keyCode: 51, flags: .maskAlternate, pinned: nil), "⌥⌫")
        XCTAssertEqual(KeyUsageLog.comboLabel(keyCode: 36, flags: [], pinned: nil), "Enter")
    }

    /// Arrow keys carry fn + numericPad on every press; neither may leak into the label.
    func testFnAndCapsLockFlagsAreIgnored() {
        let flags: CGEventFlags = [.maskSecondaryFn, .maskNumericPad, .maskAlphaShift]
        XCTAssertEqual(KeyUsageLog.comboLabel(keyCode: 123, flags: flags, pinned: nil), "←")
    }

    /// DH-Việt puts `;` on the physical P key: the label must name what the user
    /// typed, not the QWERTY legend.
    func testPinnedLayoutCharacterWinsOverTheQwertyLegend() {
        XCTAssertEqual(KeyUsageLog.comboLabel(keyCode: 35, flags: .maskShift, pinned: nil), "⇧P")
        XCTAssertEqual(KeyUsageLog.comboLabel(keyCode: 35, flags: .maskShift,
                                              pinned: UInt8(ascii: ";")), "⇧;")
        // A named key never goes through the layout.
        XCTAssertEqual(KeyUsageLog.comboLabel(keyCode: 49, flags: [], pinned: UInt8(ascii: " ")), "Space")
    }

    func testUnknownKeycodeStillGetsAStableLabel() {
        XCTAssertEqual(KeyUsageLog.comboLabel(keyCode: 105, flags: [], pinned: nil), "key105")
    }

    // MARK: - Nhấn / nhả modifier

    func testPressCountsOnceAndReleaseDoesNot() {
        var tracker = KeyUsageLog.ModifierPressTracker()
        XCTAssertTrue(tracker.isPress(keyCode: 56, flags: .maskShift))
        XCTAssertFalse(tracker.isPress(keyCode: 56, flags: []))
        XCTAssertTrue(tracker.isPress(keyCode: 56, flags: .maskShift))
    }

    /// Both shifts held, left released first: the shift flag stays set, so only the
    /// keycode tells that event apart from a press.
    func testReleasingOneSideWhileTheOtherIsHeldIsNotAPress() {
        var tracker = KeyUsageLog.ModifierPressTracker()
        XCTAssertTrue(tracker.isPress(keyCode: 56, flags: .maskShift))
        XCTAssertTrue(tracker.isPress(keyCode: 60, flags: .maskShift))
        XCTAssertFalse(tracker.isPress(keyCode: 56, flags: .maskShift))
        XCTAssertFalse(tracker.isPress(keyCode: 60, flags: []))
        XCTAssertTrue(tracker.isPress(keyCode: 60, flags: .maskShift))
    }

    func testOtherModifiersHeldDoNotConfuseTheTracker() {
        var tracker = KeyUsageLog.ModifierPressTracker()
        XCTAssertTrue(tracker.isPress(keyCode: 55, flags: .maskCommand))
        XCTAssertTrue(tracker.isPress(keyCode: 56, flags: [.maskCommand, .maskShift]))
        XCTAssertFalse(tracker.isPress(keyCode: 56, flags: .maskCommand))
        XCTAssertFalse(tracker.isPress(keyCode: 55, flags: []))
    }

    func testNonModifierKeycodeIsNeverAPress() {
        var tracker = KeyUsageLog.ModifierPressTracker()
        XCTAssertFalse(tracker.isPress(keyCode: 0, flags: .maskShift))
        XCTAssertNil(KeyUsageLog.modifierLabel(keyCode: 0))
    }

    // MARK: - Tổng hợp

    func testSummarySplitsShortcutsKeysAndLetters() {
        let days: [String: KeyUsageLog.Day] = [
            "2026-10-12": .init(combos: ["⌘Tab": 5, "⇧;": 2, "Enter": 4, "A": 10, "⇧A": 1, "⌃C": 1],
                                modifiers: ["⇧ trái": 3]),
            "2026-10-13": .init(combos: ["⌘Tab": 3, "⇧⌘4": 1, "7": 2], modifiers: ["⇧ trái": 1, "⌘ trái": 9]),
        ]
        let summary = KeyUsageLog.summarize(days)
        XCTAssertEqual(summary.dayCount, 2)
        XCTAssertEqual(summary.firstDay, "2026-10-12")
        XCTAssertEqual(summary.lastDay, "2026-10-13")
        XCTAssertEqual(summary.total, 29)
        XCTAssertEqual(summary.shortcuts, [.init(label: "⌘Tab", count: 8),
                                           .init(label: "⇧⌘4", count: 1),
                                           .init(label: "⌃C", count: 1)])
        XCTAssertEqual(summary.keys, [.init(label: "Enter", count: 4),
                                      .init(label: "7", count: 2),
                                      .init(label: "⇧;", count: 2)])
        XCTAssertEqual(summary.modifiers, [.init(label: "⌘ trái", count: 9),
                                           .init(label: "⇧ trái", count: 4)])
        XCTAssertEqual(summary.letters, 11)
        XCTAssertEqual(summary.shiftedLetters, 1)
    }

    func testShiftedSymbolIsAnnotatedWithWhatItTypes() {
        XCTAssertEqual(KeyUsageLog.annotated("⇧/"), "⇧/ (?)")
        XCTAssertEqual(KeyUsageLog.annotated("⇧;"), "⇧; (:)")
        XCTAssertEqual(KeyUsageLog.annotated("⇧A"), "⇧A")
        XCTAssertEqual(KeyUsageLog.annotated("⌘/"), "⌘/")
        XCTAssertEqual(KeyUsageLog.annotated("Enter"), "Enter")
    }

    func testReportOnEmptyDataSaysSo() {
        XCTAssertEqual(KeyUsageLog.report([:]), "Chưa có số liệu.")
    }

    // MARK: - Lưu trữ

    func testCountsBucketByDayAndSurviveARestart() {
        var clock = DateComponents(calendar: .current, year: 2026, month: 10, day: 12, hour: 23).date!
        KeyUsageLog.now = { clock }
        KeyUsageLog.shared.noteModifierPress(keyCode: 56)
        KeyUsageLog.shared.noteModifierPress(keyCode: 56)
        // The day is read on the store's own queue: drain it before moving the clock.
        _ = KeyUsageLog.shared.snapshot()
        clock = clock.addingTimeInterval(2 * 3600)
        KeyUsageLog.shared.noteModifierPress(keyCode: 54)

        let live = KeyUsageLog.shared.snapshot()
        XCTAssertEqual(live["2026-10-12"]?.modifiers, ["⇧ trái": 2])
        XCTAssertEqual(live["2026-10-13"]?.modifiers, ["⌘ phải": 1])

        KeyUsageLog.shared.flush()
        KeyUsageLog.shared.resetForTestingByReloadingStore()
        XCTAssertEqual(KeyUsageLog.shared.snapshot(), live)
    }

    func testResetClearsMemoryAndFile() {
        KeyUsageLog.shared.noteModifierPress(keyCode: 56)
        KeyUsageLog.shared.flush()
        XCTAssertTrue(FileManager.default.fileExists(atPath: storeURL.path))
        KeyUsageLog.shared.reset()
        XCTAssertFalse(FileManager.default.fileExists(atPath: storeURL.path))
        XCTAssertTrue(KeyUsageLog.shared.snapshot().isEmpty)
    }
}
