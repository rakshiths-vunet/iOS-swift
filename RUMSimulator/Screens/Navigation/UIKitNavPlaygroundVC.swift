#if os(iOS)
import UIKit

// MARK: - UIKitNavPlaygroundVC

/// UINavigationController-based deep-stack playground.
/// Driveable by the scenario engine and manually via toolbar.
/// Supports: push, popOne, popToRoot, replaceStack, presentModal,
///           presentFullScreen, dismissModal.
final class UIKitNavPlaygroundVC: UIViewController {

    private(set) var _tabBarController: UITabBarController!
    private weak var currentModal: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Navigation Playground"
        view.backgroundColor = .systemBackground
        setupGlobalControls()
        setupTabBar()
        setupToolbar()
    }

    // MARK: - Global Navigation setup

    private func setupGlobalControls() {
        let pushBtn = makeButton(title: "Push", icon: "arrow.right", color: Theme.Colors.primary) { [weak self] in self?.globalPush() }
        let popBtn  = makeButton(title: "Pop",  icon: "arrow.left",  color: Theme.Colors.warning) { [weak self] in self?.globalPop() }
        let rootBtn = makeButton(title: "Root", icon: "house",       color: Theme.Colors.danger)  { [weak self] in self?.globalRoot() }

        let stack = UIStackView(arrangedSubviews: [pushBtn, popBtn, rootBtn])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false

        let card = UIView()
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stack)

        view.addSubview(card)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            card.heightAnchor.constraint(equalToConstant: 60),

            stack.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            stack.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        self.globalControlCard = card
    }

    private var globalControlCard: UIView?

    private func makeButton(title: String, icon: String, color: UIColor, action: @escaping () -> Void) -> UIButton {
        var config = Theme.premiumButtonConfig(title: title, systemImage: icon, color: color)
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 11, weight: .bold)
            return a
        }
        let b = UIButton(configuration: config)
        b.addAction(UIAction { _ in action() }, for: .touchUpInside)
        return b
    }

    // MARK: - Tab Bar setup

    private func setupTabBar() {
        _tabBarController = UITabBarController()
        
        let tab1 = makeTab(title: "Home", icon: "house", level: 0)
        let tab2 = makeTab(title: "Search", icon: "magnifyingglass", level: 0)
        let tab3 = makeTab(title: "Cart", icon: "cart", level: 0)
        let tab4 = makeTab(title: "Profile", icon: "person", level: 0)
        
        _tabBarController.viewControllers = [tab1, tab2, tab3, tab4]
        _tabBarController.tabBar.backgroundColor = .secondarySystemBackground

        addChild(_tabBarController)
        view.addSubview(_tabBarController.view)
        _tabBarController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            _tabBarController.view.topAnchor.constraint(equalTo: globalControlCard?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor, constant: 12),
            _tabBarController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            _tabBarController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            _tabBarController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        _tabBarController.didMove(toParent: self)
    }

    private func makeTab(title: String, icon: String, level: Int) -> UINavigationController {
        let root = NavLevelViewController(level: level, rootNavController: nil)
        let nav = UINavigationController(rootViewController: root)
        nav.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: icon), selectedImage: UIImage(systemName: icon + ".fill"))
        nav.navigationBar.prefersLargeTitles = true
        return nav
    }

    private func setupToolbar() {
        let pushBtn    = UIBarButtonItem(title: "Push",    style: .plain,  target: self, action: #selector(pushLevel))
        let popBtn     = UIBarButtonItem(title: "Pop",     style: .plain,  target: self, action: #selector(popOne))
        let rootBtn    = UIBarButtonItem(title: "Root",    style: .plain,  target: self, action: #selector(popToRoot))
        
        let menu = UIMenu(title: "Latency Mode", children: [
            UIAction(title: "None") { _ in NavigationLatencyInjector.shared.globalMode = .none },
            UIAction(title: "Fixed 0.5s") { _ in NavigationLatencyInjector.shared.globalMode = .fixed(0.5) },
            UIAction(title: "Fixed 2s") { _ in NavigationLatencyInjector.shared.globalMode = .fixed(2.0) },
            UIAction(title: "Random (1-3s)") { _ in NavigationLatencyInjector.shared.globalMode = .random(min: 1.0, max: 3.0) },
            UIMenu(title: "Status", options: .displayInline, children: [
                UIAction(title: "Toggle Enabled", image: UIImage(systemName: "power")) { _ in
                    NavigationLatencyInjector.shared.isEnabled.toggle()
                }
            ])
        ])
        let latencyBtn = UIBarButtonItem(image: UIImage(systemName: "timer"), menu: menu)
        
        navigationItem.rightBarButtonItems = [pushBtn, popBtn, rootBtn, latencyBtn]
    }

    private var currentNav: UINavigationController? {
        _tabBarController.selectedViewController as? UINavigationController
    }

    // MARK: - Global Navigation Actions

    private func globalPush() {
        Task {
            await NavigationLatencyInjector.shared.injectDelay(screenName: NavigationConstants.screenName(for: 0), context: "Before UIKit Global Push")
            await MainActor.run {
                let next = NavLevelViewController(level: 0, rootNavController: self.navigationController)
                self.navigationController?.pushViewController(next, animated: true)
            }
        }
    }

    private func globalPop() {
        navigationController?.popViewController(animated: true)
    }

    private func globalRoot() {
        navigationController?.popToRootViewController(animated: true)
    }

    // MARK: - Engine-callable interface

    /// Push the next named screen onto the current stack.
    @objc func pushLevel() {
        guard let nav = currentNav,
              let current = nav.viewControllers.last as? NavLevelViewController,
              nav.viewControllers.count < 10 else { return }
        
        let nextName = NavigationConstants.screenName(for: current.level + 1)
        
        Task {
            await NavigationLatencyInjector.shared.injectDelay(screenName: nextName, context: "Before UIKit Push (Playground)")
            await MainActor.run {
                let next = NavLevelViewController(level: current.level + 1, rootNavController: nav)
                nav.pushViewController(next, animated: true)
            }
        }
    }

    /// Pop just one level from current stack.
    @objc func popOne() {
        currentNav?.popViewController(animated: true)
    }

    /// Pop all the way back to the root screen on current stack.
    @objc func popToRoot() {
        currentNav?.popToRootViewController(animated: true)
    }

    /// Replace the entire navigation stack of the current tab.
    @objc func replaceStack() {
        guard let nav = currentNav else { return }
        let root = NavLevelViewController(level: 0, rootNavController: nav)
        let mid  = NavLevelViewController(level: 4, rootNavController: nav)
        nav.setViewControllers([root, mid], animated: true)
    }

    /// Present a formSheet modal on current tab.
    func presentModal() {
        Task {
            await NavigationLatencyInjector.shared.injectDelay(screenName: "Modal", context: "Before UIKit Present")
            await MainActor.run {
                let modal = ModalViewController(presentationStyle: .formSheet)
                self.currentModal = modal
                self._tabBarController.present(modal, animated: true)
            }
        }
    }

    /// Present a full-screen modal.
    func presentFullScreen() {
        let modal = ModalViewController(presentationStyle: .fullScreen)
        currentModal = modal
        _tabBarController.present(modal, animated: true)
    }

    /// Dismiss whatever modal is currently on screen.
    func dismissModal() {
        currentModal?.dismiss(animated: true)
        currentModal = nil
    }

    /// Actually switch tabs.
    func simulateTabSwitch() {
        let nextIndex = (_tabBarController.selectedIndex + 1) % (_tabBarController.viewControllers?.count ?? 1)
        _tabBarController.selectedIndex = nextIndex
    }

    /// Simulate an unknown navigation action.
    func simulateUnknownAction() {
        print("Executing unknown navigation action")
    }
}

// MARK: - APIDrivenLevelViewController

final class APIDrivenLevelViewController: UIViewController {
    
    let level: Int
    private var screenName: String {
        NavigationConstants.screenName(for: level)
    }
    
    // UI Elements
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let contentStack = UIStackView()
    private let dataLabel = UILabel()
    private let nextButton = UIButton(type: .system)
    
    init(level: Int) {
        self.level = level
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = screenName
        view.backgroundColor = .systemBackground
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchData()
    }
    
    private func setupUI() {
        // Loading Indicator
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loadingIndicator)
        
        // Content Stack
        contentStack.axis = .vertical
        contentStack.spacing = 20
        contentStack.alignment = .center
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.isHidden = true
        view.addSubview(contentStack)
        
        // Data Label
        dataLabel.font = .systemFont(ofSize: 14, weight: .medium)
        dataLabel.textAlignment = .center
        dataLabel.numberOfLines = 0
        contentStack.addArrangedSubview(dataLabel)
        
        // Next Button
        var config = UIButton.Configuration.filled()
        config.title = "Go to Next Screen"
        config.image = UIImage(systemName: "arrow.right.circle.fill")
        config.imagePlacement = .trailing
        config.imagePadding = 10
        nextButton.configuration = config
        nextButton.addAction(UIAction { [weak self] _ in self?.pushNext() }, for: .touchUpInside)
        contentStack.addArrangedSubview(nextButton)
        
        // Latency Toggle Button (UI enhancement)
        let latencyBtn = UIButton(type: .system)
        latencyBtn.setTitle("Toggle Latency Mode", for: .normal)
        latencyBtn.addAction(UIAction { [weak self] _ in self?.showLatencyMenu() }, for: .touchUpInside)
        contentStack.addArrangedSubview(latencyBtn)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            contentStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            contentStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    private func fetchData() {
        loadingIndicator.startAnimating()
        contentStack.isHidden = true
        
        Task {
            let data = await APILatencyManager.shared.fetchRealData(level: self.level, screenName: self.screenName)
            
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.dataLabel.text = data
                self.contentStack.isHidden = false
                print("[RENDER COMPLETE] \(self.screenName)")
            }
        }
    }
    
    private func pushNext() {
        let nextName = NavigationConstants.screenName(for: level + 1)
        print("[NAV START] \(screenName) → \(nextName)")
        
        let nextVC = APIDrivenLevelViewController(level: level + 1)
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
    private func showLatencyMenu() {
        let alert = UIAlertController(title: "API Latency Mode", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "None", style: .default) { _ in APILatencyManager.shared.mode = .none })
        alert.addAction(UIAlertAction(title: "Fixed 1s", style: .default) { _ in APILatencyManager.shared.mode = .fixed(1.0) })
        alert.addAction(UIAlertAction(title: "Random (0.3 - 2s)", style: .default) { _ in APILatencyManager.shared.mode = .random(min: 0.3, max: 2.0) })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

#endif