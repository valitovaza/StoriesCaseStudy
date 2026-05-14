import BRViewModels
import BRStoriesUI
import BRShared
import SwiftUI

@MainActor
@Observable
final class MainStore {
    let storiesViewModel: StoryListViewModel
    var storyViewModel: StoryViewModel?
    
    fileprivate let storeListCache: StoreListCache
    fileprivate let storyStateStore = UserDefaultsStoryStateStore(suiteName: "app-local-state")
    private var router: Router?
    
    init() {
        storeListCache = InMemoryStoreListCache()
        let avatarImageSize = Int(UIScreen.main.scale * StoryListItem.storyImageSize)
        let remoteStoriesRepository = FakeStoriesRepository(
            pageSize: 20,
            avatarImageSize: avatarImageSize,
            storyImageSize: Int(UIScreen.main.scale * UIScreen.main.bounds.height)
        )
        let router = Router()
        self.storiesViewModel = StoryListViewModel(
            storiesRepository: remoteStoriesRepository,
            storeListCache: storeListCache,
            storyStateStore: storyStateStore,
            onOpenStory: router.openStoryBy(id:)
        )
        router.mainStore = self
        self.router = router
    }
}

private final class Router {
    weak var mainStore: MainStore?
    
    func openStoryBy(id: UUID) {
        guard let mainStore else { return }
        guard let story = mainStore.storeListCache.getStoreBy(id: id) else { return }
        
        mainStore.storyViewModel = StoryViewModel(
            story: StoryItem(
                id: story.id,
                username: story.authorName,
                avatarURL: story.authorURL,
                mediaURLs: story.storyURLs,
                isLiked: mainStore.storyStateStore.likedStoryIDs().contains(id)
            ),
            storyStateStore: StoryStateStoreDecorator(
                storyStateStore: mainStore.storyStateStore,
                storyListViewModel: mainStore.storiesViewModel
            ),
            onClose: { [weak mainStore] in
                mainStore?.storyViewModel = nil
            }
        )
    }
}

private final class StoryStateStoreDecorator: StoryStateStore {
    let storyStateStore: StoryStateStore
    let storyListViewModel: StoryListViewModel
    
    init(storyStateStore: StoryStateStore, storyListViewModel: StoryListViewModel) {
        self.storyStateStore = storyStateStore
        self.storyListViewModel = storyListViewModel
    }
    
    func seenStoryIDs() -> Set<UUID> {
        storyStateStore.seenStoryIDs()
    }
    
    func likedStoryIDs() -> Set<UUID> {
        storyStateStore.likedStoryIDs()
    }
    
    func markSeen(_ id: UUID) {
        storyStateStore.markSeen(id)
        Task {
            await MainActor.run {
                storyListViewModel.markSeen(id)
            }
        }
    }
    
    func setLiked(_ isLiked: Bool, for id: UUID) {
        storyStateStore.setLiked(isLiked, for: id)
    }
}
