import AVKit
import SwiftUI

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
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: self.player.currentItem
            )
        }

        @objc func playerDidFinishPlaying() {
            print("playerDidFinishPlaying")
        }
    }
}
