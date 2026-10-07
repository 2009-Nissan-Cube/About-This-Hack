import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    private let tabs: [(title: String, tag: Int)] = [
        (L("segment.title.overview", comment: "Overview tab title"), 0),
        (L("segment.title.displays", comment: "Displays tab title"), 1),
        (L("segment.title.storage", comment: "Storage tab title"), 2),
        (L("segment.title.support", comment: "Support tab title"), 3)
    ]

    var body: some View {
        if #available(macOS 26.0, *) {
            // Hide the toolbar's shared glass platter: the segmented picker
            // already draws its own liquid glass, and nesting both doubles it.
            mainContent.toolbar {
                ToolbarItem(placement: .principal) {
                    tabPicker
                }
                .sharedBackgroundVisibility(.hidden)
            }
        } else {
            mainContent.toolbar {
                ToolbarItem(placement: .principal) {
                    tabPicker
                }
            }
        }
    }

    private var mainContent: some View {
        selectedContent
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color(NSColor.windowBackgroundColor))
    }

    private var tabPicker: some View {
        Picker("", selection: $viewModel.selectedTab) {
            ForEach(tabs, id: \.tag) { tab in
                Text(tab.title).tag(tab.tag)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: 324)
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch viewModel.selectedTab {
        case 1:
            DisplaysView(revision: viewModel.revision)
        case 2:
            StorageView(revision: viewModel.revision)
        case 3:
            SupportView()
        default:
            OverviewView(revision: viewModel.revision, logo: viewModel.logo)
        }
    }
}
