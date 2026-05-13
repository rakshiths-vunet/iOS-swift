#if os(iOS)
import UIKit

// MARK: - BFSI Models

struct CreditCard: Hashable {
    let id: String
    let bankName: String
    let cardNumber: String
    let balance: Double
    let creditLimit: Double
    let color: UIColor

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CreditCard, rhs: CreditCard) -> Bool {
        lhs.id == rhs.id
    }
}

struct Transaction {
    let title: String
    let amount: Double
    let date: String
    let category: String
}

// MARK: - BFSI Theme Extension

extension Theme.Colors {
    static let cardGold = UIColor(red: 0.83, green: 0.69, blue: 0.22, alpha: 1.0)
    static let cardSilver = UIColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 1.0)
    static let cardBlue = UIColor(red: 0.15, green: 0.35, blue: 0.85, alpha: 1.0)
}

// MARK: - Skeleton View

class SkeletonView: UIView {
    private let gradientLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor.white.withAlphaComponent(0.05)
        layer.cornerRadius = 8
        clipsToBounds = true
        
        gradientLayer.colors = [
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(0.1).cgColor,
            UIColor.clear.cgColor
        ]
        gradientLayer.locations = [0, 0.5, 1]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradientLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        startAnimation()
    }
    
    private func startAnimation() {
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = -bounds.width
        animation.toValue = bounds.width
        animation.duration = 1.5
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "skeleton")
    }
}

// MARK: - Dashboard

final class BFSIDashboardViewController: UIViewController {
    
    private let welcomeLabel: UILabel = {
        let l = UILabel()
        l.text = "Good Morning,\nAlex"
        l.font = .systemFont(ofSize: 28, weight: .bold)
        l.textColor = .white
        l.numberOfLines = 0
        return l
    }()
    
    private let balanceCard: UIView = {
        let v = UIView()
        v.layer.cornerRadius = 24
        v.backgroundColor = .white.withAlphaComponent(0.1)
        return v
    }()
    
