import SwiftUI

struct ThoughtCard: View {
    @EnvironmentObject var thoughtStore: ThoughtStore
    @State private var draft: String = ""
    @FocusState private var editing: Bool

    private var savedText: String {
        thoughtStore.todayThought?.text ?? ""
    }

    private var trimmedDraft: String {
        draft.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isDirty: Bool {
        trimmedDraft != savedText
    }

    private var canSave: Bool {
        !trimmedDraft.isEmpty && isDirty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 8)

            inputArea
                .padding(.bottom, 8)

            footer
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.regularMaterial)
        .cornerRadius(10)
        .onAppear { draft = savedText }
        .onChange(of: thoughtStore.todayKey) { _, _ in
            draft = savedText
        }
    }

    private var header: some View {
        HStack {
            Text("今日随想")
                .font(.system(size: 13, weight: .semibold))
            Spacer()
            if thoughtStore.hasThoughtToday && !isDirty {
                HStack(spacing: 3) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                    Text("已记录")
                        .font(.system(size: 10))
                }
                .foregroundColor(.green)
            } else {
                Text(isDirty ? "未保存" : "未记录")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
    }

    private var inputArea: some View {
        ScrollView(.vertical, showsIndicators: true) {
            TextField("记一下今天的感受，一两句话就好…", text: $draft, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($editing)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
        }
        .frame(height: 62)
        .background(.thinMaterial)
        .cornerRadius(6)
    }

    private var footer: some View {
        HStack(spacing: 6) {
            if thoughtStore.currentStreak > 0 {
                Text("连续 \(thoughtStore.currentStreak) 天")
                    .font(.system(size: 10, weight: .medium))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
            }
            Spacer()

            Button {
                draft = ""
                thoughtStore.clearToday()
            } label: {
                Text("清空")
                    .font(.system(size: 11))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.primary.opacity(0.06))
                    .foregroundColor(draft.isEmpty && !thoughtStore.hasThoughtToday ? .secondary.opacity(0.4) : .primary)
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .disabled(draft.isEmpty && !thoughtStore.hasThoughtToday)

            Button {
                thoughtStore.saveToday(draft)
                editing = false
            } label: {
                Text("记录")
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(canSave ? Color.accentColor : Color.primary.opacity(0.06))
                    .foregroundColor(canSave ? .white : .secondary.opacity(0.5))
                    .cornerRadius(5)
            }
            .buttonStyle(.plain)
            .focusable(false)
            .disabled(!canSave)
        }
    }
}
