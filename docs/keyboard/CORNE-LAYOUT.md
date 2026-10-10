# Keymap Corne ba tầng, 36 phím, QWERTY, không trễ

Bàn phím là Corne v4 bản Bluetooth (ZMK, có ZMK Studio), thay cho Sofle v2 có dây.
Firmware nằm ở repo [xkhanhs/zmk-config-corne](https://github.com/xkhanhs/zmk-config-corne),
fork từ `shopcntech/corne1` của shop bán; keymap là file `config/corne.keymap` ở đó.

**Trạng thái.** Phương án chốt ngày 10/10/2026: chữ về QWERTY để gõ quen tay trong lúc
còn tập DH-Việt ở bàn phím MacBook, vì học cùng lúc cả bàn phím mới lẫn layout mới thì
không kịp. Phương án 36 phím DH-Việt trước đó nằm trong lịch sử git của file này.

Bản xem được: [corne-layout.html](corne-layout.html). Phần 1 vẽ ba tầng. Phần 2 liệt kê
các tổ hợp hay dùng, bấm vào một tổ hợp thì sơ đồ tô các phím cần bấm. Bản để in ra
một trang A4: [corne-layout-print.html](corne-layout-print.html).

## Nguyên tắc

- **Mỗi phím chỉ một chức năng.** Không có mod-tap, không phím dính, và phím layer chỉ để
  giữ, không kiêm Space hay Enter. Firmware không phải đoán bấm hay giữ nên không có trễ.
- **Chỉ dùng 36 phím.** Hai cột ngoài cùng không gán gì, ngón út không phải với ra.
- **Base là QWERTY nguyên vẹn.** Cả 26 chữ và bốn dấu `;` `,` `.` `/` ở đúng chỗ của bàn
  phím thường, nên `?` `:` `<` `>` vẫn là ⇧ cộng phím gốc.
- **⌘ ở ngón cái trái, ⇧ ở ngón cái phải.** Tay phải cầm chuột chọn chữ thì tay trái vẫn
  tự copy được, và ⌘⇧ là hai ngón cái.
- **Tầng NAV gánh gần hết:** tay trái di chuyển, tay phải là numpad. Ký hiệu là ⇧ ngón cái
  phải cộng phím số, như bàn phím thường.
- **Tầng thứ ba (FN) dùng ít nên không có phím riêng ở Base.** Giữ NAV rồi giữ thêm ngón
  cái phải ngoài cùng.

## Ba tầng

`·` là phím giữ nguyên như Base, `□` là ô trống.

**Tầng 0: Base**
```
 q     w     e     r     t     │   y     u     i     o     p
 a     s     d     f     g     │   h     j     k     l     ;
 z     x     c     v     b     │   n     m     ,     .     /
             ⌘    [NAV] Space  │  Bksp   ⇧    Enter
```

**Tầng 1: NAV** (giữ bằng ngón cái trái)
```
 Esc   [     ↑     ]     `     │   +     7     8     9     '
 ⌘     ←     ↓     →     Tab   │   -     4     5     6     0
 ⇧     ⌥←    \     ⌥→    ⌃C    │   =     1     2     3     .
             ·    [giữ]  ·     │  XoáTừ  ·    [FN]
```
- Tay phải là numpad, `4 5 6` nằm ngay hàng chủ, `0` ở ngón út. Cột phía trong là phép
  tính `+` `-` `=`, dấu chấm thập phân ở dưới số 0.
- Ký hiệu là giữ thêm ⇧ ngón cái phải: `! @ # $ % ^ & * ( )` từ phím số, `_` từ `-`,
  `"` từ `'`, `{ }` từ `[ ]`, `|` từ `\`, `~` từ `` ` ``. Riêng `+` có ô riêng.
- ⌘ và ⇧ ở ngón út trái là phím thường, dùng khi ngón cái đang bận giữ NAV: ⌘ cộng Tab
  để chuyển app, ⌘ cộng `←` `→` về đầu và cuối dòng, ⇧ cộng mũi tên để bôi chọn.
- `⌥←` và `⌥→` nhảy từng từ, nằm ngay dưới `←` và `→`. Thêm ⇧ ngón út là bôi theo từ.
- `⌃C` là một ô gửi thẳng ⌃C để ngắt lệnh trong terminal.
- Xoá từ (⌥⌫) nằm đúng chỗ Bksp. Muốn xoá một chữ số thì nhả NAV trước.
- Esc và Tab chỉ có ở tầng này.

**Tầng 2: FN** (giữ NAV, rồi giữ thêm ngón cái phải ngoài cùng)
```
 BT1   BT2   BT3   BT4   BT5   │  BTxoá Sáng− Sáng+  □     □
 □     □     □     □     □     │   □    Mute  Vol−  Vol+  Play
 □     ⌘⇧2   ⌘⇧3   ⌘⇧4   ⌘⇧5   │   □     □     □     □     □
             ·     ·     ·     │   ·     ·    [giữ]
```
- Bốn ô ⌘⇧2 đến ⌘⇧5 là nút chụp màn hình một chạm.
- BT1 đến BT5 chọn máy đang ghép qua Bluetooth, BT xoá gỡ ghép nối của ô đang chọn.
  Hướng dẫn xử lý sự cố kết nối của shop đều bắt đầu bằng BT xoá.

## Các tổ hợp hay dùng

| Tổ hợp | Cách bấm |
|---|---|
| Viết hoa | Cái phải giữ ⇧, gõ chữ bằng tay nào cũng được |
| ⌘⇧ đổi bộ gõ | Cái trái ⌘, cái phải ⇧ |
| ⌘⇧C, ⌘⇧V | Hai ngón cái giữ ⌘ và ⇧, tay trái bấm c hoặc v |
| ⌘C, ⌘V, ⌘X, ⌘Z một tay | Cái trái ⌘, tay trái bấm chữ |
| ⌘Tab một tay | Giữ NAV, út trái giữ ⌘, trỏ trái bấm Tab; bấm Tab tiếp để đi qua từng app |
| ⌘Enter | Cái trái ⌘, cái phải Enter |
| Số | Giữ NAV, tay phải bấm numpad |
| Ký hiệu trên phím số | Giữ NAV và ⇧ bằng hai ngón cái, bấm số |
| `+` `-` `=` | Giữ NAV, trỏ phải bấm cột phía trong |
| Nhảy từ | Giữ NAV, bấm ô dưới `←` hoặc `→` |
| Xoá từ | NAV + Bksp |
| ⌃C | NAV + trỏ trái hàng dưới phía trong |
| Âm lượng, độ sáng, chụp màn hình | Giữ NAV và FN bằng hai ngón cái, bấm một ô |

Chưa có chỗ: ⌃ và ⌥ cộng một chữ (trừ ⌃C), và ⌃ cộng mũi tên để đổi desktop, vì bàn
phím không còn phím ⌃ hay ⌥ trần. Gõ `10/10/2026` phải nhả NAV để bấm `/`.

## Chi tiết cần nhớ khi viết firmware

- **Firmware gửi mã phím QWERTY, nên macOS phải ở một bộ gõ QWERTY.** Với VTX là chế độ
  Telex. Nếu chuyển sang chế độ Colemak thì macOS dịch tiếp sang DH-Việt: chữ ra sai chỗ,
  và ô `⌃C` thành ⌃ cộng một chữ khác.
- Ô ra thẳng một tổ hợp là phím gốc kèm modifier: `+` là `&kp PLUS`, nhảy từ là
  `&kp LA(LEFT)`, ⌃C là `&kp LC(C)`, chụp màn hình là `&kp LG(LS(N2))` đến
  `&kp LG(LS(N5))`. ZMK Studio gán được kiểu này bằng cách chọn phím rồi tích thêm
  modifier.
- Phím FN là `&mo 2` đặt trong tầng NAV, không có ở Base. Hai cột ngoài và các ô trống
  của tầng FN là `&none`, để lỡ chạm không ra số của tầng NAV.
- Corne không có hàng số, và macOS không tự đổi F1–F12 của bàn phím rời thành phím
  media. Vì vậy độ sáng, âm lượng và play phải là keycode riêng ở tầng FN.

## Sửa keymap và nạp lại

- Đổi phím hay đổi tầng: cắm dây vào nửa trái, mở [zmk.studio](https://zmk.studio) bằng
  Chrome, sửa rồi Save. Bản lưu trong Studio nằm trên bàn phím và đè lên keymap của mọi
  firmware nạp sau đó; muốn về keymap trong repo thì chọn Restore Stock Settings.
- Đổi thứ ngoài keymap (file `.conf`, macro, combo): sửa repo, để GitHub Actions build, rồi
  nạp file `.uf2` vào nửa trái. Keymap chỉ nằm ở nửa trái, nửa phải không cần nạp lại.
- Keymap không có phím Bootloader. Khi cần nạp, bấm nút reset đen dưới OLED của nửa trái
  hai lần liền nhau, hoặc gán tạm hành vi Bootloader cho một phím **nửa trái** trong
  Studio, không Save, rồi bấm phím đó: ổ đĩa `NICENANO` hiện ra. Phím Bootloader chỉ đưa
  đúng nửa chứa nó vào chế độ nạp.
