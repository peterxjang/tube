import SwiftUI
import AVFoundation
import AVKit
import Foundation
import InvidiousKit
import MediaPlayer
import Observation

enum VideoPlaybackError: LocalizedError {
    case missingUrl
}

@Observable
final class OpenVideoPlayerAction {
    var isPlayerOpen: Bool = false
    private var player: AVPlayer? = nil
    private var currentVideo: Video? = nil

    // Expose player through a computed property
    var currentPlayer: AVPlayer? {
        return player
    }

    @MainActor
    public func callAsFunction(id: String?) async {
        guard let id else { return }
        try? await playVideo(withId: id)
    }

    public func close() {
        isPlayerOpen = false
        player?.pause()
        player = nil
    }

    @MainActor
    private func playVideo(withId id: String) async throws {
        let video = try await TubeApp.client.video(for: id)
        let playerItem = try createPlayerItem(for: video)

        player = AVPlayer(playerItem: playerItem)
        player?.allowsExternalPlayback = true
        player?.play()

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

        #if !os(macOS)
        var metadata: [AVMetadataItem] = []
        let titleMetadata = AVMutableMetadataItem()
        titleMetadata.identifier = .commonIdentifierTitle
        titleMetadata.value = video.title as any NSCopying & NSObjectProtocol
        metadata.append(titleMetadata)

        let subtitleMetadata = AVMutableMetadataItem()
        subtitleMetadata.identifier = .iTunesMetadataTrackSubTitle
        subtitleMetadata.value = video.author as any NSCopying & NSObjectProtocol
        metadata.append(subtitleMetadata)

        item.externalMetadata = metadata
        #endif

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