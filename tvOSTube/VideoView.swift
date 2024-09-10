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

enum VideoPlaybackError: LocalizedError {
    case missingUrl
}

extension URL {
    func valueOf(_ queryParameterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParameterName })?.value
    }
}

struct VideoView: View {
    var videoId: String
    var historyVideos: [HistoryVideo]
    var recommendedVideos: [RecommendedVideo]
    @State var isLoading: Bool = true
    @State var player: AVPlayer? = nil
    @State var currentVideo: Video? = nil
    @State var statusObserver: AnyCancellable?
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
            if let player = player, let video = currentVideo {
                VideoPlayerView(
                    video: video,
                    player: player,
                    skippableSegments: skippableSegments,
                    historyVideos: historyVideos,
                    recommendedVideos: recommendedVideos
                )
                    .ignoresSafeArea()
                    .onDisappear {
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
    }

    private func getSponsorSegments(id: String) async throws -> [[Float]] {
        let url = URL(string: "https://sponsor.ajay.app/api/skipSegments?videoID=\(id)")!
        let request = URLRequest(url: url)
        let (data, _) = try await URLSession.shared.data(for: request)
        if let videoInfo = try? JSONDecoder().decode([SponsorBlockObject].self, from: data) {
            print(videoInfo)
            return videoInfo.map { $0.segment }
        } else {
            print("SponsorBlock Invalid Response")
            return []
        }
    }

    private func playVideo(withId id: String, startTime: Int? = nil) async throws {
        let video = try await TubeApp.client.video(for: id)
        skippableSegments = try await getSponsorSegments(id: id)
        let playerItem = try createPlayerItem(for: video)
        player = AVPlayer(playerItem: playerItem)
        player?.allowsExternalPlayback = true
        statusObserver = playerItem.publisher(for: \.status)
            .sink { [self] status in
                switch status {
                case .readyToPlay:
                    if let startTime = startTime {
                        let newStartTime = Int(video.lengthSeconds) - startTime > 5 ? Double(startTime) : 0.0
                        self.player?.seek(to: CMTime(seconds: newStartTime, preferredTimescale: 1))
                    }
                    self.player?.play()
                    self.isLoading = false
                    self.currentVideo = video
                case .failed:
                    self.isLoading = false
                default:
                    break
                }
            }
    }

    private func createPlayerItem(for video: Video) throws -> AVPlayerItem {
        let sortedStreams = video.formatStreams.sorted {
            let aQuality = Int($0.quality.trimmingCharacters(in: .letters)) ?? -1
            let bQuality = Int($1.quality.trimmingCharacters(in: .letters)) ?? -1
            return aQuality > bQuality
        }
        print(video.videoId)
        if let hlsUrlStr = video.hlsUrl, let hlsUrl = URL(string: hlsUrlStr) {
            print("hlsUrl")
            return AVPlayerItem(url: hlsUrl)
        } else if
            let videoFormat = video.adaptiveFormats.first(where: { $0.container == "mp4" && (Int($0.resolution?.trimmingCharacters(in: .letters) ?? "") ?? 0) >= 640  }),
            let videoUrl = URL(string: videoFormat.url),
            let audioFormat = video.adaptiveFormats.first(where: { $0.container == "m4a" }),
            let audioUrl = URL(string: audioFormat.url)
        {
            print("adaptive \(videoFormat.resolution ?? "") m4a")
            var duration = Double(video.lengthSeconds)
            if let dur = videoUrl.valueOf("dur") {
                duration = Double(dur) ?? Double(video.lengthSeconds)
            }
            let composition = AVMutableComposition()
            try addAssetToComposition(composition, assetUrl: videoUrl, mediaType: .video, duration: duration)
            try addAssetToComposition(composition, assetUrl: audioUrl, mediaType: .audio, duration: duration)
            return AVPlayerItem(asset: composition)
        } else if let stream = sortedStreams.first, let streamUrl = URL(string: stream.url) {
            print(stream.resolution)
            return AVPlayerItem(url: streamUrl)
        } else {
            throw VideoPlaybackError.missingUrl
        }
    }

    private func addAssetToComposition(_ composition: AVMutableComposition, assetUrl: URL, mediaType: AVMediaType, duration: Double) throws {
        let asset = AVURLAsset(url: assetUrl)
        var assetTrack: AVAssetTrack?
        let group = DispatchGroup()
        group.enter()
        asset.loadTracks(withMediaType: mediaType) { tracks, error in
            assetTrack = tracks?.first
            group.leave()
        }
        group.wait()
        guard let assetTrack = assetTrack else {
            throw VideoPlaybackError.missingUrl
        }
        let compositionTrack = composition.addMutableTrack(
            withMediaType: mediaType,
            preferredTrackID: kCMPersistentTrackID_Invalid
        )
        try compositionTrack?.insertTimeRange(
            CMTimeRange(start: .zero, duration: CMTime(seconds: Double(duration), preferredTimescale: 1)),
            of: assetTrack,
            at: .zero
        )
    }

}