    private let cardsButton: UIButton = {
        var config = Theme.premiumButtonConfig(title: "My Credit Cards", systemImage: "creditcard.fill", color: Theme.Colors.primary)
        let b = UIButton(configuration: config)
        return b
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        title = "Dashboard"
        view.backgroundColor = Theme.Colors.backgroundStart
        Theme.addGradientBackground(to: view)
        
        [welcomeLabel, balanceCard, cardsButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        Theme.applyGlassEffect(to: balanceCard)
        
        let balanceTitle = UILabel()
        balanceTitle.text = "Total Balance"
        balanceTitle.font = .systemFont(ofSize: 14, weight: .medium)
        balanceTitle.textColor = .white.withAlphaComponent(0.6)
        
        let balanceAmount = UILabel()
        balanceAmount.text = "$42,500.80"
        balanceAmount.font = .systemFont(ofSize: 34, weight: .bold)
        balanceAmount.textColor = .white
        
        [balanceTitle, balanceAmount].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            balanceCard.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            
            balanceCard.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 32),
            balanceCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            balanceCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            balanceCard.heightAnchor.constraint(equalToConstant: 160),
            
            balanceTitle.topAnchor.constraint(equalTo: balanceCard.topAnchor, constant: 24),
            balanceTitle.leadingAnchor.constraint(equalTo: balanceCard.leadingAnchor, constant: 24),
            
            balanceAmount.topAnchor.constraint(equalTo: balanceTitle.bottomAnchor, constant: 8),
            balanceAmount.leadingAnchor.constraint(equalTo: balanceCard.leadingAnchor, constant: 24),
            
            cardsButton.topAnchor.constraint(equalTo: balanceCard.bottomAnchor, constant: 40),
            cardsButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            cardsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            cardsButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        cardsButton.addTarget(self, action: #selector(didTapCards), for: .touchUpInside)
    }
    
    @objc private func didTapCards() {
        // Log instrumentation point if needed (handled by RUM)
        let vc = BFSICardsListViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Cards List

final class BFSICardsListViewController: UIViewController {
    
    private let tableView = UITableView()
    private var cards: [CreditCard] = []
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchCards()
    }
    
    private func setupUI() {
        title = "My Cards"
        view.backgroundColor = Theme.Colors.backgroundStart
        Theme.addGradientBackground(to: view)
        
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BFSICardCell.self, forCellReuseIdentifier: "CardCell")
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.color = .white
        view.addSubview(loadingIndicator)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        addTimingLabel(text: "API Triggered in viewDidLoad (During Transition)")
    }
    
    private func addTimingLabel(text: String) {
        let l = UILabel()
        l.text = "⏱ \(text)"
        l.font = .monospacedSystemFont(ofSize: 10, weight: .semibold)
        l.textColor = .white.withAlphaComponent(0.4)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(l)
        NSLayoutConstraint.activate([
            l.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
            l.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            l.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func fetchCards() {
        loadingIndicator.startAnimating()
        Task {
            // Simulate "fetch customer cards"
            let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                // Use data to simulate cards
                await MainActor.run {
                    self.loadingIndicator.stopAnimating()
                    self.cards = [
                        CreditCard(id: "1", bankName: "HDFC BANK", cardNumber: "**** **** **** 4432", balance: 2500.0, creditLimit: 10000.0, color: Theme.Colors.cardBlue),
                        CreditCard(id: "2", bankName: "ICICI BANK", cardNumber: "**** **** **** 8821", balance: 1200.0, creditLimit: 5000.0, color: Theme.Colors.cardGold),
                        CreditCard(id: "3", bankName: "SBI BANK", cardNumber: "**** **** **** 1092", balance: 450.0, creditLimit: 2000.0, color: Theme.Colors.cardSilver)
                    ]
                    self.tableView.reloadData()
                }
            } catch {
                print("Error fetching cards: \(error)")
            }
        }
    }
}

extension BFSICardsListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { cards.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CardCell", for: indexPath) as! BFSICardCell
        cell.configure(with: cards[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let card = cards[indexPath.row]
        let vc = BFSICardDetailsViewController(card: card)
        navigationController?.pushViewController(vc, animated: true)
    }
}

class BFSICardCell: UITableViewCell {
    private let cardView = UIView()
    private let bankLabel = UILabel()
    private let numberLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        cardView.layer.cornerRadius = 16
        cardView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardView)
        
        bankLabel.font = .systemFont(ofSize: 18, weight: .bold)
        bankLabel.textColor = .white
        bankLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(bankLabel)
        
        numberLabel.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
        numberLabel.textColor = .white.withAlphaComponent(0.8)
        numberLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(numberLabel)
        
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            cardView.heightAnchor.constraint(equalToConstant: 120),
            
            bankLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 20),
            bankLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24),
            
            numberLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            numberLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 24)
        ])
    }
    
    func configure(with card: CreditCard) {
        bankLabel.text = card.bankName
        numberLabel.text = card.cardNumber
        cardView.backgroundColor = card.color
    }
}

// MARK: - Card Details

final class BFSICardDetailsViewController: UIViewController {
    
    private let card: CreditCard
    private var transactions: [Transaction] = []
    
    private let detailCard = UIView()
    private let duesLabel = UILabel()
    private let amountLabel = UILabel()
    private let payButton = UIButton()
    
    private let skeletonStack = UIStackView()
    private let transactionTableView = UITableView()
    
    init(card: CreditCard) {
        self.card = card
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchDetails()
    }
    
    private func setupUI() {
        title = "Card Details"
        view.backgroundColor = Theme.Colors.backgroundStart
        Theme.addGradientBackground(to: view)
        
        detailCard.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(detailCard)
        Theme.applyGlassEffect(to: detailCard)
        
        duesLabel.text = "Outstanding Balance"
        duesLabel.font = .systemFont(ofSize: 14, weight: .medium)
        duesLabel.textColor = .white.withAlphaComponent(0.6)
        
        amountLabel.text = "$ --.--" // Initial skeleton state
        amountLabel.font = .systemFont(ofSize: 34, weight: .bold)
        amountLabel.textColor = .white
        
        var payConfig = Theme.premiumButtonConfig(title: "Pay Bill", systemImage: "arrow.right", color: Theme.Colors.success)
        payButton.configuration = payConfig
        payButton.translatesAutoresizingMaskIntoConstraints = false
        payButton.isEnabled = false
        view.addSubview(payButton)
        
        [duesLabel, amountLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            detailCard.addSubview($0)
        }
        
        // Skeleton for transactions
        skeletonStack.axis = .vertical
        skeletonStack.spacing = 12
        skeletonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skeletonStack)
        
        for _ in 0..<3 {
            let s = SkeletonView()
            s.heightAnchor.constraint(equalToConstant: 60).isActive = true
            skeletonStack.addArrangedSubview(s)
        }
        
