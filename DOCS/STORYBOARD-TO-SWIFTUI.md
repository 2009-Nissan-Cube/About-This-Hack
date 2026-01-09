## Convert Settings window from Storyboard to SwiftUI

### Created `SettingsView.swift`

- SwiftUI view with explicit `frame(width: 422, height: 400)`
- Drag-and-drop support via `.onDrop() `modifier
- SettingsViewModel manages state and validation logic

### Simplified `SettingsWindowController.swift`

- Removed UIKit element traversal and manual constraint handling
- Hosts SwiftUI via NSHostingController:

```swift
private func setupSwiftUIContent() {
    let settingsView = SettingsView()
    let hostingController = NSHostingController(rootView: settingsView)
    window?.contentViewController = hostingController
}
```

### Simplified `Settings.storyboard`

- Removed view controller scene with problematic constraints
- Retained window controller definition for AppDelegate instantiation
- Removed resizable from window style mask

### Preserved Functionality

- Drag-and-drop PNG validation (1024x1024)
- UserDefaults persistence
- Notification posting to Overview tab
- Error handling and status messages.