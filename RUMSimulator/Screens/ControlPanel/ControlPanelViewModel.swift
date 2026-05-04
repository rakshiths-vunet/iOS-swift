#if os(iOS)
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

    private let engine: EngineState
    private var cancellables: Set<AnyCancellable> = []

    // MARK: - Init

    init(engineState: EngineState) {
        self.engine = engineState
        bind()
    }

    // MARK: - Binding

    private func bind() {
        engine.$isRunning.receive(on: DispatchQueue.main).sink { [weak self] in self?.isRunning = $0 }.store(in: &cancellables)
        engine.$stepIndex.receive(on: DispatchQueue.main).sink { [weak self] in self?.stepIndex = $0 }.store(in: &cancellables)
        engine.$totalSteps.receive(on: DispatchQueue.main).sink { [weak self] in self?.totalSteps = $0 }.store(in: &cancellables)
        engine.$eventsPerSecond.receive(on: DispatchQueue.main).sink { [weak self] in self?.eventsPerSecond = $0 }.store(in: &cancellables)
        engine.$lastStepLabel.receive(on: DispatchQueue.main).sink { [weak self] in self?.lastStepLabel = $0 }.store(in: &cancellables)
        engine.$mode.receive(on: DispatchQueue.main).sink { [weak self] in self?.mode = $0 }.store(in: &cancellables)
        engine.$currentScenario
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sc in
                self?.currentScenarioName = sc?.name ?? "—"
            }
            .store(in: &cancellables)
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

#endif

