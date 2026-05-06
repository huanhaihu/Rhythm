import Foundation

struct Word: Identifiable, Codable, Equatable {
    var id: UUID
    var english: String
    var chinese: String      // primary single-line gloss (first sense, or whole translation)
    var phonetic: String?    // IPA from local dictionary if available
    var senses: [WordSense]? // multi-POS breakdown from local dictionary if available
    var direction: Direction // how user originally looked it up
    var firstSeen: Date
    var lastSeen: Date
    var lookupCount: Int
    var box: Int             // Leitner 1...7
    var nextDueDate: Date
    var lastReviewed: Date?
    var retired: Bool        // user chose "完全掌握", won't appear in review

    enum Direction: String, Codable {
        case enToCn
        case cnToEn
    }

    enum CodingKeys: String, CodingKey {
        case id, english, chinese, phonetic, senses, direction, firstSeen, lastSeen
        case lookupCount, box, nextDueDate, lastReviewed, retired
    }

    init(id: UUID, english: String, chinese: String, phonetic: String? = nil,
         senses: [WordSense]? = nil, direction: Direction,
         firstSeen: Date, lastSeen: Date, lookupCount: Int, box: Int,
         nextDueDate: Date, lastReviewed: Date?, retired: Bool) {
        self.id = id; self.english = english; self.chinese = chinese
        self.phonetic = phonetic; self.senses = senses
        self.direction = direction; self.firstSeen = firstSeen; self.lastSeen = lastSeen
        self.lookupCount = lookupCount; self.box = box; self.nextDueDate = nextDueDate
        self.lastReviewed = lastReviewed; self.retired = retired
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id          = try c.decode(UUID.self, forKey: .id)
        english     = try c.decode(String.self, forKey: .english)
        chinese     = try c.decode(String.self, forKey: .chinese)
        phonetic    = try c.decodeIfPresent(String.self, forKey: .phonetic)
        senses      = try c.decodeIfPresent([WordSense].self, forKey: .senses)
        direction   = try c.decodeIfPresent(Direction.self, forKey: .direction) ?? .enToCn
        firstSeen   = try c.decode(Date.self, forKey: .firstSeen)
        lastSeen    = try c.decode(Date.self, forKey: .lastSeen)
        lookupCount = try c.decode(Int.self, forKey: .lookupCount)
        box         = try c.decode(Int.self, forKey: .box)
        nextDueDate = try c.decode(Date.self, forKey: .nextDueDate)
        lastReviewed = try c.decodeIfPresent(Date.self, forKey: .lastReviewed)
        retired     = try c.decodeIfPresent(Bool.self, forKey: .retired) ?? false
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
