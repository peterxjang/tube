import AVKit
import InvidiousKit
import Observation
import SwiftUI

@Observable
class VideoViewModel: Identifiable {
    var showingInfo: Bool = false
    var infoSelectedTab: SelectedTab = .info

    enum SelectedTab {
        case info
        case comments
        case recommended
    }
}

struct VideoView: View {
    @Bindable var model: VideoViewModel
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

        let playPauseTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePlayPauseTap))
        playPauseTap.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        
        let playPauseDoubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handlePlayPauseDoubleTap))
        playPauseDoubleTap.allowedPressTypes = [NSNumber(value: UIPress.PressType.playPause.rawValue)]
        playPauseDoubleTap.numberOfTapsRequired = 2
        
        playPauseTap.require(toFail: playPauseDoubleTap)
        
        videoView.view.addGestureRecognizer(playPauseTap)
        videoView.view.addGestureRecognizer(playPauseDoubleTap)
        
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

        @objc func handlePlayPauseTap() {
            if player.rate == 0.0 {
                player.play()
            } else {
                player.pause()
            }
        }

        @objc func handlePlayPauseDoubleTap() {
            if player.rate == 1.0 {
                player.rate = 2.0
            } else {
                player.rate = 1.0
            }
        }
    }
}
