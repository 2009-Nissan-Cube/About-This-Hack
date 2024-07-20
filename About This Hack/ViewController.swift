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
    @IBOutlet private weak var blPrefix: NSTextField!
    @IBOutlet private weak var creditText: NSTextField!
    @IBOutlet private weak var btSysInfo: NSButton!
    @IBOutlet private weak var btSoftUpd: NSButton!
    
    // MARK: - Properties
    
    private lazy var osNumber = ProcessInfo.processInfo.operatingSystemVersionString
    private let modelID = "Mac"
    private let ocLevel = "Unknown"
    private let ocVersionID = "Version"
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.initializeOverview()
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view if the represented object changes.
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window?.styleMask.remove(.resizable)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        updateUI()
        setToolTips()
    }
    
    // MARK: - Private Methods
    
    private func initializeOverview() {
        DispatchQueue.concurrentPerform(iterations: 7) { index in
            switch index {
            case 0: HCVersion.getVersion()
            case 1: HCMacModel.getMacModel()
            case 2: _ = HCCPU.getCPU()
            case 3: _ = HCRAM.getRam()
            case 4: _ = HCStartupDisk.getStartupDisk()
            case 5: _ = HCDisplay.getDisp()
            case 6: _ = HCGPU.getGPU()
            default: break
            }
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateUI()
        }
    }
    
    private func updateUI() {
        if !HardwareCollector.dataHasBeenSet {
            HardwareCollector.getAllData()
        }
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        picture.image = NSImage(named: getOSImageName())
        osVersion.stringValue = HCVersion.OSname
        systemVersion.stringValue = HCVersion.getOSnum() + HCVersion.getOSbuild()
        macModel.stringValue = "\(HCMacModel.macName) - \(HCMacModel.getModelIdentifier())"
        cpu.stringValue = HCCPU.getCPU()
        ram.stringValue = HCRAM.getRam()
        graphics.stringValue = HCGPU.getGPU()
        display.stringValue = HCDisplay.getDisp()
        startupDisk.stringValue = HCStartupDisk.getStartupDisk()
        serialNumber.stringValue = HCSerialNumber.getSerialNumber()
        blVersion.stringValue = HCBootloader.getBootloader()
        serialToggle.isTransparent = true
        
        CATransaction.commit()
    }
    
    private func getOSImageName() -> String {
        let osImageNames: [macOSvers: String] = [
            .SEQUOIA: "Sequoia", .SONOMA: "Sonoma", .VENTURA: "Ventura",
            .MONTEREY: "Monterey", .BIG_SUR: "Big Sur", .CATALINA: "Catalina",
            .MOJAVE: "Mojave", .HIGH_SIERRA: "High Sierra", .SIERRA: "Sierra"
        ]
        return osImageNames[HCVersion.OSvers] ?? "Unknown"
    }
    
    private func setToolTips() {
        let tooltips: [(NSView, String?)] = [
            (osVersion, osVersiontoolTip),
            (systemVersion, systemVersiontoolTip),
            (macModel, macModeltoolTip),
            (cpu, cputoolTip),
            (ram, ramtoolTip),
            (startupDisk, startupDisktoolTip),
            (display, displaytoolTip),
            (graphics, graphicstoolTip),
            (serialToggle, serialToggletoolTip),
            (blVersion, blVersiontoolTip),
            (btSysInfo, btSysInfotoolTip),
            (btSoftUpd, btSoftUpdtoolTip)
        ]
        
        tooltips.forEach { view, tooltip in
            view.toolTip = trimTooltip(tooltip)
        }
    }

    private func trimTooltip(_ tooltip: String?) -> String? {
        guard let tooltip = tooltip else { return nil }
        let lines = tooltip.components(separatedBy: .newlines)
        let nonEmptyLines = lines.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        return nonEmptyLines.joined(separator: "\n")
    }
    
    // MARK: - IBActions
    
    @IBAction func hideSerialNumber(_ sender: NSButton) {
        toggleSerialNumber()
    }
    
    @IBAction func showSystemReport(_ sender: NSButton) {
        print("System Report...")
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/SystemProfiler/SPPlatformReporter.spreporter"))
    }
    
    @IBAction func showSoftwareUpdate(_ sender: NSButton) {
        print("Software Update...")
        let softwareUpdatePath = "/System/Library/PreferencePanes/SoftwareUpdate.prefPane"
        if FileManager.default.fileExists(atPath: softwareUpdatePath) {
            NSWorkspace.shared.open(URL(fileURLWithPath: softwareUpdatePath))
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: "\(initGlobVar.allAppliLocation)/App Store.app"))
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleSerialNumber() {
        print("Serial Number toggled")
        serialNumber.stringValue = serialNumber.stringValue.isEmpty ? HCSerialNumber.getSerialNumber() : ""
    }
}
