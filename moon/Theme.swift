import SwiftUI

enum Mode: String, Equatable {
    case day, twilight, night

    var isDay: Bool { self == .day }
    var isDark: Bool { self != .day }
}

func mode(forSunAltitude alt: Double) -> Mode {
    if alt > 6 { return .day }
    if alt > -6 { return .twilight }
    return .night
}

struct Palette {
    let bg: Color
    let mid: Color
    let edge: Color
    let ink: Color
    let inkSub: Color
    let recessedDark: Color
    let recessedLight: Color
    let inset: Color
    let groove: Color
    let knobTop: Color
    let knobMid: Color
    let knobBot: Color
    let accent: Color
    let displayLightInk: Color
    let displayDarkInk: Color
    let separator: Color
}

extension Mode {
    var palette: Palette {
        switch self {
        case .day:
            return Palette(
                bg: Color(hex: 0xC4C6C8),
                mid: Color(hex: 0xD2D4D6),
                edge: Color(hex: 0x8E9092),
                ink: Color(hex: 0x222428),
                inkSub: Color(hex: 0x222428).opacity(0.55),
                recessedDark: Color(hex: 0x1A1410),
                recessedLight: Color(hex: 0xD8DADC),
                inset: Color(hex: 0xB6B8BA),
                groove: Color(hex: 0x707274),
                knobTop: Color(hex: 0xE8EAEC),
                knobMid: Color(hex: 0xB8BABC),
                knobBot: Color(hex: 0x888A8C),
                accent: Color(hex: 0xE53935),
                displayLightInk: Color(hex: 0x222428),
                displayDarkInk: Color(hex: 0xD8DADC),
                separator: Color(hex: 0x222428).opacity(0.12)
            )
        case .twilight:
            return Palette(
                bg: Color(hex: 0x3C3D42),
                mid: Color(hex: 0x4A4B50),
                edge: Color(hex: 0x1C1D20),
                ink: Color(hex: 0xF4F1E8),
                inkSub: Color(hex: 0xF4F1E8).opacity(0.65),
                recessedDark: Color(hex: 0x0A0B0E),
                recessedLight: Color(hex: 0x252329),
                inset: Color(hex: 0x2A2C30),
                groove: Color(hex: 0x050608),
                knobTop: Color(hex: 0x44444C),
                knobMid: Color(hex: 0x1E1E26),
                knobBot: Color(hex: 0x0A0A10),
                accent: Color(hex: 0xE53935),
                displayLightInk: Color(hex: 0xE8ECF0),
                displayDarkInk: Color(hex: 0xE6E8EA),
                separator: Color(hex: 0xE8ECF5).opacity(0.08)
            )
        case .night:
            return Palette(
                bg: Color(hex: 0x3C3D42),
                mid: Color(hex: 0x4A4B50),
                edge: Color(hex: 0x1C1D20),
                ink: Color(hex: 0xF4F1E8),
                inkSub: Color(hex: 0xF4F1E8).opacity(0.65),
                recessedDark: Color(hex: 0x0A0B0E),
                recessedLight: Color(hex: 0x1C1D22),
                inset: Color(hex: 0x26282C),
                groove: Color(hex: 0x050608),
                knobTop: Color(hex: 0x44444C),
                knobMid: Color(hex: 0x1E1E26),
                knobBot: Color(hex: 0x0A0A10),
                accent: Color(hex: 0xE53935),
                displayLightInk: Color(hex: 0xE8ECF0),
                displayDarkInk: Color(hex: 0xE6E8EA),
                separator: Color(hex: 0xE8ECF5).opacity(0.08)
            )
        }
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}

// Embossed inset shadow used everywhere for recessed displays / panels.
struct InsetShadow: ViewModifier {
    let cornerRadius: CGFloat
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                    .blur(radius: 0.5)
                    .offset(y: 1)
                    .mask(RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.black.opacity(0.55), lineWidth: 1)
                    .blur(radius: 2)
                    .offset(y: 1)
                    .mask(RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)))
            )
    }
}

extension View {
    func recessed(cornerRadius: CGFloat = 6) -> some View {
        modifier(InsetShadow(cornerRadius: cornerRadius))
    }
}

// Procedurally-generated grain overlay — fine isotropic noise to approximate
// the soft-touch finish of brushed titanium. Renders via SwiftUI Canvas so it
// stays portable to watchOS.
struct GrainOverlay: View {
    let mode: Mode

    // Pre-computed deterministic grain points so the noise doesn't shimmer
    // on every frame. Seed-stable across launches.
    private static let points: [(CGFloat, CGFloat, Double)] = {
        var rng = SplitMix64(seed: 0xC0FFEE)
        var arr: [(CGFloat, CGFloat, Double)] = []
        arr.reserveCapacity(2400)
        for _ in 0..<2400 {
            let x = CGFloat(rng.nextUnit())
            let y = CGFloat(rng.nextUnit())
            let v = rng.nextUnit()
            arr.append((x, y, v))
        }
        return arr
    }()

    var body: some View {
        Canvas { ctx, size in
            for (fx, fy, v) in GrainOverlay.points {
                let rect = CGRect(x: fx * size.width, y: fy * size.height, width: 0.7, height: 0.7)
                let gray = Color(.sRGB, red: v, green: v, blue: v, opacity: 0.55)
                ctx.fill(Path(rect), with: .color(gray))
            }
        }
        .blendMode(.overlay)
        .opacity(mode.isDay ? 0.5 : 0.6)
        .allowsHitTesting(false)
    }
}

// Tiny seedable PRNG — deterministic noise without pulling Foundation random.
private struct SplitMix64 {
    var state: UInt64
    init(seed: UInt64) { self.state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func nextUnit() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
}
