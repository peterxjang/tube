import InvidiousKit
import Observation
import SwiftData
import SwiftUI

struct FeedView: View {
    @State var search: String = ""
    @Query(sort: \FollowedChannel.name) var channels: [FollowedChannel]
    @Query var savedVideos: [SavedVideo]
    @Query var historyVideos: [HistoryVideo]
    @Query var recommendedVideos: [RecommendedVideo]
    @State private var combinedVideos: [VideoObject] = []
    @State private var isLoading: Bool = true
    @State private var loadedChannelsCount: Int = 0
    @State private var hasLoadedOnce: Bool = false // New flag to prevent reloading
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                if channels.isEmpty {
                    MessageBlock(
                        title: "You aren't following any channels.",
                        message: "Search for channels you'd like to follow."
                    ).padding(.horizontal)
                } else {
                    VStack(alignment: .trailing) {
                        if isLoading {
                            ProgressView(value: Double(loadedChannelsCount), total: Double(channels.count))
                                .padding()
                            Text("Loaded \(loadedChannelsCount) out of \(channels.count) channels")
                                .padding()
                        } else if combinedVideos.isEmpty {
                            MessageBlock(title: "No Videos", message: "No videos available from followed channels.")
                                .padding()
                        } else {
                            Button {
                                loadedChannelsCount = 0
                                isLoading = true
                                Task {
                                    await fetchCombinedVideos()
                                }
                            } label: {
                                Label("Refresh", systemImage: "arrow.clockwise")
                            }
                            .padding(.trailing, 20)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 100) {
                                ForEach(combinedVideos, id: \.videoId) { video in
                                    VideoCard(
                                        id: video.videoId,
                                        title: video.title,
                                        duration: video.lengthSeconds,
                                        publishedText: video.publishedText,
                                        published: video.published,
                                        thumbnails: video.videoThumbnails,
                                        author: video.author,
                                        authorId: video.authorId,
                                        viewCountText: video.viewCountText,
                                        savedVideos: savedVideos,
                                        historyVideos: historyVideos,
                                        recommendedVideos: recommendedVideos
                                    )
                                }
                            }
                        }
                    }
                    .onAppear {
                        if !hasLoadedOnce {
                            Task {
                                await fetchCombinedVideos()
                            }
                        }
                    }
                }
            }
            .padding(50)
        }
    }
    
    private func fetchCombinedVideos() async {
        do {
            var allVideos: [VideoObject] = []
            let oneMonthAgo = Date().addingTimeInterval(-30 * 24 * 60 * 60)
            try await withThrowingTaskGroup(of: [VideoObject].self) { group in
                for channel in channels {
                    group.addTask {
                        let result = try await TubeApp.client.videos(for: channel.id, continuation: nil)
                        let recentVideos = result.videos.filter { video in
                            let publishedDate = Date(timeIntervalSince1970: TimeInterval(video.published))
                            return publishedDate >= oneMonthAgo
                        }
                        return recentVideos
                    }
                }
                for try await recentVideos in group {
                    allVideos.append(contentsOf: recentVideos)
                    loadedChannelsCount += 1
                    combinedVideos = allVideos.sorted(by: { $0.published > $1.published })
                }
            }
            isLoading = false
            hasLoadedOnce = true
        } catch {
            print("Error fetching videos: \(error)")
            isLoading = false
        }
    }
}
