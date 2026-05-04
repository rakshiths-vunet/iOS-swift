import Foundation

// MARK: - LoadMode

enum LoadMode: String, CaseIterable {
    case burst     = "Burst"
    case sustained = "Sustained"
    case mixed     = "Mixed"
}

// MARK: - LoadGenerator

/// Drives high-volume event generation in three modes:
/// - Burst: X actions in Y seconds using DispatchGroup
/// - Sustained: continuous moderate rate using a repeating timer
/// - Mixed: interleaved navigation, network, and tap events
final class LoadGenerator {

    private var sustainedTimer: Timer?
    private var isStopped = false
    private let logger: EventLogger

    init(logger: EventLogger) {
        self.logger = logger
    }

    // MARK: - Public API

    func start(mode: LoadMode, networkSimulator: NetworkSimulator? = nil) {
        isStopped = false
        switch mode {
        case .burst:     startBurst(networkSimulator: networkSimulator)
        case .sustained: startSustained()
        case .mixed:     startMixed(networkSimulator: networkSimulator)
        }
    }

    func stop() {
        isStopped = true
        sustainedTimer?.invalidate()
        sustainedTimer = nil
    }

    // MARK: - Burst mode (50 actions in 10 seconds)

    private func startBurst(networkSimulator: NetworkSimulator?, actionCount: Int = 50, duration: TimeInterval = 10) {
        let group = DispatchGroup()
        let interval = duration / Double(actionCount)

        for i in 0..<actionCount {
            let delay = interval * Double(i)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                guard let self = self, !self.isStopped else { return }
                self.logger.log(
                    type: "tap",
                    scenario: "LoadGenerator-Burst",
                    step: i,
                    metadata: ["burst_action": "\(i)"]
                )
                group.enter()
                if let net = networkSimulator {
                    Task {
                        _ = await net.fire(.get)
                        group.leave()
                    }
                } else {
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.logger.log(type: "load_complete", scenario: "LoadGenerator-Burst", step: nil, metadata: ["mode": "burst"])
        }
    }

    // MARK: - Sustained mode (5 actions/second)

    private func startSustained() {
        sustainedTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] _ in
            guard let self = self, !self.isStopped else { return }
            self.logger.log(
                type: "tap",
                scenario: "LoadGenerator-Sustained",
                step: nil,
                metadata: ["mode": "sustained"]
            )
        }
    }

    // MARK: - Mixed mode (nav + network + tap loop)

    private func startMixed(networkSimulator: NetworkSimulator?) {
        Task { [weak self] in
            guard let self = self else { return }
            var iteration = 0
            while !self.isStopped {
                // Simulate navigation
                await MainActor.run {
                    self.logger.log(type: "navigation", scenario: "LoadGenerator-Mixed", step: iteration, metadata: ["action": "push"])
                }
                try? await Task.sleep(nanoseconds: 200_000_000)

                // Simulate tap
                await MainActor.run {
                    self.logger.log(type: "tap", scenario: "LoadGenerator-Mixed", step: iteration, metadata: ["action": "tap"])
                }
                try? await Task.sleep(nanoseconds: 100_000_000)

                // Simulate network
                if let net = networkSimulator {
                    _ = await net.fire(.get)
                } else {
                    self.logger.log(type: "network", scenario: "LoadGenerator-Mixed", step: iteration, metadata: ["action": "simulated"])
                }
                try? await Task.sleep(nanoseconds: 300_000_000)

                iteration += 1
            }
        }
    }
}
