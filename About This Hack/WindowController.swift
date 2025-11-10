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

        // Hide window initially - will show once data is loaded
        window?.setIsVisible(false)

        // Set fixed window size
        window?.setFrame(NSRect(origin: window?.frame.origin ?? .zero, size: defaultWindowSize), display: false)
        window?.minSize = defaultWindowSize
        window?.maxSize = defaultWindowSize
        window?.styleMask.remove(.resizable)

        // Restore window position or center if no saved position
        if let savedFrame = defaults.string(forKey: windowFrameKey) {
            var frame = NSRectFromString(savedFrame)
            frame.size = defaultWindowSize  // Ensure correct size even if saved frame has different size
            window?.setFrame(frame, display: false)
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

        // Wait for data to be ready before showing window
        waitForDataAndShowWindow()
    }

    private func waitForDataAndShowWindow() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Wait for data files to be created
            while !CreateDataFiles.dataFilesCreated {
                Thread.sleep(forTimeInterval: 0.05)
            }

            // Collect all hardware data
            HardwareCollector.shared.getAllData()

            // Show window on main thread
            DispatchQueue.main.async {
                // Trigger initial UI update for the Overview tab
                if let tabVC = self?.tabViewController,
                   let overviewVC = tabVC.tabViewItems.first?.viewController as? ViewController {
                    overviewVC.updateUIAfterDataLoaded()
                }

                self?.window?.setIsVisible(true)
                self?.window?.makeKeyAndOrderFront(nil)
                ATHLogger.info("Window shown after data loaded", category: .ui)
            }
        }
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
