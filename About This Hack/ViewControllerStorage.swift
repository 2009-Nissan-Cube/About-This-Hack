import Cocoa

class ViewControllerStorage: NSViewController {

    @IBOutlet weak var startupDiskImage: NSImageView!
    @IBOutlet weak var storageValue: NSTextField!
    @IBOutlet weak var storageAmount: NSLevelIndicatorCell!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override var representedObject: Any? {
        didSet {
        }
    }

    override func viewDidAppear() {
        self.view.window?.styleMask.remove(.resizable)
        start()
        setToolTips()
    }

    func start() {
        print("Initializing Storage View...")
        
        if (!HardwareCollector.dataHasBeenSet) {
            HardwareCollector.getAllData()
        }

        setStartupDiskImage()
        updateStorageInfo()
    }
    
    private func setStartupDiskImage() {
        let imageShortName = "\(HCVersion.OSname) \(HardwareCollector.devicelocation)"
        let storageType = HardwareCollector.getStorageType() ? "SSD" : "HDD"
        
        if let specificImage = NSImage(named: "\(imageShortName) \(storageType)") {
            startupDiskImage.image = specificImage
        } else {
            startupDiskImage.image = NSImage(named: storageType)
        }
    }
    
    private func updateStorageInfo() {
        storageValue.stringValue = HardwareCollector.storageData
        storageAmount.doubleValue = HardwareCollector.storagePercent * 1_000_000
    }
    
    private func setToolTips() {
        startupDiskImage.toolTip = startupDiskImagetoolTip
        storageValue.toolTip = storageValuetoolTip
    }
}
