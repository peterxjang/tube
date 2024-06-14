import InvidiousKit
import Observation
import SwiftData
import SwiftUI

struct FeedView: View {
    @State var search: String = ""
    @Query(sort: \FollowedChannel.name) var channels: [FollowedChannel]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                if channels.isEmpty {
                    MessageBlock(
                        title: "You aren't following any channels.",
                        message: "Search for channels you'd like to follow."
                    ).padding(.horizontal)
                } else {
                    FollowedChannelsCombinedView(channels: channels)
                    ForEach(channels) { channel in
                        FollowedChannelFeedView(channel: channel)
                    }
                }
            }.padding(.vertical)
        }
        .navigationTitle("Feed")
        .searchable(text: $search)
        .overlay {
            SearchResultsView(query: $search)
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
        }
        .toolbar {
            ToolbarItem {
                NavigationLink(value: NavigationDestination.settings) {
                    Label("Settings", systemImage: "gear")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        FeedView()
            //.modelContainer(previewContainer)
    }
}

@MainActor
let previewContainer: ModelContainer = {
    do {
        TubeApp.client.setApiUrl(url: URL(string: "https://inv.tux.pizza"))
        
        let container = try ModelContainer(
            for: FollowedChannel.self,
            configurations: .init(isStoredInMemoryOnly: true)
        )
        
        let exampleChannels = [
            FollowedChannel(id: "UCBJycsmduvYEL83R_U4JriQ", name: "MKBHD", dateFollowed: Date()),
            FollowedChannel(id: "UC8JOgFXp-I3YV6dsKqqQdUw", name: "Caroline Winkler", dateFollowed: Date())
        ]

        for channel in exampleChannels {
            container.mainContext.insert(channel)
        }

        return container
    } catch {
        fatalError("Failed to create container")
    }
}()
