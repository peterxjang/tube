import SwiftUI

struct PlaylistItemView: View {
    var id: String
    var title: String
    var thumbnail: String?
    var author: String
    var videoCount: Int
    
    var body: some View {
        NavigationLink(destination: PlaylistView(model: PlaylistViewModel(playlistId: id))) {
            VStack(alignment: .leading) {
                ZStack {
                    Group {
                        if let thumbnail, let url = URL(string: thumbnail) {
                            AsyncImage(url: url) { image in
                                image.resizable().scaledToFit()
                            } placeholder: {
                                ProgressView()
                            }
                        }
                    }
                    .frame(maxWidth: 500, maxHeight: 280)
                    .aspectRatio(16 / 9, contentMode: .fill)
                    .background(Rectangle().foregroundStyle(.background))
                    .cornerRadius(8.0)
                    .clipped()
                    VideoThumbnailTag("\(videoCount.formatted()) videos")
                }
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(title).lineLimit(1).font(.callout)
                    Text(author).lineLimit(1).foregroundStyle(.secondary).font(.callout)
                }
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}
