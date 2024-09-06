import InvidiousKit
import SwiftData
import SwiftUI

@main
struct TubeApp: App {
    static var client = APIClient()
    var settings = Settings()
    @State var hasValidInstance: Bool? = nil

    var body: some Scene {
        WindowGroup {
            ZStack {
                switch hasValidInstance {
                case .some(true):
                    NavigationStack {
                        RootView()
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
        }
        .modelContainer(
            for: [
                FollowedChannel.self,
                SavedVideo.self,
                HistoryVideo.self,
                RecommendedVideo.self
            ]
        )
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
