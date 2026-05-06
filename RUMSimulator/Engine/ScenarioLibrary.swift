#if os(iOS)
import UIKit

// MARK: - ScenarioLibrary

/// Factory returning all 6 predefined Scenario instances.
/// Scenarios reference playground controllers via weak closures to avoid retain cycles.
@MainActor
final class ScenarioLibrary {

    weak var playgroundCoordinator: PlaygroundCoordinator?
    let networkSimulator: NetworkSimulator

    init(networkSimulator: NetworkSimulator) {
        self.networkSimulator = networkSimulator
    }

    func all() -> [Scenario] {
        [s1(), s2(), s3(), s4(), s5(), s6(), s7(), s8(), s9()]
    }
}

#endif