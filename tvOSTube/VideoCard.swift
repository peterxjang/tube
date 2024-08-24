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
    var viewCountText: String
    @Environment(OpenVideoPlayerAction.self) var openPlayer

    private var formattedDuration: String {
        (Date() ..< Date().advanced(by: TimeInterval(duration))).formatted(.timeDuration)
    }

    init(videoObject: VideoObject) {
        id = videoObject.videoId
        title = videoObject.title
        duration = videoObject.lengthSeconds
        published = videoObject.published
        publishedText = videoObject.publishedText
        thumbnails = videoObject.videoThumbnails
        author = videoObject.author
        viewCountText = videoObject.viewCountText
    }

    init(id: String, title: String, duration: Int, publishedText: String = "", published: Int64 = 0, thumbnails: [ThumbnailObject], author: String, viewCountText: String = "") {
        self.id = id
        self.title = title
        self.duration = duration
        self.publishedText = publishedText
        self.published = published
        self.thumbnails = thumbnails
        self.author = author
        self.viewCountText = viewCountText
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
