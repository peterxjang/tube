import SwiftUI
import InvidiousKit

struct VideoCard: View {
    var id: String
    var title: String
    var duration: Int
    var publishedText: String
    var published: Int64
    var thumbnails: [ThumbnailObject]
    var author: String
    var authorId: String
    var viewCountText: String
    @Environment(OpenVideoPlayerAction.self) var openPlayer
    @EnvironmentObject var navigationManager: NavigationManager

    private var formattedDuration: String {
        let result = (Date() ..< Date().advanced(by: TimeInterval(duration))).formatted(.timeDuration)
        return result == "0" ? "" : result
    }

    init(videoObject: VideoObject) {
        id = videoObject.videoId
        title = videoObject.title
        duration = videoObject.lengthSeconds
        published = videoObject.published
        publishedText = videoObject.publishedText
        thumbnails = videoObject.videoThumbnails
        author = videoObject.author
        authorId = videoObject.authorId
        viewCountText = videoObject.viewCountText
    }

    init(id: String, title: String, duration: Int, publishedText: String = "", published: Int64 = 0, thumbnails: [ThumbnailObject], author: String, authorId: String, viewCountText: String = "") {
        self.id = id
        self.title = title
        self.duration = duration
        self.publishedText = publishedText
        self.published = published
        self.thumbnails = thumbnails
        self.author = author
        self.viewCountText = viewCountText
        self.authorId = authorId
    }

    var body: some View {
        let width = 500.0
        let height = width / 1.8

        VStack(alignment: .leading) {
            Button(action: action) {
                ZStack {
                    ThumbnailView(width: width, height: height, radius: 8.0, thumbnails: thumbnails)
                    VideoThumbnailTag(self.formattedDuration)
                }
                .frame(width: width, height: height)
            }
            .buttonStyle(.card)
            .frame(width: width)
            .contextMenu {
                Button {
                    navigationManager.navigateToChannel(with: authorId)
                } label: {
                    Label("Go to channel", systemImage: "location.circle")
                }

                Button {
                    print("add to watch later")
                } label: {
                    Label("Add to Watch Later", systemImage: "globe")
                }
            }

            Text(title).lineLimit(2, reservesSpace: true).font(.headline)
            Text(author).lineLimit(1).foregroundStyle(.secondary).font(.caption)
            if !publishedText.isEmpty && !viewCountText.isEmpty {
                Text("\(publishedText)  |  \(viewCountText)").lineLimit(1).foregroundStyle(.secondary).font(.caption)
            }
        }.frame(width: width)
    }

    @MainActor
    func action() {
        Task {
            await openPlayer(id: id)
        }
    }
}
