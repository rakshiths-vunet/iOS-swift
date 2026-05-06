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
            await NavigationLatencyInjector.shared.injectDelay(screenName: "Modal", context: "UIKit Modal viewWillAppear Task")
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