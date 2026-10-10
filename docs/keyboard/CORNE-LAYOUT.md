# Keymap Corne ba tầng, 36 phím, không trễ

Bàn phím là Corne v4 bản Bluetooth (ZMK, có ZMK Studio), thay cho Sofle v2 có dây.
Firmware nằm ở repo [xkhanhs/zmk-config-corne](https://github.com/xkhanhs/zmk-config-corne),
fork từ `shopcntech/corne1` của shop bán; keymap là file `config/corne.keymap` ở đó.

**Trạng thái.** Bản nạp ngày 09/10/2026 dùng đủ 42 phím. Tài liệu này mô tả phương án
36 phím chốt ngày 10/10/2026, **chưa nạp vào bàn phím**: bỏ hẳn hai cột ngoài cùng vì
ngón út phải với, và xếp lại theo những tổ hợp dùng nhiều nhất (viết hoa, ⌘Tab, ⌘⇧ đổi
bộ gõ, ⌘⇧C, chụp màn hình).

Bản xem được: [corne-layout.html](corne-layout.html). Phần 1 vẽ ba tầng, ô có chấm xanh
là chỗ đổi so với bản đang chạy. Phần 2 liệt kê các tổ hợp hay dùng, bấm vào một tổ hợp
thì sơ đồ tô các phím cần bấm.

## Nguyên tắc

- **Mỗi phím chỉ một chức năng.** Không có mod-tap, không phím dính, và phím layer chỉ để
  giữ, không kiêm Space hay Enter. Firmware không phải đoán bấm hay giữ nên không có trễ.
  Home row mods thì phải chờ nhả phím mới biết là chữ. Chéo tay và prior-idle chỉ rút
  ngắn thời gian chờ này, không bỏ được.
- **Chỉ dùng 36 phím.** Hai cột ngoài cùng không gán gì, ngón út không phải với ra.
- **⌘ ở ngón cái trái, ⇧ ở ngón cái phải.** Tay phải cầm chuột chọn chữ thì tay trái vẫn
  tự copy được. ⇧ ở ngón cái thì viết hoa được chữ của cả hai tay, và ⌘⇧ là hai ngón cái.
- **Tab nằm ở Base** để ⌘Tab là hai phím và ⌘ được giữ thật: bấm Tab tiếp là đi qua từng
  app.
- **Trong layer, hàng chủ tay phải là ⌘ ⌥ ⌃ ⇧ thường**, ở vị trí J K L ; của QWERTY. Nhờ
  đó ⌥←, hay ⇧ cộng phím số, vẫn bấm được khi ngón cái đang giữ layer.

## Ba tầng

Chữ trên phím là ký tự ra theo DH-Việt. `·` là phím giữ nguyên như Base, `□` là ô trống.

**Tầng 0: Base**
```
 q     w     f     g     b     │   Tab   l     u     y     x
 a     h     s     t     p     │   m     n     e     o     i
 j     v     r     c     z     │   k     d     ,     .     Enter
             ⌘    [NAV] Space  │  Bksp   ⇧    [SYM]
```
- So với bản đang chạy: ⇧ lấy chỗ Enter ở ngón cái phải, Enter xuống chỗ dấu `/` (ngón út
  phải hàng dưới), Tab lấy chỗ dấu `;` (phím Y của QWERTY).
- `<` và `>` là ⇧ ngón cái cộng dấu phẩy, dấu chấm.

**Tầng 1: NAV** (giữ bằng ngón cái trái)
```
 Esc   □     ↑     □     □     │  BTxoá Sáng− Sáng+ BT1   BT2
 ⇧     ←     ↓     →     ?     │  BT4   ⌘     ⌥     ⌃     ⇧
 Del   ⌘⇧2   ⌘⇧3   ⌘⇧4   ⌘⇧5   │  BT5   Mute  Vol−  Vol+  Play
             ⌘    [giữ]  ·     │  XoáTừ  ·     ·
```
- Bốn ô ⌘⇧2 đến ⌘⇧5 là nút chụp màn hình một chạm, bấm bằng một tay trái.
- `?` ra thẳng dấu hỏi, không cần ⇧.
- ⇧ trái để bôi chọn bằng một tay: NAV + ⇧ + mũi tên.
- Xoá từ (⌥⌫) nằm đúng chỗ Bksp: giữ NAV rồi bấm Bksp.
- Không còn Dán, Chép, Cắt, Hoàn tác, Làm lại, Đầu dòng, Cuối dòng, PgUp, PgDn. Giữ ⌘
  ngón cái rồi bấm v, c, z ở Base cho ra đúng như ba ô đầu, cũng bằng một tay.
- BT1, BT2, BT4, BT5 chọn máy đang ghép qua Bluetooth, BT xoá gỡ ghép nối của ô đang
  chọn. Hướng dẫn xử lý sự cố kết nối của shop đều bắt đầu bằng BT xoá. BT3 nằm ở cột
  ngoài nên không còn.

**Tầng 2: SYM** (giữ bằng ngón cái phải)
```
 [     7     8     9     ]     │   `     (     )     !     @
 -     4     5     6     =     │   /     ⌘     ⌥     ⌃     ⇧
 .     1     2     3     ;     │   \     '     "     :     _
             ·     0     ·     │   ·     ·    [giữ]
```
- Tay phải là ký hiệu hay dùng, mỗi ô ra thẳng một ký hiệu. Hàng F1 đến F12 nhường chỗ;
  cần lại thì phải thêm tầng thứ tư.
- Ký hiệu còn lại là ⇧ ở hàng chủ tay phải cộng ô gốc: `#` `$` `%` `^` `&` `*` từ phím
  số, `{` `}` `+` `|` `~` từ `[` `]` `=` `\` `` ` ``. Ngón cái phải đang giữ SYM nên
  không dùng được ⇧ ngón cái ở đây.

## Các tổ hợp hay dùng

| Tổ hợp | Cách bấm |
|---|---|
| Viết hoa | Cái phải giữ ⇧, gõ chữ bằng tay nào cũng được |
| ⌘⇧ đổi bộ gõ | Cái trái ⌘, cái phải ⇧ |
| ⌘⇧C | Hai ngón cái giữ ⌘ và ⇧, trỏ trái bấm c |
| ⌘Tab | Cái trái giữ ⌘, trỏ phải bấm Tab; thêm ⇧ để đi ngược |
| ⌘Enter | Cái trái ⌘, út phải Enter |
| ⌘C, ⌘V, ⌘Z một tay | Cái trái ⌘, tay trái bấm c, v, z |
| Chụp màn hình | NAV + một trong bốn ô hàng dưới tay trái |
| Xoá từ | NAV + Bksp |
| `?` | NAV + trỏ trái hàng chủ phía trong |
| `/` | SYM + trỏ phải hàng chủ phía trong |
| ⌃ hoặc ⌥ với Space, mũi tên, số | Giữ NAV hoặc SYM, bấm ⌃ hay ⌥ ở hàng chủ tay phải |

Chưa có chỗ: ⌃ và ⌥ cộng một chữ (ví dụ ⌃C trong terminal), vì ở Base không còn ⌃ ⌥ và
chữ không có trong layer. ⌘X cắt chữ là hai tay, do x của DH-Việt nằm tay phải.

## Chi tiết cần nhớ khi viết firmware

- **macOS lấy phím tắt ⌘ theo chữ của DH-Việt.** Trong file `Colemak DH-Viet.keylayout`,
  tổ hợp `command` chọn keyMap 0, tức bảng chữ thường của DH-Việt. Vì vậy ⌘C nằm ở
  phím V vật lý, ⌘V ở X, ⌘Z ở B, còn ⌘X nằm ở P, bên tay phải.
- Firmware gửi mã phím QWERTY và để macOS dịch sang DH-Việt. Vì vậy muốn ra dấu `;`
  phải gửi phím Y (`&kp Y` trong ZMK), vì DH-Việt đã chuyển `;` sang đó; ô `:` ở tầng
  SYM là `&kp LS(Y)`. Các ký hiệu khác vẫn ở chỗ cũ.
- Ô ra thẳng ký hiệu có ⇧ là phím gốc kèm ⇧: `?` là `&kp LS(FSLH)`, `(` là
  `&kp LS(N9)`, nút chụp màn hình là `&kp LG(LS(N2))` đến `&kp LG(LS(N5))`. ZMK Studio
  gán được kiểu này bằng cách chọn phím rồi tích thêm modifier.
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
