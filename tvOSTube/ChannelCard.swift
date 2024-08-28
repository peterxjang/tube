import SwiftUI
import InvidiousKit

struct ChannelCard: View {
    var channel: ChannelObject
    @State private var showChannelView = false

    var body: some View {
        NavigationLink(destination: ChannelView(model: ChannelViewModel(channelId: channel.authorId))) {
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
