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

    @Published var isSaverActive: Bool = false

    private var assertionID: IOPMAssertionID = 0
    private var idleTimer: Timer?
    private let idleThresholdSeconds: TimeInterval = 5
    
    private var eventMonitor: Any?
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    private var initialMouseLocation: NSPoint?

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

    // Check if another app is keeping the display awake
    private func isOtherAppPreventingDisplaySleep() -> Bool {
        var assertionsByProcess: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&assertionsByProcess) == kIOReturnSuccess,
              let processDict = assertionsByProcess?.takeRetainedValue() as? [pid_t: [[String: Any]]] else {
            return false
        }

        let myPID = ProcessInfo.processInfo.processIdentifier

        for (pid, assertions) in processDict {
            // Ignore power assertions created by app itself
            if pid == myPID { continue }

            for assertion in assertions {
                guard let assertionType = assertion[kIOPMAssertionTypeKey as String] as? String else { continue }

                // Check for display sleep prevention assertions created during media playback
                if assertionType == (kIOPMAssertionTypePreventUserIdleDisplaySleep as String) ||
                   assertionType == "NoDisplaySleepAssertion" {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Idle Polling
    private func startIdleMonitoring() {
        // Polls system idle time every 2 seconds
        idleTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.checkIdleTime()
        }
    }

    private func checkIdleTime() {
        // Suppress if media/calls/presentations are active
        if isOtherAppPreventingDisplaySleep() {
            if isSaverActive { dismissSaver() }
            return
        }

        // Fetch system idle time
        let idleSeconds = CGEventSource.secondsSinceLastEventType(
            .combinedSessionState,
            eventType: CGEventType(rawValue: ~0)!
        )

        if idleSeconds >= idleThresholdSeconds && !isSaverActive {
            triggerSaver()
        }
    }

    // MARK: - Actions
    func triggerSaverManually() {
        if !isSaverActive {
            triggerSaver()
        }
    }

    private func triggerSaver() {
        // Placeholder for displaying your full-screen hexagon generator
        isSaverActive = true
        print("Screensaver triggered")

        // Wait a fraction of a second before monitoring
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self, self.isSaverActive else { return }
            self.startDismissalMonitoring()
        }
    }

    private func startDismissalMonitoring() {
        stopDismissalMonitoring()
        
        initialMouseLocation = NSEvent.mouseLocation
        let eventMask: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDown, .rightMouseDown, .keyDown]

        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleDismissalEvent(event)
        }

        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: eventMask) { [weak self] event in
            self?.handleDismissalEvent(event)
            return event
        }
    }

    private func handleDismissalEvent(_ event: NSEvent) {
        if event.type == .mouseMoved {
            guard let initial = initialMouseLocation else { return }
            let current = NSEvent.mouseLocation
            let dx = current.x - initial.x
            let dy = current.y - initial.y
            let distance = hypot(dx, dy)

            // Dismiss if mouse moved noticeably
            if distance > 10 {
                DispatchQueue.main.async { [weak self] in
                    self?.dismissSaver()
                }
            }
        } else {
            // Dismiss if keyboard tap or mouse click
            DispatchQueue.main.async { [weak self] in
                self?.dismissSaver()
            }
        }
    }

    private func stopDismissalMonitoring() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
        }
        initialMouseLocation = nil
    }
    
    private func dismissSaver() {
        // Placeholder for closing your full-screen hexagon generator
        stopDismissalMonitoring()
        isSaverActive = false
        print("Screensaver dismissed")
    }
}
