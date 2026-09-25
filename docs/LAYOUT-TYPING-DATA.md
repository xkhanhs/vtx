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

## Cặp chậm đang chờ đủ mẫu

Lập 25/09/2026, lấy từ mốc 40 bài. Khi chấm lại, so từng dòng với con số mới.

**Sổ có trần, nên có cặp không bao giờ tới n=20.** Ở 40 bài sổ nặng 27,7 bài.
Trần là 50, vậy mỗi cặp chỉ tăng được tối đa ×1,8 so với bây giờ. Cặp nào
đang dưới n≈11 thì gõ mãi cũng không chạm 20. Với những cặp đó, chấm theo
**nhóm** (mục dưới), đừng đợi từng cặp.

| Cặp | n lúc 40 bài | ms | So thường | Tới n=20 được? |
|---|---|---|---|---|
| `uy` | 16,3 | 215 | ×1,47 | được (~55 bài) |
| `mo` | 16,1 | 192 | ×1,32 | được (~55 bài) |
| `lo` | 14,4 | 229 | ×1,57 | được (~75 bài) |
| `ki` | 14,2 | 236 | ×1,62 | được (~75 bài) |
| `di` | 13,3 | 217 | ×1,49 | sát trần |
| `so` | 12,0 | 195 | ×1,34 | sát trần |
| `no` | 11,9 | 263 | ×1,80 | sát trần |
| `lu` | 11,0 | 266 | ×1,82 | sát trần |
| `eu` | 10,5 | 194 | ×1,33 | không |
| `ke` | 9,3 | 220 | ×1,51 | không |
| `be` | 9,2 | 237 | ×1,62 | không |
| `io` | 8,4 | 226 | ×1,55 | không |
| `te` | 7,5 | 240 | ×1,65 | không |
| `mi` | 6,9 | 223 | ×1,53 | không |
| `uj` | 6,7 | 218 | ×1,50 | không |
| bộ ba `uye` | 14,4 | 501 | ×1,75 | được (~75 bài) |

Đã chắc từ mốc 40 bài, chỉ cần xem có giữ không: `ye` ×1,87, `tr` ×1,53,
`ie` ×1,49, `oi` ×1,32, `va` ×1,33 (n=20, chưa chắc).

### Chấm theo nhóm: phụ âm ngón trỏ phải + nguyên âm tay phải

`l`, `m`, `n`, `k`, `d` đều nằm ở ngón trỏ phải. Khi theo sau là nguyên âm cùng
tay (`e u o i y`), 19 cặp gộp lại có n=174, 210 ms, **×1,44 ±8%**, tốn ~400 ms
mỗi bài (~2,4%). Đây là chi phí lớn nhất trong sổ. Cùng những phụ âm đó mà theo
sau là `a` (đổi tay: `ma` 97, `na` 102, `da` 106, `la` 116 ms) thì chỉ ×0,71.
Cả hai loại đều là cặp mở đầu từ, nên khác biệt này **không** do thời gian đọc
gây ra. Đó là giá của việc đặt năm phụ âm lên ngón trỏ phải, cạnh các nguyên âm.

## Nếu số đo vẫn như vậy thì có đổi không

Ước lượng thô, bằng cách phân loại lại các cặp trong sổ 40 bài với mô hình ngón
của script:

- **Nhóm ngón trỏ phải (~2,4%)**: không có phép đổi hai phím nào gỡ được. Muốn
  gỡ phải đưa phụ âm sang tay trái, tức là thiết kế lại bố cục.
- **`r↔v`** (`r` sang phím X vật lý, `v` sang phím C): `tr` và `va` từ scissor
  thành cuộn ra, `vow` hết sfs; đổi lại `ra` thành scissor. Lợi ~100 ms mỗi bài
  (~0,6%).
- **`i↔o`**: `oi` từ cuộn ra thành cuộn vào, lợi ~100 ms mỗi bài (~0,6%). Mô
  hình không phân biệt khoảng cách nên không biết `ie` có đỡ hơn không.
