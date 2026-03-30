import Foundation

class SessionStore: ObservableObject {
    @Published var sessions: [Session] = []

    private let fileURL: URL

    init() {
        let dir = FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Rhythm", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("sessions.json")
        load()
    }

    func save(session: Session) {
        sessions.append(session)
        persist()
    }

    // Sessions grouped by calendar day, newest first
    var groupedByDay: [(String, [Session])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let grouped = Dictionary(grouping: sessions) { formatter.string(from: $0.startTime) }
        return grouped.keys.sorted(by: >).map { key in (key, grouped[key]!.sorted { $0.startTime > $1.startTime }) }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(sessions) {
            try? data.write(to: fileURL)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Session].self, from: data) else { return }
        sessions = decoded
    }
}
