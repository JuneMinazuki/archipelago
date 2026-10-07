import Foundation
import Combine
import IOKit.pwr_mgt
import AppKit

class IdleWatcher: ObservableObject {
    @Published var isSleepPrevented: Bool = true {
        didSet {
            toggleSleepAssertion(isSleepPrevented)
        }
    }

    private var assertionID: IOPMAssertionID = 0
    private var idleTimer: Timer?
    private let idleThresholdSeconds: TimeInterval = 60

    init() {
        toggleSleepAssertion(isSleepPrevented)
        startIdleMonitoring()
    }

    deinit {
        toggleSleepAssertion(false)
        idleTimer?.invalidate()
    }

    // MARK: - Prevents display/system sleep & lock
    private func toggleSleepAssertion(_ enable: Bool) {
        if enable {
            guard assertionID == 0 else { return }
            let reason = "Archipelago Custom Screensaver Active" as CFString
            let result = IOPMAssertionCreateWithName(
                kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason,
                &assertionID
            )
            if result != kIOReturnSuccess {
                print("Failed to create power assertion: \(result)")
            }
        } else {
            if assertionID != 0 {
                IOPMAssertionRelease(assertionID)
                assertionID = 0
            }
        }
    }

    // MARK: - Idle Polling
    private func startIdleMonitoring() {
        // Polls system idle time every 2 seconds
        idleTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkIdleTime()
        }
    }

    private func checkIdleTime() {
        // Reads macOS system-wide idle time across all events
        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: ~0)!
        )
        
        if idleSeconds >= idleThresholdSeconds {
            triggerSaver()
        }
    }

    // MARK: - Actions
    func triggerSaverManually() {
        triggerSaver()
    }

    private func triggerSaver() {
        // Placeholder for displaying your full-screen hexagon generator
        print("Screensaver triggered")
    }
}
