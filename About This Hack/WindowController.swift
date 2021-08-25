//
//  WindowController.swift
//  NSTabView
//
//  Created by Szabolcs Toth on 11/19/18.
//  Copyright © 2018 purzelbaum.hu. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    
    var tabViewController: NSTabViewController?
    public var currentView: Int = 0
    @IBOutlet public weak var segmentedControl: NSSegmentedControl!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        print("loaded")
        
        self.tabViewController = self.window?.contentViewController as? NSTabViewController
        
        if let window = window {
            if let view = window.contentView {
                
                //window.setValue(580, forKey: "width")
                //view.wantsLayer = true
                //window.titleVisibility = .hidden
                    //window.titlebarAppearsTransparent = true
                //window.backgroundColor = .white
            }
        }

    }

    @IBAction func segmentedControlSwitched(_ sender: Any) {
        
        print("switched")
        let segCtrl = sender as! NSSegmentedControl
        currentView = segCtrl.selectedSegment
        self.tabViewController?.selectedTabViewItemIndex = currentView
        ViewController.currentView = currentView
    }
}