        transactionTableView.backgroundColor = .clear
        transactionTableView.separatorStyle = .singleLine
        transactionTableView.separatorColor = .white.withAlphaComponent(0.1)
        transactionTableView.isHidden = true
        transactionTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(transactionTableView)
        
        NSLayoutConstraint.activate([
            detailCard.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            detailCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            detailCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            detailCard.heightAnchor.constraint(equalToConstant: 140),
            
            duesLabel.topAnchor.constraint(equalTo: detailCard.topAnchor, constant: 24),
            duesLabel.leadingAnchor.constraint(equalTo: detailCard.leadingAnchor, constant: 24),
            
            amountLabel.topAnchor.constraint(equalTo: duesLabel.bottomAnchor, constant: 8),
            amountLabel.leadingAnchor.constraint(equalTo: detailCard.leadingAnchor, constant: 24),
            
            skeletonStack.topAnchor.constraint(equalTo: detailCard.bottomAnchor, constant: 32),
            skeletonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            skeletonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            transactionTableView.topAnchor.constraint(equalTo: detailCard.bottomAnchor, constant: 32),
            transactionTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            transactionTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            transactionTableView.bottomAnchor.constraint(equalTo: payButton.topAnchor, constant: -20),
            
            payButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            payButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            payButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            payButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        payButton.addTarget(self, action: #selector(didTapPay), for: .touchUpInside)
        addTimingLabel(text: "API Triggered in viewDidAppear (After Transition)")
    }
    
    private func addTimingLabel(text: String) {
        let l = UILabel()
        l.text = "⏱ \(text)"
        l.font = .monospacedSystemFont(ofSize: 10, weight: .semibold)
        l.textColor = .white.withAlphaComponent(0.4)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(l)
        NSLayoutConstraint.activate([
            l.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
            l.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            l.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func fetchDetails() {
        Task {
            // Simulate fetching dues and last transactions
            let url = URL(string: "https://dummyjson.com/carts/1")!
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                // Simulate delay
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                
                await MainActor.run {
                    self.amountLabel.text = String(format: "$%.2f", self.card.balance)
                    self.skeletonStack.isHidden = true
                    self.transactionTableView.isHidden = false
                    self.payButton.isEnabled = true
                    // Mock some transactions
                    self.transactions = [
                        Transaction(title: "Amazon.com", amount: -45.50, date: "May 5", category: "Shopping"),
                        Transaction(title: "Starbucks", amount: -5.20, date: "May 4", category: "Food"),
                        Transaction(title: "Netflix", amount: -15.99, date: "May 1", category: "Entertainment")
                    ]
                    self.transactionTableView.reloadData()
                }
            } catch {
                print("Error: \(error)")
            }
        }
    }
    
    @objc private func didTapPay() {
        let vc = BFSIPaymentViewController(amount: card.balance)
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - Payment Screen

final class BFSIPaymentViewController: UIViewController {
    
    private let amount: Double
    private let amountField = UITextField()
    private let methodStack = UIStackView()
    private let confirmButton = UIButton()
    private let loader = UIActivityIndicatorView(style: .large)
    
    init(amount: Double) {
        self.amount = amount
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchPaymentMethods()
    }
    
    private func setupUI() {
        title = "Make Payment"
        view.backgroundColor = Theme.Colors.backgroundStart
        Theme.addGradientBackground(to: view)
        
        let label = UILabel()
        label.text = "Payment Amount"
        label.textColor = .white.withAlphaComponent(0.6)
        label.font = .systemFont(ofSize: 14)
        
        amountField.text = String(format: "%.2f", amount)
        amountField.font = .systemFont(ofSize: 40, weight: .bold)
        amountField.textColor = .white
        amountField.keyboardType = .decimalPad
        amountField.textAlignment = .center
        
        methodStack.axis = .vertical
        methodStack.spacing = 12
        
        confirmButton.configuration = Theme.premiumButtonConfig(title: "Confirm Payment", systemImage: "checkmark.circle.fill", color: Theme.Colors.primary)
        
        [label, amountField, methodStack, confirmButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        loader.translatesAutoresizingMaskIntoConstraints = false
        loader.color = .white
        view.addSubview(loader)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            amountField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 12),
            amountField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            amountField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            methodStack.topAnchor.constraint(equalTo: amountField.bottomAnchor, constant: 60),
            methodStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            methodStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            confirmButton.heightAnchor.constraint(equalToConstant: 56),
            
            loader.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loader.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        confirmButton.addTarget(self, action: #selector(didTapConfirm), for: .touchUpInside)
        addTimingLabel(text: "API Triggered in viewDidLoad (During Transition)")
    }
    
    private func addTimingLabel(text: String) {
        let l = UILabel()
        l.text = "⏱ \(text)"
        l.font = .monospacedSystemFont(ofSize: 10, weight: .semibold)
        l.textColor = .white.withAlphaComponent(0.4)
        l.textAlignment = .center
        l.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(l)
        NSLayoutConstraint.activate([
            l.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -4),
            l.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            l.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func fetchPaymentMethods() {
        Task {
            // Simulate fetching payment methods
            let url = URL(string: "https://dummyjson.com/users/1")!
            do {
                let _ = try await URLSession.shared.data(from: url)
                await MainActor.run {
                    self.addMethod(name: "Linked Bank Account (.... 4492)", icon: "building.columns.fill")
                    self.addMethod(name: "UPI / GPay", icon: "iphone.circle")
                    self.addMethod(name: "Debit Card (.... 1102)", icon: "creditcard.fill")
                }
            } catch {}
        }
    }
    
    private func addMethod(name: String, icon: String) {
        let v = UIView()
        v.backgroundColor = .white.withAlphaComponent(0.05)
        v.layer.cornerRadius = 12
        v.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        let img = UIImageView(image: UIImage(systemName: icon))
        img.tintColor = Theme.Colors.primary
        img.contentMode = .scaleAspectFit
        
        let lbl = UILabel()
        lbl.text = name
        lbl.textColor = .white
        lbl.font = .systemFont(ofSize: 15, weight: .medium)
        
        [img, lbl].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            v.addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            img.leadingAnchor.constraint(equalTo: v.leadingAnchor, constant: 16),
            img.centerYAnchor.constraint(equalTo: v.centerYAnchor),
            img.widthAnchor.constraint(equalToConstant: 24),
            
            lbl.leadingAnchor.constraint(equalTo: img.trailingAnchor, constant: 16),
            lbl.centerYAnchor.constraint(equalTo: v.centerYAnchor)
        ])
        
        methodStack.addArrangedSubview(v)
    }
    
    @objc private func didTapConfirm() {
        confirmButton.isEnabled = false
        confirmButton.alpha = 0.5
        loader.startAnimating()
        
        Task {
            // Simulate POST payment call
            let url = URL(string: "https://dummyjson.com/http/200")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let body: [String: Any] = [
                "cardId": "HDFC-4432",
                "amount": amount,
                "paymentMethod": "UPI"
            ]
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            do {
                let _ = try await URLSession.shared.data(for: request)
                try? await Task.sleep(nanoseconds: 1_500_000_000) // Simulate processing
                
                await MainActor.run {
                    self.loader.stopAnimating()
                    let vc = BFSIPaymentSuccessViewController()
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.loader.stopAnimating()
                    self.confirmButton.isEnabled = true
                    self.confirmButton.alpha = 1.0
                }
            }
        }
    }
}

// MARK: - Success Screen

final class BFSIPaymentSuccessViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        navigationItem.hidesBackButton = true
        view.backgroundColor = Theme.Colors.success
        
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        let icon = UIImageView(image: UIImage(systemName: "checkmark.seal.fill"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.heightAnchor.constraint(equalToConstant: 100).isActive = true
        icon.widthAnchor.constraint(equalToConstant: 100).isActive = true
        
        let titleLabel = UILabel()
        titleLabel.text = "Payment Successful"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        
        let refLabel = UILabel()
        refLabel.text = "Ref: BFSI-\(Int.random(in: 100000...999999))"
        refLabel.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        refLabel.textColor = .white.withAlphaComponent(0.8)
        
        let backButton = UIButton(type: .system)
        backButton.setTitle("Back to Dashboard", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor.white.cgColor
        backButton.layer.cornerRadius = 28
        backButton.heightAnchor.constraint(equalToConstant: 56).isActive = true
        backButton.widthAnchor.constraint(equalToConstant: 240).isActive = true
        
        [icon, titleLabel, refLabel, backButton].forEach { stack.addArrangedSubview($0) }
        
        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        backButton.addTarget(self, action: #selector(didTapBack), for: .touchUpInside)
    }
    
    @objc private func didTapBack() {
        navigationController?.popToRootViewController(animated: true)
    }
}

#endif
