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
        ATHLogger.info("Initializing Storage View...", category: .ui)
        
        if (!HardwareCollector.shared.dataHasBeenSet) {
            HardwareCollector.shared.getAllData()
        }

        setStartupDiskImage()
        updateStorageInfo()
    }
    
    private func setStartupDiskImage() {
        let imageShortName = "\(HCVersion.shared.osName) \(HardwareCollector.shared.deviceLocation)"
        let storageType = HardwareCollector.shared.storageType ? "SSD" : "HDD"
        
        ATHLogger.debug("Setting storage image: \(imageShortName) \(storageType)", category: .hardware)
        
        if let specificImage = NSImage(named: "\(imageShortName) \(storageType)") {
            startupDiskImage.image = specificImage
        } else {
            ATHLogger.debug("Specific image not found, using generic \(storageType) image", category: .hardware)
            startupDiskImage.image = NSImage(named: storageType)
        }
    }
    
    private func updateStorageInfo() {
        storageValue.stringValue = HardwareCollector.shared.storageData
        storageAmount.doubleValue = HardwareCollector.shared.storagePercent * storageAmount.maxValue
        
        ATHLogger.debug("Updated storage info: \(HardwareCollector.shared.storageData), \(HardwareCollector.shared.storagePercent * 100)%", category: .hardware)
    }
    
    private func setToolTips() {
        startupDiskImage.toolTip = startupDiskImagetoolTip
        storageValue.toolTip = storageValuetoolTip
        
        ATHLogger.debug("Storage tooltips configured", category: .ui)
    }
}
