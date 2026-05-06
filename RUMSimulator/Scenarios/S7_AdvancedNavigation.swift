#if os(iOS)
import UIKit

// MARK: - S7: Advanced Navigation (Metadata Matrix)
//
// Systematic testing of all action types, triggers, and entries.
// Verifies that RUM captures the full context of navigation.

extension ScenarioLibrary {
    func s7() -> Scenario {
        let nav = playgroundCoordinator
        return Scenario(
            id: "S7",
            name: "Advanced Navigation Matrix",
            steps: [
                ScenarioStep(label: "Open Navigation Playground", action: {
                    nav?.openNavigationPlayground()
                }, delay: 1.0),

                // 1. Push via DeepLink (Internal Entry)
                ScenarioStep(label: "Push via DeepLink", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()
                }, delay: 1.0, triggerType: .deepLink, entryType: .internalFlow),

                // 2. Tab Switch via User Tap
                ScenarioStep(label: "Tab Switch (User Tap)", action: {
                    nav?.navigationPlaygroundVC?.simulateTabSwitch()
                }, delay: 0.8, triggerType: .userTap, entryType: .internalFlow),

                // 3. Present Modal via Notification (External Entry)
                ScenarioStep(label: "Present Modal (Notification)", action: {
                    nav?.navigationPlaygroundVC?.presentModal()
                }, delay: 1.2, triggerType: .notification, entryType: .external),

                // 4. Dismiss Modal via Programmatic
                ScenarioStep(label: "Dismiss Modal (Programmatic)", action: {
                    nav?.navigationPlaygroundVC?.dismissModal()
                }, delay: 0.8, triggerType: .programmatic),

                // 5. Replace Stack via Restored state
                ScenarioStep(label: "Replace Stack (Restored)", action: {
                    nav?.navigationPlaygroundVC?.replaceStack()
                }, delay: 1.2, triggerType: .restored, entryType: .restored),

                // 6. Unknown Action via System
                ScenarioStep(label: "Unknown Action (System)", action: {
                    nav?.navigationPlaygroundVC?.simulateUnknownAction()
                }, delay: 0.8, triggerType: .system),

                // 7. Pop Back via Gesture
                ScenarioStep(label: "Pop Back (Gesture)", action: {
                    nav?.navigationPlaygroundVC?.popOne()
                }, delay: 1.0, triggerType: .userGesture),

                // 8. Pop to Root via DeepLink
                ScenarioStep(label: "Pop to Root (DeepLink)", action: {
                    nav?.navigationPlaygroundVC?.popToRoot()
                }, delay: 1.0, triggerType: .deepLink),
            ],
            loop: false
        )
    }
}

#endif
