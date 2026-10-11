import SwiftUI

@main
struct VeltrixSecurityApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(minWidth: 900, minHeight: 620)
        }
        .windowStyle(.titleBar)
    }
}
