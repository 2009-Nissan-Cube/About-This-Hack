//
//  ViewController.swift
//  About This Hack
//
//  Created by AvaQueen on 8/20/21.
//

// NOTE: This code is horribly unoptimized. If you find anything at all that can make it better, please change it. This is my first time making a storyboard app this complicated.

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var picture: NSImageView!
    @IBOutlet weak var systemVersion: NSTextField!
    @IBOutlet weak var macModel: NSTextField!
    @IBOutlet weak var cpu: NSTextField!
    @IBOutlet weak var ram: NSTextField!
    @IBOutlet weak var graphics: NSTextField!
    @IBOutlet weak var display: NSTextField!
    @IBOutlet weak var startupDisk: NSTextField!
    @IBOutlet weak var serialNumber: NSTextField!
    @IBOutlet weak var ocVersion: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view
    }

    override var representedObject: Any? {
        didSet {
            
        }
    }

    override func viewDidAppear() {
        self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
    }
    
    init() {
        var modelID: String
        
        systemVersion.stringValue = (try? call("sw_vers | grep ProductVersion | cut -c 17-")) ?? "11.0"
        //modelID = (try? (try? call("'/Applications/About This Hack.app/Contents/Resources/modelID.sh'")) ?? call("sysctl -n hw.model")) ?? "Mac"
        let hardwareCache = (try? call("system_profiler SPHardwareDataType")) ?? "Some data idk lol"
        serialNumber.stringValue = (try? call("echo \"\(hardwareCache)\" | awk '/Serial/ {print $4}'")) ?? "Serial # not found"
        print("Serial Number: \(String(describing: serialNumber))")
        
        macModel.stringValue = (try? call("""
 /usr/libexec/PlistBuddy -c "print :'CPU Names':$(echo \"\(hardwareCache)\" | awk '/Serial/ {print $4}' | cut -c 9-)-en-US_US" ~/Library/Preferences/com.apple.SystemProfiler.plist
 """)) ?? "Unknown Model"

        ram.stringValue = (try? call("echo \"$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))\"")) ?? "RAM Error"
        print("\(String(describing: ram)) GB")
        ram.stringValue = "\(String(describing: ram)) GB"
        let ramInfoCache = (try? call("system_profiler SPMemoryDataType")) ?? "RAM Error"
        let ramSpeedTmp = (try? call("echo \"\(ramInfoCache)\" | grep Speed:")) ?? "RAM Error"
        let ramSpeedID = ramSpeedTmp.firstIndex(of: "\n")!
        let ramSpeedTrim1 = String(ramSpeedTmp[ramSpeedID...])
        print(ramSpeedTrim1)
        let ramSpeedID1 = ramSpeedTrim1.firstIndex(of: ":")!
        let ramSpeedTrim2 = String(ramSpeedTrim1[ramSpeedID1...])
        let ramSpeedID2 = ramSpeedTrim2.firstIndex(of: " ")!
        var ramSpeedTrim3 = String(ramSpeedTrim2[ramSpeedID2...])
        if(ramSpeedTrim3.contains("\n")) {
            let ramID = ramSpeedTrim3.firstIndex(of: "\n")!
            let ramTrimFinal = String(ramSpeedTrim3[..<ramID])
            ramSpeedTrim3 = ramTrimFinal
        }
        ram.stringValue = "\(String(describing: ram))\(ramSpeedTrim3)"
        
        let ramType = (try? call("echo \"\(ramInfoCache)\" | grep Type: | cut -c 16-")) ?? "RAM Error"
        let ramTypeID = ramType.firstIndex(of: "\n")!
        let ramTypeTrim = String(ramType[ramTypeID...])
        let ramTypeID1 = ramTypeTrim.firstIndex(of: " ")!
        let ramTypeTrim1 = String(ramTypeTrim[ramTypeID1...])
        var ramTypeOfficial = ramTypeTrim1
        if(ramTypeTrim1.contains("\n")) {
            let ramTypeID2 = ramTypeTrim1.firstIndex(of: "\n")!
            let ramTypeTrim2 = String(ramTypeTrim1[..<ramTypeID2])
            ramTypeOfficial = ramTypeTrim2
        }
        ram.stringValue = "\(String(describing: ram))\(ramTypeOfficial)"
        ram.needsDisplay = true
        
        cpu.stringValue = (try? call("sysctl -n machdep.cpu.brand_string")) ?? "Whoopsie"
        cpu.needsDisplay = true
        
        let displaysCache = (try? call("system_profiler SPDisplaysDataType")) ?? "Unknown GPU"
        graphics.stringValue = (try? call("echo \"\(displaysCache)\" | awk -F': ' '/^\\ *Chipset Model:/ {printf $2 \" \"}'")) ?? "Unknown GPU"
        // system_profiler SPDisplaysDataType | grep VRAM | cut -c 28-
        let graphicsRAM  = (try? call("echo \"\(displaysCache)\" | grep VRAM | sed 's/.*: //'")) ?? "Unknown GPU RAM"
        graphics.stringValue = "\(String(describing: graphics))\(graphicsRAM)"
        
        display.stringValue = (try? call("echo \"\(displaysCache)\" | grep Resolution | sed 's/.*: //'")) ?? "Unknown Display"
        if display.stringValue.contains("(QHD"){
            display.stringValue = (try? call("echo \"\(displaysCache)\" | grep Resolution | sed 's/.*: //' | cut -c -11")) ?? "Unknown Display"
        }
        if(display.stringValue.contains("\n")) {
            let displayID = display.stringValue.firstIndex(of: "\n")!
            let displayTrimmed = String(display.stringValue[..<displayID])
            display.stringValue = displayTrimmed
        }
        
        var opencore1: String
        var opencore2: String
        var opencore3: String
        var opencoreType: String
        opencore1 = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 59- | cut -c -1")) ?? "X"
        opencore2 = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 60- | cut -c -1")) ?? "X"
        opencore3 = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 61- | cut -c -1")) ?? "X"
        opencoreType = (try? call("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | cut -c 55- | cut -c -3")) ?? "N/A"
        if opencoreType == "REL" {
            opencoreType = "(Release)"
        } else if opencoreType == "N/A" {
            opencoreType = ""
        } else {
            opencoreType = "(Debug)"
        }
        ocVersion.stringValue = "\(opencore1).\(opencore2).\(opencore3) \(opencoreType)"
        
        
        // thanks AstroKid for helping out with making "display" work with macOS 12 Monterey
        
        if(systemVersion.stringValue.hasPrefix("12")) {
            picture.image = NSImage(named: "Dark Monterey")
        }
        else if(systemVersion.stringValue.hasPrefix("11")) {
            picture.image = NSImage(named: "Dark Sur")
        }
        else {
            picture.image = NSImage(named: "Unknown")
        }
        
        
        // Startup Disk
        startupDisk.stringValue = (try? call("system_profiler SPSoftwareDataType | grep 'Boot Volume' | sed 's/.*: //'")) ?? "Macintosh HD"
        print(startupDisk ?? "Error")
        modelID = (try? call("sysctl hw.model | cut -f2 -d \" \"")) ?? "Mac"
        // curl -s 'https://support-sp.apple.com/sp/product?cc='$(system_profiler SPHardwareDataType | awk '/Serial/ {print $4}' | cut -c 9-)  | sed 's|.*<configCode>\(.*\)</configCode>.*|\1|'
        
        print("MAC: \(String(describing: macModel))")
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
    }
}

