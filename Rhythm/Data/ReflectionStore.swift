import Foundation

final class ReflectionStore: ObservableObject {
    @Published var reflections: [String: MonthlyReflection] = [:]

    private let fileURL: URL

    init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Rhythm", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("reflections.json")
        load()
    }

    func reflection(for monthKey: String) -> MonthlyReflection? {
        reflections[monthKey]
    }

    func save(_ reflection: MonthlyReflection) {
        reflections[reflection.monthKey] = reflection
        persist()
    }

    static func monthKey(for date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM"
        return f.string(from: date)
    }

    static func previousMonthKey(from date: Date = Date()) -> String {
        let cal = Calendar.current
        let prev = cal.date(byAdding: .month, value: -1, to: date) ?? date
        return monthKey(for: prev)
    }

    private func persist() {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(reflections) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        if let decoded = try? decoder.decode([String: MonthlyReflection].self, from: data) {
            reflections = decoded
        }
    }
}
