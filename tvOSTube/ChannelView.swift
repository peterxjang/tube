import InvidiousKit
import Observation
import SwiftUI

@Observable
class ChannelViewModel {
    var channelId: String
    var loading = true
    var error: Error?
    var channel: Channel?
    var videos: [VideoObject] = []
    var selectedTab: ChannelTab = .videos(.videos)
    
    init(channelId: String) {
        self.channelId = channelId
    }
    
    enum ChannelTab: Hashable {
        case videos(ChannelVideosViewModel.VideosList)
        case playlists
        
        var displayName: String {
            switch self {
            case .videos(.videos):
                "Videos"
            case .videos(.shorts):
                "Shorts"
            case .videos(.streams):
                "Streams"
            case .playlists:
                "Playlists"
            }
        }
    }
    
    func load() async {
        if loading {
            loading = true
            error = nil
            do {
                channel = try await TubeApp.client.channel(for: channelId)
            } catch {
                print(error)
                self.error = error
            }
            loading = false
        }
    }
}

struct ChannelView: View {
    @Bindable var model: ChannelViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            if let channel = model.channel {
                ChannelHeaderView(channel: channel, selection: $model.selectedTab)
                    .padding(.bottom, 50)
                switch model.selectedTab {
                case .videos(let list):
                    ChannelVideosView(model: ChannelVideosViewModel(list: list, channelId: model.channelId))
                        .padding()
                case .playlists:
                    ChannelPlaylistsView(model: ChannelPlaylistsViewModel(channelId: model.channelId))
                        .padding(50)
                }
            }
        }
        .asyncTaskOverlay(error: model.error, isLoading: model.loading)
        .onAppear {
            Task {
                await model.load()
            }
        }
        .refreshable {
            await model.load()
        }
    }
}
