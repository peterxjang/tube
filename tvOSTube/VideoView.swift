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

struct VideoPlayerView: UIViewControllerRepresentable {
    var player: AVPlayer
    @Environment(OpenVideoPlayerAction.self) private var playerState

    typealias NSViewControllerType = AVPlayerViewController

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let videoView = AVPlayerViewController()
        videoView.player = player
        videoView.player?.play()
        videoView.allowsPictureInPicturePlayback = false
        videoView.player?.rate = 1.0
        let defaultSpeedImage = UIImage(systemName: "forward.circle")
        let fasterSpeedImage = UIImage(systemName: "forward.circle.fill")
        let fastestSpeedImage = UIImage(systemName: "forward.fill")
        let rateAction = UIAction(title: "Playback speed", image: defaultSpeedImage) { action in
            if player.rate == 1.0 {
                player.rate = 1.5
                action.image = fasterSpeedImage
            } else if player.rate == 1.5 {
                player.rate = 2.0
                action.image = fastestSpeedImage
            } else {
                player.rate = 1.0
                action.image = defaultSpeedImage
            }
        }
        videoView.transportBarCustomMenuItems = [rateAction]
        return videoView
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self, player: player, playerState: playerState)
    }

    class Coordinator: NSObject {
        var parent: VideoPlayerView
        var player: AVPlayer
        var playerState: OpenVideoPlayerAction

        init(_ parent: VideoPlayerView, player: AVPlayer, playerState: OpenVideoPlayerAction) {
            self.parent = parent
            self.player = player
            self.playerState = playerState
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: self.player.currentItem
            )
        }

        @objc func playerDidFinishPlaying() {
            playerState.close()
        }
    }
}
