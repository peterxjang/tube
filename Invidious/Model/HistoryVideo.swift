import Foundation
import SwiftData

@Model
class HistoryVideo {
    @Attribute(.unique) var id: String
    var title: String
    var author: String
    var authorId: String
    var published: Int64
    var lengthSeconds: Int
    var watchedSeconds: Int
    var viewCount: Int
    var thumbnailQuality: String
    var thumbnailUrl: String
    var thumbnailWidth: Int
    var thumbnailHeight: Int

    init(id: String, title: String, author: String, authorId: String, published: Int64, lengthSeconds: Int, watchedSeconds: Int, viewCount: Int, thumbnailQuality: String, thumbnailUrl: String, thumbnailWidth: Int, thumbnailHeight: Int) {
        self.id = id
        self.title = title
        self.author = author
        self.authorId = authorId
        self.published = published
        self.lengthSeconds = lengthSeconds
        self.watchedSeconds = watchedSeconds
        self.viewCount = viewCount
        self.thumbnailQuality = thumbnailQuality
        self.thumbnailUrl = thumbnailUrl
        self.thumbnailWidth = thumbnailWidth
        self.thumbnailHeight = thumbnailHeight
    }
}
