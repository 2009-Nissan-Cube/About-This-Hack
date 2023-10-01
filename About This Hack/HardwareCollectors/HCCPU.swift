import Cocoa

class HCCPU {
    
    static func getCPU() -> String {
        return run("sysctl -n machdep.cpu.brand_string")
    }
    
    static func getCPUInfo() -> String {
        let firstLineCpu = run("grep -n \"Processor Name: \" " + initGlobVar.hwFilePath + " | awk -F':' '{print $1}' | tr -d '\n'")
        let lastLineCpu = run("grep -n \"Memory: \" " + initGlobVar.hwFilePath + " | awk -F':' '{print $1-1}' | tr -d '\n'")
        return run("head -" + lastLineCpu + " " + initGlobVar.hwFilePath + " | tail -$(echo " + lastLineCpu + "-" + firstLineCpu + " | bc)")
    }
}
