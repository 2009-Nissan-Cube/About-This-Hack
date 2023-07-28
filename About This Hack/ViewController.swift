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

        _ = run("mkdir ~/.ath")
        print("Directory created...")
        func createFileIfNeeded(atPath path: String, withCommand command: String) {
            let fileManager = FileManager.default

            if !fileManager.fileExists(atPath: path) {
                _ = run(command)
            }
        }

        // Example usage
        let homeDirectory = NSHomeDirectory()
        let hwFilePath = homeDirectory + "/.ath/hw.txt"
        let sysmemFilePath = homeDirectory + "/.ath/sysmem.txt"
        let sysvolnameFilePath = homeDirectory + "/.ath/sysvolname.txt"
        let scrFilePath = homeDirectory + "/.ath/scr.txt"
        let scrXmlFilePath = homeDirectory + "/.ath/scrXml.txt"

        createFileIfNeeded(atPath: hwFilePath, withCommand: "system_profiler SPHardwareDataType > \"\(hwFilePath)\"")
        createFileIfNeeded(atPath: sysmemFilePath, withCommand: "system_profiler SPMemoryDataType > \"\(sysmemFilePath)\"")
        createFileIfNeeded(atPath: sysvolnameFilePath, withCommand: "diskutil info / > \"\(sysvolnameFilePath)\"")
        createFileIfNeeded(atPath: scrFilePath, withCommand: "system_profiler SPDisplaysDataType > \"\(scrFilePath)\"")
        createFileIfNeeded(atPath: scrXmlFilePath, withCommand: "system_profiler SPDisplaysDataType -xml > \"\(scrXmlFilePath)\"")
        print("Files created...")
        
        // Call Functions to init Overview
        HCVersion.getVersion()
        HCMacModel.getMacModel()
        _ = HCCPU.getCPU()
        _ = HCRAM.getRam()
        _ = HCStartupDisk.getStartupDisk()
        _ = HCDisplay.getDisp()
        
    }
    

    override var representedObject: Any? {
        didSet {
        }
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
        
        // Call Start Function
        self.start()
    }
    
    
    func start() {
        print("Initializing...")
        
        switch HCVersion.OSvers {
        case .SONOMA:
            picture.image = NSImage(named: "Sonoma")
            break
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
        osVersion.stringValue = HCVersion.OSname

        // macOS Version ID
        systemVersion.stringValue = HCVersion.getOSnum() + HCVersion.OSBuildNum

        // Mac Model
        macModel.stringValue = HCMacModel.macName + " - " + HCMacModel.getModelIdentifier()

        // CPU
        cpu.stringValue = HCCPU.getCPU()
        
        // RAM
        ram.stringValue = HCRAM.getRam()

        // GPU
        graphics.stringValue = HCGPU.getGPU()

        // Display
        display.stringValue = HCDisplay.getDisp()

        // Startup Disk
        startupDisk.stringValue = HCStartupDisk.getStartupDisk()

        // Serial Number
        serialNumber.stringValue = HCSerialNumber.getSerialNumber()

        // Bootloader Version (Optional)
        blVersion.stringValue = HCBootloader.getBootloader()

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
    
    @IBAction func hideSerialNumber(_ sender: NSButton) {
        print("Serial Number toggled")
        if serialNumber.stringValue == "" {
            serialNumber.stringValue = HCSerialNumber.getSerialNumber()
        } else {
            serialNumber.stringValue = ""
        }
    }

    func showSerialNumber(_ sender: NSButton) {
          print("Serial Number toggled")
          if serialNumber.stringValue == HCSerialNumber.getSerialNumber() {
              serialNumber.stringValue = ""
          } else {
              serialNumber.stringValue = HCSerialNumber.getSerialNumber()
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
