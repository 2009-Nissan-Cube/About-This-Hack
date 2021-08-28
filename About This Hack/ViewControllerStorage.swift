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
        print("Storage view initializing...")
        
        // Image
        let name = "\(HardwareCollector.getStartupDisk())"
        let storageType = (try? call("diskutil info \"\(name)\" | grep 'Solid State'")) ?? "Unknown Storage Type"
        if storageType.contains("Yes") {
            startupDiskImage.image = NSImage(named: "SSD")
        } else {
            startupDiskImage.image = NSImage(named: "HDD")
        }
        print(storageType)
        
        // Text
        let size = (try? call("diskutil info \"\(name)\" | grep 'Disk Size' | sed 's/.*:                 //' | cut -f1 -d'('"))
        let available = (try? call("diskutil info \"\(name)\" | Grep 'Container Free Space' | sed 's/.*:      //' | cut -f1 -d'('"))
        storageValue.stringValue = "\(name) \(size ?? "")(\(available ?? "")Available)"
    }
}
