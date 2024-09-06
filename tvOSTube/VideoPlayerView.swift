import AVKit
import SwiftUI
import InvidiousKit
import MediaPlayer
import Combine

public struct SponsorBlockObject: Decodable {
    public var category: String
    public var actionType: String
    public var segment: [Float]
    public var UUID: String
    public var videoDuration: Float
    public var locked: Int
    public var votes: Int
    public var description: String
}

struct Chapter {
    let title: String
    let imageName: String
    let startTime: TimeInterval
    let endTime: TimeInterval
}

enum VideoPlaybackError: LocalizedError {
    case missingUrl
}

struct VideoPlayerView: UIViewControllerRepresentable {
    var video: Video
    var player: AVPlayer
    @State var skippableSegments: [[Float]] = []
    @Binding var watchedSeconds: Double
    @Binding var timeObserverToken: Any?

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
        updateNowPlayingInfo(with: video)
        var metadata: [AVMetadataItem] = []
        metadata.append(makeMetadataItem(.commonIdentifierTitle, value: video.title))
        metadata.append(makeMetadataItem(.iTunesMetadataTrackSubTitle, value: video.author))
        if let item = videoView.player?.currentItem {
            item.externalMetadata = metadata
            getSponsorSegments(video: video, playerItem: item)
        }
        self.startTrackingTime()
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

    private func updateNowPlayingInfo(with video: Video) {
        let center = MPNowPlayingInfoCenter.default()
        center.nowPlayingInfo = [
            MPMediaItemPropertyTitle: video.title,
            MPMediaItemPropertyArtist: video.author,
        ]
    }

    private func getSponsorSegments(video: Video, playerItem: AVPlayerItem) {
        let url = URL(string: "https://sponsor.ajay.app/api/skipSegments?videoID=\(video.videoId)")!
        let request = URLRequest(url: url)
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                if let videoInfo = try? JSONDecoder().decode([SponsorBlockObject].self, from: data) {
                    print(videoInfo)
                    skippableSegments = videoInfo.map { $0.segment }
                    playerItem.navigationMarkerGroups = makeNavigationMarkerGroups(video: video)
                } else {
                    print("SponsorBlock Invalid Response")
                }
            } catch {
                print("Failed to Send POST Request \(error)")
            }
        }
    }

    private func makeNavigationMarkerGroups(video: Video) -> [AVNavigationMarkersGroup] {
        var chapters: [Chapter] = []
        var previousEndTime: TimeInterval = 0.0
        for (index, segment) in skippableSegments.enumerated() {
            let startTime = TimeInterval(segment[0])
            let endTime = TimeInterval(segment[1])
            if previousEndTime < startTime {
                chapters.append(Chapter(title: "Chapter \(chapters.count + 1)", imageName: "chapter\(chapters.count + 1)", startTime: previousEndTime, endTime: startTime))
            }
            chapters.append(Chapter(title: "Advertisement \(index + 1)", imageName: "ad", startTime: startTime, endTime: endTime))
            previousEndTime = endTime
        }
        if previousEndTime < TimeInterval(video.lengthSeconds) {
            chapters.append(Chapter(title: "Chapter \(chapters.count + 1)", imageName: "chapter\(chapters.count + 1)", startTime: previousEndTime, endTime: TimeInterval(video.lengthSeconds)))
        }
        var metadataGroups = [AVTimedMetadataGroup]()
        chapters.forEach { chapter in
            metadataGroups.append(makeTimedMetadataGroup(for: chapter))
        }
        return [AVNavigationMarkersGroup(title: nil, timedNavigationMarkers: metadataGroups)]
    }

    private func makeTimedMetadataGroup(for chapter: Chapter) -> AVTimedMetadataGroup {
        var metadata = [AVMetadataItem]()
        let titleItem = makeMetadataItem(.commonIdentifierTitle, value: chapter.title)
        metadata.append(titleItem)
        if let image = UIImage(named: chapter.imageName),
           let pngData = image.pngData() {
            let imageItem = makeMetadataItem(.commonIdentifierArtwork, value: pngData)
            metadata.append(imageItem)
        }
        let timescale: Int32 = 600
        let startTime = CMTime(seconds: chapter.startTime, preferredTimescale: timescale)
        let endTime = CMTime(seconds: chapter.endTime, preferredTimescale: timescale)
        let timeRange = CMTimeRangeFromTimeToTime(start: startTime, end: endTime)
        return AVTimedMetadataGroup(items: metadata, timeRange: timeRange)
    }

    private func makeMetadataItem(_ identifier: AVMetadataIdentifier, value: Any) -> AVMetadataItem {
        let item = AVMutableMetadataItem()
        item.identifier = identifier
        item.value = value as? NSCopying & NSObjectProtocol
        item.extendedLanguageTag = "und"
        return item.copy() as! AVMetadataItem
    }

    private func startTrackingTime() {
        if let timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
        }
        let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [self] time in
            let currentTime = CMTimeGetSeconds(time)
            for segment in self.skippableSegments {
                let startTime = segment[0]
                let endTime = segment[1]
                if currentTime >= Double(startTime) && currentTime < Double(endTime) {
                    print("Current \(currentTime), Skipping segment: \(startTime) to \(endTime)")
                    self.player.seek(to: CMTime(seconds: Double(endTime + 1.0), preferredTimescale: 1), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.positiveInfinity)
                    break
                }
            }
            self.watchedSeconds = currentTime
        }
    }
}
