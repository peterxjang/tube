import InvidiousKit
import Observation
import SwiftUI

@Observable
class ChannelVideosViewModel {
    var channelId: String
    var list: VideosList
    var videos: [VideoObject]?
    var continuation: String?
    var done = false
    var loading = true
    var error: Error?

    enum VideosList {
        case videos
        case shorts
        case streams
    }

    init(list: VideosList, channelId: String) {
        self.list = list
        self.channelId = channelId
    }

    func load() async {
        loading = false
        error = nil
        do {
            let response = switch list {
            case .videos:
                try await TubeApp.client.videos(for: channelId, continuation: continuation)
            case .shorts:
                try await TubeApp.client.shorts(for: channelId, continuation: continuation)
            case .streams:
                try await TubeApp.client.streams(for: channelId, continuation: continuation)
            }
            continuation = response.continuation

            guard var videos = videos else {
                self.videos = response.videos
                return
            }
            if let video = videos.first, response.videos.firstIndex(of: video) != nil {
                done = true
            } else if response.videos.isEmpty {
                done = true
            } else {
                videos.append(contentsOf: response.videos)
            }
        } catch {
            print(error)
            self.error = error
        }
        loading = false
    }
}

struct ChannelVideosView: View {
    var model: ChannelVideosViewModel

    var body: some View {
        if let videos = model.videos {
            if videos.isEmpty {
                Text("No Videos")
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 50) {
                    ForEach(videos, id: \.videoId) { video in
                        VideoCard(
                            id: video.videoId,
                            title: video.title,
                            duration: video.lengthSeconds,
                            publishedText: video.publishedText,
                            published: video.published,
                            thumbnails: video.videoThumbnails,
                            author: video.author,
                            authorId: video.authorId,
                            viewCountText: video.viewCountText
                        )
                    }
                }
            }
        }
        if !model.done {
            ProgressView()
                .task(id: model.list) {
                    await model.load()
                }.refreshable {
                    await model.load()
                }
        }
    }
}
