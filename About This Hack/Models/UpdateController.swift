//
//  UpdateController.swift
//

import AppKit
import UserNotifications
import ZIPFoundation

enum UpdateController {
    private struct Release: Decodable {
        let tagName: String
        let name: String
        let assets: [Asset]

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name", name, assets
        }

        var version: String {
            sanitizedVersion(tagName).nilIfEmpty ?? sanitizedVersion(name)
        }
    }

    private struct Asset: Decodable {
        let name: String
        let contentType: String
        let browserDownloadURL: URL

        enum CodingKeys: String, CodingKey {
            case name, contentType = "content_type", browserDownloadURL = "browser_download_url"
        }

        var isZip: Bool { name.lowercased().hasSuffix(".zip") || contentType.lowercased().contains("zip") }
        var isDiskImage: Bool { name.lowercased().hasSuffix(".dmg") }
    }

    /// A localized alert title (`update.alert.<key>`) plus technical detail.
    private struct UpdateError: Error {
        let message: String
        let detail: String

        init(_ key: String, _ detail: String) {
            message = NSLocalizedString("update.alert.\(key)", comment: "Update error title")
            self.detail = detail
        }
    }

    private static let updateQueue = DispatchQueue(label: "AboutThisHack.UpdateController", qos: .userInitiated)
    private static var appName: String { InitGlobVar.thisApplicationName }

    /// Checks GitHub for a newer release and, if the user agrees, installs it and relaunches.
    /// Network failures stay silent so an offline launch doesn't nag.
    static func checkForUpdates() {
        guard let url = URL(string: InitGlobVar.latestReleaseAPIURL) else { return }

        URLSession.shared.dataTask(with: request(url, timeout: 10)) { data, response, error in
            guard let data, (response as? HTTPURLResponse)?.statusCode == 200,
                  let release = try? JSONDecoder().decode(Release.self, from: data) else {
                ATHLogger.error("Update check failed: \(error?.localizedDescription ?? "invalid response")", category: .system)
                return
            }

            let remoteVersion = release.version
            guard !remoteVersion.isEmpty else {
                present(UpdateError("cant_get_version", InitGlobVar.latestReleaseAPIURL))
                return
            }
            ATHLogger.info("Local version \(thisApplicationVersion), remote version \(remoteVersion)", category: .system)
            guard compareVersionStrings(thisApplicationVersion, remoteVersion) == .orderedAscending else { return }

            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = NSLocalizedString("update.alert.update_found", comment: "Update found!")
                alert.informativeText = String(format: NSLocalizedString("update.alert.latest_version", comment: "Latest version info"), remoteVersion, thisApplicationVersion)
                alert.addButton(withTitle: NSLocalizedString("update.alert.button.update", comment: "Update"))
                alert.addButton(withTitle: NSLocalizedString("update.alert.button.skip", comment: "Skip"))
                if alert.runModal() == .alertFirstButtonReturn {
                    updateQueue.async { install(release) }
                }
            }
        }.resume()
    }

    private static func install(_ release: Release) {
        let fileManager = FileManager.default
        let updateDirectory = InitGlobVar.updateDirectoryURL

        do {
            try? fileManager.removeItem(at: updateDirectory)
            try fileManager.createDirectory(at: updateDirectory, withIntermediateDirectories: true)

            guard let asset = release.assets.first(where: \.isZip) ?? release.assets.first(where: \.isDiskImage) else {
                throw UpdateError("cant_find_extension", InitGlobVar.athrepositoryURL)
            }

            notify(String(format: NSLocalizedString("update.notify.starting_download", comment: "Starting Download"), release.version))
            var item = try download(asset, to: updateDirectory.appendingPathComponent(asset.name))

            if !asset.isDiskImage {
                notify(NSLocalizedString("update.notify.unzipping", comment: "Unzipping Archive"))
                let extracted = updateDirectory.appendingPathComponent("Extracted", isDirectory: true)
                let unzipDetail = String(format: NSLocalizedString("update.alert.cant_unzip_detail", comment: "Archive unzip detail"), item.path, extracted.path)
                do {
                    try fileManager.unzipItem(at: item, to: extracted)
                } catch {
                    throw UpdateError("cant_unzip", "\(unzipDetail)\n\(error.localizedDescription)")
                }
                guard let found = findBundle(in: extracted, extensions: ["app", "dmg"]) else {
                    throw UpdateError("cant_find_extension", unzipDetail)
                }
                item = found
            }

            if item.pathExtension.lowercased() == "dmg" {
                item = try copyApplication(fromDiskImage: item, to: updateDirectory)
            }

            try validateMinimumSystemVersion(of: item, releaseVersion: release.version)
            try replaceInstalledApplication(with: item)
            relaunch()
        } catch let error as UpdateError {
            present(error)
        } catch {
            present(UpdateError("cant_replace_app", "\(InitGlobVar.thisAppliLocation)\n\(error.localizedDescription)"))
        }
    }

    private static func sanitizedVersion(_ value: String) -> String {
        numericVersionComponents(from: value).map(String.init).joined(separator: ".")
    }

    private static func request(_ url: URL, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("AboutThisHack/\(thisApplicationVersion)", forHTTPHeaderField: "User-Agent")
        return request
    }

    private static func download(_ asset: Asset, to destination: URL) throws -> URL {
        let semaphore = DispatchSemaphore(value: 0)
        var failure: Error?

        URLSession.shared.downloadTask(with: request(asset.browserDownloadURL, timeout: 120)) { temporaryURL, response, error in
            defer { semaphore.signal() }
            do {
                guard let temporaryURL, (response as? HTTPURLResponse).map({ (200..<300).contains($0.statusCode) }) == true else {
                    throw error ?? URLError(.badServerResponse)
                }
                try? FileManager.default.removeItem(at: destination)
                try FileManager.default.moveItem(at: temporaryURL, to: destination)
            } catch {
                failure = error
            }
        }.resume()
        semaphore.wait()

        if let failure {
            throw UpdateError("cant_download", "\(asset.name)\n\(failure.localizedDescription)")
        }
        return destination
    }

    /// Prefers "<this app>.app", then any item with the first matching extension.
    private static func findBundle(in directory: URL, extensions: [String]) -> URL? {
        let items = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])?
            .compactMap { $0 as? URL } ?? []
        if let preferred = items.first(where: { $0.lastPathComponent == "\(appName).app" }) {
            return preferred
        }
        return extensions.lazy.compactMap { ext in items.first { $0.pathExtension.lowercased() == ext } }.first
    }

    private static func copyApplication(fromDiskImage diskImage: URL, to directory: URL) throws -> URL {
        notify(NSLocalizedString("update.notify.mounting_dmg", comment: "Try to mount dmg"))
        let attach = executeProcess(executableURL: URL(fileURLWithPath: "/usr/bin/hdiutil"),
                                    arguments: ["attach", diskImage.path, "-nobrowse", "-plist"])
        guard attach.succeeded,
              let plist = try? PropertyListSerialization.propertyList(from: Data(attach.stdout.utf8), format: nil) as? [String: Any],
              let mountPath = (plist["system-entities"] as? [[String: Any]])?.compactMap({ $0["mount-point"] as? String }).first else {
            throw UpdateError("cant_mount_dmg", "\(diskImage.path)\n\(attach.combinedOutput)")
        }
        defer {
            notify(NSLocalizedString("update.notify.unmounting_dmg", comment: "Try to unmount dmg"))
            executeProcess(executableURL: URL(fileURLWithPath: "/usr/bin/hdiutil"), arguments: ["detach", mountPath, "-force", "-quiet"])
        }

        let copyDetail = String(format: NSLocalizedString("update.alert.cant_copy_app_detail", comment: "Can't copy app detail"), appName, appName, mountPath)
        guard let mountedApp = findBundle(in: URL(fileURLWithPath: mountPath, isDirectory: true), extensions: ["app"]) else {
            throw UpdateError("cant_copy_app", copyDetail)
        }

        let stagedApp = directory.appendingPathComponent("\(appName).app", isDirectory: true)
        do {
            try? FileManager.default.removeItem(at: stagedApp)
            try FileManager.default.copyItem(at: mountedApp, to: stagedApp)
        } catch {
            throw UpdateError("cant_copy_app", "\(copyDetail)\n\(error.localizedDescription)")
        }
        return stagedApp
    }

    private static func validateMinimumSystemVersion(of application: URL, releaseVersion: String) throws {
        notify(String(format: NSLocalizedString("update.notify.checking_allowed", comment: "Checking if new app is allowed"), releaseVersion))
        let infoPlist = application.appendingPathComponent("Contents/Info.plist")
        guard let minimum = (NSDictionary(contentsOf: infoPlist)?["LSMinimumSystemVersion"] as? String)?.nilIfEmpty else {
            throw UpdateError("cant_get_min_os", String(format: NSLocalizedString("update.alert.cant_get_min_os_detail", comment: "LSMinimumSystemVersion not found"), infoPlist.path))
        }

        let current = HCVersion.shared.osNumber
        guard isVersion(current, atLeast: minimum) else {
            throw UpdateError("update_cant_be_achieved", String(format: NSLocalizedString("update.alert.update_cant_be_achieved_detail", comment: "Update can't be achieved detail"), minimum, current))
        }
    }

    /// Stages next to the installed bundle so the final swap is an atomic same-volume replace.
    private static func replaceInstalledApplication(with candidate: URL) throws {
        notify(NSLocalizedString("update.notify.installing", comment: "New Version Install"))
        let fileManager = FileManager.default
        let installed = InitGlobVar.installedApplicationURL
        let staged = installed.deletingLastPathComponent().appendingPathComponent("\(appName).app.update-staging", isDirectory: true)

        do {
            try? fileManager.removeItem(at: staged)
            try fileManager.copyItem(at: candidate, to: staged)
            if fileManager.fileExists(atPath: installed.path) {
                _ = try fileManager.replaceItemAt(installed, withItemAt: staged, backupItemName: nil, options: .usingNewMetadataOnly)
            } else {
                try fileManager.moveItem(at: staged, to: installed)
            }
        } catch {
            throw UpdateError("cant_replace_app", "\(installed.path)\n\(error.localizedDescription)")
        }
    }

    private static func relaunch() {
        notify(NSLocalizedString("update.notify.complete", comment: "Update Complete, Launching New Version"))
        DispatchQueue.main.async {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.createsNewApplicationInstance = true
            NSWorkspace.shared.openApplication(at: InitGlobVar.installedApplicationURL, configuration: configuration) { _, error in
                if let error {
                    present(UpdateError("cant_replace_app", "\(InitGlobVar.thisAppliLocation)\n\(error.localizedDescription)"))
                } else {
                    exit(0)
                }
            }
        }
    }

    private static func present(_ error: UpdateError) {
        ATHLogger.error("\(error.message): \(error.detail)", category: .system)
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = error.message
            alert.informativeText = error.detail
            alert.alertStyle = .critical
            alert.addButton(withTitle: NSLocalizedString("update.alert.button.return", comment: "Return"))
            alert.runModal()
        }
    }

    private static func notify(_ title: String) {
        ATHLogger.info(title, category: .system)
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.sound = .default
            center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }
}
