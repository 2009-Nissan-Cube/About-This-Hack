import AppKit
import SwiftUI

struct OverviewView: View {
    /// Changes when hardware data updates, so SwiftUI re-reads the collectors.
    let revision: Int
    let logo: NSImage
    @State private var isSerialHidden = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(nsImage: logo)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 160, height: 160)
                .shadow(color: Color.black.opacity(0.24), radius: 3, x: 0, y: 1)
                .position(x: 128, y: 155)

            VStack(alignment: .leading, spacing: 0) {
                header
                details.padding(.top, 14)
                buttons.padding(.top, 14)
            }
            .frame(width: 330, alignment: .topLeading)
            .offset(x: 238, y: 26)

            MainFooter()
                .frame(maxWidth: .infinity)
                .position(x: 290, y: 303)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 0) {
            (Text(HCVersion.shared.osPrefix).font(.system(size: 25, weight: .bold))
                + Text(HCVersion.shared.osName.isEmpty ? "" : " \(HCVersion.shared.osName)").font(.system(size: 25)))
                .lineLimit(1)
                .minimumScaleFactor(0.78)

            Text(String(format: L("overview.version_format", comment: "Version format"), HCVersion.shared.osNumber, HCVersion.shared.osBuildNumber))
                .font(.system(size: 11, weight: .semibold))
                .help(trimmedTooltip(HCVersion.shared.getOSBuildInfo()))
        }
    }

    private var details: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(macModelText)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .truncationMode(.tail)
                .help("\(HCMacModel.shared.macName) - \(HCMacModel.shared.modelIdentifier)\n\(HCGPU.shared.getGPUInfo())")

            InfoRow(title: L("overview.label.processor", comment: "Processor label"),
                    value: HCCPU.shared.getCPU(),
                    tooltip: HCCPU.shared.getCPU() + "\n" + HCCPU.shared.getCPUInfo())
            InfoRow(title: L("overview.label.memory", comment: "Memory label"),
                    value: HCRAM.shared.getRam(),
                    tooltip: HardwareCollector.shared.memoryData)
            InfoRow(title: L("overview.label.startup_disk", comment: "Startup Disk label"),
                    value: HCStartupDisk.shared.getStartupDisk(),
                    tooltip: HCStartupDisk.shared.getStartupDiskInfo())
            InfoRow(title: L("overview.label.display", comment: "Display label"),
                    value: HCDisplay.shared.getDisp(),
                    tooltip: HCDisplay.shared.getDispInfo())
            InfoRow(title: L("overview.label.graphics", comment: "Graphics label"),
                    value: HCGPU.shared.getGPU(),
                    tooltip: HCGPU.shared.getGPUInfo())
            InfoRow(title: L("overview.label.serial_number", comment: "Serial Number label"),
                    value: isSerialHidden ? "••••••••••••" : HCSerialNumber.shared.getSerialNumber(),
                    tooltip: HCSerialNumber.shared.getHardwareInfo())
                .contentShape(Rectangle())
                .onTapGesture { isSerialHidden.toggle() }
            InfoRow(title: L("overview.label.bootloader", comment: "Bootloader label"),
                    value: HCBootloader.shared.getBootloader())
        }
    }

    private var buttons: some View {
        HStack(spacing: 14) {
            Button(L("overview.button.system_report", comment: "System Report button")) {
                NSWorkspace.shared.open(URL(fileURLWithPath: InitGlobVar.systemReportSP))
            }
            .help(trimmedTooltip(L("tooltip.sysinfo", comment: "System Info button tooltip")))

            Button(L("overview.button.software_update", comment: "Software Update button"), action: openSoftwareUpdate)
                .help(trimmedTooltip(L("tooltip.softupd", comment: "Software Update button tooltip")))
        }
        .controlSize(.small)
    }

    private var macModelText: String {
        let full = "\(HCMacModel.shared.macName) - \(HCMacModel.shared.modelIdentifier)"
        return full.count > 60 ? HCMacModel.shared.macName : full
    }

    private func openSoftwareUpdate() {
        let opened = openFirstAvailableURL(
            urlStrings: [
                "x-apple.systempreferences:com.apple.Software-Update-Settings.extension",
                "x-apple.systempreferences:com.apple.preferences.softwareupdate"
            ],
            fallbackFilePaths: [InitGlobVar.softwareUpdateSP]
        )
        if !opened {
            NSWorkspace.shared.open(URL(fileURLWithPath: "\(InitGlobVar.allAppliLocation)/App Store.app"))
        }
    }
}
