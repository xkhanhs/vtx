import XCTest
@testable import VietTelex

// KeyboardLayoutOverride's discoverable surface: which layouts we offer, and whether
// a saved preference still resolves.
//
// `apply` is deliberately NOT asserted on. TISSetInputMethodKeyboardLayoutOverride is
// scoped to the calling input-method process: from a test host it returns noErr and
// changes nothing (verified 2026-08-13 against TISCopyInputMethodKeyboardLayoutOverride,
// which kept reporting "(none)"). A test asserting it "worked" would pass for the
// wrong reason and keep passing if the call were deleted, so the effect is verified
// by hand in a real install instead — see docs/BUILD.md.
final class KeyboardLayoutOverrideTests: XCTestCase {

    private let s = AppState.shared
    private var savedLayout = ""

    override func setUp() {
        super.setUp()
        savedLayout = s.keyboardLayoutID
    }

    override func tearDown() {
        s.keyboardLayoutID = savedLayout
        super.tearDown()
    }

    /// Every Mac ships ABC and Colemak, so an empty or ABC-less list means the TIS
    /// filter regressed (wrong type constant, or ASCII-capable dropped).
    func testInstalledListsStockAsciiLayouts() {
        let ids = Set(KeyboardLayoutOverride.installed().map(\.id))
        XCTAssertTrue(ids.contains("com.apple.keylayout.ABC"))
        XCTAssertTrue(ids.contains("com.apple.keylayout.Colemak"))
    }

    /// Non-ASCII layouts can't carry Telex — a Telex key must map to a bare Latin
    /// letter — so they must never reach the picker.
    func testInstalledExcludesNonAsciiLayouts() {
        let ids = Set(KeyboardLayoutOverride.installed().map(\.id))
        XCTAssertFalse(ids.contains("com.apple.keylayout.Thai"))
        XCTAssertFalse(ids.contains("com.apple.keylayout.Hebrew"))
    }

    /// The picker shows names, so a layout with no name would render as a blank row.
    func testEveryOptionHasANonEmptyName() {
        for option in KeyboardLayoutOverride.installed() {
            XCTAssertFalse(option.name.isEmpty, "no display name for \(option.id)")
        }
    }

    /// Guards the Settings fallback: a preference naming a layout that has since been
    /// uninstalled must report false so the picker can drop back to "follow".
    func testIsInstalledDistinguishesRealFromStaleIDs() {
        XCTAssertTrue(KeyboardLayoutOverride.isInstalled(KeyboardLayoutOverride.systemDefault))
        XCTAssertTrue(KeyboardLayoutOverride.isInstalled("com.apple.keylayout.Colemak"))
        XCTAssertFalse(KeyboardLayoutOverride.isInstalled("com.apple.keylayout.NoSuchLayout"))
    }

    /// Applying the "follow the previous input source" sentinel must be a no-op, not
    /// a failed lookup of a layout literally named "".
    func testApplyingSystemDefaultDoesNothing() {
        XCTAssertFalse(KeyboardLayoutOverride.apply(KeyboardLayoutOverride.systemDefault))
    }

    /// A chosen layout survives a settings round trip, and clearing it returns to
    /// "follow" — the value an upgrade from 1.5.7 starts on, so the QWERTY majority
    /// sees no behaviour change.
    func testPreferenceRoundTrips() {
        s.keyboardLayoutID = "com.apple.keylayout.Colemak"
        XCTAssertEqual(s.keyboardLayoutID, "com.apple.keylayout.Colemak")
        XCTAssertEqual(s.defaults.string(forKey: "keyboardLayoutID"),
                       "com.apple.keylayout.Colemak")

        s.keyboardLayoutID = KeyboardLayoutOverride.systemDefault
        XCTAssertEqual(s.keyboardLayoutID, KeyboardLayoutOverride.systemDefault)
    }

    /// A stale saved layout must not leave the Picker with an unmatched tag (SwiftUI
    /// renders that as an empty control).
    func testSettingsModelFallsBackWhenSavedLayoutIsGone() {
        s.keyboardLayoutID = "com.apple.keylayout.NoSuchLayout"
        let model = SettingsModel(selected: .general)
        XCTAssertEqual(model.keyboardLayoutID, KeyboardLayoutOverride.systemDefault)
    }
}
