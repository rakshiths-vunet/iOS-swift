#if os(iOS)
import UIKit

// MARK: - S9: SwiftUI Navigation
//
// Verifies RUM capture of SwiftUI-specific navigation actions.
// Uses the SwiftUINavPlayground via UIHostingController.

extension ScenarioLibrary {
    func s9() -> Scenario {
        let nav = playgroundCoordinator
        return Scenario(
            id: "S9",
            name: "SwiftUI Navigation Flow",
            steps: [
                ScenarioStep(label: "Open SwiftUI Playground", action: {
                    nav?.openSwiftUINavigationPlayground()
                }, delay: 1.0),

                ScenarioStep(label: "Push Level 1", action: {
                    nav?.swiftUINavCoordinator?.push()
                }, delay: 1.0, triggerType: .userTap),

                ScenarioStep(label: "Push Level 2", action: {
                    nav?.swiftUINavCoordinator?.push()
                }, delay: 1.0, triggerType: .userTap),

                ScenarioStep(label: "Present Modal", action: {
                    nav?.swiftUINavCoordinator?.presentModal()
                }, delay: 1.2, triggerType: .programmatic),

                ScenarioStep(label: "Dismiss Modal", action: {
                    nav?.swiftUINavCoordinator?.dismissModal()
                }, delay: 1.0, triggerType: .userTap),

                ScenarioStep(label: "Pop One Level", action: {
                    nav?.swiftUINavCoordinator?.popOne()
                }, delay: 0.8, triggerType: .userGesture),

                ScenarioStep(label: "Pop to Root", action: {
                    nav?.swiftUINavCoordinator?.popToRoot()
                }, delay: 1.0, triggerType: .deepLink),
            ],
            loop: false
        )
    }
}

#endif
