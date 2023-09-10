import Foundation

class HCBootloader {
    
    
    static func getBootloader() -> String {
        
        let fileManager = FileManager.default
        let homeDirectory = NSHomeDirectory()
        let hwFilePath = homeDirectory + "/.ath/hw.txt"
        let oclpXmlFilePath = homeDirectory + "/.ath/oclp.txt"
        let bdmesgExecID = "/usr/local/bin/bdmesg"

        var BootloaderInfo: String = ""
       
        var oclpRelease: String = ""
        var oclpDateTime: String = ""
        var oclpCommit: String = ""

        if fileManager.fileExists(atPath: oclpXmlFilePath) {
            oclpRelease = run("grep -A1 \"OpenCore Legacy Patcher\" " + oclpXmlFilePath + " | tail -1 | sed -e 's?.*<string>?OCLP ?' -e 's?<\\/string>??' | tr -d '\n'")
            oclpDateTime = run("grep -A1 \"Time Patched\" " + oclpXmlFilePath + " | tail -1 | sed -e 's?.*<string>??' -e 's?<\\/string>??' -e 's?@ ? ?' | tr -d '\n'")
            oclpCommit = run("grep -A1 \"Commit URL\" " + oclpXmlFilePath + " | tail -1 | sed -e 's?.*<string>??' -e 's?<\\/string>??' | awk -F'/' '{print substr($NF,1,7)}' | tr -d '\n'")

            if oclpCommit != "" { oclpRelease += (" (\(oclpCommit))") }
            if oclpDateTime != "" { oclpRelease += (" (\(oclpDateTime))") }
        }

        BootloaderInfo = run("nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}' | awk -F'-' '{print $2}'")
        if BootloaderInfo != "" {
            // Regular OpenCore
                BootloaderInfo = run("echo \"OpenCore \"$(nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}' | awk -F'-' '{print $2}' | sed -e 's/ */./g' -e s'/^.//g' -e 's/.$//g' -e 's/ .//g' -e 's/. //g' | tr -d '\n') $( nvram 4D1FDA02-38C7-4A6A-9CC6-4BCCA8B30102:opencore-version | awk '{print $2}' | awk -F'-' '{print $1}' | sed -e 's/REL/(Release)/g' -e s'/N\\/A//g' -e 's/DEB/(Debug)/g' | tr -d '\n')")
            }
        else {
            BootloaderInfo = run("grep \"Clover\" " + hwFilePath + " | awk '{print $4,\"r\" $6,\"(\" substr($9,1,7) \") \"}' | tr -d '\n'")
            if BootloaderInfo  != "" {
                BootloaderInfo += run("echo $(" + bdmesgExecID + " | grep -i \"Build with: \\[Args:\" | awk -F '\\-b' '{print $NF}' |  awk -F '\\-t' '{print $1,$2}' |  awk '{print toupper(substr($2,0,1))tolower(substr($2,2)),toupper(substr($1,0,1))tolower(substr($1,2))}') $(" + bdmesgExecID + " | grep -i \"Build id:\" | awk -F 'Build id:' '{print $NF}' | awk -F '-' '{print  substr($1,1,5)\"/\"substr($1,6,2)\"/\"substr($1,8,2)\" \"substr($1,10,2)\":\"substr($1,12,2)\":\"substr($1,14,2)}'  | tr -d '\n')")
            }
            else {
                if run("sysctl -n machdep.cpu.brand_string").contains("Apple") {
                    BootloaderInfo = "Apple iBoot"
                } else {
                    BootloaderInfo = "Apple UEFI"
                }
            }
        }
        if oclpRelease != "" { BootloaderInfo += " \(oclpRelease)" }
        return BootloaderInfo
    }
}
