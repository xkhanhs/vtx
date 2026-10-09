# Phác thảo keymap Corne ba tầng, không trễ

Phác thảo ngày 27/09/2026, nạp vào bàn phím ngày 09/10/2026. Bàn phím là Corne v4 bản
Bluetooth (ZMK, có ZMK Studio), thay cho Sofle v2 có dây, chấp nhận học tầng số.
Firmware nằm ở repo [xkhanhs/zmk-config-corne](https://github.com/xkhanhs/zmk-config-corne),
fork từ `shopcntech/corne1` của shop bán; keymap là file `config/corne.keymap` ở đó.
Bản này trả lời câu hỏi: nếu dùng Corne (3 phím ngón cái mỗi bên) thì xếp modifier thế
nào để gõ không bị khựng như home row mods trên kanata.

Bản xem được, có nút bấm thử từng phím tắt: [corne-layout.html](corne-layout.html).

## Nguyên tắc

- **Mỗi phím chỉ một chức năng.** Không có mod-tap, và phím layer chỉ để giữ, không
  kiêm Space hay Enter. Firmware không phải đoán bấm hay giữ nên không có trễ.
  Home row mods thì phải chờ nhả phím mới biết là chữ. Chéo tay và prior-idle chỉ rút
  ngắn thời gian chờ này, không bỏ được.
- **⌃ và ⇧ ở cột ngoài cho ngón út**, như bàn phím thường.
- **⌘ ở ngón cái trái.** Tay phải cầm chuột chọn chữ thì tay trái vẫn tự copy được.
- **Trong layer, hàng chủ tay kia là ⌘ ⌥ ⌃ ⇧ thường**, ở vị trí J K L ; giống phía phải
  của home row mods cũ. Nhờ đó ⌥←, ⌘⇧4 vẫn bấm được khi ngón cái đang giữ layer.

## Ba tầng

Chữ trên phím là ký tự ra theo DH-Việt. `·` là phím giữ nguyên như Base.

**Tầng 0: Base**
```
 Tab   q     w     f     g     b     │   ;     l     u     y     x     Esc
 ⌃     a     h     s     t     p     │   m     n     e     o     i     ⌥
 ⇧     j     v     r     c     z     │   k     d     ,     .     /     ⇧
                   ⌘    [NAV] Space  │  Bksp  Enter [SYM]
```

**Tầng 1: NAV** (giữ bằng ngón cái trái)
```
 ·     Esc   PgUp  ↑     PgDn  Redo  │  BTxoá Sáng− Sáng+ BT1   BT2   BT3
 ·     ĐầuD  ←     ↓     →     CuốiD │  BT4   ⌘     ⌥     ⌃     ⇧     ·
 ·     Del   Dán   Cắt   Chép  Undo  │  BT5   Mute  Vol−  Vol+  Play  ·
                   ⌘    [giữ]  ·     │  XoáTừ  ·     ·
```
- Đầu dòng và Cuối dòng gửi ⌘← và ⌘→. Trên Mac, Home và End thường chỉ cuộn trang.
- Dán, Chép, Hoàn tác đặt trùng chỗ ⌘v, ⌘c, ⌘z của DH-Việt. Phím Cắt có vì x nằm tay phải.
- Xoá từ (⌥⌫) nằm đúng chỗ Bksp: giữ NAV rồi bấm Bksp.
- BT1 đến BT5 chọn máy đang ghép qua Bluetooth, BT xoá gỡ ghép nối của ô đang chọn.
  Hướng dẫn xử lý sự cố kết nối của shop đều bắt đầu bằng BT xoá.

**Tầng 2: SYM** (giữ bằng ngón cái phải)
```
 `     [     7     8     9     ]     │   F1    F2    F3    F4    F5    F6
 '     -     4     5     6     =     │   ·     ⌘     ⌥     ⌃     ⇧     ·
 \     .     1     2     3     ,     │   F7    F8    F9    F10   F11   F12
                   ·     0     ·     │   ·     ·    [giữ]
```
- Ký hiệu có ⇧ như `!` và `{` thì bấm ⇧ ở hàng chủ tay phải cùng với phím số hoặc ngoặc.

## Chi tiết cần nhớ khi viết firmware

- **macOS lấy phím tắt ⌘ theo chữ của DH-Việt.** Trong file `Colemak DH-Viet.keylayout`,
  tổ hợp `command` chọn keyMap 0, tức bảng chữ thường của DH-Việt. Vì vậy ⌘C nằm ở
  phím V vật lý, ⌘V ở X, ⌘Z ở B, còn ⌘X nằm ở P, bên tay phải.
- Firmware gửi mã phím QWERTY và để macOS dịch sang DH-Việt. Vì vậy muốn ra dấu `;`
  phải gửi phím Y (`&kp Y` trong ZMK), vì DH-Việt đã chuyển `;` sang đó. Các ký hiệu khác vẫn ở chỗ cũ.
- Corne không có hàng số, và macOS không tự đổi F1–F12 của bàn phím rời thành phím
  media. Vì vậy độ sáng, âm lượng và play phải là keycode riêng ở tầng NAV.

## Sửa keymap và nạp lại

- Đổi phím hay đổi tầng: cắm dây vào nửa trái, mở [zmk.studio](https://zmk.studio) bằng
  Chrome, sửa rồi Save. Bản lưu trong Studio nằm trên bàn phím và đè lên keymap của mọi
  firmware nạp sau đó; muốn về keymap trong repo thì chọn Restore Stock Settings.
- Đổi thứ ngoài keymap (file `.conf`, macro, combo): sửa repo, để GitHub Actions build, rồi
  nạp file `.uf2` vào nửa trái. Keymap chỉ nằm ở nửa trái, nửa phải không cần nạp lại.
- Keymap không có phím Bootloader. Khi cần nạp, gán tạm hành vi Bootloader cho một phím
  **nửa trái** trong Studio, không Save, rồi bấm phím đó: ổ đĩa `NICENANO` hiện ra. Phím
  Bootloader chỉ đưa đúng nửa chứa nó vào chế độ nạp.
