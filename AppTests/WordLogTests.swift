import XCTest
@testable import VietTelex

// TẠM THỜI — xoá cùng WordLog.swift khi gỡ bộ ghi từ hay gõ.
//
// Corpus là dữ liệu người dùng, nên suite này không được chạm vào file thật:
// `storeURLOverride` trỏ sang một thư mục tạm, và `resetForTesting` nạp state
// trực tiếp thay vì đọc file.
final class WordLogTests: XCTestCase {

    private var tempDir: URL!
    private var wasOn = false

    override func setUp() {
        super.setUp()
        tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("wordlog-\(UUID().uuidString)")
        WordLog.storeURLOverride = tempDir.appendingPathComponent("typing-corpus.json")
        WordLog.shared.resetForTesting()
        wasOn = AppState.shared.logTypedWords
    }

    override func tearDown() {
        AppState.shared.logTypedWords = wasOn
        WordLog.shared.resetForTesting()
        WordLog.storeURLOverride = nil
        WordLog.onMilestone = { DispatchQueue.main.async { WordLogNotifier.postMilestone() } }
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    // MARK: Lọc

    func testNormalizeKeepsVietnameseDiacriticsAndLowercases() {
        XCTAssertEqual(WordLog.normalize("Trường"), "trường")
        XCTAssertEqual(WordLog.normalize("trường"), "trường")
        XCTAssertEqual(WordLog.normalize("HELLO"), "hello")
        // Không bao giờ gộp không-dấu: dấu chính là đầu ra mong muốn.
        XCTAssertNotEqual(WordLog.normalize("Trường"), "truong")
    }

    func testNormalizeRejectsNonWords() {
        XCTAssertNil(WordLog.normalize(""))            // rỗng
        XCTAssertNil(WordLog.normalize("à"))           // quá ngắn
        XCTAssertNil(WordLog.normalize("2026"))        // chữ số
        XCTAssertNil(WordLog.normalize("mp3"))         // lẫn chữ số
        XCTAssertNil(WordLog.normalize("a,b"))         // dấu câu
        XCTAssertNil(WordLog.normalize("don't"))       // dấu nháy
        XCTAssertNil(WordLog.normalize("hai từ"))      // khoảng trắng
        XCTAssertNil(WordLog.normalize("⌘c"))          // chord
        // Dài hơn ngưỡng = từ overflow của engine (mất đồng bộ sau 32 phím).
        XCTAssertNil(WordLog.normalize(String(repeating: "a", count: 33)))
    }

    // MARK: Toggle

    func testNoteIsNoOpWhileToggleOffAndWritesNoFile() {
        AppState.shared.logTypedWords = false
        WordLog.shared.note("trường")
        WordLog.shared.note("người")
        XCTAssertEqual(WordLog.shared.stats().total, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: WordLog.storeURL.path))
    }

    func testNoteCountsWhileToggleOn() {
        AppState.shared.logTypedWords = true
        for _ in 0..<3 { WordLog.shared.note("Trường") }
        WordLog.shared.note("người")
        WordLog.shared.note("2026")          // bị lọc
        let stats = WordLog.shared.stats()   // io.sync — cũng là điểm đồng bộ
        XCTAssertEqual(stats.total, 4)
        XCTAssertEqual(stats.unique, 2)
    }

    // MARK: Mốc mẫu

    func testMilestoneFiresExactlyOnce() {
        AppState.shared.logTypedWords = true
        let fired = Counter()
        WordLog.onMilestone = { fired.bump() }
        WordLog.shared.resetForTesting(words: ["anh": WordLog.sampleTarget - 1],
                                       total: WordLog.sampleTarget - 1)
        WordLog.shared.note("người")                      // chạm mốc
        for _ in 0..<5 { WordLog.shared.note("người") }   // không được lặp
        _ = WordLog.shared.stats()
        XCTAssertEqual(fired.value, 1)
    }

    func testMilestoneFlagSurvivesAReload() throws {
        AppState.shared.logTypedWords = true
        let fired = Counter()
        WordLog.onMilestone = { fired.bump() }
        WordLog.shared.resetForTesting(words: ["anh": WordLog.sampleTarget - 1],
                                       total: WordLog.sampleTarget - 1)
        WordLog.shared.note("người")
        _ = WordLog.shared.stats()                        // ép flush cờ ra file
        XCTAssertEqual(fired.value, 1)

        // Khởi động lại: đọc corpus cũ, cờ đã lưu nên không bắn lại.
        WordLog.shared.resetForTestingByReloadingStore()
        WordLog.shared.note("người")
        _ = WordLog.shared.stats()
        XCTAssertEqual(fired.value, 1)
    }

    /// `nonisolated(unsafe) static var onMilestone` là closure `() -> Void`, nên đếm
    /// phải nằm ngoài struct value semantics.
    private final class Counter {
        private(set) var value = 0
        func bump() { value += 1 }
    }
}
