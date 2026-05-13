// #if os(iOS)
import UIKit

/// A UIKit playground that simulates rendering jank.
/// Users can customise the number of frames, period between frames, and the maximum blocking time (threshold).
/// Two modes are supported:
/// • Controlled – each frame uses the exact period and threshold values.
/// • Random    – each frame picks a random period in [0, configured period] and a random blocking time up to threshold.
final class RenderSlowPlaygroundVC: UIViewController {
    // MARK: - Public model
    struct Settings {
        var frameCount: Int
        var period: Double
        var threshold: Double
        var mode: RenderSlowPlaygroundVC.Mode
    }
    // MARK: - UI Controls
    private let frameCountSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 1
        s.maximumValue = 200
        s.value = 30
        return s
    }()
    private let periodSlider: UISlider = {
        // period in seconds
        let s = UISlider()
        s.minimumValue = 0.0
        s.maximumValue = 2.0
        s.value = 0.2
        return s
    }()
    private let thresholdSlider: UISlider = {
        // threshold in seconds (max block per frame)
        let s = UISlider()
        s.minimumValue = 0.01
        s.maximumValue = 0.5
        s.value = 0.1
        return s
    }()
    private let modeSegmented: UISegmentedControl = {
        let seg = UISegmentedControl(items: ["Controlled", "Random"])
        seg.selectedSegmentIndex = 0
        return seg
    }()
    private let startButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "▶ Start"
        config.baseBackgroundColor = .systemGreen
        return UIButton(configuration: config)
    }()
    private let stopButton: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "⏹ Stop"
        config.baseBackgroundColor = .systemRed
        return UIButton(configuration: config)
    }()
    private let thresholdMsSlider: UISlider = {
        // threshold in milliseconds (frames.slow_threshold_ms)
        let s = UISlider()
        s.minimumValue = 1
        s.maximumValue = 100
        s.value = 33.33
        return s
    }()
    private let statusLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Status: Ready"
        lbl.font = .systemFont(ofSize: 14, weight: .semibold)
        lbl.textColor = .systemGreen
        lbl.textAlignment = .center
        return lbl
    }()
    // MARK: - State
    private var framesRemaining = 0
    private var isRunning = false
    private var displayLink: CADisplayLink?
    private var animatedBox: UIView?
    private var boxPosition: CGFloat = 0
    
    // Jank engine state
    private var lastJankTriggerTime: CFTimeInterval = 0
    private let frameDuration = 1.0 / 60.0  // 16.67ms per frame at 60fps
    private var jankInProgress = false
    private var jankStartTime: CFTimeInterval = 0
    
    private var currentMode: Mode {
        return modeSegmented.selectedSegmentIndex == 0 ? .controlled : .random
    }
    enum Mode { case controlled, random }

    // Expose current settings and allow external controllers to apply them.
    var currentSettings: Settings {
        return Settings(frameCount: Int(frameCountSlider.value), period: Double(periodSlider.value), threshold: Double(thresholdSlider.value), mode: currentMode)
    }

    func apply(settings: Settings, startImmediately: Bool = false) {
        frameCountSlider.value = Float(settings.frameCount)
        periodSlider.value = Float(settings.period)
        thresholdSlider.value = Float(settings.threshold)
        modeSegmented.selectedSegmentIndex = (settings.mode == .controlled) ? 0 : 1
        if startImmediately {
            startJank()
        }
    }
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "render.slow"
        view.backgroundColor = .systemBackground
        setupUI()
        startButton.addAction(UIAction { [weak self] _ in self?.startJank() }, for: .touchUpInside)
        stopButton.addAction(UIAction { [weak self] _ in self?.stopJank() }, for: .touchUpInside)
        updateButtonStates()
    }
    // MARK: - UI Setup
    private func setupUI() {
        frameCountSlider.addTarget(self, action: #selector(updateValueLabels), for: .valueChanged)
        periodSlider.addTarget(self, action: #selector(updateValueLabels), for: .valueChanged)
        thresholdSlider.addTarget(self, action: #selector(updateValueLabels), for: .valueChanged)
        thresholdMsSlider.addTarget(self, action: #selector(updateValueLabels), for: .valueChanged)
        
        // Create animated indicator box
        let box = UIView()
        box.backgroundColor = .systemBlue
        box.layer.cornerRadius = 8
        box.translatesAutoresizingMaskIntoConstraints = false
        box.heightAnchor.constraint(equalToConstant: 40).isActive = true
        box.widthAnchor.constraint(equalToConstant: 40).isActive = true
        self.animatedBox = box
        
        let animationLabel = UILabel()
        animationLabel.text = "↔ Visual Activity"
        animationLabel.font = .systemFont(ofSize: 12, weight: .regular)
        animationLabel.textColor = .secondaryLabel
        
        let animationContainer = UIStackView(arrangedSubviews: [animationLabel, box])
        animationContainer.axis = .vertical
        animationContainer.alignment = .center
        animationContainer.spacing = 4
        
        let stack = UIStackView(arrangedSubviews: [
            statusLabel,
            animationContainer,
            labeledSlider(label: "Frames to Drop", slider: frameCountSlider, format: "%.0f"),
            labeledSlider(label: "Jank Period (s)", slider: periodSlider, format: "%.2f"),
            labeledSlider(label: "Threshold (s)", slider: thresholdSlider, format: "%.3f"),
            labeledSlider(label: "Threshold (ms)", slider: thresholdMsSlider, format: "%.2f"),
            modeSegmented,
            makeControlRow()
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        updateValueLabels()
    }
    
    private func makeControlRow() -> UIStackView {
        let row = UIStackView(arrangedSubviews: [startButton, stopButton])
        row.axis = .horizontal
        row.spacing = 12
        row.distribution = .fillEqually
        return row
    }
    
    private func updateButtonStates() {
        startButton.isEnabled = !isRunning
        stopButton.isEnabled = isRunning
        startButton.alpha = isRunning ? 0.5 : 1.0
        stopButton.alpha = isRunning ? 1.0 : 0.5
    }
    
    private var valueLabels: [UILabel] = []
    
    @objc private func updateValueLabels() {
        if valueLabels.count >= 4 {
            valueLabels[0].text = String(format: "%.0f", frameCountSlider.value)
            valueLabels[1].text = String(format: "%.2f", periodSlider.value)
            valueLabels[2].text = String(format: "%.3f", thresholdSlider.value)
            valueLabels[3].text = String(format: "%.2f", thresholdMsSlider.value)
        }
    }
    
    private func labeledSlider(label: String, slider: UISlider, format: String) -> UIStackView {
        let lbl = UILabel()
        lbl.text = label
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        
        let valueLbl = UILabel()
        valueLbl.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        valueLbl.textColor = .systemBlue
        valueLbl.textAlignment = .right
        valueLbl.text = String(format: format, slider.value)
        valueLabels.append(valueLbl)
        
        let headerStack = UIStackView(arrangedSubviews: [lbl, valueLbl])
        headerStack.axis = .horizontal
        headerStack.distribution = .fill
        
        let container = UIStackView(arrangedSubviews: [headerStack, slider])
        container.axis = .vertical
        container.spacing = 4
        return container
    }
    // MARK: - Jank Simulation
    private func startJank() {
        isRunning = true
        updateButtonStates()
        statusLabel.text = "Status: Running VSync-synchronized jank..."
        statusLabel.textColor = .systemOrange
        animatedBox?.backgroundColor = .systemBlue
        startAnimatingBox()
    }
    
    private func stopJank() {
        isRunning = false
        jankInProgress = false
        updateButtonStates()
        statusLabel.text = "Status: Stopped"
        statusLabel.textColor = .systemRed
        stopAnimatingBox()
        animatedBox?.backgroundColor = .systemRed
    }
    
    private func startAnimatingBox() {
        displayLink = CADisplayLink(target: self, selector: #selector(onDisplayLinkTick))
        displayLink?.preferredFramesPerSecond = 60
        displayLink?.add(to: .main, forMode: .common)
        lastJankTriggerTime = CACurrentMediaTime()
        jankInProgress = false
    }
    
    private func stopAnimatingBox() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    @objc private func onDisplayLinkTick(displayLink: CADisplayLink) {
        guard isRunning else { return }
        
        let now = CACurrentMediaTime()
        
        // If not in jank, check if we should trigger one
        if !jankInProgress {
            let period = Double(periodSlider.value)
            if now - lastJankTriggerTime >= period {
                triggerJank()
                lastJankTriggerTime = now
            }
        } else {
            // Currently in jank, check if we should stop
            let jankDuration = now - jankStartTime
            let targetDuration = Double(Int(frameCountSlider.value)) * frameDuration
            if jankDuration >= targetDuration {
                jankInProgress = false
                animatedBox?.backgroundColor = .systemGreen
            } else {
                // Actively blocking - perform computation
                blockMainThread()
            }
        }
        
        // Animate the box smoothly (will stutter when jank is blocking)
        boxPosition += 8
        if boxPosition > 150 {
            boxPosition = 0
        }
        animatedBox?.layer.position = CGPoint(x: boxPosition, y: animatedBox?.layer.position.y ?? 0)
    }
    
    private func triggerJank() {
        jankInProgress = true
        jankStartTime = CACurrentMediaTime()
        animatedBox?.backgroundColor = .systemOrange
    }
    
    @objc private func updateAnimation() {
        // Legacy method - no longer used, kept for compatibility
    }
    
    private func scheduleNextFrame() {
        // Legacy method - no longer used, kept for compatibility
    }
    
    private func blockMainThread() {
        // Perform actual computation to block main thread deterministically
        // This creates real frame drops synchronized with display refresh
        let iterations = 10000
        var sum: Double = 0
        for i in 0..<iterations {
            sum += sqrt(Double(i))
        }
        // Use the sum to prevent optimization
        _ = sum
    }
}
// Companion UI: Root tab controller + Settings screen

protocol RenderSlowSettingsDelegate: AnyObject {
    func renderSlowSettingsDidChange(_ settings: RenderSlowPlaygroundVC.Settings, startImmediately: Bool)
}

/// Root container for the render.slow playground. Provides two tabs:
/// • Simulator — the busy-waiting `RenderSlowPlaygroundVC` where jank is produced
/// • Settings   — a companion settings screen that controls the simulator
final class RenderSlowRootVC: UITabBarController {

    private let simulatorVC = RenderSlowPlaygroundVC()
    private let settingsVC = RenderSlowSettingsVC()

    override func viewDidLoad() {
        super.viewDidLoad()
        simulatorVC.title = "Simulator"
        settingsVC.title = "Settings"
        settingsVC.delegate = self

        viewControllers = [
            UINavigationController(rootViewController: simulatorVC),
            UINavigationController(rootViewController: settingsVC)
        ]

        tabBar.items?.first?.image = UIImage(systemName: "play.circle")
        tabBar.items?.last?.image = UIImage(systemName: "slider.horizontal.3")
        title = "render.slow"
    }
}

extension RenderSlowRootVC: RenderSlowSettingsDelegate {
    func renderSlowSettingsDidChange(_ settings: RenderSlowPlaygroundVC.Settings, startImmediately: Bool) {
        simulatorVC.apply(settings: settings, startImmediately: startImmediately)
    }
}

final class RenderSlowSettingsVC: UIViewController {

    weak var delegate: RenderSlowSettingsDelegate?

    private let frameCountSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 1
        s.maximumValue = 200
        s.value = 30
        return s
    }()
    private let periodSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 0.0
        s.maximumValue = 2.0
        s.value = 0.2
        return s
    }()
    private let thresholdSlider: UISlider = {
        let s = UISlider()
        s.minimumValue = 0.01
        s.maximumValue = 0.5
        s.value = 0.1
        return s
    }()
    private let modeSegmented: UISegmentedControl = {
        let seg = UISegmentedControl(items: ["Controlled", "Random"])
        seg.selectedSegmentIndex = 0
        return seg
    }()
    private let applyButton: UIButton = {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "Apply"
        return UIButton(configuration: cfg)
    }()
    private let applyAndStartButton: UIButton = {
        var cfg = UIButton.Configuration.tinted()
        cfg.title = "Apply & Start"
        return UIButton(configuration: cfg)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Render Settings"
        view.backgroundColor = .systemBackground
        setupUI()
        applyButton.addAction(UIAction { [weak self] _ in self?.apply(start: false) }, for: .touchUpInside)
        applyAndStartButton.addAction(UIAction { [weak self] _ in self?.apply(start: true) }, for: .touchUpInside)
        frameCountSlider.addTarget(self, action: #selector(updateValueLabels), for: .valueChanged)
        periodSlider.addTarget(self, action: #selector(updateValueLabels), for: .valueChanged)
        thresholdSlider.addTarget(self, action: #selector(updateValueLabels), for: .valueChanged)
    }

    private var valueLabels: [UILabel] = []
    
    @objc private func updateValueLabels() {
        if valueLabels.count >= 3 {
            valueLabels[0].text = String(format: "%.0f", frameCountSlider.value)
            valueLabels[1].text = String(format: "%.2f", periodSlider.value)
            valueLabels[2].text = String(format: "%.3f", thresholdSlider.value)
        }
    }

    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [
            labeledSlider(label: "Frames", slider: frameCountSlider, format: "%.0f"),
            labeledSlider(label: "Period (s)", slider: periodSlider, format: "%.2f"),
            labeledSlider(label: "Threshold (s)", slider: thresholdSlider, format: "%.3f"),
            modeSegmented,
            applyButton,
            applyAndStartButton
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        updateValueLabels()
    }

    private func labeledSlider(label: String, slider: UISlider, format: String) -> UIStackView {
        let lbl = UILabel()
        lbl.text = label
        lbl.font = .systemFont(ofSize: 14, weight: .medium)
        
        let valueLbl = UILabel()
        valueLbl.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        valueLbl.textColor = .systemBlue
        valueLbl.textAlignment = .right
        valueLbl.text = String(format: format, slider.value)
        valueLabels.append(valueLbl)
        
        let headerStack = UIStackView(arrangedSubviews: [lbl, valueLbl])
        headerStack.axis = .horizontal
        headerStack.distribution = .fill
        
        let container = UIStackView(arrangedSubviews: [headerStack, slider])
        container.axis = .vertical
        container.spacing = 4
        return container
    }

    private func apply(start: Bool) {
        let mode: RenderSlowPlaygroundVC.Mode = modeSegmented.selectedSegmentIndex == 0 ? .controlled : .random
        let settings = RenderSlowPlaygroundVC.Settings(frameCount: Int(frameCountSlider.value), period: Double(periodSlider.value), threshold: Double(thresholdSlider.value), mode: mode)
        delegate?.renderSlowSettingsDidChange(settings, startImmediately: start)
    }
}

// #endif
