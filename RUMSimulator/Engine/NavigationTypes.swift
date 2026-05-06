#if os(iOS)
import Foundation

// MARK: - Navigation Action Types
enum NavActionType: String, Codable, CaseIterable {
    case push
    case pop
    case popToRoot
    case present
    case dismiss
    case tabSwitch
    case replace
    case unknown
}

// MARK: - Navigation Trigger Types
enum NavTriggerType: String, Codable, CaseIterable {
    case userGesture
    case userTap
    case programmatic
    case system
    case deepLink
    case notification
    case restored
    case unknown
}

// MARK: - Navigation Entry Types
enum NavEntryType: String, Codable, CaseIterable {
    case internalFlow
    case deepLink
    case external
    case notification
    case restored
    case unknown
}

struct NavMetadata {
    let actionType: NavActionType
    let triggerType: NavTriggerType
    let entryType: NavEntryType
    
    var dictionary: [String: String] {
        [
            "actionType": actionType.rawValue,
            "triggerType": triggerType.rawValue,
            "entryType": entryType.rawValue
        ]
    }
}

public struct NavigationConstants {
    public static let screenNames: [String] = [
        "Home", "Dashboard", "Profile", "Settings", "Order Details",
        "Checkout", "Payment", "Confirmation", "Review", "Done"
    ]
    
    public static func screenName(for level: Int) -> String {
        return screenNames[min(level, screenNames.count - 1)]
    }
}

// MARK: - Navigation Latency

public enum LatencyMode: Equatable {
    case none
    case fixed(TimeInterval)
    case random(min: TimeInterval, max: TimeInterval)
    
    public var delay: TimeInterval {
        switch self {
        case .none:
            return 0
        case .fixed(let interval):
            return interval
        case .random(let min, let max):
            return TimeInterval.random(in: min...max)
        }
    }
    
    public var description: String {
        switch self {
        case .none: return "None"
        case .fixed(let d): return "Fixed (\(String(format: "%.2f", d))s)"
        case .random(let min, let max): return "Random (\(String(format: "%.2f", min))-\(String(format: "%.2f", max))s)"
        }
    }
}

public class NavigationLatencyInjector {
    public static let shared = NavigationLatencyInjector()
    
    public var globalMode: LatencyMode = .none
    public var isEnabled: Bool = true
    
    private var screenOverrides: [String: LatencyMode] = [:]
    
    private init() {}
    
    public func setOverride(for screenName: String, mode: LatencyMode) {
        screenOverrides[screenName] = mode
    }
    
    public func clearOverrides() {
        screenOverrides.removeAll()
    }
    
    public func injectDelay(screenName: String? = nil, context: String) async {
        guard isEnabled else { return }
        
        let modeToUse: LatencyMode
        if let screenName = screenName, let override = screenOverrides[screenName] {
            modeToUse = override
        } else {
            modeToUse = globalMode
        }
        
        let delay = modeToUse.delay
        if delay > 0 {
            print("[NavigationLatencyInjector] ⏳ Injecting \(String(format: "%.3f", delay))s delay for [\(context)]\(screenName != nil ? " on \(screenName!)" : "")")
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            print("[NavigationLatencyInjector] ✅ Delay completed for [\(context)]")
        }
    }
}

// MARK: - API Latency

public enum APILatencyMode: Equatable {
    case none
    case fixed(TimeInterval)
    case random(min: TimeInterval, max: TimeInterval)
    
    public var delay: TimeInterval {
        switch self {
        case .none:
            return 0
        case .fixed(let interval):
            return interval
        case .random(let min, let max):
            return TimeInterval.random(in: min...max)
        }
    }
}

public class APILatencyManager {
    public static let shared = APILatencyManager()
    
    public var mode: APILatencyMode = .random(min: 0.3, max: 2.0)
    
    private init() {}

    private let apiMap: [Int: String] = [
        0: "https://jsonplaceholder.typicode.com/posts",
        1: "https://reqres.in/api/users?page=2",
        2: "https://fakestoreapi.com/products",
        3: "https://randomuser.me/api/",
        4: "https://restcountries.com/v3.1/name/canada",
        5: "http://universities.hipolabs.com/search?country=United+States",
        6: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd",
        7: "https://dog.ceo/api/breeds/image/random",
        8: "https://pokeapi.co/api/v2/pokemon/ditto",
        9: "https://official-joke-api.appspot.com/random_joke"
    ]
    
    public func fetchRealData(level: Int, screenName: String) async -> String {
        print("\n--- [API REQUEST] ---")
        print("[SCREEN] \(screenName)")
        
        // 1. Inject artificial latency if configured
        let delay = mode.delay
        if delay > 0 {
            print("[LATENCY] Injected \(String(format: "%.2f", delay))s")
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        
        // 2. Perform real network request
        guard let urlString = apiMap[level], let url = URL(string: urlString) else {
            print("[ERROR] No URL for level \(level)")
            return "No URL defined for this level"
        }
        
        print("[URL] \(url.absoluteString)")
        print("[METHOD] GET")
        print("[API START] \(screenName)")
        
        let startTime = Date()
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let duration = Date().timeIntervalSince(startTime)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return "Invalid Response"
            }
            
            print("\n--- [API RESPONSE] ---")
            print("[SCREEN] \(screenName)")
            print("[STATUS] \(httpResponse.statusCode)")
            print("[DURATION] \(String(format: "%.3f", duration))s")
            print("[SIZE] \(data.count) bytes")
            
            print("[API END] \(screenName)")
            
            if let responseString = String(data: data, encoding: .utf8) {
                let preview = responseString.count > 500 ? String(responseString.prefix(500)) + "..." : responseString
                print("[BODY] \(preview)")
                
                // Return a user-friendly summary for the UI
                if let json = try? JSONSerialization.jsonObject(with: data) {
                    if let dict = json as? [String: Any] {
                        return "Keys: \(dict.keys.joined(separator: ", "))"
                    } else if let array = json as? [[String: Any]] {
                        return "Array (\(array.count) items)"
                    }
                }
                return "Loaded successfully (\(data.count) bytes)"
            }
            
            return "Loaded data"
        } catch {
            print("\n--- [API ERROR] ---")
            print("[SCREEN] \(screenName)")
            print("[ERROR] \(error.localizedDescription)")
            return "Error: \(error.localizedDescription)"
        }
    }
    
    public func fakeAPICall(screenName: String) async -> String {
        return await fetchRealData(level: 0, screenName: screenName)
    }
}

#endif
