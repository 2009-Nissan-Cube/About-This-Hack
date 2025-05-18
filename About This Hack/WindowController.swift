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
        print("loaded")
        self.tabViewController = self.window?.contentViewController as? NSTabViewController
        
        // Set fixed window size
        window?.setContentSize(defaultWindowSize)
        window?.maxSize = defaultWindowSize
        window?.minSize = defaultWindowSize
        
        // Restore window position or center if no saved position
        if let savedFrame = defaults.string(forKey: windowFrameKey) {
            var frame = NSRectFromString(savedFrame)
            frame.size = defaultWindowSize
            window?.setFrame(frame, display: true)
        } else {
            window?.center()
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
    }

    @IBAction func segmentedControlSwitched(_ sender: Any) {
        print("switched")
        guard let segCtrl = sender as? NSSegmentedControl else { return }
        currentView = segCtrl.selectedSegment
        tabViewController?.selectedTabViewItemIndex = currentView
    }
    
    public func changeView(new: Int) {
        print("changed to \(new)")
        tabViewController?.selectedTabViewItemIndex = new
        segmentedControl?.selectedSegment = new
    }
    
    @objc private func windowDidMove(_ notification: Notification) {
        saveWindowFrame()
    }
    
    @objc private func windowDidResize(_ notification: Notification) {
        saveWindowFrame()
    }
    
    private func saveWindowFrame() {
        if let window = self.window {
            let frameString = NSStringFromRect(window.frame)
            defaults.set(frameString, forKey: windowFrameKey)
        }
    }
}
