import InvidiousKit
import SwiftData
import SwiftUI

struct SubscriptionsView: View {
    @Query(sort: \FollowedChannel.name) var channels: [FollowedChannel]
    @Binding var resetView: Bool
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                if channels.isEmpty {
                    MessageBlock(
                        title: "You aren't following any channels.",
                        message: "Search for channels you'd like to follow."
                    ).padding(.horizontal)
                } else {
                    VStack(alignment: .leading) {
                        ForEach(channels) { channel in
                            Button(action: {
                                navigationManager.navigateToChannel(with: channel.id)
                            }) {
                                HStack {
                                    Text(channel.name)
                                        .padding()
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .padding(.trailing)
                                }
                            }
                        }
                    }
                }
            }
            .padding(50)
        }
        .id(resetView) // Reset the view by changing the id whenever resetView changes
    }
}
