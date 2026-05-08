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
            // Brushed aluminum / titanium silver. Cooler hue, brighter top
            // highlight, deeper bottom shadow → reads as machined metal.
            return Palette(
                bg: Color(hex: 0xCED1D5),
                mid: Color(hex: 0xE3E6E9),
                edge: Color(hex: 0x9DA1A5),
                ink: Color(hex: 0x1B1E22),
                inkSub: Color(hex: 0x1B1E22).opacity(0.55),
                recessedDark: Color(hex: 0x121418),
                recessedLight: Color(hex: 0xD7DADD),
                inset: Color(hex: 0xBDC1C5),
                groove: Color(hex: 0x6C7074),
                knobTop: Color(hex: 0xEEF1F3),
                knobMid: Color(hex: 0xBDC1C4),
                knobBot: Color(hex: 0x83878B),
                accent: Color(hex: 0xE53935),
                displayLightInk: Color(hex: 0x1B1E22),
                displayDarkInk: Color(hex: 0xD7DADD),
                separator: Color(hex: 0x1B1E22).opacity(0.12)
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

