import Foundation

final class WordStore: ObservableObject {
    @Published var words: [Word] = []

    private let fileURL: URL
    private let retention: TimeInterval = 365 * 86400

    init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Rhythm", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("words.json")
        load()
        pruneOld()
    }

    func record(english: String, chinese: String, direction: Word.Direction,
                phonetic: String? = nil, senses: [WordSense]? = nil) {
        let key = english.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cn = chinese.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty, !cn.isEmpty else { return }

        if let idx = words.firstIndex(where: { $0.english.lowercased() == key }) {
            words[idx].lastSeen = Date()
            words[idx].lookupCount += 1
            if words[idx].chinese != cn { words[idx].chinese = cn }
            if let p = phonetic, !p.isEmpty { words[idx].phonetic = p }
            if let s = senses, !s.isEmpty { words[idx].senses = s }
            if words[idx].retired { words[idx].retired = false; words[idx].box = 1; words[idx].nextDueDate = Date() }
        } else {
            let now = Date()
            let w = Word(
                id: UUID(),
                english: key,
                chinese: cn,
                phonetic: phonetic,
                senses: senses,
                direction: direction,
                firstSeen: now,
                lastSeen: now,
                lookupCount: 1,
                box: 1,
                nextDueDate: now,
                lastReviewed: nil,
                retired: false
            )
            words.append(w)
        }
        persist()
    }

    func update(_ word: Word) {
        guard let idx = words.firstIndex(where: { $0.id == word.id }) else { return }
        words[idx] = word
        persist()
    }

    func remove(id: UUID) {
        let before = words.count
        words.removeAll { $0.id == id }
        if words.count != before { persist() }
    }

    /// Words due for review right now, oldest first (ones user hasn't reviewed recently).
    var dueWords: [Word] {
        words.filter { $0.isDue }
            .sorted { ($0.lastReviewed ?? .distantPast) < ($1.lastReviewed ?? .distantPast) }
    }

    /// Top N non-retired words sorted by lastReviewed ascending (never-reviewed first),
    /// regardless of Leitner due date — used for quick review from the translate card.
    func longestUnreviewed(limit: Int) -> [Word] {
        words.filter { !$0.retired }
            .sorted { ($0.lastReviewed ?? .distantPast) < ($1.lastReviewed ?? .distantPast) }
            .prefix(limit)
            .map { $0 }
    }

    func lookupCount(since: Date) -> Int {
        words.filter { $0.lastSeen >= since }.count
    }

    func reviewedCount(since: Date) -> Int {
        words.filter { ($0.lastReviewed ?? .distantPast) >= since }.count
    }

    var todayStart: Date { Calendar.current.startOfDay(for: Date()) }

    var todayLookupCount: Int { lookupCount(since: todayStart) }
    var weekLookupCount: Int  { lookupCount(since: Date().addingTimeInterval(-7 * 86400)) }
    var monthLookupCount: Int { lookupCount(since: Date().addingTimeInterval(-30 * 86400)) }

    var todayReviewedCount: Int { reviewedCount(since: todayStart) }
    var retiredCount: Int { words.filter { $0.retired }.count }

    private func pruneOld() {
        let cutoff = Date().addingTimeInterval(-retention)
        let before = words.count
        words.removeAll { $0.lastSeen < cutoff }
        if words.count != before { persist() }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(words) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Word].self, from: data) else { return }
        words = decoded
    }
}
