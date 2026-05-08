import SwiftUI

enum CompassStyle: String, CaseIterable, Identifiable {
    case rose, ticks, minimal
    var id: String { rawValue }
    var label: String {
        switch self {
        case .rose: return "ROSE"
        case .ticks: return "TICKS"
        case .minimal: return "MINIMAL"
        }
    }
}

// Maps an (azimuth, altitude) onto the compass disk: angle from heading,
// radius shrinks toward center as |altitude| → 90° (zenith pulls in).
func markerOffset(az: Double, alt: Double, ringR: Double, heading: Double) -> CGPoint {
    let theta = ((az - heading) - 90) * .pi / 180
    let t = max(0, min(1, 1 - abs(alt) / 90))
    let dist = ringR * (1 - t * 0.85)
    return CGPoint(x: cos(theta) * dist, y: sin(theta) * dist)
}

struct CompassView: View {
    var size: CGFloat = 240
    var style: CompassStyle = .rose
    var heading: Double                // degrees, true
    var sun: SunPosition
    var moon: MoonPosition
    var mode: Mode
    var selected: SkyTarget? = nil
    var onSunTap: (() -> Void)? = nil
    var onMoonTap: (() -> Void)? = nil

    var body: some View {
        let r = size / 2
        let ringR = r * 0.78
        let sunOffset = markerOffset(az: sun.azimuth, alt: sun.altitude, ringR: ringR, heading: heading)
        let moonOffset = markerOffset(az: moon.azimuth, alt: moon.altitude, ringR: ringR, heading: heading)
        let sunBelow = sun.altitude < 0
        let moonBelow = moon.altitude < 0
        let sunVisible = sun.altitude > -6
        let moonVisible = moon.altitude > -6

        let sunRimColor = Color(hex: 0xF4A040)
        let moonRimColor = mode.isDark ? Color(hex: 0xCFD8E8) : Color(hex: 0x6A6F7D)

        ZStack {
            CompassDial(
                size: size, style: style,
                heading: heading, mode: mode
            )

            // Direction indicators — radial line from rim to marker + pip on the rim,
            // colored to match the body. Mirrors the red North pip so users see at a
            // glance which direction the sun and moon are in.
            if sunVisible {
                bodyDirection(az: sun.azimuth, target: sunOffset,
                              ringR: ringR, color: sunRimColor,
                              dim: sunBelow)
            }
            if moonVisible {
                bodyDirection(az: moon.azimuth, target: moonOffset,
                              ringR: ringR, color: moonRimColor,
                              dim: moonBelow)
            }

            if sunVisible {
                SunMarker(selected: selected == .sun, dark: mode.isDark, accent: mode.palette.accent)
                    .frame(width: 38, height: 38)
                    .opacity(sunBelow ? 0.5 : 1)
                    .offset(x: sunOffset.x, y: sunOffset.y)
                    .onTapGesture { onSunTap?() }
            }
            if moonVisible {
                MoonMarker(phase: moon.phase, selected: selected == .moon, dark: mode.isDark)
                    .frame(width: 32, height: 32)
                    .opacity(moonBelow ? 0.5 : 1)
                    .offset(x: moonOffset.x, y: moonOffset.y)
                    .onTapGesture { onMoonTap?() }
            }
        }
        .frame(width: size, height: size)
    }

    @ViewBuilder
    private func bodyDirection(az: Double, target: CGPoint, ringR: CGFloat,
                               color: Color, dim: Bool) -> some View {
        let theta: Double = ((az - heading) - 90) * .pi / 180
        let cx: CGFloat = size / 2
        let cy: CGFloat = size / 2
        let cosT: CGFloat = CGFloat(cos(theta))
        let sinT: CGFloat = CGFloat(sin(theta))

        // Triangle indicator pointing inward, sitting just outside the rim.
        // Tip rests on (ringR + 4); base sits at (ringR + 12), 8 wide.
        let tipR: CGFloat = ringR + 4
        let baseR: CGFloat = ringR + 12
        let tipX: CGFloat = cx + cosT * tipR
        let tipY: CGFloat = cy + sinT * tipR
        let baseCx: CGFloat = cx + cosT * baseR
        let baseCy: CGFloat = cy + sinT * baseR
        // Perpendicular for the triangle base spread
        let perpX: CGFloat = -sinT
        let perpY: CGFloat = cosT
        let halfBase: CGFloat = 4
        let baseLeft = CGPoint(x: baseCx + perpX * halfBase, y: baseCy + perpY * halfBase)
        let baseRight = CGPoint(x: baseCx - perpX * halfBase, y: baseCy - perpY * halfBase)

        // Hairline from the marker outward to the tip — gives the eye a clear
        // line to follow from body to bearing.
        let markerX: CGFloat = cx + target.x
        let markerY: CGFloat = cy + target.y

        ZStack {
            Path { p in
                p.move(to: CGPoint(x: markerX, y: markerY))
                p.addLine(to: CGPoint(x: tipX, y: tipY))
            }
            .stroke(color.opacity(dim ? 0.4 : 0.7),
                    style: StrokeStyle(lineWidth: 1,
                                       dash: dim ? [2, 3] : []))
            Path { p in
                p.move(to: CGPoint(x: tipX, y: tipY))
                p.addLine(to: baseLeft)
                p.addLine(to: baseRight)
                p.closeSubpath()
            }
            .fill(color)
            .opacity(dim ? 0.65 : 1)
            .shadow(color: color.opacity(dim ? 0 : 0.7), radius: 3)
        }
        .allowsHitTesting(false)
    }

}

