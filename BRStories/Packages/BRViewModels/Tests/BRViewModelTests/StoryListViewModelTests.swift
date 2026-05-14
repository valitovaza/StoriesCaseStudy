import XCTest
import BRShared
import BRViewModels

@MainActor
class StoryListViewModelTests: XCTestCase {
    func test_onAppear() async throws {
        await withMainSerialExecutor {
            let (sut, storiesRepository, _, _) = makeSUT()
            XCTAssertEqual(sut.stories.count, 0)
            
            let aStory = Story(id: UUID(), authorName: "Test", authorURL: URL(string: "http://fake.com")!, storyURLs: [URL(string: "http://fake.com")!])
            let aPage = StoryPage(nextPage: 1, stories: [aStory])
            storiesRepository.pageResults = [0: .success(aPage)]
            
            sut.onAppear()
            XCTAssertTrue(sut.isLoading)
            
            await Task.megaYield()
            XCTAssertEqual(sut.stories, [StoryListItem(id: aStory.id, authorName: aStory.authorName, thumbnailURL: aStory.authorURL, isSeen: false)])
        }
    }
    
    // - MARK: Helpers
    
    private func makeSUT(
        storiesRepository: TestStoriesRepository = TestStoriesRepository(),
        storeListCache: TestStoreListCache = TestStoreListCache(),
        storyStateStore: TestStoryStateStore = TestStoryStateStore(),
        onOpenStory: @escaping (UUID) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: StoryListViewModel,
        storiesRepository: TestStoriesRepository,
        storeListCache: TestStoreListCache,
        storyStateStore: TestStoryStateStore
    ) {
        let sut = StoryListViewModel(
            storiesRepository: storiesRepository,
            storeListCache: storeListCache,
            storyStateStore: storyStateStore,
            onOpenStory: onOpenStory
        )
        
        trackForMemoryLeaks(sut, file: file, line: line)
        trackForMemoryLeaks(storiesRepository, file: file, line: line)
        trackForMemoryLeaks(storeListCache, file: file, line: line)
        trackForMemoryLeaks(storyStateStore, file: file, line: line)
        
        return (sut, storiesRepository, storeListCache, storyStateStore)
    }
    
    final class TestStoriesRepository: @unchecked Sendable, StoriesRepository {
        var pageResults: [Int: Result<StoryPage, Error>] = [:]
        private(set) var requestedPages: [Int] = []
        
        func fetchStories(page: Int) async throws -> StoryPage {
            requestedPages.append(page)
            
            switch pageResults[page] {
            case let .success(storyPage):
                return storyPage
            case let .failure(error):
                throw error
            case nil:
                return StoryPage(nextPage: page + 1, stories: [])
            }
        }
    }
    
    final class TestStoreListCache: StoreListCache {
        private(set) var cachedStories: [Story] = []
        
        func getStoreBy(id: UUID) -> Story? {
            cachedStories.first { $0.id == id }
        }
        
        func setStories(stories: [Story]) {
            cachedStories.append(contentsOf: stories)
        }
    }
    
    struct LikeTestInfo: Equatable {
        let isLiked: Bool
        let id: UUID
    }
    
    final class TestStoryStateStore: @unchecked Sendable, StoryStateStore {
        var seenIDs: Set<UUID> = []
        var likedIDs: Set<UUID> = []
        private(set) var markedSeenIDs: [UUID] = []
        private(set) var likedUpdates: [LikeTestInfo] = []
        
        func seenStoryIDs() -> Set<UUID> {
            seenIDs
        }
        
        func likedStoryIDs() -> Set<UUID> {
            likedIDs
        }
        
        func markSeen(_ id: UUID) {
            markedSeenIDs.append(id)
            seenIDs.insert(id)
        }
        
        func setLiked(_ isLiked: Bool, for id: UUID) {
            likedUpdates.append(LikeTestInfo(isLiked: isLiked, id: id))
            
            if isLiked {
                likedIDs.insert(id)
            } else {
                likedIDs.remove(id)
            }
        }
    }
}
