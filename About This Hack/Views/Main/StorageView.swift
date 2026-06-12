import AppKit
import SwiftUI

struct StorageView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Text(L("storage.label.startup_disk", comment: "Startup Disk storage title"))
                    .font(.system(size: 25, weight: .bold))
                    .frame(width: geometry.size.width, alignment: .center)
                    .position(x: geometry.size.width / 2, y: 48)

                VStack(spacing: 8) {
                    Image(nsImage: storageImage)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 126, height: 126)
                        .help(trimmedTooltip(Tooltips.shared.startupDiskImagetoolTip) ?? "")

                    storageMeter
                        .frame(width: 126, height: 12)
                }
                .frame(width: 126, alignment: .center)
                .position(x: 150, y: 150)

                VStack(alignment: .leading, spacing: 7) {
                    Text(HCStartupDisk.shared.getStartupDisk())
                        .font(.system(size: 18, weight: .semibold))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    StorageInfoRow(title: L("storage.label.kind", comment: "Storage kind label"), value: driveKind)
                    StorageInfoRow(title: L("storage.label.connection", comment: "Storage connection label"), value: driveConnection)
                    StorageInfoRow(title: L("storage.label.capacity", comment: "Storage capacity label"), value: capacityText)
                }
                .frame(width: 330, alignment: .leading)
                .position(x: 405, y: 150)

            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .onAppear {
            ATHLogger.info(NSLocalizedString("log.storage.init", comment: "Storage view initializing"), category: .ui)
        }
    }

    private var storageMeter: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(NSColor.separatorColor).opacity(0.30))
                    .frame(height: 8)

                Capsule()
                    .fill(Color.accentColor.opacity(0.82))
                    .frame(width: geometry.size.width * CGFloat(storagePercent), height: 8)
            }
            .frame(height: geometry.size.height, alignment: .center)
            .help(HCStartupDisk.shared.getStartupDiskInfo())
        }
    }

    private var storagePercent: Double {
        max(0, min(HCStartupDisk.shared.percentUsed, 1))
    }

    private var driveKind: String {
        HCStartupDisk.shared.isSolidState ? "SSD" : "HDD"
    }

    private var driveConnection: String {
        "\(HCStartupDisk.shared.deviceLocation) \(HCStartupDisk.shared.deviceProtocol)"
    }

    private var capacityText: String {
        let total = HCStartupDisk.shared.totalGB
        guard total > 0 else { return "—" }

        let available = HCStartupDisk.shared.availableGB
        if available > 0 {
            return "\(formatGB(total)) (\(formatGB(available)) available)"
        }

        return formatGB(total)
    }

    private func formatGB(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f GB", value)
        }
        return String(format: "%.1f GB", value)
    }

    private var storageImage: NSImage {
        let imageShortName = "\(HCVersion.shared.osName) \(HCStartupDisk.shared.deviceLocation)"
        let storageType = HCStartupDisk.shared.isSolidState ? "SSD" : "HDD"
        return namedImage("\(imageShortName) \(storageType)", fallback: storageType)
    }
}

private struct StorageInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .frame(width: 74, alignment: .leading)

            Text(value)
                .font(.system(size: 11, weight: .regular))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}
