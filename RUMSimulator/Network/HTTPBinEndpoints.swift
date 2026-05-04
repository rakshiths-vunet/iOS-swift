import Foundation

// MARK: - HTTPBinEndpoint

enum HTTPBinEndpoint {
    /// GET https://httpbin.org/get  — fast success
    case get
    /// GET https://httpbin.org/delay/{n}  — artificial delay
    case delay(Int)
    /// GET https://httpbin.org/status/{code}  — specified HTTP status
    case status(Int)
    /// DNS resolution failure (intentionally invalid domain)
    case invalidDomain

    var url: URL {
        switch self {
        case .get:
            return URL(string: "https://httpbin.org/get")!
        case .delay(let n):
            return URL(string: "https://httpbin.org/delay/\(n)")!
        case .status(let code):
            return URL(string: "https://httpbin.org/status/\(code)")!
        case .invalidDomain:
            return URL(string: "https://invalid.rumsimulator-does-not-exist.xyz/test")!
        }
    }

    var displayName: String {
        switch self {
        case .get:              return "GET /get"
        case .delay(let n):     return "GET /delay/\(n)"
        case .status(let code): return "GET /status/\(code)"
        case .invalidDomain:    return "GET invalidDomain (DNS fail)"
        }
    }
}
