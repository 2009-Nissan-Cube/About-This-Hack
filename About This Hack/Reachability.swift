import SystemConfiguration

public enum Reachability {
    static func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            ATHLogger.error("Failed to create network reachability", category: .system)
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            ATHLogger.error("Failed to get reachability flags", category: .system)
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let isConnected = isReachable && !needsConnection

        ATHLogger.info("Internet is \(isConnected ? "reachable" : "NOT reachable")", category: .system)
        
        return isConnected
    }
}
