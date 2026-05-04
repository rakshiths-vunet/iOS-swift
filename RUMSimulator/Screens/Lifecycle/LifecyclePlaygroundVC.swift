#if os(iOS)
import UIKit

// MARK: - LifecyclePlaygroundVC

/// Background/foreground trigger UI, inactivity timer simulation.
final class LifecyclePlaygroundVC: UIViewController {

    private let logger: EventLogger
    private var inactivityTimer: Timer?
    private var eventLog: [String] = []

    private lazy var logTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        tv.textColor = .label
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 10
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
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
        title = "Lifecycle Playground"
        view.backgroundColor = .systemBackground
        setupLayout()
        observeLifecycleNotifications()
    }

    // MARK: - Layout

    private func setupLayout() {
        let bgBtn      = makeActionButton(title: "Simulate Background", action: #selector(simulateBackground))
        let fgBtn      = makeActionButton(title: "Simulate Foreground", action: #selector(simulateForeground))
        let inactBtn   = makeActionButton(title: "Start Inactivity Timer (5s)", action: #selector(startInactivity))
        let clearBtn   = makeActionButton(title: "Clear Log", action: #selector(clearLog))

        let note = UILabel()
        note.text = "ℹ️  Real backgrounding requires the user to press the Home button. These buttons post notification observers to test lifecycle wiring."
        note.numberOfLines = 0
        note.font = .systemFont(ofSize: 12)
        note.textColor = .secondaryLabel
        note.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.06)
        note.layer.cornerRadius = 8
        note.clipsToBounds = true
        note.layoutMargins = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)

        let stack = UIStackView(arrangedSubviews: [note, bgBtn, fgBtn, inactBtn, clearBtn, logTextView])
        stack.axis = .vertical
        stack.spacing = 12
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        stack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)
        view.addSubview(scrollView)

        logTextView.heightAnchor.constraint(equalToConstant: 240).isActive = true

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func simulateBackground() {
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        appendLog("Posted didEnterBackground notification")
        logger.log(type: "lifecycle", metadata: ["event": "playground_simulate_background"])
    }

    @objc private func simulateForeground() {
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        appendLog("Posted willEnterForeground + didBecomeActive")
        logger.log(type: "lifecycle", metadata: ["event": "playground_simulate_foreground"])
    }

    @objc private func startInactivity() {
        appendLog("Inactivity timer started (5s)...")
        inactivityTimer?.invalidate()
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.appendLog("Inactivity timeout — simulating idle state")
            self?.logger.log(type: "lifecycle", metadata: ["event": "inactivity_timeout"])
        }
    }

    @objc private func clearLog() {
        eventLog.removeAll()
        logTextView.text = ""
    }

    // MARK: - Notification observation

    private func observeLifecycleNotifications() {
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.appendLog("→ didEnterBackground")
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.appendLog("→ didBecomeActive")
        }
    }

    // MARK: - Helpers

    private func appendLog(_ text: String) {
        let ts = Date().formatted(.dateTime.hour().minute().second())
        eventLog.insert("[\(ts)] \(text)", at: 0)
        logTextView.text = eventLog.joined(separator: "\n")
    }

    private func makeActionButton(title: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.title = title
        config.cornerStyle = .medium
        let b = UIButton(configuration: config)
        b.addTarget(self, action: action, for: .touchUpInside)
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return b
    }
}

#endif