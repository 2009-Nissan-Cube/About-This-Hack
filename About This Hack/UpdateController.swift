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

    static var latestVersion     :String = ""
    static var latestVersionNum  :Int    = 0
    static var minSystemVersion  :String = "Unknown"
    static var localVersionNum   :Int    = (Int(thisApplicationVersion.replacingOccurrences(of: ".", with: "")) ?? 0)
    static var exeToSearchIsApp  :String = "\(initGlobVar.athDirectory)/\(thisApplicationName).app"
    static var exeToSearchIsDmg  :String = "\(initGlobVar.athDirectory)/\(thisApplicationName)xxx.dmg"
    static var exeToSearch       :String = ""
    static var kindToSearch      :String = "app"
    static var isUpdateAvailable :Bool   = false
    static var alertheader       :String = ""
    static var alertdetail       :Any    = ""
    static var notificationID    :Int    = 0

    static func checkForUpdates() -> Bool {
        print("\(thisComponent) : Checking for updates...")
        latestVersion = run("GIT_TERMINAL_PROMPT=0 git ls-remote --tags --refs \(initGlobVar.athrepositoryURL) | grep \"/tags/[0-9]\" | awk -F'/' '{print  $NF}' | sort -u | tail -n1 | tr -d '\n'")
        if latestVersion != "" && !latestVersion.starts(with: "fatal") {
            print("\(thisComponent) : Local version (\(thisApplicationVersion)) and Remote version (\(latestVersion))")
            latestVersionNum  = (Int(latestVersion.replacingOccurrences(of: ".", with: "")) ?? 0)
            if localVersionNum < latestVersionNum {
                //MARK: newer app found
                print("\(thisComponent) : Newer version (\(latestVersion)) available")
                let prompt = updateAlert(message: "Update found!", text: "The latest version is \(latestVersion).\nYou are currently running \(thisApplicationVersion).", buttonArray: ["Update", "Skip"])
                print("\(thisComponent) : Done")
                exeToSearchIsDmg = exeToSearchIsDmg.replacingOccurrences(of: "xxx.dmg", with: " v\(latestVersion).dmg")
                return prompt
            }
        } else {
            alertheader = "Can't get latest tag version from repo"
            alertdetail = "\(initGlobVar.athrepositoryURL)"
            print("\(thisComponent) : \(alertheader) \(alertdetail)")
            _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: ["Return"])
        }
        return false
    }

    static func updateATH() {
        isUpdateAvailable = true
        
        //MARK: DownLoad new app.zip from repo
        print("\(thisComponent) : Starting Download v\(latestVersion) Update...")
        notify(title: "Starting Download... v\(latestVersion) Update...", informativeText: "")
        guard run("\(initGlobVar.curlLocation) -L \(initGlobVar.lastAthreleaseURL)\(latestVersion)/\(initGlobVar.newAthziprelease) -o \(initGlobVar.newAthreleasezip)") == "" else {
            alertheader = "Can't Download Update"
            alertdetail = "\(initGlobVar.lastAthreleaseURL)\(latestVersion)/\(initGlobVar.newAthziprelease)"
            print("\(thisComponent) : \(alertheader) \(alertdetail)")
            _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: ["Return"])
            isUpdateAvailable = false
            return
        }

        //MARK: unzip new app.zip
        if isUpdateAvailable {
            while (!initGlobVar.defaultfileManager.fileExists(atPath: initGlobVar.newAthreleasezip)) {
                Thread.sleep(forTimeInterval: 0.2)
            }
            print("\(thisComponent) : Unzipping Archive...")
            notify(title: "Unzipping Archive...", informativeText: "")
            guard run("/usr/bin/unzip -q -o \(initGlobVar.newAthreleasezip) -d \(initGlobVar.athDirectory)") == "" else {
                alertheader = "Can't unzip Archive"
                alertdetail = "\(initGlobVar.newAthreleasezip) into \(initGlobVar.athDirectory)"
                print("\(thisComponent) : \(alertheader) \(alertdetail)")
                _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: ["Return"])
                isUpdateAvailable = false
                return
            }
            // what kind of component ".app" or ".dmg"
            var unzippedFile:Bool = false
            while (!unzippedFile) {
                Thread.sleep(forTimeInterval: 0.2)
                if initGlobVar.defaultfileManager.fileExists(atPath: exeToSearchIsApp) {
                    unzippedFile = true
                    exeToSearch = exeToSearchIsApp
                    kindToSearch = "app"
                }
                if initGlobVar.defaultfileManager.fileExists(atPath: exeToSearchIsDmg) {
                    unzippedFile = true
                    exeToSearch = exeToSearchIsDmg
                    kindToSearch = "dmg"
                }
            }
            if kindToSearch == "dmg" {
                print("\(thisComponent) : From archive was extracted : \(exeToSearchIsDmg)")
            } else {
                print("\(thisComponent) : From archive was extracted : \(exeToSearchIsApp)")
            }
        }
        
        //MARK: from new app.zip extracted .dmg or .app
        if isUpdateAvailable && kindToSearch == "dmg" {
            while (!initGlobVar.defaultfileManager.fileExists(atPath: exeToSearch)) {
                Thread.sleep(forTimeInterval: 0.2)
            }
            //MARK: from new app.zip a .dmg extracted must be attached
            print("\(thisComponent) : Try to mount dmg \(exeToSearch)")
            notify(title: "Try to mount dmg...", informativeText: "")
            guard run("/usr/bin/hdiutil attach \"\(exeToSearch)\" -nobrowse -quiet") == "" else {
                alertheader = "Can't mount dmg"
                alertdetail = "\(exeToSearch)"
                print("\(thisComponent) : \(alertheader) \(alertdetail)")
                _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: ["Return"])
                isUpdateAvailable = false
                return
            }
            if isUpdateAvailable {
                while (!initGlobVar.defaultfileManager.fileExists(atPath: "/Volumes/\(thisApplicationName)")) {
                    Thread.sleep(forTimeInterval: 2)
                }
                //MARK: .dmg is mounted containing a .app so we copy it to temp Dir
                print("\(thisComponent) : \(exeToSearch) mounted in /Volumes/\(thisApplicationName)!\n\(thisComponent) : Try to copy application /Volumes/\"\(thisApplicationName)/\(thisApplicationName).app\" to \(initGlobVar.athDirectory)")
                guard run("/bin/cp -prf /Volumes/\"\(thisApplicationName)/\(thisApplicationName).app\" \(initGlobVar.athDirectory)/\"\(thisApplicationName).app\"") == "" else {
                    alertheader = "Can't copy application"
                    alertdetail = "/Volumes/\"\(thisApplicationName)/\(thisApplicationName).app\" to \(initGlobVar.athDirectory)"
                    print("\(thisComponent) : \(alertheader) \(alertdetail)")
                    _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: ["Return"])
                    isUpdateAvailable = false
                    return
                }
            }
            if isUpdateAvailable {
                while (!initGlobVar.defaultfileManager.fileExists(atPath: "\(initGlobVar.athDirectory)/\(thisApplicationName).app")) {
                    Thread.sleep(forTimeInterval: 0.2)
                }
                //MARK: .app from .dmg copied to temp Dir .dmg is detached
                print("\(thisComponent) : /Volumes/\"\(thisApplicationName)/\(thisApplicationName).app\" copied to \(initGlobVar.athDirectory)!")
                print("\(thisComponent) : Try to umount Volume \"/Volumes/\(thisApplicationName)\"")
                notify(title: "Try to umount dmg...", informativeText: "")
                guard run("/usr/bin/hdiutil detach  /Volumes/\"\(thisApplicationName)\" -force -quiet") == "" else {
                    alertheader = "Can't umount \(thisApplicationName)dmg"
                    alertdetail = "/Volumes/\"\(thisApplicationName)\""
                    print("\(thisComponent) : \(alertheader) \(alertdetail)")
                    _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: ["Return"])
                    isUpdateAvailable = false
                    return
                }
                print("\(thisComponent) : /Volumes/\"\(thisApplicationName)\" ejected!")
            }
        }
        
        //MARK: does this new .app alowed on this OS version
        if isUpdateAvailable {
            while (!initGlobVar.defaultfileManager.fileExists(atPath: "\(initGlobVar.athDirectory)/\(thisApplicationName).app")) {
                Thread.sleep(forTimeInterval: 0.2)
            }
            print("\(thisComponent) : Is new app v\(latestVersion) allowed on current OS \(HCVersion.OSnum)?")
            notify(title: "Is new app v\(latestVersion) allowed...", informativeText: "")
            let plistNewVersion = "\(initGlobVar.athDirectory)/\(thisApplicationName).app/Contents/Info.plist"
            if initGlobVar.defaultfileManager.fileExists(atPath: "\(plistNewVersion)") {
                if let resourceFileDictionaryContent = NSDictionary(contentsOfFile: "\(plistNewVersion)") {
                    // Get "LSMinimumSystemVersion" value by key
                    minSystemVersion = resourceFileDictionaryContent.object(forKey: "LSMinimumSystemVersion")! as! String
                }
            }
            if minSystemVersion == "Unknown" || minSystemVersion == "" { //plistNewVersion not found or LSMinimumSystemVersion key not found
                alertheader = "Can't get Minimum OS Version"
                alertdetail = "LSMinimumSystemVersion not found in\n\"\(plistNewVersion)\""
                print("\(thisComponent) : \(alertheader) \(alertdetail)")
                _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: ["Return"])
                isUpdateAvailable = false
                return
            } else {
                let arrayMinOSVersion:[String] = minSystemVersion.components(separatedBy: ".")
                let arrayCurOSVersion:[String] = HCVersion.OSnum.components(separatedBy: ".")
                var minCountIndex:Int = 0
                var allowed:Bool = true
                if arrayMinOSVersion.count > arrayCurOSVersion.count {
                    minCountIndex = arrayCurOSVersion.count
                } else {
                    minCountIndex = arrayMinOSVersion.count
                }
                print("\(thisComponent) : Current OS version \(HCVersion.OSnum) and Minimum OS Version \(minSystemVersion)")
                for index in 0...minCountIndex-1 {
                    if arrayCurOSVersion[index] < arrayMinOSVersion[index] {
                        allowed = false
                        break
                    } else {
                        if arrayCurOSVersion[index] > arrayMinOSVersion[index] {
                            break
                        }
                    } // if arrayCurOSVersion[index] = arrayMinOSVersion[index] go on to check with next index (next part of tows versions)
                    print("\(thisComponent) : Index (\(index)) : Current OS version \(arrayCurOSVersion[index]) and Minimum OS Version \(arrayMinOSVersion[index])")
                }
                if !allowed {
                    alertheader = "Update can't be achieve"
                    alertdetail = "Minimum OS Version \(minSystemVersion) is greater than current OS version \(HCVersion.OSnum)"
                    print("\(thisComponent) : \(alertheader) \(alertdetail)")
                    _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: ["Return"])
                    isUpdateAvailable = false
                    return
                } else {
                    print("\(thisComponent) : Update (with \(minSystemVersion) as minimum OS version ) is allowed on current OS version \(HCVersion.OSnum)")
                }
            }
        }

        //MARK: this new .app allowed current app is removed before installing new one
        if isUpdateAvailable && initGlobVar.defaultfileManager.fileExists(atPath: initGlobVar.thisAppliLocation) {
            while (!initGlobVar.defaultfileManager.fileExists(atPath: exeToSearch)) {
                Thread.sleep(forTimeInterval: 0.2)
            }
            print("\(thisComponent) : Removing Old App...")
            notify(title: "Removing Old App...", informativeText: "")
            if initGlobVar.defaultfileManager.fileExists(atPath: initGlobVar.thisAppliLocation) {
                do {
                    try initGlobVar.defaultfileManager.removeItem(atPath: "\(initGlobVar.thisAppliLocation)")
                    print("\(thisComponent) : Directory \(initGlobVar.thisAppliLocation) deleted successfully")
                } catch {
                    print("\(thisComponent) : Error deleting Directory \(initGlobVar.thisAppliLocation) with error : (\(error))")
                    alertheader = "Failed to delete the old copy of"
                    alertdetail = "\(initGlobVar.thisAppliLocation)\nPlease make sure it is in \(initGlobVar.allAppliLocation) folder!!!"
                    print("\(thisComponent) : \(alertheader) \(alertdetail)")
                    _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: ["Return"])
                    isUpdateAvailable = false
                    return
                }
            }
        }

        //MARK: current app removed new one replaces it
        if isUpdateAvailable {
            print("\(thisComponent) : Copying New Version \"/\(thisApplicationName).app\" Almost there!")
            notify(title: "New Version Install...", informativeText: "")
            guard run("/bin/mv -f \(initGlobVar.athDirectory)\"/\(thisApplicationName).app\" \(initGlobVar.allAppliLocation)") == "" else {
                alertheader = "Can't replace application"
                alertdetail = "\"\(thisApplicationName)\""
                print("\(thisComponent) : \(alertheader) \(alertdetail)")
                _ = updateAlert(message: "\(alertheader)", text: "\(alertdetail)", buttonArray: ["Return"])
                isUpdateAvailable = false
                return
            }
        }

        //MARK: update complete, that's all folks
        if isUpdateAvailable {
            while (!initGlobVar.defaultfileManager.fileExists(atPath: initGlobVar.thisAppliLocation)) {
                Thread.sleep(forTimeInterval: 0.2)
            }
            if isUpdateAvailable {
                print("\(thisComponent) : Update Complete!...Launching New \"\(thisApplicationName).app\" Version...")
                notify(title: "Update Complete...Launching  New Version...", informativeText: "")
                _ = run("/usr/bin/open \"\(initGlobVar.thisAppliLocation)\"")
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
                    print("\(thisComponent) : \(String(describing: error))!")
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
    
}
