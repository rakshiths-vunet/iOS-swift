import os

def wrap_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    
    if content.strip().startswith('#if os(iOS)') or content.strip().startswith('#if canImport(UIKit)'):
        print(f"Skipping {filepath} (already wrapped)")
        return

    # Wrap content
    wrapped = f"#if os(iOS)\n{content}\n#endif\n"
    
    with open(filepath, 'w') as f:
        f.write(wrapped)
    print(f"Wrapped {filepath}")

def main():
    root_dir = "/home/vunet/development/workspaces/rakshith/projects/iOS-swift/RUMSimulator"
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith(".swift"):
                wrap_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
