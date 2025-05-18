import Cocoa
import Foundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    override init() {
        super.init()
        ATHLogger.info("Application starting...", category: .system)
        CreateDataFiles.getInitDataFiles()
        Thread.sleep(forTimeInterval: 1.5)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        ATHLogger.info("Checking for Updates...", category: .system)
        if UpdateController.checkForUpdates() {
            ATHLogger.info("Update available, initiating update process", category: .system)
            UpdateController.updateATH()
        } else {
            ATHLogger.info("No updates available", category: .system)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        ATHLogger.info("Application terminating, cleaning up temporary files", category: .system)
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
        guard let windowController = NSApplication.shared.mainWindow?.windowController as? WindowController else { 
            ATHLogger.warning("Cannot show view: main window controller not found", category: .ui)
            return 
        }
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
