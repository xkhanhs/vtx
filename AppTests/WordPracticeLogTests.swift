import XCTest
import CoreGraphics
@testable import VietTelex

final class WordPracticeLogTests: XCTestCase {

    private let ms: UInt64 = 1_000_000

    /// Gõ `keys` cách nhau `gap` ms; "<" là ⌫, " " chốt từ, "|" ngắt (click/mũi tên).
    private func type(_ keys: String, gap: UInt64 = 100, tracker: inout WordTracker,
                      start: UInt64 = 1_000) -> [WordTracker.Finished] {
        var out: [WordTracker.Finished] = []
        var t = start * ms
        for ch in keys {
            let input: WordTracker.Input
            switch ch {
            case "<": input = .backspace
            case " ", ",", ".": input = .separator
            case "|": input = .breakWord
            default: input = .letter(ch)
            }
            out += tracker.handle(input, ns: t)
            t += gap * ms
        }
        return out
    }

    private func words(_ keys: String, gap: UInt64 = 100) -> [WordTracker.Finished] {
        var tracker = WordTracker()
        return type(keys + "|", gap: gap, tracker: &tracker)
    }

    // MARK: - Dựng từ

    func testTelexKeysBecomeTheWordOnScreen() {
        XCTAssertEqual(words("dduwowngf ").map(\.text), ["đường"])
    }

    func testEnglishWordsComeOutAsTyped() {
        XCTAssertEqual(words("merge commit files ").map(\.text), ["merge", "commit", "files"])
    }

    func testUppercaseIsFoldedSoOneWordIsOneRow() {
        XCTAssertEqual(words("Vieetj ").map(\.text), ["việt"])
    }

    func testCleanWordIsTimedFromFirstLetterToTheSeparator() {
        let done = words("mootj ", gap: 100)
        XCTAssertEqual(done.count, 1)
        XCTAssertEqual(done[0].text, "một")
        XCTAssertFalse(done[0].errored)
        XCTAssertEqual(done[0].ms, 500)     // 5 phím chữ → phím cách: 5 khoảng 100 ms
        XCTAssertEqual(done[0].keys, 5)
    }

    func testBackspaceInsideTheWordMarksItWrongAndKeepsWhatWasOnScreen() {
        let done = words("tieeng<<ngs ")
        XCTAssertEqual(done.map(\.text), ["tiếng"])
        XCTAssertTrue(done[0].errored)
        XCTAssertEqual(done[0].mistake, "tiêng")
        XCTAssertNil(done[0].ms, "a corrected word says nothing about speed")
    }

    /// "teh ⌫⌫⌫⌫the " — the user saw the previous word was wrong and went back for it.
    func testBackspacingOverTheSpaceReopensThePreviousWord() {
        let done = words("teh <<<<the ")
        XCTAssertEqual(done.map(\.text), ["the"])
        XCTAssertTrue(done[0].errored)
        XCTAssertEqual(done[0].mistake, "teh")
    }

    func testBackspacingOnlyTheSpaceThenRetypingItIsStillOneWord() {
        let done = words("chaof < ")
        XCTAssertEqual(done.map(\.text), ["chào"])
        XCTAssertTrue(done[0].errored)
    }

    func testAWordDeletedEntirelyDoesNotMarkTheNextOne() {
        let done = words("xyz<<< ok ")
        XCTAssertEqual(done.map(\.text), ["ok"])
        XCTAssertFalse(done[0].errored)
    }

    func testLongPauseInsideAWordIsNotCountedAsSlowTyping() {
        var tracker = WordTracker()
        var out = type("comm", tracker: &tracker)
        out += type("it |", tracker: &tracker, start: 10_000)
        XCTAssertEqual(out.map(\.text), ["commit"])
        XCTAssertNil(out[0].ms)
    }

    func testBreakAbandonsTheWordInProgress() {
        XCTAssertEqual(words("hello|world ").map(\.text), ["world"])
    }

    func testSingleLetterWordsAreSkipped() {
        XCTAssertEqual(words("a b co ").map(\.text), ["co"])
    }

    // MARK: - Phân loại phím

