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

    /// The layout id this mode composes on, as KeyboardLayoutOverride.apply wants it.
    var pinnedLayoutID: String {
        switch self {
        case .telex:     return AppState.shared.keyboardLayoutID
        case .altLayout: return AppState.shared.altKeyboardLayoutID
        }
    }
}

enum InputModeState {
    /// Defaults to `.telex`: if IMKit ever fails to hand us a mode, behaving as the
    /// mode that existed before this feature is the safe direction to be wrong in.
    private(set) static var current: InputMode = .telex

    /// Record the mode macOS just switched to and re-pin the layout immediately —
    /// waiting for the next activateServer would leave the very next keystroke
    /// composing on the previous mode's layout.
    static func select(_ mode: InputMode) {
        guard mode != current else { return }
        current = mode
        DebugLog.log("input-mode: \(mode.rawValue) → layout \(mode.pinnedLayoutID.isEmpty ? "(follow)" : mode.pinnedLayoutID)")
        KeyboardLayoutOverride.apply(mode.pinnedLayoutID)
    }

    /// Re-assert the current mode's layout. Called from activateServer, and from
    /// Settings when either picker changes.
    static func reapply() {
        KeyboardLayoutOverride.apply(current.pinnedLayoutID)
    }
}
