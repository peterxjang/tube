import InvidiousKit
import Observation
import SwiftData
import SwiftUI

struct SearchView: View {
    @State var search: String = ""
    @Query(sort: \FollowedChannel.name) var channels: [FollowedChannel]

    var body: some View {
        VStack {
            SearchResultsView(query: $search)
                .padding(.top, 100)
                .searchable(text: $search)
        }
    }
}
