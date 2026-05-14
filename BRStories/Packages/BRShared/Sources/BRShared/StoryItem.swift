import Foundation

public struct StoryItem: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let username: String
    public let avatarURL: URL
    public let mediaURLs: [URL]
    public var isLiked: Bool

    public init(
        id: UUID,
        username: String,
        avatarURL: URL,
        mediaURLs: [URL],
        isLiked: Bool
    ) {
        self.id = id
        self.username = username
        self.avatarURL = avatarURL
        self.mediaURLs = mediaURLs
        self.isLiked = isLiked
    }
}
