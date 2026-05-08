import SwiftUI

// Just the sheet panel — the dimming overlay is owned by the parent
// (MainView) so it can fade in/out independently of the sheet's slide.
struct DetailSheetView: View {
    let target: SkyTarget
    let mode: Mode
    let sun: SunPosition
    let moon: MoonPosition
    let sunRS: RiseSet
    let moonRS: RiseSet
    let goldenHour: (start: Date, end: Date)?
    var onClose: () -> Void

    var body: some View {
        let p = mode.palette
        VStack(spacing: 0) {
            Capsule()
                .fill(mode.isDay ? Color(hex: 0x888A8C) : Color(hex: 0x0A0A10))
                .frame(width: 44, height: 5)
                .padding(.top, 14)
                .padding(.bottom, 18)
            header
                .padding(.horizontal, 20)
                .padding(.bottom, 18)
            metrics
                .padding(.horizontal, 20)
            Spacer().frame(height: 16)
        }
        .frame(maxWidth: .infinity)
        .background(
            Rectangle()
                .fill(p.bg)
                .shadow(color: .black.opacity(0.4), radius: 24, y: -8)
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 14,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 14,
                style: .continuous
            )
        )
        .ignoresSafeArea(.container, edges: .bottom)
        .gesture(
            DragGesture()
                .onEnded { v in
                    if v.translation.height > 60 { onClose() }
                }
        )
    }

    private var isSun: Bool { target == .sun }

    @ViewBuilder
    private var header: some View {
        HStack(spacing: 14) {
            ZStack {
                if isSun {
                    SunMarker(dark: mode.isDark, accent: mode.palette.accent)
                        .frame(width: 44, height: 44)
                } else {
                    MoonMarker(phase: moon.phase, dark: mode.isDark)
                        .frame(width: 44, height: 44)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(isSun ? "SOLAR OBJECT" : "LUNAR OBJECT")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(2.5)
                    .foregroundStyle(mode.palette.ink.opacity(0.6))
                Text(isSun ? "The Sun" : "The Moon")
                    .font(.system(size: 22, weight: .bold))
                    .tracking(-0.4)
                    .foregroundStyle(mode.palette.ink)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(mode.palette.ink.opacity(0.7))
            }
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(mode.palette.ink.opacity(0.6))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(mode.palette.inset))
            }
            .buttonStyle(.plain)
        }
    }

    @ViewBuilder
    private var metrics: some View {
        let az = isSun ? sun.azimuth : moon.azimuth
        let alt = isSun ? sun.altitude : moon.altitude
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                MetricCell(mode: mode, label: "DIRECTION",
                           value: "\(Int(az.rounded()))°",
                           sub: cardinalLabel(az))
                MetricCell(mode: mode, label: "ALTITUDE",
                           value: "\(Int(alt.rounded()))°",
                           sub: alt > 0 ? "Above" : "Below")
            }
            GridRow {
                MetricCell(mode: mode, label: "RISES",
                           value: formatted(isSun ? sunRS.rise : moonRS.rise),
                           sub: nil)
                MetricCell(mode: mode, label: "SETS",
                           value: formatted(isSun ? sunRS.set : moonRS.set),
                           sub: nil)
            }
            GridRow {
                if isSun {
                    MetricCell(mode: mode, label: "GOLDEN HOUR",
                               value: goldenHourString,
                               sub: nil)
                        .gridCellColumns(2)
                } else {
                    MetricCell(mode: mode, label: "PHASE",
                               value: "\(Int((moon.phase * 100).rounded()))%",
                               sub: phaseName(moon.phase))
                        .gridCellColumns(2)
                }
            }
        }
    }

    private var goldenHourString: String {
        guard let gh = goldenHour else { return "—" }
        return "\(formatted(gh.start)) – \(formatted(gh.end))"
    }

    private var subtitle: String {
        switch target {
        case .sun: return sun.altitude > 0 ? "Above horizon" : "Below horizon"
        case .moon: return phaseName(moon.phase)
        }
    }

    private func formatted(_ d: Date?) -> String {
        guard let d else { return "—" }
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: d)
    }
}

struct MetricCell: View {
    let mode: Mode
    let label: String
    let value: String
    let sub: String?

    var body: some View {
        let p = mode.palette
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .tracking(1.8)
                .foregroundStyle(p.ink.opacity(0.6))
            DisplayBox(mode: mode, dark: true, cornerRadius: 4,
                       horizontalPadding: 10, verticalPadding: 6) {
                Text(value)
                    .displayText(size: 16, tracking: 0.5)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let sub {
                Text(sub)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(p.ink.opacity(0.65))
            }
        }
        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(p.inset)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.35), lineWidth: 1)
                .blur(radius: 1)
                .offset(y: 1)
                .mask(RoundedRectangle(cornerRadius: 8)
                    .fill(LinearGradient(colors: [.black, .clear],
                                         startPoint: .top, endPoint: .center)))
        )
    }
}
