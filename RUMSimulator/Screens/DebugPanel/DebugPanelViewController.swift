#if os(iOS)
import UIKit

// MARK: - DebugPanelViewController

/// Hidden panel revealed by shake gesture or long-press on app logo.
/// Exposed via Notification.Name.showDebugPanel.
final class DebugPanelViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: DebugPanelViewModel
    private let engine: ScenarioEngine
    private let logger: EventLogger

    // MARK: - UI Elements

    private let scrollView = UIScrollView()
    private let stackView  = UIStackView()

    private lazy var speedLabel    = makeLabel("Speed Multiplier: 1.0×")
    private lazy var speedSlider   = makeSlider(min: 0.5, max: 5.0, value: 1.0, action: #selector(speedChanged))

    private lazy var delayLabel    = makeLabel("Network Delay Override")
    private lazy var delaySwitch   = UISwitch()

    private lazy var failureLabel  = makeLabel("Failure Rate: 0%")
    private lazy var failureSlider = makeSlider(min: 0, max: 1.0, value: 0, action: #selector(failureChanged))

    private lazy var crashButton   = makeDangerButton(title: "⚠️  Force Crash", action: #selector(forceCrash))
    private lazy var bgButton      = makeButton(title: "☁️  Simulate Background", action: #selector(forceBackground))
    private lazy var resetButton   = makeButton(title: "↺  Reset All State", action: #selector(resetAll))

    // MARK: - Init

    init(viewModel: DebugPanelViewModel, engine: ScenarioEngine, logger: EventLogger) {
        self.viewModel = viewModel
        self.engine = engine
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "🛠 Debug Panel"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismiss(_:)))

        setupScrollStack()
        buildControls()
    }

    // MARK: - Layout

    private func setupScrollStack() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 40, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(stackView)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

    private func buildControls() {
        // Banner
        stackView.addArrangedSubview(makeBanner())
        stackView.addArrangedSubview(makeSeparator())

        // Speed multiplier
        stackView.addArrangedSubview(makeSection(title: "⚡ Speed Multiplier (0.5× – 5×)"))
        stackView.addArrangedSubview(speedLabel)
        stackView.addArrangedSubview(speedSlider)
        stackView.addArrangedSubview(makeSeparator())

        // Network delay
        stackView.addArrangedSubview(makeSection(title: "🌐 Network Delay Override"))
        let delayRow = makeHorizontalRow(label: delayLabel, control: delaySwitch)
        delaySwitch.addTarget(self, action: #selector(delayToggled), for: .valueChanged)
        stackView.addArrangedSubview(delayRow)
        stackView.addArrangedSubview(makeSeparator())

        // Failure rate
        stackView.addArrangedSubview(makeSection(title: "💥 Failure Rate (0% – 100%)"))
        stackView.addArrangedSubview(failureLabel)
        stackView.addArrangedSubview(failureSlider)
        stackView.addArrangedSubview(makeSeparator())

        // Action buttons
        stackView.addArrangedSubview(makeSection(title: "🔧 Actions"))
        stackView.addArrangedSubview(crashButton)
        stackView.addArrangedSubview(bgButton)
        stackView.addArrangedSubview(resetButton)
    }

    // MARK: - Actions

    @objc private func speedChanged(_ slider: UISlider) {
        let val = Double(slider.value)
        viewModel.speedMultiplier = val
        speedLabel.text = String(format: "Speed Multiplier: %.1f×", val)
    }

    @objc private func delayToggled(_ sw: UISwitch) {
        viewModel.networkDelayEnabled = sw.isOn
    }

    @objc private func failureChanged(_ slider: UISlider) {
        let val = Double(slider.value)
        viewModel.failureRate = val
        failureLabel.text = String(format: "Failure Rate: %.0f%%", val * 100)
    }

    @objc private func forceCrash() {
        let alert = UIAlertController(title: "Trigger Crash?",
                                      message: "This will immediately crash the app to test the RUM SDK crash capture.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Crash", style: .destructive) { _ in
            fatalError("[RUMSimulator] Intentional test crash triggered from Debug Panel")
        })
        present(alert, animated: true)
    }

    @objc private func forceBackground() {
        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)
        logger.log(type: "lifecycle", metadata: ["event": "debug_panel_force_background"])
    }

    @objc private func resetAll() {
        engine.reset()
        logger.clear()
        dismiss(animated: true)
    }

    @objc private func dismiss(_ sender: Any) {
        dismiss(animated: true)
    }

    // MARK: - UI Factories

    private func makeLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        l.textColor = .label
        return l
    }

    private func makeSection(title: String) -> UILabel {
        let l = UILabel()
        l.text = title
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }

    private func makeBanner() -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
        container.layer.cornerRadius = 10
        let label = UILabel()
        label.text = "⚠️  DEBUG PANEL — Internal Use Only"
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .systemOrange
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10),
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -12),
        ])
        return container
    }

    private func makeSlider(min: Float, max: Float, value: Float, action: Selector) -> UISlider {
        let s = UISlider()
        s.minimumValue = min
        s.maximumValue = max
        s.value = value
        s.addTarget(self, action: action, for: .valueChanged)
        return s
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        b.backgroundColor = .secondarySystemBackground
        b.layer.cornerRadius = 10
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    private func makeDangerButton(title: String, action: Selector) -> UIButton {
        let b = makeButton(title: title, action: action)
        b.setTitleColor(.systemRed, for: .normal)
        b.layer.borderWidth = 1
        b.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.4).cgColor
        return b
    }

    private func makeHorizontalRow(label: UILabel, control: UIView) -> UIStackView {
        let s = UIStackView(arrangedSubviews: [label, UIView(), control])
        s.axis = .horizontal
        s.spacing = 8
        return s
    }

    private func makeSeparator() -> UIView {
        let v = UIView()
        v.backgroundColor = .separator
        v.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
        return v
    }
}

#endif