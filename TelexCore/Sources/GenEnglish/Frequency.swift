// gen-english --frequency — sinh bảng EnglishDominant: từ tiếng Anh mà Telex gõ ra
// một âm tiết Việt hợp lệ, nhưng tiếng Anh phổ biến hơn HẲN và từ Việt đó hiếm.
//
// Điểm = 10·log10(số lần trên một triệu từ), lấy từ FrequencyWords (Hermit Dave,
// OpenSubtitles 2018, CC BY-SA 4.0). Một từ vào bảng khi:
//   - phím raw là một từ tiếng Anh thật (đã lọc bằng trình kiểm chính tả macOS),
//   - engine mặc định gõ nó thành chữ CÓ DẤU khác raw (gõ đúp để bỏ dấu không tính),
//   - từ Việt đó dưới ngưỡng phổ biến `vnFloor` (từ Việt thông dụng không bao giờ bị lật),
//   - điểm tiếng Anh hơn điểm tiếng Việt ít nhất `prefer` (10 = gấp 10 lần),
//   - từ Việt đó không nằm trong protect-list (chính sách 23/07: từ Việt thật thắng).
//
// Chạy (từ thư mục TelexCore):
//   cut -d' ' -f1 en_50k.txt | grep -E '^[a-z]{2,12}$' | spellfilter > en_spell_ok.txt
//   swift run gen-english --frequency en_50k.txt vi_50k.txt en_spell_ok.txt \
//       Sources/TelexCore/EnglishDominant.swift [dump.tsv]
// spellfilter: đọc stdin, in các từ NSSpellChecker (en) chấp nhận.
import Foundation

let frequencyPrefer = 10
let frequencyVnFloor = 10

/// Đọc file "từ số_lần" của FrequencyWords → điểm 10·log10(per million).
func frequencyScores(_ path: String) -> [String: Int] {
    guard let text = try? String(contentsOfFile: path, encoding: .utf8) else {
        FileHandle.standardError.write("cannot read \(path)\n".data(using: .utf8)!)
        exit(1)
    }
    var counts: [(String, Double)] = []
    var total = 0.0
    for line in text.split(separator: "\n") {
        let parts = line.split(separator: " ")
        guard parts.count == 2, let c = Double(parts[1]) else { continue }
        counts.append((String(parts[0]).lowercased(), c))
        total += c
    }
    var scores: [String: Int] = [:]
    for (w, c) in counts where scores[w] == nil {
        scores[w] = Int((10 * log10(c / total * 1_000_000)).rounded())
    }
    return scores
}

@MainActor func runFrequency(_ args: [String]) {
    guard args.count >= 6 else {
        FileHandle.standardError.write(
            "usage: gen-english --frequency <en_50k> <vi_50k> <en_spell_ok> <out.swift> [dump.tsv]\n"
                .data(using: .utf8)!)
        exit(1)
    }
    let en = frequencyScores(args[2])
    let vi = frequencyScores(args[3])
    guard let okText = try? String(contentsOfFile: args[4], encoding: .utf8) else { exit(1) }
    let realEnglish = Set(okText.split(separator: "\n").map { String($0) })

    var kept: [String] = []
    var dump = "raw\ten\tcomposed\tvn\tdecision\n"
    for (w, enScore) in en.sorted(by: { $0.value > $1.value }) {
        guard realEnglish.contains(w), w.count >= 2, w.count <= 12,
              w.allSatisfy({ $0.isASCII && $0.isLetter }) else { continue }
        if junk.contains(w) || (w.count == 2 && !twoLetterWhitelist.contains(w)) { continue }
        let out = commitDefault(w)
        guard out != w, !out.allSatisfy({ $0.isASCII }) else { continue }
        let vnScore = vi[out.lowercased()] ?? -1000
        let decision: String
        if protected.contains(out) {
            decision = "protected"
        } else if vnScore >= frequencyVnFloor {
            decision = "vn-common"
        } else if enScore - vnScore < frequencyPrefer {
            decision = "tie"
        } else {
            decision = "english"
            kept.append(w)
        }
        dump += "\(w)\t\(enScore)\t\(out)\t\(vnScore == -1000 ? "-" : String(vnScore))\t\(decision)\n"
    }
    kept.sort()

    var src = """
    // EnglishDominant.swift — SINH TỰ ĐỘNG bởi `gen-english --frequency`, ĐỪNG SỬA TAY.
    // Từ tiếng Anh mà Telex gõ ra âm tiết Việt hợp lệ, nhưng tiếng Anh phổ biến hơn
    // ít nhất \(frequencyPrefer / 10) bậc độ lớn và từ Việt đó hiếm (dưới \(frequencyVnFloor) điểm). Khôi phục về
    // tiếng Anh ngay cả khi "Ưu tiên tiếng Việt". Tần suất: FrequencyWords (Hermit Dave,
    // OpenSubtitles 2018, CC BY-SA 4.0). Cách sinh lại: GenEnglish/Frequency.swift.
    enum EnglishDominant {
        /// Sorted ascii, lowercase. \(kept.count) từ, tra Set ở boundary (không trên hot path).
        static let words: Set<String> = {
            var set = Set<String>(minimumCapacity: \(kept.count))
            for token in list.split(whereSeparator: { $0 == " " || $0 == "\\n" }) {
                set.insert(String(token))
            }
            return set
        }()

        private static let list = \"\"\"

    """
    for chunk in stride(from: 0, to: kept.count, by: 8) {
        src += "        " + kept[chunk..<min(chunk + 8, kept.count)].joined(separator: " ") + "\n"
    }
    src += """
            \"\"\"
    }

    """
    try! src.write(toFile: args[5], atomically: true, encoding: .utf8)
    if args.count >= 7 { try! dump.write(toFile: args[6], atomically: true, encoding: .utf8) }
    print("english-dominant \(kept.count)")
}
