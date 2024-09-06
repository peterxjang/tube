import SwiftUI
import AVFoundation
import AVKit
import Foundation
import InvidiousKit
import MediaPlayer
import Observation
import Combine

//public struct SponsorBlockObject: Decodable {
//    public var category: String
//    public var actionType: String
//    public var segment: [Float]
//    public var UUID: String
//    public var videoDuration: Float
//    public var locked: Int
//    public var votes: Int
//    public var description: String
//}
//
//struct Chapter {
//    let title: String
//    let imageName: String
//    let startTime: TimeInterval
//    let endTime: TimeInterval
//}
//
//enum VideoPlaybackError: LocalizedError {
//    case missingUrl
//}

@Observable
final class OpenVideoPlayerAction {
    var isPlayerOpen: Bool = false
    var isLoading: Bool = false
    private var player: AVPlayer? = nil
    var currentVideo: Video? = nil
    private var statusObserver: AnyCancellable?
    private var timeObserverToken: Any? = nil
    var watchedSeconds: Double = 0.0
    private var skippableSegments: [[Float]] = []

    var currentPlayer: AVPlayer? {
        return player
    }

    @MainActor
    public func callAsFunction(id: String?, startTime: Int? = nil) async {
        guard let id else { return }
        
        await MainActor.run {
            isLoading = true
        }

        try? await playVideo(withId: id, startTime: startTime)
    }

    public func close() {
        isPlayerOpen = false
        player?.pause()
        player = nil
        statusObserver?.cancel()
        statusObserver = nil
        if let timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
        timeObserverToken = nil
    }

    @MainActor
    private func playVideo(withId id: String, startTime: Int? = nil) async throws {
        let video = try await TubeApp.client.video(for: id)
        let playerItem = try createPlayerItem(for: video)
        player = AVPlayer(playerItem: playerItem)
        player?.allowsExternalPlayback = true
        statusObserver = playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    if let startTime = startTime {
                        self?.player?.seek(to: CMTime(seconds: Double(startTime), preferredTimescale: 1))
                    }
                    self?.player?.play()
                    self?.isLoading = false
                    self?.currentVideo = video
                    self?.startTrackingTime()
                case .failed:
                    self?.isLoading = false
                default:
                    break
                }
            }
        updateNowPlayingInfo(with: video)
        await MainActor.run {
            isPlayerOpen = true
        }
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
                    print("Invalid Response")
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
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
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
}
