import SwiftUI

@main
struct archipelagoApp: App {
    @StateObject private var idleController = IdleWatcher()

    var body: some Scene {
        MenuBarExtra("Archipelago", systemImage: "hexagon.fill") {
            Button("Launch Saver Now") {
                idleController.triggerSaverManually()
            }
            Divider()
            Toggle("Prevent System Sleep", isOn: $idleController.isSleepPrevented)
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
    }
}
