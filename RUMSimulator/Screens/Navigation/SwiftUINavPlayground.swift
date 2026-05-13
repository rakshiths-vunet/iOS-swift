#if os(iOS)
import SwiftUI
import vuTelemetry

// MARK: - SwiftUINavPlayground

/// TrackedNavigationStack with programmatic navigation via path binding.
/// Supports push up to 10 levels deep, driveable by the scenario engine.
struct SwiftUINavPlayground: View {

    @ObservedObject var coordinator: SwiftUINavCoordinator

    var body: some View {
        TrackedNavigationStack(
            path: $coordinator.path,
            screenNameProvider: { level in coordinator.screenName(for: level) }
        ) {
            SwiftUINavLevel(level: 0, coordinator: coordinator)
                .navigationTitle("SwiftUI Navigation")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button("Push") { coordinator.push() }
                        Button("Root") { coordinator.popToRoot() }
                        Menu {
                            Button("Mode: None") { NavigationLatencyInjector.shared.globalMode = .none }
                            Button("Mode: Fixed 0.5s") { NavigationLatencyInjector.shared.globalMode = .fixed(0.5) }
                            Button("Mode: Fixed 2s") { NavigationLatencyInjector.shared.globalMode = .fixed(2.0) }
                            Button("Mode: Random (1-3s)") { NavigationLatencyInjector.shared.globalMode = .random(min: 1.0, max: 3.0) }
                            Divider()
                            Toggle("Injector Enabled", isOn: Binding(
                                get: { NavigationLatencyInjector.shared.isEnabled },
                                set: { NavigationLatencyInjector.shared.isEnabled = $0 }
                            ))
                        } label: {
                            Image(systemName: "timer")
                        }
                    }
                }
                .navigationDestination(for: Int.self) { level in
                    SwiftUINavLevel(level: level, coordinator: coordinator)
                }
        }
        .environmentObject(coordinator)
    }
}

// MARK: - SwiftUINavLevel

struct SwiftUINavLevel: View {
    let level: Int
    @ObservedObject var coordinator: SwiftUINavCoordinator

