import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject var settings: Settings
    @EnvironmentObject var soundPlayer: SoundPlayer
    @State private var showFilePicker = false

    var body: some View {
        Form {
            // Work & Rest
            Section("工作与休息") {
                LabeledContent("工作时长") {
                    Stepper(
                        "\(settings.workDuration / 60) 分钟",
                        value: Binding(
                            get: { settings.workDuration / 60 },
                            set: { settings.workDuration = $0 * 60 }
                        ),
                        in: 5...120
                    )
                }
                LabeledContent("休息时长") {
                    Stepper(
                        "\(settings.restDuration / 60) 分钟",
                        value: Binding(
                            get: { settings.restDuration / 60 },
                            set: { settings.restDuration = $0 * 60 }
                        ),
                        in: 1...30
                    )
                }
            }

            // Micro Rest
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
                                value: Binding(
                                    get: { settings.microRestIntervalMin / 60 },
                                    set: { settings.microRestIntervalMin = $0 * 60 }
                                ),
                                in: 1...settings.microRestIntervalMax / 60
                            )
                            Text("~")
                            Stepper(
                                "\(settings.microRestIntervalMax / 60)",
                                value: Binding(
                                    get: { settings.microRestIntervalMax / 60 },
                                    set: { settings.microRestIntervalMax = $0 * 60 }
                                ),
                                in: settings.microRestIntervalMin / 60...30
                            )
                            Text("分钟")
                        }
                    }
                }
            }

            // Sound
            Section("提示音") {
                LabeledContent("休息提示音") {
                    HStack {
                        Picker("", selection: $settings.alertSound) {
                            ForEach(Settings.systemSounds, id: \.self) { Text($0).tag($0) }
                            Text("自定义").tag("custom")
                        }
                        .labelsHidden()
                        .frame(width: 110)
                        Button("试听") { soundPlayer.playAlert() }
                            .controlSize(.small)
                    }
                }
                LabeledContent("微休息提示音") {
                    HStack {
                        Picker("", selection: $settings.microAlertSound) {
                            ForEach(Settings.systemSounds, id: \.self) { Text($0).tag($0) }
                            Text("自定义").tag("custom")
                        }
                        .labelsHidden()
                        .frame(width: 110)
                        Button("试听") { soundPlayer.playMicroAlert() }
                            .controlSize(.small)
                    }
                }

                if settings.alertSound == "custom" || settings.microAlertSound == "custom" {
                    LabeledContent("自定义音效文件") {
                        HStack {
                            Text(settings.customSoundPath.isEmpty
                                 ? "未选择"
                                 : URL(fileURLWithPath: settings.customSoundPath).lastPathComponent)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                            Button("选择...") { showFilePicker = true }
                                .controlSize(.small)
                        }
                    }
                    .fileImporter(
                        isPresented: $showFilePicker,
                        allowedContentTypes: [.audio],
                        allowsMultipleSelection: false
                    ) { result in
                        if case .success(let urls) = result, let url = urls.first {
                            // Copy to app support dir
                            let dest = FileManager.default
                                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                                .appendingPathComponent("Rhythm/Sounds", isDirectory: true)
                            try? FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
                            let target = dest.appendingPathComponent(url.lastPathComponent)
                            try? FileManager.default.copyItem(at: url, to: target)
                            settings.customSoundPath = target.path
                        }
                    }
                }
            }

        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding(.vertical, 8)
    }
}
