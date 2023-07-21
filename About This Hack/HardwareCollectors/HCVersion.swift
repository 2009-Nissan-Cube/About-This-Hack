//
//  HCVersion.swift
//  About This Hack
//
//  Created by Felix on 15.07.23.
//

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
        OSnum = getOSnum()
        print(OSnum)
        setOSvers(osNumber: OSnum)
        OSname = macOSversToString()
        osPrefix = getOSPrefix()
        OSBuildNum = getOSBuildNum()
        
        dataHasBeenSet = true
    }
    
    

    static func getOSnum() -> String {
        
        let osVersion = run("sw_vers -productVersion")
        
        return osVersion
    }
    static func setOSvers(osNumber: String) {
        switch osNumber.prefix(2) {
            case "14": OSvers = macOSvers.SONOMA
            case "13": OSvers = macOSvers.VENTURA
            case "12": OSvers = macOSvers.MONTEREY
            case "11": OSvers = macOSvers.BIG_SUR
            case "10":
                if osNumber.contains("16") { OSvers = macOSvers.BIG_SUR }
                else if osNumber.contains("15") { OSvers = macOSvers.CATALINA }
                else if osNumber.contains("14") { OSvers = macOSvers.MOJAVE }
                else if osNumber.contains("13") { OSvers = macOSvers.HIGH_SIERRA }
                else if osNumber.contains("12") { OSvers = macOSvers.SIERRA }
                else if osNumber.contains("11") { OSvers = macOSvers.EL_CAPITAN }
                else if osNumber.contains("10") { OSvers = macOSvers.YOSEMITE }
                else if osNumber.contains("9") { OSvers = macOSvers.MAVERICKS }
                else { OSvers = macOSvers.macOS }
            default: OSvers = macOSvers.macOS
        }
    }



    static func macOSversToString() -> String {
        switch OSvers {
        case .MAVERICKS: return "Mavericks"
        case .YOSEMITE: return "Yosemite"
        case .EL_CAPITAN: return "El Capitan"
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


    static func getOSBuildNum() -> String {
        return "(" + run("sw_vers -buildVersion") + ")"
    }
    
    static func getOSPrefix() -> String{
        switch OSvers {
        case .MAVERICKS,.YOSEMITE,.EL_CAPITAN:
            return "OS X"
        case .SIERRA,.HIGH_SIERRA,.MOJAVE,.CATALINA,.BIG_SUR,.MONTEREY,.VENTURA,.SONOMA,.macOS:
            return "macOS"
        }
    }
}

enum macOSvers {
    case MAVERICKS
    case YOSEMITE
    case EL_CAPITAN
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


