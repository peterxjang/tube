import InvidiousKit
import SwiftUI

enum NavigationDestination: Hashable {
    case channel(String)
    case playlist(String)
    case settings
}

struct RootView: View {
    @State private var selectedTab: Int = 0
    @State private var resetSubscriptionsView: Bool = false
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Text("Recent Videos")
                }
                .tag(0)
            SubscriptionsView(resetView: $resetSubscriptionsView)
                .tabItem {
                    Text("Subscriptions")
                }
                .tag(1)
            SearchView()
                .tabItem {
                    Text("Search")
                }
                .tag(2)
            SettingsView()
                .tabItem {
                    Text("Settings")
                }
                .tag(3)
        }
        .onChange(of: selectedTab) {
            if selectedTab == 1 {
                resetSubscriptionsView.toggle()
            }
        }
        .sheet(item: $navigationManager.selectedChannelId) { identifiableChannelId in
            ChannelView(model: ChannelViewModel(channelId: identifiableChannelId.id))
        }
    }
}
