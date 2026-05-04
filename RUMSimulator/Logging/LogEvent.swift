import Foundation

// MARK: - LogEvent

struct LogEvent: Codable, Identifiable {
    let id: UUID
    let timestamp: Date
    let type: String          // "navigation" | "tap" | "network" | "lifecycle" | "crash" | "step"
    let scenario: String?     // active scenario name, if any
    let step: Int?            // step index within scenario
    let metadata: [String: String]

    init(type: String, scenario: String? = nil, step: Int? = nil, metadata: [String: String] = [:]) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.scenario = scenario
        self.step = step
        self.metadata = metadata
    }

    // MARK: - Display

    var typeIcon: String {
        switch type {
        case "navigation":    return "🗺"
        case "tap":           return "👆"
        case "network":       return "🌐"
        case "lifecycle":     return "♻️"
        case "crash":         return "💥"
        case "step":          return "▶️"
        case "load_complete": return "⚡"
        default:              return "•"
        }
    }

    var summary: String {
        if let label = metadata["label"] { return label }
        if let endpoint = metadata["endpoint"] { return endpoint }
        if let action = metadata["action"] { return action }
        return type
    }
}
