import Foundation

class HCBootloader {
    static let shared = HCBootloader()
    private init() {}
    
    private lazy var bootloaderInfo: String = {
        let openCoreVersion = run("nvram \(InitGlobVar.nvramOpencoreVersion) 2>/dev/null | awk '{print $2}' | awk -F'-' '{print $2}'")
        
        if !openCoreVersion.isEmpty {
            return run("echo \"OpenCore \"$(nvram \(InitGlobVar.nvramOpencoreVersion) 2>/dev/null | awk '{print $2}' | awk -F'-' '{print $2}' | sed -e 's/ */./g' -e s'/^.//g' -e 's/.$//g' -e 's/ .//g' -e 's/. //g' | tr -d '\n') $( nvram \(InitGlobVar.nvramOpencoreVersion) 2>/dev/null | awk '{print $2}' | awk -F'-' '{print $1}' | sed -e 's/REL/(Release)/g' -e s'/N\\/A//g' -e 's/DEB/(Debug)/g' | tr -d '\n')")
        } else {
            let cloverInfo = "Clover " + run ("cat \(InitGlobVar.hwFilePath) | grep Clover | cut -d \":\" -f2")
            
            if !cloverInfo.isEmpty {
                return cloverInfo
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
