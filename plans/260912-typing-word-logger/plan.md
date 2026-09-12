# Bộ ghi từ hay gõ (tạm thời, local, opt-in)

> Tính năng **tạm thời**, tắt mặc định, chỉ chạy local. Mục tiêu: gom danh sách
> **từ tiếng Việt kèm tần suất** người dùng gõ nhiều nhất, để đổ về **beartype**
> luyện đi luyện lại trên layout **Colemak‑DH‑Việt tuỳ biến** đang tập. Đủ mẫu →
> báo → xuất → luyện → **gỡ hẳn tính năng khỏi VTX**.

## Kết quả mong muốn (outcome)

- Một corpus `{từ: số_lần}` tích luỹ cục bộ, chỉ khi người dùng bật.
- Một **mốc mẫu** (ngưỡng tổng token). Đạt mốc → **thông báo hệ thống** một lần:
  "đã đủ mẫu, xuất top từ để luyện".
- Một **đường export**: ghi ra file `top‑N từ + tần suất` (giảm dần) để beartype nạp.
- Sau khi đã có danh sách, **gỡ bỏ toàn bộ tính năng** bằng revert sạch.

## Không làm (non-goals)

- Không đọc clipboard, không gửi mạng, không đồng bộ.
- Không log số, phím tắt/chord, gõ tắt (shortcut expansion), từ tràn (`overflowed`).
- Không log trong ô mật khẩu (vốn đã bị VTX chặn compose từ trước).
- Không đổi đường xử lý phím. Chỉ **quan sát read‑only** tại điểm từ đã chốt.
- Không viết importer phía beartype trong repo này (ghi rõ ở handoff, làm bên kia).

## Tiêu chí nghiệm thu (acceptance)

1. Toggle tắt mặc định; tắt thì không có bất kỳ ghi nào (không tạo file corpus).
2. Bật, gõ vài câu Việt xen Anh → corpus tăng đúng từ đã hiện trên màn, có dấu.
3. Gõ mật khẩu (ô native + web `type=password`) → **không** vào corpus.
4. Gõ `Cmd+C`, số `2026`, gõ tắt `vn`→ không vào corpus.
5. Đạt ngưỡng → nhận đúng **một** thông báo, không lặp mỗi phím sau đó.
6. Export ra file JSON `[{word,count}]` giảm dần, cắt top‑N.
7. `git revert` các commit tính năng → build xanh, không còn dấu vết, xoá file dữ liệu.

## Đầu ra cuối & vòng đời (điều người dùng thật sự cần)

```
bật (Thử Nghiệm)  →  gõ như thường vài ngày  →  đạt mốc mẫu  →  thông báo
      →  bấm "Xuất từ hay gõ…"  →  beartype-words.json  →  nạp vào sổ từ hay sai
      →  luyện top từ trên Colemak-DH-Việt  →  git revert (gỡ tính năng)  →  xoá file
```

## Điểm cắm chính xác (đã dò trong mã)

Cả hai đường commit của VTX đều đi qua một chỗ "một từ vừa chốt". Không hook tầng
`insertText` (nhiều đường rewrite/backspace) — hook đúng chỗ từ đã tính xong:

- **IMKit (mọi app thường, cả marked & in-place):**
  `App/Sources/TelexInputController.swift`, hàm `boundary(_ client:)` (~dòng 1555).
  Ngay trước mỗi `return true` của nhánh **auto‑restore**, biến `restored`
  (= `engine.commitText(...)`) **là từ cuối cùng** — tiếng Việt có dấu hoặc tiếng
  Anh đã khôi phục. Cắm: `WordLog.shared.note(restored)`.
  **Bỏ qua nhánh shortcut expansion** (không log `expansion`).

- **Terminal/iTerm:** `App/Sources/TerminalTap.swift` (~dòng 2885), nhánh
  `engine.commitBoundary(...)`. Từ hiển thị = `word` (composed, đã bắt trước
  `reset()`), hoặc `rawWord` khi kết quả là `.replace` (auto‑restore tiếng Anh).
  Cắm: log `rawWord` nếu `.replace`, ngược lại log `word`. Vẫn **bỏ qua** nhánh
  shortcut.

## Lọc (trong `WordLog.note`)

- Rỗng → bỏ.
- Chứa chữ số hoặc ký tự không phải chữ cái (kể cả dấu câu) → bỏ.
- Độ dài < 2 → bỏ (tuỳ chọn, giảm nhiễu "à", "ơ").
- Giữ nguyên **dấu tiếng Việt** (đây chính là đầu ra mong muốn). Chuẩn hoá
  thường hoá (lowercase) để `Trường`/`trường` gộp một khoá. Không gộp không‑dấu.
