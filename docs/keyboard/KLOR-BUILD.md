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
- 2 pin LiPo 301230, 2 jack JST PH2.0 nằm ngang, 2 công tắc MSK12C02
  (jack: JST PH bước chân 2.0 mm, 2 chân, hàn xuyên lỗ, cắm ngang; mã S2B-PH-K-S
  hoặc bản tương đương. Dây đực đã có.)
- 14 đai ốc ép nhiệt M2 (ngoài 3.2, dài 3–4 mm), 14 ốc M2x12, 8 đệm cao su 10x2

LƯU Ý KHI LẮP
- Bẻ bỏ cột ngoài cùng và phím cái thứ 4 trước khi hàn.
- Bo điều khiển và jack pin hàn ở MẶT TRÊN PCB, linh kiện của bo úp xuống,
  nâng bo khoảng 6 mm để pin nằm bên dưới (khác build guide gốc).
- Đo cực pin bằng đồng hồ trước khi cắm, rồi hàn chập jumper đúng phía.
- KHÔNG lắp: OLED, encoder, LED, loa, rung, TRRS, nút reset.

VỊ TRÍ CẦN HÀN (mỗi nửa, theo tên trên iBOM rev 1.3)
- Diode + socket: D/SW 1–10, 12–16, 20–22 (18 phím). Bỏ 11, 17, 19 (nằm trên
  hai tab bẻ đi) và 18 (encoder).
- U1 (bo điều khiển), BT1 (jack pin JST), PSW1 (công tắc nguồn).
- Hai jumper BATT sát jack (JP22–25 trên iBOM): chập ở cùng mặt với jack. Trước
  khi cắm pin, kiểm dây đỏ nằm phía "+ RED".
- Không chập "LOST THUMB?" (JP26): nó chỉ nối lại chuỗi LED, mà bản này không có LED.
- Bỏ hết jumper còn lại (OLED, trackball, haptic) và BT2 (pad hàn pin trực tiếp;
  chỉ dùng nếu bỏ jack JST, khi đó cũng không cần jumper BATT).
