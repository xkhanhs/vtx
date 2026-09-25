# Chấm DH-Việt bằng số đo gõ thật

Bố cục DH-Việt (`Scripts/make-dh-viet-layout.py`) được chốt bằng mô hình trên
corpus (keybear, `docs/dh_viet_layout.md`). Theo tài liệu đó, mọi tinh chỉnh
sau này phải chờ **dữ liệu gõ thật**. Tài liệu này ghi dữ liệu đó lấy từ đâu,
chấm ra sao, và mốc nào thì đủ để kết luận.

## Lấy dữ liệu

beartype là nơi tập gõ. Đo ở đó, còn quyết định layout thì ghi ở repo này. Sau
mỗi bài tiếng Việt, beartype ghi "sổ cú chuyển phím" riêng cho từng bố cục:

1. Màn kết quả → mở **tay chậm ở đâu** → chọn đúng bố cục đang gõ (trình duyệt
   không tự biết được).
2. Bấm **chép sổ** để lấy JSON vào clipboard.
3. Chạy lệnh:

```bash
pbpaste | ./Scripts/analyze-transition-book.py
```

Thêm `--top 20` nếu muốn xem danh sách dài hơn.

## Sổ ghi gì

Mỗi cặp (và bộ ba) phím Telex gõ liền nhau **trong cùng một từ** được lưu dạng
`gram: [seen, ms, timed, missed]`:

- `seen`: số lần gặp; `timed`: số lần có đo giờ; `ms`: tổng thời gian đo được;
  `missed`: số lần gõ sai.
- **Suy giảm 0,98 mỗi bài.** Trước khi cộng bài mới, sổ nhân mọi con số cũ với
  0,98. Vì vậy sổ chỉ nặng tối đa khoảng 50 bài: 15 bài ≈ 13,1, 30 bài ≈ 22,7,
  50 bài ≈ 31,8. Đi quá vài chục bài thì số mẫu tăng chậm lại, đổi lại sổ phản
  ánh tay của hiện tại.
- **Nhịp thường** là trung bình ms mỗi cú chuyển (bỏ các phím lặp như `dd`,
  `ee`). "×1,40" nghĩa là chậm hơn nhịp thường 40%. Chỉ nên so tỉ lệ này, vì ms
  tuyệt đối giảm dần theo tuần khi tay quen.
