import Foundation

class CreateDataFiles {

    static private var _dataFilesCreated: Bool = false
    static private let lock = NSLock()
    
    // Notification name for when data files are created
    static let dataFilesCreatedNotification = Notification.Name("DataFilesCreated")

    static var dataFilesCreated: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _dataFilesCreated
    }

    /// Asynchronously creates initial data files
    /// - Parameter completion: Called on completion (main thread)
    static func getInitDataFilesAsync(completion: @escaping () -> Void) {
        lock.lock()
        if _dataFilesCreated {
            lock.unlock()
            DispatchQueue.main.async {
                completion()
            }
            return
        }
        lock.unlock()

        DispatchQueue.global(qos: .userInitiated).async {
            getInitDataFiles()
            DispatchQueue.main.async {
                completion()
                // Post notification that data files are ready
                NotificationCenter.default.post(name: dataFilesCreatedNotification, object: nil)
            }
        }
    }

    static func getInitDataFiles() {
        lock.lock()
        if _dataFilesCreated {
            lock.unlock()
            return
        }
        lock.unlock()

        _ = run("rm -rf " + InitGlobVar.athDirectory + " 2>/dev/null")
        _ = run("mkdir " + InitGlobVar.athDirectory + " 2>/dev/null")
        ATHLogger.debug(NSLocalizedString("log.data.directory_created", comment: "Data directory created"), category: .system)

// /* Product phase  - Uncomment for product phase
        // Use DispatchGroup to run all commands in parallel
        let group = DispatchGroup()
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        // Define all file creation commands
        // Note: scrXmlFilePath and syssoftdataFilePath removed - they were never used in the codebase
        let commands = [
            "system_profiler SPHardwareDataType > \"\(InitGlobVar.hwFilePath)\"",
            "system_profiler SPMemoryDataType | grep -v \"^Memory:$\" > \"\(InitGlobVar.sysmemFilePath)\"",
            "diskutil info / > \"\(InitGlobVar.bootvolnameFilePath)\"",
            "diskutil list / > \"\(InitGlobVar.bootvollistFilePath)\"",
            "system_profiler SPDisplaysDataType > \"\(InitGlobVar.scrFilePath)\"",
            "system_profiler SPStorageDataType > \"\(InitGlobVar.storagedataFilePath)\""
        ]
        
        // Execute all commands concurrently
        for command in commands {
            group.enter()
            queue.async {
                _ = run(command)
                group.leave()
            }
        }
        
        // Wait for all commands to complete (this is called from a background thread in getInitDataFilesAsync)
        // Timeout after 12 seconds to prevent indefinite blocking if a command hangs
        let timeout = DispatchTime.now() + .seconds(12)
        let result = group.wait(timeout: timeout)
        
        if case .timedOut = result {
            ATHLogger.warning(NSLocalizedString("log.data.timeout", comment: "Data files creation timed out after 12 seconds"), category: .system)
        }
// */

/*  Testing phase - Uncomment and modify path for testing phase
        let testDataRep = "~/Downloads/0-ath-issue-N78" // Replace with your test data directory

        createFileIfNeeded(atPath: InitGlobVar.hwFilePath, withCommand: "ln -s \(testDataRep)/hw.txt  \"\(InitGlobVar.hwFilePath)\"")
        // ... Add similar lines for other files
*/

        ATHLogger.info(NSLocalizedString("log.data.files_created", comment: "Data files created successfully"), category: .system)

        lock.lock()
        _dataFilesCreated = true
        lock.unlock()
    }
}
