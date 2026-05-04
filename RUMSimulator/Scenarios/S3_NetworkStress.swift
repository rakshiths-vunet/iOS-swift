#if os(iOS)
import Foundation

// MARK: - S3: Network Stress Flow

extension ScenarioLibrary {
    func s3() -> Scenario {
        let net = networkSimulator
        let nav = playgroundCoordinator
        return Scenario(
            id: "S3",
            name: "Network Stress Flow",
            steps: [
                ScenarioStep(label: "Open Network Playground", action: {
                    nav?.openNetworkPlayground()
                }, delay: 0.5),
                ScenarioStep(label: "Fire GET /get", action: {
                    Task { _ = await net.fire(HTTPBinEndpoint.get) }
                }, delay: 0.3),
                ScenarioStep(label: "Fire GET /delay/3", action: {
                    Task { _ = await net.fire(HTTPBinEndpoint.delay(3)) }
                }, delay: 0.3),
                ScenarioStep(label: "Fire GET /status/500", action: {
                    Task { _ = await net.fire(HTTPBinEndpoint.status(500)) }
                }, delay: 0.3),
                ScenarioStep(label: "Fire invalid domain (DNS fail)", action: {
                    Task { _ = await net.fire(HTTPBinEndpoint.invalidDomain) }
                }, delay: 0.3),
                ScenarioStep(label: "Fire 10 concurrent calls", action: {
                    Task {
                        let endpoints: [HTTPBinEndpoint] = [
                            HTTPBinEndpoint.get, HTTPBinEndpoint.get, HTTPBinEndpoint.delay(1), HTTPBinEndpoint.status(404),
                            HTTPBinEndpoint.get, HTTPBinEndpoint.status(500), HTTPBinEndpoint.delay(2), HTTPBinEndpoint.get,
                            HTTPBinEndpoint.invalidDomain, HTTPBinEndpoint.get
                        ]
                        _ = await net.fireParallel(endpoints)
                    }
                }, delay: 4.0),
            ],
            loop: false
        )
    }
}

#endif