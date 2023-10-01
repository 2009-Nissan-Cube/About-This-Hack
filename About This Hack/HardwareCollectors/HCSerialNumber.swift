import Foundation

class HCSerialNumber {
    
    static func getSerialNumber() -> String {
        return run("awk '/Serial/ {print $4}' " + initGlobVar.hwFilePath)
    }
    
    static func getHardWareInfo() -> String {
        return run("cat " + initGlobVar.hwFilePath + " | egrep \"[System Firmware |OS Loader |SMC ]Version|Apple ROM Info:|Board-ID :|Hardware UUID:|Provisioning UDID:\" | sed -e 's/^ *//g' -e 's/^/      /g'")
    }
}
