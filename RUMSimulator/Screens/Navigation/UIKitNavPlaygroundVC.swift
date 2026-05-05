#if os(iOS)
import UIKit

// MARK: - UIKitNavPlaygroundVC

/// UINavigationController-based deep-stack playground.
/// Driveable by the scenario engine and manually via toolbar.
/// Supports: push, popOne, popToRoot, replaceStack, presentModal,
///           presentFullScreen, dismissModal.
final class UIKitNavPlaygroundVC: UIViewController {

    private(set) var navController: UINavigationController!
    private weak var currentModal: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Navigation Playground"
        view.backgroundColor = .systemBackground
        setupChildNav()
        setupToolbar()
    }

    // MARK: - Child nav setup

    private func setupChildNav() {
        let root = NavLevelViewController(level: 0, rootNavController: nil)
        navController = UINavigationController(rootViewController: root)
        navController.navigationBar.prefersLargeTitles = true

        addChild(navController)
        view.addSubview(navController.view)
        navController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            navController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            navController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        navController.didMove(toParent: self)
    }

    private func setupToolbar() {
        let pushBtn    = UIBarButtonItem(title: "Push",    style: .plain,  target: self, action: #selector(pushLevel))
        let popBtn     = UIBarButtonItem(title: "Pop",     style: .plain,  target: self, action: #selector(popOne))
        let rootBtn    = UIBarButtonItem(title: "Root",    style: .plain,  target: self, action: #selector(popToRoot))
        navigationItem.rightBarButtonItems = [pushBtn, popBtn, rootBtn]
    }

    // MARK: - Engine-callable interface

    /// Push the next named screen onto the stack.
    @objc func pushLevel() {
        guard let current = navController.viewControllers.last as? NavLevelViewController,
              navController.viewControllers.count < 10 else { return }
        let next = NavLevelViewController(level: current.level + 1, rootNavController: navController)
        navController.pushViewController(next, animated: true)
    }

    /// Pop just one level.
    @objc func popOne() {
        navController.popViewController(animated: true)
    }

    /// Pop all the way back to the root screen.
    @objc func popToRoot() {
        navController.popToRootViewController(animated: true)
    }

    /// Replace the entire navigation stack (simulates deep-link / state restore).
    @objc func replaceStack() {
        let root = NavLevelViewController(level: 0, rootNavController: navController)
        let mid  = NavLevelViewController(level: 4, rootNavController: navController)   // "Order Details"
        navController.setViewControllers([root, mid], animated: true)
    }

    /// Present a formSheet modal.
    func presentModal() {
        let modal = ModalViewController(presentationStyle: .formSheet)
        currentModal = modal
        navController.present(modal, animated: true)
    }

    /// Present a full-screen modal.
    func presentFullScreen() {
        let modal = ModalViewController(presentationStyle: .fullScreen)
        currentModal = modal
        navController.present(modal, animated: true)
    }

    /// Dismiss whatever modal is currently on screen.
    func dismissModal() {
        currentModal?.dismiss(animated: true)
        currentModal = nil
    }
}

#endif