enum SkyTarget: String, Identifiable, Equatable {
    case sun, moon
    var id: String { rawValue }
}

// MARK: - Dial faces (rose / ticks / minimal)

struct CompassDial: View {
    let size: CGFloat
    let style: CompassStyle
    let heading: Double
    let mode: Mode

    var body: some View {
        let r = size / 2
        let ringR = r * 0.78
        let p = mode.palette
        let fg = mode.isDark ? Color(hex: 0xF4F1E8) : Color(hex: 0x1A1A1F)
        let sub = fg.opacity(0.55)
        let faint = fg.opacity(0.18)
        let hair = fg.opacity(0.35)
        let lume = p.accent

        Canvas { ctx, _ in
            switch style {
            case .rose:
                drawRose(ctx: ctx, r: r, ringR: ringR, heading: heading,
                         fg: fg, sub: sub, faint: faint, hair: hair, lume: lume)
            case .ticks:
                drawTicks(ctx: ctx, r: r, ringR: ringR, heading: heading,
                          fg: fg, sub: sub, hair: hair, lume: lume)
            case .minimal:
                drawMinimal(ctx: ctx, r: r, ringR: ringR, heading: heading,
                            fg: fg, sub: sub, faint: faint, hair: hair, lume: lume)
            }
        }
        .frame(width: size, height: size)
        .allowsHitTesting(false)
        .overlay {
            // Center text overlays — kept as SwiftUI Text for crisp font rendering
            switch style {
            case .rose: roseCenter(r: r, fg: fg, sub: sub, faint: faint)
            case .ticks: ticksCenter(r: r, fg: fg, sub: sub)
            case .minimal: minimalCenter(r: r, sub: sub)
            }
        }
        .overlay {
            // Cardinal letters
            cardinals(r: r, ringR: ringR, fg: fg, sub: sub, lume: lume)
        }
    }

    // MARK: dial drawers

    private func drawRose(ctx: GraphicsContext, r: CGFloat, ringR: CGFloat, heading: Double,
                          fg: Color, sub: Color, faint: Color, hair: Color, lume: Color) {
        // engraved double bezel
        ctx.stroke(Path(ellipseIn: CGRect(x: r - ringR - 4, y: r - ringR - 4,
                                          width: 2 * (ringR + 4), height: 2 * (ringR + 4))),
                   with: .color(faint), lineWidth: 0.6)
        ctx.stroke(Path(ellipseIn: CGRect(x: r - ringR, y: r - ringR,
                                          width: 2 * ringR, height: 2 * ringR)),
                   with: .color(hair), lineWidth: 0.8)
        ctx.stroke(Path(ellipseIn: CGRect(x: r - (ringR - 22), y: r - (ringR - 22),
                                          width: 2 * (ringR - 22), height: 2 * (ringR - 22))),
                   with: .color(faint), lineWidth: 0.5)
        // ticks every 5°
        for i in stride(from: 0, to: 360, by: 5) {
            let major = i % 30 == 0
            let big = i % 90 == 0
            let len: CGFloat = big ? 16 : (major ? 10 : 4)
            let w: CGFloat = big ? 1.4 : (major ? 1 : 0.5)
            let opacity = big ? 0.95 : (major ? 0.7 : 0.3)
            let angle = (Double(i) - 90 - heading) * .pi / 180
            let x1 = r + cos(angle) * ringR
            let y1 = r + sin(angle) * ringR
            let x2 = r + cos(angle) * (ringR - len)
            let y2 = r + sin(angle) * (ringR - len)
            var p = Path()
            p.move(to: CGPoint(x: x1, y: y1))
            p.addLine(to: CGPoint(x: x2, y: y2))
            ctx.stroke(p, with: .color(fg.opacity(opacity)), lineWidth: w)
        }
        // North pip — small red dot at the very top
        let pipAngle: Double = (-90 - heading) * .pi / 180
        let pipCos: CGFloat = CGFloat(cos(pipAngle))
        let pipSin: CGFloat = CGFloat(sin(pipAngle))
        let pipPos = CGPoint(x: r + pipCos * (ringR + 8),
                             y: r + pipSin * (ringR + 8))
        ctx.fill(Path(ellipseIn: CGRect(x: pipPos.x - 2.2, y: pipPos.y - 2.2,
                                        width: 4.4, height: 4.4)),
                 with: .color(lume))
    }

