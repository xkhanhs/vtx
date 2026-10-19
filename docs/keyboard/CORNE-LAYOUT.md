# Keymap Corne ba tầng, 36 phím, Colemak DH-Việt

Bàn phím là Corne v4 bản Bluetooth (ZMK, có ZMK Studio), thay cho Sofle v2 có dây.
Firmware nằm ở repo [xkhanhs/zmk-config-corne](https://github.com/xkhanhs/zmk-config-corne),
fork từ `shopcntech/corne1` của shop bán; keymap là file `config/corne.keymap` ở đó.

**Trạng thái.** Chốt ngày 11/10/2026: gõ Colemak DH-Việt trên Corne, và phần dịch chữ do
VTX làm trên máy. Firmware vẫn gửi mã phím QWERTY như bản nạp ngày 10/10/2026, chỉ sửa
đúng một ô (`⌃C`, xem cuối trang). Không có tầng Colemak trong firmware và không có phím
chuyển layout.

Ngày 19/10/2026 file `corne.keymap` trong repo firmware được viết lại cho khớp với bàn
phím (các ô đã sửa trong ZMK Studio ngày 12 và 13/10/2026), cộng thêm hai thay đổi ở mục
cuối trang: chạm NAV ra Shift dính, và hai ô ngoặc đơn ở NAV. Từ đây file trong repo là
bản gốc; sửa trong Studio thì chép lại vào file.

Hệ quả: cắm Corne vào một máy không có VTX thì nó gõ QWERTY. Trên máy nhà, VTX phải ở
chế độ **Colemak**; chuyển sang chế độ Telex thì Corne gõ QWERTY ngay, không cần đụng
firmware.

Bản xem được: [corne-layout.html](corne-layout.html) và bản in một trang A4
[corne-layout-print.html](corne-layout-print.html). Cả hai vẽ keymap ngày 11/10/2026 và
chưa cập nhật theo các thay đổi ngày 12, 13 và 19/10/2026 ở trang này.

## Nguyên tắc

- **Chữ, Space, ⌘ và Enter không bao giờ phải chờ.** Không có home row mod và không có
  mod-tap trên phím chữ. Ngoại lệ duy nhất là phím NAV: giữ là tầng NAV, chạm riêng là
  Shift dính (từ 19/10/2026; trước đó mọi phím chỉ có một chức năng).
- **Chỉ dùng 36 phím.** Hai cột ngoài cùng không gán gì, ngón út không phải với ra. Ngoại
  lệ duy nhất là hai ô cột ngoài bên trái của Base, gửi `⌃4` và `⌃3` để chọn thẳng bộ gõ.
- **Base là DH-Việt y như trên MacBook.** Chữ nào ở ô nào của bàn phím MacBook thì ở đúng
  ô ấy trên Corne, vì cả hai cùng đi qua một bộ dịch của VTX. Ba dấu `,` `.` `/` không
  dời. `;` nằm ở hàng trên, cột trong của tay phải, nên `:` là ⇧ cộng ô đó.
- **⌘ ở ngón cái trái.** Tay phải cầm chuột chọn chữ thì tay trái vẫn tự copy được.
- **Shift cho cả hai tay, chéo tay.** Giữ ⇧ ngón cái phải để viết hoa chữ bên tay trái.
  Chạm phím NAV (ngón cái trái) rồi gõ để viết hoa chữ bên tay phải, `?` và `:`.
- **Phím tắt đi theo chữ DH-Việt.** VTX đổi địa chỉ mọi tổ hợp ⌘, ⌃, ⌥ sang ô mang chữ đó
  trên DH-Việt. ⌘C, ⌘V, ⌘Z vẫn nằm hàng dưới tay trái; ⌘X sang ngón út phải hàng trên.
- **Tầng NAV gánh gần hết:** tay trái di chuyển, tay phải là numpad. Ký hiệu là ⇧ ngón cái
  phải cộng phím số, như bàn phím thường.
- **Tầng thứ ba (FN) dùng ít nên không có phím riêng ở Base.** Giữ NAV rồi giữ thêm ngón
  trỏ trái ở hàng dưới, cột trong.

## Ba tầng

`·` là phím giữ nguyên như Base, `□` là ô trống.

**Tầng 0: Base**
```
 q     w     f     g     b     │   ;     l     u     y     x
 a     h     s     t     p     │   m     n     e     o     i
 j     v     r     c     z     │   k     d     ,     .     /
             ⌘   [NAV/⇧] Space │  Bksp   ⇧    Enter
```
Cột ngoài bên trái có thêm `⌃4` (hàng trên) và `⌃3` (hàng chủ).

Phím NAV có hai việc:
- **Giữ** là tầng NAV. Giữ NAV rồi bấm và nhả một phím (số, mũi tên, `⌘Tab`) thì firmware
  quyết là giữ ngay, không chờ. Riêng khi giữ NAV rồi giữ luôn một mũi tên để chạy liên
  tục, mũi tên chờ 200 ms mới bắt đầu.
- **Chạm riêng** (ấn rồi nhả, không bấm gì khác) là Shift dính: chữ gõ tiếp theo ra hoa.
  Chạm nhầm thì chữ sau bị hoa, thấy ngay.

**Tầng 1: NAV** (giữ bằng ngón cái trái)
```
 Esc   [     ↑     ]     Tab   │   /     7     8     9     -
 ⌘     ←     ↓     →     ⌘Tab  │   *     4     5     6     +
 ⇧     (     )     ⌘⇧4   [FN]  │   =     1     2     3     .
             ·    [giữ]  ·     │  XoáTừ  0    ⇧Enter
```
- Tay phải là numpad, `4 5 6` nằm ngay hàng chủ, `0` ở ngón cái phải. Cột phía trong là
  `/` `*` `=`, cột ngón út là `-` `+` và dấu chấm thập phân.
- Ký hiệu trên phím số cần ⇧, mà ⇧ ngón cái phải đang là số `0` ở tầng này, nên dùng ⇧
  ngón út trái: `! @ # $ % ^ &` từ phím số, `_` từ `-`, `{ }` từ `[ ]`. `( )`, `*` và `+`
  có ô riêng.
- `⌘Tab` là một ô gửi thẳng tổ hợp, để quay về app vừa dùng bằng một nhịp. Tab trần nằm
  ngay phía trên.
- ⌘ và ⇧ ở ngón út trái là phím thường, dùng khi ngón cái đang bận giữ NAV: ⌘ cộng Tab
  để đi qua từng app, ⌘ cộng `←` `→` về đầu và cuối dòng, ⇧ cộng mũi tên để bôi chọn.
- `⌘⇧4` là nút chụp một vùng màn hình. Các kiểu chụp khác mở bằng ⌘⇧5 (Spotlight hoặc
  ⇧ cộng số).
- `⇧Enter` nằm đúng chỗ Enter và Xoá từ (⌥⌫) nằm đúng chỗ Bksp. Muốn xoá một chữ số thì
  nhả NAV trước.
- Esc và Tab chỉ có ở tầng này.

**Tầng 2: FN** (giữ NAV, rồi giữ thêm ngón trỏ trái ở hàng dưới, cột trong)
```
 □     □     □     □     □     │   :     □    Sáng− Sáng+ BTxoá
 □     □     □     □     □     │   □    Mute  Vol−  Vol+  Play
 □     □     □     □    [giữ]  │  ⌃C     ?     '     "     □
             ·     ·     ·     │   ·     ·     ·
```
- Mọi ô dùng được đều ở tay phải, vì tay trái đang giữ hai phím tầng.
- `⌃C` là một ô gửi thẳng ⌃C để ngắt lệnh trong terminal.
- `?` có ô riêng (`&kp LS(SLASH)`) vì ở Base nó là ⇧ ngón cái phải cộng út phải, cùng một
  tay, mà được gõ hơn 100 lần mỗi ngày.
- `'` và `"` là hai ô riêng vì ở tầng này không với được ⇧ nào: ⇧ ngón cái phải rơi xuống
  thành số `0` của NAV, còn ⇧ ngón út trái là ô trống.
- `:` nằm đúng ô của `;` ở Base, cho lúc tay trái đang giữ sẵn hai phím tầng. Cách thường
  dùng vẫn là ⇧ cộng `;` ở Base.
- `BTxoá` (Bluetooth, Clear Selected Profile) xoá ghép nối của profile đang dùng. Đây là ô
  Bluetooth duy nhất còn lại; nó nằm ở ngón út hàng trên cho khó chạm nhầm.

## Các tổ hợp hay dùng

| Tổ hợp | Cách bấm |
|---|---|
| Viết hoa chữ tay trái | Cái phải giữ ⇧, tay trái gõ chữ |
| Viết hoa chữ tay phải | Chạm NAV (cái trái) rồi gõ chữ |
| ⌘⇧ đổi bộ gõ | Cái trái ⌘, cái phải ⇧ |
| ⌘⇧C, ⌘⇧V | Hai ngón cái giữ ⌘ và ⇧, trỏ trái bấm c hoặc áp út trái bấm v, đều ở hàng dưới |
| ⌘C, ⌘V, ⌘Z một tay | Cái trái ⌘, tay trái bấm chữ ở hàng dưới: v áp út, c trỏ, z trỏ vươn vào trong |
| ⌘X | Cái trái ⌘, út phải bấm x ở hàng trên |
| `:` | Chạm NAV, rồi trỏ phải bấm `;` ở hàng trên phía trong |
| `?` ở Base | Chạm NAV, rồi út phải bấm `/` |
| `'` `"` `:` qua FN | Giữ NAV và FN bằng tay trái; giữa và áp út phải bấm hàng dưới ra `'` `"`, trỏ phải bấm hàng trên phía trong ra `:` |
| ⌘Tab một nhịp | Giữ NAV, trỏ trái bấm ô `⌘Tab` ở hàng chủ |
| ⌘Tab qua nhiều app | Giữ NAV, út trái giữ ⌘, trỏ trái bấm Tab ở hàng trên nhiều lần |
| ⇧Enter | Giữ NAV, cái phải bấm Enter |
| ⌘Enter | Cái trái ⌘, cái phải Enter |
| Số | Giữ NAV, tay phải bấm numpad |
| Ký hiệu trên phím số | Giữ NAV, út trái giữ ⇧, bấm số |
| `(` `)` | Giữ NAV, áp út hoặc giữa trái bấm hàng dưới |
| `/` `*` `=` và `-` `+` | Giữ NAV, trỏ phải bấm cột phía trong, út phải bấm cột ngoài |
| Chụp một vùng màn hình | Giữ NAV, trỏ trái bấm ô `⌘⇧4` ở hàng dưới |
| Xoá từ | NAV + Bksp |
| Âm lượng, độ sáng | Giữ NAV và FN bằng tay trái, tay phải bấm một ô |
| ⌃C | Giữ NAV và FN bằng tay trái, trỏ phải vươn vào cột trong ở hàng dưới |
| `?` | Giữ NAV và FN bằng tay trái, trỏ phải bấm hàng dưới; hoặc ở Base, ⇧ cộng `/` |

Chưa có chỗ: `` ` `` và `~`, `\` và `|`, nhảy từng từ (⌥ cộng mũi tên), ⌃ và
⌥ cộng một chữ (trừ ⌃C), và ⌃ cộng mũi tên để đổi desktop, vì bàn phím không còn phím ⌃
hay ⌥ trần.

## Chi tiết cần nhớ khi viết firmware

- **Firmware gửi mã phím QWERTY, VTX chế độ Colemak dịch sang DH-Việt.** Tầng Base trong
  `corne.keymap` và trong ZMK Studio vì vậy vẫn hiện QWERTY, khác với hình vẽ ở trang này.
  Bảng dưới cho biết ô nào trong firmware ra chữ nào.
- **Ô `⌃C` phải là `&kp LC(V)`, không phải `&kp LC(C)`.** VTX đổi địa chỉ cả tổ hợp ⌃ theo
  DH-Việt, mà mã phím `C` trên DH-Việt là chữ `r`, nên `LC(C)` ra ⌃R. Mã phím `V` mới là
  chữ `c`. Khi VTX ở chế độ Telex
  hoặc khi cắm máy khác thì ô này ra ⌃V.
- **Ô `:` ở tầng FN phải là `&kp LS(Y)`, không phải `&kp COLON`,** cùng lý do: `;` của
  DH-Việt nằm ở mã phím `Y`, còn mã phím `;` là chữ `i`, nên `COLON` ra chữ `I` hoa. Ở chế
  độ Telex hoặc trên máy khác ô này ra `Y`. Hai ô `'` và `"` là `&kp SQT` và `&kp DQT`,
  không phụ thuộc layout.
- Ô ra thẳng một tổ hợp là phím gốc kèm modifier: `+` là `&kp LS(EQUAL)`, `*` là
  `&kp LS(N8)`, `⌘Tab` là `&kp LG(TAB)`, `⇧Enter` là `&kp LS(RET)`, chụp màn hình là
  `&kp LG(LS(N4))`, ngoặc đơn là `&kp LPAR` và `&kp RPAR`. ZMK Studio gán được kiểu này bằng cách chọn phím
  rồi tích thêm modifier, nhưng mặt phím trong Studio chỉ hiện phím gốc: hai ô Tab trông
  giống nhau, và ô `⌃C` hiện chữ `V`.
- Phím FN là `&mo 2` đặt trong tầng NAV, không có ở Base. Các ô trống của tầng FN là
  `&none`, để lỡ chạm không ra số của tầng NAV.
- Phím NAV ở Base là `&nav_shift 1 LSHFT`, một hold-tap tự định nghĩa trong
  `corne.keymap`: flavor `balanced`, `tapping-term-ms` 200, giữ là `&mo 1`, chạm là
  `&sk LSHFT`. ZMK Studio không tạo được hành vi này, nên đổi nó phải sửa file và build
  lại; Studio vẫn gán được nó cho ô khác vì firmware đã có sẵn.
- Corne không có hàng số, và macOS không tự đổi F1–F12 của bàn phím rời thành phím
  media. Vì vậy độ sáng, âm lượng và play phải là keycode riêng ở tầng FN.

### Mã phím firmware và chữ ra trên DH-Việt

Hàng trên của mỗi cặp là mã phím trong firmware, hàng dưới là chữ VTX cho ra.

```
 Q W E R T │ Y U I O P        A S D F G │ H J K L ;        Z X C V B │ N M , . /
 q w f g b │ ; l u y x        a h s t p │ m n e o i        j v r c z │ k d , . /
```

Các ký hiệu, số và mũi tên của tầng NAV không đổi: DH-Việt chỉ dời chữ và dấu `;`.

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

## Đo phím nào dùng nhiều

Trước khi dời một phím hay một tổ hợp sang chỗ khác, xem nó được bấm bao nhiêu lần. VTX có
bộ đếm ở Cài đặt → Thử nghiệm → **Đếm phím** (mặc định tắt). Bật lên, dùng máy vài ngày,
rồi bấm **Chép bảng thống kê**: bảng liệt kê phím tắt có ⌘ ⌃ ⌥, các phím riêng và ký hiệu
(Enter, ⌫, `⇧;`, `⇧/`…), và số lần nhấn từng modifier bên trái, bên phải, kèm trung bình
mỗi ngày.

- Bộ đếm thấy phím của mọi app và mọi bộ gõ, kể cả ABC. Ở chế độ VTX Colemak, nhãn là chữ
  DH-Việt chứ không phải chữ in trên phím.
- Chỉ lưu số lần theo ngày, không lưu thứ tự hay nội dung gõ. Phím gõ trong ô mật khẩu
  không được đếm. Phím do phần mềm phát ra (PasteMe dán, remote desktop) cũng không.
- Một ô gửi cả tổ hợp trên Corne (`⌘⇧4`, `⌘Tab` ở NAV) được đếm như tổ hợp đó.
- Số liệu nằm ở `~/Library/Application Support/VietTelex/key-usage.json`. Muốn xoá thì
  dùng nút Xoá trong Cài đặt; xoá file bằng tay thì VTX ghi lại từ bộ nhớ.

## Bảng tầng phím trên màn hình

Trong lúc chưa thuộc NAV và FN, VTX ghim được một sơ đồ nhỏ của hai tầng ở góc dưới phải
màn hình: Cài đặt → Thử nghiệm → **Tầng phím** (mặc định tắt). Bật tắt nhanh thì dùng dòng
**Bảng tầng phím** trong menu VTX trên menu bar. Bảng kéo đi chỗ khác được và nhớ chỗ đã kéo; nó
không lấy focus của app đang gõ, nhưng che chuột với thứ nằm bên dưới.

- Bảng luôn hiện chứ không bật theo phím NAV. Phím tầng (`&mo`) được xử lý trong firmware
  và không gửi gì về máy, nên VTX không biết lúc nào nó đang được giữ. Muốn bảng chỉ hiện
  lúc giữ NAV thì firmware phải gửi kèm một phím báo hiệu, việc đó cần build lại firmware.
- Sơ đồ là bản chép tay ở `~/Library/Application Support/VietTelex/layer-hud.json`, VTX tạo
  file này lần đầu bật. Đổi ô trong ZMK Studio thì sửa file rồi tắt và bật lại mục Tầng
  phím. Mỗi tầng có ba hàng 10 ô và một hàng 6 ô ngón cái; file lệch số ô thì VTX vẽ sơ đồ
  dựng sẵn và để nguyên file.

## Thay đổi ngày 12/10/2026 và số liệu dẫn tới nó

Dựa trên một ngày số liệu (12/10/2026, 21.849 lần nhấn trên MacBook). Đang dùng thử, sẽ
xem lại khi có thêm vài ngày đo.

| Phím | Lần/ngày | Trên Corne trước khi đổi |
|------|---------:|--------------------------|
| Tab (201 trong `⌘Tab`, 50 trần) | 251 | Chỉ có ở NAV; `⌘Tab` là ba phím |
| Enter trần | 249 | Ngón cái phải |
| `⇧Enter` | 63 | ⇧ và Enter cùng ở ngón cái phải, không bấm được |
| `;` và `:` | 20 | Một ô ở tầng Base |

⌘ trái được nhấn 473 lần và có 468 phím bấm kèm ⌘, tức mỗi lần giữ ⌘ gần như chỉ đi với
một phím. `⌘Tab` vì vậy hầu hết là một nhịp để quay về app vừa dùng, và một ô gửi thẳng
`⌘Tab` phủ được gần hết.

Đã đổi trên bàn phím:

- Ô Tab ở hàng chủ của NAV thành `⌘Tab`; Tab trần dời lên ô phía trên, thay `` ` ``.
- Ô ngón cái phải ngoài cùng của NAV thành `⇧Enter`, thay phím vào FN.
- Phím vào FN dời về ô `⌃C` cũ (hàng dưới, cột trong tay trái).
- `⌃C` sang tầng FN, ngón trỏ phải hàng dưới.

Không đổi `;` ở Base lấy Tab dù số liệu ủng hộ: Base phải giống MacBook.

## Thay đổi ngày 19/10/2026 và số liệu dẫn tới nó

Số liệu 8 ngày (12–19/10/2026, 360.574 lần nhấn, gộp MacBook và Corne):

| Phím | Lần/ngày | Ghi chú |
|------|---------:|---------|
| ⌘ trái | 556 | ⌘V 90, ⌘W 60, ⌘A 36, ⌘C 35: hầu hết là chữ tay trái |
| ⇧ trái | 380 | Trên MacBook người gõ bấm ⇧ chéo tay, nghiêng về ⇧ trái vì ⇧ phải khó với |
| ⇧ cộng chữ | 167 | |
| `?` / `⇧Enter` / `:` | 61 / 58 / 28 | `?` và `:` là ⇧ ngón cái phải cộng phím tay phải |
| `⌘⇧4` / `⌘⇧2` / `⌘⇧3` | 43 / 1 / 0 | |
| `(` + `)` | 13,5 | Trước đó cần NAV + ⇧ út trái + số |
| ⌥ trái / ⌃ trái | 1 / 6,6 | ⌥ hoặc ⌃ cộng chữ gần như không có |

Corne chỉ có một ⇧ (ngón cái phải), nên chữ hoa bên tay phải phải bấm cùng tay. Đã cân
nhắc home row mod và bỏ: nó chặn ⌘ một tay trái (luật chéo tay chặn ⌘V, ⌘W, ⌘C) và làm
mọi chữ hàng nhà ra lúc nhả phím, trong khi thứ duy nhất nó thêm được là ⌥ và ⌃ cộng chữ,
gần như không dùng. Nhảy từng từ (⌥ cộng mũi tên) cũng không làm: người gõ chưa từng dùng.

Đã đổi:

- Phím NAV ở Base: chạm riêng là Shift dính. Đây là phím chạm/giữ đầu tiên của keymap.
- Hai ô `⌘⇧2` `⌘⇧3` ở NAV thành `(` và `)`.

Sau một tuần dùng, xem lại `⇧Space` (14/ngày) và `⇧⌫` (10/ngày) trong bộ Đếm phím: hai số
này tăng nghĩa là Shift dính đang bị chạm nhầm trước Space hoặc Bksp.
