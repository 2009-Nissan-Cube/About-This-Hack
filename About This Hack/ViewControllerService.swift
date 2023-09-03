//
//  ViewControllerDisplays.swift
//  ViewControllerDisplays
//
//

import Foundation
import Cocoa

class ViewControllerService: NSViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        start()
        
    }
    

    override var representedObject: Any? {
        didSet {
        }
    }

    override func viewDidAppear() {
        self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
    }
    
    func start() {
        print("Initializing Service View...")
    }
}
