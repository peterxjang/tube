import SwiftUI
import AVFoundation
import AVKit
import Foundation
import InvidiousKit
import MediaPlayer
import Observation
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

struct VideoView: View {
    var videoId: String
    var historyVideos: [HistoryVideo]
    var recommendedVideos: [RecommendedVideo]
    @Environment(\.modelContext) private var context
    @State var isLoading: Bool = true
    @State var player: AVPlayer? = nil
    @State var currentVideo: Video? = nil
    @State var statusObserver: AnyCancellable?
    @State var timeObserverToken: Any? = nil
    @State var watchedSeconds: Double = 0.0
    @State var skippableSegments: [[Float]] = []

    var body: some View {
        if isLoading {
            LoadingView()
                .onAppear {
                    Task {
                        let startTime = historyVideos.first(where: { $0.id == videoId })?.watchedSeconds
                        try? await playVideo(withId: videoId, startTime: startTime)
                    }
                }
                .onDisappear {
                    if isLoading {
                        close()
                    }
                }
        } else {
            if let player = player {
                VideoPlayerView(player: player)
                    .ignoresSafeArea()
                    .onDisappear {
                        if let video = currentVideo {
                            saveVideoToHistory(video: video, watchedSeconds: Int(watchedSeconds))
                            saveRecommendedVideos(video: video)
                        }
                        close()
                    }
            } else {
                Text("error")
            }
        }
    }

    public func close() {
        player?.pause()
        player = nil
        statusObserver?.cancel()
        statusObserver = nil
        if let timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
        timeObserverToken = nil
    }

    private func playVideo(withId id: String, startTime: Int? = nil) async throws {
        let video = try await TubeApp.client.video(for: id)
        let playerItem = try createPlayerItem(for: video)
        player = AVPlayer(playerItem: playerItem)
        player?.allowsExternalPlayback = true
        statusObserver = playerItem.publisher(for: \.status)
            .sink { [self] status in
                switch status {
                case .readyToPlay:
                    if let startTime = startTime {
                        self.player?.seek(to: CMTime(seconds: Double(startTime), preferredTimescale: 1))
                    }
                    self.player?.play()
                    self.isLoading = false
                    self.currentVideo = video
                    self.startTrackingTime()
                case .failed:
                    self.isLoading = false
                default:
                    break
                }
            }
        updateNowPlayingInfo(with: video)
    }

    private func createPlayerItem(for video: Video) throws -> AVPlayerItem {
        let sortedStreams = video.formatStreams.sorted {
            let aQuality = Int($0.quality.trimmingCharacters(in: .letters)) ?? -1
            let bQuality = Int($1.quality.trimmingCharacters(in: .letters)) ?? -1
            return aQuality > bQuality
        }

        let item: AVPlayerItem = if let hlsUrlStr = video.hlsUrl, let hlsUrl = URL(string: hlsUrlStr) {
            AVPlayerItem(url: hlsUrl)
        } else if let stream = sortedStreams.first, let streamUrl = URL(string: stream.url) {
            AVPlayerItem(url: streamUrl)
        } else {
            throw VideoPlaybackError.missingUrl
        }

        var metadata: [AVMetadataItem] = []
        metadata.append(makeMetadataItem(.commonIdentifierTitle, value: video.title))
        metadata.append(makeMetadataItem(.iTunesMetadataTrackSubTitle, value: video.author))
        item.externalMetadata = metadata

        getSponsorSegments(video: video, playerItem: item)

        return item
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

    private func updateNowPlayingInfo(with video: Video) {
        let center = MPNowPlayingInfoCenter.default()
        center.nowPlayingInfo = [
            MPMediaItemPropertyTitle: video.title,
            MPMediaItemPropertyArtist: video.author,
        ]
    }

    private func startTrackingTime() {
        guard let player = player else { return }
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
                    self.player?.seek(to: CMTime(seconds: Double(endTime + 1.0), preferredTimescale: 1), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.positiveInfinity)
                    break
                }
            }
            self.watchedSeconds = currentTime
        }
    }

    private func saveVideoToHistory(video: Video, watchedSeconds: Int) {
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
