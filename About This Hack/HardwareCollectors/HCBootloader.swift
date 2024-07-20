import Foundation

class HCBootloader {
    static let shared = HCBootloader()
    private init() {}
    
    private lazy var bootloaderInfo: String = {
        let openCoreVersion = run("nvram \(InitGlobVar.nvramOpencoreVersion) 2>/dev/null | awk '{print $2}' | awk -F'-' '{print $2}'")
        
        if !openCoreVersion.isEmpty {
            return run("echo \"OpenCore \"$(nvram \(InitGlobVar.nvramOpencoreVersion) 2>/dev/null | awk '{print $2}' | awk -F'-' '{print $2}' | sed -e 's/ */./g' -e s'/^.//g' -e 's/.$//g' -e 's/ .//g' -e 's/. //g' | tr -d '\n') $( nvram \(InitGlobVar.nvramOpencoreVersion) 2>/dev/null | awk '{print $2}' | awk -F'-' '{print $1}' | sed -e 's/REL/(Release)/g' -e s'/N\\/A//g' -e 's/DEB/(Debug)/g' | tr -d '\n')")
        } else {
            let cloverInfo = run("\(InitGlobVar.bdmesgExecID) | grep -i \"Starting Clover revision:\" | awk -F 'Starting Clover revision:' '{print $NF}'  | awk '{print \"Clover r\"$1\" (\"substr($4,1,7)\") \"}' | tr -d '\n'")
            
            if !cloverInfo.isEmpty {
                let additionalInfo = run("echo $(\(InitGlobVar.bdmesgExecID) | grep -i \"Build with: \\[Args:\" | awk -F '\\-b' '{print $NF}' |  awk -F '\\-t' '{print $1,$2}' |  awk '{print toupper(substr($2,0,1))tolower(substr($2,2)),toupper(substr($1,0,1))tolower(substr($1,2))}') $(\(InitGlobVar.bdmesgExecID) | grep -i \"Build id:\" | awk -F 'Build id:' '{print $NF}' | awk -F '-' '{print  substr($1,1,5)\"/\"substr($1,6,2)\"/\"substr($1,8,2)\" \"substr($1,10,2)\":\"substr($1,12,2)\":\"substr($1,14,2)}'  | tr -d '\n')")
                return cloverInfo + additionalInfo
            } else {
                return run("sysctl -n machdep.cpu.brand_string").contains("Apple") ? "Apple iBoot" : "Apple UEFI"
            }
        }
    }()
    
    private lazy var bootargsInfo: String = {
        var bootargs = run("nvram -x boot-args 2>/dev/null | grep -A1 \"<key>boot-args</key>\" | tail -1 | awk -F \"<string>\" '{print $NF}' | awk -F \"<\\/string>\" '{print $1}'  | tr -d '\n'")
        
        if bootargs.isEmpty {
            bootargs = run("\(InitGlobVar.bdmesgExecID) 2>/dev/null | grep ' boot-args=' | tail -1 | awk -F ' boot-args=' '{print $NF}' | tr -d '\n'")
        }
        
        return bootargs.isEmpty ? "Empty/Unknown" : bootargs
    }()
    
    func getBootloader() -> String {
        return bootloaderInfo.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    func getBootargs() -> String {
        return bootargsInfo
    }
}
