import Foundation
import SwiftUI
import Combine

final class SaverSettings: ObservableObject {
    static let shared = SaverSettings()

    @AppStorage("idleThresholdMinutes") var idleThresholdMinutes: Double = 5.0 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("animationDuration") var animationDuration: Double = 10.0 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("holdDuration") var holdDuration: Double = 15.0 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("fadeDuration") var fadeDuration: Double = 5.0 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("darkFilter") var darkFilter: Double = 0.5 {
        didSet { objectWillChange.send() }
    }
    
    @AppStorage("showCustomText") var showCustomText: Bool = true {
        didSet { objectWillChange.send() }
    }

    @AppStorage("customBottomText") var customBottomText: String = {
        return Host.current().localizedName ?? "MacBook Pro"
    }() {
        didSet { objectWillChange.send() }
    }
}
