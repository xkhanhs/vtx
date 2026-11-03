# Keymap Klor, 36 phím, Colemak DH-Việt

Ngày 25/10/2026, bố cục được đọc thẳng từ bàn phím sau khi sửa trong ZMK Studio, rồi đổi
phím NAV thành giữ ⇧, chạm bật/tắt NAV. Ngày 27/10/2026 ngón cái giữa bên phải đổi thành
giữ ⇧, chạm Tab. Ngày 03/11/2026 phím NAV về lại chỉ giữ để vào NAV, bỏ ⇧ và bỏ chạm để
bật/tắt. File `config/klor.keymap` ở repo
[xkhanhs/zmk-config-klor](https://github.com/xkhanhs/zmk-config-klor) là bản gốc. Sửa trong
Studio thì chép lại vào file.

Klor đi từ keymap Corne ([CORNE-LAYOUT.md](CORNE-LAYOUT.md)) và khác ba chỗ: phím NAV ở
ngón cái trái, ô `;` ở Base, và nửa phải tầng FN. Firmware vẫn gửi mã phím
QWERTY, VTX chế độ Colemak dịch sang DH-Việt, nên hình dưới đây vẽ chữ DH-Việt còn ZMK
Studio hiện QWERTY.

`·` là phím giữ nguyên như Base, `□` là ô trống.

**Tầng 0: Base**
```
 q     w     f     g     b     │   :     l     u     y     x
 a     h     s     t     p     │   m     n     e     o     i
 j     v     r     c     z     │   k     d     ,     .     /
             ⌘    [NAV]  Space │  Bksp  ⇧/Tab  Enter
```
- Ô `;` của DH-Việt ra `:` (`&kp LS(Y)`). `;` trần chuyển sang tầng FN. Đây là chỗ duy
  nhất Base của Klor khác MacBook.
- Chỉ còn một ⇧, là ⇧/Tab ở ngón cái phải, dùng để viết hoa chữ của cả hai tay.
- Phím ⇧/Tab (`&mt LSHFT TAB`): **giữ** là ⇧, **chạm** là Tab. ⌘Tab là giữ ⌘ ngón cái trái
  rồi chạm ngón cái phải; chạm tiếp thì lướt qua các app. Lý do: ⌘Tab là phím tắt dùng
  nhiều nhất (khoảng 208 lần/ngày, số đếm của VTX 12–27/10/2026), mà trước đó phải bật NAV,
  bấm ô ⌘Tab rồi tắt NAV, và ô đó chỉ về được app ngay trước. ⇧ phải chỉ khoảng 7 lần/ngày
  nên đổi không mất gì.
- Phím NAV (`&mo 1`): giữ thì vào NAV, nhả là về Base, chạm không làm gì. Từ 25/10 tới
  03/11/2026 phím này là giữ ⇧, chạm bật/tắt NAV; dùng một thời gian thì thấy chỉ giữ
  là đủ.

**Tầng 1: NAV** (giữ NAV)
```
 Esc   [     ↑     ]     Tab   │   /     7     8     9     -
 ⌘     ←     ↓     →     ⌘Tab  │   *     4     5     6     +
 ⇧     (     )     ⌘⇧4   [FN]  │   =     1     2     3     .
             ·    [giữ]  ·     │  Bksp   0    ⇧Enter
```
- Giống Corne, trừ ô Bksp: ở đây là Bksp thường chứ không phải Xoá từ, vì gõ sai một số
  thì chỉ nên mất một ký tự.
- Bôi chọn: giữ NAV, giữ ⇧/Tab ngón cái phải, rồi bấm mũi tên.

**Tầng 2: FN** (giữ NAV, giữ thêm ngón trỏ trái ở hàng dưới, cột trong)
```
 Boot  □     □     □     □     │   ;     @    Mute  Sáng+ BTxoá
 □     □     □     □     □     │   "     ?    Vol+  Sáng− □
 □     □     □     □    [giữ]  │  ⌃C    ⌃4   Vol−   ⌃3   Boot
             ·     ·     ·     │   ·     ·     ·
```
- `;` nằm đúng ô `:` của Base (`&kp Y`, vì mã phím `Y` là `;` trên DH-Việt).
- `@` có ô riêng (`&kp AT`). `'` không còn ô nào; `"` là `&kp DQT`.
- `⌃4` và `⌃3` chọn thẳng bộ gõ. Trên Corne hai ô này ở cột ngoài của Base, Klor không
  có cột đó.
- Không còn ô Play/Pause.
- Vào bootloader: giữ NAV, giữ B, bấm Q (nửa trái) hoặc `/` (nửa phải).
- `Boot` đưa nửa chứa nó vào chế độ nạp: góc trên trái là nửa trái, góc dưới phải là nửa
  phải.
- `⌃C` vẫn là `&kp LC(V)`, lý do ở mục "Chi tiết cần nhớ khi viết firmware" của
  [CORNE-LAYOUT.md](CORNE-LAYOUT.md).