- **`uy`/`ye`**: `u` và `e` cùng cột nên `uye` là sfs. Gỡ được thì phải dời `u`
  hoặc `e`, hai phím quá nhiều việc. Không đáng.

Kết luận: không phép đổi nào vượt ~1%, cùng mức với `v↔z`. Đổi một phím nóng
như `r`, `i`, `o` phải tập lại tay vài tuần. **Giữ bố cục**, trừ khi lần chấm
sau có cặp mới vượt ~2% (tính như dòng "tốn … ms/bài" ở trên). Trước khi đổi
thật: chạy mô hình keybear, rồi gõ biến thể trên một trang sổ riêng.

## Mốc 40 bài: thiết kế lại thì ra sao (25/09/2026)

Câu hỏi: nếu không chỉ đổi hai phím mà thiết kế lại để gỡ nhóm ngón trỏ phải,
bố cục sẽ trông thế nào và lợi bao nhiêu. Đã chạy thử, kết quả dưới đây.
Hai script: `Scripts/fit-transition-book.py` (hồi quy sổ gõ thật theo đặc
điểm cú chuyển) và bộ dò swap của keybear (`scripts/layout-eval-vi.mjs`).
Bộ ủ (simulated annealing) trên hàm hồi quy là một lượt chạy tay, không đưa
vào repo; các bố cục nó tìm ra ghi nguyên ở đây.

### Điều sổ nói: tay phải chậm khi tự cuộn, không riêng ngón trỏ

Gộp theo nhóm, 40 bài:

| Cú chuyển | ms | n |
|---|---|---|
| tay phải, phụ âm → nguyên âm (`ne`, `lu`, `ki`…) | 212 | 193 |
| tay phải, nguyên âm → nguyên âm (`ie`, `oi`, `uy`, `ye`…) | 204 | 293 |
| tay phải, → `n m d k` (`on`, `en`, `in`…) | 121 | 217 |
| tay trái, phụ âm → phụ âm (`th`, `ch`, `tr`…) | 160 | 414 |
| tay trái, phụ âm → `a` (`ha`, `ta`, `ca`…) | 158 | 311 |
| đổi tay, phụ âm → nguyên âm (`ma`, `ho`, `vi`…) | 137 | 757 |
| đổi tay, nguyên âm → nguyên âm (`ua`, `ia`, `oa`) | 119 | 239 |

- Nguyên âm đôi gõ đổi tay (`ua`, `ia`, `oa`) nhanh nhất sổ, nên nguyên âm đôi
  cùng tay phải chậm **không** phải vì phải nghĩ Telex. Nó là tay.
- Tay phải cuộn cùng tay chậm hơn tay trái ~50 ms (204–212 so với 160), trừ
  khi cú chuyển đi **về phía ngón trỏ** (`on`, `in`: 121 ms).
- Hồi quy (R² = 0,69 trên 132 cặp) tách được các khoản không đổi theo bố cục:
  phím dấu thanh +41 ms, tới `e` +62 ms, sau `w` −45 ms (bấm gối). Phần bố
  cục: cùng tay +18, cùng ngón +20 và +33 mỗi đơn vị khoảng cách, scissor +37,
  tới út +21, tới áp út +18, cột giữa +12, và **tay phải phụ âm → nguyên âm
  +50, nguyên âm → nguyên âm +40** trên nền cùng tay.

### Ba cách thiết kế lại, và mô hình nói gì

Chấm mỗi bố cục bằng hai mô hình độc lập: hồi quy trên (có thêm phí từng phím
theo lưới keybear), và 12 mô hình của keybear (`layout-eval-vi.mjs`, thuần
corpus). Số là lợi so với bố cục hiện hành; dương = tốt hơn.

