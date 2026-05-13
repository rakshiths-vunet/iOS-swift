#if os(iOS)
import UIKit
import Alamofire

// MARK: - NetworkLogEntry

struct NetworkLogEntry {
    let method: String
    let url: String
    let status: Int
    let duration: TimeInterval
    let requestSize: Int64
    let responseSize: Int64
    let timestamp: Date = Date()
}

// MARK: - AlamofirePlaygroundVC

final class AlamofirePlaygroundVC: UIViewController {

    // MARK: - Dependencies
    private let session = Session(interceptor: AlamofireHeaderInterceptor(), eventMonitors: [AlamofireHeaderMonitor()])

    // MARK: - State
    private var logs: [NetworkLogEntry] = []

    // MARK: - UI Components
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.register(AlamofireLogCell.self, forCellReuseIdentifier: AlamofireLogCell.reuseID)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = 100
        tv.dataSource = self
        return tv
    }()

    private lazy var buttonStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        stack.isLayoutMarginsRelativeArrangement = true
        return stack
    }()

    private lazy var activityIndicator: UIActivityIndicatorView = {
        let ai = UIActivityIndicatorView(style: .medium)
        ai.translatesAutoresizingMaskIntoConstraints = false
        ai.hidesWhenStopped = true
        return ai
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        title = "Alamofire Playground"
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearLogs))

        view.addSubview(buttonStack)
        view.addSubview(tableView)
        view.addSubview(activityIndicator)

        NSLayoutConstraint.activate([
            buttonStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            tableView.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        setupButtons()
    }

    private func setupButtons() {
        let endpoints: [HTTPBinEndpoint] = [.get, .delay(2), .status(404), .status(500), .invalidDomain]
        
        for endpoint in endpoints {
            let btn = makeButton(for: endpoint)
            buttonStack.addArrangedSubview(btn)
        }
    }

    private func makeButton(for endpoint: HTTPBinEndpoint) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = endpoint.displayName
        config.cornerStyle = .medium
        
        let btn = UIButton(configuration: config)
        btn.addAction(UIAction { [weak self] _ in
            self?.fireRequest(endpoint)
        }, for: .touchUpInside)
        return btn
    }

    // MARK: - Actions
    @objc private func clearLogs() {
        logs.removeAll()
        tableView.reloadData()
    }

    private func fireRequest(_ endpoint: HTTPBinEndpoint) {
        activityIndicator.startAnimating()
        
        let startTime = Date()
        
        session.request(endpoint.url).responseData { [weak self] response in
            guard let self = self else { return }
            self.activityIndicator.stopAnimating()
            
            let duration = Date().timeIntervalSince(startTime)
            let status = response.response?.statusCode ?? 0
            let method = response.request?.method?.rawValue ?? "GET"
            let url = response.request?.url?.absoluteString ?? endpoint.url.absoluteString
            
            // Estimate sizes
            let requestSize = Int64(response.request?.allHTTPHeaderFields?.description.count ?? 0) + (response.request?.httpBody?.count.toInt64 ?? 0)
            let responseSize = Int64(response.response?.allHeaderFields.description.count ?? 0) + (response.data?.count.toInt64 ?? 0)
            
            let entry = NetworkLogEntry(
                method: method,
                url: url,
                status: status,
                duration: duration,
                requestSize: requestSize,
                responseSize: responseSize
            )
            
            self.logs.insert(entry, at: 0)
            self.tableView.reloadData()
        }
    }
}

// MARK: - UITableViewDataSource
extension AlamofirePlaygroundVC: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AlamofireLogCell.reuseID, for: indexPath) as! AlamofireLogCell
        cell.configure(with: logs[indexPath.row])
        return cell
    }
}

// MARK: - AlamofireLogCell
final class AlamofireLogCell: UITableViewCell {
    static let reuseID = "AlamofireLogCell"
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(infoLabel)
        NSLayoutConstraint.activate([
            infoLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            infoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with entry: NetworkLogEntry) {
        let statusColor = entry.status >= 200 && entry.status < 300 ? "🟢" : "🔴"
        let sizeFormatter = ByteCountFormatter()
        sizeFormatter.allowedUnits = [.useAll]
        sizeFormatter.countStyle = .file
        
        let reqSizeStr = sizeFormatter.string(fromByteCount: entry.requestSize)
        let resSizeStr = sizeFormatter.string(fromByteCount: entry.responseSize)
        
        infoLabel.text = """
        \(statusColor) [\(entry.status)] \(entry.method)
        URL: \(entry.url)
        Duration: \(String(format: "%.3f", entry.duration))s
        Req Size: \(reqSizeStr)
        Resp Size: \(resSizeStr)
        """
        
        if entry.status == 0 {
            infoLabel.textColor = .systemOrange
        } else if entry.status >= 200 && entry.status < 300 {
            infoLabel.textColor = .label
        } else {
            infoLabel.textColor = .systemRed
        }
    }
}

// MARK: - Helpers
extension Int {
    var toInt64: Int64 { Int64(self) }
}

#endif
