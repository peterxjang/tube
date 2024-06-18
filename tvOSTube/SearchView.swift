//
//  SearchView.swift
//  tvOSTube
//
//  Created by Peter Jang on 6/17/24.
//

import InvidiousKit
import Observation
import SwiftData
import SwiftUI

struct SearchView: View {
    @State var search: String = ""
    @Query(sort: \FollowedChannel.name) var channels: [FollowedChannel]

    var body: some View {
        VStack {
            TextField("Search...", text: $search)
                .padding()
            SearchResultsView(query: $search)
            Spacer()
        }
        .padding()
    }
}

//#Preview {
//    SearchView()
//}
