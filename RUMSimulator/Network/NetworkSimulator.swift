#if os(iOS)
import Foundation

// MARK: - NetworkSimulator

/// URLSession wrapper that applies debug panel overrides.
/// All requests MUST go through URLSession.shared — no third-party networking.
final class NetworkSimulator {

    private let debugState: DebugPanelViewModel
    private let logger: EventLogger?

    init(debugState: DebugPanelViewModel, logger: EventLogger? = nil) {
        self.debugState = debugState
        self.logger = logger
    }

    // MARK: - Single request

    func fire(_ endpoint: HTTPBinEndpoint) async -> NetworkResult {
        // Apply failure rate override BEFORE making the request
        if debugState.failureRate > 0 {
            let roll = Double.random(in: 0..<1)
            if roll < debugState.failureRate {
                let result = NetworkResult.clientError(statusCode: 0)
                logResult(endpoint: endpoint, result: result)
                return result
            }
        }

        // Build the effective endpoint (apply delay override if enabled)
        var effectiveEndpoint = endpoint
        if debugState.networkDelayEnabled {
            if case .get = endpoint {
                effectiveEndpoint = .delay(3)
            }
        }

        let result = await performRequest(url: effectiveEndpoint.url, displayName: endpoint.displayName)
        logResult(endpoint: endpoint, result: result)
        return result
    }

    // MARK: - Parallel requests

    func fireParallel(_ endpoints: [HTTPBinEndpoint]) async -> [NetworkResult] {
        await withTaskGroup(of: NetworkResult.self) { group in
            for endpoint in endpoints {
                group.addTask { await self.fire(endpoint) }
            }
            var results: [NetworkResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }

    // MARK: - Core URLSession call

    private func performRequest(url: URL, displayName: String) async -> NetworkResult {
        var request = URLRequest(url: url)
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .unknownError(NSError(domain: "RUMSimulator", code: -1, userInfo: [NSLocalizedDescriptionKey: "Non-HTTP response"]))
            }
            let code = http.statusCode
            switch code {
            case 200..<300: return .success(data: data, statusCode: code)
            case 400..<500: return .clientError(statusCode: code)
            case 500..<600: return .serverError(statusCode: code)
            default:        return .clientError(statusCode: code)
            }
        } catch let urlError as URLError {
            switch urlError.code {
            case .timedOut:                           return .timeout
            case .cannotFindHost, .dnsLookupFailed,
                 .cannotConnectToHost:                return .dnsError(urlError)
            default:                                  return .unknownError(urlError)
            }
        } catch {
            return .unknownError(error)
        }
    }

    // MARK: - Logging

    private func logResult(endpoint: HTTPBinEndpoint, result: NetworkResult) {
        logger?.log(
            type: "network",
            scenario: nil,
            step: nil,
            metadata: [
                "endpoint": endpoint.displayName,
                "result": result.displayString
            ]
        )
    }
}

#endif
