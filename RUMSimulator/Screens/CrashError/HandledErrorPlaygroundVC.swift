#if os(iOS)
import UIKit

// MARK: - HandledErrorPlaygroundVC

final class HandledErrorPlaygroundVC: UIViewController {

    private let logger: EventLogger

    // MARK: - UI Components

    private lazy var instructionLabel: UILabel = {
        let l = UILabel()
        l.text = """
        📝 Instructions:
        1. Enter credentials to simulate a login flow.
        2. Expected Username: 'admin'
        3. Expected Code: '1234'
        4. Any other input will trigger a 'Handled Exception/Error' log.
        
        This playground tests how the RUM SDK captures non-fatal, handled errors that occur during app logic execution.
        """
        l.numberOfLines = 0
        l.font = .systemFont(ofSize: 14, weight: .regular)
        l.textColor = .secondaryLabel
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private lazy var usernameField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Username (try 'admin')"
        tf.borderStyle = .roundedRect
        tf.autocapitalizationType = .none
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var codeField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Code (try '1234')"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.translatesAutoresizingMaskIntoConstraints = false
        return tf
    }()

    private lazy var validateButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "Verify Credentials"
        config.cornerStyle = .medium
        let b = UIButton(configuration: config)
        b.addTarget(self, action: #selector(validateTapped), for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }()

    private lazy var resultLabel: UILabel = {
        let l = UILabel()
        l.textAlignment = .center
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init

    init(logger: EventLogger) {
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Handled Errors"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        
        let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tap)
    }

    // MARK: - Layout

    private func setupLayout() {
        let card = UIView()
        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 12
        card.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(card)
        card.addSubview(instructionLabel)
        card.addSubview(usernameField)
        card.addSubview(codeField)
        card.addSubview(validateButton)
        card.addSubview(resultLabel)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            instructionLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            instructionLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),

            usernameField.topAnchor.constraint(equalTo: instructionLabel.bottomAnchor, constant: 24),
            usernameField.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            usernameField.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            usernameField.heightAnchor.constraint(equalToConstant: 44),

            codeField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 12),
            codeField.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            codeField.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            codeField.heightAnchor.constraint(equalToConstant: 44),

            validateButton.topAnchor.constraint(equalTo: codeField.bottomAnchor, constant: 20),
            validateButton.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            validateButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            validateButton.heightAnchor.constraint(equalToConstant: 50),

            resultLabel.topAnchor.constraint(equalTo: validateButton.bottomAnchor, constant: 16),
            resultLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            resultLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            resultLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20)
        ])
    }

    // MARK: - Actions

    @objc private func validateTapped() {
        view.endEditing(true)
        
        let username = usernameField.text ?? ""
        let code = codeField.text ?? ""
        
        if username == "admin" && code == "1234" {
            resultLabel.text = "✅  Access Granted"
            resultLabel.textColor = .systemGreen
        } else {
            resultLabel.text = "❌  Validation Failed"
            resultLabel.textColor = .systemRed
            
            // Log Handled Error
            let errorDomain = "com.rumsimulator.validation"
            let errorCode = username != "admin" ? 1001 : 1002
            let errorReason = username != "admin" ? "Invalid Username" : "Invalid Security Code"
            
            logger.log(
                type: "error",
                metadata: [
                    "error.type": "HandledException",
                    "error.message": "Validation failed for input: \(username)",
                    "error.stack": "HandledErrorPlaygroundVC.validateTapped()",
                    "validation.reason": errorReason,
                    "validation.code": "\(errorCode)",
                    "domain": errorDomain
                ]
            )
            
            // Visual feedback for error
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

#endif
