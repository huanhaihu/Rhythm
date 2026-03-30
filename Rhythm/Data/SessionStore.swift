import Foundation

struct DayStats {
    let date: String
    let sessions: [Session]

    var completedCycles: Int  { sessions.filter { $0.type == .rest && !$0.skipped && !$0.wasManualTrigger }.count }
    var manualRests: Int      { sessions.filter { $0.type == .rest && $0.wasManualTrigger }.count }
    var microRests: Int       { sessions.filter { $0.type == .microRest }.count }
    var skippedCount: Int     { sessions.filter { $0.skipped }.count }
    var resetCount: Int       { sessions.filter { $0.type == .reset }.count }

    var totalRestSeconds: Int {
        sessions.filter { $0.type != .reset }.reduce(0) { $0 + $1.actualDuration }
    }

    var totalRestLabel: String {
        let s = totalRestSeconds
        if s < 60 { return "\(s)秒" }
        let m = s / 60; let r = s % 60
        return r > 0 ? "\(m)分\(r)秒" : "\(m)分钟"
    }
}

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

    func recordReset() {
        save(session: Session(
            id: UUID(), type: .reset,
            startTime: Date(), plannedDuration: 0, actualDuration: 0,
            skipped: false, wasManualTrigger: false
        ))
    }

    var dayStats: [DayStats] {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        let grouped = Dictionary(grouping: sessions) { fmt.string(from: $0.startTime) }
        return grouped.keys.sorted(by: >).map { key in
            DayStats(date: key, sessions: grouped[key]!.sorted { $0.startTime > $1.startTime })
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(sessions) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Session].self, from: data) else { return }
        sessions = decoded
    }
}
