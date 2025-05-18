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
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.initializeOverview()
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
        let tasks = [
            { HCVersion.shared.getVersion() },
            { HCMacModel.shared.getMacModel() },
            { _ = HCCPU.shared.getCPU() },
            { _ = HCRAM.shared.getRam() },
            { _ = HCStartupDisk.shared.getStartupDisk() },
            { _ = HCDisplay.shared.getDisp() },
            { _ = HCGPU.shared.getGPU() }
        ]
        DispatchQueue.concurrentPerform(iterations: tasks.count) { tasks[$0]() }
        DispatchQueue.main.async { [weak self] in self?.updateUI() }
    }
    
    private func updateUI() {
        if !HardwareCollector.shared.dataHasBeenSet {
            HardwareCollector.shared.getAllData()
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
        
        serialToggle.isTransparent = true
        blVersionToggle.isTransparent = true
        blPrefix.isHidden = false
        blVersion.isHidden = false
        
        CATransaction.commit()
    }
    
    private func getOSImageName() -> String {
        let osImageNames: [MacOSVersion: String] = [.sequoia: "Sequoia", .sonoma: "Sonoma", .ventura: "Ventura",
                                                    .monterey: "Monterey", .bigSur: "Big Sur", .catalina: "Catalina",
                                                    .mojave: "Mojave", .highSierra: "High Sierra", .sierra: "Sierra"]
        return osImageNames[HCVersion.shared.osVersion] ?? "Unknown"
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
        tooltip?.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            .joined(separator: "\n")
    }
    
    // MARK: - IBActions
    @IBAction func hideSerialNumber(_ sender: NSButton) {
        serialNumber.isHidden = !serialNumber.isHidden
    }
    
//    @IBAction func hideBlVersion(_ sender: NSButton) {
//        if (blPrefix.isHidden) {
//            blPrefix.isHidden = false
//            blVersion.isHidden = false
//        } else {
//            blPrefix.isHidden = true
//            blVersion.isHidden = true
//        }
//    }
    
    @IBAction func showSystemReport(_ sender: NSButton) {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/SystemProfiler/SPPlatformReporter.spreporter"))
    }
    
    @IBAction func showSoftwareUpdate(_ sender: NSButton) {
        let softwareUpdatePath = "/System/Library/PreferencePanes/SoftwareUpdate.prefPane"
        NSWorkspace.shared.open(URL(fileURLWithPath: FileManager.default.fileExists(atPath: softwareUpdatePath) ? softwareUpdatePath : "\(InitGlobVar.allAppliLocation)/App Store.app"))
    }
}
