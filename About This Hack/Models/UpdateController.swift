//
//  UpdateController.swift
//

import Foundation
import AppKit
import Cocoa
import UserNotifications

class UpdateController {
    
    static var thisComponent: String {
        return String(describing: self)
    }

    static var lastTagVersion    :String = ""
    static var marketVersion     :String = ""
    static var minSystemVersion  :String = "Unknown"
    static var exeToSearch       :String = ""
    static var kindToSearch      :String = "app"
    static var isUpdateAvailable :Bool   = false
    static var alertheader       :String = ""
    static var alertdetail       :Any    = ""
    static var notificationID    :Int    = 0
    static var unzippedFile      :Bool   = false
    
    // Timeout duration for update check (in seconds)
    static let updateCheckTimeout: TimeInterval = 10.0
    
    // Lock for thread-safe access to cancellation flag
    private static let cancellationLock = NSLock()
    private static var _updateCheckCancelled = false
    private static var updateCheckCancelled: Bool {
        get {
            cancellationLock.lock()
            defer { cancellationLock.unlock() }
            return _updateCheckCancelled
        }
        set {
            cancellationLock.lock()
            defer { cancellationLock.unlock() }
            _updateCheckCancelled = newValue
        }
    }
    
    /// Asynchronously checks for updates with timeout
    /// - Parameter completion: Completion handler called with result (true if update should be performed)
    static func checkForUpdatesAsync(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            ATHLogger.info(String(format: NSLocalizedString("log.update.checking", comment: "Checking for updates"), thisComponent), category: .system)
            
            updateCheckCancelled = false
            let semaphore = DispatchSemaphore(value: 0)
            var result = false
            
            // Create a separate thread for the actual check to allow timeout
            DispatchQueue.global(qos: .utility).async {
                result = checkForUpdates()
                // Only signal if not cancelled to avoid race condition
                if !updateCheckCancelled {
                    semaphore.signal()
                }
            }
            
            // Wait with timeout
            let waitResult = semaphore.wait(timeout: .now() + updateCheckTimeout)
            
            if waitResult == .timedOut {
                updateCheckCancelled = true
                ATHLogger.warning(String(format: NSLocalizedString("log.update.timeout", comment: "Update check timed out"), thisComponent), category: .system)
                
                // Call completion handler first to allow data loading to proceed
                DispatchQueue.main.async {
                    completion(false)
                }
                
                // Show timeout alert without blocking data loading
                // Silenced for now, to enable it uncomment lines 79, 80, 81
//                alertheader = NSLocalizedString("update.alert.timeout", comment: "Update check timed out")
//                alertdetail = String(format: NSLocalizedString("update.alert.timeout_detail", comment: "The connection to GitHub timed out after %d seconds"), Int(updateCheckTimeout))
//                showInformationalAlert(message: alertheader, text: "\(alertdetail)")
            } else {
                // Call completion handler consistently on main thread
                DispatchQueue.main.async {
                    completion(updateCheckCancelled ? false : result)
                }
            }
        }
    }

    static func checkForUpdates() -> Bool {
        // Check if cancelled early to avoid unnecessary work
        guard !updateCheckCancelled else { return false }
        
        lastTagVersion = run("GIT_TERMINAL_PROMPT=0 git ls-remote --tags --refs \(InitGlobVar.athrepositoryURL) | grep \"/tags/[0-9]\" | awk -F'/' '{print  $NF}' | sort -u | tail -n1 | tr -d '\n'")
        
        guard !updateCheckCancelled else { return false }
        
        if lastTagVersion != "" && !lastTagVersion.starts(with: "fatal") {
            let pbxProjLocat = InitGlobVar.athlasttagpbxproj.replacingOccurrences(of: "[LASTTAG]", with: lastTagVersion)
            marketVersion = run("\(InitGlobVar.curlLocation) -s \(InitGlobVar.athrepositoryURL)\(pbxProjLocat) | sed -e 's?,?\\n?g' -e 's?;?\\n?g' | grep \"MARKETING_VERSION = \" | awk '{print $NF}' | sort -u | tail -n1 | tr -d '\n' 2>/dev/null")
            
            guard !updateCheckCancelled else { return false }
// Postulat : there is one and only one target in pbxproj
            if marketVersion == "" {
                marketVersion = thisApplicationVersion  // fake marketVersion (ie. = localVersion) so no Update and no app. crash
            }
            ATHLogger.info(String(format: NSLocalizedString("log.update.versions", comment: "Local and remote versions"), thisComponent, thisApplicationVersion, marketVersion, lastTagVersion), category: .system)
            if thisApplicationVersion < marketVersion {
                //MARK: newer app found
                ATHLogger.info(String(format: NSLocalizedString("log.update.newer_version", comment: "Newer version available"), thisComponent, marketVersion), category: .system)
                
                guard !updateCheckCancelled else { return false }
                
                var prompt = false
                // Show alert on main thread and wait for user response
                DispatchQueue.main.sync {
                    prompt = updateAlert(message: NSLocalizedString("update.alert.update_found", comment: "Update found!"), text: String(format: NSLocalizedString("update.alert.latest_version", comment: "Latest version info"), marketVersion, thisApplicationVersion), buttonArray: [NSLocalizedString("update.alert.button.update", comment: "Update"), NSLocalizedString("update.alert.button.skip", comment: "Skip")])
                }
                ATHLogger.info(String(format: NSLocalizedString("log.update.done", comment: "Update check done"), thisComponent), category: .system)
                return prompt
            }
        } else {
            guard !updateCheckCancelled else { return false }
            
            alertheader = NSLocalizedString("update.alert.cant_get_version", comment: "Can't get version from remote repo")
            alertdetail = "\(InitGlobVar.athrepositoryURL)"
            ATHLogger.error("\(thisComponent) : \(alertheader) \(alertdetail)", category: .system)
            // Show alert without blocking the main thread
            showInformationalAlert(message: "\(alertheader)", text: "\(alertdetail)")
        }
        return false
    }

    static func updateATH() {
        isUpdateAvailable = true
        
        //MARK: DownLoad new app.zip from repo
        ATHLogger.info(String(format: NSLocalizedString("log.update.starting_download", comment: "Starting download"), thisComponent, marketVersion), category: .system)
        notify(title: String(format: NSLocalizedString("update.notify.starting_download", comment: "Starting Download"), marketVersion), informativeText: "")
        guard run("\(InitGlobVar.curlLocation) -L \(InitGlobVar.lastAthreleaseURL)\(lastTagVersion)/\(InitGlobVar.newAthziprelease) -o \(InitGlobVar.newAthreleasezip)") == "" else {
            alertheader = NSLocalizedString("update.alert.cant_download", comment: "Can't Download Update")
            alertdetail = "\(InitGlobVar.lastAthreleaseURL)\(lastTagVersion)/\(InitGlobVar.newAthziprelease)"
            ATHLogger.error("\(thisComponent) : \(alertheader) \(alertdetail)", category: .system)
            _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: [NSLocalizedString("update.alert.button.return", comment: "Return")])
            isUpdateAvailable = false
            return
        }

        //MARK: unzip new app.zip
        if isUpdateAvailable {
            while (!InitGlobVar.defaultfileManager.fileExists(atPath: InitGlobVar.newAthreleasezip)) {
                Thread.sleep(forTimeInterval: 0.2)
            }
            ATHLogger.info(String(format: NSLocalizedString("log.update.unzipping", comment: "Unzipping archive"), thisComponent), category: .system)
            notify(title: NSLocalizedString("update.notify.unzipping", comment: "Unzipping Archive"), informativeText: "")
            guard run("/usr/bin/unzip -q -o \(InitGlobVar.newAthreleasezip) -d \(InitGlobVar.athDirectory)") == "" else {
                alertheader = NSLocalizedString("update.alert.cant_unzip", comment: "Can't unzip Archive")
                alertdetail = String(format: NSLocalizedString("update.alert.cant_unzip_detail", comment: "Archive unzip detail"), InitGlobVar.newAthreleasezip, InitGlobVar.athDirectory)
                ATHLogger.error("\(thisComponent) : \(alertheader) \(alertdetail)", category: .system)
                _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: [NSLocalizedString("update.alert.button.return", comment: "Return")])
                isUpdateAvailable = false
                return
            }
            // what kind of extracted component a ".app" or a ".dmg" and man try 5 times
            var notFoundLoop : Int = 0
            while (!unzippedFile) && (notFoundLoop < 5) {
                Thread.sleep(forTimeInterval: 0.2)
                exeToSearch = checkFileExtension(atPath: InitGlobVar.athDirectory, withExtensions: [".app", ".dmg"])
                if exeToSearch != "" {
                    unzippedFile = true
                    notFoundLoop = 5
                    kindToSearch = String(exeToSearch.suffix(3))
                } else {
                    notFoundLoop += 1
                }
            }
            if (!unzippedFile) && (notFoundLoop > 4) {
                alertheader = NSLocalizedString("update.alert.cant_find_extension", comment: "Can't find .app or .dmg extension")
                alertdetail = String(format: NSLocalizedString("update.alert.cant_unzip_detail", comment: "Archive extraction detail"), InitGlobVar.newAthreleasezip, InitGlobVar.athDirectory)
                ATHLogger.error("\(thisComponent) : \(alertheader) \(alertdetail)", category: .system)
                _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: [NSLocalizedString("update.alert.button.return", comment: "Return")])
                isUpdateAvailable = false
                return
            }
            ATHLogger.info(String(format: NSLocalizedString("log.update.extracted", comment: "File extracted from archive"), thisComponent, exeToSearch), category: .system)
        }
        
        //MARK: from new app.zip extracted .dmg or .app
        if isUpdateAvailable && kindToSearch == "dmg" {
            while (!InitGlobVar.defaultfileManager.fileExists(atPath: exeToSearch)) {
                Thread.sleep(forTimeInterval: 0.2)
            }
            //MARK: from new app.zip a .dmg extracted must be attached
            ATHLogger.info(String(format: NSLocalizedString("log.update.mounting_dmg", comment: "Try to mount dmg"), thisComponent, exeToSearch), category: .system)
            notify(title: NSLocalizedString("update.notify.mounting_dmg", comment: "Try to mount dmg"), informativeText: "")
            guard run("/usr/bin/hdiutil attach \"\(exeToSearch)\" -nobrowse -quiet") == "" else {
                alertheader = NSLocalizedString("update.alert.cant_mount_dmg", comment: "Can't mount dmg")
                alertdetail = "\(exeToSearch)"
                ATHLogger.error("\(thisComponent) : \(alertheader) \(alertdetail)", category: .system)
                _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: [NSLocalizedString("update.alert.button.return", comment: "Return")])
                isUpdateAvailable = false
                return
            }
            if isUpdateAvailable {
                while (!InitGlobVar.defaultfileManager.fileExists(atPath: "/Volumes/\(InitGlobVar.thisApplicationName)")) {
                    Thread.sleep(forTimeInterval: 2)
                }
                //MARK: .dmg is mounted containing a .app so we copy it to temp Dir
                ATHLogger.info(String(format: NSLocalizedString("log.update.dmg_mounted", comment: "DMG mounted and copying"), thisComponent, exeToSearch, InitGlobVar.thisApplicationName, thisComponent, InitGlobVar.thisApplicationName, InitGlobVar.thisApplicationName, InitGlobVar.athDirectory), category: .system)
                guard run("/bin/cp -prf /Volumes/\"\(InitGlobVar.thisApplicationName)/\(InitGlobVar.thisApplicationName).app\" \(InitGlobVar.athDirectory)/\"\(InitGlobVar.thisApplicationName).app\"") == "" else {
                    alertheader = NSLocalizedString("update.alert.cant_copy_app", comment: "Can't copy application")
                    alertdetail = String(format: NSLocalizedString("update.alert.cant_copy_app_detail", comment: "Can't copy app detail"), InitGlobVar.thisApplicationName, InitGlobVar.thisApplicationName, InitGlobVar.athDirectory)
                    ATHLogger.error("\(thisComponent) : \(alertheader) \(alertdetail)", category: .system)
                    _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: [NSLocalizedString("update.alert.button.return", comment: "Return")])
                    isUpdateAvailable = false
                    return
                }
            }
            if isUpdateAvailable {
                while (!InitGlobVar.defaultfileManager.fileExists(atPath: "\(InitGlobVar.athDirectory)/\(InitGlobVar.thisApplicationName).app")) {
                    Thread.sleep(forTimeInterval: 0.2)
                }
                //MARK: .app from .dmg copied to temp Dir .dmg is detached
                ATHLogger.info(String(format: NSLocalizedString("log.update.app_copied", comment: "App copied to directory"), thisComponent, InitGlobVar.thisApplicationName, InitGlobVar.thisApplicationName, InitGlobVar.athDirectory), category: .system)
                ATHLogger.info(String(format: NSLocalizedString("log.update.unmounting_dmg", comment: "Try to unmount dmg"), thisComponent, InitGlobVar.thisApplicationName), category: .system)
                notify(title: NSLocalizedString("update.notify.unmounting_dmg", comment: "Try to unmount dmg"), informativeText: "")
                guard run("/usr/bin/hdiutil detach  /Volumes/\"\(InitGlobVar.thisApplicationName)\" -force -quiet") == "" else {
                    alertheader = String(format: NSLocalizedString("update.alert.cant_unmount_dmg", comment: "Can't unmount dmg"), InitGlobVar.thisApplicationName)
                    alertdetail = String(format: NSLocalizedString("update.alert.cant_unmount_dmg_detail", comment: "Can't unmount dmg detail"), InitGlobVar.thisApplicationName)
                    ATHLogger.error("\(thisComponent) : \(alertheader) \(alertdetail)", category: .system)
                    _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: [NSLocalizedString("update.alert.button.return", comment: "Return")])
                    isUpdateAvailable = false
                    return
                }
                ATHLogger.info(String(format: NSLocalizedString("log.update.dmg_ejected", comment: "DMG ejected"), thisComponent, InitGlobVar.thisApplicationName), category: .system)
            }
        }
        
        //MARK: does this new .app alowed on this OS version
        if isUpdateAvailable {
            while (!InitGlobVar.defaultfileManager.fileExists(atPath: "\(InitGlobVar.athDirectory)/\(InitGlobVar.thisApplicationName).app")) {
                Thread.sleep(forTimeInterval: 0.2)
            }
            ATHLogger.info(String(format: NSLocalizedString("log.update.checking_os_compatibility", comment: "Checking OS compatibility"), thisComponent, marketVersion, HCVersion.shared.osNumber), category: .system)
            notify(title: String(format: NSLocalizedString("update.notify.checking_allowed", comment: "Checking if new app is allowed"), marketVersion), informativeText: "")
            let plistNewVersion = "\(InitGlobVar.athDirectory)/\(InitGlobVar.thisApplicationName).app/Contents/Info.plist"
            if InitGlobVar.defaultfileManager.fileExists(atPath: "\(plistNewVersion)") {
                if let resourceFileDictionaryContent = NSDictionary(contentsOfFile: "\(plistNewVersion)") {
                    // Get "LSMinimumSystemVersion" value by key
                    minSystemVersion = resourceFileDictionaryContent.object(forKey: "LSMinimumSystemVersion")! as! String
                }
            }
            if minSystemVersion == "Unknown" || minSystemVersion == "" { //plistNewVersion not found or LSMinimumSystemVersion key not found
                alertheader = NSLocalizedString("update.alert.cant_get_min_os", comment: "Can't get Minimum OS Version")
                alertdetail = String(format: NSLocalizedString("update.alert.cant_get_min_os_detail", comment: "LSMinimumSystemVersion not found"), plistNewVersion)
                ATHLogger.error("\(thisComponent) : \(alertheader) \(alertdetail)", category: .system)
                _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: [NSLocalizedString("update.alert.button.return", comment: "Return")])
                isUpdateAvailable = false
                return
            } else {
                let arrayMinOSVersion:[String] = minSystemVersion.components(separatedBy: ".")
                let arrayCurOSVersion:[String] = HCVersion.shared.osNumber.components(separatedBy: ".")
                var minCountIndex:Int = 0
                var allowed:Bool = true
                if arrayMinOSVersion.count > arrayCurOSVersion.count {
                    minCountIndex = arrayCurOSVersion.count
                } else {
                    minCountIndex = arrayMinOSVersion.count
                }
                ATHLogger.info(String(format: NSLocalizedString("log.update.os_versions", comment: "Current and minimum OS versions"), thisComponent, HCVersion.shared.osNumber, minSystemVersion), category: .system)
                for index in 0...minCountIndex-1 {
                    if arrayCurOSVersion[index] < arrayMinOSVersion[index] {
                        allowed = false
                        break
                    } else {
                        if arrayCurOSVersion[index] > arrayMinOSVersion[index] {
                            break
                        }
                    } // if arrayCurOSVersion[index] = arrayMinOSVersion[index] go on to check with next index (next part of tows versions)
                    ATHLogger.debug(String(format: NSLocalizedString("log.update.os_version_index", comment: "OS version comparison at index"), thisComponent, index, arrayCurOSVersion[index], arrayMinOSVersion[index]), category: .system)
                }
                if !allowed {
                    alertheader = NSLocalizedString("update.alert.update_cant_be_achieved", comment: "Update can't be achieved")
                    alertdetail = String(format: NSLocalizedString("update.alert.update_cant_be_achieved_detail", comment: "Update can't be achieved detail"), minSystemVersion, HCVersion.shared.osNumber)
                    ATHLogger.error("\(thisComponent) : \(alertheader) \(alertdetail)", category: .system)
                    _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: [NSLocalizedString("update.alert.button.return", comment: "Return")])
                    isUpdateAvailable = false
                    return
                } else {
                    ATHLogger.info(String(format: NSLocalizedString("log.update.update_allowed", comment: "Update is allowed"), thisComponent, minSystemVersion, HCVersion.shared.osNumber), category: .system)
                }
            }
        }

        //MARK: this new .app allowed current app is removed before installing new one
        if isUpdateAvailable && InitGlobVar.defaultfileManager.fileExists(atPath: InitGlobVar.thisAppliLocation) {
            while (!InitGlobVar.defaultfileManager.fileExists(atPath: exeToSearch)) {
                Thread.sleep(forTimeInterval: 0.2)
            }
            ATHLogger.info(String(format: NSLocalizedString("log.update.removing_old_app", comment: "Removing old app"), thisComponent), category: .system)
            notify(title: NSLocalizedString("update.notify.removing_old", comment: "Removing Old App"), informativeText: "")
            if InitGlobVar.defaultfileManager.fileExists(atPath: InitGlobVar.thisAppliLocation) {
                do {
                    try InitGlobVar.defaultfileManager.removeItem(atPath: "\(InitGlobVar.thisAppliLocation)")
                    ATHLogger.info(String(format: NSLocalizedString("log.update.directory_deleted", comment: "Directory deleted successfully"), thisComponent, InitGlobVar.thisAppliLocation), category: .system)
                } catch {
                    ATHLogger.error(String(format: NSLocalizedString("log.update.error_deleting_directory", comment: "Error deleting directory"), thisComponent, InitGlobVar.thisAppliLocation, String(describing: error)), category: .system)
                    alertheader = NSLocalizedString("update.alert.failed_delete_old", comment: "Failed to delete the old copy of")
                    alertdetail = String(format: NSLocalizedString("update.alert.failed_delete_old_detail", comment: "Failed to delete old detail"), InitGlobVar.thisAppliLocation, InitGlobVar.allAppliLocation)
                    ATHLogger.error("\(thisComponent) : \(alertheader) \(alertdetail)", category: .system)
                    _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: [NSLocalizedString("update.alert.button.return", comment: "Return")])
                    isUpdateAvailable = false
                    return
                }
            }
        }

        //MARK: current app removed new one replaces it
        if isUpdateAvailable {
            ATHLogger.info(String(format: NSLocalizedString("log.update.copying_new_version", comment: "Copying new version"), thisComponent, InitGlobVar.thisApplicationName), category: .system)
            notify(title: NSLocalizedString("update.notify.installing", comment: "New Version Install"), informativeText: "")
            guard run("/bin/mv -f \(InitGlobVar.athDirectory)\"/\(InitGlobVar.thisApplicationName).app\" \(InitGlobVar.allAppliLocation)") == "" else {
                alertheader = NSLocalizedString("update.alert.cant_replace_app", comment: "Can't replace application")
                alertdetail = String(format: NSLocalizedString("update.alert.cant_replace_app_detail", comment: "Can't replace app detail"), InitGlobVar.thisApplicationName)
                ATHLogger.error("\(thisComponent) : \(alertheader) \(alertdetail)", category: .system)
                _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: [NSLocalizedString("update.alert.button.return", comment: "Return")])
                isUpdateAvailable = false
                return
            }
        }

        //MARK: update complete, that's all folks
        if isUpdateAvailable {
            while (!InitGlobVar.defaultfileManager.fileExists(atPath: InitGlobVar.thisAppliLocation)) {
                Thread.sleep(forTimeInterval: 0.2)
            }
            if isUpdateAvailable {
                ATHLogger.info(String(format: NSLocalizedString("log.update.complete_launching", comment: "Update complete, launching new version"), thisComponent, InitGlobVar.thisApplicationName), category: .system)
                notify(title: NSLocalizedString("update.notify.complete", comment: "Update Complete, Launching New Version"), informativeText: "")
                _ = run("/usr/bin/open \"\(InitGlobVar.thisAppliLocation)\"")
                exit(0)
            }
        }
    }
    
    static func updateAlert(message: String, text: String, buttonArray: [String]) -> Bool {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = text
        alert.alertStyle = .critical
        buttonArray.forEach { buttonAlerte in
            alert.addButton(withTitle: buttonAlerte)
        }
        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }
    
    /// Shows an informational alert without blocking using a non-modal approach
    /// The alert is displayed but doesn't prevent other UI operations from proceeding
    static func showInformationalAlert(message: String, text: String) {
        DispatchQueue.main.async {
            // Create alert window manually to avoid runModal() blocking
            let alert = NSAlert()
            alert.messageText = message
            alert.informativeText = text
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("update.alert.button.return", comment: "Return"))
            
            // Get the alert's window and show it non-modally
            let window = alert.window
            window.level = .floating
            window.center()
            
            // Use beginSheetModal if we have a main window, otherwise show as floating
            if let mainWindow = NSApplication.shared.mainWindow {
                alert.beginSheetModal(for: mainWindow) { response in
                    // Sheet dismissed, no action needed
                }
            } else {
                // No main window yet, show as non-blocking floating alert
                // We'll make the OK button close the window
                let button = alert.buttons.first
                button?.target = window
                button?.action = #selector(NSWindow.close)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    static func notify(title: String, informativeText: String) -> Void {
        notificationID += 1
        if #available(macOS 10.14, *) {
            let notification   = UNMutableNotificationContent()
            notification.title = title
            notification.body  = informativeText
            notification.sound = UNNotificationSound.default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "ATH \(notificationID)", content: notification, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { (error) in
                if (error != nil) {
                    ATHLogger.error("\(thisComponent) : \(String(describing: error))!", category: .system)
                }
            }
        } else { // macOS 10.13 and less
            let notification = NSUserNotification()
            notification.identifier = "ATH \(notificationID)"
            notification.title = title
            notification.informativeText = informativeText
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)
        }
    }

    static func checkFileExtension(atPath path: String, withExtensions fileExtensionInArray:[String]) -> String {
        let pathURL = NSURL(fileURLWithPath: path, isDirectory: true)
        var fileNameToReturn: String = ""
        if let enumerator = InitGlobVar.defaultfileManager.enumerator(atPath: path) {
            for file in enumerator {
                let pathElement = NSURL(fileURLWithPath: file as! String, relativeTo: pathURL as URL).path
                ATHLogger.debug(String(format: NSLocalizedString("log.update.element_from_archive", comment: "Element from archive"), thisComponent, String(describing: pathElement)), category: .system)
                if pathElement?.replacingOccurrences(of: "%20", with: " ").contains("\(InitGlobVar.athDirectory)/\(InitGlobVar.thisApplicationName)") ?? false {
                    fileExtensionInArray.forEach { extention in
                        if pathElement?.hasSuffix(extention) ?? false {
                            fileNameToReturn = pathElement?.replacingOccurrences(of: "%20", with: " ") ?? ""
                        }
                    }
                }
           }
        }
        ATHLogger.debug(String(format: NSLocalizedString("log.update.element_returned", comment: "Element returned from archive"), thisComponent, fileNameToReturn), category: .system)
        return fileNameToReturn
    }
}
