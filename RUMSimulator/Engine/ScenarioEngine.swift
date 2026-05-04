import Foundation

// MARK: - ScenarioEngine

/// Sequential async step executor with configurable speed multiplier.
/// All step actions run on MainActor. Supports stop and reset at any point.
final class ScenarioEngine {

    // MARK: - Dependencies

    private let stateLegacy: EngineStateLegacy
    private let logger: EventLogger

    // MARK: - Internal state

    private var isStopped = false
    private var runTask: Task<Void, Never>?

    // Event rate tracking
    private var eventCount: Int = 0
    private var rateWindow: Date = Date()
    private var rateTimer: Timer?

    // MARK: - Init

    init(state: EngineStateLegacy, logger: EventLogger) {
        self.stateLegacy = state
        self.logger = logger
    }

    // MARK: - Public API

    func run(scenario: Scenario, speedMultiplier: Double) {
        stop()
        isStopped = false
        eventCount = 0
        rateWindow = Date()

        DispatchQueue.main.async {
            self.stateLegacy.isRunning = true
            self.stateLegacy.currentScenario = scenario
            self.stateLegacy.stepIndex = 0
            self.stateLegacy.totalSteps = scenario.steps.count
            self.stateLegacy.lastStepLabel = ""
        }

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
        DispatchQueue.main.async {
            self.stateLegacy.isRunning = false
        }
    }

    func reset() {
        stop()
        DispatchQueue.main.async {
            self.stateLegacy.stepIndex = 0
            self.stateLegacy.totalSteps = 0
            self.stateLegacy.currentScenario = nil
            self.stateLegacy.eventsPerSecond = 0
            self.stateLegacy.lastStepLabel = ""
        }
        logger.clear()
    }

    // MARK: - Step execution loop

    private func executeScenario(_ scenario: Scenario, speedMultiplier: Double) async {
        repeat {
            for (index, step) in scenario.steps.enumerated() {
                guard !isStopped else { return }

                await MainActor.run {
                    self.stateLegacy.stepIndex = index
                    self.stateLegacy.lastStepLabel = step.label
                    step.action()
                }

                logger.log(
                    type: "step",
                    scenario: scenario.name,
                    step: index,
                    metadata: ["label": step.label]
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
            DispatchQueue.main.async {
                self.stateLegacy.isRunning = false
            }
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

    private func startRateTimer() {
        stopRateTimer()
        rateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let elapsed = Date().timeIntervalSince(self.rateWindow)
            let rate = elapsed > 0 ? Double(self.eventCount) / elapsed : 0
            DispatchQueue.main.async {
                self.stateLegacy.eventsPerSecond = (rate * 10).rounded() / 10
            }
        }
    }

    private func stopRateTimer() {
        rateTimer?.invalidate()
        rateTimer = nil
    }
}
