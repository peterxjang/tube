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
    @Query var historyVideos: [HistoryVideo]

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

        let isInHistory = historyVideos.contains(where: { $0.id == id })
        if isInHistory {
            Button {
                removeFromHistory()
            } label: {
                Label("Remove from history", systemImage: "minus.circle")
            }
        }
    }

    private func removeFromWatchLater() {
        if let index = savedVideos.firstIndex(where: { $0.id == id }) {
            context.delete(savedVideos[index])
        }
    }

    private func removeFromHistory() {
        if let index = historyVideos.firstIndex(where: { $0.id == id }) {
            context.delete(historyVideos[index])
        }
    }

    private func addToWatchLater() {
        let savedVideo = SavedVideo(
            id: id,
            title: title,
            author: author,
            authorId: authorId,
            published: published,
            duration: duration,
            viewCountText: viewCountText,
            thumbnailQuality: thumbnails[0].quality,
            thumbnailUrl: thumbnails[0].url,
            thumbnailWidth: thumbnails[0].width,
            thumbnailHeight: thumbnails[0].height
        )
        context.insert(savedVideo)
    }
}
