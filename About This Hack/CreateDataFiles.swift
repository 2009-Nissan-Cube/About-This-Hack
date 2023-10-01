import Foundation

class CreateDataFiles {

    static var dataFilesCreated: Bool = false

    static func getInitDataFiles() {
        
        if (dataFilesCreated) {return}

        _ = run("rm -rf " + initGlobVar.athDirectory + " 2>/dev/null")
        _ = run("mkdir " + initGlobVar.athDirectory + " 2>/dev/null")
        print("Directory created...")
        func createFileIfNeeded(atPath path: String, withCommand command: String) {
            
            // Because a simple redirection ">" empties the fil before it writes
            //            if !initGlobVar.defaultfileManager.fileExists(atPath: path) {
            _ = run(command)
            //            }
        }
        
        createFileIfNeeded(atPath: initGlobVar.hwFilePath, withCommand: "system_profiler SPHardwareDataType > \"\(initGlobVar.hwFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.sysmemFilePath, withCommand: "system_profiler SPMemoryDataType  | grep -v \"^Memory:$\" > \"\(initGlobVar.sysmemFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.bootvolnameFilePath, withCommand: "diskutil info / > \"\(initGlobVar.bootvolnameFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.bootvollistFilePath, withCommand: "diskutil list / > \"\(initGlobVar.bootvollistFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.scrFilePath, withCommand: "system_profiler SPDisplaysDataType > \"\(initGlobVar.scrFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.scrXmlFilePath, withCommand: "system_profiler SPDisplaysDataType -xml > \"\(initGlobVar.scrXmlFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.syssoftdataFilePath, withCommand: "system_profiler SPSoftwareDataType > \"\(initGlobVar.syssoftdataFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.storagedataFilePath, withCommand: "system_profiler SPStorageDataType > \"\(initGlobVar.storagedataFilePath)\"")

        print("Files created...")

        dataFilesCreated = true
    }
}