    private func drawTicks(ctx: GraphicsContext, r: CGFloat, ringR: CGFloat, heading: Double,
                           fg: Color, sub: Color, hair: Color, lume: Color) {
        ctx.stroke(Path(ellipseIn: CGRect(x: r - ringR, y: r - ringR,
                                          width: 2 * ringR, height: 2 * ringR)),
                   with: .color(hair), lineWidth: 0.6)
        for i in stride(from: 0, to: 360, by: 2) {
            let major = i % 30 == 0
            let big = i % 90 == 0
            let len: CGFloat = big ? 14 : (major ? 9 : 3)
            let w: CGFloat = big ? 1.2 : (major ? 0.9 : 0.4)
            let opacity = big ? 0.9 : (major ? 0.55 : 0.22)
            let angle = (Double(i) - 90 - heading) * .pi / 180
            let x1 = r + cos(angle) * ringR
            let y1 = r + sin(angle) * ringR
            let x2 = r + cos(angle) * (ringR - len)
            let y2 = r + sin(angle) * (ringR - len)
            var p = Path()
            p.move(to: CGPoint(x: x1, y: y1))
            p.addLine(to: CGPoint(x: x2, y: y2))
            ctx.stroke(p, with: .color(fg.opacity(opacity)), lineWidth: w)
        }
        // Fixed 12-o'clock chevron above the rim
        var chev = Path()
        chev.move(to: CGPoint(x: r, y: r - ringR - 10))
        chev.addLine(to: CGPoint(x: r - 5, y: r - ringR - 2))
        chev.addLine(to: CGPoint(x: r + 5, y: r - ringR - 2))
        chev.closeSubpath()
        ctx.fill(chev, with: .color(lume))
    }

    private func drawMinimal(ctx: GraphicsContext, r: CGFloat, ringR: CGFloat, heading: Double,
                             fg: Color, sub: Color, faint: Color, hair: Color, lume: Color) {
        ctx.stroke(Path(ellipseIn: CGRect(x: r - ringR, y: r - ringR,
                                          width: 2 * ringR, height: 2 * ringR)),
                   with: .color(hair), lineWidth: 0.8)
        for i in [0, 90, 180, 270] {
            let angle = (Double(i) - 90 - heading) * .pi / 180
            let x1 = r + cos(angle) * ringR
            let y1 = r + sin(angle) * ringR
            let x2 = r + cos(angle) * (ringR - 8)
            let y2 = r + sin(angle) * (ringR - 8)
            var p = Path()
            p.move(to: CGPoint(x: x1, y: y1))
            p.addLine(to: CGPoint(x: x2, y: y2))
            ctx.stroke(p, with: .color(fg.opacity(0.6)), lineWidth: 1)
        }
        // North pip on the rim
        let pipAngle: Double = (-90 - heading) * .pi / 180
        let pipCos: CGFloat = CGFloat(cos(pipAngle))
        let pipSin: CGFloat = CGFloat(sin(pipAngle))
        let pipPos = CGPoint(x: r + pipCos * ringR, y: r + pipSin * ringR)
        ctx.fill(Path(ellipseIn: CGRect(x: pipPos.x - 2.5, y: pipPos.y - 2.5,
                                        width: 5, height: 5)),
                 with: .color(lume))
        // crosshair
        var v = Path()
        v.move(to: CGPoint(x: r - 10, y: r))
        v.addLine(to: CGPoint(x: r + 10, y: r))
        ctx.stroke(v, with: .color(faint), lineWidth: 0.6)
        var h = Path()
        h.move(to: CGPoint(x: r, y: r - 10))
        h.addLine(to: CGPoint(x: r, y: r + 10))
        ctx.stroke(h, with: .color(faint), lineWidth: 0.6)
    }

