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
 //       return run("tail -$(echo $(wc -l " + initGlobVar.scrFilePath + " | awk '{print $1}' | tr -d '\n') - $(grep -n \" Displays:\" " + initGlobVar.scrFilePath + " | awk -F':' '{print $1-1}' | tr -d '\n') | bc) " + initGlobVar.scrFilePath)
        
        let displtotline = run("wc -l " + initGlobVar.scrFilePath + " | awk '{print $1}' | tr -d '\n'")
        print("wc -l " + initGlobVar.scrFilePath + "\(displtotline)")
        let displendline = run("grep -n \" Displays:\" " + initGlobVar.scrFilePath + " | awk -F':' '{print $1-1}' | tr -d '\n'")
        print("Displays: " + initGlobVar.scrFilePath + "\(displendline)")
        let dispnbrlines = (Int(displtotline) ?? 0) - (Int(displendline) ?? 0)
        print("tail -\(dispnbrlines)" + " " + initGlobVar.scrFilePath)
        
        return run("tail -\(dispnbrlines)" + " " + initGlobVar.scrFilePath)
   }
}
