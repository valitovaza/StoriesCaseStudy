import Foundation

public struct Story: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let authorName: String
    public let authorURL: URL
    public let storyURLs: [URL]
    
    public init(
        id: UUID,
        authorName: String,
        authorURL: URL,
        storyURLs: [URL]
    ) {
        self.id = id
        self.authorName = authorName
        self.authorURL = authorURL
        self.storyURLs = storyURLs
    }
}

public struct StoryPage: Equatable, Sendable {
    public let nextPage: Int
    public let stories: [Story]
    
    public init(nextPage: Int, stories: [Story]) {
        self.nextPage = nextPage
        self.stories = stories
    }
}
