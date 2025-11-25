//
//  About_This_HackApp.swift
//  About This Hack
//
//  Created by AvaQueen on 3/08/21.
//

import SwiftUI

extension String {
    func inserting(separator: String, every n: Int) -> String {
        var result: String = ""
        let characters = Array(self)
        stride(from: 0, to: characters.count, by: n).forEach {
            result += String(characters[$0..<min($0+n, characters.count)])
            if $0+n < characters.count {
                result += separator
            }
        }
        return result
    }
}

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
