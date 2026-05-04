import Foundation

// MARK: - S5: Cold Start Simulation

extension ScenarioLibrary {
    func s5() -> Scenario {
        let net = networkSimulator
        let nav = playgroundCoordinator
        return Scenario(
            id: "S5",
            name: "Cold Start Simulation",
            steps: [
                // Immediate nav + network calls within 500ms (concurrent)
                ScenarioStep(label: "Cold Start: Push screen + fire network (concurrent)", action: {
                    // Navigation (UIKit)
                    nav?.navigationPlaygroundVC?.pushLevel()
                    // Concurrent network call — fired at same time
                    Task { _ = await net.fire(.get) }
                }, delay: 0.5),
                ScenarioStep(label: "Cold Start: Second push", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()
                }, delay: 0.4),
                ScenarioStep(label: "Cold Start: Network call 2", action: {
                    Task { _ = await net.fire(.delay(1)) }
                }, delay: 1.5),
                ScenarioStep(label: "Cold Start: Pop to root", action: {
                    nav?.navigationPlaygroundVC?.popToRoot()
                }, delay: 0.5),
            ],
            loop: false
        )
    }
}
