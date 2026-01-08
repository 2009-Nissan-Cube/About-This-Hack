import Cocoa

class SettingsWindowController: NSWindowController {
    
    // MARK: - Properties
    private let defaults = UserDefaults.standard
    private var dragDestination: DragDestinationView?
    
    // References to UI elements (accessed from content view)
    private var logoImageView: NSImageView?
    private var infoLabel: NSTextField?
    private var statusLabel: NSTextField?
    private var resetButton: NSButton?
    
    // MARK: - Lifecycle
    override func windowDidLoad() {
        super.windowDidLoad()
        
        // Set window properties
        window?.styleMask.remove(.resizable)
        window?.center()
        
        // Get references to UI elements from content view
        findUIElements()
        
        // Configure UI
        setupUI()
        loadCustomLogo()
    }
    
    // MARK: - Setup
    private func findUIElements() {
        guard let contentView = window?.contentViewController?.view else {
            ATHLogger.error("Settings window content view not found", category: .ui)
            return
        }
        
        // Find UI elements by their identifiers from the storyboard
        logoImageView = findView(in: contentView, withIdentifier: "logo-image-view")
        infoLabel = findView(in: contentView, withIdentifier: "info-label")
        statusLabel = findView(in: contentView, withIdentifier: "status-label")
        resetButton = findView(in: contentView, withIdentifier: "reset-button")
        
        // Connect the reset button action
        resetButton?.target = self
        resetButton?.action = #selector(resetToDefault(_:))
    }
    
    private func findView<T: NSView>(in view: NSView, withIdentifier identifier: String) -> T? {
        if view.identifier?.rawValue == identifier {
            return view as? T
        }
        for subview in view.subviews {
            if let found: T = findView(in: subview, withIdentifier: identifier) {
                return found
            }
        }
        return nil
    }
    
    private func setupUI() {
        // Check if UI elements were found
        guard let infoLabel = infoLabel,
              let statusLabel = statusLabel,
              let resetButton = resetButton,
              let logoImageView = logoImageView else {
            ATHLogger.error("Settings window UI elements not found", category: .ui)
            return
        }
        
        infoLabel.stringValue = NSLocalizedString("settings.logo.info", 
            comment: "Drag and drop a PNG image (1024x1024 pixels) to customize the macOS logo in the Overview tab.")
        statusLabel.stringValue = ""
        resetButton.title = NSLocalizedString("settings.logo.reset", comment: "Reset to Default")
        
        // Enable drag and drop on the image view
        logoImageView.wantsLayer = true
        logoImageView.layer?.cornerRadius = 8
        logoImageView.layer?.borderWidth = 2
        logoImageView.layer?.borderColor = NSColor.systemGray.cgColor
        
        // Setup drag destination
        dragDestination = DragDestinationView(imageView: logoImageView, controller: self)
    }
    
    private func loadCustomLogo() {
        guard let logoImageView = logoImageView,
              let statusLabel = statusLabel else {
            ATHLogger.error("Settings window UI elements not found in loadCustomLogo", category: .ui)
            return
        }
        
        if let logoPath = defaults.string(forKey: CustomLogoConstants.customLogoPathKey),
           let image = NSImage(contentsOfFile: logoPath) {
            logoImageView.image = image
            statusLabel.stringValue = NSLocalizedString("settings.logo.custom_active", comment: "Custom logo active")
            statusLabel.textColor = .systemGreen
        } else {
            // Show default OS logo using ViewController's method
            logoImageView.image = NSImage(named: getOSImageName())
            statusLabel.stringValue = NSLocalizedString("settings.logo.default_active", comment: "Default logo active")
            statusLabel.textColor = .systemGray
        }
    }
    
    private func getOSImageName() -> String {
        // Use the same logic as ViewController
        let osImageNames: [MacOSVersion: String] = [.tahoe: "Tahoe", .sequoia: "Sequoia", .sonoma: "Sonoma", .ventura: "Ventura",
                                                    .monterey: "Monterey", .bigSur: "Big Sur", .catalina: "Catalina",
                                                    .mojave: "Mojave", .highSierra: "High Sierra", .sierra: "Sierra"]
        return osImageNames[HCVersion.shared.osVersion] ?? "Unknown"
    }
    
