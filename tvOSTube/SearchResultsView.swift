//
//  SearchResultsView.swift
//  tvOSTube
//
//  Created by Peter Jang on 6/17/24.
//

import InvidiousKit
import SwiftUI

@Observable
class SearchResultsViewModel {
    var results: [Search.Result] = []
    var done: Bool = false
    var page: Int32 = 0
    var task: Task<Void, Never>?

    func handleUpdate(query: String, appending: Bool = false) {
        task?.cancel()
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
                }
            } catch {
                print(error)
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
    
    var body: some View {
        if !query.isEmpty {
            ScrollView(.horizontal) {
                LazyHGrid(rows: [.init(.flexible(minimum: 600, maximum: 600))], alignment: .top, spacing: 100.0) {
                    ForEach(model.results) { result in
                        switch result {
                        case .video(let video):
                            VideoCard(videoObject: video)
                        case .channel(let channel):
                             ChannelCard(channel: channel)
                        case .playlist(let playlist):
                            PlaylistItemView(id: playlist.playlistId, title: playlist.title, author: playlist.author, videoCount: playlist.videoCount)
                        }
                    }
                }.padding(.horizontal)
            }
            .onChange(of: query) { _, _ in
                model.handleUpdate(query: query)
            }
        }
    }
}

// #Preview {
//    SearchResultsView()
// }
