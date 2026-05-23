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
        ZStack(alignment: .topLeading) {
            Color(NSColor.windowBackgroundColor)

            if viewModel.isLoaded {
                selectedContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text(L("loading.data.message", comment: "Loading data message"))
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .principal) {
                Picker("", selection: $viewModel.selectedTab) {
                    ForEach(tabs, id: \.tag) { tab in
                        Text(tab.title).tag(tab.tag)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .labelsHidden()
                .controlSize(.regular)
                .frame(width: 324)
            }
        }
    }

    @ViewBuilder
    private var selectedContent: some View {
        switch viewModel.selectedTab {
        case 1:
            DisplaysView(refreshID: viewModel.refreshID)
        case 2:
            StorageView(refreshID: viewModel.refreshID)
        case 3:
            SupportView()
        default:
            OverviewView(refreshID: viewModel.refreshID)
        }
    }
}