| Phương án | Phím dời | Hồi quy | keybear (trung vị, thắng/12) |
|---|---|---|---|
| Ủ tự do, phạt mỗi phím dời nặng | 8 | +8% | −0,5%, 3/12 |
| Ủ tự do, phạt nhẹ | 16 | +10% | −30%, 0/12 |
| Ủ tự do, không phạt | 26 | +11% | −25%, 0/12 |
| Tách tay: phụ âm trái, nguyên âm phải | 23 | +8% | −8%, 0/12 |

Bố cục 8 phím (chỉ để ghi lại, chưa gõ thử):

```
q w f g p · l u y x
t h s a j m n i o b
c v r e z k d
```

Nó đưa `e` sang tay trái để `ie ye ne le de` thành đổi tay, kéo `t` lên hàng
nhà út, `b` sang phải, `p` lên phím T.

**`p` ở T, ô Y trống** (chốt 25/09/2026). Bộ ủ đặt `p` ở Y vì `e` giờ ở phím
V, cùng ngón trỏ trái, nên `p` ở T biến `ep` (`đẹp tiếp sếp kịp`) và `ap`
thành cú nhảy cùng ngón hai hàng; mô hình chấm `p` ở T kém hơn (hồi quy +7,3%
so với +7,9%, keybear −5,1% so với −0,5%). Nhưng cả hai mô hình đều không
biết hàng trên lệch trái 0,25u: F→T ngón trỏ trái với ngang 0,75u, J→Y ngón
trỏ phải với 1,25u, Y là ô tệ nhất bàn phím. `p` chỉ 8‰, hai vế đều nhỏ, tay
người gõ chọn T. Kéo theo: ô trống vẫn ở Y như DH-Việt, bài `top-reach` của
giáo trình không đổi.

- **Tách tay không làm được** nếu giữ ràng buộc phím tắt: `s` và `r` phải ở
  nửa trái cho Cmd+S/Cmd+R, mà chúng là phím dấu thanh. Muốn tách phải bỏ
  ràng buộc ấy, và kể cả khi bỏ, tách tay dồn nguyên âm + dấu thanh lên tay
  phải, đẩy tỉ phần cùng tay phải từ 18,7% lên 24,2%: gỡ được nhóm ngón trỏ
  thì lại tạo nhóm khác trên đúng bàn tay chậm.
- **Hai mô hình cãi nhau ở mọi phương án dời trên 8 phím.** Hồi quy có số đo
  thật nhưng chỉ 132 cặp, R² 0,69, không có bộ ba; keybear có bộ ba và phí
  từng phím nhưng không biết tay phải chậm. Chỗ chúng bất đồng là chỗ mô hình
  ngoại suy ra ngoài dữ liệu. Dời 8–26 phím trên cơ sở đó là đánh cược.
- Phương án 8 phím là thứ duy nhất không bị keybear bác. Lợi hồi quy +8%
  (~1,2 giây trên 17 giây một bài) đổi lấy học lại 8 phím, trong đó có `t`,
  `e`, `a`, tức ba trong bảy phím nặng nhất.

### Kết luận

**Chưa thiết kế lại.** Số đo mới đủ để nói *tay phải cuộn chậm*, chưa đủ để
nói *đặt phím ở đâu thì hết chậm*. Hai việc rẻ hơn, làm trước:

1. Kiểm tra giả thuyết "là tay, không phải bố cục": gõ vài bài bằng bố cục
   khác (DH-angle, đã có sổ riêng trong beartype) và so nhóm "tay phải
   nguyên âm → nguyên âm" giữa hai sổ. Nếu vẫn ~200 ms thì bố cục nào cũng
   thế, và việc đáng làm là luyện tay phải chứ không phải dời phím.
2. Nếu vẫn muốn thử, gõ bố cục 8 phím trên chế độ giả lập của keybear với
   một trang sổ riêng, đủ 20 bài rồi chạy `fit-transition-book.py` lên cả
   hai sổ. Chỉ khi nhóm tay phải xuống dưới ~170 ms mới đáng sinh bundle.

### Cùng bảng với lúc chốt DH-Việt

