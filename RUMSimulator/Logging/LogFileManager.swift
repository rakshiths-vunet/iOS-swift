#if os(iOS)
import Foundation

// MARK: - LogFileManager

/// Per-scenario file rotation. JSON files saved to /Documents/rum_log_{scenarioId}_{ISO8601}.json
@MainActor
final class LogFileManager {

    static let shared = LogFileManager()

    private let encoder = JSONEncoder()
    private let queue = DispatchQueue(label: "com.rumsimulator.logfile", qos: .background)
    private var currentFileName: String = ""
    private(set) var currentFileURL: URL

    private var documentsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    // MARK: - Init

    private init() {
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        currentFileName = LogFileManager.generateFileName(scenarioId: "session")
        currentFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(currentFileName)
    }

    // MARK: - File management

    func startNewFile(scenarioId: String = "session") {
        currentFileName = LogFileManager.generateFileName(scenarioId: scenarioId)
        currentFileURL = documentsDir.appendingPathComponent(currentFileName)
    }

    func append(event: LogEvent) {
        // Lightweight append: just accumulates; full flush is done on flush()
        // For simplicity, we write on flush rather than true append-per-event
    }

    func flush(events: [LogEvent]) {
        let url = currentFileURL
        queue.async { [weak self] in
            guard let self = self else { return }
            do {
                let data = try self.encoder.encode(events)
                try data.write(to: url, options: .atomic)
            } catch {
                print("[LogFileManager] Write error: \(error)")
            }
        }
    }

    // MARK: - Helpers

    private static func generateFileName(scenarioId: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withColonSeparatorInTime]
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        return "rum_log_\(scenarioId)_\(timestamp).json"
    }

    func allLogFiles() -> [URL] {
        let dir = documentsDir
        let files = (try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.lastPathComponent.hasPrefix("rum_log_") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
    }
}

#endif
