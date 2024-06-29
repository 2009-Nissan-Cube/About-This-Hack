import Cocoa

class ViewControllerDisplays: NSViewController {
    
    @IBOutlet weak var DisplayPicCenter: NSImageView!
    @IBOutlet weak var DisplayPicL1: NSImageView!
    @IBOutlet weak var DisplayPicL2: NSImageView!
    @IBOutlet weak var DisplayPicR1: NSImageView!
    @IBOutlet weak var DisplayPicR2: NSImageView!
    
    @IBOutlet weak var DisplaySizeResCenter: NSTextField!
    @IBOutlet weak var DisplaySizeResL1: NSTextField!
    @IBOutlet weak var DisplaySizeResL2: NSTextField!
    @IBOutlet weak var DisplaySizeResR1: NSTextField!
    @IBOutlet weak var DisplaySizeResR2: NSTextField!
    
    @IBOutlet weak var DisplayNameCenter: NSTextField!
    @IBOutlet weak var DisplayNameL1: NSTextField!
    @IBOutlet weak var DisplayNameL2: NSTextField!
    @IBOutlet weak var DisplayNameR1: NSTextField!
    @IBOutlet weak var DisplayNameR2: NSTextField!
    
    @IBAction func openPrefsDispl(_ sender: Any) {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.displays") {
            NSWorkspace.shared.open(url)
        }
    }
    
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
    }
    
    func start() {
        print("Initializing Display View...")
        if (!HardwareCollector.dataHasBeenSet) { HardwareCollector.getAllData() }
        
        let dispArr: [NSImageView] = [DisplayPicCenter, DisplayPicL1, DisplayPicL2, DisplayPicR1, DisplayPicR2]
        let nameArr: [NSTextField] = [DisplayNameCenter, DisplayNameL1, DisplayNameL2, DisplayNameR1, DisplayNameR2]
        let labelArr2: [NSTextField] = [DisplaySizeResCenter, DisplaySizeResL1, DisplaySizeResL2, DisplaySizeResR1, DisplaySizeResR2]
        
        // Hide all display elements initially
        (dispArr + nameArr + labelArr2).forEach { $0.isHidden = true }
        
        print("HardwareCollector.displayNames = \"\(HardwareCollector.displayNames)\"")
        print("HardwareCollector.displayRes = \"\(HardwareCollector.displayRes)\"")
        
        let numDisplays = min(HardwareCollector.numberOfDisplays, 3)  // Limit to 3 displays
        
        switch numDisplays {
        case 1:
            showDisplay(index: 0, imageView: DisplayPicCenter, nameField: DisplayNameCenter, resField: DisplaySizeResCenter)
        case 2:
            showDisplay(index: 0, imageView: DisplayPicL2, nameField: DisplayNameL2, resField: DisplaySizeResL2)
            showDisplay(index: 1, imageView: DisplayPicR2, nameField: DisplayNameR2, resField: DisplaySizeResR2)
        case 3:
            showDisplay(index: 0, imageView: DisplayPicCenter, nameField: DisplayNameCenter, resField: DisplaySizeResCenter)
            showDisplay(index: 1, imageView: DisplayPicL1, nameField: DisplayNameL1, resField: DisplaySizeResL1)
            showDisplay(index: 2, imageView: DisplayPicR1, nameField: DisplayNameR1, resField: DisplaySizeResR1)
        default:
            break
        }
    }

    private func showDisplay(index: Int, imageView: NSImageView, nameField: NSTextField, resField: NSTextField) {
        imageView.isHidden = false
        
        if index < HardwareCollector.displayNames.count {
            nameField.isHidden = false
            nameField.stringValue = HardwareCollector.displayNames[index]
            print("DisplayName: \"\(HardwareCollector.displayNames[index])\"")
            
            setDisplayImage(imageView, for: HardwareCollector.displayNames[index])
        }
        
        if index < HardwareCollector.displayRes.count {
            resField.isHidden = false
            resField.stringValue = HardwareCollector.displayRes[index]
            print("DisplayReso: \"\(HardwareCollector.displayRes[index])\"")
        }
    }
    
    private func setDisplayImage(_ imageView: NSImageView, for displayName: String) {
        let imageName: String
        switch displayName {
        case "iMac":
            imageName = "NSComputer"
        case "LG HDR 4K":
            imageName = "LG4K"
        case "Sidecar Display":
            imageName = "ipad"
        case "LED Cinema Display":
            imageName = "appledisp"
        default:
            imageName = "genericLCD"
        }
        imageView.image = NSImage(named: imageName)
    }
}
