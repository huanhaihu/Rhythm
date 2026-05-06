import Foundation

final class CheckinStore: ObservableObject {
    @Published var checkins: [String: Bool] = [:]

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
        fileURL = dir.appendingPathComponent("checkins.json")
        load()
    }

    var todayKey: String { formatter.string(from: Date()) }

    var todayChecked: Bool {
        get { checkins[todayKey] ?? false }
        set { checkins[todayKey] = newValue; persist() }
    }

    func isChecked(_ date: Date) -> Bool {
        checkins[formatter.string(from: date)] ?? false
    }

    var currentStreak: Int {
        var streak = 0
        var day = Date()
        while true {
            let key = formatter.string(from: day)
            guard checkins[key] == true else { break }
            streak += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    var totalCount: Int { checkins.values.filter { $0 }.count }

    var monthCheckinCount: Int {
        let cal = Calendar.current
        let now = Date()
        return checkins.filter { key, val in
            guard val, let date = formatter.date(from: key) else { return false }
            return cal.isDate(date, equalTo: now, toGranularity: .month)
        }.count
    }

    var weekCheckinCount: Int {
        var cal = Calendar.current
        cal.firstWeekday = 2
        guard let week = cal.dateInterval(of: .weekOfYear, for: Date()) else { return 0 }
        return checkins.filter { key, val in
            guard val, let date = formatter.date(from: key) else { return false }
            return week.contains(date)
        }.count
    }

    var shouldWarnWeekly: Bool {
        Calendar.current.component(.weekday, from: Date()) == 7 && weekCheckinCount < 3
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(checkins) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([String: Bool].self, from: data) else { return }
        checkins = decoded
    }
}
