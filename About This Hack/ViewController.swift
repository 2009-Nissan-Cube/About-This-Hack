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
        resizeButtonsToFit()
    }
    
    // MARK: - Private Methods
    private func updateUI() {

        // Ensure buttons reflect current titles after UI update
        resizeButtonsToFit()
        
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
        
        CATransaction.commit()
    }

    /// Resize the two action buttons so their widths fit their current titles.
    /// This uses the button's font to measure the title and applies a small padding.
    /// Ensures at least a 10-point gap between the two buttons.
    private func resizeButtonsToFit() {
        guard let sysInfoBtn = btSysInfo, let softUpdBtn = btSoftUpd else { return }
        
        let minGap: CGFloat = 10.0
        let padding: CGFloat = 30.0 // left + right padding
        
        // Measure and resize first button (System Report)
        let sysRptFont = (sysInfoBtn.cell as? NSButtonCell)?.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let sysRptAttrs: [NSAttributedString.Key: Any] = [.font: sysRptFont]
        let sysRptTitleSize = (sysInfoBtn.title as NSString).size(withAttributes: sysRptAttrs)
        let newSysRptTitleWidth = max(44.0, ceil(sysRptTitleSize.width + padding))
        var sysRptButtonFrame = sysInfoBtn.frame
        sysRptButtonFrame.size.width = newSysRptTitleWidth
        sysInfoBtn.frame = sysRptButtonFrame
        
        // Measure and resize second button (Software Update)
        let softUpdFont = (softUpdBtn.cell as? NSButtonCell)?.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let softUpdAttrs: [NSAttributedString.Key: Any] = [.font: softUpdFont]
        let softUpdTitleSize = (softUpdBtn.title as NSString).size(withAttributes: softUpdAttrs)
        let newSoftUpdTitleWidth = max(44.0, ceil(softUpdTitleSize.width + padding))
        var softUpdButtonFrame = softUpdBtn.frame
        softUpdButtonFrame.size.width = newSoftUpdTitleWidth
        
        // Ensure minimum gap: if buttons overlap, shift second button to the right
        let gap = softUpdButtonFrame.origin.x - (sysRptButtonFrame.origin.x + sysRptButtonFrame.size.width)
        if gap < minGap {
            softUpdButtonFrame.origin.x = sysRptButtonFrame.origin.x + sysRptButtonFrame.size.width + minGap
        }
        
        softUpdBtn.frame = softUpdButtonFrame
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
