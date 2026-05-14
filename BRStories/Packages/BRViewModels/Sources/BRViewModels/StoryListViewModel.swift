import BRShared
import Foundation

@MainActor
@Observable
public final class StoryListViewModel {
    private let storiesRepository: StoriesRepository
    private let storeListCache: StoreListCache
    private let storyStateStore: StoryStateStore
    private let onOpenStory: (UUID) -> Void
    
    public private(set) var stories: [StoryListItem] = []
    public private(set) var isLoading = false
    private var page = 0
    private var paginationTriggerIDs: Set<UUID> = []
    
    public init(
        storiesRepository: StoriesRepository,
        storeListCache: StoreListCache,
        storyStateStore: StoryStateStore,
        onOpenStory: @escaping (UUID) -> Void
    ) {
        self.storiesRepository = storiesRepository
        self.storeListCache = storeListCache
        self.storyStateStore = storyStateStore
        self.onOpenStory = onOpenStory
    }
    
    public func onAppear() {
        guard stories.isEmpty else { return }
        loadNextPage()
    }
    
    private func loadNextPage() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            defer {
                isLoading = false
            }
            do {
                let seenIds = storyStateStore.seenStoryIDs()
                let storyPage = try await storiesRepository.fetchStories(page: page)
                stories.append(contentsOf: storyPage.stories.map({ remoteStory in
                    StoryListItem(
                        id: remoteStory.id,
                        authorName: remoteStory.authorName,
                        thumbnailURL: remoteStory.authorURL,
                        isSeen: seenIds.contains(remoteStory.id)
                    )
                }))
                storeListCache.setStories(stories: storyPage.stories)
                page = storyPage.nextPage
                paginationTriggerIDs = Set(stories.suffix(Pagination.threshold).map(\.id))
            } catch {
                print("handle in prod: \(error)")
            }
        }
    }
    
    public func onStorySelected(id: UUID) {
        onOpenStory(id)
    }

    public func onStoryAppeared(id: UUID) {
        guard shouldLoadNextPage(appearingStoryID: id) else { return }
        loadNextPage()
    }
    
    private func shouldLoadNextPage(appearingStoryID id: UUID) -> Bool {
        guard !isLoading else { return false }
        return paginationTriggerIDs.contains(id)
    }
    
    public func markSeen(_ id: UUID) {
        guard let index = stories.firstIndex(where: { $0.id == id }) else { return }
        stories[index].isSeen = true
    }
}

private enum Pagination {
    static let threshold = 5
}
