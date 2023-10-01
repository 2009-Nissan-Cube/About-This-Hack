class HCRAM {
    
    static func getRam() -> String {
        let ram = run("echo \"$(($(sysctl -n hw.memsize) / 1073741824))\" | tr -d '\n'")  // 1073741824 = 1024 third power
        let ramType = run("grep 'Type' " + initGlobVar.sysmemFilePath + " | awk '{print $2}' | sed -n '1p'")
        print("RAM Type: " + ramType)
        let ramSpeed = run("grep 'Speed' " + initGlobVar.sysmemFilePath + " | grep 'MHz' | awk '{print $2\" \"$3}' | sed -n '1p'").trimmingCharacters(in: .whitespacesAndNewlines)
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
    
    static func getMemDesc() -> String {
        return run("echo \"$(egrep \"ECC:|BANK |Size:|Type:|Speed:|Manufacturer:|Part Number:\" " + initGlobVar.sysmemFilePath + ")\"")
    }

    // Another Data display way
    static func getMemDescArray() -> String {
        var memInfoFormatted = ""
        let memoryDataTmp = run("echo $(egrep \"BANK |Size:|Type:|Speed:|Manufacturer:|Part Number:\" " + initGlobVar.sysmemFilePath + " | sed -e 's/$/ /g' -e 's/^. *//g' -e 's/:/: /g' -e 's/:  /: /g' | tr -d '\n' | sed 's/BANK /\\nBANK /g' )")
        let memoryDataArray = memoryDataTmp.components(separatedBy: "BANK ").filter({ $0 != ""})
        for index in 0..<memoryDataArray.count {
            memInfoFormatted += ("BANK " + "\(memoryDataArray[index])" + run("echo \"\n\""))
        }
        return "\(memInfoFormatted)"
    }
}
