import Foundation

class CreateDataFiles {
    static private var _dataFilesCreated = false
    static private var _loadInProgress = false
    static private var pendingCompletions: [() -> Void] = []
    static private let lock = NSLock()

    // Notification name for when startup data is ready
    static let dataFilesCreatedNotification = Notification.Name("DataFilesCreated")

    static var dataFilesCreated: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _dataFilesCreated
    }

    /// Asynchronously prepares initial hardware data.
    /// Concurrent callers share one in-progress load.
    static func getInitDataFilesAsync(completion: @escaping () -> Void) {
        var shouldStartLoad = false

        lock.lock()
        if _dataFilesCreated {
            lock.unlock()
            DispatchQueue.main.async {
                completion()
            }
            return
        }

        pendingCompletions.append(completion)
        if !_loadInProgress {
            _loadInProgress = true
            shouldStartLoad = true
        }
        lock.unlock()

        guard shouldStartLoad else {
            return
        }

        HardwareCollector.shared.prepareInitialDataAsync {
            finishInitialLoad()
        }
    }

    static func getInitDataFiles() {
        let semaphore = DispatchSemaphore(value: 0)
        getInitDataFilesAsync {
            semaphore.signal()
        }
        semaphore.wait()
    }

    static func reset() {
        lock.lock()
        _dataFilesCreated = false
        _loadInProgress = false
        pendingCompletions.removeAll()
        lock.unlock()

        HardwareCollector.shared.resetData()
    }

    private static func finishInitialLoad() {
        lock.lock()
        _dataFilesCreated = true
        _loadInProgress = false
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        lock.unlock()

        completions.forEach { $0() }
        NotificationCenter.default.post(name: dataFilesCreatedNotification, object: nil)
    }
}
