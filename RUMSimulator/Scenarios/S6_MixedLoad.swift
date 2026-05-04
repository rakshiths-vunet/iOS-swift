#if os(iOS)
import Foundation

// MARK: - S6: Mixed Load (Continuous)

extension ScenarioLibrary {
    func s6() -> Scenario {
        // Combines S1 navigation steps + S2 interaction steps + S3 network steps
        let s1Steps = s1().steps
        let s2Steps = s2().steps
        let s3Steps = s3().steps

        var combined: [ScenarioStep] = []
        combined.append(contentsOf: s1Steps)
        combined.append(contentsOf: s2Steps)
        combined.append(contentsOf: s3Steps)

        return Scenario(
            id: "S6",
            name: "Mixed Load (Continuous)",
            steps: combined,
            loop: true  // loops indefinitely until manually stopped
        )
    }
}

#endif