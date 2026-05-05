#if os(iOS)
import UIKit

// MARK: - ModalViewController

/// Modal presentation target. Supports both .formSheet and .fullScreen.
/// Displays the current presentation style and offers a Dismiss button.
final class ModalViewController: UIViewController {

    private let style: UIModalPresentationStyle

    init(presentationStyle: UIModalPresentationStyle = .formSheet) {
        self.style = presentationStyle
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = presentationStyle
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Modal"
        view.backgroundColor = .systemBackground
        setupUI()
    }

    private func setupUI() {
        let iconName = style == .fullScreen ? "arrow.up.left.and.arrow.down.right" : "rectangle.portrait.and.arrow.right"
        let styleLabel = style == .fullScreen ? "Full Screen" : "Form Sheet"

        let iconView = UIImageView(image: UIImage(systemName: iconName))
        iconView.tintColor = style == .fullScreen ? .systemTeal : .systemBlue
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Modal Presentation"
        titleLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let styleTagLabel = UILabel()
        styleTagLabel.text = ".\(styleLabel.lowercased().replacingOccurrences(of: " ", with: ""))"
        styleTagLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        styleTagLabel.textColor = .secondaryLabel
        styleTagLabel.textAlignment = .center
        styleTagLabel.translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.filled()
        config.title = "Dismiss"
        config.image = UIImage(systemName: "xmark.circle.fill")
        config.imagePlacement = .leading
        config.imagePadding = 6
        config.cornerStyle = .medium
        let dismissBtn = UIButton(configuration: config)
        dismissBtn.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        dismissBtn.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [iconView, titleLabel, styleTagLabel, dismissBtn])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            iconView.heightAnchor.constraint(equalToConstant: 52),
            iconView.widthAnchor.constraint(equalToConstant: 52),
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32),
            dismissBtn.widthAnchor.constraint(equalToConstant: 180),
        ])
    }
}

#endif