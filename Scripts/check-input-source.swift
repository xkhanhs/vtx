#!/usr/bin/env swift
// Is VTX actually enabled / selected as an input source? Asks Text Input Sources (TIS),
// the same source of truth the menu bar and the ⌃Space HUD use.
//
//   swift Scripts/check-input-source.swift
//
// Do NOT answer this question with `defaults read com.apple.HIToolbox
// AppleEnabledInputSources`: on macOS 26 that key goes stale. On 2026-09-12 and
// 2026-09-13 it listed no VTX while VTX was in the menu bar and TIS reported both modes
// enabled — two "VTX dropped out" incidents were written up from it and neither
// happened. See docs/MACOS_IME_NOTES.md.
//
// Exit 0 when both VTX modes are enabled, 1 otherwise.

import Carbon
import Foundation

let modes = ["com.vtx.inputmethod.telex.vi", "com.vtx.inputmethod.telex.vi-colemak"]

func string(_ source: TISInputSource, _ key: CFString) -> String {
    guard let p = TISGetInputSourceProperty(source, key) else { return "nil" }
    return Unmanaged<CFString>.fromOpaque(p).takeUnretainedValue() as String
}

func flag(_ source: TISInputSource, _ key: CFString) -> Bool {
    guard let p = TISGetInputSourceProperty(source, key) else { return false }
    return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(p).takeUnretainedValue())
}

let filter = [kTISPropertyBundleID as String: "com.vtx.inputmethod.telex"] as CFDictionary
let installed = TISCreateInputSourceList(filter, true).takeRetainedValue() as NSArray

var enabled = Set<String>()
for item in installed {
    let source = item as! TISInputSource
    let id = string(source, kTISPropertyInputSourceID)
    guard modes.contains(id) else { continue }
    let isEnabled = flag(source, kTISPropertyInputSourceIsEnabled)
    let isSelected = flag(source, kTISPropertyInputSourceIsSelected)
    if isEnabled { enabled.insert(id) }
    print("\(id)  enabled=\(isEnabled ? "Y" : "N")  selected=\(isSelected ? "Y" : "N")")
}

let missing = modes.filter { !enabled.contains($0) }
if installed.count == 0 {
    print("VTX is not installed/registered as an input source.")
    exit(1)
}
if !missing.isEmpty {
    print("NOT enabled: \(missing.joined(separator: ", "))")
    exit(1)
}
print("OK: both VTX modes are enabled.")
