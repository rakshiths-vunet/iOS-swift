import Foundation
import Combine

// MARK: - ControlPanelViewModel

/// Observable state bridging EngineState to the ControlPanel UI.
final class ControlPanelViewModel: ObservableObject {

    // MARK: - Engine state (mirrored)
    @Published var isRunning: Bool = false
    @Published var currentScenarioName: String = "—"
    @Published var stepIndex: Int = 0
    @Published var totalSteps: Int = 0
    @Published var eventsPerSecond: Double = 0.0
    @Published var lastStepLabel: String = ""
    @Published var mode: AppMode = .manual

    // MARK: - Available scenarios
    var scenarios: [Scenario] = []
    var selectedScenarioIndex: Int = 0

    var selectedScenario: Scenario? {
        guard !scenarios.isEmpty else { return nil }
        return scenarios[min(selectedScenarioIndex, scenarios.count - 1)]
    }

    // MARK: - Engine reference

    private let engine: EngineStateLegacy
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(engineState: EngineStateLegacy) {
        self.engine = engineState
        bind()
    }

    // MARK: - Binding

    private func bind() {
        engine.$isRunning.receive(on: DispatchQueue.main).assign(to: &$isRunning)
        engine.$stepIndex.receive(on: DispatchQueue.main).assign(to: &$stepIndex)
        engine.$totalSteps.receive(on: DispatchQueue.main).assign(to: &$totalSteps)
        engine.$eventsPerSecond.receive(on: DispatchQueue.main).assign(to: &$eventsPerSecond)
        engine.$lastStepLabel.receive(on: DispatchQueue.main).assign(to: &$lastStepLabel)
        engine.$mode.receive(on: DispatchQueue.main).assign(to: &$mode)
        engine.$currentScenario
            .receive(on: DispatchQueue.main)
            .map { $0?.name ?? "—" }
            .assign(to: &$currentScenarioName)
    }

    // MARK: - Progress

    var progress: Double {
        guard totalSteps > 0 else { return 0 }
        return Double(stepIndex) / Double(totalSteps)
    }

    var progressText: String {
        guard totalSteps > 0 else { return "—" }
        return "Step \(stepIndex + 1) / \(totalSteps)"
    }
}
