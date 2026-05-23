//
//  HardwareCollector.swift
//  HardwareCollector
//
//

import Foundation
import AppKit

private struct HardwareSnapshot {
    let hardwareData: String
    let memoryData: String
    let oclpData: String?
}

class HardwareCollector {
    static let shared = HardwareCollector()
    private init() {}

    private let stateLock = NSLock()
    private var snapshot: HardwareSnapshot?
    private var _dataHasBeenSet = false
    private var _isLoading = false
    private var pendingCompletions: [() -> Void] = []
    private let loadQueue = DispatchQueue(label: "AboutThisHack.HardwareCollector.Load", qos: .userInitiated)

    var dataHasBeenSet: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _dataHasBeenSet
    }

    var numberOfDisplays = NSScreen.screens.count
    var displayRes: [String] = []
    var displayNames: [String] = []
    var storageType = false
    var storageData = ""
    var storagePercent = 0.0
    var deviceLocation = ""
    var deviceProtocol = ""
    var hasBuiltInDisplay = false
    var macType: MacType = .laptop

    func prepareInitialDataAsync(completion: @escaping () -> Void) {
        var shouldStartLoad = false

        stateLock.lock()
        if _dataHasBeenSet {
            stateLock.unlock()
            DispatchQueue.main.async {
                completion()
            }
            return
        }

        pendingCompletions.append(completion)
        if !_isLoading {
            _isLoading = true
            shouldStartLoad = true
        }
        stateLock.unlock()

        guard shouldStartLoad else {
            return
        }

        loadQueue.async { [weak self] in
            self?.loadInitialData()
        }
    }

    func getAllData() {
        guard !dataHasBeenSet else { return }

        let semaphore = DispatchSemaphore(value: 0)
        prepareInitialDataAsync {
            semaphore.signal()
        }
        semaphore.wait()
    }

    func resetData() {
        stateLock.lock()
        snapshot = nil
        _dataHasBeenSet = false
        _isLoading = false
        pendingCompletions.removeAll()
        stateLock.unlock()

        resetDerivedState()
        resetCollectorCaches()
    }

    func getCachedFileContent(_ path: String) -> String? {
        if let snapshot = currentSnapshot(), let content = mappedSnapshotContent(for: path, snapshot: snapshot), !content.isEmpty {
            return content
        }

        guard let content = try? String(contentsOfFile: path, encoding: .utf8), !content.isEmpty else {
            return nil
        }
        return content
    }

    private func loadInitialData() {
        let collectedSnapshot = collectSnapshot()

        stateLock.lock()
        snapshot = collectedSnapshot
        stateLock.unlock()

        resetDerivedState()
        resetCollectorCaches()
        initializeDerivedData()

        stateLock.lock()
        _dataHasBeenSet = true
        _isLoading = false
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        stateLock.unlock()

        ATHLogger.info(NSLocalizedString("log.data.files_created", comment: "Data files created successfully"), category: .system)

        DispatchQueue.main.async {
            completions.forEach { $0() }
        }
    }

    private func currentSnapshot() -> HardwareSnapshot? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return snapshot
    }

    private func mappedSnapshotContent(for path: String, snapshot: HardwareSnapshot) -> String? {
        switch path {
        case InitGlobVar.hwFilePath:
            return snapshot.hardwareData
        case InitGlobVar.sysmemFilePath:
            return snapshot.memoryData
        case InitGlobVar.oclpXmlFilePath:
            return snapshot.oclpData
        default:
            return nil
        }
    }

    private func resetDerivedState() {
        numberOfDisplays = NSScreen.screens.count
        displayRes = []
        displayNames = []
        storageType = false
        storageData = ""
        storagePercent = 0.0
        deviceLocation = ""
        deviceProtocol = ""
        hasBuiltInDisplay = false
        macType = .laptop
    }

    private func resetCollectorCaches() {
        ATHLogger.debug(NSLocalizedString("log.hardware.cache_cleared", comment: "File cache cleared"), category: .hardware)
        HCVersion.shared.reset()
        HCMacModel.shared.reset()
        HCStartupDisk.shared.reset()
        HCDisplay.shared.reset()
        HCGPU.shared.reset()
        HCBootloader.shared.reset()
    }

    private func initializeDerivedData() {
        HCVersion.shared.getVersion()
        HCMacModel.shared.getMacModel()
        _ = HCCPU.shared.getCPU()
        _ = HCRAM.shared.getRam()
        _ = HCStartupDisk.shared.getStartupDisk()
        _ = HCDisplay.shared.getDisp()
        _ = HCGPU.shared.getGPU()

        displayNames = HCDisplay.shared.getDisplayNames()
        displayRes = HCDisplay.shared.getDisplayResolutions()
        numberOfDisplays = displayNames.count
        hasBuiltInDisplay = HCDisplay.shared.hasBuiltInDisplay()

        let storageSummary = HCStartupDisk.shared.getStorageSummary()
        storageType = storageSummary.isSolidState
        storageData = storageSummary.description
        storagePercent = storageSummary.percentUsed
        deviceLocation = storageSummary.deviceLocation
        deviceProtocol = storageSummary.deviceProtocol
    }

    private func collectSnapshot() -> HardwareSnapshot {
        let collectionQueue = DispatchQueue(label: "AboutThisHack.HardwareCollector.Collection", qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()

        var hardwareData = ""
        var memoryData = ""

        group.enter()
        collectionQueue.async {
            hardwareData = self.collectCommandOutput(
                executablePath: "/usr/sbin/system_profiler",
                arguments: ["SPHardwareDataType"],
                label: "SPHardwareDataType"
            )
            group.leave()
        }

        group.enter()
        collectionQueue.async {
            memoryData = self.collectCommandOutput(
                executablePath: "/usr/sbin/system_profiler",
                arguments: ["SPMemoryDataType"],
                label: "SPMemoryDataType"
            ) { output in
                output
                    .components(separatedBy: .newlines)
                    .filter { $0.trimmingCharacters(in: .whitespaces) != "Memory:" }
                    .joined(separator: "\n")
            }
            group.leave()
        }

        group.wait()

        let oclpData = try? String(contentsOfFile: InitGlobVar.oclpXmlFilePath, encoding: .utf8)

        return HardwareSnapshot(
            hardwareData: hardwareData,
            memoryData: memoryData,
            oclpData: oclpData
        )
    }

    private func collectCommandOutput(
        executablePath: String,
        arguments: [String],
        label: String,
        postProcess: (String) -> String = { $0 }
    ) -> String {
        let result = executeProcess(executableURL: URL(fileURLWithPath: executablePath), arguments: arguments)

        guard result.succeeded else {
            ATHLogger.warning("\(label) failed with status \(result.terminationStatus): \(result.combinedOutput)", category: .hardware)
            return ""
        }

        let output = postProcess(result.stdout)
        if output.isEmpty {
            ATHLogger.warning("\(label) returned no output", category: .hardware)
        }
        return output
    }
}
