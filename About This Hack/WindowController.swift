//
//  WindowController.swift
//  NSTabView
//
//

import Cocoa

class WindowController: NSWindowController {
    
    public var tabViewController: NSTabViewController?
    public var currentView: Int = 0
    @IBOutlet public weak var segmentedControl: NSSegmentedControl!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        print("loaded")
        self.tabViewController = self.window?.contentViewController as? NSTabViewController
    }

    @IBAction func segmentedControlSwitched(_ sender: Any) {
        print("switched")
        guard let segCtrl = sender as? NSSegmentedControl else { return }
        currentView = segCtrl.selectedSegment
        tabViewController?.selectedTabViewItemIndex = currentView
    }
    
    public func changeView(new: Int) {
        print("changed to \(new)")
        tabViewController?.selectedTabViewItemIndex = new
        segmentedControl?.selectedSegment = new
    }
}
