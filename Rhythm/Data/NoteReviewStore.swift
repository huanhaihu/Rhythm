import Foundation

final class NoteReviewStore: ObservableObject {
    @Published var reviews: [String: Bool] = [:]

    private let fileURL: URL
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Rhythm", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("note_reviews.json")
        load()
    }

    var todayKey: String { formatter.string(from: Date()) }

    var todayReviewed: Bool {
        get { reviews[todayKey] ?? false }
        set { reviews[todayKey] = newValue; persist() }
    }

    func isReviewed(_ date: Date) -> Bool {
        reviews[formatter.string(from: date)] ?? false
    }

    var currentStreak: Int {
        var streak = 0
        var day = Date()
        while true {
            let key = formatter.string(from: day)
            guard reviews[key] == true else { break }
            streak += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    var totalCount: Int { reviews.values.filter { $0 }.count }

    var monthReviewCount: Int {
        let cal = Calendar.current
        let now = Date()
        return reviews.filter { key, val in
            guard val, let date = formatter.date(from: key) else { return false }
            return cal.isDate(date, equalTo: now, toGranularity: .month)
        }.count
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(reviews) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) else { return }
        reviews = decoded
    }
}
