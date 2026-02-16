//
//  ViewControllerSupport.swift
//

import Foundation
import Cocoa

class ViewControllerSupport: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        ATHLogger.info(NSLocalizedString("log.support_view.init", comment: "Support View initializing"), category: .ui)
    }

    @IBAction func macOSUserGuidePress(_ sender: NSButton) {
        openURL(InitGlobVar.macOSUserGuideURL, logKey: "log.browser.opened.macos_user_guide")
    }
    @IBAction func whatsNewInMacOSPress(_ sender: NSButton) {
        openURL(InitGlobVar.whatsNewInMacOSURL, logKey: "log.browser.opened.whats_new")
    }
    @IBAction func AppleSupportPress(_ sender: NSButton) {
        openURL(InitGlobVar.AppleSupportURL, logKey: "log.browser.opened.apple_support")
    }
    @IBAction func HackintoshPress(_ sender: NSButton) {
        openURL(InitGlobVar.HackintoshInstallURL, logKey: "log.browser.opened.hackintosh")
    }
    @IBAction func MacBasicsPress(_ sender: NSButton) {
        openURL(InitGlobVar.MacBasicsURL, logKey: "log.browser.opened.mac_basics")
    }
    @IBAction func MacUserGuidePress(_ sender: NSButton) {
        openURL(InitGlobVar.MacUserGuideURL, logKey: "log.browser.opened.mac_user_guide")
    }

    private func openURL(_ urlString: String, logKey: String) {
        let url = URL(string: urlString)!
        if NSWorkspace.shared.open(url) {
            ATHLogger.info(NSLocalizedString(logKey, comment: ""), category: .ui)
        } else {
            ATHLogger.error(String(format: NSLocalizedString("log.browser.failed", comment: "Failed to open URL"), url.absoluteString), category: .ui)
        }
    }

    override var representedObject: Any? { didSet { } }
}
