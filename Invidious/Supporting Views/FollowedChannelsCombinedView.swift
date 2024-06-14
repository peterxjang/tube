//
//  FollowedChannelsCombinedView.swift
//  Tube
//
//  Created by Peter Jang on 6/14/24.
//

import InvidiousKit
import SwiftUI

struct FollowedChannelsCombinedView: View {
    var channels: [FollowedChannel]
    @State private var combinedVideos: [VideoObject] = []
    @State private var isLoading: Bool = true

    var body: some View {
        VStack(alignment: .leading) {
            Text("Recent Videos from All Channels")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.horizontal)

            if isLoading {
                ProgressView()
                    .padding()
            } else if combinedVideos.isEmpty {
                MessageBlock(title: "No Videos", message: "No videos available from followed channels.")
                    .padding()
            } else {
                ScrollView(.horizontal) {
                    LazyHGrid(rows: [.init(.flexible(minimum: 200, maximum: 300))], alignment: .top, spacing: 16.0) {
                        ForEach(combinedVideos, id: \.videoId) { video in
                            HorizontalSwiperVideoCard(videoObject: video)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .task {
            await fetchCombinedVideos()
        }
    }

    private func fetchCombinedVideos() async {
        do {
            var allVideos: [VideoObject] = []
            
            // Calculate the date one month ago from today
            let oneMonthAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60) // Roughly 30 days ago

            for channel in channels {
                let result = try await TubeApp.client.videos(for: channel.id, continuation: nil)
                // Filter videos to include only those published within the last month
                let recentVideos = result.videos.filter { video in
                    // Convert Unix timestamp to Date
                    let publishedDate = Date(timeIntervalSince1970: TimeInterval(video.published))
                    return publishedDate >= oneMonthAgo
                }
                allVideos.append(contentsOf: recentVideos)
            }
            
            // Sort the filtered videos by their published date
            combinedVideos = allVideos.sorted(by: { $0.published > $1.published })
            isLoading = false
        } catch {
            print("Error fetching videos: \(error)")
            isLoading = false
        }
    }
}
