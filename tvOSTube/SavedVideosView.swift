import SwiftUI
import SwiftData
import InvidiousKit

struct SavedVideosView: View {
    @Environment(\.modelContext) private var context
    @Query private var savedVideos: [SavedVideo]

    var body: some View {
        VStack {
            if savedVideos.isEmpty {
                Text("No videos saved to Watch Later.")
                    .foregroundStyle(.secondary)
                    .font(.headline)
                    .padding()
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 50) {
                    ForEach(savedVideos, id: \.id) { video in
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
                        .padding(30)
                    }
                }
                .padding(50)
            }
        }
        .navigationTitle("Watch Later")
    }
}
