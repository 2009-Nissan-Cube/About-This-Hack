//
//  SettingsView.swift
//  About This Hack
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Title
            Text(NSLocalizedString("settings.title", comment: "Custom logo settings"))
                .font(.system(size: 16, weight: .bold))
                .padding(.top, 10)
                .padding(.horizontal, 20)
            
            // Info label
            Text(NSLocalizedString("settings.logo.info", comment: "Drag and drop a PNG image (1024x1024 pixels) to customize the macOS logo in the Overview tab."))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(height: 40)
                .padding(.top, 4)
                .padding(.horizontal, 20)
                .padding(.bottom, 4)
            
            // Logo image with drag and drop
            ZStack {
                Image(nsImage: viewModel.logoImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .background(Color(NSColor.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(viewModel.isDragging ? Color.blue : Color.gray, lineWidth: 2)
                    )
                    .onDrop(of: [.fileURL], isTargeted: $viewModel.isDragging) { providers in
                        viewModel.handleDrop(providers: providers)
                        return true
                    }
            }
            .padding(.top, 0)
            
            // Status label
            Text(viewModel.statusMessage)
                .font(.system(size: 13))
                .foregroundColor(viewModel.statusColor)
                .frame(height: 16)
                .padding(.top, 8)
                .padding(.horizontal, 20)
            
            // Reset button
            Button() {
                viewModel.resetToDefault()
            }
                label: {
                Text(NSLocalizedString("settings.logo.reset", comment: "Reset to Default"))
                    .font(.system(size: 12))
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
        .frame(width: 422, height: 330)
        .onAppear {
            viewModel.loadCustomLogo()
        }
    }
}

// ViewModel for SettingsView
class SettingsViewModel: ObservableObject {
    @Published var logoImage: NSImage = NSImage()
    @Published var statusMessage: String = ""
    @Published var statusColor: Color = .gray
    @Published var isDragging: Bool = false
    
    private let defaults = UserDefaults.standard
    
    func loadCustomLogo() {
        if let logoPath = defaults.string(forKey: CustomLogoConstants.customLogoPathKey),
           let image = NSImage(contentsOfFile: logoPath) {
            logoImage = image
            statusMessage = NSLocalizedString("settings.logo.custom_active", comment: "Custom logo active")
            statusColor = .green
        } else {
            // Show default OS logo
            logoImage = NSImage(named: getOSImageName()) ?? NSImage()
            statusMessage = NSLocalizedString("settings.logo.default_active", comment: "Default logo active")
            statusColor = .gray
        }
    }
    
    private func getOSImageName() -> String {
        // Use the same logic as ViewController
        let osImageNames: [MacOSVersion: String] = [
            .tahoe: "Tahoe", .sequoia: "Sequoia", .sonoma: "Sonoma", .ventura: "Ventura",
            .monterey: "Monterey", .bigSur: "Big Sur", .catalina: "Catalina",
            .mojave: "Mojave", .highSierra: "High Sierra", .sierra: "Sierra"
        ]
        return osImageNames[HCVersion.shared.osVersion] ?? "Unknown"
    }
    
    func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        
        provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { [weak self] (urlData, error) in
            guard let self = self,
                  let urlData = urlData as? Data,
                  let url = URL(dataRepresentation: urlData, relativeTo: nil) else {
                DispatchQueue.main.async {
                    self?.isDragging = false
                }
                return
            }
            
            self.handleDroppedImage(at: url.path)
        }
    }
    
    func handleDroppedImage(at path: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Validate image
            guard let image = NSImage(contentsOfFile: path) else {
                self.showError(NSLocalizedString("settings.logo.error.invalid", comment: "Invalid image file"))
                return
            }
            
            // Check if it's a PNG
            guard path.lowercased().hasSuffix(".png") else {
                self.showError(NSLocalizedString("settings.logo.error.not_png", comment: "Image must be in PNG format"))
                return
            }
            
            // Check dimensions
            guard let imageRep = image.representations.first else {
                self.showError(NSLocalizedString("settings.logo.error.no_rep", comment: "Cannot read image dimensions"))
                return
            }
            
            let width = imageRep.pixelsWide
            let height = imageRep.pixelsHigh
            
            guard width == 1024 && height == 1024 else {
                self.showError(String(format: NSLocalizedString("settings.logo.error.wrong_size",
                    comment: "Image must be 1024x1024 pixels. Current size: %dx%d"), width, height))
                return
            }
            
            // Save the path
            self.defaults.set(path, forKey: CustomLogoConstants.customLogoPathKey)
            
            // Update display
            self.logoImage = image
            self.statusMessage = NSLocalizedString("settings.logo.success", comment: "Custom logo applied successfully")
            self.statusColor = .green
            
            // Post notification to update the Overview tab
            NotificationCenter.default.post(name: .customLogoDidChange, object: nil)
        }
    }
    
    func resetToDefault() {
        defaults.removeObject(forKey: CustomLogoConstants.customLogoPathKey)
        loadCustomLogo()
        
        // Post notification to update the Overview tab
        NotificationCenter.default.post(name: .customLogoDidChange, object: nil)
        
        statusMessage = NSLocalizedString("settings.logo.reset_success", comment: "Logo reset to default")
        statusColor = .green
    }
    
    private func showError(_ message: String) {
        statusMessage = message
        statusColor = .red
        
        // Play beep sound for errors
        NSSound.beep()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
