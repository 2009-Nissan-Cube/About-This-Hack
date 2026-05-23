import Cocoa
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindowController: WindowController?
    private var settingsWindowController: SettingsWindowController?

    override init() {
        super.init()
        ATHLogger.info(NSLocalizedString("log.app.starting", comment: "Application starting"), category: .system)

        CreateDataFiles.getInitDataFilesAsync {
            ATHLogger.info(NSLocalizedString("log.data_files.ready", comment: "Data files ready"), category: .system)
        }
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        installMainMenu()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        showMainWindow()

        ATHLogger.info(NSLocalizedString("log.checking_updates", comment: "Checking for updates"), category: .system)
        UpdateController.checkForUpdatesAsync { shouldUpdate in
            if shouldUpdate {
                ATHLogger.info(NSLocalizedString("log.update_available", comment: "Update available"), category: .system)
                UpdateController.updateATH()
            } else {
                ATHLogger.info(NSLocalizedString("log.no_updates", comment: "No updates available"), category: .system)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        ATHLogger.info(NSLocalizedString("log.app.terminating", comment: "Application terminating"), category: .system)
        try? InitGlobVar.defaultfileManager.removeItem(at: InitGlobVar.athDirectoryURL)
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }

    private func showMainWindow() {
        if mainWindowController == nil {
            mainWindowController = WindowController()
        }

        mainWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showView(atIndex index: Int) {
        showMainWindow()
        mainWindowController?.changeView(new: index)
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

    @IBAction func showSettings(_ sender: Any) {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }

        settingsWindowController?.showWindow(nil)
        settingsWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func installMainMenu() {
        let mainMenu = NSMenu(title: "")

        let appMenuItem = NSMenuItem()
        mainMenu.addItem(appMenuItem)
        appMenuItem.submenu = buildApplicationMenu()

        let viewMenuItem = NSMenuItem()
        mainMenu.addItem(viewMenuItem)
        viewMenuItem.submenu = buildViewMenu()

        let windowMenuItem = NSMenuItem()
        mainMenu.addItem(windowMenuItem)
        let windowMenu = buildWindowMenu()
        windowMenuItem.submenu = windowMenu
        NSApp.windowsMenu = windowMenu

        let helpMenuItem = NSMenuItem()
        mainMenu.addItem(helpMenuItem)
        let helpMenu = NSMenu(title: L("menu.help", comment: "Help menu"))
        helpMenuItem.submenu = helpMenu
        NSApp.helpMenu = helpMenu

        NSApp.mainMenu = mainMenu
    }

    private func buildApplicationMenu() -> NSMenu {
        let appName = Bundle.main.applicationName ?? "About This Hack"
        let appMenu = NSMenu(title: appName)

        appMenu.addItem(NSMenuItem(title: String(format: L("menu.about", comment: "About menu item"), appName),
                                   action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)),
                                   keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())

        let preferences = NSMenuItem(title: L("menu.preferences", comment: "Preferences menu item"),
                                     action: #selector(showSettings(_:)),
                                     keyEquivalent: ",")
        preferences.target = self
        appMenu.addItem(preferences)
        appMenu.addItem(NSMenuItem.separator())

        appMenu.addItem(NSMenuItem(title: String(format: L("menu.hide", comment: "Hide app menu item"), appName),
                                   action: #selector(NSApplication.hide(_:)),
                                   keyEquivalent: "h"))
        let hideOthers = NSMenuItem(title: L("menu.hide_others", comment: "Hide Others menu item"),
                                    action: #selector(NSApplication.hideOtherApplications(_:)),
                                    keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthers)
        appMenu.addItem(NSMenuItem(title: L("menu.show_all", comment: "Show All menu item"),
                                   action: #selector(NSApplication.unhideAllApplications(_:)),
                                   keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: String(format: L("menu.quit", comment: "Quit app menu item"), appName),
                                   action: #selector(NSApplication.terminate(_:)),
                                   keyEquivalent: "q"))

        return appMenu
    }

    private func buildViewMenu() -> NSMenu {
        let viewMenu = NSMenu(title: L("menu.view", comment: "View menu"))
        let items: [(String, Selector, String)] = [
            (L("segment.title.overview", comment: "Overview tab title"), #selector(showOverview(_:)), "1"),
            (L("segment.title.displays", comment: "Displays tab title"), #selector(showDisplays(_:)), "2"),
            (L("segment.title.storage", comment: "Storage tab title"), #selector(showStorage(_:)), "3"),
            (L("segment.title.support", comment: "Support tab title"), #selector(showHelp(_:)), "4")
        ]

        for item in items {
            let menuItem = NSMenuItem(title: item.0, action: item.1, keyEquivalent: item.2)
            menuItem.target = self
            viewMenu.addItem(menuItem)
        }

        return viewMenu
    }

    private func buildWindowMenu() -> NSMenu {
        let windowMenu = NSMenu(title: L("menu.window", comment: "Window menu"))
        windowMenu.addItem(NSMenuItem(title: L("menu.minimize", comment: "Minimize menu item"),
                                      action: #selector(NSWindow.miniaturize(_:)),
                                      keyEquivalent: "m"))
        windowMenu.addItem(NSMenuItem(title: L("menu.close", comment: "Close menu item"),
                                      action: #selector(NSWindow.performClose(_:)),
                                      keyEquivalent: "w"))
        windowMenu.addItem(NSMenuItem.separator())
        windowMenu.addItem(NSMenuItem(title: L("menu.bring_all_to_front", comment: "Bring All to Front menu item"),
                                      action: #selector(NSApplication.arrangeInFront(_:)),
                                      keyEquivalent: ""))
        return windowMenu
    }
}
