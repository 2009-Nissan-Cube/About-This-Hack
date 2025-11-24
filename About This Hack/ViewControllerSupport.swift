//
//  ViewControllerDisplays.swift
//  ViewControllerDisplays
//
//

import Foundation
import Cocoa

var successMessage: String {
    NSLocalizedString("browser.success", comment: "Browser opened successfully message")
}

class ViewControllerSupport: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        start()
    }

    @IBAction func macOSUserGuidePress(_ sender: NSButton) {
        let url = URL(string: InitGlobVar.macOSUserGuidePress)!
        if NSWorkspace.shared.open(url) { 
            ATHLogger.info(NSLocalizedString("log.browser.opened.macos_user_guide", comment: "macOS User Guide opened"), category: .ui) 
        } else {
            ATHLogger.error(String(format: NSLocalizedString("log.browser.failed", comment: "Failed to open URL"), url.absoluteString), category: .ui)
        }
    }
    @IBAction func whatsNewInMacOSPress(_ sender: NSButton) {
        let url = URL(string: InitGlobVar.whatsNewInMacOSPress)!
        if NSWorkspace.shared.open(url) { 
            ATHLogger.info(NSLocalizedString("log.browser.opened.whats_new", comment: "What's New in macOS opened"), category: .ui) 
        } else {
            ATHLogger.error(String(format: NSLocalizedString("log.browser.failed", comment: "Failed to open URL"), url.absoluteString), category: .ui)
        }
    }
    @IBAction func AppleSupportPress(_ sender: NSButton) {
        let url = URL(string: InitGlobVar.AppleSupportPress)!
        if NSWorkspace.shared.open(url) { 
            ATHLogger.info(NSLocalizedString("log.browser.opened.apple_support", comment: "Apple Support opened"), category: .ui) 
        } else {
            ATHLogger.error(String(format: NSLocalizedString("log.browser.failed", comment: "Failed to open URL"), url.absoluteString), category: .ui)
        }
    }
    @IBAction func HackintoshPress(_ sender: NSButton) {
        let url = URL(string: InitGlobVar.HackintoshPress)!
        if NSWorkspace.shared.open(url) { 
            ATHLogger.info(NSLocalizedString("log.browser.opened.hackintosh", comment: "Hackintosh Guide opened"), category: .ui) 
        } else {
            ATHLogger.error(String(format: NSLocalizedString("log.browser.failed", comment: "Failed to open URL"), url.absoluteString), category: .ui)
        }
    }
    @IBAction func MacBasicsPress(_ sender: NSButton) {
        let url = URL(string: InitGlobVar.MacBasicsPress)!
        if NSWorkspace.shared.open(url) { 
            ATHLogger.info(NSLocalizedString("log.browser.opened.mac_basics", comment: "Mac Basics opened"), category: .ui) 
        } else {
            ATHLogger.error(String(format: NSLocalizedString("log.browser.failed", comment: "Failed to open URL"), url.absoluteString), category: .ui)
        }
    }
    @IBAction func MacUserGuidePress(_ sender: NSButton) {
        let url = URL(string: InitGlobVar.MacUserGuidePress)!
        if NSWorkspace.shared.open(url) { 
            ATHLogger.info(NSLocalizedString("log.browser.opened.mac_user_guide", comment: "Mac User Guide opened"), category: .ui) 
        } else {
            ATHLogger.error(String(format: NSLocalizedString("log.browser.failed", comment: "Failed to open URL"), url.absoluteString), category: .ui)
        }
    }
    
    override var representedObject: Any? { didSet { } }

    override func viewDidAppear() { self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable) }
    
    func start() { ATHLogger.info(NSLocalizedString("log.support_view.init", comment: "Support View initializing"), category: .ui) }
}
