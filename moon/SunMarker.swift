import SwiftUI

// Engraved sun: outer hairline ring, 12 tiny rays, solid disk core.
// No glow, no flares — matches the industrial aesthetic of compass.jsx.
struct SunMarker: View {
    var selected: Bool = false
    var dark: Bool = false
    var accent: Color = Color(hex: 0xE53935)

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let scale = size.width / 38

            // 12 hairline rays
            for i in 0..<12 {
                let a = Double(i) * 30 * .pi / 180
                let inner = 14.0 * scale
                let outer = 18.0 * scale
                var p = Path()
                p.move(to: CGPoint(x: cx + cos(a) * inner, y: cy + sin(a) * inner))
                p.addLine(to: CGPoint(x: cx + cos(a) * outer, y: cy + sin(a) * outer))
                ctx.stroke(p, with: .color(accent.opacity(0.85)),
                           style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
            }
            // outer engraved ring
            let ring = CGRect(x: cx - 12 * scale, y: cy - 12 * scale,
                              width: 24 * scale, height: 24 * scale)
            ctx.stroke(Path(ellipseIn: ring), with: .color(accent.opacity(0.6)), lineWidth: 0.7)
            // solid disk
            let disk = CGRect(x: cx - 9 * scale, y: cy - 9 * scale,
                              width: 18 * scale, height: 18 * scale)
            ctx.fill(Path(ellipseIn: disk), with: .color(accent))
            // inner concentric ring
            let inner = CGRect(x: cx - 6 * scale, y: cy - 6 * scale,
                               width: 12 * scale, height: 12 * scale)
            ctx.stroke(Path(ellipseIn: inner), with: .color(accent.opacity(0.45)), lineWidth: 0.6)
            // center dot
            let dot = CGRect(x: cx - 1.5 * scale, y: cy - 1.5 * scale,
                             width: 3 * scale, height: 3 * scale)
            ctx.fill(Path(ellipseIn: dot), with: .color(accent.opacity(0.7)))
            // selection halo
            if selected {
                let halo = CGRect(x: cx - 16 * scale, y: cy - 16 * scale,
                                  width: 32 * scale, height: 32 * scale)
                ctx.stroke(Path(ellipseIn: halo), with: .color(accent.opacity(0.6)), lineWidth: 0.6)
            }
        }
        .scaleEffect(selected ? 1.08 : 1.0)
        .animation(.easeOut(duration: 0.12), value: selected)
        .contentShape(Rectangle())
    }
}
