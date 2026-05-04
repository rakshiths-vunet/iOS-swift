import Foundation

// MARK: - DebugPanelViewModel

/// Observable state for Debug Panel controls.
final class DebugPanelViewModel: ObservableObject {
    /// Speed multiplier applied to all ScenarioEngine step delays (0.5× – 5×)
    @Published var speedMultiplier: Double = 1.0
    /// When true, all NetworkSimulator requests prepend /delay/3
    @Published var networkDelayEnabled: Bool = false
    /// Fraction (0.0–1.0) of requests that return a fake error without hitting the network
    @Published var failureRate: Double = 0.0
}
