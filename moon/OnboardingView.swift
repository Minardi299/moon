import SwiftUI

struct OnboardingView: View {
    var onContinue: () -> Void

    var body: some View {
        FrontPanel(mode: .night) {
            VStack {
                Spacer().frame(height: 90)
                VStack(spacing: 36) {
                    // Hero compass — small mock with placeholder positions.
                    CompassView(
                        size: 200, style: .rose,
                        heading: 28,
                        sun: SunPosition(azimuth: 95, altitude: 12),
                        moon: MoonPosition(azimuth: 240, altitude: 38, phase: 0.6, illumination: 0.7),
                        mode: .night
                    )
                    VStack(spacing: 8) {
                        Text("SUN & MOON COMPASS")
                            .font(.system(size: 9, weight: .bold))
                            .tracking(4)
                            .foregroundStyle(Color(hex: 0xF4F1E8).opacity(0.5))
                        Text("Lumen")
                            .font(.system(size: 32, weight: .bold))
                            .tracking(-0.6)
                            .foregroundStyle(Color(hex: 0xF4F1E8))
                            .padding(.bottom, 4)
                        Text("A field compass for light. Point your phone, find the sun and the moon.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: 0xF4F1E8).opacity(0.65))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 280)
                            .lineSpacing(4)
                    }
                }
                Spacer()
                Button(action: onContinue) {
                    Text("BEGIN")
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(Color(hex: 0x1A1A22))
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(colors: [Color(hex: 0xF5F3EC), Color(hex: 0xC8C4B8)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
            }
        }
    }
}
