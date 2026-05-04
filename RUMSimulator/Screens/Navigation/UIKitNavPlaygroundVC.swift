import UIKit

// MARK: - UIKitNavPlaygroundVC

/// UINavigationController-based deep-stack playground.
/// Driveable by the scenario engine and manually.
final class UIKitNavPlaygroundVC: UIViewController {

    private(set) var navController: UINavigationController!
    private var currentModal: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Navigation Playground"
        view.backgroundColor = .systemBackground
        setupChildNav()
        setupManualControls()
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
            navController.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            navController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        navController.didMove(toParent: self)
    }

    private func setupManualControls() {
        let pushBtn = UIBarButtonItem(title: "Push", style: .plain, target: self, action: #selector(pushLevel))
        let popBtn  = UIBarButtonItem(title: "Pop Root", style: .plain, target: self, action: #selector(popToRoot))
        navigationItem.rightBarButtonItems = [pushBtn, popBtn]
    }

    // MARK: - Engine-callable interface

    @objc func pushLevel() {
        guard let current = navController.viewControllers.last as? NavLevelViewController,
              navController.viewControllers.count < 10 else { return }
        let next = NavLevelViewController(level: current.level + 1, rootNavController: navController)
        navController.pushViewController(next, animated: true)
    }

    @objc func popToRoot() {
        navController.popToRootViewController(animated: true)
    }

    func presentModal() {
        let modal = ModalViewController()
        modal.modalPresentationStyle = .formSheet
        currentModal = modal
        navController.present(modal, animated: true)
    }

    func dismissModal() {
        currentModal?.dismiss(animated: true)
        currentModal = nil
    }
}