- Số/chord/gõ tắt/overflow: gần như **miễn phí** vì không tới điểm cắm dưới dạng
  `word`; các bộ lọc trên chỉ để chắc.

## Kiến trúc thành phần (mới, cô lập)

- `App/Sources/WordLog.swift` — singleton `WordLog.shared`:
  - `note(_:)` hot‑path an toàn: lọc → tăng đếm trong RAM.
  - Corpus `[String:Int]` + `totalTokens`.
  - Ghi **debounce** (vd 5s hoặc mỗi +200 token) ra
    `~/Library/Application Support/VietTelex/typing-corpus.json`.
  - `export(topN:to:)` → `[{word,count}]` giảm dần.
  - Kiểm mốc: `totalTokens >= target && !milestoneNotified` → bắn thông báo, set cờ
    (lưu cờ trong corpus để không lặp qua các lần chạy).
- `AppState.swift` — thêm `var logTypedWords: Bool` (UserDefaults‑backed, default
  `false`, theo đúng mẫu `autoRestore`). `note()` no‑op khi tắt.
- `SettingsWindow.swift` — mục **Thử Nghiệm**: 1 toggle "Ghi từ hay gõ (local, tạm
  thời)" + nút "Xuất từ hay gõ…" (NSSavePanel, mặc định `~/Downloads/beartype-words.json`).
- Hằng số: `typedWordSampleTarget` (mặc định — câu hỏi mở), `exportTopN`
  (mặc định — câu hỏi mở).

## Thông báo mốc

- `UNUserNotificationCenter` (fallback menu‑bar badge nếu chưa xin được quyền
  notification). Nội dung: "VietTelex: đã đủ mẫu từ hay gõ — mở Cài đặt để xuất."
- Bắn **đúng một lần**; cờ `milestoneNotified` lưu cùng corpus.

## Định dạng export (đổ về beartype)

`beartype-words.json`:
```json
[{ "word": "trường", "count": 812 }, { "word": "người", "count": 655 }]
```
Giảm dần theo `count`, cắt `exportTopN`. Bên beartype sẽ có importer nhỏ nạp vào
`miss-book.ts` (làm ở repo beartype, ngoài phạm vi plan này).

## Các phase (mỗi phase một commit, để revert sạch)

1. `feat(wordlog): WordLog store + toggle Thử Nghiệm (mặc định tắt)`
   - Thêm `WordLog.swift`, `AppState.logTypedWords`, toggle UI. Chưa cắm hook.
2. `feat(wordlog): cắm 2 điểm ghi từ đã chốt (IMKit + TerminalTap)`
   - Hai dòng `WordLog.shared.note(...)`. Test bằng gõ thử + đọc file corpus.
3. `feat(wordlog): mốc mẫu + thông báo một lần`
4. `feat(wordlog): export top‑N ra JSON cho beartype`
5. *(sau khi đã lấy đủ danh sách, ở lần dùng sau)* `revert` gọn 4 commit trên →
   xoá `WordLog.swift`, toggle, hook, và file `typing-corpus.json`.

## Kiểm thử

- Unit: `WordLog.note` lọc số/chord/rỗng/độ dài; đếm & top‑N đúng thứ tự; mốc bắn
  một lần. Đặt trong `AppTests/`.
- Tay: gõ Việt/Anh ở TextEdit (in‑place), Chrome omnibox (marked), Terminal
  (tap) → đọc `typing-corpus.json`. Ô mật khẩu native + web → không tăng.
- Regression VTX phải xanh (không đụng đường phím).

## Rủi ro & giới hạn

- **Chỉ bắt khi VTX ở chế độ tiếng Việt.** ⌃Space sang chế độ Anh/passthrough →
  không log. Chấp nhận được cho mục tiêu (đa phần gõ ở chế độ Việt).
- Corpus là **mọi từ đã gõ** (trừ mật khẩu). Dù local, coi như dữ liệu nhạy cảm:
  không sync iCloud/backup thư mục này khi đang bật; xoá file khi gỡ.
- Trái với claim README "không thu thập dữ liệu" — giảm thiểu bằng: opt‑in, tắt
  mặc định, local‑only, tạm thời, và gỡ hẳn sau khi xong.
- Ghi file phải off hot‑path (debounce + queue nền), không chặn gõ.

## Quyết định (đã chốt)

1. **Mốc mẫu = tổng token**, mặc định `typedWordSampleTarget = 20000`.
2. **`exportTopN = 500`**.
3. **Gộp hoa/thường** thành một khoá (lowercase khi đếm). **Không** gộp không‑dấu —
   giữ nguyên dấu tiếng Việt.
4. Giữ vị trí file như đề xuất: corpus
   `~/Library/Application Support/VietTelex/typing-corpus.json`, export mặc định
   `~/Downloads/beartype-words.json`.
