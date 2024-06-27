import Foundation

class HCDisplay {
    
    static func getDisp() -> String {
        let dispName = run("system_profiler SPDisplaysDataType | awk -F ' {8}|:' '/^ {8}[^ :]+/ {print $2}' | sed -n '1p' | tr -d '\n'")
        let resolution = run("system_profiler SPDisplaysDataType | awk -F ': ' '/ {10}.+/ {print $2}' | sed -n '1p' | tr -d '\n'")
        return "\(dispName) (\(resolution))"
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