- **Gõ sai** (từ 24/09/2026, [xkhanhs/beartype#53](https://github.com/xkhanhs/beartype/pull/53)):
  được ghi vào cặp **định gõ**, tức phím trước cộng phím mà từ cần tiếp theo
  (chữ theo thứ tự, dấu thanh gõ cuối). Lần sai không tính giờ. Nếu gõ tiếp
  khi từ vẫn đang sai thì cả chuỗi chỉ tính một lần. **Sổ trước mốc này** ghi
  cặp (phím trước, phím lỡ bấm), vì vậy mới có các cặp như `nt`, `ih`, `tc`.
  Những cặp đó sẽ mờ dần theo hệ số suy giảm.

## Đọc cho đúng

- **Chỉ kết luận với cặp có n ≥ 20.** Script in dải tin cậy ±% cho từng cặp,
  giả định mỗi lần gõ lệch khoảng 50% quanh trung bình (sổ chỉ lưu tổng, không
  lưu độ lệch). Mức tương ứng: n=6 ±40%, n=20 ±22%, n=50 ±14%, n=100 ±10%.
- **Cặp mở đầu từ bị thổi phồng.** Thời gian từ phím 1 sang phím 2 có lẫn lúc
  đọc và lên kế hoạch cho cả từ. Các cặp phụ âm đầu + nguyên âm như `lu`, `no`,
  `ki`, `mi` đứng đầu danh sách chậm có thể vì lý do này chứ không phải do
  layout. Sổ chưa tách được yếu tố này.
- **Cặp nhanh bất thường (< 40 ms)** là do bấm gối hai phím gần như cùng lúc,
  không phải một cú chuyển tay thật. Ví dụ `nw` 28 ms.
- **Ngón bấm hàng dưới đã chốt (24/09/2026).** Mỗi cột một ngón trên mọi
  hàng, giống mô hình của beartype và keybear. Phím C vật lý (chữ `r` trên
  DH-Việt) bấm bằng ngón giữa, nên `tr` là cặp **chéo** (scissor), không phải
  cặp cùng ngón. Đừng chấm lại theo kiểu angle mod "phím C bấm ngón trỏ",
  vì tay người gõ không bấm như vậy.
- Danh sách "hay gõ sai" xếp theo **số lần** sai, không theo tỉ lệ: một lần
  trượt trên cặp hiếm gặp đã là 100%.

## Quyết định đang chờ: có đổi `v↔z` không

Từ 24/09/2026, người gõ tập DH-Việt hiện hành vài tuần rồi mới dựa vào số đo để
quyết có chuyển sang biến thể `v↔z` hay không. Biến thể này (beartype gọi là
"DH-Việt · v ở B") đưa `v` từ phím X vật lý (áp út trái) sang phím B (trỏ trái),
và `z` về phím X. Ngón bấm: đặt tay chuẩn QWERTY, `v` hiện gõ bằng áp út trái.
Ngoại lệ duy nhất là phím B vật lý, trên QWERTY người gõ hay bấm bằng tay phải;
cần hỏi lại tay nào nếu `v` về đó.

Đổi `v↔z` chỉ tác động tới hai loại cú chuyển; các cặp `v` + nguyên âm khác
(`vo`, `vi`, `vu`, `ve`) vẫn là đổi tay:

- `va`: đang là chéo (áp út dưới, út trên), sẽ thành cuộn ra;
- `vow` (`với`, `vợ`, `vở`): đang là sfs, vì `v` và `w` cùng áp út trái; sẽ
  thành đổi tay.

Để quyết, xem ba điểm khi sổ đã có 40–50 bài:

1. `va` và bộ ba `vow` đã có n ≥ 20 chưa, và có chậm hơn nhịp thường một cách
   chắc chắn không (script ghi "chắc", tức ×(1 − dải) > 1,1).
2. Các cặp `v` có nằm trong danh sách hay gõ sai không.
3. **Trần lợi ích nhỏ.** Ở mốc 15 bài, mọi cặp chứa `v` chỉ chiếm 2,3% số cú
   chuyển (×1,25). Kể cả khi đổi xong chúng nhanh bằng nhịp thường, mỗi bài chỉ
   lợi khoảng 90 ms trên khoảng 17 giây gõ, tức dưới 1%. Nếu (1) và (2) không
   nổi bật thì giữ bố cục hiện tại, không đáng tập lại tay.

Sổ chỉ đo bố cục đang gõ. Muốn so trực tiếp thì phải gõ biến thể thật (chế độ
giả lập của keybear, hoặc sinh bundle mới) trên một trang sổ riêng.

## Mốc đã đo

**24/09/2026: 15 bài** (sổ nặng 13,1 bài, ~116 cặp/bài, nhịp thường 144 ms,
dùng mô hình ngón của beartype):

| Loại cặp | Tỉ phần | ms | So thường |
|---|---|---|---|
| đổi tay | 51,5% | 123 | ×0,86 |
| cuộn vào | 14,3% | 150 | ×1,04 |
| cuộn ra | 26,8% | 170 | ×1,18 |
| scissor | 3,0% | 202 | ×1,41 |
| cùng ngón, phím kề | 0,7% | 255 | ×1,78 |

- Tỉ lệ cặp cùng ngón đo được là 0,7%, sát con số mô hình dự đoán (0,47%;
  DH-angle là 5,9%).
- Các cặp chậm đã chắc: `ie` (n=46, ×1,47), `tr` (n=30, ×1,40), `oi` (n=39,
  ×1,35), `ha` (n=47, ×1,24).
- Các cặp chậm nhưng chưa đủ mẫu: `lu` ×2,00, `ye` ×1,82, `no` ×1,67. Mỗi cặp
  mới có 6–8 lần đo.
- Lượt đo này chưa có dữ liệu gõ sai kiểu mới.

**25/09/2026: 40 bài** (sổ nặng 27,7 bài, ~121 cặp/bài, nhịp thường 146 ms,
~17 giây gõ mỗi bài, 3,8% cú chuyển gõ sai):

| Loại cặp | Tỉ phần | ms | So thường | Mốc 15 bài |
|---|---|---|---|---|
| đổi tay | 51,4% | 127 | ×0,87 | ×0,86 |
| cuộn vào | 13,2% | 152 | ×1,04 | ×1,04 |
| cuộn ra | 26,9% | 169 | ×1,16 | ×1,18 |
| scissor | 2,6% | 224 | ×1,54 | ×1,41 |
| cùng ngón, phím kề | 0,8% | 256 | ×1,75 | ×1,78 |

- Cơ cấu gần như không đổi so với mốc 15 bài; cặp cùng ngón vẫn 0,8%.
- Chậm đã chắc, n ≥ 20: `ye` (n=20, ×1,87, lên từ ×1,82 lúc n=6–8), `tr`
  (n=55, ×1,53, trước ×1,40), `ie` (n=78, ×1,49), `oi` (n=73, ×1,32). `ha` hạ
  xuống ×1,19. Bộ ba: `uye` (n=14, ×1,75, sfs ngón giữa phải), `tra` (n=20, ×1,51).
- `ye` và `uy` (×1,47) **không** phải cặp đầu từ, nên không đổ cho thời gian
  đọc được. Cụm `uy`/`ye` chỉ chiếm 1,1% cú chuyển nhưng tốn ~135 ms mỗi bài so
  với nhịp thường, gấp khoảng 4 lần mọi cặp chứa `v` cộng lại. `tr` là cặp đầu
  từ, nhưng `th` cũng đầu từ mà chỉ 131 ms (×0,90), nên phần chậm của `tr` là do
  cú chéo thật.
- `lu` ×1,82, `no` ×1,80, `ki` ×1,62, `lo` ×1,57 vẫn đứng đầu nhưng n=11–14,
  và đều là cặp mở đầu từ: chưa kết luận.
- Gõ sai kiểu mới đã có: `in` 10% (n=47), `ti` 9% (n=42), `au` 13%, `cu` 14%,
  `gh` 17%. Các cặp `ns` 78%, `cs` 84%, `acs`, `ans` là phụ âm cuối + dấu
  thanh; nghi là do gõ dấu trước phụ âm cuối (Telex vẫn nhận) mà beartype tính
  là sai. Chưa kiểm tra bên beartype.
- **`v↔z`: đề xuất giữ bố cục hiện tại.** (1) `va` n=20, 194 ms ×1,33 ±22%:
  chưa chắc; `vow` mới n=1,4 (`voi` n=6, 319 ms). (2) Không cặp `v` nào trong
  danh sách hay gõ sai; lỗi có chữ `v` (`nv`, `vy`, `vl`, `ev`) là sổ kiểu cũ.
  (3) Mọi cặp chứa `v` là 2,1% cú chuyển, ×1,10; kể cả `va` về bằng nhịp thường
  thì mỗi bài lợi ~35 ms / 17 s, khoảng 0,2%.

Lần chấm sau: sổ đã gần trần (~50 bài). Nếu còn muốn chỉnh thì nhìn vào vùng
`u`/`y`/`e` và `tr`, không phải `v`.
