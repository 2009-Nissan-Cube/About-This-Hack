import Cocoa

class ViewController: NSViewController {
    // MARK: - IBOutlets
    @IBOutlet private weak var picture: NSImageView!
    @IBOutlet private weak var osVersion: NSTextField!
    @IBOutlet private weak var osPrefix: NSTextField!
    @IBOutlet private weak var systemVersion: NSTextField!
    @IBOutlet private weak var macModel: NSTextField!
    @IBOutlet private weak var cpu: NSTextField!
    @IBOutlet private weak var ram: NSTextField!
    @IBOutlet private weak var graphics: NSTextField!
    @IBOutlet private weak var display: NSTextField!
    @IBOutlet private weak var startupDisk: NSTextField!
    @IBOutlet private weak var serialNumber: NSTextField!
    @IBOutlet private weak var serialToggle: NSButton!
    @IBOutlet private weak var blVersion: NSTextField!
    @IBOutlet private weak var blVersionToggle: NSButton!
    @IBOutlet private weak var blPrefix: NSTextField!
    @IBOutlet private weak var creditText: NSTextField!
    @IBOutlet private weak var btSysInfo: NSButton!
    @IBOutlet private weak var btSoftUpd: NSButton!
    
    // MARK: - Properties
    private lazy var osNumber = ProcessInfo.processInfo.operatingSystemVersionString
    private let modelID = "Mac", ocLevel = "Unknown", ocVersionID = "Version"
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Don't initialize UI until all data is ready
        
        // Hide creditText immediately to prevent it from being visible during startup
        // It will be shown/hidden appropriately in updateUI() based on OS version
        creditText.isHidden = true
        creditText.alphaValue = 0
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.styleMask.remove(.resizable)

        // Only update UI if data is already loaded
        if HardwareCollector.shared.dataHasBeenSet {
            updateUI()
        }
    }

    // Called by WindowController after data is loaded
    func updateUIAfterDataLoaded() {
        updateUI()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        setToolTips()
    }
    
    // MARK: - Private Methods
    private func updateUI() {
        // Ensure we're on the main thread
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.updateUI()
            }
            return
        }
        
        // Data should already be loaded by now
        guard HardwareCollector.shared.dataHasBeenSet else {
            return
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        picture.image = NSImage(named: getOSImageName())
        osVersion.stringValue = HCVersion.shared.osName
        systemVersion.stringValue = "\(HCVersion.shared.osNumber) (\(HCVersion.shared.osBuildNumber))"
        
        let macNamePart = HCMacModel.shared.macName
        let modelIdentifierPart = HCMacModel.shared.getModelIdentifier()
        let fullMacModelString = "\(macNamePart) - \(modelIdentifierPart)"
        if fullMacModelString.count > 60 {
            macModel.stringValue = macNamePart
        } else {
            macModel.stringValue = fullMacModelString
        }

        cpu.stringValue = HCCPU.shared.getCPU()
        ram.stringValue = HCRAM.shared.getRam()
        graphics.stringValue = HCGPU.shared.getGPU()
        display.stringValue = HCDisplay.shared.getDisp()
        startupDisk.stringValue = HCStartupDisk.shared.getStartupDisk()
        serialNumber.stringValue = HCSerialNumber.shared.getSerialNumber()
        blVersion.stringValue = HCBootloader.shared.getBootloader()
        
        serialToggle.isBordered = false
        serialToggle.isTransparent = false
        blPrefix.isHidden = false
        blVersion.isHidden = false
        
        // Show credits text - no longer needs to be hidden in Tahoe since
        // we've adjusted the window size to accommodate the increased toolbar height
        creditText.isHidden = false
        creditText.alphaValue = 1
        
        CATransaction.commit()
    }
    
    private func getOSImageName() -> String {
        let osImageNames: [MacOSVersion: String] = [.tahoe: "Tahoe", .sequoia: "Sequoia", .sonoma: "Sonoma", .ventura: "Ventura",
                                                    .monterey: "Monterey", .bigSur: "Big Sur", .catalina: "Catalina",
                                                    .mojave: "Mojave", .highSierra: "High Sierra", .sierra: "Sierra"]
        return osImageNames[HCVersion.shared.osVersion] ?? "Unknown"
    }
    
    private func setToolTips() {
        let t = Tooltips.shared
        let tooltips: [(NSView, String?)] = [
            (osVersion, t.osVersiontoolTip),
            (systemVersion, t.systemVersiontoolTip),
            (macModel, t.macModeltoolTip),
            (cpu, t.cputoolTip),
            (ram, t.ramtoolTip),
            (startupDisk, t.startupDisktoolTip),
            (display, t.displaytoolTip),
            (graphics, t.graphicstoolTip),
            (serialToggle, t.serialToggletoolTip),
            (blVersion, t.blVersiontoolTip),
            (btSysInfo, t.btSysInfotoolTip),
            (btSoftUpd, t.btSoftUpdtoolTip)
        ]

        tooltips.forEach { view, tooltip in
            view.toolTip = trimTooltip(tooltip)
        }
    }

    private func trimTooltip(_ tooltip: String?) -> String? {
        tooltip?.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: "\n")
    }
    
    // MARK: - IBActions
    @IBAction func hideSerialNumber(_ sender: NSButton) {
        serialNumber.isHidden = !serialNumber.isHidden
    }
    
    @IBAction func showSystemReport(_ sender: NSButton) {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/SystemProfiler/SPPlatformReporter.spreporter"))
    }
    
    @IBAction func showSoftwareUpdate(_ sender: NSButton) {
        let softwareUpdatePath = "/System/Library/PreferencePanes/SoftwareUpdate.prefPane"
        NSWorkspace.shared.open(URL(fileURLWithPath: FileManager.default.fileExists(atPath: softwareUpdatePath) ? softwareUpdatePath : "\(InitGlobVar.allAppliLocation)/App Store.app"))
    }
}
