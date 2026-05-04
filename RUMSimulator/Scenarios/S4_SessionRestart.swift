#if os(iOS)
import UIKit

// MARK: - S4: Session Restart Flow

extension ScenarioLibrary {
    func s4() -> Scenario {
        let nav = playgroundCoordinator
        return Scenario(
            id: "S4",
            name: "Session Restart Flow",
            steps: [
                ScenarioStep(label: "Open Lifecycle Playground", action: {
                    nav?.openLifecyclePlayground()
                }, delay: 0.8),
                ScenarioStep(label: "Navigate to screen", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()
                }, delay: 0.5),
                ScenarioStep(label: "Simulate Background", action: {
                    // Post notification — real backgrounding requires Home button press
                    NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
                }, delay: 3.0),
                ScenarioStep(label: "Simulate Foreground", action: {
                    NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
                    NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
                }, delay: 0.5),
                ScenarioStep(label: "Continue navigation after foreground", action: {
                    nav?.navigationPlaygroundVC?.pushLevel()
                }, delay: 0.8),
                ScenarioStep(label: "Pop to Root", action: {
                    nav?.navigationPlaygroundVC?.popToRoot()
                }, delay: 0.5),
            ],
            loop: false
        )
    }
}

#endif