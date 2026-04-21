import Foundation

@MainActor
final class MonthlyReportGenerator: ObservableObject {
    @Published var isGenerating: Bool = false
    @Published var lastError: String?

    private let thoughtStore: ThoughtStore
    private let reflectionStore: ReflectionStore
    private let settings: Settings

    init(thoughtStore: ThoughtStore, reflectionStore: ReflectionStore, settings: Settings) {
        self.thoughtStore = thoughtStore
        self.reflectionStore = reflectionStore
        self.settings = settings
    }

    func generateIfNeeded() async {
        let prevKey = ReflectionStore.previousMonthKey()
        guard reflectionStore.reflection(for: prevKey) == nil else { return }
        guard !settings.claudeAPIKey.isEmpty else { return }
        let entries = thoughtStore.entries(inMonth: prevKey)
        guard !entries.isEmpty else { return }
        try? await generate(monthKey: prevKey, entries: entries)
    }

    func regenerate(monthKey: String) async throws {
        let entries = thoughtStore.entries(inMonth: monthKey)
        guard !entries.isEmpty else {
            throw ClaudeClientError.decodeFailed("该月份暂无笔记")
        }
        try await generate(monthKey: monthKey, entries: entries)
    }

    private func generate(monthKey: String, entries: [(date: String, thought: DailyThought)]) async throws {
        isGenerating = true
        lastError = nil
        defer { isGenerating = false }

        let client = ClaudeClient(apiKey: settings.claudeAPIKey)
        let simpleEntries = entries.map { (date: $0.date, text: $0.thought.text) }
        do {
            let reflection = try await client.generateMonthlyReflection(
                monthKey: monthKey,
                entries: simpleEntries
            )
            reflectionStore.save(reflection)
        } catch {
            lastError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            print("[MonthlyReportGenerator] failed: \(error)")
            throw error
        }
    }
}