    func testClassify() {
        let letter = WordPracticeLog.classify(keyCode: 0, flags: [], ascii: UInt8(ascii: "a"))
        XCTAssertEqual(letter, .letter("a"))
        XCTAssertEqual(WordPracticeLog.classify(keyCode: 49, flags: [], ascii: UInt8(ascii: " ")), .separator)
        XCTAssertEqual(WordPracticeLog.classify(keyCode: 51, flags: [], ascii: nil), .backspace)
        XCTAssertEqual(WordPracticeLog.classify(keyCode: 51, flags: .maskAlternate, ascii: nil), .breakWord)
        XCTAssertEqual(WordPracticeLog.classify(keyCode: 9, flags: .maskCommand, ascii: UInt8(ascii: "v")), .breakWord)
        XCTAssertEqual(WordPracticeLog.classify(keyCode: 18, flags: [], ascii: UInt8(ascii: "1")), .breakWord)
        XCTAssertEqual(WordPracticeLog.classify(keyCode: 44, flags: .maskShift, ascii: UInt8(ascii: "?")), .separator)
        XCTAssertEqual(WordPracticeLog.classify(keyCode: 123, flags: [], ascii: nil), .breakWord)
    }

    /// Ngoài VTX Colemak không có layout ghim → không có ascii → không chữ nào được ghi.
    func testNothingIsRecordedWithoutAPinnedLayout() {
        var tracker = WordTracker()
        for code: UInt16 in [4, 14, 37, 37, 31, 49] {
            XCTAssertTrue(tracker.handle(WordPracticeLog.classify(keyCode: code, flags: [], ascii: nil),
                                         ns: 0).isEmpty)
        }
    }

    // MARK: - Thống kê và báo cáo

    private func store(_ keys: String, gap: UInt64 = 100) -> WordPracticeLog.Store {
        var store = WordPracticeLog.Store()
        for word in words(keys, gap: gap) { WordPracticeLog.add(word, to: &store) }
        store.days["2026-10-15"] = 1
        return store
    }

    func testStatsAccumulateCountsErrorsAndTypos() {
        let s = store("teh <<<<the the teh <<<<the ")
        let stat = s.words["the"]
        XCTAssertEqual(stat?.count, 3)
        XCTAssertEqual(stat?.errors, 2)
        XCTAssertEqual(stat?.mistakes, ["teh": 2])
        XCTAssertEqual(stat?.timed, 1)
    }

    func testMistakeVariantsAreCapped() {
        var s = WordPracticeLog.Store()
        for i in 0..<10 {
            WordPracticeLog.add(.init(text: "commit", errored: true, mistake: "comm\(i)",
                                      ms: nil, keys: 6), to: &s)
        }
        XCTAssertEqual(s.words["commit"]?.mistakes.count, WordPracticeLog.maxMistakes)
        XCTAssertEqual(s.words["commit"]?.errors, 10)
    }

    func testReportListsErrorsAndAPracticeLine() {
        let s = store("teh <<<<the teh <<<<the merge merge merge ")
        let report = WordPracticeLog.report(s)
        XCTAssertTrue(report.contains("TỪ HAY SAI"), report)
        XCTAssertTrue(report.contains("teh×2"), report)
        XCTAssertTrue(report.contains("TỪ CHẬM"), report)
        XCTAssertTrue(report.contains("DÒNG TẬP"), report)
        XCTAssertEqual(WordPracticeLog.practiceWords(s).first, "the")
    }

    func testEmptyReport() {
        XCTAssertEqual(WordPracticeLog.report(.init()), "Chưa có số liệu.")
    }

    // MARK: - File

    func testFlushWritesAndAFreshLoadReadsItBack() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("word-practice-\(UUID().uuidString).json")
        WordPracticeLog.storeURLOverride = url
        defer {
            WordPracticeLog.shared.reset()
            WordPracticeLog.storeURLOverride = nil
        }
        WordPracticeLog.shared.resetForTestingByReloadingStore()
        WordPracticeLog.shared.recordForTesting(words("merge commit "))
        WordPracticeLog.shared.flush()
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        WordPracticeLog.shared.resetForTestingByReloadingStore()
        let reloaded = WordPracticeLog.shared.snapshot()
        XCTAssertEqual(reloaded.words["merge"]?.count, 1)
        XCTAssertEqual(reloaded.words["commit"]?.count, 1)
        XCTAssertEqual(reloaded.days.values.reduce(0, +), 2)

        WordPracticeLog.shared.reset()
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }
}
