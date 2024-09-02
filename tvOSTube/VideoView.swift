import AVKit
import InvidiousKit
import Observation
import SwiftUI
import SwiftData

struct VideoView: View {
    @Environment(OpenVideoPlayerAction.self) private var playerState
    @Environment(\.modelContext) private var context
    @Query var historyVideos: [HistoryVideo]

    var body: some View {
        if let player = playerState.currentPlayer {
            VideoPlayerView(player: player)
                .ignoresSafeArea()
                .onDisappear {
                    if let video = playerState.currentVideo {
                        saveVideoToHistory(video: video)
                    }
                    playerState.close()
                }
        } else {
            Text("No video to play")
                .ignoresSafeArea()
        }
    }

    private func saveVideoToHistory(video: Video) {
        let isVideoInHistory = historyVideos.first(where: { $0.id == video.videoId }) != nil
        if !isVideoInHistory {
            let maxHistorySize = 10
            let numRemove = historyVideos.count - maxHistorySize + 1
            if numRemove > 0 {
                let videosToRemove = historyVideos.prefix(numRemove)
                for video in videosToRemove {
                    context.delete(video)
                }
            }
            let historyVideo = HistoryVideo(
                id: video.videoId,
                title: video.title,
                author: video.author,
                authorId: video.authorId,
                published: video.published,
                lengthSeconds: Int(video.lengthSeconds),
                watchedSeconds: 0,
                viewCount: Int(video.viewCount),
                thumbnailQuality: video.videoThumbnails.first?.quality ?? "",
                thumbnailUrl: video.videoThumbnails.first?.url ?? "N/A",
                thumbnailWidth: video.videoThumbnails.first?.width ?? 0,
                thumbnailHeight: video.videoThumbnails.first?.height ?? 0
            )
            context.insert(historyVideo)
            do {
                try context.save()
            } catch {
                print("Failed to save video to history: \(error)")
            }
        }
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    var player: AVPlayer

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
        Coordinator(self, player: player)
    }

    class Coordinator: NSObject {
        var parent: VideoPlayerView
        var player: AVPlayer

        init(_ parent: VideoPlayerView, player: AVPlayer) {
            self.parent = parent
            self.player = player
        }
    }
}
