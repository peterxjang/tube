import SwiftUI
import SwiftData
import InvidiousKit

struct SavedVideosView: View {
    @Environment(\.modelContext) private var context
    @Query private var savedVideos: [SavedVideo]
    @Query private var historyVideos: [HistoryVideo]
    @Query var recommendedVideos: [RecommendedVideo]
    var settings = Settings()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Watch Later")
                    .font(.subheadline)
                ScrollView(.horizontal) {
                    LazyHGrid(rows: [.init(.flexible())], alignment: .top, spacing: 70.0) {
                        ForEach(savedVideos.reversed()) { video in
                            VideoCard(
                                id: video.id,
                                title: video.title,
                                duration: video.duration,
                                published: video.published,
                                thumbnails: [
                                    ThumbnailObject(
                                        quality: video.thumbnailQuality,
                                        url: "\(settings.invidiousInstance ?? "")/vi/\(video.id)/sddefault.jpg",
                                        width: video.thumbnailWidth,
                                        height: video.thumbnailHeight
                                    )
                                ],
                                author: video.author,
                                authorId: video.authorId,
                                viewCountText: video.viewCountText,
                                savedVideos: savedVideos,
                                historyVideos: historyVideos
                            )
                        }
                    }.padding(20)
                }

                Text("Recommended")
                    .font(.subheadline)
                    .padding(.top, 50)
                ScrollView(.horizontal) {
                    LazyHGrid(rows: [.init(.flexible())], alignment: .top, spacing: 70.0) {
                        ForEach(recommendedVideos.shuffled()) { video in
                            VideoCard(
                                id: video.id,
                                title: video.title,
                                duration: video.lengthSeconds,
                                published: 0,
                                thumbnails: [
                                    ThumbnailObject(
                                        quality: video.thumbnailQuality,
                                        url: "\(settings.invidiousInstance ?? "")/vi/\(video.id)/sddefault.jpg",
                                        width: video.thumbnailWidth,
                                        height: video.thumbnailHeight
                                    )
                                ],
                                author: video.author,
                                authorId: "UNAVAILABLE",
                                viewCountText: video.viewCountText,
                                savedVideos: savedVideos,
                                historyVideos: historyVideos
                            )
                        }
                    }.padding(20)
                }

                Text("Recent History")
                    .font(.subheadline)
                    .padding(.top, 50)
                ScrollView(.horizontal) {
                    LazyHGrid(rows: [.init(.flexible())], alignment: .top, spacing: 70.0) {
                        ForEach(historyVideos.reversed()) { video in
                            VideoCard(
                                id: video.id,
                                title: video.title,
                                duration: video.lengthSeconds,
                                published: video.published,
                                thumbnails: [
                                    ThumbnailObject(
                                        quality: video.thumbnailQuality,
                                        url: "\(settings.invidiousInstance ?? "")/vi/\(video.id)/sddefault.jpg",
                                        width: video.thumbnailWidth,
                                        height: video.thumbnailHeight
                                    )
                                ],
                                author: video.author,
                                authorId: video.authorId,
                                viewCountText: String(video.viewCount),
                                savedVideos: savedVideos,
                                historyVideos: historyVideos
                            )
                        }
                    }.padding(20)
                }
            }
            .navigationTitle("Watch Later")
            .padding(50)
        }
    }
}
