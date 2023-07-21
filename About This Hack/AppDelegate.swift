//
//  AppDelegate.swift
//  About This Hack
//
//

import Cocoa
import Foundation
import Sparkle

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet var checkForUpdatesMenuItem: NSMenuItem!
    let updaterController: SPUStandardUpdaterController
    
    override init() {
        // If you want to start the updater manually, pass false to startingUpdater and call .startUpdater() later
        // This is where you can also pass an updater delegate if you need one
        updaterController = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    }
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Hooking up the menu item's target/action to the standard updater controller does two things:
        // 1. The menu item's action is set to perform a user-initiated check for new updates
        // 2. The menu item is enabled and disabled by the updater controller depending on -[SPUUpdater canCheckForUpdates]
        checkForUpdatesMenuItem.target = updaterController
        checkForUpdatesMenuItem.action = #selector(SPUStandardUpdaterController.checkForUpdates(_:))
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    @IBAction func showOverview(_ sender: Any) {
        let windCtrl: WindowController = NSApplication.shared.mainWindow?.windowController as! WindowController
        windCtrl.changeView(new: 0)
    }
    @IBAction func showDisplays(_ sender: Any) {
        let windCtrl: WindowController = NSApplication.shared.mainWindow?.windowController as! WindowController
        windCtrl.changeView(new: 1)
    }
    @IBAction func showStorage(_ sender: Any) {
        let windCtrl: WindowController = NSApplication.shared.mainWindow?.windowController as! WindowController
        windCtrl.changeView(new: 2)
    }
    @IBAction func showHelp(_ sender: Any) {
        let windCtrl: WindowController = NSApplication.shared.mainWindow?.windowController as! WindowController
        windCtrl.changeView(new: 3)
    }
}

