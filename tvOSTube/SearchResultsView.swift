import InvidiousKit
import SwiftUI
import SwiftData

@Observable
class SearchResultsViewModel {
    var results: [Search.Result] = []
    var done: Bool = false
    var page: Int32 = 0
    var task: Task<Void, Never>?
    var isSearching: Bool = false

    func handleUpdate(query: String, appending: Bool = false) {
        task?.cancel()
        isSearching = true // Set to true when the search begins
        task = Task {
            do {
                let response = try await TubeApp.client.search(query: query, page: page)
                await MainActor.run {
                    done = response.count == 0
                    if appending {
                        results.append(contentsOf: response)
                    } else {
                        results = response
                    }
                    isSearching = false
                }
            } catch {
                print(error)
                isSearching = false
            }
            task = nil
        }
    }

    func nextPage(query: String) {
        page += 1
        handleUpdate(query: query, appending: true)
    }
}

struct SearchResultsView: View {
    @Binding var query: String
    var model = SearchResultsViewModel()
    @Query var savedVideos: [SavedVideo]
    @Query var historyVideos: [HistoryVideo]

    var body: some View {
        VStack {
            if model.isSearching {
                ProgressView("Searching...")
                    .padding(.top, 200)
            }

            if !query.isEmpty {
                ScrollView(.horizontal) {
                    LazyHGrid(rows: [.init(.flexible(minimum: 600, maximum: 600))], alignment: .top, spacing: 100.0) {
                        ForEach(model.results) { result in
                            switch result {
                            case .video(let video):
                                VideoCard(
                                    id: video.videoId,
                                    title: video.title,
                                    duration: video.lengthSeconds,
                                    publishedText: video.publishedText,
                                    published: video.published,
                                    thumbnails: video.videoThumbnails,
                                    author: video.author,
                                    authorId: video.authorId,
                                    viewCountText: video.viewCountText,
                                    savedVideos: savedVideos,
                                    historyVideos: historyVideos
                                )
                            case .channel(let channel):
                                ChannelCard(channel: channel)
                            case .playlist(let playlist):
                                PlaylistItemView(
                                    id: playlist.playlistId,
                                    title: playlist.title,
                                    thumbnail: playlist.playlistThumbnail,
                                    author: playlist.author,
                                    videoCount: playlist.videoCount
                                )
                            }
                        }
                    }.padding(50)
                }
                .onChange(of: query) { _, _ in
                    model.handleUpdate(query: query)
                }
            }
        }
    }
}
