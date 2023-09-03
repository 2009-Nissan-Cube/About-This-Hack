//
//  ViewControllerDisplays.swift
//  ViewControllerDisplays
//
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
        print("Initializing Storage View...")
        
        if (!HardwareCollector.dataHasBeenSet) {HardwareCollector.getAllData()}

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
