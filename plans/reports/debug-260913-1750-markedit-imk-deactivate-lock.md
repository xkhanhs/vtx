# MarkEdit + VTX: khoá phím sau ⌫ — tái hiện tự động, nguyên nhân, cách chốt (13/09/2026)

Tiếp nối `handoff-260913-1730-markedit-colemak-beep.md`. Phiên này KHÔNG cần người gõ:
bơm CGEvent thật bằng `Scripts/ime-drive.swift`, đọc màn hình bằng `Scripts/ax-read-text.swift`,
đối chiếu `log show --start` theo mốc từng phím. Bản VTX 1.6.27 (95).

## Kết luận

1. **Tái hiện được, tất định (12/12).** Chuỗi tối thiểu: `mootj` · ⌫ ⌫ · `t` — hoặc ⌘A · ⌫ · chữ đầu.
   10–20 ms sau `insertText` của chữ đó, WebKit gửi `deactivateServer`; `activateServer` về sau
   250 ms; từ đó không phím nào tới `handle()` (WindowServer vẫn giao keyDown cho MarkEdit).
   MarkEdit tự xử lý từng phím (log `ModelBundle instruct_3b`, `runJavaScriptInFrame`,
   `SFSafariPlatformSupport credentialSelected: nil`) và beep. ⌘A hoặc Alt-Tab mở lại.
2. **Không phải Colemak.** Telex (live ABC) khoá y hệt. Remap hay không remap đều khoá.
   Bảng "Telex OK" trong handoff cũ là do nhịp tay: nghỉ ≥ 1,5 s sau ⌫ thì thường thoát.
3. **Không phải app + layout.** Layout thuần DH-Việt, không IME: `mootj xong` đúng, không deactivate.
4. **Marked chữa được.** Ghim `app.cyan.markedit: marked` (tạm qua `manualAppModes` + restart VTX):
   cùng hai chuỗi phím, 0 deactivate, mọi phím tới `handle()`, `setMarked` đủ.
5. Cơ chế (suy luận từ số đo, chưa đọc được mã WebKit): sau một lần xoá, WebKit hoãn một lần
   reset input context. Nếu nó tự bắn cặp `Deactivate`+`Activate` (cách 1 ms) ngay tại ⌘A/⌫ thì
   gõ tiếp bình thường; nếu chưa, `insertText` kế tiếp của IME kích nó và lần này phiên IME chết.

## Ma trận đo

| Test | Chuỗi | Kết quả |
|---|---|---|
| run2 | câu dài, ⌫ rải rác | deactivate đúng tại `t` sau `mootj`⌫⌫ |
| A/B/C/D/E/F/G/M | `mootj`(⌫×1..3)`t`, có/không remap | khoá |
| H | Telex + ABC, cùng chuỗi | khoá |
| I | layout thuần, không IME | OK |
| L, N1 | nghỉ 1–1,5 s giữa ⌫ và chữ | N1 OK; L khoá ngay chữ đầu sau ⌘A⌫ |
| N2 | ⌘A rồi gõ đè (không ⌫) | OK, `selection fold` đúng |
| N3a, T2, T4 | ⌘A · ⌫ · chữ (0,6–1,5 s) | khoá ngay chữ đầu |
| T3 | `xin` ⌫ (native) · 1,5 s · `n` | khoá |
| P1, P2 | **marked** | OK |

## Đã sửa trong worktree `fix/markedit-webkit-ime-deactivate`

- `typing-modes.yml`: `app.cyan.markedit: marked` + comment số đo.
- `AppTests/BundledTypingModesTests.swift`: `testMarkEditResolvesToMarked`; Spark giữ inPlace.
- `docs/MACOS_IME_NOTES.md`: mục "WKWebView + in-place: `deactivateServer` sau ⌫ rồi khoá phím".
- `Scripts/ime-drive.swift`, `Scripts/ax-read-text.swift`: công cụ tái hiện.

## Chưa làm / mở

- ĐÃ thử né reset (V1, dev-install): chữ thường chèn `kNoRange`. 4/4 chuỗi hết deactivate,
  nhưng chữ sai ("xx", "tj") vì WebKit trả `selectedRange`/`attributedSubstring` cũ ngay sau
  xoá (caret=1 trong tài liệu rỗng; IMK nói 3 ký tự, AX nói 1). In-place thua cả hai nhánh;
  đã revert. Chi tiết trong `docs/MACOS_IME_NOTES.md`.
- Nghiên cứu mã WebKit về điều kiện deactivate: xem `researcher-260913-1745-webkit-imk-deactivate.md`.
- Sự cố phụ: lượt bơm phím đầu (17:30) rơi vào một tài liệu MarkEdit ~1455 ký tự đang mở vì ⌘N
  chưa kịp mở tab; tài liệu đó đã đóng qua hộp Save — user tự kiểm tra.
- `NSBeep` không xuất hiện trong unified log dù app beep; `log stream` rớt message — dùng `log show`.
