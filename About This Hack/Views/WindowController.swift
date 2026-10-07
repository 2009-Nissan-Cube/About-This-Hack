import Cocoa
import SwiftUI

final class WindowController: NSWindowController {
    let viewModel = MainViewModel()

    private static let frameAutosaveName = "MainWindow"
    private static let contentSize = NSSize(width: 580, height: 322)

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: Self.contentSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        self.init(window: window)

        window.title = Bundle.main.applicationName ?? "About This Hack"
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.toolbarStyle = .unifiedCompact
        window.collectionBehavior = [.fullScreenNone]

        let hostingController = NSHostingController(rootView: MainView(viewModel: viewModel)
            .frame(width: Self.contentSize.width, height: Self.contentSize.height))
        window.contentViewController = hostingController
        window.setContentSize(Self.contentSize)
        restoreWindowFrame()
    }

    /// Restores the saved position, recentering if it no longer fits on any connected screen.
    private func restoreWindowFrame() {
        guard let window else { return }

        let restored = window.setFrameUsingName(Self.frameAutosaveName)
        let isVisible = NSScreen.screens.contains { $0.visibleFrame.intersection(window.frame).width >= 100 }
        if !restored || !isVisible {
            window.center()
        }
        window.setFrameAutosaveName(Self.frameAutosaveName)
    }

    func changeView(new index: Int) {
        viewModel.selectedTab = index
        window?.makeKeyAndOrderFront(nil)
    }
}
