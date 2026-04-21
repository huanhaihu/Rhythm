import Foundation

final class ThoughtStore: ObservableObject {
    @Published var thoughts: [String: DailyThought] = [:]

    private let fileURL: URL
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()
    private let monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f
    }()

    init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Rhythm", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("thoughts.json")
        load()
    }

    var todayKey: String { dayFormatter.string(from: Date()) }

    var todayThought: DailyThought? { thoughts[todayKey] }

    var hasThoughtToday: Bool {
        guard let t = thoughts[todayKey] else { return false }
        return !t.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func isRecorded(_ date: Date) -> Bool {
        guard let t = thoughts[dayFormatter.string(from: date)] else { return false }
        return !t.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func thought(for date: Date) -> DailyThought? {
        thoughts[dayFormatter.string(from: date)]
    }

    func saveToday(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            thoughts.removeValue(forKey: todayKey)
            persist()
            return
        }
        let now = Date()
        if var existing = thoughts[todayKey] {
            existing.text = trimmed
            existing.updatedAt = now
            thoughts[todayKey] = existing
        } else {
            thoughts[todayKey] = DailyThought(text: trimmed, createdAt: now, updatedAt: now)
        }
        persist()
    }

    func clearToday() {
        thoughts.removeValue(forKey: todayKey)
        persist()
    }

    var currentStreak: Int {
        var streak = 0
        var day = Date()
        while true {
            let key = dayFormatter.string(from: day)
            guard let t = thoughts[key],
                  !t.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { break }
            streak += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    var totalCount: Int {
        thoughts.values.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var monthRecordCount: Int {
        let cal = Calendar.current
        let now = Date()
        return thoughts.filter { key, val in
            guard !val.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let date = dayFormatter.date(from: key) else { return false }
            return cal.isDate(date, equalTo: now, toGranularity: .month)
        }.count
    }

    func entries(inMonth monthKey: String) -> [(date: String, thought: DailyThought)] {
        thoughts
            .filter { key, val in
                key.hasPrefix(monthKey + "-") &&
                !val.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            .map { (date: $0.key, thought: $0.value) }
            .sorted { $0.date < $1.date }
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(thoughts) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([String: DailyThought].self, from: data) {
            thoughts = decoded
        }
    }
}
