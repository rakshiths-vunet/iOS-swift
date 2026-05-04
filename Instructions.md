Product Requirements Document
RUM Scenario Simulator
A synthetic iOS application for Real User Monitoring SDK validation
iOS · Swift
UIKit + SwiftUI
Internal Tool
v1.0
Auto-instrumentation only
Contents
01
Overview & Purpose
02
Goals & Non-Goals
03
App Modes
04
Scenario Engine
05
Predefined Scenarios
06
Playgrounds
07
Control Panel & Debug
08
Logging System
09
Architecture
10
Engineering Constraints
11
Success Criteria
12
Build Phases
01
Overview & Purpose
This document specifies a synthetic iOS application built exclusively to stress-test and validate the auto-instrumentation capabilities of a Real User Monitoring (RUM) SDK. The app generates controlled, repeatable signals — page navigations, user interactions, network requests, lifecycle events — without writing a single manual instrumentation hook.

The core premise: if the SDK's auto-capture works correctly, it should observe everything this app does simply by being linked into the binary.

📐
Deterministic scenarios
Every run produces identical signals, making SDK regressions easy to spot.
🔁
Auto + manual modes
Scripted runs for CI, free-form exploration for developers.
📡
Full signal coverage
Navigation, taps, network, lifecycle, crashes — all surfaces covered.
⚡
Load generation
Burst and sustained modes push the SDK to its limits under high volume.
02
Goals & Non-Goals
Goals
Validate auto-instrumented telemetry across all SDK surfaces
Simulate realistic synthetic user journeys in a controlled, repeatable way
Run deterministic scripted scenarios with configurable speed and intensity
Stress-test the SDK with high event volumes (burst and sustained)
Support both manual developer exploration and automated CI-friendly runs
Provide local logs to cross-reference what the SDK should be capturing
Non-Goals
No business logic
No manual span creation
No backend ownership
No real product flows
No analytics dashboards
No real user data
03
App Modes
The app operates in two modes, togglable from the Home / Control Panel screen.

🧑‍💻
Manual mode
User drives all interactions. Used for exploratory testing and SDK debugging by developers.
🤖
Auto mode (primary)
Scripted scenarios run end-to-end. Deterministic, repeatable, configurable speed and intensity.
Home / Control Panel
The entry screen of the app serves as the central orchestration UI. It must expose:

Mode toggle (Manual / Auto)
Scenario picker dropdown / list
Start / Stop automation controls
Live status display: active scenario, step count, approximate event rate
Navigation entry points to all playgrounds
04
Scenario Engine
The core of the app is a lightweight scenario execution engine. It runs sequences of typed steps with configurable delays, forming deterministic user journeys.

