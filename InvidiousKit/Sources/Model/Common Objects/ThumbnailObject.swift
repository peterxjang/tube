import Foundation

public struct ThumbnailObject: Hashable, Decodable {
    public var quality: String
    public var url: String
    public var width: Int
    public var height: Int
    
    public init(quality: String, url: String, width: Int, height: Int) {
        self.quality = quality
        self.url = url
        self.width = width
        self.height = height
    }

    public static func == (lhs: ThumbnailObject, rhs: ThumbnailObject) -> Bool {
        lhs.url == rhs.url
    }
}
