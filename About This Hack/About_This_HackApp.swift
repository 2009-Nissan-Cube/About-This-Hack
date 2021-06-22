//
//  About_This_HackApp.swift
//  About This Hack
//
//  Created by AvaQueen on 3/08/21.
//

import SwiftUI

@main
struct About_This_HackApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willUpdateNotification), perform: { _ in
                hideButtons()
            })
        }
    }
    func hideButtons() {
        for window in NSApplication.shared.windows {
            window.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isHidden = true
            //window.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)!.isHidden = true
        }
    }
}
