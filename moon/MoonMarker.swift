import SwiftUI

// Terminator-correct crescent. The lit region is bounded by an outer
// circular half-arc (the disk's lit limb) and an inner elliptical half-arc
// (the terminator). The ellipse's half-width Rx is 0 at quarter-phase and
// equals the disk radius at new/full. Phase 0 = new, 0.25 = first quarter
// (right half lit), 0.5 = full, 0.75 = last quarter.
struct MoonMarker: View {
    var phase: Double
    var selected: Bool = false
    var dark: Bool = false

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            let cy = size.height / 2
            let scale = size.width / 32
            let R = 11.0 * scale
            let lit = dark ? Color(hex: 0xECE4CF) : Color(hex: 0xF6EFD9)
            let shadow = dark ? Color(hex: 0x2A2F44) : Color(hex: 0xB9B39C)
            let ink = dark ? Color(hex: 0xE8E2D1).opacity(0.45) : Color(hex: 0x1A1A1F).opacity(0.4)

            // Shadowed full disk
            let disk = CGRect(x: cx - R, y: cy - R, width: 2 * R, height: 2 * R)
            ctx.fill(Path(ellipseIn: disk), with: .color(shadow))

            // Lit region (sampled arcs)
            let lp = MoonMarker.litPath(cx: cx, cy: cy, R: R, phase: phase)
            ctx.fill(lp, with: .color(lit))

            // Subtle craters clipped to lit region
            let craters: [(CGFloat, CGFloat, CGFloat)] = [
                (-3, -4, 1.1), (2, -2, 0.7), (-1, 2, 0.9), (3, 3, 0.6), (-2.5, 0, 0.5),
            ]
            ctx.drawLayer { layer in
                layer.clip(to: lp)
                for (dx, dy, rr) in craters {
                    let cr = rr * scale
                    let p = Path(ellipseIn: CGRect(x: cx + dx * scale - cr,
                                                    y: cy + dy * scale - cr,
                                                    width: 2 * cr, height: 2 * cr))
                    layer.fill(p, with: .color(shadow.opacity(0.22)))
                }
            }

            // Engraved outline
            ctx.stroke(Path(ellipseIn: disk), with: .color(ink), lineWidth: 0.6)

            if selected {
                let h = R + 4 * scale
                ctx.stroke(Path(ellipseIn: CGRect(x: cx - h, y: cy - h, width: 2 * h, height: 2 * h)),
                           with: .color(lit.opacity(0.6)), lineWidth: 0.5)
            }
        }
        .scaleEffect(selected ? 1.08 : 1.0)
        .animation(.easeOut(duration: 0.12), value: selected)
        .contentShape(Rectangle())
    }

    // Builds the lit-side path: outer circular arc (lit limb) + inner
    // elliptical arc (terminator). Sampled at 48 points for smoothness.
    static func litPath(cx: CGFloat, cy: CGFloat, R: CGFloat, phase: Double) -> Path {
        let k = (1 - cos(phase * 2 * .pi)) / 2          // illumination fraction 0..1
        let waxing = phase < 0.5
        let Rx = R * CGFloat(abs(1 - 2 * k))            // half-width of terminator ellipse

        // Outer arc side: +1 = right half (waxing), -1 = left half (waning)
        let outerSign: CGFloat = waxing ? 1 : -1

        // Inner ellipse bulge direction:
        //   waxing crescent (k<0.5) → terminator ellipse bulges into the lit (right) → -1 then mirrored... no.
        //   The terminator ellipse is centered on the disk; its half-width is Rx.
        //   For waxing crescent: lit region is a thin right sliver; terminator bulges LEFT into shadow.
        //   For waxing gibbous:  lit region is most of disk minus a small left ellipse; terminator bulges RIGHT into shadow.
        //   For waning crescent: symmetric (lit on left, terminator bulges RIGHT into shadow).
        //   For waning gibbous:  symmetric (lit most of disk, terminator bulges LEFT into shadow).
        // In all cases, "into shadow" = away from the lit side.
        // So bulgeSign points AWAY from outerSign for crescents, TOWARD outerSign for gibbous.
        let bulgeSign: CGFloat = {
            if k < 0.5 { return -outerSign }
            return outerSign
        }()

        var p = Path()
        let steps = 48
        // Outer half-arc from top (cx, cy-R) to bottom (cx, cy+R) on the lit side.
        p.move(to: CGPoint(x: cx, y: cy - R))
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let angle = -(.pi / 2) + t * .pi              // -90° → +90°
            let x = cx + outerSign * R * CGFloat(cos(angle))
            let y = cy + R * CGFloat(sin(angle))
            p.addLine(to: CGPoint(x: x, y: y))
        }
        // Inner elliptical arc from bottom back up to top.
        for i in 1...steps {
            let t = Double(i) / Double(steps)
            let angle = (.pi / 2) - t * .pi               // +90° → -90°
            let x = cx + bulgeSign * Rx * CGFloat(cos(angle))
            let y = cy + R * CGFloat(sin(angle))
            p.addLine(to: CGPoint(x: x, y: y))
        }
        p.closeSubpath()
        return p
    }
}
