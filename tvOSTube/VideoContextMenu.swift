import InvidiousKit
import SwiftUI
import SwiftData

struct VideoContextMenu: View {
    var id: String
    var title: String
    var duration: Int
    var publishedText: String
    var published: Int64
    var thumbnails: [ThumbnailObject]
    var author: String
    var authorId: String
    var viewCountText: String
    @Environment(\.modelContext) private var context
    @Query var savedVideos: [SavedVideo]

    var body: some View {
        NavigationLink(destination: ChannelView(model: ChannelViewModel(channelId: authorId))) {
            Label("Go to channel", systemImage: "location.circle")
        }

        let isInWatchLater = savedVideos.contains(where: { $0.id == id })
        if isInWatchLater {
            Button {
                removeFromWatchLater()
            } label: {
                Label("Remove from Watch Later", systemImage: "minus.circle")
            }
        } else {
            Button {
                addToWatchLater()
            } label: {
                Label("Add to Watch Later", systemImage: "plus.circle")
            }
        }
    }

    private func removeFromWatchLater() {
        if let index = savedVideos.firstIndex(where: { $0.id == id }) {
            context.delete(savedVideos[index])
        }
    }

    private func addToWatchLater() {
        let savedVideo = SavedVideo(
            id: id,
            title: title,
            author: author,
            published: published,
            duration: duration,
            quality: thumbnails[0].quality,
            url: thumbnails[0].url,
            width: thumbnails[0].width,
            height: thumbnails[0].height,
            viewCountText: viewCountText
        )
        context.insert(savedVideo)
    }
}
