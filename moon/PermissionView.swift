import SwiftUI
import CoreLocation

struct PermissionView: View {
    @EnvironmentObject var location: LocationManager
    var onContinue: () -> Void

    var body: some View {
        FrontPanel(mode: .night) {
            VStack(alignment: .leading, spacing: 0) {
                Spacer().frame(height: 90)
                Text("PERMISSIONS")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(4)
                    .foregroundStyle(Color(hex: 0xF4F1E8).opacity(0.5))
                    .padding(.bottom, 12)
                Text("Lumen needs your location and compass.")
                    .font(.system(size: 24, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(Color(hex: 0xF4F1E8))
                    .lineSpacing(2)
                    .padding(.bottom, 14)
                Text("To compute where the sun and moon are right now and rotate the dial as you turn. Nothing leaves your device.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color(hex: 0xF4F1E8).opacity(0.65))
                    .lineSpacing(4)
                    .padding(.bottom, 28)
                VStack(spacing: 10) {
                    permRow(title: "LOCATION", sub: "While using Lumen",
                            granted: location.authorization == .authorizedWhenInUse
                                  || location.authorization == .authorizedAlways)
                    permRow(title: "MOTION & ORIENTATION", sub: "To rotate the dial", granted: true)
                }
                Spacer()
                Button {
                    if location.authorization == .notDetermined {
                        location.requestAuthorization()
                    } else {
                        onContinue()
                    }
                } label: {
                    Text(buttonLabel)
                        .font(.system(size: 14, weight: .bold))
                        .tracking(1.5)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(colors: [Color(hex: 0xC4513A), Color(hex: 0x8A3424)],
                                           startPoint: .top, endPoint: .bottom)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 32)
            }
            .padding(.horizontal, 24)
            .onChange(of: location.authorization) { _, newValue in
                if newValue == .authorizedWhenInUse || newValue == .authorizedAlways {
                    onContinue()
                }
            }
        }
    }

    private var buttonLabel: String {
        switch location.authorization {
        case .notDetermined: return "ALLOW ACCESS"
        case .denied, .restricted: return "OPEN SETTINGS"
        default: return "CONTINUE"
        }
    }

    @ViewBuilder
    private func permRow(title: String, sub: String, granted: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1.5)
                    .foregroundStyle(Color(hex: 0xF4F1E8))
                Text(sub)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: 0xF4F1E8).opacity(0.6))
            }
            Spacer()
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(granted
                          ? LinearGradient(colors: [Color(hex: 0x2C8A48), Color(hex: 0x1A5C30)],
                                           startPoint: .top, endPoint: .bottom)
                          : LinearGradient(colors: [Color(hex: 0x444), Color(hex: 0x222)],
                                           startPoint: .top, endPoint: .bottom))
                    .frame(width: 36, height: 20)
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0xECEFF2), Color(hex: 0xB6B8BA)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 18, height: 18)
                    .offset(x: granted ? 8 : -8)
                    .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
            }
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(hex: 0x0E0E16))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.4), lineWidth: 1)
                .blur(radius: 1)
                .offset(y: 1)
                .mask(RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [.black, .clear],
                                         startPoint: .top, endPoint: .center)))
        )
    }
}
