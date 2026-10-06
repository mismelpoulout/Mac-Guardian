import SwiftUI

@main
struct MacGuardianApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 900, minHeight: 620)
        }
        .windowStyle(.titleBar)
    }
}
