import SwiftUI

struct WordsView: View {
    @EnvironmentObject var wordStore: WordStore
    @State private var filter: Filter = .all
    @State private var search: String = ""

    enum Filter: String, CaseIterable, Identifiable {
        case all = "全部"
        case due = "待复习"
        case today = "今日"
        var id: String { rawValue }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            statsHeader
            filterBar
            wordList
        }
        .padding(18)
    }

    private var statsHeader: some View {
        HStack(spacing: 10) {
            statTile(label: "今日查词", value: "\(wordStore.todayLookupCount)")
            statTile(label: "今日复习", value: "\(wordStore.todayReviewedCount)", tint: .green)
            statTile(label: "待复习", value: "\(wordStore.dueWords.count)", tint: .orange)
            statTile(label: "已掌握", value: "\(wordStore.retiredCount)", tint: .green)
            statTile(label: "总词数", value: "\(wordStore.words.count)")
        }
    }

    private func statTile(label: String, value: String, tint: Color = .accentColor) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(tint)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.regularMaterial)
        .cornerRadius(8)
    }

    private var filterBar: some View {
        HStack(spacing: 8) {
            Picker("", selection: $filter) {
                ForEach(Filter.allCases) { f in Text(f.rawValue).tag(f) }
            }
            .pickerStyle(.segmented)
            .frame(width: 220)

            TextField("搜索单词", text: $search)
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: .infinity)
        }
    }

    private var filteredWords: [Word] {
        var list: [Word]
        switch filter {
        case .all:
            list = wordStore.words
        case .due:
            list = wordStore.dueWords
        case .today:
            let start = Calendar.current.startOfDay(for: Date())
            list = wordStore.words.filter { $0.lastSeen >= start }
        }
        let q = search.trimmingCharacters(in: .whitespaces).lowercased()
        if !q.isEmpty {
            list = list.filter {
                $0.english.lowercased().contains(q) || $0.chinese.contains(q)
            }
        }
        return list.sorted { $0.lastSeen > $1.lastSeen }
    }

    private var wordList: some View {
        Group {
            if filteredWords.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 22))
                        .foregroundColor(.secondary)
                    Text("暂无单词")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(filteredWords.enumerated()), id: \.element.id) { idx, word in
                            row(word: word)
                            if idx < filteredWords.count - 1 {
                                Divider().opacity(0.5)
                            }
                        }
                    }
                }
                .background(.regularMaterial)
                .cornerRadius(8)
            }
        }
    }

    private func row(word: Word) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(word.english)
                        .font(.system(size: 14, weight: .medium))
                    Button {
                        Speaker.shared.speak(word.english, lang: "en-US")
                    } label: {
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                }
                Text(word.chinese)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                HStack(spacing: 4) {
                    Text("盒\(word.box)")
                        .font(.system(size: 10, weight: .medium))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(boxColor(word.box).opacity(0.15))
                        .foregroundColor(boxColor(word.box))
                        .clipShape(Capsule())
                    if word.retired {
                        Text("已掌握")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.15))
                            .foregroundColor(.green)
                            .clipShape(Capsule())
                    } else if word.isDue {
                        Text("待复习")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .clipShape(Capsule())
                    }
                }
                Text("×\(word.lookupCount) · \(relative(word.lastSeen))")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private func boxColor(_ box: Int) -> Color {
        switch box {
        case 1: return .red
        case 2: return .orange
        case 3: return .yellow
        case 4: return .blue
        default: return .green
        }
    }

    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.unitsStyle = .short
        return f.localizedString(for: date, relativeTo: Date())
    }
}
