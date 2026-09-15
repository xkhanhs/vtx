# Handoff: MarkEdit + VTX Colemak — gõ một lúc thì mất phím, bấm gì cũng beep

Phiên điều tra 2026-09-13 16:56–17:30. Chưa sửa gì trong repo. Bản đang cài: 1.6.27 (95),
build 10:21 cùng ngày, một tiến trình VTX duy nhất.

## Triệu chứng (user mô tả + log xác nhận)

- Đang gõ trong **MarkEdit** (`app.cyan.markedit`, 1.33.1, WKWebView + CodeMirror 6) bằng
  **VTX Colemak**, bấm Backspace sửa lỗi → từ đó mọi phím đều `NSBeep`, không chữ nào vào.
- Cửa sổ vẫn key, con trỏ vẫn nháy, không có HUD/bong bóng nào hiện.
- Chữa: Alt-Tab ra rồi vào lại MarkEdit, hoặc bấm Tab (đôi khi) là gõ tiếp được.
- Ban đầu tưởng chỉ khi xoá hết về đầu dòng; user test lại: **xoá một phần (chưa về đầu
  dòng) thỉnh thoảng cũng bị**. Vậy "đầu dòng" KHÔNG phải điều kiện cần.

## Ma trận đã test — biết chắc

| Tổ hợp | Kết quả |
|---|---|
| VTX Colemak + MarkEdit | **LỖI** |
| VTX Telex + MarkEdit | không lỗi |
| VTX Colemak + Chrome (beartype) | không lỗi |
| VTX Colemak + Safari | không lỗi |
| VTX Colemak + TextEdit | không lỗi |
| VTX Colemak + các app khác | không lỗi |
| Layout thuần Colemak DH ANSI / DH-Việt (không VTX) | không lỗi |

Cơ chế gõ của MarkEdit trong bảng: "Gõ trực tiếp" (in-place, rule Tự động). Log:
`handle app.cyan.markedit: in-place needsProbe=false`, probe `honored`, `axMatch=yes`.

## Giả thuyết ĐÃ LOẠI (kèm bằng chứng)

1. **Remap layout (KeyboardLayoutOverride translator)** — loại. 17:11:15 VTX báo
   `layout-override …ColemakDH-Viet: off (live=…ColemakDH-Viet)` (live == pinned → không
   remap), 17:11:46 vẫn `cause=deactivateServer` + 19 `NSBeep`.
2. **VTX chèn ký tự điều khiển 0x08 cho Backspace** — loại. `KeyboardLayoutTranslator`
   bỏ `ascii < 0x20` (dòng 80) và `insertsOneCharacter` chặn `< 0x20`.
3. **VTX tự chuyển input source** — loại. Chỉ `SecureInputMonitor` và `SwitchHotkey` gọi
   `TISSelectInputSource`, cả hai đều log; không có dòng nào lúc lỗi. Poller TIS (20 ms,
   có pump run loop) không thấy source/layout đổi trong lúc lỗi.
4. **Caps Lock / globe / hidutil / Karabiner** — loại. `hidutil UserKeyMapping` rỗng,
   không Karabiner, user bấm Backspace thật, từng lần.
5. **Cửa sổ mất key focus** — loại. WindowServer suốt quá trình giao phím tới
   `keyboardFocus; pid MarkEdit; token viewbridge-key-window`.
6. **TerminalTap** — loại cho chữ thường: tap chỉ sửa event ⌘/⌃/⌥ chord (`remapChord`),
   MarkEdit đi đường IMKit.
7. **Edge-tap word (`edgeTapWord`)** — loại: chỉ bật cho `offset0AppendApps = ["com.hnc.Discord"]`.
8. **WordLog** (commit 191442c, chỉ thu ở Telex) — loại: ở Colemak chỉ `return` sớm.
9. **Ngôn ngữ/TIS property khác nhau giữa 2 mode** — loại: cả hai `languages=(vi)`,
   `TISTypeKeyboardInputMode`, ASCII-capable.
10. **WebKit + mode không-primary nói chung** — loại: Safari (WebKit) với VTX Colemak không lỗi.
11. **MarkEdit native code đụng input source** — loại: không Mach-O nào trong
    `MarkEdit.app` (kể cả FinderExtension/PreviewExtension appex) chứa symbol TIS /
    `selectedKeyboardInputSource` / `allowedInputSourceLocales`. Researcher agent đọc repo
    MarkEdit: không có code TIS/TSM, `resignFirstResponder` chỉ khi webView hidden; IME
    code chỉ xử lý `compositionstart/end` (marked text). Báo cáo:
    `plans/reports/researcher-260913-1715-markedit-input-source.md`.
12. **Gợi ý chữ của MarkEdit** — tắt sẵn (`assistant.inline-predictions` và
    `assistant.suggest-while-typing` = false).
