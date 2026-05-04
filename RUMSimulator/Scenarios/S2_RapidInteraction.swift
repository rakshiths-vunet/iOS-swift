#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

// MARK: - S2: Rapid Interaction Burst

extension ScenarioLibrary {
    func s2() -> Scenario {
        let nav = playgroundCoordinator
        return Scenario(
            id: "S2",
            name: "Rapid Interaction Burst",
            steps: [
                ScenarioStep(label: "Open Interaction Playground", action: {
                    nav?.openInteractionPlayground()
                }, delay: 0.8),
                ScenarioStep(label: "Tap Burst ×20", action: {
                    nav?.interactionPlaygroundVC?.simulateTapBurst(count: 20)
                }, delay: 2.0),
                ScenarioStep(label: "Scroll Down", action: {
                    nav?.interactionPlaygroundVC?.simulateScrollDown()
                }, delay: 0.8),
                ScenarioStep(label: "Scroll Up", action: {
                    nav?.interactionPlaygroundVC?.simulateScrollUp()
                }, delay: 0.8),
                ScenarioStep(label: "Long Press", action: {
                    nav?.interactionPlaygroundVC?.simulateLongPress()
                }, delay: 1.2),
                ScenarioStep(label: "Swipe Left", action: {
                    nav?.interactionPlaygroundVC?.simulateSwipeLeft()
                }, delay: 0.6),
                ScenarioStep(label: "Swipe Right", action: {
                    nav?.interactionPlaygroundVC?.simulateSwipeRight()
                }, delay: 0.6),
            ],
            loop: false
        )
    }
}

#endif