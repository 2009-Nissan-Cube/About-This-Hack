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
    
    // Computed property to get the appropriate window size based on macOS version
    private var windowSize: NSSize {
        // In macOS Tahoe, the toolbar takes up more vertical space
        // We need to compensate by making the window slightly taller
        let isTahoe = isMacOSTahoe()
        return isTahoe ? NSSize(width: 580, height: 370) : defaultWindowSize
    }
    
    // Detect if running on macOS Tahoe (26.x) without waiting for HCVersion
    private func isMacOSTahoe() -> Bool {
        let osVersion = ProcessInfo.processInfo.operatingSystemVersion
        return osVersion.majorVersion == 26
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        ATHLogger.info(NSLocalizedString("log.window.loaded", comment: "Window controller loaded"), category: .ui)
        self.tabViewController = self.window?.contentViewController as? NSTabViewController

			// Localize segmented control immediately if outlet is ready on pre-Tahoe macOS
			// Skip immediate call on Tahoe to avoid race condition where outlet might not be ready
			// On Tahoe, rely on deferred async call and the call during loadDataAndShowWindow()
		if !isMacOSTahoe() {
			localizeSegmentedControl()
		}
		DispatchQueue.main.async { [weak self] in
			self?.localizeSegmentedControl()
		}

        // Hide window initially - will show once data is loaded
        window?.setIsVisible(false)

        // Set fixed window size - adjusted for Tahoe if needed
        let size = windowSize
        window?.setFrame(NSRect(origin: window?.frame.origin ?? .zero, size: size), display: false)
        window?.minSize = size
        window?.maxSize = size
        window?.styleMask.remove(.resizable)
        window?.styleMask.insert(.fullSizeContentView)

        // Restore window position or center if no saved position
        if let savedFrame = defaults.string(forKey: windowFrameKey) {
            var frame = NSRectFromString(savedFrame)
            frame.size = size  // Ensure correct size even if saved frame has different size
            window?.setFrame(frame, display: false)
            ATHLogger.debug(NSLocalizedString("log.window.restored", comment: "Window position restored"), category: .ui)
        } else {
            window?.center()
            ATHLogger.debug(NSLocalizedString("log.window.centered", comment: "Window centered"), category: .ui)
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

        // Add observer for data files created notification
        NotificationCenter.default.addObserver(self,
                                            selector: #selector(dataFilesCreated),
                                            name: CreateDataFiles.dataFilesCreatedNotification,
                                            object: nil)

        // Show loading indicator centered on main window while waiting for data
        LoadingIndicatorController.shared.show(centeredOn: window)

        // If data files are already created (e.g., app restarted), load immediately
        if CreateDataFiles.dataFilesCreated {
            loadDataAndShowWindow()
        }
    }

    @objc private func dataFilesCreated() {
        loadDataAndShowWindow()
    }

    private func loadDataAndShowWindow() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            // Collect all hardware data
            HardwareCollector.shared.getAllData()

            // Show window on main thread
            DispatchQueue.main.async {
                // Hide loading indicator before showing main window
                LoadingIndicatorController.shared.hide()
                
                // Ensure segmented control is properly localized before showing window
                // This is a safety measure for Tahoe where outlets might not be ready earlier
                self?.localizeSegmentedControl()
                
                // Trigger initial UI update for the Overview tab
                if let tabVC = self?.tabViewController,
                   let overviewVC = tabVC.tabViewItems.first?.viewController as? ViewController {
                    overviewVC.updateUIAfterDataLoaded()
                }

                self?.window?.setIsVisible(true)
                self?.window?.makeKeyAndOrderFront(nil)
                ATHLogger.info(NSLocalizedString("log.window.shown", comment: "Window shown after data loaded"), category: .ui)
            }
        }
    }
    
    private func localizeSegmentedControl() {
        guard let segmentedControl = segmentedControl else {
            ATHLogger.warning(NSLocalizedString("log.window.segmented_not_ready", comment: "Segmented control outlet not ready"), category: .ui)
            return
        }
        
        // Localize segment titles
        let titles = [
            NSLocalizedString("segment.title.overview", comment: "Overview segment title"),
            NSLocalizedString("segment.title.displays", comment: "Displays segment title"),
            NSLocalizedString("segment.title.storage", comment: "Storage segment title"),
            NSLocalizedString("segment.title.support", comment: "Support segment title")
        ]
        
        // Localize segment tooltips
        let tooltips = [
            NSLocalizedString("segment.tooltip.overview", comment: "Overview segment tooltip"),
            NSLocalizedString("segment.tooltip.displays", comment: "Displays segment tooltip"),
            NSLocalizedString("segment.tooltip.storage", comment: "Storage segment tooltip"),
            NSLocalizedString("segment.tooltip.support", comment: "Support segment tooltip")
        ]
        
        // Apply localized titles and tooltips to each segment
        for index in 0..<segmentedControl.segmentCount {
            if index < titles.count {
                segmentedControl.setLabel(titles[index], forSegment: index)
            }
            if index < tooltips.count {
				if #available(macOS 10.13, *) {
					segmentedControl.setToolTip(tooltips[index], forSegment: index)
				} else {
						// Fallback on earlier versions
				}
            }
        }
        
        ATHLogger.debug(NSLocalizedString("log.window.segmented_localized", comment: "Segmented control localized"), category: .ui)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        ATHLogger.debug(NSLocalizedString("log.window.deinitialized", comment: "Window controller deinitialized"), category: .ui)
    }

    @IBAction func segmentedControlSwitched(_ sender: Any) {
        guard let segCtrl = sender as? NSSegmentedControl else { return }
        currentView = segCtrl.selectedSegment
        tabViewController?.selectedTabViewItemIndex = currentView
        ATHLogger.info(String(format: NSLocalizedString("log.window.view_switched", comment: "View switched to index"), currentView), category: .ui)
    }
    
    public func changeView(new: Int) {
        ATHLogger.info(String(format: NSLocalizedString("log.window.view_changing", comment: "Changing view to index"), new), category: .ui)
        tabViewController?.selectedTabViewItemIndex = new
        segmentedControl?.selectedSegment = new
    }
    
    @objc private func windowDidMove(_ notification: Notification) {
        saveWindowFrame()
    }
    
    @objc private func windowDidResize(_ notification: Notification) {
        // Ensure window maintains fixed size even if somehow resized
        window?.setFrame(NSRect(origin: window?.frame.origin ?? .zero, size: windowSize), display: true)
        saveWindowFrame()
    }
    
    private func saveWindowFrame() {
        if let window = self.window {
            let frameString = NSStringFromRect(window.frame)
            defaults.set(frameString, forKey: windowFrameKey)
            ATHLogger.debug(String(format: NSLocalizedString("log.window.frame_saved", comment: "Saved window frame"), frameString), category: .ui)
        }
    }
}
