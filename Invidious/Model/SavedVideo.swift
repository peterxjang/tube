import Foundation
import SwiftData

@Model
class SavedVideo {
    @Attribute(.unique) var id: String
    var videoType: String
    var title: String
    var author: String
    var published: Int64
    var duration: Int
    var quality: String
    var url: String
    var width: Int
    var height: Int
    var viewCountText: String
    var addedDate: Date

    init(id: String, videoType: String, title: String, author: String, published: Int64, duration: Int, quality: String,url: String,width: Int,height: Int, viewCountText: String, addedDate: Date = Date()) {
        self.id = id
        self.videoType = videoType
        self.title = title
        self.author = author
        self.published = published
        self.duration = duration
        self.quality = quality
        self.url = url
        self.width = width
        self.height = height
        self.viewCountText = viewCountText
        self.addedDate = addedDate
    }
}
