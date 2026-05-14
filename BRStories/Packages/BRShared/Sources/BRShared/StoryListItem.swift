import Foundation

public struct StoryListItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let authorName: String
    public let thumbnailURL: URL
    public var isSeen: Bool
    
    public init(id: UUID, authorName: String, thumbnailURL: URL, isSeen: Bool) {
        self.id = id
        self.authorName = authorName
        self.thumbnailURL = thumbnailURL
        self.isSeen = isSeen
    }
}
