# Keymap Klor, 36 phím, Colemak DH-Việt

Bố cục đang chạy trên Klor, đọc thẳng từ bàn phím ngày 25/10/2026 sau khi sửa trong ZMK
Studio. File `config/klor.keymap` ở repo
[xkhanhs/zmk-config-klor](https://github.com/xkhanhs/zmk-config-klor) đã chép lại đúng như
vậy. Sửa trong Studio thì chép lại vào file.

Klor đi từ keymap Corne ([CORNE-LAYOUT.md](CORNE-LAYOUT.md)): tầng NAV, phím NAV/⇧ và các
nguyên tắc giống hệt. Chỉ khác ô `;` ở Base và nửa phải tầng FN. Firmware vẫn gửi mã phím
QWERTY, VTX chế độ Colemak dịch sang DH-Việt, nên hình dưới đây vẽ chữ DH-Việt còn ZMK
Studio hiện QWERTY.

`·` là phím giữ nguyên như Base, `□` là ô trống.

**Tầng 0: Base**
```
 q     w     f     g     b     │   :     l     u     y     x
 a     h     s     t     p     │   m     n     e     o     i
 j     v     r     c     z     │   k     d     ,     .     /
             ⌘   [NAV/⇧] Space │  Bksp   ⇧    Enter
```
- Ô `;` của DH-Việt ra `:` (`&kp LS(Y)`). `;` trần chuyển sang tầng FN. Đây là chỗ duy
  nhất Base của Klor khác MacBook.
- Phím NAV: giữ là tầng NAV, chạm riêng là Shift dính, như Corne.

**Tầng 1: NAV** (giữ bằng ngón cái trái) giống Corne
```
 Esc   [     ↑     ]     Tab   │   /     7     8     9     -
 ⌘     ←     ↓     →     ⌘Tab  │   *     4     5     6     +
 ⇧     (     )     ⌘⇧4   [FN]  │   =     1     2     3     .
             ·    [giữ]  ·     │  XoáTừ  0    ⇧Enter
```

**Tầng 2: FN** (giữ NAV, rồi giữ thêm ngón trỏ trái ở hàng dưới, cột trong)
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
- `Boot` đưa nửa chứa nó vào chế độ nạp: góc trên trái là nửa trái, góc dưới phải là nửa
  phải.
- `⌃C` vẫn là `&kp LC(V)`, lý do ở mục "Chi tiết cần nhớ khi viết firmware" của
  [CORNE-LAYOUT.md](CORNE-LAYOUT.md).

