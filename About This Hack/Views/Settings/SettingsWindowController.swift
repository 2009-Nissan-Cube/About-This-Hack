import Cocoa
import SwiftUI

final class SettingsWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(contentViewController: NSHostingController(rootView: SettingsView()))
        window.title = NSLocalizedString("settings.title", comment: "Custom logo settings")
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.isReleasedWhenClosed = false
        self.init(window: window)
    }

    override func showWindow(_ sender: Any?) {
        positionNextToMainWindow()
        super.showWindow(sender)
    }

    /// Places the window beside the main window (right, else left), kept fully on screen.
    private func positionNextToMainWindow() {
        guard let window else { return }
        guard let main = NSApp.windows.first(where: { $0.windowController is WindowController && $0.isVisible }),
              let screen = main.screen?.visibleFrame else {
            window.center()
            return
        }

        let size = window.frame.size
        let spacing: CGFloat = 10
        var origin = NSPoint(x: main.frame.maxX + spacing, y: main.frame.maxY - size.height)
        if origin.x + size.width > screen.maxX {
            origin.x = main.frame.minX - size.width - spacing
        }
        origin.x = min(max(origin.x, screen.minX), screen.maxX - size.width)
        origin.y = min(max(origin.y, screen.minY), screen.maxY - size.height)
        window.setFrameOrigin(origin)
    }
}
