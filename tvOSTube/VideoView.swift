import AVKit
import InvidiousKit
import Observation
import SwiftUI
import SwiftData

struct VideoView: View {
    @Environment(OpenVideoPlayerAction.self) private var playerState
    @Environment(\.modelContext) private var context
    @Query var historyVideos: [HistoryVideo]
    @Query var recommendedVideos: [RecommendedVideo]

    var body: some View {
        if let player = playerState.currentPlayer {
            VideoPlayerView(player: player)
                .ignoresSafeArea()
                .onDisappear {
                    if let video = playerState.currentVideo {
                        saveVideoToHistory(video: video)
                        saveRecommendedVideos(video: video)
                    }
                    playerState.close()
                }
        } else {
            Text("No video to play")
                .ignoresSafeArea()
        }
    }

    private func saveVideoToHistory(video: Video) {
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
            watchedSeconds: Int(playerState.watchedSeconds),
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
