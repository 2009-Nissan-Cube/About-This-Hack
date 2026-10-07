//
//  InitGlobalVariables.swift
//

import Foundation

enum InitGlobVar {
    static var thisApplicationName: String {
        (Bundle.main.applicationName ?? "").replacingOccurrences(of: ".app", with: "")
    }

    static let athDirectoryURL = URL(fileURLWithPath: "/private/tmp/.ath", isDirectory: true)
    static let updateDirectoryURL = athDirectoryURL.appendingPathComponent("update", isDirectory: true)

    // Used by UpdateController
    static let athrepositoryURL = "https://github.com/2009-Nissan-Cube/About-This-Hack"
    static let latestReleaseAPIURL = "https://api.github.com/repos/2009-Nissan-Cube/About-This-Hack/releases/latest"
    static let allAppliLocation = "/Applications"

    /// Bundle replaced by updates. Prefer the running .app so launching from
    /// Downloads or a DMG doesn't replace the copy in /Applications.
    static var installedApplicationURL: URL {
        let bundleURL = Bundle.main.bundleURL
        if bundleURL.pathExtension.lowercased() == "app" {
            return bundleURL.standardizedFileURL
        }
        return URL(fileURLWithPath: allAppliLocation, isDirectory: true).appendingPathComponent("\(thisApplicationName).app", isDirectory: true)
    }

    static var thisAppliLocation: String {
        installedApplicationURL.path
    }

    // OCLP plist with the patch version, commit, and date
    static let oclpXmlFilePath = "/System/Library/CoreServices/OpenCore-Legacy-Patcher.plist"

    // Used by the overview and displays views
    static let systemReportSP = "/System/Library/SystemProfiler/SPPlatformReporter.spreporter"
    static let softwareUpdateSP = "/System/Library/PreferencePanes/SoftwareUpdate.prefPane"
    static let displayPrefPane = "/System/Library/PreferencePanes/Displays.prefPane"

    // Used by the support view
    static let macOSUserGuideURL = "https://support.apple.com/guide/mac-help/welcome/mac"
    static let whatsNewInMacOSURL = "https://www.apple.com/macos/"
    static let AppleSupportURL = "https://support.apple.com"
    static let HackintoshInstallURL = "https://dortania.github.io/OpenCore-Install-Guide/troubleshooting/troubleshooting.html#table-of-contents"
    static let MacBasicsURL = "https://help.apple.com/macos/big-sur/mac-basics/"
    static let MacUserGuideURL = "https://support.apple.com/manuals"

    static let nvramOpencoreVersion = "4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version"
}
