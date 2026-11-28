import Cocoa
import IOKit.hid

// Giữ ⌥ phải trên bàn phím AULA + ↑↓ = âm lượng, ←→ = độ sáng, End = tắt tiếng
// (28/11/2026). Trước đây là rule Karabiner; AULA dùng firmware đóng nên không đổi
// được ở bàn phím, và Fn của nó không bao giờ tới máy — ⌥ phải là phím giữ còn lại.
//
// Chỉ AULA: ở MacBook và Klor/Corne, ⌥ phải + mũi tên vẫn là nhảy từ như cũ. CGEvent
// không mang danh tính thiết bị, nên phần "phím ⌥ phải này đến từ AULA" đọc từ IOHID
// (cùng nguồn Karabiner dùng), chỉ QUAN SÁT, không seize. Mũi tên tới sau ⌥ cả chục
// mili-giây nên không có race giữa callback IOHID và tap.
enum MediaKeyChord {
    /// NX_KEYTYPE_* trong IOKit/hidsystem/ev_keymap.h.
    enum Key: Int {
        case volumeUp = 0, volumeDown = 1, brightnessUp = 2, brightnessDown = 3, mute = 7

        /// Giữ phím thì lặp (âm lượng, độ sáng); tắt tiếng thì chỉ lần nhấn đầu.
        var repeats: Bool { self != .mute }
    }

    /// NX_DEVICERALTKEYMASK: bit "⌥ PHẢI đang giữ" trong flags phụ thuộc thiết bị.
    static let rightOptionMask: UInt64 = 0x40

    static let keys: [Int64: Key] = [
        126: .volumeUp,         // ↑
        125: .volumeDown,       // ↓
        123: .brightnessDown,   // ←
        124: .brightnessUp,     // →
        119: .mute,             // End
    ]

    /// Hàm thuần cho tap-thread. `rightOptionOnTarget`: ⌥ phải đang được giữ trên một
    /// bàn phím trong `HIDRightOptionWatcher.targets`.
    static func key(keycode: Int64, flags: CGEventFlags, rightOptionOnTarget: Bool) -> Key? {
        guard rightOptionOnTarget,
              flags.intersection(ModifierChordRecognizer.relevant) == .maskAlternate,
              flags.rawValue & rightOptionMask != 0
        else { return nil }
        return keys[keycode]
    }

    /// Gửi phím media như phím thật trên hàng F. Flags của sự kiện để trống: có ⌥ thì
    /// macOS mở Cài đặt Âm thanh/Màn hình thay vì chỉnh.
    static func post(_ key: Key) {
        for down in [true, false] {
            let state = down ? 0xA : 0xB
            let event = NSEvent.otherEvent(
                with: .systemDefined, location: .zero,
                modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(state << 8)),
                timestamp: 0, windowNumber: 0, context: nil,
                subtype: 8, data1: (key.rawValue << 16) | (state << 8), data2: -1)
            event?.cgEvent?.post(tap: .cghidEventTap)
        }
    }
}

/// Theo dõi phím ⌥ phải (HID usage 0x07/0xE6) trên các bàn phím đích qua IOHIDManager.
/// Callback chạy trên main; tap-thread đọc `isHeld` — cả hai qua `lock`.
final class HIDRightOptionWatcher {
    static let shared = HIDRightOptionWatcher()

    /// AULA (vendor 0x3554): đầu thu 2.4G 0xfa09, Bluetooth 0xfa07. Đầu thu chuột VXE
    /// cùng vendor (0xf58e) không có trong danh sách.
    static let targets: [(vendor: Int, product: Int)] = [(0x3554, 0xfa09), (0x3554, 0xfa07)]

    private let lock = NSLock()
    private var heldOn: Set<UInt> = []
    private var manager: IOHIDManager?

    var isHeld: Bool { lock.withLock { !heldOn.isEmpty } }

    /// MAIN thread. Cần quyền Input Monitoring; thiếu thì IOHIDManagerOpen báo lỗi,
    /// ghi log và tính năng tắt im (⌥ phải + mũi tên vẫn là nhảy từ).
    func start() {
        guard manager == nil else { return }
        let m = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let devices = Self.targets.map {
            [kIOHIDVendorIDKey: $0.vendor, kIOHIDProductIDKey: $0.product] as CFDictionary
        }
        IOHIDManagerSetDeviceMatchingMultiple(m, devices as CFArray)
        IOHIDManagerSetInputValueMatching(m, [kIOHIDElementUsagePageKey: kHIDPage_KeyboardOrKeypad,
                                              kIOHIDElementUsageKey: kHIDUsage_KeyboardRightAlt] as CFDictionary)
        let me = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterInputValueCallback(m, { ctx, _, sender, value in
            guard let ctx else { return }
            let watcher = Unmanaged<HIDRightOptionWatcher>.fromOpaque(ctx).takeUnretainedValue()
            let device = UInt(bitPattern: sender)
            let pressed = IOHIDValueGetIntegerValue(value) != 0
            watcher.lock.withLock {
                if pressed { _ = watcher.heldOn.insert(device) } else { _ = watcher.heldOn.remove(device) }
            }
        }, me)
        // Bàn phím ngắt kết nối giữa lúc giữ ⌥ thì không có sự kiện nhả.
        IOHIDManagerRegisterDeviceRemovalCallback(m, { ctx, _, _, device in
            guard let ctx else { return }
            let watcher = Unmanaged<HIDRightOptionWatcher>.fromOpaque(ctx).takeUnretainedValue()
            _ = watcher.lock.withLock { watcher.heldOn.remove(UInt(bitPattern: Unmanaged.passUnretained(device).toOpaque())) }
        }, me)
        IOHIDManagerScheduleWithRunLoop(m, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        let rc = IOHIDManagerOpen(m, IOOptionBits(kIOHIDOptionsTypeNone))
        let result = rc == kIOReturnSuccess ? "ok" : String(format: "0x%08x", rc)
        Signposts.log.notice("media-keys: IOHIDManagerOpen → \(result, privacy: .public)")
        DebugLog.log("media-keys: IOHIDManagerOpen → \(result)")
        manager = m
    }
}
