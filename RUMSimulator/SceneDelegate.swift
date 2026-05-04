#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var coordinator: AppCoordinator?
    private var lifecycleObserver: LifecycleObserver?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        let coordinator = AppCoordinator(window: window)
        self.coordinator = coordinator

        // Wire lifecycle observer BEFORE start so it captures first active event
        lifecycleObserver = LifecycleObserver(logger: coordinator.eventLogger)

        coordinator.start()
        window.makeKeyAndVisible()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        lifecycleObserver?.sceneDidBecomeActive()
    }

    func sceneWillResignActive(_ scene: UIScene) {
        lifecycleObserver?.sceneWillResignActive()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        lifecycleObserver?.sceneDidEnterBackground()
        // Flush logs on background
        coordinator?.eventLogger.flush()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        lifecycleObserver?.sceneWillEnterForeground()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        coordinator?.eventLogger.flush()
    }
}

#endif