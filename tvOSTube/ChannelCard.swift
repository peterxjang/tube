//
//  ChannelCard.swift
//  tvOSTube
//
//  Created by Peter Jang on 6/17/24.
//

import SwiftUI
import InvidiousKit

struct ChannelCard: View {
    var channel: Channel
    
    var body: some View {
        VStack {
            ImageView(width: 200, height: 200, images: channel.authorThumbnails)
            Text(channel.author)
            Text("\(channel.subCount.formatted()) subscribers").font(.callout)
                .foregroundStyle(.secondary)
            FollowButton(channelId: channel.authorId, channelName: channel.author)
        }
    }
}

//#Preview {
//    ChannelCard()
//}
