//
//  SubscriptionsView.swift
//  tvOSTube
//
//  Created by Peter Jang on 6/17/24.
//

import InvidiousKit
import Observation
import SwiftData
import SwiftUI

struct SubscriptionsView: View {
    @Query(sort: \FollowedChannel.name) var channels: [FollowedChannel]
    @State private var selectedChannel: FollowedChannel? = nil

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
                                selectedChannel = channel
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
            }.padding(.vertical)
        }
        .navigationTitle("Feed")
        .sheet(item: $selectedChannel) { channel in
            ChannelView(model: ChannelViewModel(channelId: channel.id))
        }
    }
}
