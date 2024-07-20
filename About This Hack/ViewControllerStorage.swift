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
        print("Initializing Storage View...")
        
        if (!HardwareCollector.shared.dataHasBeenSet) {
            HardwareCollector.shared.getAllData()
        }

        setStartupDiskImage()
        updateStorageInfo()
    }
    
    private func setStartupDiskImage() {
        let imageShortName = "\(HCVersion.shared.osName) \(HardwareCollector.shared.deviceLocation)"
        let storageType = HardwareCollector.shared.storageType ? "SSD" : "HDD"
        
        if let specificImage = NSImage(named: "\(imageShortName) \(storageType)") {
            startupDiskImage.image = specificImage
        } else {
            startupDiskImage.image = NSImage(named: storageType)
        }
    }
    
    private func updateStorageInfo() {
        storageValue.stringValue = HardwareCollector.shared.storageData
        storageAmount.doubleValue = HardwareCollector.shared.storagePercent * storageAmount.maxValue
    }
    
    private func setToolTips() {
        startupDiskImage.toolTip = startupDiskImagetoolTip
        storageValue.toolTip = storageValuetoolTip
    }
}