Core Data Model
struct ScenarioStep { let action: () -> Void let delay: TimeInterval // seconds before next step fires let label: String // human-readable, shown in control panel }
struct Scenario { let id: String let name: String let steps: [ScenarioStep] let loop: Bool // repeat after completion }
Engine Requirements
Execute steps sequentially with configurable per-step delays
Support speed multiplier (0.5× – 5×) applied globally to all delays
Expose current step index and scenario name to the control panel in real-time
Support graceful stop and reset at any point
Use GCD / async-await — no third-party scheduler dependencies
Steps must be main-thread-safe for all UIKit interactions
05
Predefined Scenarios
Six predefined scenarios cover the full surface area of RUM signal types. Each must be runnable in isolation or as part of a combined mixed-load flow.

S1
Basic Navigation Flow
Open screen A → navigate to B → C → D → pop back stack → open modal → dismiss modal. Validates push/pop and modal presentation tracking.
Navigation
S2
Rapid Interaction Burst
Rapid button taps in a loop → aggressive scroll up/down → long press → swipe gestures. Validates tap, scroll, and gesture auto-capture at high frequency.
Interaction
S3
Network Stress Flow
Fire multiple concurrent URLSession requests: fast success (/get), slow response (/delay/3), server error (/status/500), invalid domain. Tests network telemetry across all outcome types.
Network
S4
Session Restart Flow
Start actions → background app → wait → resume → continue actions. Validates session lifecycle continuity and background/foreground transition tracking.
Lifecycle
S5
Cold Start Simulation
App launch → immediate navigation to a deep screen + fire network calls simultaneously. Validates cold-start session initialisation and early signal capture.
Lifecycle
S6
Mixed Load (Continuous)
Navigation + rapid interactions + network calls combined in a continuous loop. The primary stress scenario for SDK throughput and event volume validation.
Mixed
06
Playground Modules
Each playground is a standalone screen (or screen group) that can be driven manually or orchestrated by the scenario engine. Playgrounds are the building blocks scenarios are composed from.

🗺
Navigation Playground
UIKit flow via UINavigationController (push/pop up to 10 levels). SwiftUI flow via NavigationStack with programmatic navigation. Supports rapid transitions and modal + push combinations.
UINavigationController
NavigationStack
deep stacks
modals
👆
Interaction Playground
Buttons of multiple types, ScrollView, UITableView, gesture recognizers. Supports looped rapid tap simulation, long press, and scroll velocity variations.
UIButton
ScrollView
UITableView
gestures
🌐
Network Playground
URLSession-only (critical: no AFNetworking, no Alamofire). Targets httpbin.org for /get (success), /delay/3 (slow), /status/500 (error), and invalid domains (DNS failure). Supports sequential, parallel (10–50 concurrent), and retry patterns.
URLSession
httpbin
parallel calls
error simulation
♻️
Lifecycle Playground
Hooks into sceneDidBecomeActive, sceneWillResignActive, sceneDidEnterBackground. Simulates foreground → background → foreground cycles, app inactivity periods, and scene phase transitions.
SceneDelegate
background/foreground
inactivity
💥
Crash & Error Playground
Manual crash trigger via fatalError("Test Crash") with a confirmation guard. UI freeze simulation via Thread.sleep(forTimeInterval: 5) to test ANR / hang detection. Non-fatal error generation for error-tracking surface validation.
fatalError
Thread.sleep
non-fatal
⚡
Load Generator
Three sub-modes: Burst (X actions in Y seconds), Sustained (continuous moderate rate indefinitely), Mixed (navigation + network + interactions combined). Configurable from the debug panel.
burst
sustained
mixed load
07
Control Panel & Debug Panel
Control Panel (always visible)
Manual / Auto mode toggle — persistent across sessions
Scenario selector (list or segmented control)
Start / Stop / Reset automation controls
Live readout: scenario name, step N of M, ~events/sec
Quick-launch buttons to each playground
Debug Panel (hidden — long-press logo or shake gesture to reveal)
Speed multiplier slider: 0.5× to 5× (applies to all scenario delays)
Network delay toggle (forces /delay/3 for all requests)
Failure rate slider (0–100% of requests return errors)
Force crash button (with mandatory confirmation dialog)
Force background simulation
Reset all app state and clear logs
08
Local Logging System
A local event log lets developers cross-reference what the SDK should have captured against what the RUM backend actually recorded. This is the primary debugging tool for SDK gaps.

Log Event Model
struct LogEvent: Codable { let timestamp: Date let type: String // "navigation", "tap", "network", "lifecycle" let scenario: String? // active scenario name, if any let step: Int? // step index in scenario let metadata: [String: String] }
In-memory ring buffer for live display (last 500 events)
Async file write to /Documents/rum_log.json — append mode
Export / Share via UIActivityViewController
Filterable by event type in the log viewer screen
Separate log file per scenario run (timestamped filename)
09
Architecture
Tech Stack
Swift 5+
UIKit
SwiftUI
URLSession
GCD + async/await
No third-party SDKs
Components
ScenarioEngine
Executes step sequences. Manages timing, speed multiplier, and live step state.
PlaygroundCoordinator
Routes between playground modules. Handles both UIKit and SwiftUI navigation roots.
NetworkSimulator
URLSession wrapper. Applies debug panel overrides (delay, failure rate).
LifecycleObserver
Listens to SceneDelegate callbacks and forwards them to the logger.
EventLogger
In-memory + file logging. Handles export and per-scenario file rotation.
ControlPanelVM
Observable state for the Home screen. Bridges engine state to UI.
10
Engineering Constraints
These constraints are non-negotiable. They ensure the app generates only signals the SDK can auto-capture — no hand-rolled spans or custom events.

No manual instrumentation hooks. No SDK API calls. Zero custom span creation.
Network traffic must use URLSession only — no AFNetworking, no Alamofire, no custom transport.
All signals must originate from: UI interactions, navigation events, URLSession, or OS lifecycle callbacks.
No third-party UI frameworks that intercept or wrap system gesture recognizers.
The crash playground must require explicit developer confirmation before triggering fatalError.
Background simulation must use documented SceneDelegate APIs only — no private APIs.
11
Success Criteria
Functional
All 6 scenarios execute reliably. Auto mode runs indefinitely without unintended crashes.
Observability
RUM backend shows screen transitions, network spans, session events, and crash reports.
Load
App sustains 20–50 concurrent network calls and high-frequency UI events without degradation.
12
Build Phases
Phase 1
Foundation
AppDelegate + SceneDelegate setup, UIKit navigation skeleton, SwiftUI NavigationStack root, URLSession integration with httpbin, manual mode with all playgrounds accessible.
Phase 2
Scenario Engine + Core Scenarios
ScenarioEngine implementation, S1 Basic Navigation, S3 Network Stress, control panel with live step readout, speed multiplier.
Phase 3
Full Scenario Suite + Load Generator
S2, S4, S5, S6 scenarios, load generator (burst + sustained + mixed), lifecycle playground, crash playground with confirmation guard.
Phase 4
Debug Panel + Logging
Debug panel (shake to reveal), full EventLogger with file rotation and share sheet, failure rate slider, network delay toggle, per-scenario log export.
RUM Scenario Simulator · PRD v1.0
Generate project structure ↗


Here's the full folder structure with every file explained. I'll follow it with a structural diagram showing how the major layers relate.Now the structural diagram showing how these layers wire together at runtime:Use the filter buttons in the tree to isolate any layer. A few things worth noting about the layout decisions:

**Why `Scenarios/` is separate from `Engine/`.** The engine is generic infrastructure — it doesn't know what a "Network Stress" scenario is. The `Scenarios/` folder holds the six concrete step definitions. This makes it trivial to add a seventh scenario without touching the engine at all.

**Why there are two `Network/` folders.** `Screens/Network/` is the playground UI (buttons, result list). `Network/` at the root is the `URLSession` wrapper and endpoint enum — pure logic, no UIKit. The scenario engine imports from the root `Network/`, not the screen.

**`AppCoordinator` is the only thing that touches everything.** It's the wiring layer — it holds references to `ScenarioEngine`, `EventLogger`, `PlaygroundCoordinator`, and passes them down by dependency injection. No singleton access anywhere else.

**`LifecycleObserver` lives in `Lifecycle/`, not `Screens/Lifecycle/`.** It's not a screen — it's an infrastructure object that bridges `SceneDelegate` callbacks into the logger. The `LifecyclePlaygroundVC` (the screen) is separate and just triggers explicit foreground/background simulations for testing.

Let me know if you want starter Swift code for any specific file — the `ScenarioEngine`, `NetworkSimulator`, or `EventLogger` are good places to begin.