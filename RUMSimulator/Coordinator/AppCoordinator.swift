import UIKit

// MARK: - AppCoordinator

/// Root coordinator: wires engine, logger, network, and navigation.
/// The ONLY class that touches all layers. Uses dependency injection — no singletons.
final class AppCoordinator {

    // MARK: - Window

    private let window: UIWindow

    // MARK: - Core objects (owned here, passed down by init injection)

    let eventLogger: EventLogger
    private let debugViewModel: DebugPanelViewModel
    private let networkSimulator: NetworkSimulator
    private let engineState: EngineStateLegacy
    private let scenarioEngine: ScenarioEngine
    private let loadGenerator: LoadGenerator

    private var scenarioLibrary: ScenarioLibrary!
    private var playgroundCoordinator: PlaygroundCoordinator!
    private var controlPanelViewModel: ControlPanelViewModel!

    // MARK: - Root navigation

    private var rootNav: UINavigationController!

    // MARK: - Init

    init(window: UIWindow) {
        self.window = window

        // Build all dependencies bottom-up
        eventLogger       = EventLogger()
        debugViewModel    = DebugPanelViewModel()
        networkSimulator  = NetworkSimulator(debugState: debugViewModel, logger: eventLogger)
        engineState       = EngineStateLegacy()
        scenarioEngine    = ScenarioEngine(state: engineState, logger: eventLogger)
        loadGenerator     = LoadGenerator(logger: eventLogger)
    }

    // MARK: - Start

    func start() {
        // Build root UI
        let controlPanelVM = ControlPanelViewModel(engineState: engineState)
        self.controlPanelViewModel = controlPanelVM

        let rootNav = UINavigationController()
        rootNav.navigationBar.prefersLargeTitles = true
        self.rootNav = rootNav

        // Wire playground coordinator
        let coordinator = PlaygroundCoordinator(
            navigationController: rootNav,
            logger: eventLogger,
            networkSimulator: networkSimulator
        )
        self.playgroundCoordinator = coordinator

        // Wire scenario library (needs coordinator for playground VCs)
        let library = ScenarioLibrary(networkSimulator: networkSimulator)
        library.playgroundCoordinator = coordinator
        self.scenarioLibrary = library

        // Wire scenarios into control panel VM
        controlPanelVM.scenarios = library.all()

        // Build control panel VC
        let controlPanelVC = ControlPanelViewController(
            viewModel: controlPanelVM,
            engine: scenarioEngine,
            debugViewModel: debugViewModel,
            coordinator: coordinator
        )

        rootNav.setViewControllers([controlPanelVC], animated: false)
        window.rootViewController = rootNav

        // Log app start
        eventLogger.log(type: "lifecycle", metadata: ["event": "app_start"])
    }
}
