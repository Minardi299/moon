import SwiftUI

@main
struct moonApp: App {
    @StateObject private var location = LocationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(location)
                .preferredColorScheme(.dark)
                .statusBarHidden(false)
        }
    }
}
