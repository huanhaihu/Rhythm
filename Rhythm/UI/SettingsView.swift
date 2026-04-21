import SwiftUI
import UniformTypeIdentifiers

// MARK: - Game Sound Model

private struct GameSound: Identifiable {
    let id: String
    let pack: String
    let category: String
    let name: String
    let path: String
}

private func loadGameSounds() -> [GameSound] {
    let base = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".claude/plugins/cache/citedy/game-sounds")
    guard let versions = try? FileManager.default.contentsOfDirectory(
            at: base, includingPropertiesForKeys: nil) else { return [] }
    guard let soundsDir = versions.first?.appendingPathComponent("sounds") else { return [] }
    guard let packs = try? FileManager.default.contentsOfDirectory(
            at: soundsDir, includingPropertiesForKeys: nil) else { return [] }

    var results: [GameSound] = []
    for packURL in packs.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
        let pack = packURL.lastPathComponent
        guard let cats = try? FileManager.default.contentsOfDirectory(
                at: packURL, includingPropertiesForKeys: nil) else { continue }
        for catURL in cats.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            let category = catURL.lastPathComponent
            guard let files = try? FileManager.default.contentsOfDirectory(
                    at: catURL, includingPropertiesForKeys: nil) else { continue }
            for fileURL in files.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                guard ["mp3","wav","ogg","m4a","aiff"].contains(fileURL.pathExtension.lowercased()) else { continue }
                let name = fileURL.deletingPathExtension().lastPathComponent
                    .replacingOccurrences(of: "-", with: " ")
                    .replacingOccurrences(of: "_", with: " ")
                results.append(GameSound(id: fileURL.path, pack: pack,
                                         category: category, name: name, path: fileURL.path))
            }
        }
    }
    return results
}

// MARK: - Game Sounds Browser Sheet

private struct GameSoundsBrowser: View {
    let title: String
    @Binding var customSoundPath: String
    let soundPlayer: SoundPlayer
    @State private var gameSounds: [GameSound] = []
    @State private var selectedPack = ""
    @State private var searchQuery = ""
    @Environment(\.dismiss) private var dismiss

    private var availablePacks: [String] {
        Array(Set(gameSounds.map(\.pack))).sorted()
    }

    private var filteredSounds: [GameSound] {
        gameSounds.filter { s in
            (selectedPack.isEmpty || s.pack == selectedPack) &&
            (searchQuery.isEmpty
                || s.name.localizedCaseInsensitiveContains(searchQuery)
                || s.pack.localizedCaseInsensitiveContains(searchQuery))
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Button("完成") { dismiss() }
            }
            .padding()

            Divider()

            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass").foregroundColor(.secondary).font(.caption)
                    TextField("搜索", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(6)
                .background(Color.primary.opacity(0.07))
                .cornerRadius(7)

                Picker("", selection: $selectedPack) {
                    Text("全部 Pack").tag("")
                    ForEach(availablePacks, id: \.self) { Text($0).tag($0) }
                }
                .labelsHidden()
                .frame(width: 140)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            List(filteredSounds) { sound in
                HStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(sound.name).font(.system(size: 13))
                        Text("\(sound.pack)  ·  \(sound.category)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button { soundPlayer.previewFile(path: sound.path) } label: {
                        Image(systemName: "play.circle").font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.blue)
                    .help("试听")

                    Button {
                        customSoundPath = sound.path
                        dismiss()
                    } label: {
                        Image(systemName: customSoundPath == sound.path
                              ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 16))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(customSoundPath == sound.path ? .blue : .secondary)
                    .help("选择")
                }
                .padding(.vertical, 2)
            }
            .listStyle(.plain)

            Divider()
            Text("\(filteredSounds.count) / \(gameSounds.count) 个音效")
                .font(.caption).foregroundColor(.secondary).padding(6)
        }
        .frame(width: 480, height: 480)
        .onAppear { gameSounds = loadGameSounds() }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var soundPlayer: SoundPlayer
    @State private var showAlertFilePicker = false
    @State private var showMicroFilePicker = false
    @State private var showAlertBrowser = false
    @State private var showMicroBrowser = false

