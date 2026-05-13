#if os(iOS)
import SwiftUI
import vuTelemetry

// MARK: - BFSI SwiftUI Models

enum BFSIScreen: Hashable {
    case dashboard
    case cardsList
    case cardDetails(CreditCard)
    case payment(Double)
    case success
    
    var screenName: String {
        switch self {
        case .dashboard: return "BFSISwiftUI_Dashboard"
        case .cardsList: return "BFSISwiftUI_CardsList"
        case .cardDetails: return "BFSISwiftUI_CardDetails"
        case .payment: return "BFSISwiftUI_Payment"
        case .success: return "BFSISwiftUI_Success"
        }
    }
}

// MARK: - BFSI SwiftUI Playground

struct BFSISwiftUIPlayground: View {
    @StateObject private var coordinator = BFSISwiftUICoordinator()
    
    var body: some View {
        TrackedNavigationStack(path: $coordinator.path) {
            BFSISwiftUIDashboardView(coordinator: coordinator)
                .navigationDestination(for: BFSIScreen.self) { screen in
                    switch screen {
                    case .dashboard:
                        BFSISwiftUIDashboardView(coordinator: coordinator)
                    case .cardsList:
                        BFSISwiftUICardsListView(coordinator: coordinator)
                    case .cardDetails(let card):
                        BFSISwiftUICardDetailsView(coordinator: coordinator, card: card)
                    case .payment(let amount):
                        BFSISwiftUIPaymentView(coordinator: coordinator, amount: amount)
                    case .success:
                        BFSISwiftUISuccessView(coordinator: coordinator)
                    }
                }
        }
    }
}

// MARK: - Coordinator

@MainActor
final class BFSISwiftUICoordinator: ObservableObject {
    @Published var path: [BFSIScreen] = []
    
    func navigate(to screen: BFSIScreen) {
        path.append(screen)
    }
    
    func popToRoot() {
        path.removeAll()
    }
}

// MARK: - Dashboard View

struct BFSISwiftUIDashboardView: View {
    @ObservedObject var coordinator: BFSISwiftUICoordinator
    
    var body: some View {
        ZStack {
            ThemeView()
            
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Good Morning,\nAlex")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 24)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Total Balance")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text("$42,500.80")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 24)
                
                Button {
                    // TRIGGER: During Transition
                    // Start API call BEFORE appending to path
                    Task {
                        // Simulate API start
                        _ = try? await URLSession.shared.data(from: URL(string: "https://jsonplaceholder.typicode.com/users")!)
                    }
                    coordinator.navigate(to: .cardsList)
                } label: {
                    HStack {
                        Image(systemName: "creditcard.fill")
                        Text("My Credit Cards")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                TimingLabel(text: "Next API Triggered in Button Action (During Transition)")
            }
            .padding(.top, 40)
        }
        .navigationTitle("Dashboard")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Cards List View

struct BFSISwiftUICardsListView: View {
    @ObservedObject var coordinator: BFSISwiftUICoordinator
    @State private var cards: [CreditCard] = []
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            ThemeView()
            
            VStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(cards, id: \.id) { card in
                                CardRow(card: card) {
                                    // TRIGGER: Post Transition
                                    // Just navigate, let destination .task handle it
                                    coordinator.navigate(to: .cardDetails(card))
                                }
                            }
                        }
                        .padding(24)
                    }
                }
                
                TimingLabel(text: "API Triggered in .task (During Transition Transition - Parallel)")
            }
        }
        .navigationTitle("My Cards")
        .task {
            await fetchCards()
        }
    }
    
    private func fetchCards() async {
        isLoading = true
        let url = URL(string: "https://jsonplaceholder.typicode.com/users")!
        do {
            let _ = try? await URLSession.shared.data(from: url)
            cards = [
                CreditCard(id: "1", bankName: "HDFC BANK", cardNumber: "**** **** **** 4432", balance: 2500.0, creditLimit: 10000.0, color: Theme.Colors.cardBlue),
                CreditCard(id: "2", bankName: "ICICI BANK", cardNumber: "**** **** **** 8821", balance: 1200.0, creditLimit: 5000.0, color: Theme.Colors.cardGold),
                CreditCard(id: "3", bankName: "SBI BANK", cardNumber: "**** **** **** 1092", balance: 450.0, creditLimit: 2000.0, color: Theme.Colors.cardSilver)
            ]
        }
        isLoading = false
    }
}

// MARK: - Card Details View

