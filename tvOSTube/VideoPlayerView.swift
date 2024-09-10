import AVKit
import SwiftUI
import InvidiousKit
import MediaPlayer
import Combine

struct Chapter {
    let title: String
    let imageName: String
    let startTime: TimeInterval
    let endTime: TimeInterval
}

struct VideoPlayerView: UIViewControllerRepresentable {
    var video: Video
    var player: AVPlayer
    var skippableSegments: [[Float]]
    var historyVideos: [HistoryVideo]
    var recommendedVideos: [RecommendedVideo]
    @Environment(\.modelContext) private var databaseContext
    @Environment(\.presentationMode) var presentationMode

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
            item.navigationMarkerGroups = makeNavigationMarkerGroups(video: video)
        }
        context.coordinator.startTrackingTime(playerViewController: videoView, skippableSegments: skippableSegments)
        return videoView
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self, player: player, video: video)
    }

    class Coordinator: NSObject {
        var parent: VideoPlayerView
        var player: AVPlayer
        var video: Video
        private var timeObserverToken: Any?
        private var watchedSeconds: Double = 0.0

        init(_ parent: VideoPlayerView, player: AVPlayer, video: Video) {
            self.parent = parent
            self.player = player
            self.video = video
            super.init()
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(playerDidFinishPlaying),
                name: .AVPlayerItemDidPlayToEndTime,
                object: self.player.currentItem
            )
        }

        func startTrackingTime(playerViewController: AVPlayerViewController, skippableSegments: [[Float]]) {
            if let timeObserverToken {
                player.removeTimeObserver(timeObserverToken)
            }
            let interval = CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
                let currentTime = CMTimeGetSeconds(time)
                for segment in skippableSegments {
                    let startTime = segment[0]
                    let endTime = segment[1]
                    if currentTime >= Double(startTime) && currentTime < Double(endTime) {
                        if playerViewController.contextualActions.isEmpty {
                            let skipAction = UIAction(title: "Skip", image: UIImage(systemName: "forward.fill")) { _ in
                                self?.player.seek(to: CMTime(seconds: Double(endTime + 1.0), preferredTimescale: 600), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.positiveInfinity)
                            }
                            playerViewController.contextualActions = [skipAction]
                        }
                        return
                    }
                }
                if !playerViewController.contextualActions.isEmpty {
                    playerViewController.contextualActions = []
                }
                self?.watchedSeconds = currentTime
            }
        }

        @objc func playerDidFinishPlaying() {
            parent.presentationMode.wrappedValue.dismiss()
        }

        deinit {
            if let timeObserverToken {
                player.removeTimeObserver(timeObserverToken)
            }
            timeObserverToken = nil
            parent.saveVideoToHistory(video: video, watchedSeconds: Int(watchedSeconds))
            parent.saveRecommendedVideos(video: video)
        }
        
    }

    private func updateNowPlayingInfo(with video: Video) {
        let center = MPNowPlayingInfoCenter.default()
        center.nowPlayingInfo = [
            MPMediaItemPropertyTitle: video.title,
            MPMediaItemPropertyArtist: video.author,
        ]
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

    private func saveVideoToHistory(video: Video, watchedSeconds: Int) {
        let context = databaseContext
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
        let context = databaseContext
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
