// swift-tools-version: 5.9
// RUMSimulator — no external dependencies (PRD constraint)
import PackageDescription

let package = Package(
    name: "RUMSimulator",
    platforms: [.iOS(.v16)],
    products: [
        .executable(name: "RUMSimulator", targets: ["RUMSimulator"])
    ],
    targets: [
        .executableTarget(
            name: "RUMSimulator",
            path: "RUMSimulator",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
