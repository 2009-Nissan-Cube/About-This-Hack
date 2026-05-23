import AppKit
import SwiftUI

struct StorageView: View {
    let refreshID: UUID

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

                MainFooter()
                    .frame(width: geometry.size.width, alignment: .center)
                    .position(x: geometry.size.width / 2, y: 303)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .onAppear {
            ATHLogger.info(NSLocalizedString("log.storage.init", comment: "Storage view initializing"), category: .ui)
        }
        .id(refreshID)
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
            .help(HardwareCollector.shared.storageData)
        }
    }

    private var storagePercent: Double {
        max(0, min(HardwareCollector.shared.storagePercent, 1))
    }

    private var driveKind: String {
        HardwareCollector.shared.storageType ? "SSD" : "HDD"
    }

    private var driveConnection: String {
        let location = HardwareCollector.shared.deviceLocation.isEmpty ? "Internal" : HardwareCollector.shared.deviceLocation
        let proto = HardwareCollector.shared.deviceProtocol.isEmpty ? "Unknown" : HardwareCollector.shared.deviceProtocol
        return "\(location) \(proto)"
    }

    private var capacityText: String {
        guard let total = storageNumbers.total else { return "—" }

        if let available = storageNumbers.available {
            return "\(formatGB(total)) (\(formatGB(available)) available)"
        }

        return formatGB(total)
    }

    private var usedText: String {
        guard let total = storageNumbers.total,
              let available = storageNumbers.available else {
            return String(format: "%.0f%%", storagePercent * 100)
        }

        let used = max(0, total - available)
        return "\(formatGB(used)) (\(String(format: "%.0f", storagePercent * 100))%)"
    }

    private var storageNumbers: (total: Double?, available: Double?) {
        let data = HardwareCollector.shared.storageData
        let regex = try? NSRegularExpression(pattern: "([0-9]+(?:\\.[0-9]+)?)\\s*GB", options: [])
        let nsRange = NSRange(data.startIndex..<data.endIndex, in: data)
        let matches = regex?.matches(in: data, options: [], range: nsRange) ?? []
        let values = matches.compactMap { match -> Double? in
            guard let range = Range(match.range(at: 1), in: data) else { return nil }
            return Double(data[range])
        }

        return (values.first, values.dropFirst().first)
    }

    private func formatGB(_ value: Double) -> String {
        if value >= 100 {
            return String(format: "%.0f GB", value)
        }
        return String(format: "%.1f GB", value)
    }

    private var storageImage: NSImage {
        let imageShortName = "\(HCVersion.shared.osName) \(HardwareCollector.shared.deviceLocation)"
        let storageType = HardwareCollector.shared.storageType ? "SSD" : "HDD"
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
