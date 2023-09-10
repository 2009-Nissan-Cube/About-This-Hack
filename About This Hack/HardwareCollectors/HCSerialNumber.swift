import Foundation

class HCSerialNumber {
    
    static func getSerialNumber() -> String {
        return run("awk '/Serial/ {print $4}' ~/.ath/hw.txt")
    }
}
