import Cocoa
import SwiftUI

class WindowController: NSWindowController {
    public let viewModel = MainViewModel()

    private let defaults = UserDefaults.standard
    private let windowFrameKey = "MainWindowFrame"
    private let fixedWindowFrameSize = NSSize(width: 580, height: 350)
    private var isSetupComplete = false
    private var isLoadingMainWindowData = false

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 580, height: 350),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )

        self.init(window: window)
        performSetupIfNeeded()
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        performSetupIfNeeded()
    }

    override func showWindow(_ sender: Any?) {
        performSetupIfNeeded()
        super.showWindow(sender)
        window?.makeKeyAndOrderFront(sender)
        startLoadingIfReady()
    }

    private func performSetupIfNeeded() {
        guard !isSetupComplete else { return }
        isSetupComplete = true

        ATHLogger.info(NSLocalizedString("log.window.loaded", comment: "Window controller loaded"), category: .ui)

        configureWindow()
        setupSwiftUIContent()
        restoreWindowFrame()
        registerNotifications()
        startLoadingIfReady()
    }

    private func configureWindow() {
        guard let window else { return }

        window.title = Bundle.main.applicationName ?? "About This Hack"
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.toolbarStyle = .unifiedCompact
        window.styleMask.remove(.resizable)
        window.collectionBehavior = []

        var frame = window.frame
        frame.size = fixedWindowFrameSize
        window.setFrame(frame, display: false)
    }

    private func setupSwiftUIContent() {
        guard let window else { return }

        let contentSize = window.contentRect(forFrameRect: NSRect(origin: .zero, size: fixedWindowFrameSize)).size
        let rootView = MainView(viewModel: viewModel)
            .frame(width: contentSize.width, height: contentSize.height)
        window.contentViewController = NSHostingController(rootView: rootView)
    }


    private func registerNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(windowDidMove),
                                               name: NSWindow.didMoveNotification,
                                               object: window)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(dataFilesCreated),
                                               name: CreateDataFiles.dataFilesCreatedNotification,
                                               object: nil)
    }

    private func restoreWindowFrame() {
        guard let window else { return }

        if let savedFrame = defaults.string(forKey: windowFrameKey) {
            var frame = NSRectFromString(savedFrame)
            frame.size = fixedWindowFrameSize
            window.setFrame(frame, display: false)
            ATHLogger.debug(NSLocalizedString("log.window.restored", comment: "Window position restored"), category: .ui)
        } else {
            var frame = window.frame
            frame.size = fixedWindowFrameSize
            window.setFrame(frame, display: false)
            window.center()
            ATHLogger.debug(NSLocalizedString("log.window.centered", comment: "Window centered"), category: .ui)
        }
    }

    @objc private func dataFilesCreated() {
        startLoadingIfReady()
    }

    private func startLoadingIfReady() {
        guard CreateDataFiles.dataFilesCreated else { return }
        loadDataAndShowWindow()
    }

    private func loadDataAndShowWindow() {
        guard !isLoadingMainWindowData, !viewModel.isLoaded else { return }
        isLoadingMainWindowData = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            HardwareCollector.shared.getAllData()

            DispatchQueue.main.async {
                guard let self else { return }

                self.isLoadingMainWindowData = false
                self.viewModel.markLoaded()
                self.window?.makeKeyAndOrderFront(nil)
                ATHLogger.info(NSLocalizedString("log.window.shown", comment: "Window shown after data loaded"), category: .ui)
            }
        }
    }

    public func changeView(new index: Int) {
        ATHLogger.info(String(format: NSLocalizedString("log.window.view_changing", comment: "Changing view to index"), index), category: .ui)
        viewModel.selectedTab = index
        window?.makeKeyAndOrderFront(nil)
    }

    @objc private func windowDidMove(_ notification: Notification) {
        saveWindowFrame()
    }

    private func saveWindowFrame() {
        if let window = self.window {
            let frameString = NSStringFromRect(window.frame)
            defaults.set(frameString, forKey: windowFrameKey)
            ATHLogger.debug(String(format: NSLocalizedString("log.window.frame_saved", comment: "Saved window frame"), frameString), category: .ui)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        ATHLogger.debug(NSLocalizedString("log.window.deinitialized", comment: "Window controller deinitialized"), category: .ui)
    }
}
