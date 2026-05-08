import SwiftUI

// The green-leather-pull style toggle from the design.
struct KnurledToggle: View {
    @Binding var isOn: Bool
    var mode: Mode = .night

    var body: some View {
        let p = mode.palette
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                RoundedRectangle(cornerRadius: 11)
                    .fill(
                        isOn
                        ? LinearGradient(colors: [Color(hex: 0x2C8A48), Color(hex: 0x1A5C30)],
                                         startPoint: .top, endPoint: .bottom)
                        : LinearGradient(colors: [p.groove, p.groove],
                                         startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 38, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 11)
                            .stroke(Color.black.opacity(0.4), lineWidth: 0.8)
                            .offset(y: 1)
                            .mask(RoundedRectangle(cornerRadius: 11)
                                .fill(LinearGradient(colors: [.black, .clear],
                                                     startPoint: .top, endPoint: .bottom)))
                    )
                Circle()
                    .fill(LinearGradient(colors: [Color(hex: 0xECEFF2), Color(hex: 0xB6B8BA)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 20, height: 20)
                    .padding(1)
                    .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
            }
        }
        .buttonStyle(.plain)
    }
}
