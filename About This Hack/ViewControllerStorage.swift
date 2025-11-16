import Cocoa

class ViewControllerStorage: NSViewController {

    @IBOutlet weak var startupDiskImage: NSImageView!
    @IBOutlet weak var storageValue: NSTextField!
    @IBOutlet weak var storageAmount: NSLevelIndicatorCell!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.styleMask.remove(.resizable)
        start()
        setToolTips()
    }

    private func start() {
        ATHLogger.info(NSLocalizedString("log.storage.init", comment: "Storage view initializing"), category: .ui)

        // Data is already loaded by WindowController, just update UI
        updateStorageUI()
    }

    private func updateStorageUI() {
        setStartupDiskImage()
        updateStorageInfo()
    }
    
    private func setStartupDiskImage() {
        let imageShortName = "\(HCVersion.shared.osName) \(HardwareCollector.shared.deviceLocation)"
        let storageType = HardwareCollector.shared.storageType ? "SSD" : "HDD"
        
        ATHLogger.debug(String(format: NSLocalizedString("log.storage.image_setting", comment: "Setting storage image"), imageShortName, storageType), category: .hardware)
        
        if let specificImage = NSImage(named: "\(imageShortName) \(storageType)") {
            startupDiskImage.image = specificImage
        } else {
            ATHLogger.debug(String(format: NSLocalizedString("log.storage.image_not_found", comment: "Image not found"), storageType), category: .hardware)
            startupDiskImage.image = NSImage(named: storageType)
        }
    }
    
    private func updateStorageInfo() {
        storageValue.stringValue = HardwareCollector.shared.storageData
        storageAmount.doubleValue = HardwareCollector.shared.storagePercent * storageAmount.maxValue
        
        ATHLogger.debug(String(format: NSLocalizedString("log.storage.updated", comment: "Storage info updated"), HardwareCollector.shared.storageData, String(format: "%.0f", HardwareCollector.shared.storagePercent * 100)), category: .hardware)
    }
    
    private func setToolTips() {
        let t = Tooltips.shared
        startupDiskImage.toolTip = t.startupDiskImagetoolTip
        storageValue.toolTip = t.storageValuetoolTip

        ATHLogger.debug(NSLocalizedString("log.storage.tooltips", comment: "Storage tooltips configured"), category: .ui)
    }
}
