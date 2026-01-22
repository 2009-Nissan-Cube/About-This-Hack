## Convert Settings window from Storyboard to SwiftUI

### Created `SettingsView.swift`

- SwiftUI view with explicit size for the actual content
- Window content size is set to 330 to match the SwiftUI view's frame
- Drag-and-drop support via `.onDrop() `modifier
- SettingsViewModel manages state and validation logic

### Updated `SettingsWindowController.swift`

- Removed dependency on Settings.storyboard
- Added convenience initializer to create window programmatically:

```swift
convenience init() {
    // Create the window programmatically
    let contentRect = NSRect(x: 0, y: 0, width: SettingsWindowController.windowWidth, height: SettingsWindowController.contentHeight)
    let styleMask: NSWindow.StyleMask = [.titled, .closable, .miniaturizable]
    let window = NSWindow(contentRect: contentRect, styleMask: styleMask, backing: .buffered, defer: false)
    
    // Configure window properties
    window.title = NSLocalizedString("settings.title", comment: "Custom logo settings")
    window.isReleasedWhenClosed = false
    
    self.init(window: window)
}
```

- Hosts SwiftUI via NSHostingController:

```swift
private func setupSwiftUIContent() {
    let settingsView = SettingsView()
    let hostingController = NSHostingController(rootView: settingsView)
    window?.contentViewController = hostingController
}
```

### Updated `AppDelegate.swift`

- Removed storyboard instantiation
- Direct instantiation of SettingsWindowController:

```swift
@IBAction func showSettings(_ sender: Any) {
    if settingsWindowController == nil {
        settingsWindowController = SettingsWindowController()
    }
    settingsWindowController?.showWindow(nil)
    settingsWindowController?.window?.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)
}
```

### Removed `Settings.storyboard`

- Completely removed Settings.storyboard file from project
- Removed all references from project.pbxproj
- Window is now created entirely programmatically

### Preserved Functionality

- Drag-and-drop PNG validation (1024x1024)
- UserDefaults persistence
- Notification posting to Overview tab
- Error handling and status messages
- Window positioning next to main window
- Cmd+, keyboard shortcut still works
