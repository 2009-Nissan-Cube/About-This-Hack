//
//  UpdateController.swift
//

import Foundation
import AppKit
import Cocoa
import UserNotifications
import ZIPFoundation

class UpdateController {
    private struct GitHubRelease: Decodable {
        let tagName: String
        let name: String
        let assets: [GitHubReleaseAsset]

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case name
            case assets
        }

        var versionString: String {
            let preferred = sanitizedVersionString(from: name)
            if !preferred.isEmpty {
                return preferred
            }
            return sanitizedVersionString(from: tagName)
        }
    }

    private struct GitHubReleaseAsset: Decodable {
        let name: String
        let contentType: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case contentType = "content_type"
            case browserDownloadURL = "browser_download_url"
        }
    }

    private enum UpdateError: Error {
        case invalidReleaseVersion
        case invalidReleaseResponse
        case invalidDownloadResponse
        case latestReleaseRequestFailed(Error)
        case latestReleaseStatusCode(Int)
        case latestReleaseDecodeFailed(Error)
        case noDownloadableAsset
        case downloadFailed(assetName: String, underlying: Error?)
        case unzipFailed(archivePath: String, destinationPath: String, underlying: Error)
        case noInstallableBundle(searchRoot: String)
        case mountFailed(diskImagePath: String, details: String)
        case mountedAppMissing(volumePath: String)
        case copyFailed(sourcePath: String, destinationPath: String, underlying: Error)
        case minimumSystemVersionMissing(infoPlistPath: String)
        case incompatibleSystemVersion(required: String, current: String)
        case installFailed(destinationPath: String, underlying: Error)
        case relaunchFailed(appPath: String, underlying: Error?)

        var alertMessage: String {
            switch self {
            case .latestReleaseRequestFailed, .latestReleaseStatusCode, .latestReleaseDecodeFailed, .invalidReleaseResponse:
                return NSLocalizedString("update.alert.cant_get_version", comment: "Can't get version from remote repo")
            case .downloadFailed:
                return NSLocalizedString("update.alert.cant_download", comment: "Can't Download Update")
            case .unzipFailed:
                return NSLocalizedString("update.alert.cant_unzip", comment: "Can't unzip Archive")
            case .noDownloadableAsset, .noInstallableBundle:
                return NSLocalizedString("update.alert.cant_find_extension", comment: "Can't find .app or .dmg extension")
            case .mountFailed:
                return NSLocalizedString("update.alert.cant_mount_dmg", comment: "Can't mount dmg")
            case .mountedAppMissing, .copyFailed:
                return NSLocalizedString("update.alert.cant_copy_app", comment: "Can't copy application")
            case .minimumSystemVersionMissing:
                return NSLocalizedString("update.alert.cant_get_min_os", comment: "Can't get Minimum OS Version")
            case .incompatibleSystemVersion:
                return NSLocalizedString("update.alert.update_cant_be_achieved", comment: "Update can't be achieved")
            case .installFailed, .relaunchFailed:
                return NSLocalizedString("update.alert.cant_replace_app", comment: "Can't replace application")
            case .invalidReleaseVersion:
                return NSLocalizedString("update.alert.cant_get_version", comment: "Can't get version from remote repo")
            case .invalidDownloadResponse:
                return NSLocalizedString("update.alert.cant_download", comment: "Can't Download Update")
            }
        }

        var alertDetail: String {
            switch self {
            case .latestReleaseRequestFailed:
                return InitGlobVar.athrepositoryURL
            case .latestReleaseStatusCode(let code):
                return "\(InitGlobVar.latestReleaseAPIURL) (HTTP \(code))"
            case .latestReleaseDecodeFailed(let error):
                return error.localizedDescription
            case .invalidReleaseResponse:
                return InitGlobVar.latestReleaseAPIURL
            case .downloadFailed(let assetName, let underlying):
                if let underlying {
                    return "\(assetName)\n\(underlying.localizedDescription)"
                }
                return assetName
            case .unzipFailed(let archivePath, let destinationPath, _):
                return String(format: NSLocalizedString("update.alert.cant_unzip_detail", comment: "Archive unzip detail"), archivePath, destinationPath)
            case .noDownloadableAsset:
                return InitGlobVar.athrepositoryURL
            case .noInstallableBundle(let searchRoot):
                return String(format: NSLocalizedString("update.alert.cant_unzip_detail", comment: "Archive extraction detail"), searchRoot, InitGlobVar.updateDirectory)
            case .mountFailed(let diskImagePath, let details):
                return details.isEmpty ? diskImagePath : "\(diskImagePath)\n\(details)"
            case .mountedAppMissing(let volumePath):
                return String(format: NSLocalizedString("update.alert.cant_copy_app_detail", comment: "Can't copy app detail"), InitGlobVar.thisApplicationName, InitGlobVar.thisApplicationName, volumePath)
            case .copyFailed(let sourcePath, let destinationPath, let underlying):
                return "\(sourcePath)\n\(destinationPath)\n\(underlying.localizedDescription)"
            case .minimumSystemVersionMissing(let infoPlistPath):
                return String(format: NSLocalizedString("update.alert.cant_get_min_os_detail", comment: "LSMinimumSystemVersion not found"), infoPlistPath)
            case .incompatibleSystemVersion(let required, let current):
                return String(format: NSLocalizedString("update.alert.update_cant_be_achieved_detail", comment: "Update can't be achieved detail"), required, current)
            case .installFailed(let destinationPath, let underlying):
                return "\(destinationPath)\n\(underlying.localizedDescription)"
            case .relaunchFailed(let appPath, let underlying):
                if let underlying {
                    return "\(appPath)\n\(underlying.localizedDescription)"
                }
                return appPath
            case .invalidReleaseVersion:
                return InitGlobVar.latestReleaseAPIURL
            case .invalidDownloadResponse:
                return InitGlobVar.athrepositoryURL
            }
        }

        var logDescription: String {
            switch self {
            case .latestReleaseRequestFailed(let error):
                return error.localizedDescription
            case .latestReleaseStatusCode(let code):
                return "HTTP \(code)"
            case .latestReleaseDecodeFailed(let error):
                return error.localizedDescription
            case .downloadFailed(_, let underlying):
                return underlying?.localizedDescription ?? alertDetail
            case .unzipFailed(_, _, let underlying):
                return underlying.localizedDescription
            case .copyFailed(_, _, let underlying):
                return underlying.localizedDescription
            case .installFailed(_, let underlying):
                return underlying.localizedDescription
            case .relaunchFailed(_, let underlying):
                return underlying?.localizedDescription ?? alertDetail
            default:
                return alertDetail
            }
        }
    }

    static var thisComponent: String {
        String(describing: self)
    }

    private static let updateCheckTimeout: TimeInterval = 10.0
    private static let downloadTimeout: TimeInterval = 120.0
    private static let updateQueue = DispatchQueue(label: "AboutThisHack.UpdateController", qos: .userInitiated)
    private static var pendingRelease: GitHubRelease?

    static func checkForUpdatesAsync(completion: @escaping (Bool) -> Void) {
        ATHLogger.info(String(format: NSLocalizedString("log.update.checking", comment: "Checking for updates"), thisComponent), category: .system)

        fetchLatestRelease(timeout: updateCheckTimeout) { result in
            switch result {
            case .success(let release):
                let remoteVersion = release.versionString
                guard !remoteVersion.isEmpty else {
                    DispatchQueue.main.async {
                        presentInformationalUpdateError(.invalidReleaseVersion)
                        completion(false)
                    }
                    return
                }

                ATHLogger.info(String(format: NSLocalizedString("log.update.versions", comment: "Local and remote versions"), thisComponent, thisApplicationVersion, remoteVersion, release.tagName), category: .system)

                guard compareVersionStrings(thisApplicationVersion, remoteVersion) == .orderedAscending else {
                    ATHLogger.info(String(format: NSLocalizedString("log.update.done", comment: "Update check done"), thisComponent), category: .system)
                    DispatchQueue.main.async {
                        pendingRelease = nil
                        completion(false)
                    }
                    return
                }

                ATHLogger.info(String(format: NSLocalizedString("log.update.newer_version", comment: "Newer version available"), thisComponent, remoteVersion), category: .system)

                DispatchQueue.main.async {
                    let shouldUpdate = updateAlert(
                        message: NSLocalizedString("update.alert.update_found", comment: "Update found!"),
                        text: String(format: NSLocalizedString("update.alert.latest_version", comment: "Latest version info"), remoteVersion, thisApplicationVersion),
                        buttonArray: [
                            NSLocalizedString("update.alert.button.update", comment: "Update"),
                            NSLocalizedString("update.alert.button.skip", comment: "Skip")
                        ]
                    )
                    pendingRelease = shouldUpdate ? release : nil
                    ATHLogger.info(String(format: NSLocalizedString("log.update.done", comment: "Update check done"), thisComponent), category: .system)
                    completion(shouldUpdate)
                }

            case .failure(let error):
                DispatchQueue.main.async {
                    if let updateError = error as? UpdateError {
                        presentInformationalUpdateError(updateError)
                    } else {
                        presentInformationalUpdateError(.latestReleaseRequestFailed(error))
                    }
                    completion(false)
                }
            }
        }
    }

    static func updateATH() {
        updateQueue.async {
            guard let release = pendingRelease else {
                DispatchQueue.main.async {
                    presentInformationalUpdateError(.invalidReleaseVersion)
                }
                return
            }

            defer {
                pendingRelease = nil
            }

            do {
                let fileManager = InitGlobVar.defaultfileManager
                try prepareUpdateDirectory(using: fileManager)
                let asset = try preferredAsset(from: release)
                let downloadedAssetURL = try downloadAsset(asset, releaseVersion: release.versionString, using: fileManager)
                let installableItemURL = try extractInstallableItem(from: downloadedAssetURL, asset: asset, using: fileManager)
                let candidateApplicationURL = try prepareApplicationBundle(from: installableItemURL, using: fileManager)
                try validateMinimumSystemVersion(for: candidateApplicationURL, releaseVersion: release.versionString)
                try installApplication(from: candidateApplicationURL, using: fileManager)
                try relaunchInstalledApplication()
            } catch let error as UpdateError {
                presentBlockingUpdateError(error)
            } catch {
                presentBlockingUpdateError(.installFailed(destinationPath: InitGlobVar.thisAppliLocation, underlying: error))
            }
        }
    }

    private static func sanitizedVersionString(from value: String) -> String {
        let components = numericVersionComponents(from: value)
        guard !components.isEmpty else {
            return ""
        }
        return components.map(String.init).joined(separator: ".")
    }

    private static func makeGitHubRequest(for url: URL, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("AboutThisHack/\(thisApplicationVersion)", forHTTPHeaderField: "User-Agent")
        return request
    }

    private static func fetchLatestRelease(timeout: TimeInterval, completion: @escaping (Result<GitHubRelease, Error>) -> Void) {
        guard let url = URL(string: InitGlobVar.latestReleaseAPIURL) else {
            completion(.failure(UpdateError.invalidReleaseResponse))
            return
        }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout

        let session = URLSession(configuration: configuration)
        let task = session.dataTask(with: makeGitHubRequest(for: url, timeout: timeout)) { data, response, error in
            defer {
                session.finishTasksAndInvalidate()
            }

            if let error {
                completion(.failure(UpdateError.latestReleaseRequestFailed(error)))
                return
            }

            guard let response = response as? HTTPURLResponse else {
                completion(.failure(UpdateError.invalidReleaseResponse))
                return
            }

            guard (200..<300).contains(response.statusCode) else {
                completion(.failure(UpdateError.latestReleaseStatusCode(response.statusCode)))
                return
            }

            guard let data else {
                completion(.failure(UpdateError.invalidReleaseResponse))
                return
            }

            do {
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                completion(.success(release))
            } catch {
                completion(.failure(UpdateError.latestReleaseDecodeFailed(error)))
            }
        }
        task.resume()
    }

    private static func preferredAsset(from release: GitHubRelease) throws -> GitHubReleaseAsset {
        if let zipAsset = release.assets.first(where: { $0.name.lowercased().hasSuffix(".zip") || $0.contentType.lowercased().contains("zip") }) {
            return zipAsset
        }

        if let dmgAsset = release.assets.first(where: { $0.name.lowercased().hasSuffix(".dmg") }) {
            return dmgAsset
        }

        throw UpdateError.noDownloadableAsset
    }

    private static func prepareUpdateDirectory(using fileManager: FileManager) throws {
        if fileManager.fileExists(atPath: InitGlobVar.updateDirectory) {
            try fileManager.removeItem(at: InitGlobVar.updateDirectoryURL)
        }
        try fileManager.createDirectory(at: InitGlobVar.updateDirectoryURL, withIntermediateDirectories: true)
    }

    private static func downloadAsset(_ asset: GitHubReleaseAsset, releaseVersion: String, using fileManager: FileManager) throws -> URL {
        ATHLogger.info(String(format: NSLocalizedString("log.update.starting_download", comment: "Starting download"), thisComponent, releaseVersion), category: .system)
        notify(title: String(format: NSLocalizedString("update.notify.starting_download", comment: "Starting Download"), releaseVersion), informativeText: "")

        let destinationURL = InitGlobVar.updateDirectoryURL.appendingPathComponent(asset.name)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = downloadTimeout
        configuration.timeoutIntervalForResource = downloadTimeout

        let session = URLSession(configuration: configuration)
        let semaphore = DispatchSemaphore(value: 0)
        var outcome: Result<URL, UpdateError> = .failure(.downloadFailed(assetName: asset.name, underlying: nil))

        let task = session.downloadTask(with: makeGitHubRequest(for: asset.browserDownloadURL, timeout: downloadTimeout)) { temporaryURL, response, error in
            defer {
                session.finishTasksAndInvalidate()
                semaphore.signal()
            }

            if let error {
                outcome = .failure(.downloadFailed(assetName: asset.name, underlying: error))
                return
            }

            guard let response = response as? HTTPURLResponse, (200..<300).contains(response.statusCode) else {
                outcome = .failure(.invalidDownloadResponse)
                return
            }

            guard let temporaryURL else {
                outcome = .failure(.downloadFailed(assetName: asset.name, underlying: nil))
                return
            }

            do {
                if fileManager.fileExists(atPath: destinationURL.path) {
                    try fileManager.removeItem(at: destinationURL)
                }
                try fileManager.moveItem(at: temporaryURL, to: destinationURL)
                outcome = .success(destinationURL)
            } catch {
                outcome = .failure(.downloadFailed(assetName: asset.name, underlying: error))
            }
        }

        task.resume()
        semaphore.wait()
        return try outcome.get()
    }

    private static func extractInstallableItem(from downloadedAssetURL: URL, asset: GitHubReleaseAsset, using fileManager: FileManager) throws -> URL {
        if asset.name.lowercased().hasSuffix(".dmg") {
            return downloadedAssetURL
        }

        ATHLogger.info(String(format: NSLocalizedString("log.update.unzipping", comment: "Unzipping archive"), thisComponent), category: .system)
        notify(title: NSLocalizedString("update.notify.unzipping", comment: "Unzipping Archive"), informativeText: "")

        let extractionURL = InitGlobVar.updateDirectoryURL.appendingPathComponent("Extracted", isDirectory: true)
        try fileManager.createDirectory(at: extractionURL, withIntermediateDirectories: true)

        do {
            try fileManager.unzipItem(at: downloadedAssetURL, to: extractionURL)
        } catch {
            throw UpdateError.unzipFailed(archivePath: downloadedAssetURL.path, destinationPath: extractionURL.path, underlying: error)
        }

        let installableItemURL = try locateInstallableItem(in: extractionURL, using: fileManager)
        ATHLogger.info(String(format: NSLocalizedString("log.update.extracted", comment: "File extracted from archive"), thisComponent, installableItemURL.path), category: .system)
        return installableItemURL
    }

    private static func locateInstallableItem(in directoryURL: URL, using fileManager: FileManager) throws -> URL {
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey]
        guard let enumerator = fileManager.enumerator(at: directoryURL, includingPropertiesForKeys: resourceKeys, options: [.skipsHiddenFiles]) else {
            throw UpdateError.noInstallableBundle(searchRoot: directoryURL.path)
        }

        var appCandidates = [URL]()
        var dmgCandidates = [URL]()

        for case let fileURL as URL in enumerator {
            ATHLogger.debug(String(format: NSLocalizedString("log.update.element_from_archive", comment: "Element from archive"), thisComponent, fileURL.path), category: .system)
            switch fileURL.pathExtension.lowercased() {
            case "app":
                appCandidates.append(fileURL)
            case "dmg":
                dmgCandidates.append(fileURL)
            default:
                continue
            }
        }

        let preferredAppName = "\(InitGlobVar.thisApplicationName).app"
        let candidate = appCandidates.first(where: { $0.lastPathComponent == preferredAppName })
            ?? appCandidates.first
            ?? dmgCandidates.first

        guard let candidate else {
            throw UpdateError.noInstallableBundle(searchRoot: directoryURL.path)
        }

        ATHLogger.debug(String(format: NSLocalizedString("log.update.element_returned", comment: "Element returned from archive"), thisComponent, candidate.path), category: .system)
        return candidate
    }

    private static func prepareApplicationBundle(from installableItemURL: URL, using fileManager: FileManager) throws -> URL {
        if installableItemURL.pathExtension.lowercased() == "app" {
            return installableItemURL
        }

        ATHLogger.info(String(format: NSLocalizedString("log.update.mounting_dmg", comment: "Try to mount dmg"), thisComponent, installableItemURL.path), category: .system)
        notify(title: NSLocalizedString("update.notify.mounting_dmg", comment: "Try to mount dmg"), informativeText: "")

        let mountPoint = try mountDiskImage(at: installableItemURL)
        defer {
            do {
                try detachDiskImage(at: mountPoint)
                ATHLogger.info(String(format: NSLocalizedString("log.update.dmg_ejected", comment: "DMG ejected"), thisComponent, InitGlobVar.thisApplicationName), category: .system)
            } catch {
                ATHLogger.warning("\(thisComponent) : \(error.localizedDescription)", category: .system)
            }
        }

        let mountedAppURL = try locateMountedApplication(in: mountPoint, using: fileManager)
        let stagedAppURL = InitGlobVar.updateDirectoryURL.appendingPathComponent("\(InitGlobVar.thisApplicationName).app", isDirectory: true)

        ATHLogger.info(String(format: NSLocalizedString("log.update.dmg_mounted", comment: "DMG mounted and copying"), thisComponent, installableItemURL.path, InitGlobVar.thisApplicationName, thisComponent, InitGlobVar.thisApplicationName, InitGlobVar.thisApplicationName, InitGlobVar.updateDirectory), category: .system)

        do {
            if fileManager.fileExists(atPath: stagedAppURL.path) {
                try fileManager.removeItem(at: stagedAppURL)
            }
            try fileManager.copyItem(at: mountedAppURL, to: stagedAppURL)
        } catch {
            throw UpdateError.copyFailed(sourcePath: mountedAppURL.path, destinationPath: stagedAppURL.path, underlying: error)
        }

        ATHLogger.info(String(format: NSLocalizedString("log.update.app_copied", comment: "App copied to directory"), thisComponent, InitGlobVar.thisApplicationName, InitGlobVar.thisApplicationName, InitGlobVar.updateDirectory), category: .system)
        return stagedAppURL
    }

    private static func mountDiskImage(at diskImageURL: URL) throws -> URL {
        let result = executeProcess(
            executableURL: URL(fileURLWithPath: "/usr/bin/hdiutil"),
            arguments: ["attach", diskImageURL.path, "-nobrowse", "-plist", "-quiet"]
        )

        guard result.succeeded else {
            throw UpdateError.mountFailed(diskImagePath: diskImageURL.path, details: result.combinedOutput)
        }

        guard let outputData = result.stdout.data(using: .utf8),
              let plist = try PropertyListSerialization.propertyList(from: outputData, format: nil) as? [String: Any],
              let systemEntities = plist["system-entities"] as? [[String: Any]],
              let mountPath = systemEntities.compactMap({ $0["mount-point"] as? String }).first else {
            throw UpdateError.mountFailed(diskImagePath: diskImageURL.path, details: result.stdout)
        }

        return URL(fileURLWithPath: mountPath, isDirectory: true)
    }

    private static func detachDiskImage(at mountPoint: URL) throws {
        ATHLogger.info(String(format: NSLocalizedString("log.update.unmounting_dmg", comment: "Try to unmount dmg"), thisComponent, InitGlobVar.thisApplicationName), category: .system)
        notify(title: NSLocalizedString("update.notify.unmounting_dmg", comment: "Try to unmount dmg"), informativeText: "")

        let result = executeProcess(
            executableURL: URL(fileURLWithPath: "/usr/bin/hdiutil"),
            arguments: ["detach", mountPoint.path, "-force", "-quiet"]
        )

        guard result.succeeded else {
            throw UpdateError.mountFailed(diskImagePath: mountPoint.path, details: result.combinedOutput)
        }
    }

    private static func locateMountedApplication(in mountPoint: URL, using fileManager: FileManager) throws -> URL {
        guard let enumerator = fileManager.enumerator(at: mountPoint, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            throw UpdateError.mountedAppMissing(volumePath: mountPoint.path)
        }

        let preferredAppName = "\(InitGlobVar.thisApplicationName).app"
        var fallbackAppURL: URL?

        for case let candidateURL as URL in enumerator {
            guard candidateURL.pathExtension.lowercased() == "app" else {
                continue
            }
            if candidateURL.lastPathComponent == preferredAppName {
                return candidateURL
            }
            fallbackAppURL = fallbackAppURL ?? candidateURL
        }

        if let fallbackAppURL {
            return fallbackAppURL
        }

        throw UpdateError.mountedAppMissing(volumePath: mountPoint.path)
    }

    private static func validateMinimumSystemVersion(for applicationURL: URL, releaseVersion: String) throws {
        ATHLogger.info(String(format: NSLocalizedString("log.update.checking_os_compatibility", comment: "Checking OS compatibility"), thisComponent, releaseVersion, HCVersion.shared.osNumber), category: .system)
        notify(title: String(format: NSLocalizedString("update.notify.checking_allowed", comment: "Checking if new app is allowed"), releaseVersion), informativeText: "")

        let infoPlistURL = applicationURL.appendingPathComponent("Contents/Info.plist")
        guard let infoDictionary = NSDictionary(contentsOf: infoPlistURL) as? [String: Any],
              let minimumSystemVersion = infoDictionary["LSMinimumSystemVersion"] as? String,
              !minimumSystemVersion.isEmpty else {
            throw UpdateError.minimumSystemVersionMissing(infoPlistPath: infoPlistURL.path)
        }

        ATHLogger.info(String(format: NSLocalizedString("log.update.os_versions", comment: "Current and minimum OS versions"), thisComponent, HCVersion.shared.osNumber, minimumSystemVersion), category: .system)

        guard isVersion(HCVersion.shared.osNumber, atLeast: minimumSystemVersion) else {
            throw UpdateError.incompatibleSystemVersion(required: minimumSystemVersion, current: HCVersion.shared.osNumber)
        }

        ATHLogger.info(String(format: NSLocalizedString("log.update.update_allowed", comment: "Update is allowed"), thisComponent, minimumSystemVersion, HCVersion.shared.osNumber), category: .system)
    }

    private static func installApplication(from candidateApplicationURL: URL, using fileManager: FileManager) throws {
        ATHLogger.info(String(format: NSLocalizedString("log.update.copying_new_version", comment: "Copying new version"), thisComponent, InitGlobVar.thisApplicationName), category: .system)
        notify(title: NSLocalizedString("update.notify.installing", comment: "New Version Install"), informativeText: "")

        let stagedApplicationURL = InitGlobVar.applicationsDirectoryURL.appendingPathComponent("\(InitGlobVar.thisApplicationName).app.update-staging", isDirectory: true)

        do {
            if fileManager.fileExists(atPath: stagedApplicationURL.path) {
                try fileManager.removeItem(at: stagedApplicationURL)
            }
            try fileManager.copyItem(at: candidateApplicationURL, to: stagedApplicationURL)

            if fileManager.fileExists(atPath: InitGlobVar.installedApplicationURL.path) {
                _ = try fileManager.replaceItemAt(InitGlobVar.installedApplicationURL, withItemAt: stagedApplicationURL, backupItemName: nil, options: .usingNewMetadataOnly)
            } else {
                try fileManager.moveItem(at: stagedApplicationURL, to: InitGlobVar.installedApplicationURL)
            }
        } catch {
            throw UpdateError.installFailed(destinationPath: InitGlobVar.thisAppliLocation, underlying: error)
        }
    }

    private static func relaunchInstalledApplication() throws {
        ATHLogger.info(String(format: NSLocalizedString("log.update.complete_launching", comment: "Update complete, launching new version"), thisComponent, InitGlobVar.thisApplicationName), category: .system)
        notify(title: NSLocalizedString("update.notify.complete", comment: "Update Complete, Launching New Version"), informativeText: "")

        let semaphore = DispatchSemaphore(value: 0)
        var relaunchError: UpdateError?

        DispatchQueue.main.async {
            NSWorkspace.shared.openApplication(at: InitGlobVar.installedApplicationURL, configuration: NSWorkspace.OpenConfiguration()) { _, error in
                if let error {
                    relaunchError = .relaunchFailed(appPath: InitGlobVar.thisAppliLocation, underlying: error)
                }
                semaphore.signal()
            }
        }

        semaphore.wait()

        if let relaunchError {
            throw relaunchError
        }

        exit(0)
    }

    private static func presentInformationalUpdateError(_ error: UpdateError) {
        ATHLogger.error("\(thisComponent) : \(error.alertMessage) \(error.logDescription)", category: .system)
        showInformationalAlert(message: error.alertMessage, text: error.alertDetail)
    }

    private static func presentBlockingUpdateError(_ error: UpdateError) {
        ATHLogger.error("\(thisComponent) : \(error.alertMessage) \(error.logDescription)", category: .system)
        DispatchQueue.main.sync {
            _ = updateAlert(
                message: error.alertMessage,
                text: error.alertDetail,
                buttonArray: [NSLocalizedString("update.alert.button.return", comment: "Return")]
            )
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

    static func showInformationalAlert(message: String, text: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = message
            alert.informativeText = text
            alert.alertStyle = .warning
            alert.addButton(withTitle: NSLocalizedString("update.alert.button.return", comment: "Return"))

            let window = alert.window
            window.level = .floating
            window.center()

            if let mainWindow = NSApplication.shared.mainWindow {
                alert.beginSheetModal(for: mainWindow) { _ in
                }
            } else {
                let button = alert.buttons.first
                button?.target = window
                button?.action = #selector(NSWindow.close)
                window.makeKeyAndOrderFront(nil)
            }
        }
    }

    static func notify(title: String, informativeText: String) {
        notificationID += 1
        if #available(macOS 10.14, *) {
            let notification = UNMutableNotificationContent()
            notification.title = title
            notification.body = informativeText
            notification.sound = UNNotificationSound.default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: "ATH \(notificationID)", content: notification, trigger: trigger)
            UNUserNotificationCenter.current().add(request) { error in
                if let error {
                    ATHLogger.error("\(thisComponent) : \(String(describing: error))!", category: .system)
                }
            }
        } else {
            let notification = NSUserNotification()
            notification.identifier = "ATH \(notificationID)"
            notification.title = title
            notification.informativeText = informativeText
            notification.soundName = NSUserNotificationDefaultSoundName
            NSUserNotificationCenter.default.deliver(notification)
        }
    }

    private static var notificationID: Int = 0
}
