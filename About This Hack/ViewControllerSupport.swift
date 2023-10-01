//
//  ViewControllerDisplays.swift
//  ViewControllerDisplays
//
//

import Foundation
import Cocoa

var succesMessage = "Browser Successfully opened"

class ViewControllerSupport: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        start()
    }

    @IBAction func macOSUserGuidePress(_ sender: NSButton) {
        let url = URL(string: initGlobVar.macOSUserGuidePress)!
        if NSWorkspace.shared.open(url) { print(succesMessage) }
    }
    @IBAction func whatsNewInMacOSPress(_ sender: NSButton) {
        let url = URL(string: initGlobVar.whatsNewInMacOSPress)!
        if NSWorkspace.shared.open(url) { print(succesMessage) }
    }
    @IBAction func AppleSupportPress(_ sender: NSButton) {
        let url = URL(string: initGlobVar.AppleSupportPress)!
        if NSWorkspace.shared.open(url) { print(succesMessage) }
    }
    @IBAction func HackintoshPress(_ sender: NSButton) {
        let url = URL(string: initGlobVar.HackintoshPress)!
        if NSWorkspace.shared.open(url) { print(succesMessage) }
    }
    @IBAction func MacBasicsPress(_ sender: NSButton) {
        let url = URL(string: initGlobVar.MacBasicsPress)!
        if NSWorkspace.shared.open(url) { print(succesMessage) }
    }
    @IBAction func MacUserGuidePress(_ sender: NSButton) {
        let url = URL(string: initGlobVar.MacUserGuidePress)!
        if NSWorkspace.shared.open(url) { print(succesMessage) }
    }
    
    override var representedObject: Any? { didSet { } }

    override func viewDidAppear() { self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable) }
    
    func start() { print("Support View Initializing...") }
}
