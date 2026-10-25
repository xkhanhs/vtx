# Keymap Klor, 36 phím, Colemak DH-Việt

Ngày 25/10/2026, bố cục được đọc thẳng từ bàn phím sau khi sửa trong ZMK Studio, rồi đổi
phím NAV thành giữ ⇧, chạm bật/tắt NAV. File `config/klor.keymap` ở repo
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
             ⌘   [⇧/NAV] Space │  Bksp   ⇧    Enter
```
- Ô `;` của DH-Việt ra `:` (`&kp LS(Y)`). `;` trần chuyển sang tầng FN. Đây là chỗ duy
  nhất Base của Klor khác MacBook.
- Hai ngón cái đều có ⇧, chéo tay như trên MacBook: giữ ⇧ phải để viết hoa chữ tay trái,
  giữ ⇧/NAV trái để viết hoa chữ tay phải.
- Phím ⇧/NAV: **giữ** là ⇧, **chạm** là bật NAV. NAV ở lại cho tới khi chạm phím đó lần
  nữa, nên đi mũi tên hay gõ một dãy số không phải giữ ngón cái. Bàn phím không báo NAV
  đang bật; gõ chữ mà ra số là quên tắt.
- Đè phím này mà bấm bất kỳ phím nào khác thì luôn là ⇧ (`hold-preferred`), kể cả khi gõ
  lướt nhả nó trước. Chỉ chạm rồi nhả, không kèm phím gì, mới bật NAV.

**Tầng 1: NAV** (chạm ⇧/NAV để bật, chạm lần nữa để tắt)
```
 Esc   [     ↑     ]     Tab   │   /     7     8     9     -
 ⌘     ←     ↓     →     ⌘Tab  │   *     4     5     6     +
 ⇧     (     )     ⌘⇧4   [FN]  │   =     1     2     3     .
             ·    [tắt]  ·     │  Bksp   0    ⇧Enter
```
- Giống Corne, trừ ô Bksp: ở đây là Bksp thường chứ không phải Xoá từ, vì NAV có thể bật
  lâu và gõ sai một số thì chỉ nên mất một ký tự.
- Giữ ⇧/NAV trong tầng này vẫn là ⇧, nên ⇧ cộng mũi tên để bôi chọn.

**Tầng 2: FN** (NAV đang bật, giữ ngón trỏ trái ở hàng dưới, cột trong)
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
- Vào bootloader: chạm ⇧/NAV, giữ B, bấm Q (nửa trái) hoặc `/` (nửa phải).
- `Boot` đưa nửa chứa nó vào chế độ nạp: góc trên trái là nửa trái, góc dưới phải là nửa
  phải.
- `⌃C` vẫn là `&kp LC(V)`, lý do ở mục "Chi tiết cần nhớ khi viết firmware" của
  [CORNE-LAYOUT.md](CORNE-LAYOUT.md).

