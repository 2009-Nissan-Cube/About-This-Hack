//
//  ViewControllerDisplays.swift
//  ViewControllerDisplays
//
//  Created by Marc Nich on 8/26/21.
//

import Foundation
import Cocoa

class ViewControllerStorage: NSViewController {
    
    @IBOutlet weak var startupDiskImage: NSImageView!
    @IBOutlet weak var storageValue: NSTextField!
    
    
    @IBOutlet weak var storageAmount: NSLevelIndicatorCell!
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
        print("Storage View Initializing...")
        
        // Image
        if HardwareCollector.getStorageType() == true {
            startupDiskImage.image = NSImage(named: "SSD")
        } else {
            startupDiskImage.image = NSImage(named: "HDD")
        }
        
        // Text
        storageValue.stringValue = HardwareCollector.storageData
        storageAmount.doubleValue = HardwareCollector.storagePercent*1000000
    }
}
