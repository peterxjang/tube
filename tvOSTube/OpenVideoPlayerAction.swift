import SwiftUI
import AVFoundation
import AVKit
import Foundation
import InvidiousKit
import MediaPlayer
import Observation
import Combine

enum VideoPlaybackError: LocalizedError {
    case missingUrl
}

@Observable
final class OpenVideoPlayerAction {
    var isPlayerOpen: Bool = false
    var isLoading: Bool = false
    private var player: AVPlayer? = nil
    var currentVideo: Video? = nil
    private var statusObserver: AnyCancellable?

    var currentPlayer: AVPlayer? {
        return player
    }

    @MainActor
    public func callAsFunction(id: String?) async {
        guard let id else { return }
        
        await MainActor.run {
            isLoading = true
        }

        try? await playVideo(withId: id)
    }

    public func close() {
        isPlayerOpen = false
        player?.pause()
        player = nil
        statusObserver?.cancel()
        statusObserver = nil
    }

    @MainActor
    private func playVideo(withId id: String) async throws {
        let video = try await TubeApp.client.video(for: id)
        let playerItem = try createPlayerItem(for: video)

        player = AVPlayer(playerItem: playerItem)
        player?.allowsExternalPlayback = true

        // Use Combine to observe the status of the AVPlayerItem
        statusObserver = playerItem.publisher(for: \.status)
            .sink { [weak self] status in
                switch status {
                case .readyToPlay:
                    self?.player?.play()
                    self?.isLoading = false // Hide the loading screen
                    self?.currentVideo = video
                case .failed:
                    // Handle error
                    self?.isLoading = false // Hide the loading screen
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
        let titleMetadata = AVMutableMetadataItem()
        titleMetadata.identifier = .commonIdentifierTitle
        titleMetadata.value = video.title as any NSCopying & NSObjectProtocol
        titleMetadata.extendedLanguageTag = "und"
        metadata.append(titleMetadata)

        let subtitleMetadata = AVMutableMetadataItem()
        subtitleMetadata.identifier = .iTunesMetadataTrackSubTitle
        subtitleMetadata.value = video.author as any NSCopying & NSObjectProtocol
        subtitleMetadata.extendedLanguageTag = "und"
        metadata.append(subtitleMetadata)

        item.externalMetadata = metadata
        return item
    }

    private func updateNowPlayingInfo(with video: Video) {
        let center = MPNowPlayingInfoCenter.default()
        center.nowPlayingInfo = [
            MPMediaItemPropertyTitle: video.title,
            MPMediaItemPropertyArtist: video.author,
        ]
    }
}