Bốn bố cục, `scripts/layout-eval-vi.mjs` của keybear (lưới gốc, phạt d²), sổ
Zipf trên bảng từ của app như bảng trong `dh_viet_layout.md`. Effort không so
được với con số cũ (2,92 / 2,48 / 1,85: script cũ ngoài repo, trộn 1/11 tiếng
Anh); thứ hạng giữ nguyên.

| Bố cục | Effort | Cùng ngón | …nhảy xa | Hàng nhà | Út phải | Út trái | Đổi tay |
|---|---|---|---|---|---|---|---|
| QWERTY | 1,89 | 7,53% | 1,31% | 40% | 0,7% | 10,1% | 21,2% |
| Colemak-DH góc | 1,71 | 6,19% | 1,00% | 63% | 14,8% | 11,5% | 19,6% |
| DH-Việt | 1,60 | 0,67% | 0,00% | 64% | 8,3% | 12,6% | 23,3% |
| DH-Việt · 8 phím, `p` ở Y | 1,57 | 0,78% | 0,16% | 62% | 2,2% | 10,3% | 26,1% |
| DH-Việt · 8 phím, `p` ở T (chốt) | 1,57 | 1,18% | 0,26% | 62% | 2,2% | 10,3% | 25,3% |

Corpus OpenSubtitles cho cùng hình: effort 1,62 → 1,59, cùng ngón 0,85% →
1,27% (`p` ở T; 0,91% nếu `p` ở Y), út phải 7,3% → 2,4%, đổi tay 24,9% →
27,1%. Cặp nhảy xa cùng ngón mới
là `ej` (`mẹ kệ lệ để`): `e` ở V và `j` ở G cùng ngón trỏ trái, hai hàng.
DH-Việt hiện hành không có cặp nhảy xa nào; đây là cái giá rõ nhất của bản
8 phím trên mô hình corpus.

### Gõ thử bản 8 phím (25/09/2026)

Bố cục có trong beartype dưới tên **DH-Việt · 8 phím** (`dh-viet-8`, nhánh
`feat/dh-viet-8` bên keybear), gõ qua chế độ giả lập, sổ riêng
`keybear_colemak_ngrams__dh-viet-8`. Tắt VTX khi gõ giả lập.

Bốn mươi từ để va nhiều nhất vào chỗ đổi, dán vào ô "tự gõ từ" của màn tuỳ
chỉnh (chọn bằng script tham: mỗi từ phủ càng nhiều cặp đổi loại càng tốt,
cặp nặng `ha th ch ie oi` gặp 5–10 lần, cặp nhẹ 1–2 lần):

```
thách thạch chiến thiên trách thật triệu chuỗi phiền thằng
giỏi truyền phổi cách tất thế phá liệu và trắng
ném sách thuyết thôi các bà đẹp tác chiếc nếu
tên lỗi sạch bắt bé kết vật cá tách mẹ
```

Ba nhóm cảm giác cần để ý, mỗi nhóm một câu hỏi:

- `e` sang tay trái (`chiến`, `thiên`, `nếu`, `tên`, `kết`, `mẹ`): `ie` `ye`
  `ne` `ke` thành đổi tay. Có nhanh lên như `ua` `ia` không, hay `e` ở hàng
  dưới ngón trỏ trái lại thành cú với?
- `a` vào trỏ trái, `t` ra út (`thách`, `cách`, `tất`, `và`, `bà`): `ha th ch
  ta ca` đổi chiều cuộn; `th` bây giờ là út → áp út. Út trái có chịu nổi `t`
  49‰ không?
- `i` vào ngón giữa, `b` ra út (`giỏi`, `phổi`, `lỗi`, `thôi`, `bé`, `bắt`):
  `oi` thành cuộn vào. `ix` (`lỗi`) giờ là giữa → út, hết cùng ngón.

Ngưỡng đã ghi ở trên: nhóm "tay phải nguyên âm → nguyên âm" và "phụ âm →
nguyên âm" phải xuống dưới ~170 ms sau 20 bài thì mới đáng sinh bundle.
