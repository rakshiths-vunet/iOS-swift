#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit

// MARK: - NetworkPlaygroundVC

/// Sequential / parallel / retry network call UI.
final class NetworkPlaygroundVC: UIViewController {

    // MARK: - Dependencies
    private let networkSimulator: NetworkSimulator

    // MARK: - State
    private var results: [(String, NetworkResult)] = []

    // MARK: - UI
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(NetworkResultCell.self, forCellReuseIdentifier: NetworkResultCell.reuseID)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 60
        return tv
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let a = UIActivityIndicatorView(style: .medium)
        a.translatesAutoresizingMaskIntoConstraints = false
        a.hidesWhenStopped = true
        return a
    }()

    private lazy var clearButton = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearResults))

    // MARK: - Init

    init(networkSimulator: NetworkSimulator) {
        self.networkSimulator = networkSimulator
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Network Playground"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = clearButton
        setupLayout()
        tableView.dataSource = self
    }

    // MARK: - Layout

    private func setupLayout() {
        let endpoints: [(String, HTTPBinEndpoint)] = [
            ("GET /get (fast)", .get),
            ("GET /delay/3 (slow)", .delay(3)),
            ("GET /status/500 (server error)", .status(500)),
            ("GET /status/404 (not found)", .status(404)),
            ("GET invalidDomain (DNS fail)", .invalidDomain),
        ]

        var actionButtons: [UIView] = endpoints.map { (label, endpoint) in
            makeEndpointRow(label: label, endpoint: endpoint)
        }

        let parallelBtn = makeActionButton(title: "⚡ Fire 10 Concurrent Calls", action: #selector(fireParallel))
        actionButtons.append(parallelBtn)

        let buttonsStack = UIStackView(arrangedSubviews: actionButtons)
        buttonsStack.axis = .vertical
        buttonsStack.spacing = 8
        buttonsStack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        buttonsStack.isLayoutMarginsRelativeArrangement = true
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(buttonsStack)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            buttonsStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            buttonsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: buttonsStack.bottomAnchor, constant: 4),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: buttonsStack.bottomAnchor, constant: 20),
        ])
    }

    // MARK: - Actions

    private func makeEndpointRow(label: String, endpoint: HTTPBinEndpoint) -> UIView {
        let btn = UIButton(type: .system)
        btn.setTitle(label, for: .normal)
        btn.titleLabel?.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        btn.backgroundColor = .secondarySystemBackground
        btn.layer.cornerRadius = 8
        btn.contentHorizontalAlignment = .left
        btn.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        btn.heightAnchor.constraint(equalToConstant: 40).isActive = true
        btn.addAction(UIAction { [weak self] _ in
            self?.fire(endpoint: endpoint, label: label)
        }, for: .touchUpInside)
        return btn
    }

    private func makeActionButton(title: String, action: Selector) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.cornerStyle = .medium
        let b = UIButton(configuration: config)
        b.addTarget(self, action: action, for: .touchUpInside)
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return b
    }

    private func fire(endpoint: HTTPBinEndpoint, label: String) {
        activityIndicator.startAnimating()
        Task { @MainActor in
            let result = await networkSimulator.fire(endpoint)
            self.results.insert((label, result), at: 0)
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
        }
    }

    @objc private func fireParallel() {
        activityIndicator.startAnimating()
        let endpoints: [HTTPBinEndpoint] = [
            .get, .get, .delay(1), .status(404),
            .get, .status(500), .delay(2), .get,
            .invalidDomain, .get
        ]
        Task { @MainActor in
            let res = await networkSimulator.fireParallel(endpoints)
            for (i, r) in res.enumerated() {
                self.results.insert(("Parallel [\(i)]", r), at: 0)
            }
            self.tableView.reloadData()
            self.activityIndicator.stopAnimating()
        }
    }

    @objc private func clearResults() {
        results.removeAll()
        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource

extension NetworkPlaygroundVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { results.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NetworkResultCell.reuseID, for: indexPath) as! NetworkResultCell
        let (label, result) = results[indexPath.row]
        cell.configure(label: label, result: result)
        return cell
    }
}

// MARK: - NetworkResultCell

final class NetworkResultCell: UITableViewCell {
    static let reuseID = "NetworkResultCell"

    private let endpointLabel = UILabel()
    private let resultLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        endpointLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        endpointLabel.textColor = .label
        resultLabel.font = .monospacedSystemFont(ofSize: 13, weight: .semibold)

        let stack = UIStackView(arrangedSubviews: [endpointLabel, UIView(), resultLabel])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(label: String, result: NetworkResult) {
        endpointLabel.text = label
        resultLabel.text = result.displayString
        switch result {
        case .success: resultLabel.textColor = .systemGreen
        case .timeout, .dnsError: resultLabel.textColor = .systemOrange
        default: resultLabel.textColor = .systemRed
        }
    }
}

#endif