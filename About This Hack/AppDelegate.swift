import Cocoa
import Foundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    override init() {
        super.init()
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
        _ = run("rm -rf " + InitGlobVar.athDirectory + " 2>/dev/null")
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    // Refactor show views into a single function:
    private func showView(atIndex index: Int) {
        guard let windowController = NSApplication.shared.mainWindow?.windowController as? WindowController else { return }
        windowController.changeView(new: index)
    }
    
    @IBAction func showOverview(_ sender: Any) {
        showView(atIndex: 0)
    }

    @IBAction func showDisplays(_ sender: Any) {
        showView(atIndex: 1)
    }

    @IBAction func showStorage(_ sender: Any) {
        showView(atIndex: 2)
    }

    @IBAction func showHelp(_ sender: Any) {
        showView(atIndex: 3)
    }
}
