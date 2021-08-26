//
//  ViewControllerDisplays.swift
//  ViewControllerDisplays
//
//  Created by Marc Nich on 8/26/21.
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
        print("display ini called")
        if (!HardwareCollector.dataHasBeenSet) {HardwareCollector.getAllData()}
        var dispArr: [NSImageView] = []
        if (!HardwareCollector.dataHasBeenSet) {HardwareCollector.getAllData()}
        if (HardwareCollector.macType == .DESKTOP) {
            DisplayPicCenter.image = NSImage(named: "genericLCD")
        }
        switch (HardwareCollector.numberOfDisplays) {
        case 1:
            dispArr.append(DisplayPicCenter)
            if (HardwareCollector.macType == .DESKTOP) {
                DisplayPicCenter.image = NSImage(named: "genericLCD")
            }
            DisplayPicCenter.isHidden = false
            DisplayNameCenter.isHidden = false
            DisplayNameCenter.stringValue = "Built-in Retina Display"
            break
        case 2:
            dispArr.append(DisplayPicL2)
            dispArr.append(DisplayPicR2)
            if (HardwareCollector.macType == .DESKTOP) {
                for disp in dispArr {
                    disp.image = NSImage(named: "genericLCD")
                }
            }
            else {
                if HardwareCollector.qhasBuiltInDisplay {
                    dispArr[1].image = NSImage(named: "genericLCD") // not first one
                }
            }
            for disp in dispArr {
                disp.isHidden = false
            }
            break
        case 3:
            break
        default:
            dispArr.append(DisplayPicCenter)
            if (HardwareCollector.macType == .DESKTOP) {
                DisplayPicCenter.image = NSImage(named: "genericLCD")
            }
            DisplayPicCenter.isHidden = false
        }
    }
}
