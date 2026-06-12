import Foundation

final class MainViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published private(set) var isLoaded: Bool = false

    func markLoaded() {
        isLoaded = true
    }
}
