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
        async let videoTask = TubeApp.client.video(for: id)
        async let sponsorSegmentsTask = getSponsorSegments(id: id)
        let (video, segments) = try await (videoTask, sponsorSegmentsTask)
        skippableSegments = segments
        let playerItem = try await createPlayerItem(for: video)
        player = AVPlayer(playerItem: playerItem)
        player?.allowsExternalPlayback = true
        statusObserver = playerItem.publisher(for: \.status)
            .sink { [self] status in
                switch status {
                case .readyToPlay:
                    if let startTime = startTime {
                        let newStartTime = Int(video.lengthSeconds) - startTime > 5 ? Double(startTime) : 0.0
                        self.player?.seek(to: CMTime(seconds: newStartTime, preferredTimescale: 600))
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

    private func createPlayerItem(for video: Video) async throws -> AVPlayerItem {
        let sortedStreams = video.formatStreams.sorted {
            let aQuality = Int($0.quality.trimmingCharacters(in: .letters)) ?? -1
            let bQuality = Int($1.quality.trimmingCharacters(in: .letters)) ?? -1
            return aQuality > bQuality
        }
        print(video.videoId)
        if let hlsUrlStr = video.hlsUrl, let hlsUrl = URL(string: hlsUrlStr) {
            print("hlsUrl")
            return AVPlayerItem(url: hlsUrl)
        } else if let stream = sortedStreams.first, let streamUrl = URL(string: stream.url) {
            print(stream.resolution)
            return AVPlayerItem(url: streamUrl)
        } else {
            throw VideoPlaybackError.missingUrl
        }
    }
}
