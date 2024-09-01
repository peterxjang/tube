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

        let clickpadLongPress = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(context.coordinator.handleClickpadLongPress))
        clickpadLongPress.minimumPressDuration = 1.0 // 1 second long press
        clickpadLongPress.allowedPressTypes = [NSNumber(value: UIPress.PressType.select.rawValue)]
        
        videoView.view.addGestureRecognizer(clickpadLongPress)
        
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

        @objc func handleClickpadLongPress(gesture: UILongPressGestureRecognizer) {
            if gesture.state == .began {
                if player.rate == 1.0 {
                    player.rate = 2.0
                } else {
                    player.rate = 1.0
                }
            }
        }
    }
}
