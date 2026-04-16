import Foundation

struct Word: Identifiable, Codable, Equatable {
    var id: UUID
    var english: String
    var chinese: String
    var direction: Direction // how user originally looked it up
    var firstSeen: Date
    var lastSeen: Date
    var lookupCount: Int
    var box: Int             // Leitner 1...7
    var nextDueDate: Date
    var lastReviewed: Date?
    var retired: Bool        // user chose "完全掌握", won't appear in review

    enum Direction: String, Codable {
        case enToCn // user typed English → show English front, Chinese back
        case cnToEn // user typed Chinese → show Chinese front, English back
    }

    // Leitner intervals: box determines how long until next review cycle
    // "认识" advances box, but card still reappears 3-5 times within session
    // "不认识" resets to box 1, reappears immediately
    static let boxIntervals: [TimeInterval] = [
        0,           // box 1 → due immediately (new / unknown)
        1 * 86400,   // box 2 → 1 day
        2 * 86400,   // box 3 → 2 days
        4 * 86400,   // box 4 → 4 days
        7 * 86400,   // box 5 → 7 days
        14 * 86400,  // box 6 → 14 days
        30 * 86400,  // box 7 → 30 days
    ]

    var isDue: Bool { !retired && nextDueDate <= Date() }

    var frontText: String { direction == .cnToEn ? chinese : english }
    var backText: String  { direction == .cnToEn ? english : chinese }
    var frontLang: String { direction == .cnToEn ? "zh-CN" : "en-US" }
    var backLang: String  { direction == .cnToEn ? "en-US" : "zh-CN" }

    mutating func markKnown() {
        box = min(box + 1, 7)
        lastReviewed = Date()
        nextDueDate = Date().addingTimeInterval(Word.boxIntervals[box - 1])
    }

    mutating func markUnknown() {
        box = 1
        lastReviewed = Date()
        nextDueDate = Date() // immediately due again
    }

    mutating func retire() {
        retired = true
        lastReviewed = Date()
    }
}
