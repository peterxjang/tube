import InvidiousKit
import SwiftData
import SwiftUI

@main
struct TubeApp: App {
    static var client = APIClient()
    @Bindable var playerState: OpenVideoPlayerAction
    var settings = Settings()
    @State var hasValidInstance: Bool? = nil

    init() {
        playerState = OpenVideoPlayerAction()
    }

    var playerView: some View {
        NavigationStack {
            VideoView(model: VideoViewModel())
                .background(.windowBackground)
        }
    }

    var body: some Scene {
        WindowGroup {
            switch hasValidInstance {
            case .some(true):
                RootView()
                    .fullScreenCover(isPresented: $playerState.isPlayerOpen) {
                        playerState.isPlayerOpen = false
                    } content: {
                        playerView
                    }
            case .some(false):
                OnboardingView(hasValidInstance: $hasValidInstance)
            case .none:
                ProgressView()
                    .task {
                        await validateInstance()
                    }
            }
        }
        .environment(playerState)
        .modelContainer(for: [FollowedChannel.self])
        .environment(settings)
        .onChange(of: settings.invidiousInstance) {
            Task {
                await validateInstance()
            }
        }
    }

    func validateInstance() async {
        guard
            let instanceUrlString = settings.invidiousInstance,
            let instanceUrl = URL(string: instanceUrlString)
        else {
            await MainActor.run {
                TubeApp.client.setApiUrl(url: nil)
                hasValidInstance = false
            }
            return
        }
        let response = await APIClient.isValidInstance(url: instanceUrl)
        await MainActor.run {
            if response {
                TubeApp.client.setApiUrl(url: instanceUrl)
            }
            hasValidInstance = response
        }
    }
}