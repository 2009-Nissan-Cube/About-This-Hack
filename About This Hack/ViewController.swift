import Cocoa

class ViewController: NSViewController {
    
    
    // MARK: IBOutlets Overview
    
    @IBOutlet weak var picture: NSImageView!
    @IBOutlet weak var osVersion: NSTextField!
    @IBOutlet weak var osPrefix: NSTextField!
    @IBOutlet weak var systemVersion: NSTextField!
    @IBOutlet weak var macModel: NSTextField!
    @IBOutlet weak var cpu: NSTextField!
    @IBOutlet weak var ram: NSTextField!
    @IBOutlet weak var graphics: NSTextField!
    @IBOutlet weak var display: NSTextField!
    @IBOutlet weak var startupDisk: NSTextField!
    @IBOutlet weak var serialNumber: NSTextField!
    @IBOutlet weak var serialToggle: NSButton!
    @IBOutlet weak var blVersion: NSTextField!
    @IBOutlet weak var blPrefix: NSTextField!
    @IBOutlet weak var creditText: NSTextField!
    
    @IBOutlet weak var btSysInfo: NSButton!
    @IBOutlet weak var btSoftUpd: NSButton!
    
    var osNumber = run("sw_vers | grep ProductVersion | cut -c 17-")
    var modelID = "Mac"
    var ocLevel = "Unknown"
    var ocVersionID = "Version"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        start()
        
    }
    

    override var representedObject: Any? {
        didSet {
        }
    }

    override func viewDidAppear() {
        self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
    }
    

    func start() {
        print("Initializing...")
        HardwareCollector.getAllData()
        
        // Image
        switch HardwareCollector.OSvers {
        case .SONOMA:
            picture.image = NSImage(named: "Sonoma")
        case .VENTURA:
            picture.image = NSImage(named: "Ventura")
            break
        case .MONTEREY:
            picture.image = NSImage(named: "Monterey")
            break
        case .BIG_SUR:
            picture.image = NSImage(named: "Big Sur")
            break
        case .CATALINA:
            picture.image = NSImage(named: "Catalina")
            break
        case .MOJAVE:
            picture.image = NSImage(named: "Mojave")
            break
        case .HIGH_SIERRA:
            picture.image = NSImage(named: "High Sierra")
            break
        case .SIERRA:
            picture.image = NSImage(named: "Sierra")
            break
        case .EL_CAPITAN:
            picture.image = NSImage(named: "El Capitan")
            break
        case .YOSEMITE:
            picture.image = NSImage(named: "Yosemite")
            break
        case .MAVERICKS:
            picture.image = NSImage(named: "Mavericks")
            break
        case .macOS:
            picture.image = NSImage(named: "Unknown")
            break
        }
        // macOS Version Name
        osVersion.stringValue = HardwareCollector.OSname
        
        // macOS Version ID
        systemVersion.stringValue = HardwareCollector.OSBuildNum
        
        // Mac Model
        macModel.stringValue = HardwareCollector.macName
        
        // CPU
        cpu.stringValue = HardwareCollector.CPUstring
        
        // RAM
        ram.stringValue = HardwareCollector.RAMstring
        
        // GPU
        graphics.stringValue = HardwareCollector.GPUstring
        
        // Display
        display.stringValue = HardwareCollector.DisplayString
        
        // Startup Disk
        startupDisk.stringValue = HardwareCollector.StartupDiskString
        
        // Serial Number
        serialNumber.stringValue = HardwareCollector.SerialNumberString
        
        // Bootloader Version (Optional)
        blVersion.stringValue = HardwareCollector.BootloaderString
        
        // Make Serial Number Toggle Transparent
        serialToggle.isTransparent = true
        
        // Add credit text
    }

    
    func updateView() {
        picture.needsDisplay = true
        osVersion.needsDisplay = true
        systemVersion.needsDisplay = true
        macModel.needsDisplay = true
        cpu.needsDisplay = true
        ram.needsDisplay = true
        graphics.needsDisplay = true
        display.needsDisplay = true
        startupDisk.needsDisplay = true
        serialNumber.needsDisplay = true
        blVersion.needsDisplay = true
    }
    
//    @IBAction func hideSerialNumber(_ sender: NSButton) {
//        print("Serial Number toggled")
//        if serialNumber.stringValue == "" {
//            serialNumber.stringValue = HardwareCollector.SerialNumberString
//        } else {
//            serialNumber.stringValue = ""
//        }
//    }

     @IBAction func hideSerialNumber(_ sender: NSButton) {
          print("Serial Number toggled")
          if serialNumber.stringValue == HardwareCollector.SerialNumberString {
              serialNumber.stringValue = ""
          } else {
              serialNumber.stringValue = HardwareCollector.SerialNumberString
          }
      }
    
    @IBAction func showSystemReport(_ sender: NSButton) {
        print("System Report...")
        _ = run("open /System/Library/SystemProfiler/SPPlatformReporter.spreporter")
    }
        
    @IBAction func showSoftwareUpdate(_ sender: NSButton) {
        print("Software Update...")
        _ = run("open /System/Library/PreferencePanes/SoftwareUpdate.prefPane")
    }
}
