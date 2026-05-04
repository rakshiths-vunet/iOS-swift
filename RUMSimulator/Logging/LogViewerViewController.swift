#if os(iOS)
import UIKit

// MARK: - LogViewerViewController

/// Displays in-memory log events with type filter and share export.
final class LogViewerViewController: UIViewController {

    // MARK: - Dependencies
    private let logger: EventLogger

    // MARK: - State
    private var allEvents: [LogEvent] = []
    private var filteredEvents: [LogEvent] = []
    private var selectedType: String = "All"

    private let types = ["All", "navigation", "tap", "network", "lifecycle", "crash", "step"]

    // MARK: - UI
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .plain)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(LogEventCell.self, forCellReuseIdentifier: LogEventCell.reuseID)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 60
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        return tv
    }()

    private lazy var segmentedControl: UISegmentedControl = {
        let sc = UISegmentedControl(items: types)
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        sc.addTarget(self, action: #selector(filterChanged), for: .valueChanged)
        return sc
    }()

    private lazy var shareButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(shareLogs))
    }()

    private lazy var refreshButton: UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(refreshLogs))
    }()

    private lazy var emptyLabel: UILabel = {
        let l = UILabel()
        l.text = "No events yet.\nRun a scenario to generate logs."
        l.textAlignment = .center
        l.numberOfLines = 0
        l.textColor = .secondaryLabel
        l.font = .systemFont(ofSize: 15)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    // MARK: - Init

    init(logger: EventLogger) {
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Event Log"
        view.backgroundColor = .systemBackground
        navigationItem.rightBarButtonItems = [shareButton, refreshButton]
        setupLayout()
        tableView.dataSource = self
        tableView.delegate = self
        refreshLogs()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshLogs()
    }

    // MARK: - Layout

    private func setupLayout() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsHorizontalScrollIndicator = false

        let segWrapper = UIView()
        segWrapper.translatesAutoresizingMaskIntoConstraints = false
        segWrapper.addSubview(segmentedControl)
        NSLayoutConstraint.activate([
            segmentedControl.leadingAnchor.constraint(equalTo: segWrapper.leadingAnchor, constant: 12),
            segmentedControl.trailingAnchor.constraint(equalTo: segWrapper.trailingAnchor, constant: -12),
            segmentedControl.topAnchor.constraint(equalTo: segWrapper.topAnchor, constant: 8),
            segmentedControl.bottomAnchor.constraint(equalTo: segWrapper.bottomAnchor, constant: -8),
        ])

        view.addSubview(segWrapper)
        view.addSubview(tableView)
        view.addSubview(emptyLabel)

        NSLayoutConstraint.activate([
            segWrapper.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            segWrapper.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            segWrapper.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            segWrapper.heightAnchor.constraint(equalToConstant: 50),

            tableView.topAnchor.constraint(equalTo: segWrapper.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    // MARK: - Actions

    @objc private func filterChanged() {
        let idx = segmentedControl.selectedSegmentIndex
        selectedType = types[idx]
        applyFilter()
    }

    @objc private func refreshLogs() {
        allEvents = logger.events.reversed()
        applyFilter()
    }

    @objc private func shareLogs() {
        guard let url = try? logger.exportURL() else { return }
        logger.flush()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let popover = vc.popoverPresentationController {
                popover.barButtonItem = self.shareButton
            }
            self.present(vc, animated: true)
        }
    }

    private func applyFilter() {
        if selectedType == "All" {
            filteredEvents = allEvents
        } else {
            filteredEvents = allEvents.filter { $0.type == selectedType }
        }
        emptyLabel.isHidden = !filteredEvents.isEmpty
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension LogViewerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredEvents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: LogEventCell.reuseID, for: indexPath) as! LogEventCell
        cell.configure(with: filteredEvents[indexPath.row])
        return cell
    }
}

// MARK: - UITableViewDelegate

extension LogViewerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - LogEventCell

final class LogEventCell: UITableViewCell {
    static let reuseID = "LogEventCell"

    private let iconLabel = UILabel()
    private let typeLabel = UILabel()
    private let summaryLabel = UILabel()
    private let timestampLabel = UILabel()
    private let scenarioLabel = UILabel()

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        iconLabel.font = .systemFont(ofSize: 18)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false

        typeLabel.font = .monospacedSystemFont(ofSize: 10, weight: .semibold)
        typeLabel.textColor = .systemBlue
        typeLabel.translatesAutoresizingMaskIntoConstraints = false

        summaryLabel.font = .systemFont(ofSize: 13, weight: .medium)
        summaryLabel.textColor = .label
        summaryLabel.numberOfLines = 2
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false

        timestampLabel.font = .monospacedSystemFont(ofSize: 10, weight: .regular)
        timestampLabel.textColor = .secondaryLabel
        timestampLabel.translatesAutoresizingMaskIntoConstraints = false

        scenarioLabel.font = .systemFont(ofSize: 10)
        scenarioLabel.textColor = .tertiaryLabel
        scenarioLabel.translatesAutoresizingMaskIntoConstraints = false

        let textStack = UIStackView(arrangedSubviews: [
            horizontalStack([typeLabel, UIView(), timestampLabel]),
            summaryLabel,
            scenarioLabel
        ])
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(iconLabel)
        contentView.addSubview(textStack)

        NSLayoutConstraint.activate([
            iconLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            iconLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            iconLabel.widthAnchor.constraint(equalToConstant: 28),

            textStack.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 8),
            textStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            textStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
        ])
    }

    private func horizontalStack(_ views: [UIView]) -> UIStackView {
        let s = UIStackView(arrangedSubviews: views)
        s.axis = .horizontal
        s.spacing = 4
        return s
    }

    func configure(with event: LogEvent) {
        iconLabel.text = event.typeIcon
        typeLabel.text = event.type.uppercased()
        summaryLabel.text = event.summary
        timestampLabel.text = LogEventCell.dateFormatter.string(from: event.timestamp)

        if let scenario = event.scenario, let step = event.step {
            scenarioLabel.text = "\(scenario) · step \(step)"
        } else if let scenario = event.scenario {
            scenarioLabel.text = scenario
        } else {
            scenarioLabel.text = ""
        }
    }
}

#endif