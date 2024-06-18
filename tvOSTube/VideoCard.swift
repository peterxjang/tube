//
//  VideoCard.swift
//  tvOSTube
//
//  Created by Peter Jang on 6/17/24.
//

import SwiftUI
import InvidiousKit

struct VideoCard: View {
    var id: String
    var title: String
    var duration: Int
    var published: String
    var thumbnails: [ThumbnailObject]
    @Environment(OpenVideoPlayerAction.self) var openPlayer

    private var formattedDuration: String {
        (Date() ..< Date().advanced(by: TimeInterval(duration))).formatted(.timeDuration)
    }

    init(videoObject: VideoObject) {
        id = videoObject.videoId
        title = videoObject.title
        duration = videoObject.lengthSeconds
        published = videoObject.publishedText
        thumbnails = videoObject.videoThumbnails
    }

    var body: some View {
        let width = 500.0
        let height = width / 1.5
        
        Button(action: action) {
            VStack(alignment: .leading) {
                ZStack {
                    ThumbnailView(width: width, height: height, radius: 8.0, thumbnails: thumbnails)
                    VideoThumbnailTag(self.formattedDuration)
                }.frame(width: width, height: height)
                Text(title).lineLimit(1).font(.callout)
                Text(published).lineLimit(1).foregroundStyle(.secondary).font(.callout)
            }
        }
        .buttonStyle(.plain)
        .frame(width: width)
    }

    @MainActor
    func action() {
        Task {
            await openPlayer(id: id)
        }
    }
}
