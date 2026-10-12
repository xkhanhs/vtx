import XCTest
@testable import VietTelex

final class LayerHUDTests: XCTestCase {

    private var storeURL: URL!

    override func setUp() {
        super.setUp()
        storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("layer-hud-\(UUID().uuidString).json")
        LayerHUDLayout.storeURLOverride = storeURL
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: storeURL)
        LayerHUDLayout.storeURLOverride = nil
        super.tearDown()
    }

    func testBuiltInLayoutHasTheShapeTheViewIndexes() {
        XCTAssertTrue(LayerHUDLayout.seed.isWellFormed)
    }

    /// First run: there is nothing to edit until the file exists, so loading seeds it.
    func testFirstLoadWritesTheBuiltInLayoutToTheFile() throws {
        XCTAssertEqual(LayerHUDLayout.load(), .seed)
        let written = try JSONDecoder().decode(LayerHUDLayout.self, from: Data(contentsOf: storeURL))
        XCTAssertEqual(written, .seed)
    }

    func testEditedFileWinsOverTheBuiltInLayout() throws {
        var edited = LayerHUDLayout.seed
        edited.layers[0].rows[0][0] = "`"
        try JSONEncoder().encode(edited).write(to: storeURL)
        XCTAssertEqual(LayerHUDLayout.load(), edited)
    }

    /// A hand edit that drops a cell must not reach the view (it indexes by position),
    /// and must not be overwritten either — the user's other edits are still in there.
    func testMalformedFileFallsBackWithoutBeingOverwritten() throws {
        var broken = LayerHUDLayout.seed
        broken.layers[0].rows[1].removeLast()
        XCTAssertFalse(broken.isWellFormed)
        let data = try JSONEncoder().encode(broken)
        try data.write(to: storeURL)
        XCTAssertEqual(LayerHUDLayout.load(), .seed)
        XCTAssertEqual(try Data(contentsOf: storeURL), data)

        try Data("not json".utf8).write(to: storeURL)
        XCTAssertEqual(LayerHUDLayout.load(), .seed)
        XCTAssertEqual(try Data(contentsOf: storeURL), Data("not json".utf8))
    }

    func testEmptyLayerListIsMalformed() {
        XCTAssertFalse(LayerHUDLayout(layers: []).isWellFormed)
    }

    func testPanelSitsInTheBottomRightOfTheUsableArea() {
        // Dock 70pt high at the bottom, menu bar above: visibleFrame excludes both.
        let visible = CGRect(x: 0, y: 70, width: 1440, height: 805)
        let origin = LayerHUDController.origin(for: CGSize(width: 400, height: 250), in: visible)
        XCTAssertEqual(origin, CGPoint(x: 1024, y: 86))
    }

    func testDraggedPositionIsKeptWhileItStillFitsAScreen() {
        let main = CGRect(x: 0, y: 0, width: 1440, height: 900)
        let external = CGRect(x: 1440, y: 0, width: 1920, height: 1080)
        let size = CGSize(width: 400, height: 250)
        let dragged = CGPoint(x: 1600, y: 500)
        XCTAssertEqual(LayerHUDController.origin(saved: dragged, size: size,
                                                 screens: [main, external], main: main), dragged)
        // External display unplugged: the saved spot is off every screen → default corner.
        XCTAssertEqual(LayerHUDController.origin(saved: dragged, size: size, screens: [main], main: main),
                       LayerHUDController.origin(for: size, in: main))
        XCTAssertEqual(LayerHUDController.origin(saved: nil, size: size, screens: [main], main: main),
                       LayerHUDController.origin(for: size, in: main))
    }
}
