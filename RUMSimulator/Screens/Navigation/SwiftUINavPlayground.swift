#if os(iOS)
import SwiftUI

// MARK: - SwiftUINavPlayground

/// NavigationStack with programmatic navigation via path binding.
/// Supports push up to 10 levels deep, driveable by the scenario engine.
struct SwiftUINavPlayground: View {

    @StateObject private var coordinator = SwiftUINavCoordinator()

    var body: some View {
        NavigationStack(path: $coordinator.path) {
            SwiftUINavLevel(level: 0, coordinator: coordinator)
                .navigationTitle("SwiftUI Navigation")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        Button("Push") { coordinator.push() }
                        Button("Root") { coordinator.popToRoot() }
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
            Button("Push Next Level") { coordinator.push() }
                .buttonStyle(.borderedProminent)
            Button("Pop to Root") { coordinator.popToRoot() }
                .buttonStyle(.bordered)
            Button("Present Modal") { coordinator.isModalPresented = true }
                .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(levelColor.opacity(0.04))
        .navigationTitle("Level \(level)")
        .sheet(isPresented: $coordinator.isModalPresented) {
            SwiftUIModal()
        }
    }

    private var levelTitle: String {
        let letters = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J"]
        return "Screen \(level < letters.count ? letters[level] : "\(level)")"
    }

    private var levelColor: Color {
        let colors: [Color] = [.clear, .blue, .green, .orange, .purple, .teal]
        return colors[level % colors.count]
    }
}

// MARK: - SwiftUIModal

struct SwiftUIModal: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Text("Modal View")
                .font(.title2.weight(.light))
            Text("(sheet presentation)")
                .foregroundColor(.secondary)
            Button("Dismiss") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .padding(40)
    }
}

// MARK: - SwiftUINavCoordinator

@MainActor
final class SwiftUINavCoordinator: ObservableObject {
    @Published var path: [Int] = []
    @Published var isModalPresented = false

    func push() {
        guard path.count < 9 else { return }  // root is level 0, max depth 10
        path.append(path.count + 1)
    }

    func popToRoot() {
        path.removeAll()
    }
}

#endif
