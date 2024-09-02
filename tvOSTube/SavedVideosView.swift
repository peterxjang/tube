import SwiftUI
import SwiftData
import InvidiousKit

struct SavedVideosView: View {
    @Environment(\.modelContext) private var context
    @Query private var savedVideos: [SavedVideo]

    var body: some View {
        let bookmarkedVideos = savedVideos.filter { video in
            return video.videoType == "bookmark"
        }.reversed()
        let recommendedVideos = savedVideos.filter { video in
            return video.videoType == "recommendation"
        }.reversed()
        let historyVideos = savedVideos.filter { video in
            return video.videoType == "history"
        }.reversed()

        ScrollView {
            VStack(alignment: .leading) {
                Text("Watch Later")
                    .font(.largeTitle)
                ScrollView(.horizontal) {
                    LazyHGrid(rows: [.init(.flexible())], alignment: .top, spacing: 70.0) {
                        ForEach(bookmarkedVideos) { video in
                            VideoCard(
                                id: video.id,
                                title: video.title,
                                duration: video.duration,
                                published: video.published,
                                thumbnails: [ThumbnailObject(quality: video.quality, url: video.url, width: video.width, height: video.height)],
                                author: video.author,
                                authorId: "UNAVAILABLE",
                                viewCountText: video.viewCountText
                            )
                        }
                    }.padding(20)
                }

                Text("Recommended")
                    .font(.largeTitle)
                ScrollView(.horizontal) {
                    LazyHGrid(rows: [.init(.flexible())], alignment: .top, spacing: 70.0) {
                        ForEach(recommendedVideos) { video in
                            VideoCard(
                                id: video.id,
                                title: video.title,
                                duration: video.duration,
                                published: video.published,
                                thumbnails: [ThumbnailObject(quality: video.quality, url: video.url, width: video.width, height: video.height)],
                                author: video.author,
                                authorId: "UNAVAILABLE",
                                viewCountText: video.viewCountText
                            )
                        }
                    }.padding(20)
                }

                Text("Recent History")
                    .font(.largeTitle)
                ScrollView(.horizontal) {
                    LazyHGrid(rows: [.init(.flexible())], alignment: .top, spacing: 70.0) {
                        ForEach(historyVideos) { video in
                            VideoCard(
                                id: video.id,
                                title: video.title,
                                duration: video.duration,
                                published: video.published,
                                thumbnails: [ThumbnailObject(quality: video.quality, url: video.url, width: video.width, height: video.height)],
                                author: video.author,
                                authorId: "UNAVAILABLE",
                                viewCountText: video.viewCountText
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
