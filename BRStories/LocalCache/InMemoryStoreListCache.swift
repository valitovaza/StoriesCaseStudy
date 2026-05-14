import BRViewModels
import Foundation

final class InMemoryStoreListCache: StoreListCache {
    private var storiesByID: [UUID: Story] = [:]

    func getStoreBy(id: UUID) -> Story? {
        storiesByID[id]
    }

    func setStories(stories: [Story]) {
        for story in stories {
            storiesByID[story.id] = story
        }
    }
}
