// KeyboardLayoutOverride.swift
// Pins the physical-key → character mapping VietTelex composes on, so Telex types the
// same way no matter which input source the user switched FROM.
//
// THE PROBLEM: an IMKit input method owns no keyboard layout. macOS keeps whichever
// ASCII layout was selected before the switch and translates key events with it, so
// the SAME input method composes on a different keyboard depending on switch history.
// Measured 2026-08-13 with TISCopyCurrentKeyboardLayoutInputSource:
//
//     ABC     → VietTelex   ⇒ current layout = com.apple.keylayout.ABC
//     Colemak → VietTelex   ⇒ current layout = com.apple.keylayout.Colemak
//
// For someone learning Colemak that is not a preference — it is a coin flip decided
// by where they happened to be a moment earlier.
//
// THE FIX: TISSetInputMethodKeyboardLayoutOverride is Apple's mechanism for exactly
// this — the input method declares which ASCII layout it sits on, and macOS performs
// the keycode → character translation with THAT layout before the event ever reaches
// handle(_:client:). Because the OS does the mapping, every downstream path stays
// correct for free: the engine still reads event.characters, pass-through of
// un-composed English still emits the right key, and TerminalTap needs no change.
// Remapping keycodes ourselves would have had to touch all three, including the µs
// hot path.
//
// SCOPE: the call only takes effect from INSIDE the input-method process — the same
// call from a standalone tool returns noErr and changes nothing (verified 2026-08-13).
// Hence it is applied from activateServer, which also re-asserts it on every focus
// change in case macOS drops it across an input-source cycle.
//
// MAIN THREAD ONLY: `resolved` is an unsynchronized cache. Both call sites
// (activateServer, Settings) are main-thread; keep it that way.

import Carbon
import Foundation

/// One ASCII-capable keyboard layout the user can pin VietTelex to.
struct KeyboardLayoutOption: Identifiable, Equatable {
    /// kTISPropertyInputSourceID, e.g. "com.apple.keylayout.Colemak".
    let id: String
    /// Localized display name for the Settings picker, e.g. "Colemak".
    let name: String
}

enum KeyboardLayoutOverride {
    /// Sentinel for "don't override" — inherit whatever layout macOS hands us, which
    /// is the behaviour every build up to 1.5.7 had. Kept as the default so an
    /// upgrade changes nothing for the QWERTY majority.
    static let systemDefault = ""

    /// id → input source, so a focus change doesn't re-scan the ~112 installed
    /// layouts. Never invalidated: layouts are added by installing a system update
    /// or a third-party bundle, neither of which happens without a restart.
    private static var resolved: [String: TISInputSource] = [:]

    /// Last id handed to Carbon, for log dedupe only — never to skip the call. macOS
    /// may reset the override across an input-source cycle, so activateServer must be
    /// free to re-assert the same value.
    private static var lastLogged: String?

    /// Every ASCII-capable keyboard layout INSTALLED on this Mac, not merely the ones
    /// enabled in System Settings: once VietTelex composes on Colemak the user has no
    /// reason to keep Colemak in the input menu, so demanding it be enabled there
    /// would be a step that buys nothing. Sorted by localized name.
    static func installed() -> [KeyboardLayoutOption] {
        let filter = [kTISPropertyInputSourceType as String: kTISTypeKeyboardLayout as String,
                      kTISPropertyInputSourceIsASCIICapable as String: true] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, true)?.takeRetainedValue()
                as? [TISInputSource] else { return [] }
        return list.compactMap { src -> KeyboardLayoutOption? in
            guard let id = property(src, kTISPropertyInputSourceID) else { return nil }
            resolved[id] = src
            return KeyboardLayoutOption(id: id, name: property(src, kTISPropertyLocalizedName) ?? id)
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    /// Compose on `id` from now on. `systemDefault` (empty) leaves macOS's inherited
    /// layout untouched.
    ///
    /// Carbon offers no way to UNSET an override once set, so switching back to
    /// "system default" only stops re-asserting it — it takes effect on the next
    /// launch of the input method. The Settings copy says so rather than pretending
    /// the change is immediate.
    @discardableResult
    static func apply(_ id: String) -> Bool {
        guard id != systemDefault else { lastLogged = nil; return false }
        guard let src = source(for: id) else {
            log(id, "not installed")
            return false
        }
        let err = TISSetInputMethodKeyboardLayoutOverride(src)
        guard err == noErr else {
            log(id, "failed OSStatus=\(err)")
            return false
        }
        log(id, "ok")
        return true
    }

    /// True when `id` names a layout that is still installed. Guards the Settings
    /// picker against a stale preference (layout removed by a system update) showing
    /// an empty selection.
    static func isInstalled(_ id: String) -> Bool {
        id == systemDefault || source(for: id) != nil
    }

    // MARK: - Private

    private static func source(for id: String) -> TISInputSource? {
        if let hit = resolved[id] { return hit }
        let filter = [kTISPropertyInputSourceID as String: id] as CFDictionary
        guard let list = TISCreateInputSourceList(filter, true)?.takeRetainedValue()
                as? [TISInputSource], let src = list.first else { return nil }
        resolved[id] = src
        return src
    }

    private static func property(_ src: TISInputSource, _ key: CFString) -> String? {
        guard let raw = TISGetInputSourceProperty(src, key) else { return nil }
        return Unmanaged<CFString>.fromOpaque(raw).takeUnretainedValue() as String
    }

    /// One line per DISTINCT outcome: activateServer fires on every focus change and
    /// would otherwise flood the 2000-line ring the user pastes into bug reports.
    private static func log(_ id: String, _ outcome: String) {
        let line = "layout-override \(id): \(outcome)"
        guard lastLogged != line else { return }
        lastLogged = line
        DebugLog.log(line)
    }
}
