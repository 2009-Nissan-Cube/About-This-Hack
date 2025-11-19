import Cocoa
import Foundation

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    override init() {
        super.init()
        ATHLogger.info(NSLocalizedString("log.app.starting", comment: "Application starting"), category: .system)
        // Start async data file creation - no blocking!
        CreateDataFiles.getInitDataFilesAsync {
            ATHLogger.info(NSLocalizedString("log.data_files.ready", comment: "Data files ready"), category: .system)
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        ATHLogger.info(NSLocalizedString("log.checking_updates", comment: "Checking for updates"), category: .system)
        if UpdateController.checkForUpdates() {
            ATHLogger.info(NSLocalizedString("log.update_available", comment: "Update available"), category: .system)
            UpdateController.updateATH()
        } else {
            ATHLogger.info(NSLocalizedString("log.no_updates", comment: "No updates available"), category: .system)
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        ATHLogger.info(NSLocalizedString("log.app.terminating", comment: "Application terminating"), category: .system)
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
            ATHLogger.warning(NSLocalizedString("log.view.show_error", comment: "Cannot show view"), category: .ui)
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
