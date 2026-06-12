//
//  HardwareCollector.swift
//  HardwareCollector
//
//

import Foundation

private struct HardwareSnapshot {
    let hardwareData: String
    let memoryData: String
    let oclpData: String?
}

class HardwareCollector {
    static let shared = HardwareCollector()
    private init() {}

    /// Posted on the main thread once the initial hardware snapshot is ready.
    static let dataDidLoadNotification = Notification.Name("HardwareCollectorDataDidLoad")

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

    /// Raw `system_profiler SPHardwareDataType` output.
    var hardwareData: String? {
        currentSnapshot()?.hardwareData.nilIfEmpty
    }

    /// Raw `system_profiler SPMemoryDataType` output.
    var memoryData: String? {
        currentSnapshot()?.memoryData.nilIfEmpty
    }

    /// Contents of the OpenCore Legacy Patcher plist, if present.
    var oclpData: String? {
        currentSnapshot()?.oclpData?.nilIfEmpty
    }

    /// Asynchronously collects the hardware snapshot and warms the collector caches.
    /// Concurrent callers share one in-progress load; completions run on the main thread.
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

    private func loadInitialData() {
        let collectedSnapshot = collectSnapshot()

        stateLock.lock()
        snapshot = collectedSnapshot
        stateLock.unlock()

        warmCollectors()

        stateLock.lock()
        _dataHasBeenSet = true
        _isLoading = false
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        stateLock.unlock()

        ATHLogger.info(NSLocalizedString("log.data.files_created", comment: "Data files created successfully"), category: .system)

        DispatchQueue.main.async {
            completions.forEach { $0() }
            NotificationCenter.default.post(name: Self.dataDidLoadNotification, object: nil)
        }
    }

    private func currentSnapshot() -> HardwareSnapshot? {
        stateLock.lock()
        defer { stateLock.unlock() }
        return snapshot
    }

    /// Populates the collector caches off the main thread so views render without blocking.
    private func warmCollectors() {
        HCVersion.shared.getVersion()
        HCMacModel.shared.getMacModel()
        _ = HCCPU.shared.getCPU()
        _ = HCRAM.shared.getRam()
        _ = HCStartupDisk.shared.getStartupDisk()
        _ = HCDisplay.shared.getDisp()
        _ = HCGPU.shared.getGPU()
        _ = HCSerialNumber.shared.getSerialNumber()
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
