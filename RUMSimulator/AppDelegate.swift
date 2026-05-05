#if os(iOS)
import UIKit
import vuTelemetry

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var coordinator: AppCoordinator?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // SDK link point: auto-instrumentation SDK is linked here but never called explicitly.
        // All telemetry must come from UIKit/URLSession/OS lifecycle auto-capture only.

        OtelManager.shared.initialize(endpoint: URL(string: "http://10.1.92.124:4318")!)

        
        
        
        CrashReportingManager.shared.setupPLCrashReporter()
        AppLifecycleTracker.shared.startTracking()
        UIKitTracker.shared.observeViewControllers()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // MARK: - Shake to reveal Debug Panel

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: .showDebugPanel, object: nil)
        }
    }
}

extension Notification.Name {
    static let showDebugPanel = Notification.Name("RUMSimulator.showDebugPanel")
}

#endif
