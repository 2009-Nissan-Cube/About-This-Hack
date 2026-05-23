import Foundation

final class MainViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published private(set) var isLoaded: Bool = false
    @Published private(set) var refreshID = UUID()

    func markLoaded() {
        isLoaded = true
        refreshID = UUID()
    }
}
