import SwiftUI
import InvidiousKit

struct VideoCard: View {
    var id: String
    var title: String
    var duration: Int
    var publishedText: String?
    var published: Int64
    var thumbnails: [ThumbnailObject]
    var author: String
    var authorId: String
    var viewCountText: String?
    var savedVideos: [SavedVideo]
    var historyVideos: [HistoryVideo]
    @Environment(OpenVideoPlayerAction.self) var openPlayer

    private var formattedDuration: String {
        let result = (Date() ..< Date().advanced(by: TimeInterval(duration))).formatted(.timeDuration)
        return result == "0" ? "" : result
    }

    var body: some View {
        let width = 500.0
        let height = width / 1.8

        VStack(alignment: .leading) {
            Button(action: action) {
                ZStack(alignment: .bottomLeading) {
                    ThumbnailView(width: width, height: height, radius: 8.0, thumbnails: thumbnails)
                    VideoThumbnailTag(self.formattedDuration)
                    if let historyVideo = historyVideos.first(where: { $0.id == id }) {
                        let progress = CGFloat(historyVideo.watchedSeconds) / CGFloat(duration)
                        Rectangle()
                            .fill(Color(UIColor.lightGray))
                            .frame(width: width, height: 5)
                        Rectangle()
                            .fill(Color.red)
                            .frame(width: width * progress, height: 5)
                    }
                }
                .frame(width: width, height: height)
            }
            .buttonStyle(.card)
            .frame(width: width)
            .contextMenu {
                VideoContextMenu(
                    id: id,
                    title: title,
                    duration: duration,
                    publishedText: publishedText,
                    published: published,
                    thumbnails: thumbnails,
                    author: author,
                    authorId: authorId,
                    viewCountText: viewCountText,
                    savedVideos: savedVideos,
                    historyVideos: historyVideos
                )
            }

            Text(title).lineLimit(2, reservesSpace: true).font(.headline)
            Text(author).lineLimit(1).foregroundStyle(.secondary).font(.caption)
            if let publishedTextValue = publishedText, let viewCountTextValue = viewCountText {
                Text("\(publishedTextValue)  |  \(viewCountTextValue)").lineLimit(1).foregroundStyle(.secondary).font(.caption)
            }
        }.frame(width: width)
    }

    @MainActor
    func action() {
        Task {
            let startTime = historyVideos.first(where: { $0.id == id })?.watchedSeconds
            await openPlayer(id: id, startTime: startTime)
        }
    }
}
