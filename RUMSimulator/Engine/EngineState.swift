#if os(iOS)
import Foundation
import Combine

// MARK: - AppMode

enum AppMode: String, CaseIterable {
    case manual = "Manual"
    case auto   = "Auto"
}

// MARK: - EngineState

/// Observable engine state bridged to the ControlPanel UI.
/// Uses ObservableObject for broad compatibility (iOS 16+).
final class EngineState: ObservableObject {
    @Published var isRunning: Bool      = false
    @Published var currentScenario: Scenario? = nil
    @Published var stepIndex: Int       = 0
    @Published var totalSteps: Int      = 0
    @Published var eventsPerSecond: Double = 0.0
    @Published var mode: AppMode        = .manual
    @Published var lastStepLabel: String = ""
}
#endif


