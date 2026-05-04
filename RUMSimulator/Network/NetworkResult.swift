#if os(iOS)
import Foundation

// MARK: - NetworkResult

enum NetworkResult {
    case success(data: Data, statusCode: Int)
    case clientError(statusCode: Int)
    case serverError(statusCode: Int)
    case timeout
    case dnsError(Error)
    case unknownError(Error)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var displayString: String {
        switch self {
        case .success(_, let code): return "✓ \(code)"
        case .clientError(let code): return "✗ Client \(code)"
        case .serverError(let code): return "✗ Server \(code)"
        case .timeout:              return "✗ Timeout"
        case .dnsError(let e):      return "✗ DNS: \(e.localizedDescription)"
        case .unknownError(let e):  return "✗ Error: \(e.localizedDescription)"
        }
    }
}

#endif
