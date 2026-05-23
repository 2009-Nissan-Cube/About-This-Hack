import AppKit
import SwiftUI

func L(_ key: String, comment: String = "") -> String {
    NSLocalizedString(key, comment: comment)
}

func trimmedTooltip(_ tooltip: String?) -> String? {
    tooltip?.components(separatedBy: .newlines)
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        .joined(separator: "\n")
}

func namedImage(_ imageName: String, fallback: String? = nil) -> NSImage {
    if let image = NSImage(named: imageName) {
        return image
    }

    if let fallback, let image = NSImage(named: fallback) {
        return image
    }

    return NSImage(size: NSSize(width: 1, height: 1))
}

struct InfoRow: View {
    let title: String
    let value: String
    var tooltip: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 92, alignment: .trailing)

            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 12))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .help(trimmedTooltip(tooltip) ?? "")
    }
}

struct SectionTitle: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
    }
}

struct MainFooter: View {
    var body: some View {
        Text(L("main.footer", comment: "Main window footer"))
            .font(.system(size: 10))
            .foregroundColor(Color(NSColor.disabledControlTextColor))
            .lineLimit(1)
    }
}
