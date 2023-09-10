import Cocoa

class HCCPU {
    
    static func getCPU() -> String {
        return run("sysctl -n machdep.cpu.brand_string")
    }
}
