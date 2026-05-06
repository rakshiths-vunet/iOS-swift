#if os(iOS)
import UIKit

// MARK: - Screen Catalogue
// Each navigation level maps to a named "screen" in a realistic app flow.

private let kScreenNames: [String] = NavigationConstants.screenNames

private let kScreenIcons: [String] = [
    "house.fill",
    "chart.bar.fill",
    "person.fill",
    "gearshape.fill",
    "doc.text.fill",
    "cart.fill",
    "creditcard.fill",
    "checkmark.seal.fill",
    "star.fill",
    "flag.checkered"
]

private let kScreenColors: [UIColor] = [
    .systemBackground,
    UIColor(red: 0.05, green: 0.35, blue: 0.90, alpha: 0.06),
    UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 0.06),
    UIColor(red: 0.98, green: 0.52, blue: 0.15, alpha: 0.06),
    UIColor(red: 0.55, green: 0.25, blue: 0.90, alpha: 0.06),
    UIColor(red: 0.18, green: 0.72, blue: 0.75, alpha: 0.06),
    UIColor(red: 0.95, green: 0.25, blue: 0.45, alpha: 0.06),
    UIColor(red: 0.30, green: 0.75, blue: 0.55, alpha: 0.06),
    UIColor(red: 0.90, green: 0.70, blue: 0.10, alpha: 0.06),
    UIColor(red: 0.40, green: 0.60, blue: 0.95, alpha: 0.06),
]

// MARK: - NavLevelViewController

/// Reusable UIKit screen for navigation stack levels.
/// Each level has a domain screen name, icon, and colour.
/// Supports: push, pop one, pop to root, replace stack, present modal, present full-screen.
final class NavLevelViewController: UIViewController {

    let level: Int
    private weak var rootNavController: UINavigationController?

    // Manual metadata selection
    private var selectedTrigger: NavTriggerType = .userTap
    private var selectedEntry: NavEntryType = .internalFlow

    // MARK: - UI Components

    private lazy var backgroundView: UIView = {
        let v = UIView(frame: view.bounds)
        v.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        return v
    }()

