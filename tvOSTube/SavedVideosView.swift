import SwiftUI
import SwiftData
import InvidiousKit

struct SavedVideosView: View {
    @Environment(\.modelContext) private var context
    @Query private var savedVideos: [SavedVideo]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                if savedVideos.isEmpty {
                    Text("No videos saved to Watch Later.")
                        .foregroundStyle(.secondary)
                        .font(.headline)
                        .padding()
                } else {
                    Text("Watch Later")
                        .font(.largeTitle)
                    ScrollView(.horizontal) {
                        LazyHGrid(rows: [.init(.flexible(minimum: 600))], alignment: .top, spacing: 70.0) {
                            ForEach(savedVideos) { video in
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
            }
            .navigationTitle("Watch Later")
        }
    }
}
