import Foundation
import AppKit
import Zip

class UpdateController {
    static func checkForUpdates() -> Bool {
        print("Checking for updates...")
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        _ = run("curl -o ~/.ath/version.txt https://raw.githubusercontent.com/0xCUB3/Website/main/content/ath.txt")
        let latestVersion = run("tr -d '[:space:]' < ~/.ath/version.txt")
        if appVersion < latestVersion {
            print("Newer version (" + latestVersion + ") available")
            let prompt = alert(message: "Update found!", text: "The latest version is " + latestVersion + ". You are currently running " + appVersion + ".")
            print("Done")
            return prompt
        }
        return false
    }
    
    static func alert(message: String, text: String) -> Bool {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = text
        alert.alertStyle = .critical
        alert.addButton(withTitle: "Update")
        alert.addButton(withTitle: "Skip")
        return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
    }
    
    static func updateATH() {
        print("Starting Update...")
        print("Starting Download...")
        notify(title: "Starting Download", informativeText: "This may take awhile...")
        _ = run("curl -L https://github.com/0xCUB3/About-This-Hack/releases/download/" + run("tr -d '[:space:]' <  ~/.ath/version.txt") + "/About.This.Hack.zip -o ~/.ath/new_ath.zip")
        print("Killing Old App...")
        notify(title: "Replacing Apps", informativeText: "Deleting the old version and replacing it with the new version")
        // Thanks for the code, Ben216k
        let rm = run("rm -r '/Applications/About This Hack.app'")
        if rm.contains("No") {
            notify(title: "Failed to delete the old copy of About This Hack.app", informativeText: "Please make sure it is in the Applications folder!!!")
            return
        }
        _ = run("[[ ! -d '/Applications/About This Hack.app' ]]")
        print("Unzipping Archive...")
        notify(title: "Unzipping Archive", informativeText: "")
        do {
            _ = try Zip.unzipFile(URL(string: "/Users/alexanderskula/.ath/new_ath.zip")!, destination: URL(string: "/Users/alexanderskula/")!, overwrite: true, password: "")
        } catch {
            print(error)
        }
        
        
        print("Copying New Version...")
        notify(title: "Copying New Version", informativeText: "Almost there!")
        _ = run("cp -rf ~/About\\ This\\ Hack.app /Applications")
        
        notify(title: "Update Complete!", informativeText: "Launching New Version...")
        _ = run("open /Applications/About\\ This\\ Hack\\.app")
        exit(0)
    }
    
    static func notify(title: String, informativeText: String) -> Void {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = informativeText
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.default.deliver(notification)
    }
}
