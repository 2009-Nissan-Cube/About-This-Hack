import Foundation

class HCDisplay {
    
    static func getDisp() -> String {
        var tmp = run("grep Resolution ~/.ath/scr.txt | sed 's/.*: //'")
        if tmp.contains("(QHD"){
            tmp = run("grep Resolution ~/.ath/scr.txt | sed 's/.*: //' | cut -c -11")
        }
        if(tmp.contains("\n")) {
            let displayID = tmp.firstIndex(of: "\n")!
            let displayTrimmed = String(tmp[..<displayID])
            tmp = displayTrimmed
        }
        return tmp
    }
}