    // MARK: - Actions
    @IBAction func resetToDefault(_ sender: Any) {
        guard let logoImageView = logoImageView,
              let statusLabel = statusLabel else {
            ATHLogger.error("Settings window UI elements not found in resetToDefault", category: .ui)
            return
        }
        
        defaults.removeObject(forKey: CustomLogoConstants.customLogoPathKey)
        loadCustomLogo()
        
        // Post notification to update the Overview tab
        NotificationCenter.default.post(name: .customLogoDidChange, object: nil)
        
        statusLabel.stringValue = NSLocalizedString("settings.logo.reset_success", comment: "Logo reset to default")
        statusLabel.textColor = .systemGreen
    }
    
    // MARK: - Public Methods
    func handleDroppedImage(at path: String) {
        guard let logoImageView = logoImageView,
              let statusLabel = statusLabel else {
            ATHLogger.error("Settings window UI elements not found in handleDroppedImage", category: .ui)
            return
        }
        
        // Validate image
        guard let image = NSImage(contentsOfFile: path) else {
            showError(NSLocalizedString("settings.logo.error.invalid", comment: "Invalid image file"))
            return
        }
        
        // Check if it's a PNG
        guard path.lowercased().hasSuffix(".png") else {
            showError(NSLocalizedString("settings.logo.error.not_png", comment: "Image must be in PNG format"))
            return
        }
        
        // Check dimensions
        guard let imageRep = image.representations.first else {
            showError(NSLocalizedString("settings.logo.error.no_rep", comment: "Cannot read image dimensions"))
            return
        }
        
        let width = imageRep.pixelsWide
        let height = imageRep.pixelsHigh
        
        guard width == 1024 && height == 1024 else {
            showError(String(format: NSLocalizedString("settings.logo.error.wrong_size", 
                comment: "Image must be 1024x1024 pixels. Current size: %dx%d"), width, height))
            return
        }
        
        // Save the path
        defaults.set(path, forKey: CustomLogoConstants.customLogoPathKey)
        
        // Update display
        logoImageView.image = image
        statusLabel.stringValue = NSLocalizedString("settings.logo.success", comment: "Custom logo applied successfully")
        statusLabel.textColor = .systemGreen
        
        // Post notification to update the Overview tab
        NotificationCenter.default.post(name: .customLogoDidChange, object: nil)
    }
    
    private func showError(_ message: String) {
        guard let statusLabel = statusLabel else {
            ATHLogger.error("Settings window UI elements not found in showError", category: .ui)
            return
        }
        
        statusLabel.stringValue = message
        statusLabel.textColor = .systemRed
        
        // Only shake if motion isn't reduced for accessibility
        if !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            let animation = CAKeyframeAnimation(keyPath: "position.x")
            animation.values = [0, -10, 10, -5, 5, 0]
            animation.keyTimes = [0, 0.2, 0.4, 0.6, 0.8, 1]
            animation.duration = 0.4
            animation.isAdditive = true
            window?.contentView?.layer?.add(animation, forKey: "shake")
        } else {
            // Provide alternative feedback with NSSound for accessibility
            NSSound.beep()
        }
    }
}

// MARK: - Drag Destination Helper
class DragDestinationView: NSView {
    weak var controller: SettingsWindowController?
    weak var targetImageView: NSImageView?
    
    init(imageView: NSImageView, controller: SettingsWindowController) {
        self.targetImageView = imageView
        self.controller = controller
        super.init(frame: imageView.frame)
        
        // Register for drag types
        registerForDraggedTypes([.fileURL])
        
        // Add as subview
        imageView.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: imageView.topAnchor),
            self.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            self.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: imageView.trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        targetImageView?.layer?.borderColor = NSColor.systemBlue.cgColor
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        targetImageView?.layer?.borderColor = NSColor.systemGray.cgColor
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        targetImageView?.layer?.borderColor = NSColor.systemGray.cgColor
        
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              let url = urls.first else {
            return false
        }
        
        controller?.handleDroppedImage(at: url.path)
        return true
    }
}
