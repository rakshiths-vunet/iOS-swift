import Foundation
import Combine

// MARK: - AppMode

enum AppMode: String, CaseIterable {
    case manual = "Manual"
    case auto   = "Auto"
}

// MARK: - EngineState

/// Observable engine state bridged to the ControlPanel UI.
/// Uses @Observable (iOS 17+) with ObservableObject fallback.
@available(iOS 17.0, *)
@Observable
final class EngineState {
    var isRunning: Bool      = false
    var currentScenario: Scenario? = nil
    var stepIndex: Int       = 0
    var totalSteps: Int      = 0
    var eventsPerSecond: Double = 0.0
    var mode: AppMode        = .manual
    var lastStepLabel: String = ""
}

// MARK: - EngineStateLegacy (iOS 16 fallback)

final class EngineStateLegacy: ObservableObject {
    @Published var isRunning: Bool      = false
    @Published var currentScenario: Scenario? = nil
    @Published var stepIndex: Int       = 0
    @Published var totalSteps: Int      = 0
    @Published var eventsPerSecond: Double = 0.0
    @Published var mode: AppMode        = .manual
    @Published var lastStepLabel: String = ""
}
