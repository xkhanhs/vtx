# ⌘-chord bị remap thì KHÔNG có tác dụng — 31/08/2026

Trạng thái: **ĐÃ GIẢI QUYẾT cùng ngày** (phiên 10:14). Root cause:
`keyboardSetUnicodeString(stringLength: 1)` trên chord event làm AppKit không match
key equivalent nữa — dù mọi trường đọc lại đều hoàn hảo. Fix trong
`TerminalTap.remapChord`: đổi keycode tại chỗ + `keyboardSetUnicodeString(length 0)`
(XOÁ payload để hệ tự dẫn xuất lại), keyUp remap theo CẶP thay vì theo cờ. Toàn bộ
chuỗi thí nghiệm, bảng ma trận và ba kết luận cũ bị lật (trong đó có "nội dung event
đã loại trừ" và đầu mối "tap ngoài thì được" — hoá ra bị nhiễu bởi mode):
`docs/MACOS_IME_NOTES.md`, mục "root cause found". Xác nhận bằng phím thật của user:
⌘C/⌘V chạy ở mode Colemak đang remapping.

Phần dưới giữ nguyên làm hồ sơ lịch sử của phiên điều tra buổi sáng.

Bối cảnh: fork VTX, hai input mode. `VTX Telex` ghim `com.apple.keylayout.ABC`,
`VTX Colemak` ghim `com.vtx.keyboardlayout.colemakdhviet.keylayout.ColemakDH-Viet`
(layout tuỳ chỉnh của người dùng, KHÁC `Colemak DH ANSI` của bên thứ ba).

## Triệu chứng

Ở chế độ có remap (`layout-override …: remapping (live=…)`), **mọi phím tắt mà VTX phải
viết lại keycode đều không có tác dụng**. Phím tắt VTX để nguyên thì chạy bình thường.

| chord | phép biến đổi | kết quả |
|---|---|---|
| ⌘A (kc 0→0), ⌘W (13→13) | không đổi | chạy |
| ⌘C (9→8), ⌘V (7→9), ⌘R (8→15) | có đổi | **không có gì xảy ra** |

Không phụ thuộc app: tái hiện ở Claude Desktop, Chrome, TextEdit.

## Cách tái hiện

1. Bật `VTX Colemak`, đảm bảo log ghi `remapping (live=com.apple.keylayout.ABC)`
2. Bôi đen một đoạn chữ, bấm ⌘C theo vị trí DH-Việt (phím V vật lý, keycode 9)
3. `pbpaste | wc -c` → 0

Dùng clipboard làm phép đo khách quan; xoá bằng `osascript -e 'set the clipboard to ""'`
trước mỗi lần đo. Đừng tin cảm nhận "hình như chạy".

## Hai lỗi ĐÃ sửa (thật, có số đo, đã vào code)

1. **Payload unicode không được ghi lại.** `remapChordKeyCode` chỉ sửa
   `.keyboardEventKeycode`; window server đã tính sẵn chuỗi unicode từ keycode CŨ, và
   `NSEvent.characters` / `charactersIgnoringModifiers` lấy từ đó. Đo được: ⌘C tới app
   với keycode `c` nhưng payload `v` → app **dán**. Sửa: ghi lại payload cho khớp.
2. **`keyUp` không được remap.** Mask của tap chỉ có `keyDown`. Đo được: `DOWN kc=8 'c'`
   / `UP kc=9 'v'` — nhấn một phím, nhả một phím khác. Sửa: thêm `keyUp` vào mask + một
   nhánh sớm trong `handle()` chỉ làm đúng việc remap.

Cả hai đều đã hết sau khi sửa (đo lại: `DOWN kc=8 'c'` / `UP kc=8 'c'`). **Nhưng không
cái nào là nguyên nhân của triệu chứng.**

## ĐÃ LOẠI TRỪ CHẮC CHẮN (đừng đào lại)

- **Nội dung event.** Đo bằng tap listen-only đặt `.tailAppendEventTap` (thấy event SAU
  VTX) và bằng `NSEvent.addGlobalMonitorForEvents`. Sau khi sửa, event của VTX khớp
  event thật ở **mọi** trường: `keyCode`, `characters`, `charactersIgnoringModifiers`,
  `flags` (0x100108), `autorepeat`, `keyboardType`, `eventSourceStateID`,
  `eventSourceUnixProcessID`, `eventSourceUserData`. Không còn trường nào để so.
- **Phụ thuộc app / Chromium.** Hỏng y hệt ở TextEdit (native) và Chrome.
- **Bảng remap tính sai.** Dựng lại bảng bằng `UCKeyTranslate` cho toàn bộ ASCII in được:
  không phím nào không remap được, không phím nào remap ra sai ký tự.
- **Vùng chọn bị xoá.** Vệt bôi đen KHÔNG mất khi bấm ⌘C. `.telexResetComposition` và
  `noteUserModifierChord` cũng chạy y hệt ở mode Telex nơi ⌘C vẫn tốt.
- **Composition treo trong engine.** Log tại nhánh chord: `empty=true reopen=false`.
- **"Có IME đang bật là hỏng".** Ở `VTX Telex` (remap tắt), ⌘C copy được bình thường
  trong cùng app — VTX vẫn là IME đang hoạt động.
- **Cơ chế "phát event thay thế".** Nuốt chord gốc, dựng `CGEvent` mới trên
  `CGEventSource(stateID: .privateState)` với keycode đích + flags + payload, post vào
  `.cgSessionEventTap` → **hỏng y hệt**. Đã revert (nuốt phím tắt rủi ro hơn sửa tại
  chỗ mà không được gì).

## CHƯA XÁC NHẬN — đầu mối mạnh nhất còn lại

Một tap **ngoài tiến trình VTX**, đặt `.headInsertEventTap`, làm ĐÚNG phép biến đổi
`kc9 → kc8` + payload `c`, trong khi VTX ở mode Telex → **copy được** (clipboard 36 byte).

Nếu đúng, nó nói rằng vấn đề nằm ở chỗ **event bị sửa bởi chính tiến trình của input
method đang hoạt động**, chứ không phải ở nội dung event hay ở cơ chế tap.

Nhưng đây là quan sát **một lần, chưa lặp lại được**. Hai lần thử lặp đều hỏng vì lỗi
trong công cụ đo, không phải vì kết quả âm tính. Phải xác nhận lại trước khi xây gì lên
nó.

## Bẫy trong công cụ đo (đã mất thời gian vì chúng)

- **`.defaultTap` bị macOS tắt thì phải tự bật lại.** Không xử lý
  `tapDisabledByTimeout` / `ByUserInput` → tap chết im lặng, đọc ra y hệt "không có sự
  kiện nào". Đã kết luận sai một lần vì cái này.
- **Lọc keyUp theo cờ ⌘ là sai.** Người dùng thường nhả ⌘ TRƯỚC phím chữ, nên keyUp
  không còn cờ ⌘ và bị bỏ qua → tự tạo ra đúng lỗi down/up lệch đang muốn đo. Phải bám
  theo cặp: nhớ đã sửa keyDown nào thì sửa keyUp tương ứng, bất kể cờ.
- **Đừng để công cụ thí nghiệm sống trong lúc hỏi người dùng.** Một tap rewrite còn chạy
  đã làm ⌘V hoá thành ⌘C và sinh ra một báo cáo triệu chứng hoàn toàn sai lệch.
- **Cửa sổ 60–90 giây quá ngắn** so với nhịp trao đổi; dùng 10 phút.

## Cách gỡ đang dùng

Cài layout được ghim thành input source thật rồi chọn nó một lần, để layout **đang sống**
của macOS chính là layout VTX ghim. `apply()` khi đó về sớm (`off (live=…)`) và không bao
giờ viết lại chord nữa; gõ vẫn đúng vì OS đã ở layout đó, tiếng Việt vẫn do IME lo.

Lưu ý: cách này **dời** lỗi sang chế độ còn lại — chế độ nào ghim khác layout sống thì
chế độ đó thành bên remap. macOS chỉ có MỘT layout sống, nên hai chế độ VTX ghim hai
layout khác nhau thì luôn có một chế độ hỏng phím tắt.

Hệ quả: mong muốn "Telex chạy QWERTY + VTX Việt chạy DH-Việt + ABC tiếng Anh" **không
đạt được** bằng cách sắp xếp settings. Nó đòi hỏi sửa đúng lỗi này.

## Gợi ý cho phiên sau

1. **Xác nhận lại quan sát "tap ngoài thì được"** bằng công cụ đã tránh hết các bẫy ở
   trên. Đây là việc đầu tiên nên làm — nó quyết định hướng đi.
2. Nếu đúng: tìm xem macOS phân biệt event do tiến trình IME đang hoạt động sửa như thế
   nào. Hướng khả dĩ: tách phần remap chord ra một **helper process riêng** ngoài
   bundle IME.
3. Kiểm tra `CGEventSource.keyState` — phím vật lý đang giữ là kc9 trong khi event khai
   kc8; chưa đo được ai đọc trạng thái này, nhưng nó là thứ duy nhất còn lệch giữa
   event của VTX và một cú bấm thật.

Bối cảnh nền: xem `docs/MACOS_IME_NOTES.md`, mục "An input method cannot choose its
keyboard layout" và các mục con của nó.
