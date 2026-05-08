import SwiftUI

// Recessed CRT/LCD inset. Two variants: dark (the LCD readout) and light
// (the embossed label area). Match the screens.jsx Display() function.
struct DisplayBox<Content: View>: View {
    let mode: Mode
    var dark: Bool = false
    var cornerRadius: CGFloat = 6
    var horizontalPadding: CGFloat = 14
    var verticalPadding: CGFloat = 10
    @ViewBuilder var content: () -> Content

    var body: some View {
        let p = mode.palette
        let bg = dark ? p.recessedDark : p.recessedLight
        let ink = dark ? p.displayDarkInk : p.displayLightInk
        content()
            .foregroundStyle(ink)
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(bg)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.black.opacity(0.55), lineWidth: 1.2)
                    .blur(radius: 1.2)
                    .offset(y: 1.5)
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(LinearGradient(
                                colors: [.black, .clear],
                                startPoint: .top, endPoint: .center))
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.6)
                    .offset(y: 0.5)
                    .mask(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(LinearGradient(
                                colors: [.clear, .white],
                                startPoint: .top, endPoint: .bottom))
                    )
            )
    }
}

// Tabular-numeric monospace style applied inside dark Display boxes.
struct DisplayTextStyle: ViewModifier {
    var fontSize: CGFloat = 16
    var letterSpacing: CGFloat = 0.5
    func body(content: Content) -> some View {
        content
            .font(.system(size: fontSize, weight: .medium, design: .monospaced))
            .monospacedDigit()
            .tracking(letterSpacing)
    }
}

extension View {
    func displayText(size: CGFloat = 16, tracking: CGFloat = 0.5) -> some View {
        modifier(DisplayTextStyle(fontSize: size, letterSpacing: tracking))
    }
}
