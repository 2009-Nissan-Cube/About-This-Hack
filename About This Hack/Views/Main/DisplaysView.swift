import AppKit
import SwiftUI

struct DisplaysView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Text(L("segment.title.displays", comment: "Displays tab title"))
                    .font(.system(size: 25, weight: .bold))
                    .frame(width: geometry.size.width, alignment: .center)
                    .position(x: geometry.size.width / 2, y: 48)

                if displayItems.isEmpty {
                    Text(L("displays.none", comment: "No displays message"))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                        .frame(width: geometry.size.width, alignment: .center)
                        .position(x: geometry.size.width / 2, y: 150)
                } else {
                    HStack(alignment: .top, spacing: 22) {
                        ForEach(displayItems) { item in
                            DisplayCard(item: item)
                        }
                    }
                    .frame(width: geometry.size.width, alignment: .center)
                    .position(x: geometry.size.width / 2, y: 155)
                }

                Button(L("displays.button.preferences", comment: "Display Preferences button"), action: openDisplayPreferences)
                    .controlSize(.small)
                    .position(x: geometry.size.width / 2, y: 278)

            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .onAppear {
            ATHLogger.info(NSLocalizedString("log.display_view.init", comment: "Display view initializing"), category: .ui)
        }
    }

    private var displayItems: [DisplayItem] {
        let names = HCDisplay.shared.getDisplayNames()
        let resolutions = HCDisplay.shared.getDisplayResolutions()

        return names.prefix(3).enumerated().map { index, rawName in
            let name = trimDisplayName(rawName)
            let resolution = index < resolutions.count
                ? removeParentheses(resolutions[index])
                : L("displays.resolution", comment: "Fallback resolution label")

            return DisplayItem(index: index,
                               name: name,
                               resolution: resolution,
                               imageName: imageName(for: name))
        }
    }

    private func openDisplayPreferences() {
        _ = openFirstAvailableURL(
            urlStrings: [
                "x-apple.systempreferences:com.apple.Displays-Settings.extension",
                "x-apple.systempreferences:com.apple.preference.displays"
            ],
            fallbackFilePaths: [InitGlobVar.displayPrefPane]
        )
    }

    private func trimDisplayName(_ name: String) -> String {
        let withoutParentheses = removeParentheses(name)

        if let range = withoutParentheses.range(of: "display", options: .caseInsensitive) {
            let trimmed = String(withoutParentheses[..<range.upperBound])
            return trimmed.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return withoutParentheses.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func removeParentheses(_ text: String) -> String {
        text.replacingOccurrences(of: "\\([^)]+\\)", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func imageName(for displayName: String) -> String {
        let name = displayName.lowercased()

        if name.contains("imac") { return "NSComputer" }
        if name.contains("lg") && (name.contains("hdr") || name.contains("4k")) { return "LG4K" }
        if name.contains("sidecar") { return "ipad" }
        if name.contains("led") && name.contains("cinema") { return "appledisp" }
        if name.contains("built") { return "macbook" }
        return "genericLCD"
    }
}

private struct DisplayItem: Identifiable {
    let index: Int
    let name: String
    let resolution: String
    let imageName: String

    var id: Int { index }
}

private struct DisplayCard: View {
    let item: DisplayItem

    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: namedImage(item.imageName, fallback: "genericLCD"))
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 118, height: 96)

            Text(item.name)
                .font(.system(size: 13, weight: .semibold))
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .frame(width: 145)

            Text(item.resolution)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 145)
        }
    }
}
