//
//  LoadingIndicatorController.swift
//  About This Hack
//
//  Loading indicator window that displays while collecting hardware data
//

import Cocoa

class LoadingIndicatorController {
    
    // Singleton instance
    static let shared = LoadingIndicatorController()
    
    private var loadingWindow: NSWindow?
    private var progressIndicator: NSProgressIndicator?
    
    private init() {}
    
    /// Shows the loading indicator window centered on the parent window if provided, otherwise centered on screen
    /// - Parameter parentWindow: The window to center the loading indicator on
    func show(centeredOn parentWindow: NSWindow? = nil) {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.show(centeredOn: parentWindow)
            }
            return
        }
        
        // Don't show if already visible
        guard loadingWindow == nil else { return }
        
        // Create the loading window
        let windowWidth: CGFloat = 200
        let windowHeight: CGFloat = 80
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        
        window.title = ""
        window.isReleasedWhenClosed = false
        window.level = .floating
        
        // Center on parent window if provided, otherwise center on screen
        if let parent = parentWindow {
            let parentFrame = parent.frame
            var x = parentFrame.origin.x + (parentFrame.width - windowWidth) / 2
            var y = parentFrame.origin.y + (parentFrame.height - windowHeight) / 2
            
            // Ensure the window stays within screen bounds
            if let screen = parent.screen ?? NSScreen.main {
                let screenFrame = screen.visibleFrame
                x = max(screenFrame.minX, min(x, screenFrame.maxX - windowWidth))
                y = max(screenFrame.minY, min(y, screenFrame.maxY - windowHeight))
            }
            
            window.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            window.center()
        }
        
        // Create container view
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: windowWidth, height: windowHeight))
        
        // Create and configure the progress indicator (spinning style)
        let spinner = NSProgressIndicator(frame: NSRect(x: (windowWidth - 32) / 2, y: 40, width: 32, height: 32))
        spinner.style = .spinning
        spinner.controlSize = .regular
        spinner.isIndeterminate = true
        
        // Create the "Loading data..." label
        let label = NSTextField(labelWithString: NSLocalizedString("loading.data.message", comment: "Loading data message"))
        label.frame = NSRect(x: 0, y: 10, width: windowWidth, height: 20)
        label.alignment = .center
        label.font = NSFont.systemFont(ofSize: 13)
        
        // Add subviews
        contentView.addSubview(spinner)
        contentView.addSubview(label)
        
        window.contentView = contentView
        
        // Store references
        self.loadingWindow = window
        self.progressIndicator = spinner
        
        // Start animation and show window
        spinner.startAnimation(nil)
        window.makeKeyAndOrderFront(nil)
        
        ATHLogger.debug(NSLocalizedString("log.loading.shown", comment: "Loading indicator shown"), category: .ui)
    }
    
    /// Hides and disposes the loading indicator window
    func hide() {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.hide()
            }
            return
        }
        
        guard let window = loadingWindow else { return }
        
        progressIndicator?.stopAnimation(nil)
        window.orderOut(nil)
        
        loadingWindow = nil
        progressIndicator = nil
        
        ATHLogger.debug(NSLocalizedString("log.loading.hidden", comment: "Loading indicator hidden"), category: .ui)
    }
}
