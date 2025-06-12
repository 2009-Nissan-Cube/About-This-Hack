//
//  WindowController.swift
//  NSTabView
//
//

import Cocoa

class WindowController: NSWindowController {
    
    public var tabViewController: NSTabViewController?
    public var currentView: Int = 0
    @IBOutlet public weak var segmentedControl: NSSegmentedControl!
    
    private let defaults = UserDefaults.standard
    private let windowFrameKey = "MainWindowFrame"
    private let defaultWindowSize = NSSize(width: 580, height: 350)
    
    override func windowDidLoad() {
        super.windowDidLoad()
        ATHLogger.info("Window controller loaded", category: .ui)
        self.tabViewController = self.window?.contentViewController as? NSTabViewController
        
        // Set fixed window size
        window?.setFrame(NSRect(origin: window?.frame.origin ?? .zero, size: defaultWindowSize), display: true)
        window?.minSize = defaultWindowSize
        window?.maxSize = defaultWindowSize
        window?.styleMask.remove(.resizable)
        
        // Compact toolbar for macOS Tahoe
        if #available(macOS 26.0, *) {
            window?.toolbarStyle = .unifiedCompact
            window?.toolbar?.displayMode = .iconOnly
        }
        
        // Restore window position or center if no saved position
        if let savedFrame = defaults.string(forKey: windowFrameKey) {
            var frame = NSRectFromString(savedFrame)
            frame.size = defaultWindowSize  // Ensure correct size even if saved frame has different size
            window?.setFrame(frame, display: true)
            ATHLogger.debug("Restored window position from saved frame", category: .ui)
        } else {
            window?.center()
            ATHLogger.debug("No saved window position, centering window", category: .ui)
        }
        
        // Add window move observer
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(windowDidMove),
                                            name: NSWindow.didMoveNotification,
                                            object: window)
        
        // Add window resize observer
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(windowDidResize),
                                            name: NSWindow.didResizeNotification,
                                            object: window)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        ATHLogger.debug("Window controller deinitialized", category: .ui)
    }

    @IBAction func segmentedControlSwitched(_ sender: Any) {
        guard let segCtrl = sender as? NSSegmentedControl else { return }
        currentView = segCtrl.selectedSegment
        tabViewController?.selectedTabViewItemIndex = currentView
        ATHLogger.info("View switched to index: \(currentView)", category: .ui)
    }
    
    public func changeView(new: Int) {
        ATHLogger.info("Changing view to index: \(new)", category: .ui)
        tabViewController?.selectedTabViewItemIndex = new
        segmentedControl?.selectedSegment = new
    }
    
    @objc private func windowDidMove(_ notification: Notification) {
        saveWindowFrame()
    }
    
    @objc private func windowDidResize(_ notification: Notification) {
        // Ensure window maintains fixed size even if somehow resized
        window?.setFrame(NSRect(origin: window?.frame.origin ?? .zero, size: defaultWindowSize), display: true)
        saveWindowFrame()
    }
    
    private func saveWindowFrame() {
        if let window = self.window {
            let frameString = NSStringFromRect(window.frame)
            defaults.set(frameString, forKey: windowFrameKey)
            ATHLogger.debug("Saved window frame: \(frameString)", category: .ui)
        }
    }
}
