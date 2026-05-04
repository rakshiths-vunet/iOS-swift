import UIKit

// MARK: - S1: Basic Navigation Flow

extension ScenarioLibrary {
    func s1() -> Scenario {
        let nav = playgroundCoordinator
        return Scenario(
            id: "S1",
            name: "Basic Navigation Flow",
            steps: [
                ScenarioStep(label: "Open Navigation Playground") {
                    nav?.openNavigationPlayground()
                } delay: { 0.8 }(),
                ScenarioStep(label: "Push Level A") {
                    nav?.navigationPlaygroundVC?.pushLevel()
                } delay: { 0.6 }(),
                ScenarioStep(label: "Push Level B") {
                    nav?.navigationPlaygroundVC?.pushLevel()
                } delay: { 0.6 }(),
                ScenarioStep(label: "Push Level C") {
                    nav?.navigationPlaygroundVC?.pushLevel()
                } delay: { 0.6 }(),
                ScenarioStep(label: "Push Level D") {
                    nav?.navigationPlaygroundVC?.pushLevel()
                } delay: { 0.8 }(),
                ScenarioStep(label: "Pop to Root") {
                    nav?.navigationPlaygroundVC?.popToRoot()
                } delay: { 1.0 }(),
                ScenarioStep(label: "Present Modal") {
                    nav?.navigationPlaygroundVC?.presentModal()
                } delay: { 1.0 }(),
                ScenarioStep(label: "Dismiss Modal") {
                    nav?.navigationPlaygroundVC?.dismissModal()
                } delay: { 0.8 }(),
            ],
            loop: false
        )
    }
}

// MARK: - Helper to use trailing closure as value

private func delay(_ value: TimeInterval) -> TimeInterval { value }

extension ScenarioStep {
    init(label: String, action: @escaping () -> Void, delay: () -> TimeInterval) {
        self.init(label: label, action: action, delay: delay())
    }
}
