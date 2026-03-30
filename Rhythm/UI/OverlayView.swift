import SwiftUI
import AppKit

struct VisualEffectBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.blendingMode = .behindWindow
        v.state = .active
        v.material = .fullScreenUI
        return v
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

// Rotating tips shown during rest
private let restTips: [String] = [
    "🧘 闭上眼睛，做 4 次深呼吸",
    "🚶 站起来走动 2 分钟",
    "🙆 伸展颈部：左右各转 5 次",
    "👀 望向 6 米外的远处，放松眼部肌肉",
    "💧 起身喝杯水，补充能量",
    "🤸 做几个肩部绕环，放松肩颈",
    "🌬️ 腹式呼吸：吸气 4 秒，呼气 6 秒",
    "🧠 让思绪放空，什么都不要想",
    "🌿 看看窗外的绿色，让眼睛休息",
    "🕐 站立冥想 30 秒，专注当下呼吸",
]

struct OverlayView: View {
    @ObservedObject var timerEngine: TimerEngine
    let isMicro: Bool

    @State private var tip: String = restTips.randomElement()!
    @State private var tipOpacity: Double = 0

    var body: some View {
        ZStack {
            VisualEffectBlur().ignoresSafeArea()
            Color.black.opacity(0.60).ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Icon
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 44, weight: .ultraLight))
                    .foregroundStyle(
                        LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .padding(.bottom, 16)

                // Title
                Text("休息一下")
                    .font(.system(size: 38, weight: .light, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)

                // Countdown ring + number
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 6)
                        .frame(width: 160, height: 160)

                    // Progress ring
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(
                            LinearGradient(colors: [.cyan, .purple, .pink],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: progress)

                    // Time text
                    VStack(spacing: 2) {
                        Text(countdownText)
                            .font(.system(size: 52, weight: .thin, design: .monospaced))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())
                            .animation(.linear(duration: 0.3), value: timerEngine.restSecondsRemaining)
                        Text("剩余")
                            .font(.system(size: 12, weight: .light))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
                .padding(.vertical, 24)

                // Tip card
                HStack(spacing: 10) {
                    Text(tip)
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.white.opacity(0.82))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .frame(maxWidth: 380)
                .opacity(tipOpacity)
                .onAppear {
                    withAnimation(.easeIn(duration: 0.6)) { tipOpacity = 1 }
                }

                Spacer().frame(height: 36)

                // Skip button
                Button {
                    timerEngine.skipCurrentRest()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 12))
                        Text("跳过，继续工作")
                            .font(.system(size: 14, weight: .light))
                    }
                    .foregroundColor(.white.opacity(0.38))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 9)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Text("按 ESC 跳过")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.2))
                    .padding(.top, 8)

                Spacer()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            tip = restTips.randomElement()!
        }
    }

    private var countdownText: String {
        let s = timerEngine.restSecondsRemaining
        let m = s / 60
        return m > 0 ? String(format: "%d:%02d", m, s % 60) : String(format: "0:%02d", s)
    }

    private var progress: Double {
        guard timerEngine.plannedDuration > 0 else { return 1 }
        let elapsed = timerEngine.plannedDuration - timerEngine.restSecondsRemaining
        return Double(elapsed) / Double(timerEngine.plannedDuration)
    }
}
