import Cocoa

class HCStartupDisk {
    static func getStartupDisk() -> String {
        return run("grep 'Volume Name' ~/.ath/sysvolname.txt | sed 's/.*:[[:space:]]*//' | tr -d '\n'")
    }
}
