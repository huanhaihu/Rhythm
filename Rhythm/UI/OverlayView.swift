import SwiftUI

struct OverlayView: View {
    @ObservedObject var timerEngine: TimerEngine
    let isMicro: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.78)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                // Icon
                Image(systemName: isMicro ? "eye.slash" : "figure.walk")
                    .font(.system(size: 56, weight: .ultraLight))
                    .foregroundColor(.white.opacity(0.8))

                // Title
                Text(isMicro ? "微休息" : "休息时间")
                    .font(.system(size: 42, weight: .light, design: .rounded))
                    .foregroundColor(.white)

                // Countdown
                Text(countdownText)
                    .font(.system(size: 88, weight: .thin, design: .monospaced))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                    .animation(.linear(duration: 0.3), value: timerEngine.restSecondsRemaining)

                // Subtitle
                Text(isMicro ? "放松眼睛，深呼吸" : "站起来，活动一下")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.white.opacity(0.6))

                Spacer().frame(height: 12)

                // Skip hint
                Button {
                    timerEngine.skipCurrentRest()
                } label: {
                    Text("跳过  (ESC)")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.35))
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var countdownText: String {
        let s = timerEngine.restSecondsRemaining
        let m = s / 60
        let sec = s % 60
        if m > 0 {
            return String(format: "%d:%02d", m, sec)
        }
        return String(format: "0:%02d", sec)
    }
}
