// InputMode.swift
// Which of VTX's two input sources the user is currently on, and the keyboard layout
// each one composes Telex over.
//
// WHY TWO MODES: KeyboardLayoutOverride lets Telex compose on any pinned ASCII layout,
// but the pinned layout was ONE global setting — switching between QWERTY and Colemak
// meant opening Settings. Two input modes declared in Info.plist's
// ComponentInputModeDict make each one its own TISInputSourceID, so macOS lists them
// separately and ⌃Space cycles between them like any two system input sources. Same
// process, same controller, same engine — only the pinned layout differs.
//
// The mode is delivered by IMKit through setValue(_:forTag:client:) with
// kTextServiceInputModePropertyTag; the controller records it here. There is no API to
// ASK macOS which mode is active, so `current` is only ever as fresh as the last such
// callback — that is fine, because macOS sends it on every mode selection.
//
// MAIN THREAD ONLY. Both writers (setValue, Settings) and the reader (activateServer)
// are main-thread. The value crosses to the tap thread only after
// KeyboardLayoutOverride.apply has stored it behind that type's own lock.

import Foundation

enum InputMode: String {
    /// "VTX Telex" — composes on whatever `keyboardLayoutID` pins (empty = inherit
    /// macOS's layout, the behaviour every build up to 1.6.10 had).
    case telex = "com.vtx.inputmethod.telex.vi"
    /// "VTX Colemak" — composes on `altKeyboardLayoutID`, defaulting to the installed
    /// Colemak DH ANSI. Named for the layout it ships pointed at, but the layout
    /// itself is a Settings picker: pinning Dvorak here must not need a new bundle id
    /// (changing input-mode metadata costs a notarize + logout).
    case altLayout = "com.vtx.inputmethod.telex.vi-colemak"

    /// Tên như nó hiện trong trình đơn input source. Không dịch: đây là tên riêng,
    /// và người dùng đối chiếu nó với cái đang thấy trên menu bar.
    var menuName: String {
        switch self {
        case .telex:     return "VTX Telex"
        case .altLayout: return "VTX Colemak"
        }
    }

    /// The layout id this mode composes on, as KeyboardLayoutOverride.apply wants it.
    ///
    /// Empty means opposite things for the two modes, which is why this is not one
    /// lookup. For `.telex` empty is a real choice — "inherit macOS's layout", the
    /// 1.6.10 behaviour and still the default. For `.altLayout` there is no such
    /// choice to express: a mode that exists to pin a SECOND layout has nothing to do
    /// while unset, so empty there only ever means "the user has not opened Settings
    /// yet" and must resolve to the Colemak the mode is named after. Leaving the
    /// resolution in the Settings model alone shipped a mode that typed QWERTY until
    /// the user visited a window they had no reason to visit (measured 18/08/2026:
    /// `altKeyboardLayoutID` absent from the defaults suite, mode 2 composing on ABC).
    var pinnedLayoutID: String {
        switch self {
        case .telex:
            return AppState.shared.keyboardLayoutID
        case .altLayout:
            let stored = AppState.shared.altKeyboardLayoutID
            return stored.isEmpty ? Self.resolvedDefaultAlt : stored
        }
    }

    /// Resolved ONCE: `defaultAltLayoutID()` walks every installed layout bundle, far
    /// too much for a per-focus-change call. Installing a keyboard layout mid-session
    /// and expecting this to notice is not a case worth a rescan — the Settings picker
    /// resolves fresh, and choosing there writes a real value that skips this entirely.
    private static let resolvedDefaultAlt: String = KeyboardLayoutOverride.defaultAltLayoutID()
}

enum InputModeState {
    /// Defaults to `.telex`: if IMKit ever fails to hand us a mode, behaving as the
    /// mode that existed before this feature is the safe direction to be wrong in.
    ///
    /// Lock-guarded since WordLog reads it: `select` runs on MAIN (IMKit's setValue)
    /// while the TAP thread reads the mode at every word boundary. Every other reader
    /// is main-thread, so this costs a few uncontended ns and nothing else.
    private static let lock = NSLock()
    private static var _current: InputMode = .telex
    static var current: InputMode { lock.withLock { _current } }

    /// Record the mode macOS just switched to and re-pin the layout immediately —
    /// waiting for the next activateServer would leave the very next keystroke
    /// composing on the previous mode's layout.
    ///
    /// The Carbon re-pin happens OUTSIDE the lock: `KeyboardLayoutOverride.apply` does
    /// TIS calls, far too much to hold a lock the tap thread wants per word.
    static func select(_ mode: InputMode) {
        let changed = lock.withLock { () -> Bool in
            guard mode != _current else { return false }
            _current = mode
            return true
        }
        guard changed else { return }
        DebugLog.log("input-mode: \(mode.rawValue) → layout \(mode.pinnedLayoutID.isEmpty ? "(follow)" : mode.pinnedLayoutID)")
        KeyboardLayoutOverride.apply(mode.pinnedLayoutID)
    }

    /// Re-assert the current mode's layout. Called from activateServer, and from
    /// Settings when either picker changes.
    static func reapply() {
        KeyboardLayoutOverride.apply(current.pinnedLayoutID)
    }
}
