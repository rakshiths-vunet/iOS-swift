#if os(iOS)
import UIKit

// MARK: - LifecycleObserver

/// Bridges SceneDelegate callbacks to EventLogger.
/// Infrastructure object — NOT a screen. Wired in SceneDelegate, not PlaygroundCoordinator.
final class LifecycleObserver {

    private let logger: EventLogger
    private var notificationTokens: [NSObjectProtocol] = []

    init(logger: EventLogger) {
        self.logger = logger
        observeNotifications()
    }

    deinit {
        notificationTokens.forEach { NotificationCenter.default.removeObserver($0) }
    }

    // MARK: - SceneDelegate forwarding points

    func sceneDidBecomeActive() {
        logger.log(type: "lifecycle", metadata: ["event": "sceneDidBecomeActive"])
    }

    func sceneWillResignActive() {
        logger.log(type: "lifecycle", metadata: ["event": "sceneWillResignActive"])
    }

    func sceneDidEnterBackground() {
        logger.log(type: "lifecycle", metadata: ["event": "sceneDidEnterBackground"])
    }

    func sceneWillEnterForeground() {
        logger.log(type: "lifecycle", metadata: ["event": "sceneWillEnterForeground"])
    }

    // MARK: - Notification-based simulation (for debug panel + S4)

    private func observeNotifications() {
        let nc = NotificationCenter.default

        let backgroundToken = nc.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logger.log(type: "lifecycle", metadata: ["event": "didEnterBackground_notification"])
        }

        let foregroundToken = nc.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logger.log(type: "lifecycle", metadata: ["event": "willEnterForeground_notification"])
        }

        let activeToken = nc.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logger.log(type: "lifecycle", metadata: ["event": "didBecomeActive_notification"])
        }

        notificationTokens = [backgroundToken, foregroundToken, activeToken]
    }
}

#endif