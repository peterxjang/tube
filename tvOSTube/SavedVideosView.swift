import SwiftUI
import SwiftData
import InvidiousKit

struct SavedVideosView: View {
    @Environment(\.modelContext) private var context
    @Query private var savedVideos: [SavedVideo]
    @Query private var historyVideos: [HistoryVideo]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Watch Later")
                    .font(.largeTitle)
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
                                        url: video.thumbnailUrl,
                                        width: video.thumbnailWidth,
                                        height: video.thumbnailHeight
                                    )
                                ],
                                author: video.author,
                                authorId: video.authorId,
                                viewCountText: video.viewCountText
                            )
                        }
                    }.padding(20)
                }

                Text("Recommended")
                    .font(.largeTitle)
                ScrollView(.horizontal) {
                    LazyHGrid(rows: [.init(.flexible())], alignment: .top, spacing: 70.0) {
//                        ForEach(savedVideos.reversed()) { video in
//                            VideoCard(
//                                id: video.id,
//                                title: video.title,
//                                duration: video.duration,
//                                published: video.published,
//                                thumbnails: [
//                                    ThumbnailObject(
//                                        quality: video.thumbnailQuality,
//                                        url: video.thumbnailUrl,
//                                        width: video.thumbnailWidth,
//                                        height: video.thumbnailHeight
//                                    )
//                                ],
//                                author: video.author,
//                                authorId: "UNAVAILABLE",
//                                viewCountText: video.viewCountText
//                            )
//                        }
                    }.padding(20)
                }

                Text("Recent History")
                    .font(.largeTitle)
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
                                        url: video.thumbnailUrl,
                                        width: video.thumbnailWidth,
                                        height: video.thumbnailHeight
                                    )
                                ],
                                author: video.author,
                                authorId: video.authorId,
                                viewCountText: String(video.viewCount)
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
