import SwiftUI
import Translation

struct TranslateCard: View {
    @EnvironmentObject var wordStore: WordStore
    @State private var input: String = ""
    @State private var result: String = ""
    @State private var resultSenses: [WordSense] = []
    @State private var resultPhonetic: String = ""
    @State private var config: TranslationSession.Configuration?
    @State private var pendingText: String = ""
    @State private var hoveredWordID: UUID?

    // Quick-review state: linear pass through a snapshot of the N longest-unreviewed words.
    @State private var reviewQueue: [Word] = []
    @State private var reviewIndex: Int = 0
    @State private var reviewShowBack: Bool = false
    private let quickReviewSize = 5

    private var isReviewing: Bool { !reviewQueue.isEmpty }

    private var reviewableCount: Int {
        wordStore.words.filter { !$0.retired }.count
    }

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
            header
                .padding(.bottom, 8)

            if isReviewing {
                quickReviewBody
            } else {
                translateBody
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .tintedCard(.teal)
        .translationTask(config) { session in
            await performTranslate(session: session)
        }
    }

    @ViewBuilder
    private var header: some View {
        if isReviewing {
            HStack(spacing: 6) {
                Text("快速复习")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text("\(reviewIndex + 1) / \(reviewQueue.count)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Button(action: stopQuickReview) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .frame(width: 18, height: 18)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                .help("退出复习")
            }
        } else {
            HStack(spacing: 6) {
                Text("翻译")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if reviewableCount > 0 {
                    Button(action: startQuickReview) {
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 9, weight: .semibold))
                            Text("快速复习")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(Color.teal.opacity(0.15))
                        .foregroundColor(.teal)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .help("复习最久未复习的 \(min(quickReviewSize, reviewableCount)) 个单词")
                }
                Text(input.isEmpty ? "自动识别" : directionLabel)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var translateBody: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                    resultSenses = []
                    resultPhonetic = ""
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

                Button(action: submitQuery) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(input.isEmpty ? Color.secondary.opacity(0.35) : .accentColor)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                .disabled(input.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.thinMaterial)
            .cornerRadius(6)

            Divider().opacity(0.5).padding(.vertical, 8)

            if !resultSenses.isEmpty {
                sensesView
                    .padding(.bottom, 8)
            } else if !result.isEmpty {
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
    }

    @ViewBuilder
    private var quickReviewBody: some View {
        if reviewIndex < reviewQueue.count {
            reviewCard(word: reviewQueue[reviewIndex])
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func reviewCard(word: Word) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text(word.frontText)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.center)
                Button {
                    Speaker.shared.speak(word.frontText, lang: word.frontLang)
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                        .frame(width: 22, height: 22)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            .frame(maxWidth: .infinity)

            if reviewShowBack {
                HStack(spacing: 6) {
                    Text(word.backText)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    Button {
                        Speaker.shared.speak(word.backText, lang: word.backLang)
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
                .frame(maxWidth: .infinity)
                .transition(.opacity)

                HStack(spacing: 8) {
                    reviewActionButton(title: "不认识", color: .orange) {
                        var w = word; w.markUnknown(); wordStore.update(w); advanceReview()
                    }
                    reviewActionButton(title: "认识", color: .green) {
                        var w = word; w.markKnown(); wordStore.update(w); advanceReview()
                    }
                    if word.box >= 5 {
                        reviewActionButton(title: "掌握", color: .blue) {
                            var w = word; w.retire(); wordStore.update(w); advanceReview()
                        }
                    }
                }
                .padding(.top, 2)
            } else {
                Text("点击卡片显示答案")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            if !reviewShowBack {
                withAnimation(.easeInOut(duration: 0.15)) { reviewShowBack = true }
            }
        }
    }

    private func reviewActionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(color.opacity(0.15))
                .foregroundColor(color)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(color.opacity(0.35), lineWidth: 1)
                )
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
        .focusable(false)
    }

    private func startQuickReview() {
        let picks = wordStore.longestUnreviewed(limit: quickReviewSize)
        guard !picks.isEmpty else { return }
        reviewQueue = picks
        reviewIndex = 0
        reviewShowBack = false
    }

    private func stopQuickReview() {
        reviewQueue = []
        reviewIndex = 0
        reviewShowBack = false
    }

    private func advanceReview() {
        reviewShowBack = false
        if reviewIndex + 1 < reviewQueue.count {
            reviewIndex += 1
        } else {
            stopQuickReview()
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
                    let isHovered = hoveredWordID == w.id
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
                        Button {
                            wordStore.remove(id: w.id)
                            if hoveredWordID == w.id { hoveredWordID = nil }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                                .frame(width: 18, height: 18)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .opacity(isHovered ? 1 : 0)
                        .allowsHitTesting(isHovered)
                        .help("从复习移除")
                    }
                    .padding(.vertical, 3)
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        if hovering {
                            hoveredWordID = w.id
                        } else if hoveredWordID == w.id {
                            hoveredWordID = nil
                        }
                    }
                    if idx < list.count - 1 {
                        Divider().opacity(0.4)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var sensesView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !resultPhonetic.isEmpty {
                Text("/\(resultPhonetic)/")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            ForEach(Array(resultSenses.enumerated()), id: \.offset) { _, sense in
                HStack(alignment: .top, spacing: 8) {
                    Text(sense.displayPOS)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.teal)
                        .frame(minWidth: 28, alignment: .leading)
                    Text(sense.meaning)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Button {
                        Speaker.shared.speak(sense.meaning, lang: targetSpeakLang)
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .frame(width: 20, height: 20)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func submitQuery() {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        result = ""
        resultSenses = []
        resultPhonetic = ""

        // For English input, try local dictionary first for richer multi-POS output.
        if !isChineseInput, let entry = DictionaryService.shared.lookup(trimmed) {
            let top = DictionaryService.pickTopSenses(from: entry.senses)
            if !top.isEmpty {
                resultPhonetic = entry.phonetic
                resultSenses = top
                let primary = top.first?.meaning ?? ""
                wordStore.record(
                    english: trimmed,
                    chinese: primary,
                    direction: .enToCn,
                    phonetic: entry.phonetic.isEmpty ? nil : entry.phonetic,
                    senses: top
                )
                return
            }
        }

        // Fallback: Apple on-device translation (single result; covers cn→en and rare words).
        pendingText = trimmed
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