    // MARK: center / cardinals overlays (Text — for crisp glyphs)

    @ViewBuilder
    private func roseCenter(r: CGFloat, fg: Color, sub: Color, faint: Color) -> some View {
        ZStack {
            // baseline rule
            Rectangle()
                .fill(faint)
                .frame(width: 60, height: 0.6)
                .offset(y: 18)
            VStack(spacing: 4) {
                Text(headingNumber)
                    .font(.system(size: 40, weight: .light, design: .default))
                    .monospacedDigit()
                    .tracking(-1)
                    .foregroundStyle(fg)
                Text(cardinalLabel(heading))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(3)
                    .foregroundStyle(sub)
                    .offset(y: -2)
            }
        }
        .frame(width: r * 2, height: r * 2)
    }

    @ViewBuilder
    private func ticksCenter(r: CGFloat, fg: Color, sub: Color) -> some View {
        VStack(spacing: 0) {
            Text(headingNumber.replacingOccurrences(of: "°", with: ""))
                .font(.system(size: 46, weight: .ultraLight, design: .default))
                .monospacedDigit()
                .tracking(-1.5)
                .foregroundStyle(fg)
            HStack(spacing: 28) {
                Text("HDG")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(sub)
                Text(cardinalLabel(heading))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(sub)
            }
        }
        .frame(width: r * 2, height: r * 2)
    }

    @ViewBuilder
    private func minimalCenter(r: CGFloat, sub: Color) -> some View {
        VStack {
            Spacer()
            Text("\(headingNumber)  \(cardinalLabel(heading))")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .monospacedDigit()
                .tracking(2)
                .foregroundStyle(sub)
            Spacer()
        }
        .padding(.top, r + 28)
        .frame(width: r * 2, height: r * 2)
    }

    @ViewBuilder
    private func cardinals(r: CGFloat, ringR: CGFloat, fg: Color, sub: Color, lume: Color) -> some View {
        let rr: CGFloat = {
            switch style {
            case .rose: return ringR - 14
            case .ticks: return ringR + 16
            case .minimal: return ringR + 18
            }
        }()
        ZStack {
            ForEach(["N", "E", "S", "W"], id: \.self) { letter in
                cardinalLetter(letter: letter, rr: rr, fg: fg, sub: sub, lume: lume)
            }
            if style == .rose {
                ForEach([30, 60, 120, 150, 210, 240, 300, 330], id: \.self) { deg in
                    degreeNumeral(deg: deg, ringR: ringR, sub: sub)
                }
            }
        }
        .frame(width: r * 2, height: r * 2)
    }

    private var headingNumber: String {
        let n = Int(heading.rounded())
        return String(format: "%03d°", n)
    }

    @ViewBuilder
    private func cardinalLetter(letter: String, rr: CGFloat, fg: Color, sub: Color, lume: Color) -> some View {
        let a: Double = {
            switch letter {
            case "N": return 0
            case "E": return 90
            case "S": return 180
            default: return 270
            }
        }()
        let angle: Double = (a - 90 - heading) * .pi / 180
        let x: CGFloat = CGFloat(cos(angle)) * rr
        let y: CGFloat = CGFloat(sin(angle)) * rr
        let isNorth = letter == "N"
        let isRose = style == .rose
        let size: CGFloat = (isNorth && isRose) ? 16 : 13
        let weight: Font.Weight = (isNorth && isRose) ? .semibold : .medium
        let color: Color = isNorth ? lume : (isRose ? fg : sub)
        Text(letter)
            .font(.system(size: size, weight: weight))
            .tracking(2)
            .foregroundStyle(color)
            .offset(x: x, y: y)
    }

    @ViewBuilder
    private func degreeNumeral(deg: Int, ringR: CGFloat, sub: Color) -> some View {
        let angle: Double = (Double(deg) - 90 - heading) * .pi / 180
        let rr: CGFloat = ringR - 30
        let x: CGFloat = CGFloat(cos(angle)) * rr
        let y: CGFloat = CGFloat(sin(angle)) * rr
        Text(String(format: "%03d", deg))
            .font(.system(size: 9, weight: .medium, design: .monospaced))
            .monospacedDigit()
            .tracking(0.5)
            .foregroundStyle(sub)
            .offset(x: x, y: y)
    }
}
