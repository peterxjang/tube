import Foundation
import SwiftData

@Model
class SavedVideo {
    @Attribute(.unique) var id: String
    var title: String
    var author: String
    var authorId: String
    var published: Int64
    var duration: Int
    var thumbnailQuality: String
    var thumbnailUrl: String
    var thumbnailWidth: Int
    var thumbnailHeight: Int
    var viewCountText: String

    init(id: String, title: String, author: String, authorId: String, published: Int64, duration: Int, viewCountText: String, thumbnailQuality: String, thumbnailUrl: String, thumbnailWidth: Int, thumbnailHeight: Int) {
        self.id = id
        self.title = title
        self.author = author
        self.authorId = authorId
        self.published = published
        self.duration = duration
        self.viewCountText = viewCountText
        self.thumbnailQuality = thumbnailQuality
        self.thumbnailUrl = thumbnailUrl
        self.thumbnailWidth = thumbnailWidth
        self.thumbnailHeight = thumbnailHeight
    }
}
