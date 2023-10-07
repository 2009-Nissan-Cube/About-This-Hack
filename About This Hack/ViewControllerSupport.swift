//
//  ViewControllerDisplays.swift
//  ViewControllerDisplays
//
//

import Foundation
import Cocoa

var successMessage = "Browser Successfully opened"

class ViewControllerSupport: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        start()
    }

    @IBAction func macOSUserGuidePress(_ sender: NSButton) {
        let url = URL(string: initGlobVar.macOSUserGuidePress)!
        if NSWorkspace.shared.open(url) { print(successMessage) }
    }
    @IBAction func whatsNewInMacOSPress(_ sender: NSButton) {
        let url = URL(string: initGlobVar.whatsNewInMacOSPress)!
        if NSWorkspace.shared.open(url) { print(successMessage) }
    }
    @IBAction func AppleSupportPress(_ sender: NSButton) {
        let url = URL(string: initGlobVar.AppleSupportPress)!
        if NSWorkspace.shared.open(url) { print(successMessage) }
    }
    @IBAction func HackintoshPress(_ sender: NSButton) {
        let url = URL(string: initGlobVar.HackintoshPress)!
        if NSWorkspace.shared.open(url) { print(successMessage) }
    }
    @IBAction func MacBasicsPress(_ sender: NSButton) {
        let url = URL(string: initGlobVar.MacBasicsPress)!
        if NSWorkspace.shared.open(url) { print(successMessage) }
    }
    @IBAction func MacUserGuidePress(_ sender: NSButton) {
        let url = URL(string: initGlobVar.MacUserGuidePress)!
        if NSWorkspace.shared.open(url) { print(successMessage) }
    }
    
    override var representedObject: Any? { didSet { } }

    override func viewDidAppear() { self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable) }
    
    func start() { print("Support View Initializing...") }
}
