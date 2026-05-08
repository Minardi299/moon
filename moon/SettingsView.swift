import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var location: LocationManager
    let mode: Mode

    @AppStorage("compassStyle") private var compassStyleRaw: String = CompassStyle.rose.rawValue
    @AppStorage("altitudeRings") private var altitudeRings: Bool = true
    @AppStorage("belowHorizonTrail") private var belowHorizonTrail: Bool = true
    @AppStorage("timeFormat24") private var timeFormat24: Bool = false
    @AppStorage("bearingTrue") private var bearingTrue: Bool = true
    @AppStorage("alertGoldenHour") private var alertGoldenHour: Bool = true
    @AppStorage("alertFullMoon") private var alertFullMoon: Bool = false
    @AppStorage("useMyLocation") private var useMyLocation: Bool = true

    var body: some View {
        FrontPanel(mode: mode) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer().frame(height: 24)
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("CONFIG")
                                .font(.system(size: 9, weight: .bold))
                                .tracking(4)
                                .foregroundStyle(mode.palette.ink.opacity(0.55))
                            Text("Settings")
                                .font(.system(size: 30, weight: .bold))
                                .tracking(-0.4)
                                .foregroundStyle(mode.palette.ink)
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(mode.palette.ink.opacity(0.6))
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(mode.palette.inset))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    section(title: "DIAL") {
                        compassStyleRow
                        Divider().background(mode.palette.separator)
                        toggleRow("Altitude rings", $altitudeRings)
                        Divider().background(mode.palette.separator)
                        toggleRow("Below-horizon trail", $belowHorizonTrail)
                    }
                    section(title: "UNITS") {
                        valueRow("Time format", timeFormat24 ? "24 H" : "12 H") {
                            timeFormat24.toggle()
                        }
                        Divider().background(mode.palette.separator)
                        valueRow("Bearing", bearingTrue ? "TRUE N" : "MAG N") {
                            bearingTrue.toggle()
                        }
                    }
                    section(title: "ALERTS") {
                        toggleRow("Daily golden hour", $alertGoldenHour)
                        Divider().background(mode.palette.separator)
                        toggleRow("Full moon tonight", $alertFullMoon)
                    }
                    section(title: "LOCATION") {
                        toggleRow("Use my location", $useMyLocation)
                        Divider().background(mode.palette.separator)
                        valueRow(location.placeName ?? "Brooklyn, NY",
                                 coordLabel) {}
                    }
                    Spacer().frame(height: 60)
                }
            }
        }
    }

    private var coordLabel: String {
        if let c = location.coordinate {
            return String(format: "%.2f°", c.latitude)
        }
        return "—"
    }

    @ViewBuilder
    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .bold))
            .tracking(2.5)
            .foregroundStyle(mode.palette.ink.opacity(0.6))
            .padding(.top, 20)
            .padding(.bottom, 8)
            .padding(.horizontal, 20)
        VStack(spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(mode.palette.inset)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                .blur(radius: 1)
                .offset(y: 1)
                .mask(RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [.black, .clear],
                                         startPoint: .top, endPoint: .center)))
        )
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func toggleRow(_ label: String, _ binding: Binding<Bool>) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(mode.palette.ink)
            Spacer()
            KnurledToggle(isOn: binding, mode: mode)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
    }

    @ViewBuilder
    private func valueRow(_ label: String, _ value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(mode.palette.ink)
                Spacer()
                DisplayBox(mode: mode, dark: true, cornerRadius: 4,
                           horizontalPadding: 10, verticalPadding: 4) {
                    Text(value)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .monospacedDigit()
                        .tracking(0.5)
                }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var compassStyleRow: some View {
        HStack {
            Text("Compass face")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(mode.palette.ink)
            Spacer()
            Menu {
                ForEach(CompassStyle.allCases) { style in
                    Button(style.label.capitalized) { compassStyleRaw = style.rawValue }
                }
            } label: {
                DisplayBox(mode: mode, dark: true, cornerRadius: 4,
                           horizontalPadding: 10, verticalPadding: 4) {
                    HStack(spacing: 6) {
                        Text(currentStyleLabel)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .tracking(0.5)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 52)
    }

    private var currentStyleLabel: String {
        (CompassStyle(rawValue: compassStyleRaw) ?? .rose).label
    }
}
