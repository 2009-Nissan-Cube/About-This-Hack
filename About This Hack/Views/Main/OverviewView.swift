import AppKit
import SwiftUI

struct OverviewView: View {
    @State private var isSerialHidden = false
    @State private var logoRefreshID = UUID()

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Image(nsImage: logoImage)
                    .resizable()
                    .interpolation(.high)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 160, height: 160)
                    .shadow(color: Color.black.opacity(0.24), radius: 3, x: 0, y: 1)
                    .position(x: 128, y: 155)
                    .id(logoRefreshID)

                header
                    .frame(width: 330, height: 44, alignment: .topLeading)
                    .position(x: 403, y: 44)

                details
                    .frame(width: 330, height: 134, alignment: .topLeading)
                    .position(x: 403, y: 148)

                buttons
                    .frame(width: 330, height: 24, alignment: .leading)
                    .position(x: 403, y: 250)

                MainFooter()
                    .frame(width: geometry.size.width, alignment: .center)
                    .position(x: geometry.size.width / 2, y: 303)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
            .clipped()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onReceive(NotificationCenter.default.publisher(for: .customLogoDidChange)) { _ in
            logoRefreshID = UUID()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            osTitle
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(String(format: L("overview.version_format", comment: "Version format"), HCVersion.shared.osNumber, HCVersion.shared.osBuildNumber))
                .font(.system(size: 11, weight: .semibold))
                .help(trimmedTooltip(Tooltips.shared.osVersiontoolTip) ?? "")
        }
    }

    private var osTitle: Text {
        let prefix = Text(HCVersion.shared.osPrefix)
            .font(.system(size: 25, weight: .bold))

        let osName = HCVersion.shared.osName
        guard !osName.isEmpty else {
            return prefix
        }

        return prefix + Text(" \(osName)")
            .font(.system(size: 25, weight: .regular))
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(macModelText)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .help(trimmedTooltip(Tooltips.shared.macModeltoolTip) ?? "")

            ClassicInfoRow(title: L("overview.label.processor", comment: "Processor label"),
                           value: HCCPU.shared.getCPU(),
                           tooltip: Tooltips.shared.cputoolTip)
            ClassicInfoRow(title: L("overview.label.memory", comment: "Memory label"),
                           value: HCRAM.shared.getRam(),
                           tooltip: Tooltips.shared.ramtoolTip)
            ClassicInfoRow(title: L("overview.label.startup_disk", comment: "Startup Disk label"),
                           value: HCStartupDisk.shared.getStartupDisk(),
                           tooltip: Tooltips.shared.startupDisktoolTip)
            ClassicInfoRow(title: L("overview.label.display", comment: "Display label"),
                           value: HCDisplay.shared.getDisp(),
                           tooltip: Tooltips.shared.displaytoolTip)
            ClassicInfoRow(title: L("overview.label.graphics", comment: "Graphics label"),
                           value: HCGPU.shared.getGPU(),
                           tooltip: Tooltips.shared.graphicstoolTip)
            serialRow
            ClassicInfoRow(title: L("overview.label.bootloader", comment: "Bootloader label"),
                           value: HCBootloader.shared.getBootloader(),
                           tooltip: nil)
        }
    }

    private var buttons: some View {
        HStack(spacing: 14) {
            Button(L("overview.button.system_report", comment: "System Report button"), action: openSystemReport)
                .controlSize(.small)
                .help(trimmedTooltip(Tooltips.shared.btSysInfotoolTip) ?? "")

            Button(L("overview.button.software_update", comment: "Software Update button"), action: openSoftwareUpdate)
                .controlSize(.small)
                .help(trimmedTooltip(Tooltips.shared.btSoftUpdtoolTip) ?? "")
        }
    }

    private var serialRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(L("overview.label.serial_number", comment: "Serial Number label"))
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 82, alignment: .leading)

            Text(isSerialHidden ? "••••••••••••" : HCSerialNumber.shared.getSerialNumber())
                .font(.system(size: 11, weight: .regular))
                .lineLimit(1)
                .truncationMode(.tail)
                .contentShape(Rectangle())
                .onTapGesture {
                    isSerialHidden.toggle()
                }
                .help(trimmedTooltip(Tooltips.shared.serialToggletoolTip) ?? "")
        }
    }

    private var logoImage: NSImage {
        if let customLogoPath = UserDefaults.standard.string(forKey: CustomLogoConstants.customLogoPathKey),
           let customImage = NSImage(contentsOfFile: customLogoPath) {
            return customImage
        }

        return namedImage(HCVersion.shared.getOSImageName(), fallback: "Unknown")
    }

    private var macModelText: String {
        let macNamePart = HCMacModel.shared.macName
        let modelIdentifierPart = HCMacModel.shared.getModelIdentifier()
        let fullMacModelString = "\(macNamePart) - \(modelIdentifierPart)"
        return fullMacModelString.count > 60 ? macNamePart : fullMacModelString
    }

    private func openSystemReport() {
        NSWorkspace.shared.open(URL(fileURLWithPath: InitGlobVar.systemReportSP))
    }

    private func openSoftwareUpdate() {
        let openedSettings = openFirstAvailableURL(
            urlStrings: [
                "x-apple.systempreferences:com.apple.Software-Update-Settings.extension",
                "x-apple.systempreferences:com.apple.preferences.softwareupdate"
            ],
            fallbackFilePaths: [InitGlobVar.softwareUpdateSP]
        )

        if !openedSettings {
            NSWorkspace.shared.open(URL(fileURLWithPath: "\(InitGlobVar.allAppliLocation)/App Store.app"))
        }
    }
}

private struct ClassicInfoRow: View {
    let title: String
    let value: String
    var tooltip: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 82, alignment: .leading)

            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 11, weight: .regular))
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .help(trimmedTooltip(tooltip) ?? "")
    }
}
