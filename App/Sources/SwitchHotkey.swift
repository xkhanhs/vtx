// SwitchHotkey.swift
// Phím tắt CHỈ-GỒM-MODIFIER (⌃⇧ / ⌥⇧ / ⌘⇧) để chuyển VietTelex ↔ input source
// trước đó — thứ Keyboard Shortcuts của macOS không cho gán (bắt buộc kèm một
// phím thường; field request issue #54, 15/08/2026). EXPERIMENTAL, default OFF.
//
// Vì sao làm được: CGEventTap của mình là tap TOÀN PHIÊN — thấy mọi phím kể cả
// khi VietTelex không phải source đang chọn, nên hotkey sống cả hai chiều.
// Chuyển source qua TISSelectInputSource (cùng máy móc SecureInputMonitor/
// StickyInputSource đã dùng). Cần quyền Trợ năng: không có tap = hotkey chết im
// (UI có ghi chú).
//
// Nhận diện "chord sạch": nhấn ĐÚNG bộ modifier → thả ra, KHÔNG gõ phím thường
// và không click chuột ở giữa. Điều kiện đó tránh ăn nhầm khi user giữ ⌃⇧ để
// chọn text hay bấm shortcut khác:
//   ⌃⇧ rồi thả          → chuyển
//   ⌃⇧ + C              → keyDown disarm, không chuyển (đó là một shortcut)
//   ⌃⇧ thêm ⌘ rồi thả   → thành chord khác, disarm, không chuyển
//   ⌃⇧ + click          → mouse disarm, không chuyển

import AppKit
import Carbon.HIToolbox

/// Máy trạng thái thuần, TAP-THREAD confined (không lock — mọi note đến từ đúng
/// một thread của tap). armed khi mask hiện tại == target; fire khi từ armed nhả
/// XUỐNG (subset thật sự của target); mọi thứ khác disarm.
struct ModifierChordRecognizer {
    private var armed = false
    /// Bốn modifier tham gia so khớp — các bit device-dependent/caps-lock bị lọc.
    static let relevant: CGEventFlags = [.maskControl, .maskShift, .maskAlternate, .maskCommand]

    /// Gọi cho mỗi flagsChanged. Trả về true đúng một lần khi chord hoàn tất.
    mutating func note(flags: CGEventFlags, target: CGEventFlags) -> Bool {
        let held = flags.intersection(Self.relevant)
        if held == target { armed = true; return false }
        defer { armed = false }
        // Nhả bớt (held ⊂ target, kể cả nhả sạch) từ trạng thái armed = chord xong.
        // Thêm modifier khác (held ⊄ target) = đổi ý sang chord khác → chỉ disarm.
        return armed && held.subtracting(target).isEmpty
    }

    /// Bất kỳ phím thường / click chuột nào giữa lúc giữ chord → không phải toggle.
    mutating func disarm() { armed = false }
}

enum SwitchHotkey {
    /// Giá trị lưu trong settings → bộ modifier tương ứng. nil = tắt (default) hoặc
    /// giá trị rác từ bản cũ/settings hỏng — coi như tắt, không crash.
    static func targetFlags(for choice: String) -> CGEventFlags? {
        switch choice {
        case "ctrl-shift": return [.maskControl, .maskShift]
        case "opt-shift":  return [.maskAlternate, .maskShift]
        case "cmd-shift":  return [.maskCommand, .maskShift]
        default:           return nil
        }
    }

    /// Source non-VietTelex gần nhất (đích của chiều VietTelex → khác). MAIN-thread
    /// confined: ghi từ observer TIS trong main.swift, đọc từ toggle() (cũng main).
    private(set) static var lastOtherSourceID: String?

    /// Gọi từ observer kTISNotifySelectedKeyboardInputSourceChanged (main thread).
    static func noteSelection(isVietTelex: Bool, currentID: String?) {
        if !isVietTelex, let currentID { lastOtherSourceID = currentID }
    }

    /// ABC làm đích dự phòng khi chưa từng thấy source khác (máy chỉ dùng VietTelex
    /// từ lúc login): input source phổ quát nhất, có mặt trên mọi máy.
    static let fallbackOtherID = "com.apple.keylayout.ABC"

