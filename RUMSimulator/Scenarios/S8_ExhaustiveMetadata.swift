#if os(iOS)
import UIKit

// MARK: - S8: Exhaustive Metadata Trigger
//
// This scenario ensures EVERY SINGLE enum case for Trigger, Entry, and Action types 
// is programmatically triggered at least once.

extension ScenarioLibrary {
    func s8() -> Scenario {
        let nav = playgroundCoordinator
        return Scenario(
            id: "S8",
            name: "Exhaustive Metadata Trigger",
            steps: [
                ScenarioStep(label: "Setup: Open Playground", action: {
                    nav?.openNavigationPlayground()
                }, delay: 1.0),

                // --- TRIGGER TYPES ---
                ScenarioStep(label: "Trigger: User Tap", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, triggerType: .userTap),
                ScenarioStep(label: "Trigger: User Gesture", action: { nav?.navigationPlaygroundVC?.popOne() }, delay: 0.5, triggerType: .userGesture),
                ScenarioStep(label: "Trigger: Programmatic", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, triggerType: .programmatic),
                ScenarioStep(label: "Trigger: System", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, triggerType: .system),
                ScenarioStep(label: "Trigger: DeepLink", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, triggerType: .deepLink),
                ScenarioStep(label: "Trigger: Notification", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, triggerType: .notification),
                ScenarioStep(label: "Trigger: Restored", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, triggerType: .restored),
                ScenarioStep(label: "Trigger: Unknown", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, triggerType: .unknown),

                // --- ENTRY TYPES ---
                ScenarioStep(label: "Entry: Internal Flow", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, entryType: .internalFlow),
                ScenarioStep(label: "Entry: DeepLink", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, entryType: .deepLink),
                ScenarioStep(label: "Entry: External", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, entryType: .external),
                ScenarioStep(label: "Entry: Notification", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, entryType: .notification),
                ScenarioStep(label: "Entry: Restored", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, entryType: .restored),
                ScenarioStep(label: "Entry: Unknown", action: { nav?.navigationPlaygroundVC?.pushLevel() }, delay: 0.5, entryType: .unknown),

                // --- ACTION TYPES (using appropriate triggering) ---
                ScenarioStep(label: "Action: Tab Switch", action: { nav?.navigationPlaygroundVC?.simulateTabSwitch() }, delay: 0.6),
                ScenarioStep(label: "Action: Replace", action: { nav?.navigationPlaygroundVC?.replaceStack() }, delay: 0.6),
                ScenarioStep(label: "Action: Present", action: { nav?.navigationPlaygroundVC?.presentModal() }, delay: 0.8),
                ScenarioStep(label: "Action: Dismiss", action: { nav?.navigationPlaygroundVC?.dismissModal() }, delay: 0.6),
                ScenarioStep(label: "Action: PopToRoot", action: { nav?.navigationPlaygroundVC?.popToRoot() }, delay: 0.8),
                ScenarioStep(label: "Action: Unknown", action: { nav?.navigationPlaygroundVC?.simulateUnknownAction() }, delay: 0.6),
            ],
            loop: false
        )
    }
}

#endif
