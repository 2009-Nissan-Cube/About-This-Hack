import Foundation

class CreateDataFiles {

    static private var _dataFilesCreated: Bool = false
    static private let lock = NSLock()

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
        ATHLogger.debug("Data directory created", category: .system)

        func createFileIfNeeded(atPath path: String, withCommand command: String) {
            _ = run(command)
        }

// /* Product phase  - Uncomment for product phase
        createFileIfNeeded(atPath: InitGlobVar.hwFilePath, withCommand: "system_profiler SPHardwareDataType > \"\(InitGlobVar.hwFilePath)\"")
        createFileIfNeeded(atPath: InitGlobVar.sysmemFilePath, withCommand: "system_profiler SPMemoryDataType  | grep -v \"^Memory:$\" > \"\(InitGlobVar.sysmemFilePath)\"")
        createFileIfNeeded(atPath: InitGlobVar.bootvolnameFilePath, withCommand: "diskutil info / > \"\(InitGlobVar.bootvolnameFilePath)\"")
        createFileIfNeeded(atPath: InitGlobVar.bootvollistFilePath, withCommand: "diskutil list / > \"\(InitGlobVar.bootvollistFilePath)\"")
        createFileIfNeeded(atPath: InitGlobVar.scrFilePath, withCommand: "system_profiler SPDisplaysDataType > \"\(InitGlobVar.scrFilePath)\"")
        createFileIfNeeded(atPath: InitGlobVar.scrXmlFilePath, withCommand: "system_profiler SPDisplaysDataType -xml > \"\(InitGlobVar.scrXmlFilePath)\"")
        createFileIfNeeded(atPath: InitGlobVar.syssoftdataFilePath, withCommand: "system_profiler SPSoftwareDataType > \"\(InitGlobVar.syssoftdataFilePath)\"")
        createFileIfNeeded(atPath: InitGlobVar.storagedataFilePath, withCommand: "system_profiler SPStorageDataType > \"\(InitGlobVar.storagedataFilePath)\"")
// */

/*  Testing phase - Uncomment and modify path for testing phase
        let testDataRep = "~/Downloads/0-ath-issue-N78" // Replace with your test data directory

        createFileIfNeeded(atPath: InitGlobVar.hwFilePath, withCommand: "ln -s \(testDataRep)/hw.txt  \"\(InitGlobVar.hwFilePath)\"")
        // ... Add similar lines for other files
*/

        ATHLogger.info("Data files created successfully", category: .system)

        lock.lock()
        _dataFilesCreated = true
        lock.unlock()
    }
}