struct BFSISwiftUICardDetailsView: View {
    @ObservedObject var coordinator: BFSISwiftUICoordinator
    let card: CreditCard
    @State private var amount: String = ""
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            ThemeView()
            
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Outstanding Balance")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    
                    if isLoading {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 150, height: 38)
                    } else {
                        Text(String(format: "$%.2f", card.balance))
                            .font(.system(size: 38, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(24)
                .padding(.horizontal, 24)
                
                if isLoading {
                    VStack(spacing: 12) {
                        ForEach(0..<3) { _ in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 60)
                        }
                    }
                    .padding(.horizontal, 24)
                } else {
                    List {
                        TransactionRow(title: "Amazon.com", amount: -45.50, date: "May 5")
                        TransactionRow(title: "Starbucks", amount: -5.20, date: "May 4")
                        TransactionRow(title: "Netflix", amount: -15.99, date: "May 1")
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                
                Spacer()
                
                Button {
                    // TRIGGER: During Transition
                    Task {
                        _ = try? await URLSession.shared.data(from: URL(string: "https://dummyjson.com/users/1")!)
                    }
                    coordinator.navigate(to: .payment(card.balance))
                } label: {
                    Text("Pay Bill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isLoading ? Color.gray : Color.green)
                        .cornerRadius(16)
                }
                .disabled(isLoading)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                TimingLabel(text: "API Triggered in .onAppear (Post Transition)")
            }
            .padding(.top, 20)
        }
        .navigationTitle("Details")
        .onAppear {
            Task {
                // Simulate Post-Transition Fetch
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                let url = URL(string: "https://dummyjson.com/carts/1")!
                _ = try? await URLSession.shared.data(from: url)
                withAnimation {
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Payment View

struct BFSISwiftUIPaymentView: View {
    @ObservedObject var coordinator: BFSISwiftUICoordinator
    let amount: Double
    @State private var isProcessing = false
    
    var body: some View {
        ZStack {
            ThemeView()
            
            VStack(spacing: 40) {
                VStack(spacing: 12) {
                    Text("Payment Amount")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                    
                    Text(String(format: "$%.2f", amount))
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    PaymentMethodRow(name: "Linked Bank Account", icon: "building.columns.fill")
                    PaymentMethodRow(name: "UPI / GPay", icon: "iphone.circle")
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button {
                    processPayment()
                } label: {
                    if isProcessing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Confirm Payment")
                            .font(.headline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(16)
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .disabled(isProcessing)
                
                TimingLabel(text: "API Triggered in viewDidLoad Equivalent (During Transition Transition)")
            }
        }
        .navigationTitle("Payment")
    }
    
    private func processPayment() {
        isProcessing = true
        Task {
            let url = URL(string: "https://dummyjson.com/http/200")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            _ = try? await URLSession.shared.data(for: request)
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isProcessing = false
                coordinator.navigate(to: .success)
            }
        }
    }
}

// MARK: - Success View

struct BFSISwiftUISuccessView: View {
    @ObservedObject var coordinator: BFSISwiftUICoordinator
    
    var body: some View {
        ZStack {
            Color.green.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.white)
                
                Text("Payment Successful")
                    .font(.title.bold())
                    .foregroundColor(.white)
                
                Button {
                    coordinator.popToRoot()
                } label: {
                    Text("Back to Dashboard")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .overlay(Capsule().stroke(Color.white, lineWidth: 2))
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Supporting Views

struct ThemeView: View {
    var body: some View {
        LinearGradient(colors: [Color(red: 0.05, green: 0.07, blue: 0.12), Color(red: 0.12, green: 0.15, blue: 0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
    }
}

struct CardRow: View {
    let card: CreditCard
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 20) {
                Text(card.bankName)
                    .font(.headline)
                Spacer()
                Text(card.cardNumber)
                    .font(.system(.body, design: .monospaced))
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .background(Color(card.color))
            .cornerRadius(16)
            .foregroundColor(.white)
        }
    }
}

struct TransactionRow: View {
    let title: String
    let amount: Double
    let date: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Text(String(format: "%.2f", amount))
                .font(.headline)
                .foregroundColor(amount < 0 ? .red : .green)
        }
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
    }
}

struct PaymentMethodRow: View {
    let name: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(name)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "circle")
                .foregroundColor(.white.opacity(0.3))
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct TimingLabel: View {
    let text: String
    var body: some View {
        Text("⏱ \(text)")
            .font(.system(size: 10, weight: .semibold, design: .monospaced))
            .foregroundColor(.white.opacity(0.4))
            .padding(.bottom, 10)
    }
}

#endif
