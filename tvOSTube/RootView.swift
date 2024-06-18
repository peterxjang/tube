//
//  RootView.swift
//  tvOSTube
//
//  Created by Peter Jang on 6/16/24.
//

import InvidiousKit
import SwiftUI

enum NavigationDestination: Hashable {
    case channel(String)
    case playlist(String)
    case settings
}

struct RootView: View {
    var body: some View {
        TabView {
            FeedView()
                .tabItem {
                    Text("Recent Videos")
                }
            SubscriptionsView()
                .tabItem {
                    Text("Subscriptions")
                }
            SearchView()
                .tabItem {
                    Text("Search")
                }
            SettingsView()
                .tabItem {
                    Text("Settings")
                }
        }
    }
}

//#Preview {
//    RootView()
//}
