import Foundation

class CreateDataFiles {

    static var dataFilesCreated: Bool = false

    static func getInitDataFiles() {
        
        if (dataFilesCreated) {return}

        _ = run("rm -rf " + initGlobVar.athDirectory + " 2>/dev/null")
        _ = run("mkdir " + initGlobVar.athDirectory + " 2>/dev/null")
        print("Directory created...")
        func createFileIfNeeded(atPath path: String, withCommand command: String) {
             // A simple redirection ">" empties the file before writing
            _ = run(command)
        }
        
///* Product phase
        createFileIfNeeded(atPath: initGlobVar.hwFilePath, withCommand: "system_profiler SPHardwareDataType > \"\(initGlobVar.hwFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.sysmemFilePath, withCommand: "system_profiler SPMemoryDataType  | grep -v \"^Memory:$\" > \"\(initGlobVar.sysmemFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.bootvolnameFilePath, withCommand: "diskutil info / > \"\(initGlobVar.bootvolnameFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.bootvollistFilePath, withCommand: "diskutil list / > \"\(initGlobVar.bootvollistFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.scrFilePath, withCommand: "system_profiler SPDisplaysDataType > \"\(initGlobVar.scrFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.scrXmlFilePath, withCommand: "system_profiler SPDisplaysDataType -xml > \"\(initGlobVar.scrXmlFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.syssoftdataFilePath, withCommand: "system_profiler SPSoftwareDataType > \"\(initGlobVar.syssoftdataFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.storagedataFilePath, withCommand: "system_profiler SPStorageDataType > \"\(initGlobVar.storagedataFilePath)\"")
//*/
        
/*  Testing phase
        let testDataRep = "~/Downloads/0-ath-issue-N78" // with Test DataFiles from issues N39, N72, N72bis or N78 (and N99 which is not an issue just 0xCUB3 DataFiles Mac)
        
        createFileIfNeeded(atPath: initGlobVar.hwFilePath, withCommand: "ln -s \(testDataRep)/hw.txt  \"\(initGlobVar.hwFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.sysmemFilePath, withCommand: "ln -s \(testDataRep)/sysmem.txt  \"\(initGlobVar.sysmemFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.bootvolnameFilePath, withCommand: "ln -s \(testDataRep)/sysvolname.txt  \"\(initGlobVar.bootvolnameFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.bootvollistFilePath, withCommand: "ln -s \(testDataRep)/sysbootvollist.txt  \"\(initGlobVar.bootvollistFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.scrFilePath, withCommand: "ln -s \(testDataRep)/scr.txt  \"\(initGlobVar.scrFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.scrXmlFilePath, withCommand: "ln -s \(testDataRep)/scrXml.txt  \"\(initGlobVar.scrXmlFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.syssoftdataFilePath, withCommand: "ln -s \(testDataRep)/syssoftdata.txt  \"\(initGlobVar.syssoftdataFilePath)\"")
        createFileIfNeeded(atPath: initGlobVar.storagedataFilePath, withCommand: "ln -s \(testDataRep)/storagedata.txt  \"\(initGlobVar.storagedataFilePath)\"")
*/
        print("Files created...")

        dataFilesCreated = true
    }
}
