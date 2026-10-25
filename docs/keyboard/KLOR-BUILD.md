# Lắp Klor bản không dây, 36 phím

Bản lắp tối giản nhất: chỉ có phím, bo điều khiển và pin. Mạch là Klor 1.4
(Gerber trong `~/Downloads/klor-gerbers-0.3mm.zip`). Build guide gốc của tác giả:
[GEIGEIGEIST/KLOR `docs/buildguide_3DP.md`](https://github.com/GEIGEIGEIST/KLOR/blob/main/docs/buildguide_3DP.md)
(bản có dây; bản BLE vỏ in 3D tác giả chưa viết).

Bản 1.4 là của fork [Lefuneste83/KLOR](https://github.com/Lefuneste83/KLOR) (logo
ElectronLab); hướng dẫn BLE gần nhất là `docs/buildguide_acrylic_ble.md` và
`FABNOTES.md` ở đó. So Gerber 1.3 với 1.4: viền mạch, vị trí switch, bo điều
khiển, tab bẻ và các jumper (BATT, LOST THUMB?) giữ nguyên; khác ở vị trí lỗ socket
hotswap, đường mạch, jack TRRS và encoder. Vì vậy build guide và iBOM của 1.3 dùng được.

LINH KIỆN
- 2 bo SuperMini nRF52840 (tương thích nice!nano v2)
- 36 socket hotswap Kailh MX, 36 diode 1N4148W SOD-123
  (socket: Kailh MX mã CPG151101S11, hai trụ cách nhau 6,35 mm. KHÔNG mua loại
  Choc / 1350 / low profile: chân cách nhau ~5 mm, không khớp mạch MX. Mua dư, ~40 cái.)
- 2 pin LiPo 301230 (dây trần, hàn thẳng lên mạch), 2 công tắc MSK12C02
- 14 đai ốc ép nhiệt M2 (ngoài 3.2, dài 3–4 mm), 14 ốc M2x12, 8 đệm cao su 10x2

LƯU Ý KHI LẮP
- Bẻ bỏ cột ngoài cùng và phím cái thứ 4 trước khi hàn.
- Socket hàn ở mặt dưới cùng diode: hai trụ tròn lọt vào lỗ mạch (mỗi cụm lỗ hình
  số 8 chỉ dùng một lỗ), hai lá kim loại nằm trên hai pad bạc. Lật socket thì không
  lọt lỗ nào, vậy là đúng chiều. Cắm thử một switch từ mặt trên trước khi hàn hàng loạt.
- Bo điều khiển hàn ở MẶT TRÊN PCB, linh kiện của bo úp xuống, nâng bo khoảng
  6 mm để pin nằm bên dưới (khác build guide gốc).
- Pin hàn thẳng vào hai lỗ BATT + và − (đỏ vào +, đen vào −), không dùng jack JST
  nên không chập jumper BATT. Hàn pin SAU CÙNG: khi bo điều khiển đã hàn và đã cắm
  USB thử đủ phím. Gạt công tắc nguồn về tắt, hàn từng dây một, không để hai đầu
  dây trần chạm nhau, không cắt hai dây pin bằng một nhát kìm.
- KHÔNG lắp: OLED, encoder, LED, loa, rung, TRRS, nút reset.

VỊ TRÍ CẦN HÀN (mỗi nửa, theo tên trên iBOM rev 1.3)
- Diode + socket: D/SW 1–10, 12–16, 20–22 (18 phím). Bỏ 11, 17, 19 (nằm trên
  hai tab bẻ đi) và 18 (encoder).
- U1 (bo điều khiển), PSW1 (công tắc nguồn), BT2 (hai lỗ BATT + và −, hàn dây pin).
- Không chập "LOST THUMB?" (JP26): nó chỉ nối lại chuỗi LED, mà bản này không có LED.
- Bỏ BT1 (chỗ jack JST) và jumper BATT cạnh nó (JP22–25), cùng mọi jumper còn lại
  (OLED, trackball, haptic).

FIRMWARE
- Repo [xkhanhs/zmk-config-klor](https://github.com/xkhanhs/zmk-config-klor): ZMK v0.3,
  shield `klor_left` / `klor_right` trên `nice_nano_v2` (SuperMini chạy firmware này).
  Keymap đi từ keymap Corne 36 phím, khác vài ô: xem [KLOR-LAYOUT.md](KLOR-LAYOUT.md).
  ZMK Studio bật ở nửa trái (sửa phím ở zmk.studio, Chrome, cắm USB nửa trái). Build bằng GitHub Actions khi đẩy lên repo.
- Ngón cái trái (ngoài → trong): ⌘ · NAV · Space. Phải (trong → ngoài): Bksp · ⇧ · Enter.
- Khớp chân bo: RAW vào BATT+, GND vào GND, RST vào RST; chân B+ và B− trên cùng của
  SuperMini không có lỗ, bỏ trống.
- Không có nút reset. Vào bootloader: chạm NAV (bật tầng NAV), giữ B (FN), rồi bấm phím góc trên trái
  (nạp nửa trái) hoặc góc dưới phải (nạp nửa phải). Không ăn thì nhíp chạm RST–GND
  hai lần. Ổ NICENANO hiện ra thì chép file `.uf2` của đúng nửa vào.
- Đổi keymap: chỉ nạp nửa trái. Đổi ma trận hay cấu hình bo: nạp cả hai, nửa phải
  trước. Nửa phải không gõ thẳng vào máy được; muốn thử phải có nửa trái đang chạy.
- Chép vào nửa phải macOS hay báo `Input/output error` dù bo vẫn khởi động lại; gõ thử
  để biết đã nạp chưa.

KIỂM TRA KHI LẮP (đã gặp)
- Phím không ra gì: rút switch, chạm nhíp hai lỗ socket. Ra phím là lỗi switch (chân
  cong); không ra thì so chiều diode với phím bên cạnh (phím W bị diode ngược), rồi
  nung lại pad socket.
- Ngón cái giữa là ⇧/NAV: giữ nó rồi gõ "a" ra "A" là phím chạy. Đừng thử bằng firmware mẫu của fork: ở đó phím này là LOWER, chạm không ra
  gì, nên switch hỏng ở đây đã lọt qua lần thử đầu.
