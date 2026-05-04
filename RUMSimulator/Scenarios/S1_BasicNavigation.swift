#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

// MARK: - S1: Basic Navigation Flow

extension ScenarioLibrary {
    func s1() -> Scenario {
        let nav = playgroundCoordinator
        return Scenario(
            id: "S1",
            name: "Basic Navigation Flow",
            steps: [
                ScenarioStep(label: "Open Navigation Playground", action: {
                    nav?.openNavigationPlayground()
                }, delay: 0.8),
                ScenarioStep(label: "Push Level A", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()
                }, delay: 0.6),
                ScenarioStep(label: "Push Level B", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()
                }, delay: 0.6),
                ScenarioStep(label: "Push Level C", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()
                }, delay: 0.6),
                ScenarioStep(label: "Push Level D", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()
                }, delay: 0.8),
                ScenarioStep(label: "Pop to Root", action: {
                    nav?.navigationPlaygroundVC?.popToRoot()
                }, delay: 1.0),
                ScenarioStep(label: "Present Modal", action: {
                    nav?.navigationPlaygroundVC?.presentModal()
                }, delay: 1.0),
                ScenarioStep(label: "Dismiss Modal", action: {
                    nav?.navigationPlaygroundVC?.dismissModal()
                }, delay: 0.8),
            ],
            loop: false
        )
    }
}

#endif