import Foundation

class HCDisplay {
    
    static func getDisp() -> String {
        var tmp = run("grep Resolution: " + initGlobVar.scrFilePath + " | sed 's/.*: //'")
        if tmp.contains("(QHD"){
            tmp = run("grep Resolution: " + initGlobVar.scrFilePath + " | sed 's/.*: //' | cut -c -11")
        }
        if(tmp.contains("\n")) {
            let displayID = tmp.firstIndex(of: "\n")!
            let displayTrimmed = String(tmp[..<displayID])
            tmp = displayTrimmed
        }
        return tmp
    }
    
    static func getDispInfo() -> String {
        let dispArray:[String] = run("egrep \"^        [A-Za-z0-9]|^--$\" \(initGlobVar.scrFilePath)").components(separatedBy: "\n")
        var dispContent:String = run("egrep \"^        [A-Za-z0-9]|^          [A-Za-z0-9]|^--$\" \(initGlobVar.scrFilePath)")
        print("Tooltip Displays array : \(dispArray)")
        if dispArray != [""] {
            for dispIndice in 0..<dispArray.count {
                dispContent = dispContent.replacingOccurrences(of: "\(dispArray[dispIndice])", with: "\n\(dispArray[dispIndice])\n")
            }
        }
//        print("Tooltip Displays content : \nDisplays\n\(dispContent)")
        return "Displays\n\(dispContent)"
    }
}
