import Foundation

// MARK: - EventLogger

/// In-memory ring buffer (500 events) + async file write.
/// Does NOT block the caller. Thread-safe via serial queue.
final class EventLogger {

    // MARK: - In-memory buffer

    private(set) var events: [LogEvent] = []
    private let maxEvents = 500
    private let queue = DispatchQueue(label: "com.rumsimulator.eventlogger", qos: .utility)

    // MARK: - File manager

    private let fileManager = LogFileManager.shared
    private var flushTimer: Timer?

    // MARK: - Init

    init() {
        startFlushTimer()
    }

    // MARK: - Public API

    func log(type: String, scenario: String? = nil, step: Int? = nil, metadata: [String: String] = [:]) {
        let event = LogEvent(type: type, scenario: scenario, step: step, metadata: metadata)
        queue.async { [weak self] in
            guard let self = self else { return }
            self.events.append(event)
            if self.events.count > self.maxEvents {
                self.events.removeFirst(self.events.count - self.maxEvents)
            }
            self.fileManager.append(event: event)
        }
    }

    func clear() {
        queue.async { [weak self] in
            self?.events.removeAll()
            self?.fileManager.startNewFile()
        }
    }

    func flush() {
        queue.async { [weak self] in
            self?.fileManager.flush(events: self?.events ?? [])
        }
    }

    func exportURL() throws -> URL {
        return fileManager.currentFileURL
    }

    // MARK: - Flush timer (every 30 seconds)

    private func startFlushTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.flush()
        }
    }
}