    var body: some View {
        Form {
            Section("工作与休息") {
                LabeledContent("工作时长") {
                    Stepper(
                        "\(settings.workDuration / 60) 分钟",
                        value: Binding(get: { settings.workDuration / 60 },
                                       set: { settings.workDuration = $0 * 60 }),
                        in: 5...120
                    )
                }
                LabeledContent("休息时长") {
                    Stepper(
                        "\(settings.restDuration / 60) 分钟",
                        value: Binding(get: { settings.restDuration / 60 },
                                       set: { settings.restDuration = $0 * 60 }),
                        in: 1...30
                    )
                }
            }

            Section("随机微休息") {
                Toggle("启用微休息", isOn: $settings.microRestEnabled)
                if settings.microRestEnabled {
                    LabeledContent("微休息时长") {
                        Stepper("\(settings.microRestDuration) 秒",
                                value: $settings.microRestDuration, in: 5...60)
                    }
                    LabeledContent("触发区间（分钟）") {
                        HStack {
                            Stepper(
                                "\(settings.microRestIntervalMin / 60)",
                                value: Binding(get: { settings.microRestIntervalMin / 60 },
                                               set: { settings.microRestIntervalMin = $0 * 60 }),
                                in: 1...settings.microRestIntervalMax / 60
                            )
                            Text("~")
                            Stepper(
                                "\(settings.microRestIntervalMax / 60)",
                                value: Binding(get: { settings.microRestIntervalMax / 60 },
                                               set: { settings.microRestIntervalMax = $0 * 60 }),
                                in: settings.microRestIntervalMin / 60...30
                            )
                            Text("分钟")
                        }
                    }
                }
            }

            Section("Claude API") {
                LabeledContent("API Key") {
                    SecureField("sk-ant-...", text: $settings.claudeAPIKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 260)
                }
                Text("用于每月自动生成「感受月报」。留空则不生成。可在 console.anthropic.com 获取。")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Section("提示音") {
                // — 休息提示音 —
                LabeledContent("休息提示音") {
                    HStack {
                        Picker("", selection: $settings.alertSound) {
                            ForEach(Settings.systemSounds, id: \.self) { Text($0).tag($0) }
                            Text("自定义").tag("custom")
                        }
                        .labelsHidden().frame(width: 110)
                        Button("试听") { soundPlayer.playAlert() }.controlSize(.small)
                    }
                }
                if settings.alertSound == "custom" {
                    customSoundRow(
                        path: settings.customSoundPath,
                        onBrowser: { showAlertBrowser = true },
                        onFilePicker: { showAlertFilePicker = true }
                    )
                    .fileImporter(isPresented: $showAlertFilePicker,
                                  allowedContentTypes: [.audio],
                                  allowsMultipleSelection: false) { result in
                        saveCustomSound(result: result, to: \.customSoundPath)
                    }
                }

                // — 微休息提示音 —
                LabeledContent("微休息提示音") {
                    HStack {
                        Picker("", selection: $settings.microAlertSound) {
                            ForEach(Settings.systemSounds, id: \.self) { Text($0).tag($0) }
                            Text("自定义").tag("custom")
                        }
                        .labelsHidden().frame(width: 110)
                        Button("试听") { soundPlayer.playMicroAlert() }.controlSize(.small)
                    }
                }
                if settings.microAlertSound == "custom" {
                    customSoundRow(
                        path: settings.customMicroSoundPath,
                        onBrowser: { showMicroBrowser = true },
                        onFilePicker: { showMicroFilePicker = true }
                    )
                    .fileImporter(isPresented: $showMicroFilePicker,
                                  allowedContentTypes: [.audio],
                                  allowsMultipleSelection: false) { result in
                        saveCustomSound(result: result, to: \.customMicroSoundPath)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding(.vertical, 8)
        .sheet(isPresented: $showAlertBrowser) {
            GameSoundsBrowser(title: "休息提示音 — 游戏音效库",
                              customSoundPath: $settings.customSoundPath,
                              soundPlayer: soundPlayer)
        }
        .sheet(isPresented: $showMicroBrowser) {
            GameSoundsBrowser(title: "微休息提示音 — 游戏音效库",
                              customSoundPath: $settings.customMicroSoundPath,
                              soundPlayer: soundPlayer)
        }
    }

    // MARK: - Helpers

    private func customSoundRow(path: String,
                                onBrowser: @escaping () -> Void,
                                onFilePicker: @escaping () -> Void) -> some View {
        LabeledContent("自定义音效") {
            HStack(spacing: 6) {
                Text(path.isEmpty ? "未选择" : URL(fileURLWithPath: path).lastPathComponent)
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("游戏音效库") { onBrowser() }
                    .controlSize(.small).buttonStyle(.bordered)
                Button("选择文件…") { onFilePicker() }
                    .controlSize(.small)
            }
        }
    }

    private func saveCustomSound(result: Result<[URL], Error>,
                                 to keyPath: ReferenceWritableKeyPath<Settings, String>) {
        if case .success(let urls) = result, let url = urls.first {
            let dest = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("Rhythm/Sounds", isDirectory: true)
            try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
            let target = dest.appendingPathComponent(url.lastPathComponent)
            try? FileManager.default.copyItem(at: url, to: target)
            settings[keyPath: keyPath] = target.path
        }
    }
}