    /// MAIN thread only (TIS không an toàn ngoài main — ràng buộc đã ghi ở self-heal
    /// của tap). Đổi chiều theo trạng thái hiện tại.
    static func toggle() {
        // Hotkey modifier-only KHÔNG có keyDown nào nên StickyInputSource sẽ không
        // thấy "gesture chủ động" và giành ngược lại ngay sau khi mình chuyển —
        // stamp thủ công trước khi đổi source.
        StickyInputSource.shared.noteUserModifierChord()
        let ok: Bool
        let direction: String
        if TelexInputController.isVietTelexSelected() {
            let dest = lastOtherSourceID ?? fallbackOtherID
            ok = selectInputSource(id: dest)
            direction = "→ \(dest)"
        } else {
            ok = SecureInputMonitor.reselectVietTelex()
            direction = "→ VietTelex"
        }
        DebugLog.log("switch-hotkey: toggle \(direction) \(ok ? "ok" : "FAILED")")
        if !ok {
            Signposts.log.notice("switch-hotkey toggle FAILED \(direction, privacy: .public)")
        }
    }

    // MARK: - ⌃1…⌃4: chọn THẲNG một input source

    /// ⌃+số → input source cố định (30/09/2026). ⌃Space đi qua HUD của
    /// TextInputSwitcher: giữ lâu một chút là HUD hiện và lựa chọn chỉ chốt khi nhả ⌃,
    /// nên thỉnh thoảng không chuyển. Chọn thẳng thì không có vòng xoay, không HUD,
    /// không phụ thuộc source nào đang đứng trước. Keycode VẬT LÝ hàng số (ANSI), nên
    /// đúng phím dù đang ở layout nào.
    static let directSources: [Int64: String] = [
        Int64(kVK_ANSI_1): "com.apple.keylayout.ABC",
        Int64(kVK_ANSI_2): "com.vtx.keyboardlayout.colemakdhviet.keylayout.ColemakDH-Viet",
        Int64(kVK_ANSI_3): "com.vtx.inputmethod.telex.vi",
        Int64(kVK_ANSI_4): "com.vtx.inputmethod.telex.vi-colemak",
    ]

    /// TAP THREAD, thuần: keyDown này có phải ⌃+số của bảng trên không. Chỉ ĐÚNG ⌃ —
    /// ⌃⇧2, ⌃⌥2, ⌘⌃2 là shortcut khác, để app nhận.
    static func directSourceID(keycode: Int64, flags: CGEventFlags) -> String? {
        guard flags.intersection(ModifierChordRecognizer.relevant) == .maskControl
        else { return nil }
        return directSources[keycode]
    }

    /// MAIN thread only. Source không enabled (user đã gỡ) → FAILED trong log, không
    /// tự bật lại.
    static func selectDirect(id: String) {
        // keyDown ⌃+số đã bị tap nuốt trước chỗ stamp chord thường — stamp ở đây để
        // StickyInputSource không giành ngược lại ngay sau khi mình chuyển.
        StickyInputSource.shared.noteUserModifierChord()
        let ok = selectInputSource(id: id)
        DebugLog.log("switch-hotkey: direct → \(id) \(ok ? "ok" : "FAILED")")
        if !ok {
            Signposts.log.notice("switch-hotkey direct FAILED \(id, privacy: .public)")
        }
    }

    /// Chọn input source theo đúng kTISPropertyInputSourceID. Chỉ nguồn đang enabled
    /// (danh sách mặc định của TISCreateInputSourceList) — không tự bật nguồn user đã gỡ.
    static func selectInputSource(id: String) -> Bool {
        guard let list = TISCreateInputSourceList(nil, false)?
            .takeRetainedValue() as? [TISInputSource] else { return false }
        for source in list {
            guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceID)
            else { continue }
            if Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String == id {
                return TISSelectInputSource(source) == noErr
            }
        }
        return false
    }

    /// ID của source đang chọn — cho observer trong main.swift ghi lastOtherSourceID.
    static func currentInputSourceID() -> String? {
        guard let src = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue(),
              let ptr = TISGetInputSourceProperty(src, kTISPropertyInputSourceID) else { return nil }
        return Unmanaged<CFString>.fromOpaque(ptr).takeUnretainedValue() as String
    }
}
