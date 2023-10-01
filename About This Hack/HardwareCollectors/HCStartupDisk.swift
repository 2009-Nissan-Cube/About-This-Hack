import Cocoa

class HCStartupDisk {
    static func getStartupDisk() -> String {
        return run("grep \"Volume Name\" " + initGlobVar.bootvolnameFilePath + " | sed 's/.*:[[:space:]]*//' | tr -d '\n'")
    }

    static func getStartupDiskInfo() -> String {
        let firstLineDisk = run("echo $(egrep -n \"" + HCStartupDisk.getStartupDisk() + ":|Mount Point: /$|^$\" " + initGlobVar.storagedataFilePath + " | grep -B2 \"Mount Point: /$\" | head -1 | awk -F':' '{print $1-2}') | tr -d '\n'")
        let lastLineDisk  = run("echo $(egrep -n \"" + HCStartupDisk.getStartupDisk() + ":|Mount Point: /$|^$\"  " + initGlobVar.storagedataFilePath + " | grep -A1 \"Mount Point: /$\" | tail -1 | awk -F':' '{print $1-1}') | tr -d '\n'")
        return run("head -" + lastLineDisk  + " " + initGlobVar.storagedataFilePath + " | tail -$(echo " + lastLineDisk + "-" + firstLineDisk + " | bc)")
    }
}
