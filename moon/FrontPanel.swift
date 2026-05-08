import SwiftUI

// The titanium front panel — a vertical metallic gradient. Wraps every
// screen so the day/twilight/night palette swap propagates.
struct FrontPanel<Content: View>: View {
    let mode: Mode
    @ViewBuilder var content: () -> Content

    var body: some View {
        let p = mode.palette
        ZStack {
            LinearGradient(
                colors: [p.mid, p.bg, p.bg, p.edge],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            content()
                .foregroundStyle(p.ink)
        }
        .background(p.bg)
    }
}