13. **Icon ★ (`MenuIconAlt.pdf` 16×16 viết tay) làm hỏng caret badge** — user bác: lỗi
    xảy ra cả khi không ở đầu dòng. Chưa build thử; không đổi file nào.
14. **`Cursor disabled: failed set_cursor_surface`** (WindowServer) — nhiễu, xuất hiện
    cả lúc không lỗi.

## Dấu vết lúc lỗi — lặp lại mọi lần (16:57:29, :34, :39, :43, 17:02:15, :18, :25, :34, 17:11:46)

```
handle ENTER app=app.cyan.markedit …                 ← VTX xử lý một phím
(IMK) Get selected range / Inserting text / Menu / Menu   ← insertText 1 chữ (đầu từ, len=1)
(IMK) Deactivate Server                              ← 5–160 ms sau; thường trùng một
                                                        keyDown/keyUp KHÔNG tới VTX
composition dropped mid-word (cause=deactivateServer) len=1 (đôi khi len=2)
CursorUIViewService setTextCursorIsActive: NO / deactivateInputModeSwitcher
TextInputSwitcher (TextInputMenuUI) <private>
(IMK) Activate Server  ~250 ms sau, client=app.cyan.markedit
MarkEdit NSBeep × N    ← các phím sau KHÔNG vào handle() của VTX dù đã Activate
… cho tới lần Deactivate/Activate kế tiếp (Alt-Tab) → gõ lại được
```

Ghi chú: MarkEdit log `tokengenerationcore ModelBundle: Creating … instruct_3b` và
`runJavaScriptInFrame` ngay SAU mỗi Deactivate (hệ quả, chưa rõ có liên quan không).

## Khác biệt thật còn lại giữa hai mode (chưa loại)

- `Info.plist`: Colemak có `tsInputModePrimaryInScriptKey=false`,
  `tsInputModeDefaultStateKey=false` (Telex = true). Loại khả năng "WebKit chung" nhờ
  Safari, nhưng CHƯA loại riêng MarkEdit. Thử cần notarize-install + logout.
- `InputModeState` / layout ghim khác nhau (remap đã loại, nhưng live layout lúc test
  không-remap là DH-Việt thay vì ABC — phím vật lý và `event.characters` khác Telex).
- Chuỗi phím vật lý khác (user gõ Colemak) → keyCode khác. Có dấu hiệu Deactivate trùng một
  key event không tới VTX; **chưa biết keyCode nào**. VTX không log keyCode (cố ý, privacy).

## Hướng gợi ý cho phiên sau

1. Bắt keyCode của phím ngay trước Deactivate: thêm log tạm (chỉ keyCode của phím KHÔNG
   phải chữ, hoặc keyCode ở `deactivateServer` của phím cuối) qua `dev-install.sh`, rồi
   user tái hiện. Hoặc listen-only CGEventTap (cần Input Monitoring).
2. Xem WebKit/CodeMirror: MarkEdit deactivate input context sau insertText → thử bật
   Web Inspector cho MarkEdit (`defaults write app.cyan.markedit WebKitDeveloperExtras -bool true`
   nếu app cho phép) để xem `blur/focus`, `compositionstart`, `beforeinput` lúc lỗi.
3. Thử đổi cơ chế gõ của MarkEdit sang **Gạch chân (marked)** trong Bảng cơ chế gõ để xem
   lỗi còn không — chưa thử.
4. So Telex vs Colemak với CÙNG live layout (chọn DH-Việt rồi VTX Telex → Telex remap
   ngược) — chưa thử được đúng (lần trước đi qua ABC nên không remap).

## Công cụ đã dùng (tái sử dụng được)

- Log bền: `/usr/bin/log stream --level debug --style compact --predicate 'subsystem == "com.vtx.inputmethod.telex" OR composedMessage CONTAINS[c] "NSBeep"'`
  (debug logging đang bật trong `com.viettelex.settings`).
- Dấu Deactivate phía hệ thống: predicate `process == "CursorUIViewService" AND eventMessage CONTAINS "setTextCursorIsActive"`.
- Poller TIS 20 ms: phải `CFRunLoopRunInMode` mỗi vòng, không thì TIS trả giá trị cache
  (lần đầu viết bằng `usleep` không ghi nhận đổi source nào).
- `TISCreateInputSourceList(nil,false)` hiện: ABC, ColemakDHANSI, 2 mode VTX; DH-Việt
  chọn được bằng `TISSelectInputSource` dù menu bar không hiện Colemak DH ANSI.

## Việc phụ user nêu (chưa điều tra)

Sau logout/khởi động lại, các input Colemak DH tự được thêm lại dù đã gỡ. Code VTX không
gọi `TISEnableInputSource`.
