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
        let url = URL(string: InitGlobVar.macOSUserGuidePress)!
        if NSWorkspace.shared.open(url) { 
            ATHLogger.info("Browser opened: macOS User Guide", category: .ui) 
        } else {
            ATHLogger.error("Failed to open URL: \(url)", category: .ui)
        }
    }
    @IBAction func whatsNewInMacOSPress(_ sender: NSButton) {
        let url = URL(string: InitGlobVar.whatsNewInMacOSPress)!
        if NSWorkspace.shared.open(url) { 
            ATHLogger.info("Browser opened: What's New in macOS", category: .ui) 
        } else {
            ATHLogger.error("Failed to open URL: \(url)", category: .ui)
        }
    }
    @IBAction func AppleSupportPress(_ sender: NSButton) {
        let url = URL(string: InitGlobVar.AppleSupportPress)!
        if NSWorkspace.shared.open(url) { 
            ATHLogger.info("Browser opened: Apple Support", category: .ui) 
        } else {
            ATHLogger.error("Failed to open URL: \(url)", category: .ui)
        }
    }
    @IBAction func HackintoshPress(_ sender: NSButton) {
        let url = URL(string: InitGlobVar.HackintoshPress)!
        if NSWorkspace.shared.open(url) { 
            ATHLogger.info("Browser opened: Hackintosh Guide", category: .ui) 
        } else {
            ATHLogger.error("Failed to open URL: \(url)", category: .ui)
        }
    }
    @IBAction func MacBasicsPress(_ sender: NSButton) {
        let url = URL(string: InitGlobVar.MacBasicsPress)!
        if NSWorkspace.shared.open(url) { 
            ATHLogger.info("Browser opened: Mac Basics", category: .ui) 
        } else {
            ATHLogger.error("Failed to open URL: \(url)", category: .ui)
        }
    }
    @IBAction func MacUserGuidePress(_ sender: NSButton) {
        let url = URL(string: InitGlobVar.MacUserGuidePress)!
        if NSWorkspace.shared.open(url) { 
            ATHLogger.info("Browser opened: Mac User Guide", category: .ui) 
        } else {
            ATHLogger.error("Failed to open URL: \(url)", category: .ui)
        }
    }
    
    override var representedObject: Any? { didSet { } }

    override func viewDidAppear() { self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable) }
    
    func start() { ATHLogger.info("Support View Initializing...", category: .ui) }
}
