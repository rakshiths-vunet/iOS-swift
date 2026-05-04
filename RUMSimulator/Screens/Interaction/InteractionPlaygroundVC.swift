#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

// MARK: - InteractionPlaygroundVC

/// Tap burst, scroll velocity, gesture simulation.
/// Engine calls simulation methods directly; manual mode uses UI controls.
final class InteractionPlaygroundVC: UIViewController {

    // MARK: - State
    private var tapCount = 0
    private var gestureLog: [String] = []

    // MARK: - UI
    private lazy var tapButtonsStack = UIStackView()
    private lazy var tapButtons: [UIButton] = (0..<5).map { makeNumberedTapButton(index: $0) }
    private lazy var tapCountLabel: UILabel = {
        let l = UILabel()
        l.text = "Taps: 0"
        l.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        l.textColor = .secondaryLabel
        return l
    }()

    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return tv
    }()

    private lazy var gestureLogLabel: UILabel = {
        let l = UILabel()
        l.text = "Gesture log:"
        l.font = .systemFont(ofSize: 12, weight: .semibold)
        l.textColor = .tertiaryLabel
        return l
    }()

    private lazy var gestureLogTextView: UITextView = {
        let tv = UITextView()
        tv.isEditable = false
        tv.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        tv.textColor = .label
        tv.backgroundColor = .secondarySystemBackground
        tv.layer.cornerRadius = 8
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()

    private lazy var scrollBurstButton: UIButton = makeButton(title: "Scroll Burst ↕", action: #selector(scrollBurst))
    private lazy var longPressButton: UIButton  = makeButton(title: "Long Press", action: #selector(longPressTap))
    private lazy var swipeLeftButton: UIButton  = makeButton(title: "Swipe ←", action: #selector(swipeLeftTap))
    private lazy var swipeRightButton: UIButton = makeButton(title: "Swipe →", action: #selector(swipeRightTap))

    // MARK: - Gesture recognizers (for engine use)
    private lazy var longPressRecognizer: UILongPressGestureRecognizer = {
        let r = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        r.minimumPressDuration = 0.5
        return r
    }()
    private lazy var swipeLeftRecognizer: UISwipeGestureRecognizer = {
        let r = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        r.direction = .left
        return r
    }()
    private lazy var swipeRightRecognizer: UISwipeGestureRecognizer = {
        let r = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        r.direction = .right
        return r
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Interaction Playground"
        view.backgroundColor = .systemBackground
        setupLayout()
        view.addGestureRecognizer(longPressRecognizer)
        view.addGestureRecognizer(swipeLeftRecognizer)
        view.addGestureRecognizer(swipeRightRecognizer)
    }

    // MARK: - Layout

    private func setupLayout() {
        // Tap buttons row
        tapButtonsStack.axis = .horizontal
        tapButtonsStack.spacing = 8
        tapButtonsStack.distribution = .fillEqually
        tapButtons.forEach { tapButtonsStack.addArrangedSubview($0) }

        let tapSection = UIStackView(arrangedSubviews: [
            sectionHeader("Tap Burst"),
            tapButtonsStack,
            tapCountLabel,
        ])
        tapSection.axis = .vertical
        tapSection.spacing = 8

        let gestureButtons = UIStackView(arrangedSubviews: [scrollBurstButton, longPressButton, swipeLeftButton, swipeRightButton])
        gestureButtons.axis = .horizontal
        gestureButtons.spacing = 8
        gestureButtons.distribution = .fillEqually

        let gestureSection = UIStackView(arrangedSubviews: [
            sectionHeader("Gestures"),
            gestureButtons
        ])
        gestureSection.axis = .vertical
        gestureSection.spacing = 8

        let scrollSection = UIStackView(arrangedSubviews: [
            sectionHeader("Scroll (200 rows)"),
            tableView
        ])
        scrollSection.axis = .vertical
        scrollSection.spacing = 4
        tableView.heightAnchor.constraint(equalToConstant: 200).isActive = true

        let logSection = UIStackView(arrangedSubviews: [
            sectionHeader("Gesture Log"),
            gestureLogTextView
        ])
        logSection.axis = .vertical
        logSection.spacing = 4
        gestureLogTextView.heightAnchor.constraint(equalToConstant: 100).isActive = true

        let mainStack = UIStackView(arrangedSubviews: [tapSection, gestureSection, scrollSection, logSection])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)
        mainStack.isLayoutMarginsRelativeArrangement = true
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(mainStack)
        view.addSubview(scrollView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mainStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            mainStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
        ])
    }

    // MARK: - Engine-callable interface

    func simulateTapBurst(count: Int) {
        for i in 0..<count {
            let buttonIndex = i % tapButtons.count
            tapButtons[buttonIndex].sendActions(for: .touchUpInside)
        }
    }

    func simulateScrollDown() {
        let maxOffset = CGFloat(200 * 44) - tableView.bounds.height
        let target = min(tableView.contentOffset.y + 300, max(maxOffset, 0))
        UIView.animate(withDuration: 0.5) {
            self.tableView.contentOffset = CGPoint(x: 0, y: target)
        }
        appendGestureLog("scroll_down")
    }

    func simulateScrollUp() {
        let target = max(tableView.contentOffset.y - 300, 0)
        UIView.animate(withDuration: 0.5) {
            self.tableView.contentOffset = CGPoint(x: 0, y: target)
        }
        appendGestureLog("scroll_up")
    }

    func simulateLongPress() {
        handleLongPress(longPressRecognizer)
    }

    func simulateSwipeLeft() {
        handleSwipeLeft(swipeLeftRecognizer)
    }

    func simulateSwipeRight() {
        handleSwipeRight(swipeRightRecognizer)
    }

    // MARK: - Button targets

    @objc private func tapButtonPressed(_ sender: UIButton) {
        tapCount += 1
        tapCountLabel.text = "Taps: \(tapCount)"
        appendGestureLog("tap_button_\(sender.tag)")
    }

    @objc private func scrollBurst() {
        simulateScrollDown()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { self.simulateScrollUp() }
    }

    @objc private func longPressTap() {
        simulateLongPress()
    }

    @objc private func swipeLeftTap() {
        simulateSwipeLeft()
    }

    @objc private func swipeRightTap() {
        simulateSwipeRight()
    }

    // MARK: - Gesture handlers

    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began || recognizer.state == .recognized {
            appendGestureLog("long_press")
        }
    }

    @objc private func handleSwipeLeft(_ recognizer: UISwipeGestureRecognizer) {
        appendGestureLog("swipe_left")
    }

    @objc private func handleSwipeRight(_ recognizer: UISwipeGestureRecognizer) {
        appendGestureLog("swipe_right")
    }

    // MARK: - Helpers

    private func appendGestureLog(_ event: String) {
        let entry = "[\(Date().formatted(.dateTime.hour().minute().second()))] \(event)"
        gestureLog.insert(entry, at: 0)
        if gestureLog.count > 50 { gestureLog.removeLast() }
        gestureLogTextView.text = gestureLog.joined(separator: "\n")
    }

    private func makeNumberedTapButton(index: Int) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = "\(index + 1)"
        config.cornerStyle = .capsule
        config.baseBackgroundColor = .systemBlue
        let b = UIButton(configuration: config)
        b.tag = index
        b.addTarget(self, action: #selector(tapButtonPressed), for: .touchUpInside)
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return b
    }

    private func makeButton(title: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.tinted()
        config.title = title
        config.cornerStyle = .medium
        let b = UIButton(configuration: config)
        b.addTarget(self, action: action, for: .touchUpInside)
        b.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return b
    }

    private func sectionHeader(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text.uppercased()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .secondaryLabel
        l.letterSpacing(1.2)
        return l
    }
}

// MARK: - UITableViewDataSource (200 rows)

extension InteractionPlaygroundVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 200 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row)"
        cell.textLabel?.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        return cell
    }
}

// MARK: - UILabel helper extension

private extension UILabel {
    func letterSpacing(_ value: CGFloat) {
        guard let text = text else { return }
        let attributed = NSAttributedString(string: text, attributes: [.kern: value])
        attributedText = attributed
    }
}

#endif