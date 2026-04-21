import Foundation

struct DailyThought: Codable, Equatable {
    var text: String
    var createdAt: Date
    var updatedAt: Date
}

struct MonthlyReflection: Codable, Equatable {
    var monthKey: String
    var summary: String
    var themes: [String]
    var highlights: [String]
    var entryCount: Int
    var generatedAt: Date
}
