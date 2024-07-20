import Foundation

class CreateDataFiles {

    static var dataFilesCreated: Bool = false

    static func getInitDataFiles() {
        
        if (dataFilesCreated) { return }

        _ = run("rm -rf " + InitGlobVar.athDirectory + " 2>/dev/null")
        _ = run("mkdir " + InitGlobVar.athDirectory + " 2>/dev/null")
        print("Directory created...")
        
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

        print("Files created...")
        dataFilesCreated = true
    }
}
