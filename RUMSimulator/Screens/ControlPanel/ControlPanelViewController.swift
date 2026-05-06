#if os(iOS)
import UIKit
import Combine

// MARK: - ControlPanelViewController

/// Home screen: mode toggle, scenario picker, live status, playground navigation.
final class ControlPanelViewController: UIViewController {

    // MARK: - Dependencies

    private let viewModel: ControlPanelViewModel
    private let engine: ScenarioEngine
    private let debugViewModel: DebugPanelViewModel
    private weak var coordinator: PlaygroundCoordinator?

    private var cancellables: Set<AnyCancellable> = []

    // MARK: - UI

    private lazy var scrollView: UIScrollView = {
        let s = UIScrollView()
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private lazy var contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 16
        s.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 30, right: 16)
        s.isLayoutMarginsRelativeArrangement = true
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    private lazy var modeSegment: UISegmentedControl = {
        let s = UISegmentedControl(items: AppMode.allCases.map { $0.rawValue })
        s.selectedSegmentIndex = 0
        s.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        return s
    }()

    private lazy var scenarioPicker: UIPickerView = {
        let p = UIPickerView()
        p.dataSource = self
        p.delegate = self
        return p
    }()

    private lazy var startButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "▶  Start"
        config.cornerStyle = .medium
        config.baseBackgroundColor = .systemGreen
        let b = UIButton(configuration: config)
        b.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
        b.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return b
    }()

    private lazy var stopButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "⏹  Stop"
        config.cornerStyle = .medium
        config.baseBackgroundColor = .systemRed
        let b = UIButton(configuration: config)
        b.addTarget(self, action: #selector(stopTapped), for: .touchUpInside)
        b.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return b
    }()

    private lazy var resetButton: UIButton = {
        var config = UIButton.Configuration.tinted()
        config.title = "↺  Reset"
        config.cornerStyle = .medium
        let b = UIButton(configuration: config)
        b.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return b
    }()

    // Live status card
    private lazy var statusCard: UIView = makeCard()
    private lazy var scenarioStatusLabel = makeStatusRow("Scenario", value: "—")
    private lazy var stepStatusLabel     = makeStatusRow("Step", value: "—")
    private lazy var rateStatusLabel     = makeStatusRow("Events/sec", value: "0")
    private lazy var progressView: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .default)
        p.progressTintColor = .systemBlue
        p.trackTintColor = .systemFill
        p.layer.cornerRadius = 2
        p.clipsToBounds = true
        return p
    }()
    private lazy var lastStepLabel: UILabel = {
        let l = UILabel()
        l.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 2
        return l
    }()

    // MARK: - Init

    init(viewModel: ControlPanelViewModel,
         engine: ScenarioEngine,
         debugViewModel: DebugPanelViewModel,
         coordinator: PlaygroundCoordinator) {
        self.viewModel = viewModel
        self.engine = engine
        self.debugViewModel = debugViewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "RUM Simulator"
        view.backgroundColor = .systemGroupedBackground
        navigationController?.navigationBar.prefersLargeTitles = true
        setupLayout()
        setupBindings()
        setupDebugPanelObserver()
        addLongPressOnLogo()
    }

    // MARK: - Layout

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])

        // Mode section
        contentStack.addArrangedSubview(sectionHeader("Mode"))
        contentStack.addArrangedSubview(modeSegment)

        // Scenario picker section
        contentStack.addArrangedSubview(sectionHeader("Scenario"))
        let pickerCard = makeCard()
        pickerCard.addSubview(scenarioPicker)
        scenarioPicker.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scenarioPicker.topAnchor.constraint(equalTo: pickerCard.topAnchor, constant: 4),
            scenarioPicker.bottomAnchor.constraint(equalTo: pickerCard.bottomAnchor, constant: -4),
            scenarioPicker.leadingAnchor.constraint(equalTo: pickerCard.leadingAnchor),
            scenarioPicker.trailingAnchor.constraint(equalTo: pickerCard.trailingAnchor),
        ])
        contentStack.addArrangedSubview(pickerCard)

        // Controls
        contentStack.addArrangedSubview(sectionHeader("Controls"))
        let controlRow = UIStackView(arrangedSubviews: [startButton, stopButton])
        controlRow.axis = .horizontal
        controlRow.spacing = 12
        controlRow.distribution = .fillEqually
        contentStack.addArrangedSubview(controlRow)
        contentStack.addArrangedSubview(resetButton)

        // Live status
        contentStack.addArrangedSubview(sectionHeader("Live Status"))
        buildStatusCard()
        contentStack.addArrangedSubview(statusCard)

        // Playground shortcuts
        contentStack.addArrangedSubview(sectionHeader("Playgrounds"))
        contentStack.addArrangedSubview(buildPlaygroundGrid())

        // Metadata Matrix Section
        contentStack.addArrangedSubview(sectionHeader("Manual Metadata Matrix"))
        contentStack.addArrangedSubview(buildMetadataMatrixView())
    }

    private func buildMetadataMatrixView() -> UIView {
        let card = makeCard()
        
        let triggerLabel = sectionHeader("Trigger")
        let triggerSelector = UISegmentedControl(items: ["Tap", "Gesture", "DeepLink", "Notify"])
        triggerSelector.selectedSegmentIndex = 0
        self.matrixTriggerSelector = triggerSelector

        let entryLabel = sectionHeader("Entry")
        let entrySelector = UISegmentedControl(items: ["Internal", "DeepLink", "External", "Restore"])
        entrySelector.selectedSegmentIndex = 0
        self.matrixEntrySelector = entrySelector

        let actionLabel = sectionHeader("Action")
        let actionSelector = UISegmentedControl(items: ["Push", "Pop", "Tab", "Modal", "Replace"])
        actionSelector.selectedSegmentIndex = 0
        self.matrixActionSelector = actionSelector

        var fireConfig = UIButton.Configuration.filled()
        fireConfig.title = "🔥  Trigger Action"
        fireConfig.baseBackgroundColor = .systemOrange
        let fireButton = UIButton(configuration: fireConfig)
        fireButton.addTarget(self, action: #selector(fireMatrixAction), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [
            triggerLabel, triggerSelector,
            entryLabel, entrySelector,
            actionLabel, actionSelector,
            fireButton
        ])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -12),
        ])
        
        return card
    }

    private var matrixTriggerSelector: UISegmentedControl?
    private var matrixEntrySelector: UISegmentedControl?
    private var matrixActionSelector: UISegmentedControl?

    @objc private func fireMatrixAction() {
        guard let coordinator = coordinator else { return }
        
        // If neither is open, default to opening the one most recently selected or a default
        // For now, if one is open, we use it. If both are nil, we open UIKit by default.
        if coordinator.navigationPlaygroundVC == nil && coordinator.swiftUINavCoordinator == nil {
            coordinator.openNavigationPlayground()
        }
        
        // Delay slightly to allow playground to load if it was just opened
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            
            let triggers: [NavTriggerType] = [.userTap, .userGesture, .deepLink, .notification]
            let entries: [NavEntryType] = [.internalFlow, .deepLink, .external, .restored]
            
            let trigger = triggers[self.matrixTriggerSelector?.selectedSegmentIndex ?? 0]
            let entry = entries[self.matrixEntrySelector?.selectedSegmentIndex ?? 0]
            let actionIdx = self.matrixActionSelector?.selectedSegmentIndex ?? 0
            
            if let navVC = coordinator.navigationPlaygroundVC {
                // UIKit Flow
                switch actionIdx {
                case 0: // Push
                    self.engine.logManualStep(label: "Matrix Push (UIKit)", trigger: trigger, entry: entry)
                    navVC.pushLevel()
                case 1: // Pop
                    self.engine.logManualStep(label: "Matrix Pop (UIKit)", trigger: trigger, entry: entry)
                    navVC.popOne()
                case 2: // Tab
                    self.engine.logManualStep(label: "Matrix Tab (UIKit)", trigger: trigger, entry: entry)
                    navVC.simulateTabSwitch()
                case 3: // Modal
                    self.engine.logManualStep(label: "Matrix Modal (UIKit)", trigger: trigger, entry: entry)
                    navVC.presentModal()
                case 4: // Replace
                    self.engine.logManualStep(label: "Matrix Replace (UIKit)", trigger: trigger, entry: entry)
                    navVC.replaceStack()
                default: break
                }
            } else if let swiftNav = coordinator.swiftUINavCoordinator {
                // SwiftUI Flow
                switch actionIdx {
                case 0: // Push
                    self.engine.logManualStep(label: "Matrix Push (SwiftUI)", trigger: trigger, entry: entry)
                    swiftNav.push()
                case 1: // Pop
                    self.engine.logManualStep(label: "Matrix Pop (SwiftUI)", trigger: trigger, entry: entry)
                    swiftNav.popOne()
                case 2: // Tab (Not supported in this SwiftUI playground yet)
                    self.engine.logManualStep(label: "Matrix Tab (SwiftUI - N/A)", trigger: trigger, entry: entry)
                case 3: // Modal
                    self.engine.logManualStep(label: "Matrix Modal (SwiftUI)", trigger: trigger, entry: entry)
                    swiftNav.presentModal()
                case 4: // Replace (Not supported in this SwiftUI playground yet)
                    self.engine.logManualStep(label: "Matrix Replace (SwiftUI - N/A)", trigger: trigger, entry: entry)
                default: break
                }
            }
        }
    }

    private func buildStatusCard() {
        let innerStack = UIStackView(arrangedSubviews: [
            scenarioStatusLabel.0,
            stepStatusLabel.0,
            rateStatusLabel.0,
            progressView,
            lastStepLabel
        ])
        innerStack.axis = .vertical
        innerStack.spacing = 8
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        statusCard.addSubview(innerStack)
        NSLayoutConstraint.activate([
            innerStack.topAnchor.constraint(equalTo: statusCard.topAnchor, constant: 12),
            innerStack.bottomAnchor.constraint(equalTo: statusCard.bottomAnchor, constant: -12),
            innerStack.leadingAnchor.constraint(equalTo: statusCard.leadingAnchor, constant: 14),
            innerStack.trailingAnchor.constraint(equalTo: statusCard.trailingAnchor, constant: -14),
        ])
    }

    private func buildPlaygroundGrid() -> UIView {
        let playgrounds: [(String, String, Selector)] = [
            ("🗺", "Navigation", #selector(openNavigation)),
            ("🔷", "SwiftUI Nav", #selector(openSwiftUINavigation)),
            ("⚡️", "API Driven UK", #selector(openAPIDrivenUIKit)),
            ("🌩", "API Driven SI", #selector(openAPIDrivenSwiftUI)),
            ("👆", "Interaction", #selector(openInteraction)),
            ("🌐", "Network",    #selector(openNetwork)),
            ("♻️", "Lifecycle",  #selector(openLifecycle)),
            ("💥", "Crash",      #selector(openCrash)),
            ("📋", "Log Viewer", #selector(openLogViewer)),
        ]

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 10

        let rows = stride(from: 0, to: playgrounds.count, by: 3).map {
            Array(playgrounds[$0..<min($0 + 3, playgrounds.count)])
        }

        for row in rows {
            let rowStack = UIStackView(arrangedSubviews: row.map { makePlaygroundButton(icon: $0.0, title: $0.1, action: $0.2) })
            rowStack.axis = .horizontal
            rowStack.spacing = 10
            rowStack.distribution = .fillEqually
            grid.addArrangedSubview(rowStack)
        }

        return grid
    }

    // MARK: - Bindings

    private func setupBindings() {
        viewModel.$currentScenarioName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                self?.scenarioStatusLabel.1.text = name
            }.store(in: &cancellables)

        viewModel.$stepIndex
            .combineLatest(viewModel.$totalSteps, viewModel.$lastStepLabel)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (step, total, label) in
                guard let self = self else { return }
                self.stepStatusLabel.1.text = total > 0 ? "Step \(step + 1) / \(total)" : "—"
                self.progressView.setProgress(Float(self.viewModel.progress), animated: true)
                self.lastStepLabel.text = label.isEmpty ? "" : "▶ \(label)"
            }.store(in: &cancellables)

        viewModel.$eventsPerSecond
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rate in
                self?.rateStatusLabel.1.text = String(format: "%.1f", rate)
            }.store(in: &cancellables)

        viewModel.$isRunning
            .receive(on: DispatchQueue.main)
            .sink { [weak self] running in
                self?.startButton.isEnabled = !running
                self?.stopButton.isEnabled = running
                self?.scenarioPicker.isUserInteractionEnabled = !running
            }.store(in: &cancellables)
    }

    // MARK: - Actions

    @objc private func modeChanged() {
        let mode = AppMode.allCases[modeSegment.selectedSegmentIndex]
        viewModel.mode = mode
    }

    @objc private func startTapped() {
        guard let scenario = viewModel.selectedScenario else { return }
        engine.run(scenario: scenario, speedMultiplier: debugViewModel.speedMultiplier)
    }

    @objc private func stopTapped() {
        engine.stop()
    }

    @objc private func resetTapped() {
        engine.reset()
    }

    @objc private func openNavigation()  { coordinator?.openNavigationPlayground() }
    @objc private func openSwiftUINavigation() { coordinator?.openSwiftUINavigationPlayground() }
    @objc private func openAPIDrivenUIKit()  { coordinator?.openAPIDrivenUIKitPlayground() }
    @objc private func openAPIDrivenSwiftUI() { coordinator?.openAPIDrivenSwiftUIPlayground() }
    @objc private func openInteraction() { coordinator?.openInteractionPlayground() }
    @objc private func openNetwork()     { coordinator?.openNetworkPlayground() }
    @objc private func openLifecycle()   { coordinator?.openLifecyclePlayground() }
    @objc private func openCrash()       { coordinator?.openCrashPlayground() }
    @objc private func openLogViewer()   { coordinator?.openLogViewer() }

    // MARK: - Debug Panel

    private func setupDebugPanelObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showDebugPanel),
            name: .showDebugPanel,
            object: nil
        )
    }

    @objc private func showDebugPanel() {
        guard let nav = navigationController else { return }
        let debugVC = DebugPanelViewController(viewModel: debugViewModel, engine: engine, logger: coordinator?.logger ?? EventLogger())
        let navController = UINavigationController(rootViewController: debugVC)
        navController.modalPresentationStyle = .formSheet
        nav.present(navController, animated: true)
    }

    private func addLongPressOnLogo() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(logoLongPressed))
        longPress.minimumPressDuration = 1.5
        navigationController?.navigationBar.addGestureRecognizer(longPress)
    }

    @objc private func logoLongPressed() {
        showDebugPanel()
    }

    // MARK: - UI Factories

    private func makeCard() -> UIView {
        let v = UIView()
        v.backgroundColor = .secondarySystemGroupedBackground
        v.layer.cornerRadius = 12
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.04
        v.layer.shadowRadius = 6
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }

    private func sectionHeader(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text.uppercased()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }

    private func makeStatusRow(_ label: String, value: String) -> (UIStackView, UILabel) {
        let titleLabel = UILabel()
        titleLabel.text = label
        titleLabel.font = .systemFont(ofSize: 13, weight: .medium)
        titleLabel.textColor = .secondaryLabel
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)
        valueLabel.textColor = .label
        valueLabel.textAlignment = .right

        let row = UIStackView(arrangedSubviews: [titleLabel, valueLabel])
        row.axis = .horizontal
        row.spacing = 8
        return (row, valueLabel)
    }

    private func makePlaygroundButton(icon: String, title: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.title = "\(icon) \(title)"
        config.cornerStyle = .medium
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
            var a = attrs
            a.font = UIFont.systemFont(ofSize: 13, weight: .medium)
            return a
        }
        let b = UIButton(configuration: config)
        b.addTarget(self, action: action, for: .touchUpInside)
        b.heightAnchor.constraint(equalToConstant: 52).isActive = true
        return b
    }
}

// MARK: - UIPickerViewDataSource

extension ControlPanelViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        viewModel.scenarios.count
    }
}

// MARK: - UIPickerViewDelegate

extension ControlPanelViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        "\(viewModel.scenarios[row].id) — \(viewModel.scenarios[row].name)"
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        viewModel.selectedScenarioIndex = row
    }
}

#endif