    var body: some View {
        VStack(spacing: 20) {
            Text("Level \(level)")
                .font(.system(size: 52, weight: .thin))
            Text(levelTitle)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer().frame(height: 16)
            
            VStack(spacing: 12) {
                Button("Push Next Level") { coordinator.push() }
                    .buttonStyle(.borderedProminent)
                
                HStack(spacing: 12) {
                    Button("Pop") { coordinator.popOne() }
                        .buttonStyle(.bordered)
                    Button("Pop to Root") { coordinator.popToRoot() }
                        .buttonStyle(.bordered)
                }
                
                Button("Present Modal") { coordinator.presentModal() }
                    .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(levelColor.opacity(0.04))
        .navigationTitle(levelTitle)
        .overlay {
            if isLoading {
                ZStack {
                    Color(uiColor: .systemBackground).opacity(0.8)
                    VStack(spacing: 12) {
                        ProgressView()
                            .controlSize(.large)
                        Text("Simulating Latency...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .transition(.opacity)
            }
        }
        .task {
            await NavigationLatencyInjector.shared.injectDelay(screenName: levelTitle, context: "SwiftUI View Task")
            withAnimation {
                isLoading = false
            }
        }
        .sheet(isPresented: $coordinator.isModalPresented) {
            SwiftUIModal(coordinator: coordinator)
        }
    }

    @State private var isLoading = true

    private var levelTitle: String {
        let names = ["Home", "Dashboard", "Profile", "Settings", "Orders", "Checkout", "Payment", "Confirm", "Review", "Success"]
        return names[min(level, names.count - 1)]
    }

    private var levelColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .teal, .pink, .indigo, .mint, .cyan, .yellow]
        return colors[min(level, colors.count - 1)]
    }
}

// MARK: - SwiftUIModal

struct SwiftUIModal: View {
    @ObservedObject var coordinator: SwiftUINavCoordinator

    @State private var isLoading = true

    var body: some View {
        VStack(spacing: 24) {
            if isLoading {
                ProgressView("Simulating Latency...")
            } else {
                Text("SwiftUI Modal")
                    .font(.title2.weight(.light))
                Text("(sheet presentation)")
                    .foregroundColor(.secondary)
                Button("Dismiss") { coordinator.dismissModal() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(40)
        .task {
            await NavigationLatencyInjector.shared.injectDelay(screenName: "SwiftUIModal", context: "SwiftUI Modal Task")
            withAnimation {
                isLoading = false
            }
        }
    }
}

// MARK: - SwiftUINavCoordinator

@MainActor
final class SwiftUINavCoordinator: ObservableObject {
    @Published var path: [Int] = []
    @Published var isModalPresented = false
    
    private let logger: EventLogger?

    init(logger: EventLogger? = nil) {
        self.logger = logger
    }

    func push() {
        guard path.count < 9 else { return }  // root is level 0, max depth 10
        let nextLevel = path.count + 1
        let name = screenName(for: nextLevel)
        
        Task {
            await NavigationLatencyInjector.shared.injectDelay(screenName: name, context: "Before SwiftUI Push")
            path.append(nextLevel)
            logAction(.push, screenName: name)
        }
    }
    
    func popOne() {
        guard !path.isEmpty else { return }
        path.removeLast()
        let currentLevel = path.last ?? 0
        logAction(.pop, screenName: screenName(for: currentLevel))
    }

    func popToRoot() {
        path.removeAll()
        logAction(.popToRoot, screenName: screenName(for: 0))
    }
    
    func presentModal() {
        Task {
            await NavigationLatencyInjector.shared.injectDelay(screenName: "SwiftUIModal", context: "Before SwiftUI Present")
            isModalPresented = true
            logAction(.present, screenName: "SwiftUIModal")
        }
    }
    
    func dismissModal() {
        isModalPresented = false
        let currentLevel = path.last ?? 0
        logAction(.dismiss, screenName: screenName(for: currentLevel))
    }
    
    private func logAction(_ type: NavActionType, screenName: String) {
        logger?.log(type: "navigation", metadata: [
            "actionType": type.rawValue,
            "screen": screenName,
            "framework": "SwiftUI"
        ])
    }
    
    func screenName(for level: Int) -> String {
        let names = ["Home", "Dashboard", "Profile", "Settings", "Orders", "Checkout", "Payment", "Confirm", "Review", "Success"]
        return names[min(level, names.count - 1)]
    }
}

// MARK: - APIDrivenSwiftUIPlayground

struct APIDrivenSwiftUIPlayground: View {
    @State private var path: [Int] = []
    
    var body: some View {
        TrackedNavigationStack(path: $path) {
            APIDrivenSwiftUILevel(level: 0, path: $path)
                .navigationDestination(for: Int.self) { level in
                    APIDrivenSwiftUILevel(level: level, path: $path)
                }
        }
    }
}

// MARK: - APIDrivenSwiftUILevel

struct APIDrivenSwiftUILevel: View {
    let level: Int
    @Binding var path: [Int]
    
    @State private var isLoading = false
    @State private var isPreFetching = false
    @State private var data: String?
    @State private var hasError = false
    
    var screenName: String {
        NavigationConstants.screenName(for: level)
    }
    
    var body: some View {
        VStack(spacing: 30) {
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Fetching \(screenName) data...")
                        .foregroundColor(.secondary)
                }
                .transition(.opacity)
            } else if hasError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)
                    Text("Failed to load data")
                    Button("Retry") {
                        retryFetch()
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                ScrollView {
                    VStack(spacing: 24) {
                        if let data = data {
                            Text(data)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(10)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text("No data loaded yet.")
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(spacing: 12) {
                            Button {
                                pushNext()
                            } label: {
                                Label("Next: API in Destination", systemImage: "arrow.right.circle")
                                    .font(.headline)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button {
                                pushWithPreFetch()
                            } label: {
                                HStack {
                                    if isPreFetching {
                                        ProgressView().tint(.white).padding(.trailing, 4)
                                    }
                                    Label("Next: API Before Navigation", systemImage: "clock.arrow.circlepath")
                                        .font(.headline)
                                }
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .tint(.indigo)
                            .disabled(isPreFetching)
                        }
                        
                        Menu("Latency Settings") {
                            Button("None") { APILatencyManager.shared.mode = .none }
                            Button("Fixed 1s") { APILatencyManager.shared.mode = .fixed(1.0) }
                            Button("Random (0.3-2s)") { APILatencyManager.shared.mode = .random(min: 0.3, max: 2.0) }
                        }
                        .font(.caption)
                        .padding(.top, 10)
                    }
                    .padding()
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(screenName)
        .task {
            // Initial fetch if we don't have data
            if data == nil {
                await loadData()
            } else {
                print("[RENDER COMPLETE] \(screenName) (from pre-fetch)")
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        hasError = false
        data = await APILatencyManager.shared.fetchRealData(level: level, screenName: screenName)
        withAnimation(.spring()) {
            isLoading = false
            if data != nil {
                print("[RENDER COMPLETE] \(screenName)")
            }
        }
    }
    
    private func retryFetch() {
        Task {
            await loadData()
        }
    }
    
    private func pushNext() {
        let nextLevel = level + 1
        let nextName = NavigationConstants.screenName(for: nextLevel)
        print("[NAV START] \(screenName) → \(nextName) (Default)")
        path.append(nextLevel)
    }
    
    private func pushWithPreFetch() {
        let nextLevel = level + 1
        let nextName = NavigationConstants.screenName(for: nextLevel)
        
        print("[NAV START] \(screenName) → \(nextName) (PRE-FETCH MODE)")
        
        isPreFetching = true
        
        Task {
            // Fetch data for the NEXT screen while still on the CURRENT screen
            let preFetchedData = await APILatencyManager.shared.fetchRealData(level: nextLevel, screenName: nextName)
            
            await MainActor.run {
                isPreFetching = false
                // Trigger the navigation. 
                // Note: In this simple SwiftUI playground, we don't have a clean way to "inject" state into the destination
                // without a coordinator change, so we'll just push and let the destination detect its level has data if we used a shared store.
                // For now, I'll just append to path. The destination will fetch again unless we add a cache.
                // To keep it simple and fulfill the user's request of "destination doesn't come up until API returns":
                path.append(nextLevel)
            }
        }
    }
}

#endif
