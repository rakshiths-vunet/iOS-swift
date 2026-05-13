#if os(iOS)
import UIKit
import SwiftUI

// MARK: - PlaygroundCoordinator

/// Routes between all playground modules (UIKit + SwiftUI).
/// Holds weak references to active playground VCs for engine access.
@MainActor final class PlaygroundCoordinator {

    // MARK: - Dependencies

    private weak var navigationController: UINavigationController?
    let logger: EventLogger
    private let networkSimulator: NetworkSimulator

    // MARK: - Active playground VCs (weak, set on push)

    weak var navigationPlaygroundVC: UIKitNavPlaygroundVC?
    weak var interactionPlaygroundVC: InteractionPlaygroundVC?
    weak var swiftUINavCoordinator: SwiftUINavCoordinator?
    weak var renderSlowRootVC: RenderSlowRootVC?

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

    func openSwiftUINavigationPlayground() {
        let coordinator = SwiftUINavCoordinator(logger: logger)
        self.swiftUINavCoordinator = coordinator
        let swiftUIView = SwiftUINavPlayground(coordinator: coordinator)
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.title = "SwiftUI Nav"
        logger.log(type: "navigation", metadata: ["screen": "SwiftUINavigationPlayground", "framework": "SwiftUI"])
        navigationController?.pushViewController(hostingController, animated: true)
    }

    func openNetworkPlayground() {
        let vc = NetworkPlaygroundVC(networkSimulator: networkSimulator)
        logger.log(type: "navigation", metadata: ["screen": "NetworkPlayground"])
        navigationController?.pushViewController(vc, animated: true)
    }

    func openAPIDrivenUIKitPlayground() {
        let vc = APIDrivenLevelViewController(level: 0)
        logger.log(type: "navigation", metadata: ["screen": "APIDrivenUIKitPlayground"])
        navigationController?.pushViewController(vc, animated: true)
    }

    func openAPIDrivenSwiftUIPlayground() {
        let swiftUIView = APIDrivenSwiftUIPlayground()
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.title = "API Driven SwiftUI"
        logger.log(type: "navigation", metadata: ["screen": "APIDrivenSwiftUIPlayground", "framework": "SwiftUI"])
        navigationController?.pushViewController(hostingController, animated: true)
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

    func openBFSIPlayground() {
        let vc = BFSIDashboardViewController()
        logger.log(type: "navigation", metadata: ["screen": "BFSIDashboard"])
        navigationController?.pushViewController(vc, animated: true)
    }

    func openBFSISwiftUIPlayground() {
        let swiftUIView = BFSISwiftUIPlayground()
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.title = "BFSI SwiftUI"
        logger.log(type: "navigation", metadata: ["screen": "BFSISwiftUIDashboard", "framework": "SwiftUI"])
        navigationController?.pushViewController(hostingController, animated: true)
    }

    func openRenderSlowPlayground() {
        let vc = RenderSlowRootVC()
        self.renderSlowRootVC = vc
        logger.log(type: "navigation", metadata: ["screen": "render.slow"])
        navigationController?.pushViewController(vc, animated: true)
    }

    func openAlamofirePlayground() {
        let vc = AlamofirePlaygroundVC()
        logger.log(type: "navigation", metadata: ["screen": "AlamofirePlayground"])
        navigationController?.pushViewController(vc, animated: true)
    }

    func openHandledErrorPlayground() {
        let vc = HandledErrorPlaygroundVC(logger: logger)
        logger.log(type: "navigation", metadata: ["screen": "HandledErrorPlayground"])
        navigationController?.pushViewController(vc, animated: true)
    }
}

#endif
