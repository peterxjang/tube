import Foundation
import SwiftData

@Model
class RecommendedVideo {
    @Attribute(.unique) var id: String
    var title: String
    var author: String
    var authorId: String
    var lengthSeconds: Int
    var viewCount: Int
    var viewCountText: String
    var thumbnailQuality: String
    var thumbnailUrl: String
    var thumbnailWidth: Int
    var thumbnailHeight: Int

    init(id: String, title: String, author: String, authorId: String, lengthSeconds: Int, viewCount: Int, viewCountText: String, thumbnailQuality: String, thumbnailUrl: String, thumbnailWidth: Int, thumbnailHeight: Int) {
        self.id = id
        self.title = title
        self.author = author
        self.authorId = authorId
        self.lengthSeconds = lengthSeconds
        self.viewCount = viewCount
        self.viewCountText = viewCountText
        self.thumbnailQuality = thumbnailQuality
        self.thumbnailUrl = thumbnailUrl
        self.thumbnailWidth = thumbnailWidth
        self.thumbnailHeight = thumbnailHeight
    }
}
