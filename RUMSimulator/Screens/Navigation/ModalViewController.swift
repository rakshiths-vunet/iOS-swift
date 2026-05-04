#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

// MARK: - ModalViewController

/// Modal presentation target (.formSheet). Must have a Dismiss button.
final class ModalViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Modal"
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.text = "Modal View\n(formSheet presentation)"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 18, weight: .light)
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false

        var config = UIButton.Configuration.filled()
        config.title = "Dismiss"
        config.cornerStyle = .medium
        let dismissBtn = UIButton(configuration: config)
        dismissBtn.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        dismissBtn.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView(arrangedSubviews: [label, dismissBtn])
        stack.axis = .vertical
        stack.spacing = 24
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dismissBtn.widthAnchor.constraint(equalToConstant: 160),
        ])
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }
}

#endif