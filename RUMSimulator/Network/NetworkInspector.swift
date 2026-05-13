#if os(iOS)
import Foundation
import Alamofire

// MARK: - URLProtocol Inspection

final class HeaderInspectorProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        if let headers = request.allHTTPHeaderFields {
            print("🔍 [URLProtocol] Outgoing Headers (\(request.url?.absoluteString ?? "unknown")): \(headers)")
        }
        return false // Don't actually handle the request, just inspect
    }
}

// MARK: - Alamofire Inspection

final class AlamofireHeaderInterceptor: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        // Intercepting at adapt time might show empty headers if default ones aren't added yet
        completion(.success(urlRequest))
    }
}

final class AlamofireHeaderMonitor: EventMonitor {
    func requestDidFinish(_ request: Request) {
        if let headers = request.request?.allHTTPHeaderFields {
            print("🔍 [Alamofire Monitor] Final Outgoing Headers (\(request.request?.url?.absoluteString ?? "unknown")): \(headers)")
        }
    }
}

// MARK: - URLSession Delegate Inspection

final class HeaderInspectorSessionDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        // Inspect currentRequest which should have all headers populated by the system
        if let headers = task.currentRequest?.allHTTPHeaderFields {
            print("🔍 [URLSessionDelegate] Final Outgoing Headers (\(task.currentRequest?.url?.absoluteString ?? "unknown")): \(headers)")
        }
    }
}

#endif