    private lazy var glassCard: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private lazy var iconImageView: UIImageView = {
        let img = UIImageView()
        img.image = UIImage(systemName: screenIcon())
        img.tintColor = .white
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()

    private lazy var screenNameLabel: UILabel = {
        let l = UILabel()
        l.text = screenName()
        l.font = .systemFont(ofSize: 32, weight: .bold)
        l.textColor = .white
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var levelBadge: UILabel = {
        let l = UILabel()
        l.text = "LEVEL \(level)"
        l.font = .systemFont(ofSize: 12, weight: .black)
        l.textColor = Theme.Colors.primary
        l.backgroundColor = .white
        l.textAlignment = .center
        l.layer.cornerRadius = 4
        l.layer.masksToBounds = true
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Metadata Selectors
    private lazy var triggerSelector: UISegmentedControl = makeSelector(items: ["Tap", "Gesture", "DeepLink", "Notify"], title: "TRIGGER")
    private lazy var entrySelector: UISegmentedControl = makeSelector(items: ["Internal", "DeepLink", "External", "Restore"], title: "ENTRY")

    // Buttons
    private lazy var pushButton: UIButton = makePremiumButton(title: "Push → \(nextScreenName())", icon: "arrow.right", color: Theme.Colors.primary) { [weak self] in self?.pushNext() }
    private lazy var popButton: UIButton = makePremiumButton(title: "Pop Back", icon: "arrow.left", color: Theme.Colors.warning) { [weak self] in self?.popOne() }
    private lazy var tabButton: UIButton = makePremiumButton(title: "Tab Switch", icon: "arrow.left.and.right.square", color: Theme.Colors.secondary) { [weak self] in self?.tabSwitch() }
    private lazy var moreButton: UIButton = {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "ellipsis.circle.fill")
        config.baseForegroundColor = .white.withAlphaComponent(0.6)
        let b = UIButton(configuration: config)
        b.menu = UIMenu(title: "Advanced Actions", children: [
            UIAction(title: "Pop to Root", image: UIImage(systemName: "arrow.uturn.backward"), attributes: .destructive) { [weak self] _ in self?.popRoot() },
            UIAction(title: "Replace Stack", image: UIImage(systemName: "arrow.triangle.2.circlepath")) { [weak self] _ in self?.replaceStack() },
            UIAction(title: "Present Modal", image: UIImage(systemName: "rectangle.portrait.and.arrow.right")) { [weak self] _ in self?.presentModal() },
            UIAction(title: "Unknown Action", image: UIImage(systemName: "questionmark.circle")) { [weak self] _ in self?.unknownAction() }
        ])
        b.showsMenuAsPrimaryAction = true
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    // MARK: - Init

    init(level: Int, rootNavController: UINavigationController?) {
        self.level = level
        self.rootNavController = rootNavController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = screenName()
        setupPremiumUI()
        setupLoadingOverlay()
    }

    private let loadingOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.8)
        v.isHidden = true
        v.translatesAutoresizingMaskIntoConstraints = false
        
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = "Simulating Latency..."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        
        v.addSubview(spinner)
        v.addSubview(label)
        
        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: v.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: v.centerYAnchor, constant: -20),
            label.topAnchor.constraint(equalTo: spinner.bottomAnchor, constant: 12),
            label.centerXAnchor.constraint(equalTo: v.centerXAnchor)
        ])
        
        return v
    }()

    private func setupLoadingOverlay() {
        view.addSubview(loadingOverlay)
        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Simulating rendering delay
        loadingOverlay.isHidden = false
        Task {
            await NavigationLatencyInjector.shared.injectDelay(screenName: screenName(), context: "UIKit viewWillAppear Task")
            await MainActor.run {
                UIView.animate(withDuration: 0.3) {
                    self.loadingOverlay.alpha = 0
                } completion: { _ in
                    self.loadingOverlay.isHidden = true
                    self.loadingOverlay.alpha = 1
                }
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        Theme.addGradientBackground(to: backgroundView)
        Theme.applyGlassEffect(to: glassCard)
    }

    private func setupPremiumUI() {
        view.addSubview(backgroundView)
        view.addSubview(glassCard)
        
        let headerStack = UIStackView(arrangedSubviews: [iconImageView, screenNameLabel, levelBadge])
        headerStack.axis = .vertical
        headerStack.spacing = 8
        headerStack.alignment = .center
        
        let selectorStack = UIStackView(arrangedSubviews: [
            sectionLabel("METADATA OVERRIDE"),
            triggerSelector,
            entrySelector
        ])
        selectorStack.axis = .vertical
        selectorStack.spacing = 12
        
        let actionStack = UIStackView(arrangedSubviews: [pushButton, popButton, tabButton])
        actionStack.axis = .vertical
        actionStack.spacing = 12
        
        let mainStack = UIStackView(arrangedSubviews: [headerStack, selectorStack, actionStack])
        mainStack.axis = .vertical
        mainStack.spacing = 32
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        glassCard.addSubview(mainStack)
        view.addSubview(moreButton)
        
        NSLayoutConstraint.activate([
            glassCard.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            glassCard.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            glassCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            glassCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            mainStack.topAnchor.constraint(equalTo: glassCard.topAnchor, constant: 32),
            mainStack.bottomAnchor.constraint(equalTo: glassCard.bottomAnchor, constant: -32),
            mainStack.leadingAnchor.constraint(equalTo: glassCard.leadingAnchor, constant: 24),
            mainStack.trailingAnchor.constraint(equalTo: glassCard.trailingAnchor, constant: -24),
            
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            
            levelBadge.widthAnchor.constraint(equalToConstant: 70),
            levelBadge.heightAnchor.constraint(equalToConstant: 20),
            
            moreButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            moreButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    // MARK: - Actions

    private func logAction(_ type: NavActionType) {
        // Resolve manual selections
        let triggerMap: [Int: NavTriggerType] = [0: .userTap, 1: .userGesture, 2: .deepLink, 3: .notification]
        let entryMap: [Int: NavEntryType] = [0: .internalFlow, 1: .deepLink, 2: .external, 3: .restored]
        
        let trigger = triggerMap[triggerSelector.selectedSegmentIndex] ?? .unknown
        let entry = entryMap[entrySelector.selectedSegmentIndex] ?? .unknown
        
        let metadata = NavMetadata(actionType: type, triggerType: trigger, entryType: entry)
        
        // Find the logger via AppCoordinator or Engine
        // For simplicity in this simulator, we can fire a notification or use a shared reference
        // But the Engine already logs 'step' actions. Here we log manual interactions.
        NotificationCenter.default.post(name: Notification.Name("ManualNavAction"), object: nil, userInfo: metadata.dictionary)
    }

    @objc func pushNext() {
        logAction(.push)
        guard let nav = navigationController, nav.viewControllers.count < 10 else { return }
        let nextName = nextScreenName()
        
        Task {
            await NavigationLatencyInjector.shared.injectDelay(screenName: nextName, context: "Before UIKit Push")
            await MainActor.run {
                let next = NavLevelViewController(level: self.level + 1, rootNavController: nav)
                nav.pushViewController(next, animated: true)
            }
        }
    }

    @objc func popOne() {
        logAction(.pop)
        navigationController?.popViewController(animated: true)
    }

    @objc func tabSwitch() {
        logAction(.tabSwitch)
        
        // Find the playground VC in the hierarchy
        var parentVC = parent
        while parentVC != nil {
            if let playground = parentVC as? UIKitNavPlaygroundVC {
                playground.simulateTabSwitch()
                return
            }
            parentVC = parentVC?.parent
        }
    }

    func popRoot() {
        logAction(.popToRoot)
        navigationController?.popToRootViewController(animated: true)
    }

    func replaceStack() {
        logAction(.replace)
        (parent as? UIKitNavPlaygroundVC)?.replaceStack()
    }

    func presentModal() {
        logAction(.present)
        let modal = ModalViewController(presentationStyle: .formSheet)
        present(modal, animated: true)
    }

    func unknownAction() {
        logAction(.unknown)
        (parent as? UIKitNavPlaygroundVC)?.simulateUnknownAction()
    }

    // MARK: - UI Helpers

    private func makePremiumButton(title: String, icon: String, color: UIColor, action: @escaping () -> Void) -> UIButton {
        let b = UIButton(configuration: Theme.premiumButtonConfig(title: title, systemImage: icon, color: color))
        b.addAction(UIAction { _ in action() }, for: .touchUpInside)
        Theme.applyPremiumShadow(to: b, color: color)
        return b
    }

    private func makeSelector(items: [String], title: String) -> UISegmentedControl {
        let s = UISegmentedControl(items: items)
        s.selectedSegmentIndex = 0
        s.selectedSegmentTintColor = Theme.Colors.primary
        s.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 10, weight: .bold)], for: .selected)
        s.setTitleTextAttributes([.foregroundColor: UIColor.white.withAlphaComponent(0.6), .font: UIFont.systemFont(ofSize: 10)], for: .normal)
        return s
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 10, weight: .black)
        l.textColor = .white.withAlphaComponent(0.4)
        l.textAlignment = .center
        return l
    }

    func screenName() -> String {
        return kScreenNames[min(level, kScreenNames.count - 1)]
    }

    private func nextScreenName() -> String {
        return kScreenNames[min(level + 1, kScreenNames.count - 1)]
    }

    private func screenIcon() -> String {
        return kScreenIcons[min(level, kScreenIcons.count - 1)]
    }
}

#endif