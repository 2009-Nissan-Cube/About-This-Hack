//
//  ViewControllerDisplays.swift
//  ViewControllerDisplays
//
//

import Foundation
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
        _ = run("open " + initGlobVar.displayPrefPane)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    

    override var representedObject: Any? {
        didSet {
        }
    }

    override func viewDidAppear() {
        self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
        start()
    }
    
    func start() {
        print("Initializing Display View...")
        if (!HardwareCollector.dataHasBeenSet) {HardwareCollector.getAllData()}
        var dispArr: [NSImageView] = []
        var nameArr: [NSTextField] = []
        var labelArr2: [NSTextField] = []
        if (HardwareCollector.macType == .DESKTOP) {
            DisplayPicCenter.image = NSImage(named: "genericLCD")
        }
        print("Test")
        print("HardwareCollector.displayNames = \"\(HardwareCollector.displayNames)\"")
        print("HardwareCollector.displayRes = \"\(HardwareCollector.displayRes)\"")

        switch (HardwareCollector.numberOfDisplays) {
        case 1:
            print("1 Display Detected")
            dispArr.append(DisplayPicCenter)
            if (HardwareCollector.macType == .DESKTOP) {
                DisplayPicCenter.image = NSImage(named: "genericLCD")
            }
            DisplayPicCenter.isHidden = false
            DisplayNameCenter.isHidden = false
            DisplayNameCenter.stringValue = HardwareCollector.displayNames[0]
            DisplaySizeResCenter.isHidden = false
            DisplaySizeResCenter.stringValue = HardwareCollector.displayRes[0]
            print("DisplayName: \"\(HardwareCollector.displayNames[0])\"")
            print("DisplayReso: \"\(HardwareCollector.displayRes[0])\"")
            break
        case 2:
            print("2 Displays Detected")
            labelArr2.append(DisplaySizeResL2)
            labelArr2.append(DisplaySizeResR2)
            nameArr.append(DisplayNameL2)
            nameArr.append(DisplayNameR2)
            dispArr.append(DisplayPicL2)
            dispArr.append(DisplayPicR2)
            
            if (HardwareCollector.macType == .DESKTOP) {
                let indiceArray = [0,1]
                indiceArray.forEach { i in
                    if i <= (HardwareCollector.displayNames.count-1) {
                        nameArr[i].isHidden = false
                        nameArr[i].stringValue = HardwareCollector.displayNames[i]
                        print("DisplayName: \"\(HardwareCollector.displayNames[i])\"")
                        if (!(HardwareCollector.displayNames[i] == "LG HDR 4K")) {dispArr[i].image = NSImage(named: "genericLCD")}
                        else {
                            dispArr[i].image = NSImage(named: "LG4K")
                        }
                    }
                    if i <= (HardwareCollector.displayRes.count-1) {
                        labelArr2[i].isHidden = false
                        labelArr2[i].stringValue = HardwareCollector.displayRes[i]
                        print("DisplayReso: \"\(HardwareCollector.displayRes[i])\"")
                    }
                }
            }
            else {
                if HardwareCollector.qhasBuiltInDisplay {
                    dispArr[1].image = NSImage(named: "genericLCD") // not first one
                }
            }
            let indiceArray = [0,1]
            indiceArray.forEach { i in
                if i <= (HardwareCollector.displayNames.count-1) {
                    nameArr[i].isHidden = false
                    nameArr[i].stringValue = HardwareCollector.displayNames[i]
                }
                if i <= (HardwareCollector.displayRes.count-1) {
                    labelArr2[i].isHidden = false
                    labelArr2[i].stringValue = HardwareCollector.displayRes[i]
                }
            }
            for disp in dispArr {
                disp.isHidden = false
            }
            /*
            for label in nameArr {
                label.isHidden = false
            }
            for label in labelArr2 {
                label.isHidden = false
            }*/
            
            break
        case 3:
            print("3 Displays Detected")
            labelArr2.append(DisplaySizeResL1)
            labelArr2.append(DisplaySizeResCenter)
            labelArr2.append(DisplaySizeResR1)
            nameArr.append(DisplayNameL1)
            nameArr.append(DisplayNameCenter)
            nameArr.append(DisplayNameR1)
            dispArr.append(DisplayPicL1)
            dispArr.append(DisplayPicCenter)
            dispArr.append(DisplayPicR1)
            //if (HardwareCollector.macType == .DESKTOP) {
            if(HardwareCollector.macType == .DESKTOP) {
                let indiceArray = [0,1,2]
                indiceArray.forEach { i in
                    if i <= (HardwareCollector.displayNames.count-1) {
                        nameArr[i].isHidden = false
                        nameArr[i].stringValue = HardwareCollector.displayNames[i]
                        print("DisplayName: \"\(HardwareCollector.displayNames[i])\"")
                    }
                    if i <= (HardwareCollector.displayRes.count-1) {
                        labelArr2[i].isHidden = false
                        labelArr2[i].stringValue = HardwareCollector.displayRes[i]
                        print("DisplayReso: \"\(HardwareCollector.displayRes[i])\"")
                    }
                    if i <= (HardwareCollector.displayNames.count-1) {
                        
                        if(HardwareCollector.displayNames[i] == "iMac") {
                            dispArr[0].image = NSImage(named: "NSComputer")
                        }
                        
                        else if (HardwareCollector.displayNames[i] == "LG HDR 4K") {
                            dispArr[i].image = NSImage(named: "LG4K")
                        }
                        else if (HardwareCollector.displayNames[i] == "Sidecar Display") {
                            print("Found a SidecarDisplay")
                            dispArr[i].image = NSImage(named: "ipad")
                        }
                        else if (HardwareCollector.displayNames[i] == "LED Cinema Display") {
                            dispArr[i].image = NSImage(named: "appledisp")
                        }
                        else {
                            dispArr[i].image = NSImage(named: "genericLCD")
                        }
                    }
                }
            }
            else if HardwareCollector.qhasBuiltInDisplay {
                let indiceArray = [1,2]
                indiceArray.forEach { i in
                    if i <= (HardwareCollector.displayNames.count-1) {
                        nameArr[i].isHidden = false
                        nameArr[i].stringValue = HardwareCollector.displayNames[i]
                        print("DisplayName: \"\(HardwareCollector.displayNames[i])\"")
                    }
                    if i <= (HardwareCollector.displayRes.count-1) {
                        labelArr2[i].isHidden = false
                        labelArr2[i].stringValue = HardwareCollector.displayRes[i]
                        print("DisplayReso: \"\(HardwareCollector.displayRes[i])\"")
                    }
                    if i <= (HardwareCollector.displayNames.count-1) {

                        if (HardwareCollector.displayNames[i] == "LG HDR 4K") {
                            dispArr[i].image = NSImage(named: "LG4K")
                        }
                        else if (HardwareCollector.displayNames[i] == "Sidecar Display") {
                            print("Found a SidecarDisplay")
                            dispArr[i].image = NSImage(named: "ipad")
                        }
                        else if (HardwareCollector.displayNames[i] == "LED Cinema Display") {
                            dispArr[i].image = NSImage(named: "appledisp")
                        }
                        else {
                            dispArr[i].image = NSImage(named: "genericLCD")
                        }
                    }
                }
            }
            let indiceArray = [0,1,2]
            indiceArray.forEach { i in
                if i <= (HardwareCollector.displayNames.count-1) {
                    nameArr[i].isHidden = false
                    nameArr[i].stringValue = HardwareCollector.displayNames[i]
                    print("DisplayName: \"\(HardwareCollector.displayNames[i])\"")
                }
                if i <= (HardwareCollector.displayRes.count-1) {
                    labelArr2[i].isHidden = false
                    labelArr2[i].stringValue = HardwareCollector.displayRes[i]
                    print("DisplayReso: \"\(HardwareCollector.displayRes[i])\"")
                }
            }
            for disp in dispArr {
                disp.isHidden = false
            }
            break
        default:
            print("Error detecting displays!")
            dispArr.append(DisplayPicCenter)
            if (HardwareCollector.macType == .DESKTOP) {
                DisplayPicCenter.image = NSImage(named: "genericLCD")
            }
            DisplayPicCenter.isHidden = false
        }
    }
}
