import SwiftUI

@main
struct ArchipelagoApp: App {
    @StateObject private var idleController = IdleWatcher()
    @Environment(\.openSettings) private var openSettings

    var body: some Scene {
        MenuBarExtra("Archipelago", systemImage: idleController.isSleepPrevented ? "hexagon.fill" : "hexagon") {
            Button("Launch Saver Now") {
                idleController.triggerSaverManually()
            }
            Toggle("Prevent System Sleep", isOn: $idleController.isSleepPrevented)
            
            Divider()
            
            Button("Preferences") {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            }

            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            SettingsView()
        }
    }
}
