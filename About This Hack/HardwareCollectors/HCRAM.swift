class HCRAM {
    
    static func getRam() -> String {
        let ram = run("echo \"$(($(sysctl -n hw.memsize) / 1024 / 1024 / 1024))\" | tr -d '\n'")
        let ramType = run("grep 'Type' ~/.ath/sysmem.txt | awk '{print $2}' | sed -n '1p'")
        print("RAM Type: " + ramType)
        let ramSpeed = run("grep 'Speed' ~/.ath/sysmem.txt | grep 'MHz' | awk '{print $2\" \"$3}' | sed -n '1p'").trimmingCharacters(in: .whitespacesAndNewlines)
        print("RAM Speed: " + ramSpeed)
        // If RAM type doesn't show up
        if !ramType.contains("D") {
            if !ramSpeed.contains("mpty") || ramSpeed != "" {
                return "\(ram) GB \(ramSpeed)"
            // If RAM speed doesn't show up either
            } else {
                return "\(ram) GB"
            }
        // If just RAM speed doesn't show up
        } else if ramSpeed.contains("mpty") || ramSpeed == "" {
            return "\(ram) GB \(ramType)"
        // Normal case
        } else {
            return "\(ram) GB \(ramSpeed) \(ramType)"
        }
    }
}
