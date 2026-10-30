// PersonalLexicon.swift — the user's own vocabulary: how many times each word ended up
// on screen. The app fills it from its word counter (WordPracticeLog) and adds every
// word the counter records, so it learns while the user types.
//
// The engine consults it at the word boundary only, for an AMBIGUOUS word: the keys
// compose a valid Vietnamese syllable that differs from the keys themselves ("best" /
// "bét"). Whichever of the two the user has typed more often wins; with no evidence, or
// a tie, the built-in tables decide (EnglishCollisions, EnglishDominant). A built-in
// entry the user never types therefore changes nothing.
//
// Shared between the IMKit thread and the TerminalTap thread: every access takes the
// lock. Words are lowercase, exactly as the counter stores them.
import Foundation

public final class PersonalLexicon: @unchecked Sendable {
    public static let shared = PersonalLexicon()

    private let lock = NSLock()
    private var counts: [String: Int] = [:]

    public init() {}

    /// Replace everything (app launch, data cleared).
    public func replace(_ newCounts: [String: Int]) {
        lock.lock(); defer { lock.unlock() }
        counts = newCounts
    }

    /// One more occurrence of `word` (lowercase).
    public func add(_ word: String) {
        lock.lock(); defer { lock.unlock() }
        counts[word, default: 0] += 1
    }

    public func count(_ word: String) -> Int {
        lock.lock(); defer { lock.unlock() }
        return counts[word] ?? 0
    }

    /// Both counts under one lock: (keys read as English, Vietnamese composition).
    func counts(english: String, vietnamese: String) -> (Int, Int) {
        lock.lock(); defer { lock.unlock() }
        return (counts[english] ?? 0, counts[vietnamese] ?? 0)
    }
}
