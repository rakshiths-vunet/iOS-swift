import UIKit

// MARK: - NavLevelViewController

/// Reusable UIKit screen for navigation stack levels A/B/C/D/...
/// Each level shows its depth and a "Push Next Level" button.
final class NavLevelViewController: UIViewController {

    let level: Int
    private weak var rootNavController: UINavigationController?

    private lazy var levelLabel: UILabel = {
        let l = UILabel()
        l.text = "Level \(level)"
        l.font = .systemFont(ofSize: 48, weight: .thin)
        l.textColor = .label
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = levelTitle()
        l.font = .systemFont(ofSize: 16, weight: .regular)
        l.textColor = .secondaryLabel
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var pushButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Push Next Level"
        config.cornerStyle = .medium
        let b = UIButton(configuration: config)
        b.addTarget(self, action: #selector(pushNext), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var popButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "Pop to Root"
        config.cornerStyle = .medium
        let b = UIButton(configuration: config)
        b.addTarget(self, action: #selector(popRoot), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var modalButton: UIButton = {
        var config = UIButton.Configuration.bordered()
        config.title = "Present Modal"
        config.cornerStyle = .medium
        let b = UIButton(configuration: config)
        b.addTarget(self, action: #selector(presentModalVC), for: .touchUpInside)
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
        title = "Level \(level)"
        view.backgroundColor = levelColor()
        setupLayout()
    }

    // MARK: - Layout

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [levelLabel, subtitleLabel, spacer(24), pushButton, popButton, modalButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
            pushButton.widthAnchor.constraint(equalToConstant: 220),
            popButton.widthAnchor.constraint(equalToConstant: 220),
            modalButton.widthAnchor.constraint(equalToConstant: 220),
        ])
    }

    // MARK: - Actions

    @objc func pushNext() {
        guard let nav = navigationController, nav.viewControllers.count < 10 else { return }
        let next = NavLevelViewController(level: level + 1, rootNavController: nav)
        nav.pushViewController(next, animated: true)
    }

    @objc func popRoot() {
        navigationController?.popToRootViewController(animated: true)
    }

    @objc func presentModalVC() {
        let modal = ModalViewController()
        modal.modalPresentationStyle = .formSheet
        present(modal, animated: true)
    }

    // MARK: - Helpers

    private func levelTitle() -> String {
        let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
        return "Screen \(level < letters.count ? letters[level] : "\(level)")"
    }

    private func levelColor() -> UIColor {
        let colors: [UIColor] = [
            .systemBackground,
            UIColor.systemBlue.withAlphaComponent(0.04),
            UIColor.systemGreen.withAlphaComponent(0.04),
            UIColor.systemOrange.withAlphaComponent(0.04),
            UIColor.systemPurple.withAlphaComponent(0.04),
            UIColor.systemTeal.withAlphaComponent(0.04),
        ]
        return colors[level % colors.count]
    }

    private func spacer(_ height: CGFloat) -> UIView {
        let v = UIView()
        v.heightAnchor.constraint(equalToConstant: height).isActive = true
        return v
    }
}
