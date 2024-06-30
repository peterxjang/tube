//
//  ChannelCard.swift
//  tvOSTube
//
//  Created by Peter Jang on 6/17/24.
//

import SwiftUI
import InvidiousKit

struct ChannelCard: View {
    var channel: ChannelObject
    @State private var showChannelView = false

    var body: some View {
        Button(action: {
            showChannelView = true
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
        .sheet(isPresented: $showChannelView) {
            ChannelView(model: ChannelViewModel(channelId: channel.authorId))
        }
    }
}
