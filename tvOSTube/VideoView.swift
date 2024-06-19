//
//  VideoView.swift
//  tvOSTube
//
//  Created by Peter Jang on 6/18/24.
//

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
    @State var player: AVPlayer?
    @State var showingQueue: Bool = false
    @Environment(VideoQueue.self) private var queue
    @Environment(OpenVideoPlayerAction.self) private var playerState

    var body: some View {
        VideoPlayerView(player: queue.playerQueue).ignoresSafeArea()
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    var player: AVPlayer

    typealias NSViewControllerType = AVPlayerViewController

    func makeUIViewController(context _: Context) -> UIViewController {
        let videoView = AVPlayerViewController()
        videoView.player = player
        videoView.player?.play()
        videoView.allowsPictureInPicturePlayback = false
        return videoView
    }

    func updateUIViewController(_: UIViewController, context _: Context) {}
}
