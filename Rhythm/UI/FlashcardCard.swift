import SwiftUI

struct FlashcardCard: View {
    @EnvironmentObject var wordStore: WordStore
    @State private var currentWord: Word?
    @State private var showBack: Bool = false
    @State private var sessionReviewed: Int = 0
    @State private var queue: [QueueEntry] = []
    @State private var position: Int = 0
    @State private var initialTotal: Int = 0
    @State private var processedIds: Set<UUID> = []

    private var pendingCount: Int {
        max(0, initialTotal - processedIds.count)
    }

    private struct QueueEntry: Identifiable {
        let id: UUID
        var wordId: UUID
        var skipRemaining: Int // how many cards to show before this one appears
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("单词复习")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                if pendingCount > 0 || currentWord != nil {
                    Text("待复习 \(pendingCount)")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.bottom, 10)

            if let word = currentWord {
                cardFace(word: word)
            } else {
                emptyState
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .tintedCard(.purple)
        .onAppear { buildQueue() }
    }

    private var emptyState: some View {
        VStack(spacing: 6) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 22))
                .foregroundColor(.secondary)
            Text(wordStore.words.isEmpty ? "还没有查过单词" : "今日复习完成")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            if sessionReviewed > 0 {
                Text("本轮已复习 \(sessionReviewed) 个")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
    }

    @ViewBuilder
    private func cardFace(word: Word) -> some View {
        VStack(spacing: 10) {
            // Front: show the question side
            HStack(spacing: 8) {
                Text(word.frontText)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.primary)
                    .textSelection(.enabled)
                    .multilineTextAlignment(.center)
                Button {
                    Speaker.shared.speak(word.frontText, lang: word.frontLang)
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 13))
                        .foregroundColor(.accentColor)
                        .frame(width: 24, height: 24)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
            }
            .frame(maxWidth: .infinity)

            if showBack {
                // Back: show the answer side
                HStack(spacing: 6) {
                    Text(word.backText)
                        .font(.system(size: 14))
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
            } else {
                Text("点击卡片显示答案")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary.opacity(0.7))
                    .frame(maxWidth: .infinity)
            }

            if showBack {
                HStack(spacing: 8) {
                    actionButton(title: "不认识", color: .orange) {
                        var w = word
                        w.markUnknown()
                        wordStore.update(w)
                        processedIds.insert(word.id)
                        advance()
                    }
                    actionButton(title: "认识", color: .green) {
                        var w = word
                        w.markKnown()
                        wordStore.update(w)
                        processedIds.insert(word.id)
                        // Reinforcement: re-appears after 3-5 more cards in this session
                        let delay = Int.random(in: 3...5)
                        enqueue(wordId: word.id, skip: delay)
                        advance()
                    }
                    if word.box >= 5 {
                        actionButton(title: "掌握", color: .blue) {
                            var w = word
                            w.retire()
                            wordStore.update(w)
                            processedIds.insert(word.id)
                            advance()
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.15)) { showBack = true }
        }
    }

    private func actionButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
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

    private func buildQueue() {
        let due = wordStore.dueWords
        queue = due.map {
            QueueEntry(id: UUID(), wordId: $0.id, skipRemaining: 0)
        }
        initialTotal = due.count
        processedIds.removeAll()
        pullNext()
    }

    private func enqueue(wordId: UUID, skip: Int) {
        queue.append(QueueEntry(id: UUID(), wordId: wordId, skipRemaining: skip))
    }

    private func advance() {
        sessionReviewed += 1
        showBack = false
        // Decrement skip counters
        for i in queue.indices { queue[i].skipRemaining = max(0, queue[i].skipRemaining - 1) }
        pullNext()
    }

    private func pullNext() {
        if let idx = queue.firstIndex(where: { $0.skipRemaining <= 0 }) {
            let entry = queue.remove(at: idx)
            currentWord = wordStore.words.first { $0.id == entry.wordId }
            if currentWord == nil { pullNext() }
        } else if !queue.isEmpty {
            // All entries have skip > 0, take the one with smallest skip
            queue.sort { $0.skipRemaining < $1.skipRemaining }
            let entry = queue.removeFirst()
            currentWord = wordStore.words.first { $0.id == entry.wordId }
            if currentWord == nil { pullNext() }
        } else {
            currentWord = nil
        }
        showBack = false
    }
}
