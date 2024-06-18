import InvidiousKit
import Observation
import SwiftData
import SwiftUI

struct FeedView: View {
    @State var search: String = ""
    @Query(sort: \FollowedChannel.name) var channels: [FollowedChannel]
    @State private var combinedVideos: [VideoObject] = []
    @State private var isLoading: Bool = true

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
                        if isLoading {
                            ProgressView()
                                .padding()
                        } else if combinedVideos.isEmpty {
                            MessageBlock(title: "No Videos", message: "No videos available from followed channels.")
                                .padding()
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 100) {
                                ForEach(combinedVideos, id: \.videoId) { video in
                                    VideoCard(videoObject: video)
                                }
                            }
                        }
                    }
                    .task {
                        await fetchCombinedVideos()
                    }
                }
            }
            .padding(50)
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
