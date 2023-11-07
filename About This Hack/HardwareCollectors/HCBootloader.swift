import Foundation

class HCBootloader {

    static var BootloaderInfo: String = ""
    static var BootargsInfo: String = ""

    static func getBootloader() -> String {
        
        BootloaderInfo = run("nvram " + initGlobVar.nvramOpencoreVersion + " 2>/dev/null | awk '{print $2}' | awk -F'-' '{print $2}'")
        if BootloaderInfo != "" {
            // Regular OpenCore
                BootloaderInfo = run("echo \"OpenCore \"$(nvram " + initGlobVar.nvramOpencoreVersion + " 2>/dev/null | awk '{print $2}' | awk -F'-' '{print $2}' | sed -e 's/ */./g' -e s'/^.//g' -e 's/.$//g' -e 's/ .//g' -e 's/. //g' | tr -d '\n') $( nvram " + initGlobVar.nvramOpencoreVersion + " 2>/dev/null | awk '{print $2}' | awk -F'-' '{print $1}' | sed -e 's/REL/(Release)/g' -e s'/N\\/A//g' -e 's/DEB/(Debug)/g' | tr -d '\n')")
            }
        else {
//            BootloaderInfo = run("grep \"Clover\" " + initGlobVar.hwFilePath + " | awk '{print $4,\"r\" $6,\"(\" substr($9,1,7) \") \"}' | tr -d '\n'")
            BootloaderInfo = run(initGlobVar.bdmesgExecID + " | grep -i \"Starting Clover revision:\" | awk -F 'Starting Clover revision:' '{print $NF}'  | awk '{print \"Clover r\"$1\" (\"substr($4,1,7)\") \"}' | tr -d '\n'")
            if BootloaderInfo  != "" {
                BootloaderInfo += run("echo $(" + initGlobVar.bdmesgExecID + " | grep -i \"Build with: \\[Args:\" | awk -F '\\-b' '{print $NF}' |  awk -F '\\-t' '{print $1,$2}' |  awk '{print toupper(substr($2,0,1))tolower(substr($2,2)),toupper(substr($1,0,1))tolower(substr($1,2))}') $(" + initGlobVar.bdmesgExecID + " | grep -i \"Build id:\" | awk -F 'Build id:' '{print $NF}' | awk -F '-' '{print  substr($1,1,5)\"/\"substr($1,6,2)\"/\"substr($1,8,2)\" \"substr($1,10,2)\":\"substr($1,12,2)\":\"substr($1,14,2)}'  | tr -d '\n')")
            }
            else {
                if run("sysctl -n machdep.cpu.brand_string").contains("Apple") {
                    BootloaderInfo = "Apple iBoot"
                } else {
                    BootloaderInfo = "Apple UEFI"
                }
            }
        }
        return BootloaderInfo
    }
    
    static func getBootargs() -> String {
        BootargsInfo = run("nvram -x boot-args 2>/dev/null | grep -A1 \"<key>boot-args</key>\" | tail -1 | awk -F \"<string>\" '{print $NF}' | awk -F \"<\\/string>\" '{print $1}'  | tr -d '\n'")
        if BootargsInfo == "" {
            BootargsInfo = run(initGlobVar.bdmesgExecID + " 2>/dev/null | grep ' boot-args=' | tail -1 | awk -F ' boot-args=' '{print $NF}' | tr -d '\n'")
        }
        if BootargsInfo == "" {
            BootargsInfo = "Empty/Unknown"
        }
        return BootargsInfo
    }

}
