#if os(iOS)
import Foundation

// MARK: - ScenarioEngine

/// Sequential async step executor with configurable speed multiplier.
/// All step actions run on MainActor. Supports stop and reset at any point.
@MainActor
final class ScenarioEngine {

    // MARK: - Dependencies

    private let state: EngineState
    private let logger: EventLogger

    // MARK: - Internal state

    private var isStopped = false
    private var runTask: Task<Void, Never>?

    // Event rate tracking
    private var eventCount: Int = 0
    private var rateWindow: Date = Date()
    private var rateTimer: Timer?

    // MARK: - Init

    init(state: EngineState, logger: EventLogger) {
        self.state = state
        self.logger = logger
    }

    // MARK: - Public API

    func run(scenario: Scenario, speedMultiplier: Double) {
        stop()
        isStopped = false
        eventCount = 0
        rateWindow = Date()

        self.state.isRunning = true
        self.state.currentScenario = scenario
        self.state.stepIndex = 0
        self.state.totalSteps = scenario.steps.count
        self.state.lastStepLabel = ""

        startRateTimer()

        runTask = Task {
            await self.executeScenario(scenario, speedMultiplier: speedMultiplier)
        }
    }

    func stop() {
        isStopped = true
        runTask?.cancel()
        runTask = nil
        stopRateTimer()
        self.state.isRunning = false
    }

    func reset() {
        stop()
        self.state.stepIndex = 0
        self.state.totalSteps = 0
        self.state.currentScenario = nil
        self.state.eventsPerSecond = 0
        self.state.lastStepLabel = ""
        logger.clear()
    }

    // MARK: - Step execution loop

    private func executeScenario(_ scenario: Scenario, speedMultiplier: Double) async {
        repeat {
            for (index, step) in scenario.steps.enumerated() {
                guard !isStopped else { return }

                self.state.stepIndex = index
                self.state.lastStepLabel = step.label
                step.action()

                var logMetadata = ["label": step.label]
                if let trigger = step.triggerType { logMetadata["triggerType"] = trigger.rawValue }
                if let entry = step.entryType { logMetadata["entryType"] = entry.rawValue }

                logger.log(
                    type: "step",
                    scenario: scenario.name,
                    step: index,
                    metadata: logMetadata
                )

                eventCount += 1

                let adjustedDelay = step.delay / max(speedMultiplier, 0.1)
                if adjustedDelay > 0 {
                    try? await Task.sleep(nanoseconds: UInt64(adjustedDelay * 1_000_000_000))
                }
            }

            if scenario.loop && !isStopped {
                // Log loop restart
                logger.log(
                    type: "scenario_loop",
                    scenario: scenario.name,
                    step: nil,
                    metadata: ["event": "loop_restart"]
                )
            }
        } while scenario.loop && !isStopped

        // Scenario ended
        if !isStopped {
            self.state.isRunning = false
            logger.log(
                type: "scenario_end",
                scenario: scenario.name,
                step: nil,
                metadata: ["total_steps": "\(scenario.steps.count)"]
            )
            logger.flush()
        }
    }

    // MARK: - Event rate calculation

    /// Log a step manually (used by the ControlPanel Matrix Trigger)
    func logManualStep(label: String, trigger: NavTriggerType, entry: NavEntryType) {
        var logMetadata = ["label": label, "source": "manual_matrix"]
        logMetadata["triggerType"] = trigger.rawValue
        logMetadata["entryType"] = entry.rawValue
        
        logger.log(
            type: "step",
            scenario: "Manual Matrix",
            step: nil,
            metadata: logMetadata
        )
        
        self.state.lastStepLabel = label
        eventCount += 1
    }

    private func startRateTimer() {
        stopRateTimer()
        rateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let elapsed = Date().timeIntervalSince(self.rateWindow)
            let rate = elapsed > 0 ? Double(self.eventCount) / elapsed : 0
            self.state.eventsPerSecond = (rate * 10).rounded() / 10
        }
    }

    private func stopRateTimer() {
        rateTimer?.invalidate()
        rateTimer = nil
    }
}

#endif

