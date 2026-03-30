import Foundation

enum SessionType: String, Codable {
    case rest        // 正常休息（工作时间到）
    case microRest   // 微休息
    case reset       // 重置事件
}

struct Session: Codable, Identifiable {
    let id: UUID
    let type: SessionType
    let startTime: Date
    let plannedDuration: Int    // seconds
    let actualDuration: Int     // seconds
    let skipped: Bool
    let wasManualTrigger: Bool  // 是否点了「立即休息」

    // Backward-compatible decode: wasManualTrigger defaults to false for old records
    init(id: UUID, type: SessionType, startTime: Date,
         plannedDuration: Int, actualDuration: Int,
         skipped: Bool, wasManualTrigger: Bool = false) {
        self.id = id
        self.type = type
        self.startTime = startTime
        self.plannedDuration = plannedDuration
        self.actualDuration = actualDuration
        self.skipped = skipped
        self.wasManualTrigger = wasManualTrigger
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        type = try c.decode(SessionType.self, forKey: .type)
        startTime = try c.decode(Date.self, forKey: .startTime)
        plannedDuration = try c.decode(Int.self, forKey: .plannedDuration)
        actualDuration = try c.decode(Int.self, forKey: .actualDuration)
        skipped = try c.decode(Bool.self, forKey: .skipped)
        wasManualTrigger = try c.decodeIfPresent(Bool.self, forKey: .wasManualTrigger) ?? false
    }

    var typeLabel: String {
        switch type {
        case .rest:      return wasManualTrigger ? "立即休息" : "正常休息"
        case .microRest: return "微休息"
        case .reset:     return "重置"
        }
    }

    var durationLabel: String {
        guard type != .reset else { return "-" }
        let s = actualDuration
        if s < 60 { return "\(s)秒" }
        let m = s / 60; let r = s % 60
        return r > 0 ? "\(m)分\(r)秒" : "\(m)分钟"
    }
}
