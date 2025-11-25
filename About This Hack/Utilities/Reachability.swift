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
            ATHLogger.error(NSLocalizedString("log.reachability.failed_create", comment: "Failed to create network reachability"), category: .system)
            return false
        }

        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            ATHLogger.error(NSLocalizedString("log.reachability.failed_flags", comment: "Failed to get reachability flags"), category: .system)
            return false
        }

        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        let isConnected = isReachable && !needsConnection

        let status = isConnected ? NSLocalizedString("log.reachability.reachable", comment: "reachable") : NSLocalizedString("log.reachability.not_reachable", comment: "NOT reachable")
        ATHLogger.info(String(format: NSLocalizedString("log.reachability.status", comment: "Internet status"), status), category: .system)
        
        return isConnected
    }
}
