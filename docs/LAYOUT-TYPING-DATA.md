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

Thêm `--angle` để chấm lại theo kiểu bấm angle mod (xem mục "Ngón nào bấm phím C").
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
- **Ngón nào bấm phím C.** Mô hình của beartype và keybear gán mỗi cột cố định
  một ngón, nên phím C vật lý (chữ `r`) là ngón giữa và `tr` được xếp loại
  scissor. Nếu tay bấm angle mod kiểu chuẩn (phím Z áp út, X giữa, C và V trỏ)
  thì `tr` là **cặp cùng ngón**. Khi đó tỉ lệ cặp cùng ngón của DH-Việt lên
  **2,6%** thay vì 0,7%. Cần chốt câu hỏi này trước khi dùng `tr` làm lý do
  đổi chỗ `r`.
- Danh sách "hay gõ sai" xếp theo **số lần** sai, không theo tỉ lệ: một lần
  trượt trên cặp hiếm gặp đã là 100%.

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
  DH-angle là 5,9%). Nếu tính theo angle mod thì là 2,6%.
- Các cặp chậm đã chắc: `ie` (n=46, ×1,47), `tr` (n=30, ×1,40), `oi` (n=39,
  ×1,35), `ha` (n=47, ×1,24).
- Các cặp chậm nhưng chưa đủ mẫu: `lu` ×2,00, `ye` ×1,82, `no` ×1,67. Mỗi cặp
  mới có 6–8 lần đo.
- Lượt đo này chưa có dữ liệu gõ sai kiểu mới.

Lần chấm sau: nên đợi khoảng **40–50 bài**. Ghi thêm một mục vào đây, gồm ngày,
số bài và các cặp đổi thứ hạng.
