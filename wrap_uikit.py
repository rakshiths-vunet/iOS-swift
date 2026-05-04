import os

uikit_files = [
    "RUMSimulator/Coordinator/PlaygroundCoordinator.swift",
    "RUMSimulator/Coordinator/AppCoordinator.swift",
    "RUMSimulator/Engine/ScenarioLibrary.swift",
    "RUMSimulator/SceneDelegate.swift",
    "RUMSimulator/Screens/Navigation/UIKitNavPlaygroundVC.swift",
    "RUMSimulator/Screens/Navigation/NavLevelViewController.swift",
    "RUMSimulator/Screens/Navigation/ModalViewController.swift",
    "RUMSimulator/Screens/CrashError/CrashPlaygroundVC.swift",
    "RUMSimulator/Screens/DebugPanel/DebugPanelViewController.swift",
    "RUMSimulator/Screens/Network/NetworkPlaygroundVC.swift",
    "RUMSimulator/Screens/Interaction/InteractionPlaygroundVC.swift",
    "RUMSimulator/Screens/Interaction/GestureSimulator.swift",
    "RUMSimulator/Screens/Lifecycle/LifecyclePlaygroundVC.swift",
    "RUMSimulator/Screens/ControlPanel/ControlPanelViewController.swift",
    "RUMSimulator/Logging/LogViewerViewController.swift",
    "RUMSimulator/AppDelegate.swift",
    "RUMSimulator/Scenarios/S2_RapidInteraction.swift",
    "RUMSimulator/Scenarios/S4_SessionRestart.swift",
    "RUMSimulator/Scenarios/S1_BasicNavigation.swift",
    "RUMSimulator/Lifecycle/LifecycleObserver.swift"
]

root = "/home/vunet/development/workspaces/rakshith/projects/iOS-swift"

header = "#if canImport(UIKit) && (os(iOS) || os(tvOS))\n"
footer = "\n#endif"

for rel_path in uikit_files:
    abs_path = os.path.join(root, rel_path)
    if not os.path.exists(abs_path):
        print(f"Skipping {rel_path} - not found")
        continue
    
    with open(abs_path, 'r') as f:
        content = f.read()
    
    if header in content:
        print(f"Skipping {rel_path} - already wrapped")
        continue
    
    new_content = header + content + footer
    
    with open(abs_path, 'w') as f:
        f.write(new_content)
    print(f"Wrapped {rel_path}")
