import SwiftUI
import AVFoundation
import AVKit
import Foundation
import InvidiousKit
import MediaPlayer
import Observation
import Combine

struct VideoView: View {
    var videoId: String
    var historyVideos: [HistoryVideo]
    var recommendedVideos: [RecommendedVideo]
    @Environment(\.modelContext) private var context
    @State var isLoading: Bool = true
    @State var player: AVPlayer? = nil
    @State var currentVideo: Video? = nil
    @State var statusObserver: AnyCancellable?
    @State var timeObserverToken: Any? = nil
    @State var watchedSeconds: Double = 0.0

    var body: some View {
        if isLoading {
            LoadingView()
                .onAppear {
                    Task {
                        let startTime = historyVideos.first(where: { $0.id == videoId })?.watchedSeconds
                        try? await playVideo(withId: videoId, startTime: startTime)
                    }
                }
                .onDisappear {
                    if isLoading {
                        close()
                    }
                }
        } else {
            if let player = player, let video = currentVideo {
                VideoPlayerView(video: video, player: player, watchedSeconds: $watchedSeconds, timeObserverToken: $timeObserverToken)
                    .ignoresSafeArea()
                    .onDisappear {
                        saveVideoToHistory(video: video, watchedSeconds: Int(watchedSeconds))
                        saveRecommendedVideos(video: video)
                        close()
                    }
            } else {
                Text("error")
            }
        }
    }

    public func close() {
        player?.pause()
        player = nil
        statusObserver?.cancel()
        statusObserver = nil
        if let timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
        timeObserverToken = nil
    }

    private func playVideo(withId id: String, startTime: Int? = nil) async throws {
        let video = try await TubeApp.client.video(for: id)
        let playerItem = try createPlayerItem(for: video)
        player = AVPlayer(playerItem: playerItem)
        player?.allowsExternalPlayback = true
        statusObserver = playerItem.publisher(for: \.status)
            .sink { [self] status in
                switch status {
                case .readyToPlay:
                    if let startTime = startTime {
                        self.player?.seek(to: CMTime(seconds: Double(startTime), preferredTimescale: 1))
                    }
                    self.player?.play()
                    self.isLoading = false
                    self.currentVideo = video
                case .failed:
                    self.isLoading = false
                default:
                    break
                }
            }
    }

    private func createPlayerItem(for video: Video) throws -> AVPlayerItem {
        let sortedStreams = video.formatStreams.sorted {
            let aQuality = Int($0.quality.trimmingCharacters(in: .letters)) ?? -1
            let bQuality = Int($1.quality.trimmingCharacters(in: .letters)) ?? -1
            return aQuality > bQuality
        }

        let item: AVPlayerItem = if let hlsUrlStr = video.hlsUrl, let hlsUrl = URL(string: hlsUrlStr) {
            AVPlayerItem(url: hlsUrl)
        } else if let stream = sortedStreams.first, let streamUrl = URL(string: stream.url) {
            AVPlayerItem(url: streamUrl)
        } else {
            throw VideoPlaybackError.missingUrl
        }

        return item
    }

    private func saveVideoToHistory(video: Video, watchedSeconds: Int) {
        if let foundVideo = historyVideos.first(where: { $0.id == video.videoId }) {
            context.delete(foundVideo)
        }
        let historyVideo = HistoryVideo(
            id: video.videoId,
            title: video.title,
            author: video.author,
            authorId: video.authorId,
            published: video.published,
            lengthSeconds: Int(video.lengthSeconds),
            watchedSeconds: watchedSeconds,
            viewCount: Int(video.viewCount),
            thumbnailQuality: video.videoThumbnails.first?.quality ?? "",
            thumbnailUrl: video.videoThumbnails.first?.url ?? "N/A",
            thumbnailWidth: video.videoThumbnails.first?.width ?? 0,
            thumbnailHeight: video.videoThumbnails.first?.height ?? 0
        )
        context.insert(historyVideo)
        let maxHistorySize = 100
        let numRemove = historyVideos.count - maxHistorySize
        if numRemove > 0 {
            let videosToRemove = historyVideos.prefix(numRemove)
            for video in videosToRemove {
                context.delete(video)
            }
        }
        do {
            try context.save()
        } catch {
            print("Failed to save video to history: \(error)")
        }
    }

    private func saveRecommendedVideos(video: Video) {
        for recommendedVideo in video.recommendedVideos.prefix(3) {
            if recommendedVideos.first(where: { $0.id == recommendedVideo.videoId }) == nil {
                let item = RecommendedVideo(
                    id: recommendedVideo.videoId,
                    title: recommendedVideo.title,
                    author: recommendedVideo.author,
                    authorId: recommendedVideo.authorId,
                    lengthSeconds: Int(recommendedVideo.lengthSeconds),
                    viewCount: Int(recommendedVideo.viewCount),
                    viewCountText: recommendedVideo.viewCountText,
                    thumbnailQuality: recommendedVideo.videoThumbnails.first?.quality ?? "",
                    thumbnailUrl: recommendedVideo.videoThumbnails.first?.url ?? "N/A",
                    thumbnailWidth: recommendedVideo.videoThumbnails.first?.width ?? 0,
                    thumbnailHeight: recommendedVideo.videoThumbnails.first?.height ?? 0
                )
                context.insert(item)
                do {
                    try context.save()
                } catch {
                    print("Failed to save video to history: \(error)")
                }
            }
        }

        let maxSize = 100
        let numRemove = recommendedVideos.count - maxSize
        if numRemove > 0 {
            let videosToRemove = recommendedVideos.prefix(numRemove)
            for video in videosToRemove {
                context.delete(video)
            }
        }
    }
}
