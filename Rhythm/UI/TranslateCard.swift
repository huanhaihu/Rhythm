import SwiftUI
import Translation

struct TranslateCard: View {
    @EnvironmentObject var wordStore: WordStore
    @State private var input: String = ""
    @State private var result: String = ""
    @State private var config: TranslationSession.Configuration?
    @State private var pendingText: String = ""

    private var isChineseInput: Bool {
        input.unicodeScalars.contains { $0.properties.isIdeographic }
    }

    private var sourceLang: Locale.Language {
        isChineseInput ? .init(identifier: "zh-Hans") : .init(identifier: "en")
    }

    private var targetLang: Locale.Language {
        isChineseInput ? .init(identifier: "en") : .init(identifier: "zh-Hans")
    }

    private var sourceSpeakLang: String { isChineseInput ? "zh-CN" : "en-US" }
    private var targetSpeakLang: String { isChineseInput ? "en-US" : "zh-CN" }

    private var directionLabel: String { isChineseInput ? "中 → 英" : "英 → 中" }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("翻译")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(input.isEmpty ? "自动识别" : directionLabel)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 8)

            HStack(spacing: 6) {
                TextField("输入单词", text: $input)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .onSubmit { submitQuery() }

                Button {
                    Speaker.shared.speak(input, lang: sourceSpeakLang)
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 12))
                        .foregroundColor(input.isEmpty ? Color.secondary.opacity(0.35) : .secondary)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                .disabled(input.isEmpty)

                Button {
                    input = ""
                    result = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(input.isEmpty ? Color.secondary.opacity(0.25) : .secondary)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                .disabled(input.isEmpty)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.thinMaterial)
            .cornerRadius(6)

            Button(action: submitQuery) {
                Text("查询")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(input.isEmpty ? Color.accentColor.opacity(0.3) : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .disabled(input.isEmpty)
            .padding(.top, 6)
            .keyboardShortcut(.defaultAction)

            Divider().opacity(0.5).padding(.vertical, 8)

            if !result.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Text(result)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        Speaker.shared.speak(result, lang: targetSpeakLang)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.accentColor)
                            .frame(width: 22, height: 22)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
                .padding(.bottom, 8)
            } else if !input.isEmpty {
                Text("翻译中…")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)
            }

            recentLookups
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(10)
        .translationTask(config) { session in
            await performTranslate(session: session)
        }
    }

    private var recentWords: [Word] {
        wordStore.words
            .sorted { $0.lastSeen > $1.lastSeen }
            .prefix(3)
            .map { $0 }
    }

    @ViewBuilder
    private var recentLookups: some View {
        let list = recentWords
        if list.isEmpty {
            Text("最近查询会出现在这里")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("最近查询")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                ForEach(Array(list.enumerated()), id: \.element.id) { idx, w in
                    HStack(spacing: 6) {
                        Text(w.english)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Button {
                            Speaker.shared.speak(w.english, lang: "en-US")
                        } label: {
                            Image(systemName: "speaker.wave.2")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                                .frame(width: 18, height: 18)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        Text(w.chinese)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if w.lookupCount > 1 {
                            Text("×\(w.lookupCount)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                    .padding(.vertical, 3)
                    if idx < list.count - 1 {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    private func submitQuery() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        pendingText = trimmed
        result = ""
        let newConfig = TranslationSession.Configuration(
            source: sourceLang,
            target: targetLang
        )
        if config?.source == newConfig.source && config?.target == newConfig.target {
            config?.invalidate()
        } else {
            config = newConfig
        }
    }

    private func performTranslate(session: TranslationSession) async {
        let text = pendingText
        guard !text.isEmpty else { return }
        do {
            let response = try await session.translate(text)
            let targetText = response.targetText
            let wasChinese = text.unicodeScalars.contains { $0.properties.isIdeographic }
            let english = wasChinese ? targetText : text
            let chinese = wasChinese ? text : targetText
            await MainActor.run {
                result = targetText
                wordStore.record(english: english, chinese: chinese, direction: wasChinese ? .cnToEn : .enToCn)
            }
        } catch {
            await MainActor.run { result = "" }
        }
    }
}
