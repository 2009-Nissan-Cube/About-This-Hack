//
//  UpdateViewController.swift
//  About This Hack
//
//  Created by MDNich on 6/21/22.
//

import Foundation
import AppKit

class UpdateViewController: NSViewController {
    var fileContents: String!
    var isFileDownloaded: Bool = false
    var fileDURL: URL? = nil
    var fileDURL2: URL? = nil
    
    var currentVersionNumber = "0.2.0" /// THIS MUST BE CHANGED EVERY MAJOR VERSION

    @IBOutlet weak var onlineImg: NSImageView!
    
    override func viewWillAppear() {
        currentVersion.stringValue = currentVersionNumber
    }
    
    override func viewDidLoad() {
            
        if(Reachability.isConnectedToNetwork()) {
            updateProgressBar.isIndeterminate = true
            updateProgressBar.startAnimation(nil)
            let urlPath: String = "https://aboutthishackupdateserver.herokuapp.com/version.txt"
            //let urlPath: String = "http://localhost:8080/version.txt"

            let url: URL = URL(string: urlPath)!
            let request = NSMutableURLRequest(url: url)
            print("req1")
            let session = URLSession.shared
            print("req2")
            let downloadTask = URLSession.shared.downloadTask(with: url) {
                urlOrNil, responseOrNil, errorOrNil in
                // check for and handle errors:
                // * errorOrNil should be nil
                // * responseOrNil should be an HTTPURLResponse with statusCode in 200..<299
                
                guard let fileURL = urlOrNil else { return }
                do {
                    self.fileDURL = fileURL
                    print("File is at \(fileURL)")
                    let documentsURL = try
                    FileManager.default.url(for: .documentDirectory,
                                            in: .userDomainMask,
                                            appropriateFor: nil,
                                            create: false)
                    let savedURL = documentsURL.appendingPathComponent(fileURL.lastPathComponent)
                    try FileManager.default.moveItem(at: fileURL, to: savedURL)
                } catch {
                    print ("file error: \(error)")
                }
                print("file downloaded")
                self.isFileDownloaded = true
                self.fileContents =  self.stringifyDocumentDownloaded(fileURL: self.fileDURL!)
                print("stringified")
                self.latestVersion.stringValue = self.fileContents
                print("printed to screen: \(self.latestVersion.stringValue)")
                self.latestVersion.updateLayer()
                self.latestVersion.needsDisplay = true
                self.updateProgressBar.isIndeterminate = false
                self.updateProgressBar.doubleValue = 100
                self.updateProgressBar.updateLayer()
                if(self.fileContents != self.currentVersionNumber)
                {
                    self.updateButton.isEnabled = true
                    self.updateButton.updateLayer()
                    self.updateButton.needsDisplay = true
                }
            }
            downloadTask.resume()
        }
        else {
            updateProgressBar.isHidden = true
            onlineImg.image = NSImage(named: "NSStatusUnavailable")
            onlineImg.toolTip = "Status: Offline"
            offlineLabel.isHidden = false
           
    }
    }
    
    @IBOutlet weak var offlineLabel: NSTextField!
    func stringifyDocumentDownloaded(fileURL: URL) -> String {
        print("file stringification requested")
        if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            var fileURL = documentDirectory.appendingPathComponent(fileURL.lastPathComponent)
            if(isFileDownloaded) {
                do {
                return try String(contentsOf: fileURL, encoding: String.Encoding.macOSRoman)}
                catch {return ""}
            }
        }
        return ""
    }
    
    @IBAction func reload(_ sender: Any) {
        offlineLabel.isHidden = true
        updateProgressBar.isHidden = false
        viewDidLoad()
    }
    @IBOutlet weak var updateProgressBar: NSProgressIndicator!
    @IBOutlet weak var updateButton: NSButton!
    
    @IBAction func updateDownload(_ sender: Any) {
        let url = URL(string: "https://github.com/0xCUB3/About-This-Hack/releases")!
        if NSWorkspace.shared.open(url) {
            print("Browser Successfully opened")
        }
    }
    @IBOutlet weak var currentVersion: NSTextField!
    @IBOutlet weak var latestVersion: NSTextField!
}
