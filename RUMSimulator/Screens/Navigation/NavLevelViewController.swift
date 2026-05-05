#if os(iOS)
import UIKit

// MARK: - Screen Catalogue
// Each navigation level maps to a named "screen" in a realistic app flow.

private let kScreenNames: [String] = [
    "Home",
    "Dashboard",
    "Profile",
    "Settings",
    "Order Details",
    "Checkout",
    "Payment",
    "Confirmation",
    "Review",
    "Done"
]

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

    // MARK: - UI

    private lazy var iconImageView: UIImageView = {
        let img = UIImageView()
        img.image = UIImage(systemName: screenIcon())
        img.tintColor = .label
        img.contentMode = .scaleAspectFit
        img.translatesAutoresizingMaskIntoConstraints = false
        return img
    }()

    private lazy var screenNameLabel: UILabel = {
        let l = UILabel()
        l.text = screenName()
        l.font = .systemFont(ofSize: 36, weight: .semibold)
        l.textColor = .label
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var levelBadge: UILabel = {
        let l = UILabel()
        l.text = "Level \(level)"
        l.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        l.textColor = .tertiaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // Push
    private lazy var pushButton: UIButton = makeButton(
        title: "Push → \(nextScreenName())",
        systemImage: "arrow.right",
        style: .filled(),
        tint: nil
    ) { [weak self] in self?.pushNext() }

    // Pop one level
    private lazy var popOneButton: UIButton = makeButton(
        title: "Pop ← Back",
        systemImage: "arrow.left",
        style: .tinted(),
        tint: .systemOrange
    ) { [weak self] in self?.popOne() }

    // Pop to root
    private lazy var popRootButton: UIButton = makeButton(
        title: "Pop ← Root",
        systemImage: "arrow.uturn.left",
        style: .tinted(),
        tint: .systemRed
    ) { [weak self] in self?.popRoot() }

    // Replace entire stack
    private lazy var replaceButton: UIButton = makeButton(
        title: "Replace Stack",
        systemImage: "arrow.triangle.2.circlepath",
        style: .bordered(),
        tint: .systemPurple
    ) { [weak self] in self?.replaceStack() }

    // Present modal (formSheet)
    private lazy var modalButton: UIButton = makeButton(
        title: "Present Modal",
        systemImage: "rectangle.portrait.and.arrow.right",
        style: .bordered(),
        tint: .systemBlue
    ) { [weak self] in self?.presentModal() }

    // Present full-screen
    private lazy var fullScreenButton: UIButton = makeButton(
        title: "Present Full Screen",
        systemImage: "arrow.up.left.and.arrow.down.right",
        style: .bordered(),
        tint: .systemTeal
    ) { [weak self] in self?.presentFullScreen() }

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
        view.backgroundColor = screenColor()
        setupLayout()
    }

    // MARK: - Layout

    private func setupLayout() {
        let divider = UIView()
        divider.backgroundColor = UIColor.separator.withAlphaComponent(0.4)
        divider.translatesAutoresizingMaskIntoConstraints = false

        // Action grid: 2 columns of buttons
        let pushRow    = hStack([pushButton])
        let navRow     = hStack([popOneButton, popRootButton])
        let actionRow1 = hStack([replaceButton])
        let actionRow2 = hStack([modalButton, fullScreenButton])

        let main = UIStackView(arrangedSubviews: [
            iconImageView,
            screenNameLabel,
            levelBadge,
            spacer(12),
            divider,
            spacer(8),
            pushRow,
            navRow,
            spacer(4),
            actionRow1,
            actionRow2,
        ])
        main.axis = .vertical
        main.spacing = 10
        main.alignment = .center
        main.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(main)
        NSLayoutConstraint.activate([
            iconImageView.heightAnchor.constraint(equalToConstant: 64),
            iconImageView.widthAnchor.constraint(equalToConstant: 64),
            divider.widthAnchor.constraint(equalTo: main.widthAnchor, multiplier: 0.6),
            divider.heightAnchor.constraint(equalToConstant: 1),

            main.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            main.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            main.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            main.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
        ])

        // Button widths
        for btn in [pushButton, replaceButton] {
            btn.widthAnchor.constraint(equalToConstant: 240).isActive = true
        }
        for btn in [popOneButton, popRootButton, modalButton, fullScreenButton] {
            btn.widthAnchor.constraint(equalToConstant: 150).isActive = true
        }
    }

    // MARK: - Navigation Actions

    @objc func pushNext() {
        guard let nav = navigationController, nav.viewControllers.count < kScreenNames.count else { return }
        let next = NavLevelViewController(level: level + 1, rootNavController: nav)
        nav.pushViewController(next, animated: true)
    }

    @objc func popOne() {
        navigationController?.popViewController(animated: true)
    }

    @objc func popRoot() {
        navigationController?.popToRootViewController(animated: true)
    }

    @objc func replaceStack() {
        guard let nav = navigationController else { return }
        // Replace the entire stack with a fresh root + mid-point screen
        let root = NavLevelViewController(level: 0, rootNavController: nav)
        let mid  = NavLevelViewController(level: (kScreenNames.count / 2), rootNavController: nav)
        nav.setViewControllers([root, mid], animated: true)
    }

    @objc func presentModal() {
        let modal = ModalViewController(presentationStyle: .formSheet)
        present(modal, animated: true)
    }

    @objc func presentFullScreen() {
        let modal = ModalViewController(presentationStyle: .fullScreen)
        present(modal, animated: true)
    }

    // MARK: - Helpers

    func screenName() -> String {
        kScreenNames[min(level, kScreenNames.count - 1)]
    }

    private func nextScreenName() -> String {
        let next = level + 1
        return kScreenNames[min(next, kScreenNames.count - 1)]
    }

    private func screenIcon() -> String {
        kScreenIcons[min(level, kScreenIcons.count - 1)]
    }

    private func screenColor() -> UIColor {
        kScreenColors[level % kScreenColors.count]
    }

    private func spacer(_ height: CGFloat) -> UIView {
        let v = UIView()
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }

    private func hStack(_ views: [UIView]) -> UIStackView {
        let s = UIStackView(arrangedSubviews: views)
        s.axis = .horizontal
        s.spacing = 10
        s.alignment = .center
        s.distribution = .fillEqually
        return s
    }

    private func makeButton(
        title: String,
        systemImage: String,
        style: UIButton.Configuration,
        tint: UIColor?,
        action: @escaping () -> Void
    ) -> UIButton {
        var config = style
        config.title = title
        config.image = UIImage(systemName: systemImage)
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.cornerStyle = .medium
        if let tint { config.baseForegroundColor = tint; config.baseBackgroundColor = tint }
        let b = UIButton(configuration: config)
        b.addAction(UIAction { _ in action() }, for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }
}

#endif