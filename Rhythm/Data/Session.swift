import Foundation

enum SessionType: String, Codable {
    case rest
    case microRest
}

struct Session: Codable, Identifiable {
    let id: UUID
    let type: SessionType
    let startTime: Date
    let plannedDuration: Int   // seconds
    let actualDuration: Int    // seconds
    let skipped: Bool

    var typeLabel: String {
        type == .rest ? "正常休息" : "微休息"
    }

    var durationLabel: String {
        let s = actualDuration
        if s < 60 { return "\(s)秒" }
        return "\(s / 60)分\(s % 60 > 0 ? "\(s % 60)秒" : "")"
    }
}
