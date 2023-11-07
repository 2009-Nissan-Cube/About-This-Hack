import Foundation

class HCVersion {
    
    static var OSnum: String = "10.10.0"
    static var OSvers: macOSvers = macOSvers.macOS
    static var OSname: String = ""
    static var OSBuildNum: String = "19G101"
    static var osPrefix: String = "macOS"
    static var dataHasBeenSet: Bool = false
    
    static func getVersion() {
        if (dataHasBeenSet) {return}
        osPrefix = "macOS"
        OSnum = getOSnum()
        OSBuildNum = getOSbuild()
        print(OSnum)
        setOSvers(osNumber: OSnum)
        OSname = macOSversToString()
        print("OS Build Number: \(OSBuildNum)")
        dataHasBeenSet = true
    }

    static func getOSnum() -> String {
        let osVersion = run("sw_vers -productVersion | tr -d '\n'")
        return osVersion
    }
  
    static func getOSbuild() -> String {
        let osSHA = " (" + run("sw_vers -buildVersion | tr -d '\n'") + ") "
        return osSHA
    }
    
    static func setOSvers(osNumber: String) {
        switch osNumber.prefix(2) {
            case "14": OSvers = macOSvers.SONOMA
            case "13": OSvers = macOSvers.VENTURA
            case "12": OSvers = macOSvers.MONTEREY
            case "11": OSvers = macOSvers.BIG_SUR
            case "10":
                switch osNumber.prefix(5) {
                    case "10.16": OSvers = macOSvers.BIG_SUR
                    case "10.15": OSvers = macOSvers.CATALINA
                    case "10.14": OSvers = macOSvers.MOJAVE
                    case "10.13": OSvers = macOSvers.HIGH_SIERRA
                    case "10.12": OSvers = macOSvers.SIERRA
                    default: OSvers = macOSvers.macOS
                }
            default: OSvers = macOSvers.macOS
        }
    }

    static func macOSversToString() -> String {
        switch OSvers {
        case .SIERRA: return "Sierra"
        case .HIGH_SIERRA: return "High Sierra"
        case .MOJAVE: return "Mojave"
        case .CATALINA: return "Catalina"
        case .BIG_SUR: return "Big Sur"
        case .MONTEREY: return "Monterey"
        case .VENTURA: return "Ventura"
        case .SONOMA: return "Sonoma"
        case .macOS: return ""
        }
    }

// ToolTip osVersiontoolTip
    static func getOSBuildInfo() -> String {
        var osKernelInfo: String   = ""
        var osSipInfo: String     = ""
        var oclppatchInfo: String = ""
        
        osKernelInfo = run ("grep \"Kernel Version: \" " + initGlobVar.syssoftdataFilePath + " | awk -F': ' '{print $2}'")
        osSipInfo   = run ("grep \"System Integrity Protection: \" " + initGlobVar.syssoftdataFilePath + "| awk -F': ' '{print \"SIP: \"$2\" \"}' | tr -d '\n'")
//         osSipInfo   = "SIP: Enable" // test code
        if osSipInfo.contains("Disabled") {
            let sipValue = run ("ioreg -fiw0 -p IODeviceTree -rn options | grep \"csr-active-config\" | awk '{print \"(0x\"substr($3,4,2) substr($3,2,2) substr($3,6,4)\")\"}' | tr -d '\n'")
            if sipValue.length == 12 && !sipValue.contains("(0x\">\"g)") { osSipInfo += "\(sipValue)\n" } else { osSipInfo += "\n"}
        } else { osSipInfo += " (0x00000000)\n" }
        
        if initGlobVar.defaultfileManager.fileExists(atPath: initGlobVar.oclpXmlFilePath) {
            oclppatchInfo = run("grep -A1 \"<key>OpenCore Legacy Patcher</key>\" " + initGlobVar.oclpXmlFilePath + " | tail -1 | sed -e 's?.*<string>?OCLP ?' -e 's?<\\/string>??' | tr -d '\n'")
            let oclpCommit = run("grep -A1 \"<key>Commit URL</key>\" " + initGlobVar.oclpXmlFilePath + " | tail -1 | sed -e 's?.*<string>??' -e 's?<\\/string>??' | awk -F'/' '{print \"(\" substr($NF,1,7) \")\"}' | tr -d '\n'")
            let oclpDateTime = run("grep -A1 \"<key>Time Patched</key>\" " + initGlobVar.oclpXmlFilePath + " | tail -1 | sed -e 's?.*<string>?(?' -e 's?@ ? ?' -e 's?<\\/string>?)?'")

            if oclpCommit != "" { oclppatchInfo += " \(oclpCommit)" }
            if oclpDateTime != "" { oclppatchInfo += " \(oclpDateTime)" }

        }

        if osSipInfo != "" {
            osKernelInfo += "\(osSipInfo)"
        }

        if oclppatchInfo != "" {
            osKernelInfo += "\(oclppatchInfo)"
        }
        
        print("OS Build Info: \(osKernelInfo)")
        return osKernelInfo
    }
}

enum macOSvers {
    case SIERRA
    case HIGH_SIERRA
    case MOJAVE
    case CATALINA
    case BIG_SUR
    case MONTEREY
    case VENTURA
    case SONOMA
    case macOS
}


