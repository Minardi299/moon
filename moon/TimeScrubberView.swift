import SwiftUI

// Knurled time scrubber. minutes 0..1439 maps left→right across 24 h.
struct TimeScrubberView: View {
    @Binding var minutes: Int
    var isLive: Bool
    var onLiveTap: () -> Void
    var mode: Mode
    var displayDate: Date

    var body: some View {
        let p = mode.palette
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("TIME")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(p.ink.opacity(0.6))
                Text("·")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(p.ink.opacity(0.45))
                Text(dateString)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .tracking(1.5)
                    .foregroundStyle(p.ink.opacity(0.6))
                Spacer()
                if !isLive {
                    Button(action: onLiveTap) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 9, weight: .bold))
                            Text("NOW")
                                .font(.system(size: 10, weight: .bold))
                                .tracking(1.5)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [Color(hex: 0xC4513A), Color(hex: 0x8A3424)],
                                    startPoint: .top, endPoint: .bottom
                                ))
                        )
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                                .blendMode(.plusLighter)
                        )
                        .shadow(color: .black.opacity(0.35), radius: 1.5, y: 1)
                    }
                    .buttonStyle(PressableButtonStyle())
                }
                DisplayBox(mode: mode, dark: true, cornerRadius: 4,
                           horizontalPadding: 10, verticalPadding: 4) {
                    Text(timeString)
                        .displayText(size: 16, tracking: 1)
                }
            }
            track
            HStack {
                ForEach(["00", "06", "12", "18", "24"], id: \.self) { label in
                    Text(label)
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .monospacedDigit()
                        .tracking(1)
                        .foregroundStyle(p.ink.opacity(0.45))
                    if label != "24" { Spacer() }
                }
            }
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(p.inset)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.35), lineWidth: 1)
                        .blur(radius: 1)
                        .offset(y: 1)
                        .mask(RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: [.black, .clear],
                                                 startPoint: .top, endPoint: .center)))
                )
        )
    }

    private var timeString: String {
        let h = minutes / 60
        let m = minutes % 60
        return String(format: "%02d:%02d", h, m)
    }

    private var dateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEE · MMM d"
        return f.string(from: displayDate).uppercased()
    }

    @ViewBuilder
    private var track: some View {
        let p = mode.palette
        GeometryReader { geo in
            let width = geo.size.width
            let pct = CGFloat(minutes) / 1440
            ZStack(alignment: .topLeading) {
                // recessed groove
                RoundedRectangle(cornerRadius: 2)
                    .fill(p.groove)
                    .frame(height: 4)
                    .offset(y: 11)
                    .overlay(alignment: .top) {
                        RoundedRectangle(cornerRadius: 2)
                            .stroke(Color.black.opacity(0.6), lineWidth: 1)
                            .frame(height: 4)
                            .offset(y: 11)
                            .blur(radius: 0.5)
                    }
                // tick marks
                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { f in
                    Rectangle()
                        .fill(p.ink.opacity(0.4))
                        .frame(width: 1, height: 14)
                        .offset(x: width * CGFloat(f) - 0.5, y: 6)
                }
                // knob
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(LinearGradient(colors: [p.knobTop, p.knobMid, p.knobBot],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(width: 22, height: 24)
                        .shadow(color: .black.opacity(0.4), radius: 1.2, y: 2)
                    HStack(spacing: 2) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(mode.isDay ? Color.black.opacity(0.25) : Color.white.opacity(0.15))
                                .frame(width: 1, height: 16)
                        }
                    }
                }
                .offset(x: width * pct - 11, y: 1)
            }
            .frame(width: width, height: 26)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let x = max(0, min(width, value.location.x))
                        let m = Int(round(Double(x / width) * 1440))
                        if m != minutes { minutes = min(max(m, 0), 1439) }
                    }
            )
        }
        .frame(height: 26)
    }
}

// Tactile press feedback — slight scale + dim while held.
struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
