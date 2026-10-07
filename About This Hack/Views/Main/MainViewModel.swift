import AppKit

final class MainViewModel: ObservableObject {
    @Published var selectedTab = 0
    /// Bumped whenever hardware data changes so tabs re-read the collectors.
    @Published private(set) var revision = 0
    @Published private(set) var logo = MainViewModel.loadLogo()

    private var observers: [NSObjectProtocol] = []

    init() {
        let center = NotificationCenter.default
        func observe(_ name: Notification.Name, _ handler: @escaping (MainViewModel) -> Void) {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                if let self { handler(self) }
            })
        }

        observe(HardwareCollector.dataDidLoadNotification) { $0.revision += 1 }
        observe(NSApplication.didChangeScreenParametersNotification) {
            HCDisplay.shared.invalidate()
            $0.revision += 1
        }
        observe(NSApplication.didBecomeActiveNotification) {
            HCStartupDisk.shared.invalidate()
            $0.revision += 1
        }
        observe(.customLogoDidChange) { $0.logo = Self.loadLogo() }
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    private static func loadLogo() -> NSImage {
        if let path = UserDefaults.standard.string(forKey: CustomLogoConstants.customLogoPathKey),
           let image = NSImage(contentsOfFile: path) {
            return image
        }
        return namedImage(HCVersion.shared.getOSImageName(), fallback: "Unknown")
    }
}
