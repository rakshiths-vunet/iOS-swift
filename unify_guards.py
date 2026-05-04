import os

for root, dirs, files in os.walk("RUMSimulator"):
    for file in files:
        if file.endswith(".swift"):
            path = os.path.join(root, file)
            with open(path, "r") as f:
                content = f.read()
            
            # Replace complex guard with simple os(iOS)
            new_content = content.replace("#if canImport(UIKit) && (os(iOS) || os(tvOS))", "#if os(iOS)")
            
            if new_content != content:
                with open(path, "w") as f:
                    f.write(new_content)
                print(f"Updated {path}")
