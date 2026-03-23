import SwiftUI

@main
struct M1DDCControlApp: App {
    @StateObject private var launchAtLogin = LaunchAtLoginManager()

    var body: some Scene {
        MenuBarExtra("M1DDCControl", systemImage: "sun.max.fill") {
            ContentView()
                .environmentObject(launchAtLogin)
        }
        .menuBarExtraStyle(.window)
    }
}
