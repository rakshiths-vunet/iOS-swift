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
                    Task { _ = await net.fire(.get) }
                }, delay: 0.3),
                ScenarioStep(label: "Fire GET /delay/3", action: {
                    Task { _ = await net.fire(.delay(3)) }
                }, delay: 0.3),
                ScenarioStep(label: "Fire GET /status/500", action: {
                    Task { _ = await net.fire(.status(500)) }
                }, delay: 0.3),
                ScenarioStep(label: "Fire invalid domain (DNS fail)", action: {
                    Task { _ = await net.fire(.invalidDomain) }
                }, delay: 0.3),
                ScenarioStep(label: "Fire 10 concurrent calls", action: {
                    Task {
                        let endpoints: [HTTPBinEndpoint] = [
                            .get, .get, .delay(1), .status(404),
                            .get, .status(500), .delay(2), .get,
                            .invalidDomain, .get
                        ]
                        _ = await net.fireParallel(endpoints)
                    }
                }, delay: 4.0),
            ],
            loop: false
        )
    }
}
