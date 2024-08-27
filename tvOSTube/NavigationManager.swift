import SwiftUI

struct IdentifiableString: Identifiable {
    let id: String

    init(id: String) {
        self.id = id
    }
}

class NavigationManager: ObservableObject {
    @Published var selectedChannelId: IdentifiableString? = nil

    func navigateToChannel(with channelId: String) {
        selectedChannelId = IdentifiableString(id: channelId)
    }

    func dismissChannel() {
        selectedChannelId = nil
    }
}
