#if os(iOS)
import Foundation

// MARK: - ScenarioStep

struct ScenarioStep {
    /// Human-readable label shown in the ControlPanel live readout
    let label: String
    /// Main-thread-safe closure executed by the engine
    let action: () -> Void
    /// Seconds before the next step fires (modified by speed multiplier)
    let delay: TimeInterval
    
    /// Optional navigation metadata
    let triggerType: NavTriggerType?
    let entryType: NavEntryType?

    init(label: String, action: @escaping () -> Void, delay: TimeInterval, triggerType: NavTriggerType? = nil, entryType: NavEntryType? = nil) {
        self.label = label
        self.action = action
        self.delay = delay
        self.triggerType = triggerType
        self.entryType = entryType
    }
}

// MARK: - Scenario

struct Scenario {
    let id: String
    let name: String
    let steps: [ScenarioStep]
    /// When true, the engine restarts automatically when the scenario completes
    let loop: Bool
}

#endif
