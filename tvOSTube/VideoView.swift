import AVKit
import InvidiousKit
import Observation
import SwiftUI

struct VideoView: View {
    @Environment(OpenVideoPlayerAction.self) private var playerState

    var body: some View {
        if let player = playerState.currentPlayer {
            VideoPlayerView(player: player)
                .ignoresSafeArea()
                .onDisappear {
                    playerState.close()
                }
        } else {
            Text("No video to play")
                .ignoresSafeArea()
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
        let forwardImage = UIImage(systemName: "forward")
        let forwardFillImage = UIImage(systemName: "forward.fill")
        let rateAction = UIAction(title: "Playback speed", image: forwardImage) { action in
            if player.rate == 1.0 {
                player.rate = 1.5
                action.image = forwardFillImage
            } else {
                player.rate = 1.0
                action.image = forwardImage
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
