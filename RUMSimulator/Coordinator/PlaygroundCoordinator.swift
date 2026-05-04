#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

// MARK: - PlaygroundCoordinator

/// Routes between all playground modules (UIKit + SwiftUI).
/// Holds weak references to active playground VCs for engine access.
final class PlaygroundCoordinator {

    // MARK: - Dependencies

    private weak var navigationController: UINavigationController?
    let logger: EventLogger
    private let networkSimulator: NetworkSimulator

    // MARK: - Active playground VCs (weak, set on push)

    weak var navigationPlaygroundVC: UIKitNavPlaygroundVC?
    weak var interactionPlaygroundVC: InteractionPlaygroundVC?

    // MARK: - Init

    init(navigationController: UINavigationController, logger: EventLogger, networkSimulator: NetworkSimulator) {
        self.navigationController = navigationController
        self.logger = logger
        self.networkSimulator = networkSimulator
    }

    // MARK: - Routing

    func openNavigationPlayground() {
        let vc = UIKitNavPlaygroundVC()
        self.navigationPlaygroundVC = vc
        logger.log(type: "navigation", metadata: ["screen": "NavigationPlayground"])
        navigationController?.pushViewController(vc, animated: true)
    }

    func openInteractionPlayground() {
        let vc = InteractionPlaygroundVC()
        self.interactionPlaygroundVC = vc
        logger.log(type: "navigation", metadata: ["screen": "InteractionPlayground"])
        navigationController?.pushViewController(vc, animated: true)
    }

    func openNetworkPlayground() {
        let vc = NetworkPlaygroundVC(networkSimulator: networkSimulator)
        logger.log(type: "navigation", metadata: ["screen": "NetworkPlayground"])
        navigationController?.pushViewController(vc, animated: true)
    }

    func openLifecyclePlayground() {
        let vc = LifecyclePlaygroundVC(logger: logger)
        logger.log(type: "navigation", metadata: ["screen": "LifecyclePlayground"])
        navigationController?.pushViewController(vc, animated: true)
    }

    func openCrashPlayground() {
        let vc = CrashPlaygroundVC(logger: logger)
        logger.log(type: "navigation", metadata: ["screen": "CrashPlayground"])
        navigationController?.pushViewController(vc, animated: true)
    }

    func openLogViewer() {
        let vc = LogViewerViewController(logger: logger)
        logger.log(type: "navigation", metadata: ["screen": "LogViewer"])
        navigationController?.pushViewController(vc, animated: true)
    }
}

#endif