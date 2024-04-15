import Foundation

class HCDisplay {
    
    static func getDisp() -> String {
        let regex = try! NSRegularExpression(pattern: "Resolution: (.*)\\(.*\\)")
        let tmp = run("grep Resolution: " + initGlobVar.scrFilePath + " | sed 's/.*: //'")
        if let match = regex.firstMatch(in: tmp, range: NSRange(tmp.startIndex..., in: tmp)) {
            return String(tmp[Range(match.range(at: 1), in: tmp)!])
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
