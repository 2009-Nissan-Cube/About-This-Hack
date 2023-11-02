import Cocoa
import Foundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
   override init() {
        // Call Function to create Data Files
       CreateDataFiles.getInitDataFiles()
       Thread.sleep(forTimeInterval: 1.5)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("Checking for Updates...")
        if UpdateController.checkForUpdates() {
            UpdateController.updateATH()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        _ = run("rm -rf " + initGlobVar.athDirectory + " 2>/dev/null")
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
