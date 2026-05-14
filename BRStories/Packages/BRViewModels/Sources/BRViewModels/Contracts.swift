import Foundation

public protocol StoriesRepository: Sendable {
    func fetchStories(page: Int) async throws -> StoryPage
}

public protocol StoreListCache {
    func getStoreBy(id: UUID) -> Story?
    func setStories(stories: [Story])
}

public protocol StoryStateStore: Sendable {
    func seenStoryIDs() -> Set<UUID>
    func likedStoryIDs() -> Set<UUID>
    func markSeen(_ id: UUID)
    func setLiked(_ isLiked: Bool, for id: UUID)
}
