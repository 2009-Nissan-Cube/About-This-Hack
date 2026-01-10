import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController {
    
    // MARK: - Constants
    private static let windowWidth: CGFloat = 422
    private static let defaultWindowHeight: CGFloat = 350
    
    // Computed property to get the appropriate window height based on macOS version
    private var windowHeight: CGFloat {
        // In macOS Tahoe, the toolbar takes up more vertical space
        // We need to compensate by making the window slightly taller
        let isTahoe = isMacOSTahoe()
        return isTahoe ? 370 : Self.defaultWindowHeight
    }
    
    // Detect if running on macOS Tahoe (26.x)
    private func isMacOSTahoe() -> Bool {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return osVersion.majorVersion == 26
    }
    
    // MARK: - Lifecycle
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Set window properties
        window?.styleMask.remove(.resizable)
        
        // Explicitly set the window size to ensure it's applied correctly
        setWindowSize()
        
        // Setup SwiftUI content
        setupSwiftUIContent()
    }
    
    override func windowWillLoad() {
        super.windowWillLoad()
        // Prevent window cascading to ensure consistent positioning
        shouldCascadeWindows = false
    }
    
    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        
        // Reset window size every time it's shown to prevent any saved frame from being used
        setWindowSize()
        
        // Position window next to main window
        positionWindowNextToMainWindow()
    }
    
    // MARK: - Window Management
    private func setWindowSize() {
        let windowSize = NSSize(width: Self.windowWidth, height: windowHeight)
        window?.setContentSize(windowSize)
        window?.minSize = windowSize
        window?.maxSize = windowSize
    }
    
    private func positionWindowNextToMainWindow() {
        guard let settingsWindow = window else {
            return
        }
        
        // Find the main application window (not the settings window)
        let mainWindow = NSApplication.shared.windows.first { window in
            window != settingsWindow &&
            window.isVisible &&
            window.windowController is WindowController
        }
        
        guard let mainWindow = mainWindow else {
            // Fallback: center the settings window if main window not found
            settingsWindow.center()
            return
        }
        
        let mainFrame = mainWindow.frame
        let settingsFrame = settingsWindow.frame
        
        // Position to the right of main window with some spacing
        let spacing: CGFloat = 10
        var newOrigin = NSPoint(
            x: mainFrame.maxX + spacing,
            y: mainFrame.maxY - settingsFrame.height
        )
        
        // Check if the window would go off-screen to the right
        if let screen = mainWindow.screen {
            let screenFrame = screen.visibleFrame
            
            // If off-screen to the right, try positioning to the left
            if newOrigin.x + settingsFrame.width > screenFrame.maxX {
                newOrigin.x = mainFrame.minX - settingsFrame.width - spacing
            }
            
            // If still off-screen (now to the left), position below the main window
            if newOrigin.x < screenFrame.minX {
                newOrigin.x = mainFrame.minX
                newOrigin.y = mainFrame.minY - settingsFrame.height - spacing
            }
            
            // If off-screen below, position above the main window
            if newOrigin.y < screenFrame.minY {
                newOrigin.x = mainFrame.minX
                newOrigin.y = mainFrame.maxY + spacing
            }
            
            // Ensure the window is fully visible on screen
            if newOrigin.x < screenFrame.minX {
                newOrigin.x = screenFrame.minX
            }
            if newOrigin.y < screenFrame.minY {
                newOrigin.y = screenFrame.minY
            }
            if newOrigin.x + settingsFrame.width > screenFrame.maxX {
                newOrigin.x = screenFrame.maxX - settingsFrame.width
            }
            if newOrigin.y + settingsFrame.height > screenFrame.maxY {
                newOrigin.y = screenFrame.maxY - settingsFrame.height
            }
        }
        
        settingsWindow.setFrameOrigin(newOrigin)
    }
    
    // MARK: - Setup
    private func setupSwiftUIContent() {
        // Create SwiftUI view and wrap it in NSHostingController
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        // Set the hosting controller as the window's content view controller
        window?.contentViewController = hostingController
    }
}
