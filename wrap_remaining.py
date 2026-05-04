import os

root = "/home/vunet/development/workspaces/rakshith/projects/iOS-swift"
header = "#if canImport(UIKit) && (os(iOS) || os(tvOS))\n"
footer = "\n#endif"

# List of files that either import UIKit/SwiftUI or extend classes that were wrapped
target_files = [
    # Scenarios (extend ScenarioLibrary which is wrapped)
    "RUMSimulator/Scenarios/S1_BasicNavigation.swift",
    "RUMSimulator/Scenarios/S2_RapidInteraction.swift",
    "RUMSimulator/Scenarios/S3_NetworkStress.swift",
    "RUMSimulator/Scenarios/S4_SessionRestart.swift",
    "RUMSimulator/Scenarios/S5_ColdStart.swift",
    "RUMSimulator/Scenarios/S6_MixedLoad.swift",
    # UI Playgrounds
    "RUMSimulator/Screens/Navigation/SwiftUINavPlayground.swift",
]

# We already wrapped the main UIKit files, but let's re-run for these others.
for rel_path in target_files:
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
