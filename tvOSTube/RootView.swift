import InvidiousKit
import SwiftUI

struct RootView: View {
    @State private var selectedTab: Int = 0
    @State private var resetSubscriptionsView: Bool = false

    var body: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Text("Feed")
                }
                .tag(0)

            SavedVideosView()
                .tabItem {
                    Text("Saved")
                }
                .tag(1)

            SubscriptionsView(resetView: $resetSubscriptionsView)
                .tabItem {
                    Text("Subscriptions")
                }
                .tag(2)

            SearchView()
                .tabItem {
                    Text("Search")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Text("Settings")
                }
                .tag(4)
        }
        .onChange(of: selectedTab) {
            if selectedTab == 2 {
                resetSubscriptionsView.toggle()
            }
        }
    }
}
