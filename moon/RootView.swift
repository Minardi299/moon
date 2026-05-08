import SwiftUI
import CoreLocation

struct RootView: View {
    @EnvironmentObject var location: LocationManager
    @AppStorage("didOnboard") private var didOnboard: Bool = false
    @State private var didSeePermission: Bool = false

    var body: some View {
        Group {
            if !didOnboard {
                OnboardingView(onContinue: { didOnboard = true })
                    .transition(.opacity)
            } else if needsPermission {
                PermissionView(onContinue: { didSeePermission = true })
                    .transition(.opacity)
            } else {
                MainView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: didOnboard)
        .animation(.easeInOut(duration: 0.3), value: location.authorization)
    }

    private var needsPermission: Bool {
        switch location.authorization {
        case .authorizedWhenInUse, .authorizedAlways: return false
        default: return !didSeePermission && location.authorization != .authorizedWhenInUse
        }
    }
}
