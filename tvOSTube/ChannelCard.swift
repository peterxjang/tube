import SwiftUI
import InvidiousKit

struct ChannelCard: View {
    var channel: ChannelObject
    @State private var showChannelView = false
    @EnvironmentObject var navigationManager: NavigationManager

    var body: some View {
        Button(action: {
            navigationManager.navigateToChannel(with: channel.authorId)
        }) {
            VStack {
                ImageView(width: 200, height: 200, images: channel.authorThumbnails)
                Text(channel.author)
                Text("\(channel.subCount.formatted()) subscribers")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            .frame(maxHeight: 400)
        }
    }
}
