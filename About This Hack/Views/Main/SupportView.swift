import AppKit
import SwiftUI

struct SupportView: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                Text(L("segment.title.support", comment: "Support tab title"))
                    .font(.system(size: 25, weight: .bold))
                    .frame(width: geometry.size.width, alignment: .center)
                    .position(x: geometry.size.width / 2, y: 48)

                HStack(alignment: .top, spacing: 56) {
                    supportColumn(
                        title: L("support.section.macos", comment: "macOS Help section"),
                        buttons: [
                            (L("support.macos_user_guide", comment: "macOS User Guide"), InitGlobVar.macOSUserGuideURL, "log.browser.opened.macos_user_guide"),
                            (L("support.whats_new", comment: "What's New in macOS"), InitGlobVar.whatsNewInMacOSURL, "log.browser.opened.whats_new"),
                            (L("support.mac_basics", comment: "Mac Basics"), InitGlobVar.MacBasicsURL, "log.browser.opened.mac_basics")
                        ]
                    )

                    supportColumn(
                        title: L("support.section.hardware", comment: "Hardware Help section"),
                        buttons: [
                            (L("support.apple_support", comment: "Apple Support"), InitGlobVar.AppleSupportURL, "log.browser.opened.apple_support"),
                            (L("support.hackintosh_guide", comment: "Hackintosh guide"), InitGlobVar.HackintoshInstallURL, "log.browser.opened.hackintosh"),
                            (L("support.mac_user_guide", comment: "Mac User Guide"), InitGlobVar.MacUserGuideURL, "log.browser.opened.mac_user_guide")
                        ]
                    )
                }
                .frame(width: geometry.size.width, alignment: .center)
                .position(x: geometry.size.width / 2, y: 142)

                Text(L("support.credit", comment: "Support page credit"))
                    .font(.system(size: 10))
                    .foregroundColor(Color(NSColor.disabledControlTextColor))
                    .lineLimit(1)
                    .frame(width: geometry.size.width, alignment: .center)
                    .position(x: geometry.size.width / 2, y: 293)
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .onAppear {
            ATHLogger.info(NSLocalizedString("log.support_view.init", comment: "Support View initializing"), category: .ui)
        }
    }

    private func supportColumn(title: String, buttons: [(String, String, String)]) -> some View {
        VStack(spacing: 8) {
            SectionTitle(title: title)
                .frame(width: 190, alignment: .center)

            ForEach(Array(buttons.enumerated()), id: \.offset) { _, button in
                SupportPillButton(title: button.0, urlString: button.1, logKey: button.2)
            }
        }
        .frame(width: 190, alignment: .center)
    }
}

private struct SupportPillButton: View {
    let title: String
    let urlString: String
    let logKey: String

    var body: some View {
        Button(action: open) {
            HStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 10, weight: .semibold))
            }
            .padding(.horizontal, 9)
            .frame(minWidth: 0, maxWidth: 168, minHeight: 18, maxHeight: 18)
            .foregroundColor(.primary)
            .background(
                Capsule()
                    .fill(Color(NSColor.controlColor).opacity(0.68))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    private func open() {
        guard let url = URL(string: urlString) else { return }

        if NSWorkspace.shared.open(url) {
            ATHLogger.info(NSLocalizedString(logKey, comment: ""), category: .ui)
        } else {
            ATHLogger.error(String(format: NSLocalizedString("log.browser.failed", comment: "Failed to open URL"), url.absoluteString), category: .ui)
        }
    }
}
