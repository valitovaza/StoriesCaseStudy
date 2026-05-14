import XCTest
import BRShared
import BRViewModels

@MainActor
class StoryViewModelTests: XCTestCase {
    
    func test_onToggleLike_togglesLikeStateAndSavesToStore() {
        let item = StoryItem(id: UUID(), username: "Test", avatarURL: URL(string: "http://fake.com")!, mediaURLs: [URL(string: "http://fake.com")!], isLiked: false)
        var closeDidCall = false
        let (sut, storyStateStore) = makeSUT(story: item, onClose: {
            closeDidCall = true
        })
        
        sut.onToggleLike()
        
        XCTAssertTrue(sut.story.isLiked)
        XCTAssertEqual(storyStateStore.likeInfo, [LikeTestInfo(isLiked: true, id: item.id)])
        
        XCTAssertFalse(closeDidCall)
        XCTAssertEqual(storyStateStore.markedIds, [])
    }
    
    func test_onAppear_marksAsSeen() {
        let item = StoryItem(id: UUID(), username: "Test", avatarURL: URL(string: "http://fake.com")!, mediaURLs: [URL(string: "http://fake.com")!], isLiked: false)
        var closeDidCall = false
        let (sut, storyStateStore) = makeSUT(story: item, onClose: {
            closeDidCall = true
        })
        
        sut.onAppear()
        
        XCTAssertFalse(closeDidCall)
        XCTAssertEqual(storyStateStore.markedIds, [item.id])
        XCTAssertEqual(storyStateStore.likeInfo, [])
    }
    
    // - MARK: Helpers
    
    private func makeSUT(
        story: StoryItem,
        onClose: @escaping () -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (StoryViewModel, TestStoryStateStore) {
        let storyStateStore = TestStoryStateStore()
        let sut = StoryViewModel(
            story: story,
            storyStateStore: storyStateStore,
            onClose: onClose
        )
        trackForMemoryLeaks(storyStateStore, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, storyStateStore)
    }
    
    final class TestStoryStateStore: @unchecked Sendable, StoryStateStore {
        func seenStoryIDs() -> Set<UUID> {
            []
        }
        
        func likedStoryIDs() -> Set<UUID> {
            []
        }
        
        var markedIds: [UUID] = []
        func markSeen(_ id: UUID) {
            markedIds.append(id)
        }
        
        fileprivate var likeInfo: [LikeTestInfo] = []
        func setLiked(_ isLiked: Bool, for id: UUID) {
            likeInfo.append(LikeTestInfo(isLiked: isLiked, id: id))
        }
    }
}

private struct LikeTestInfo: Equatable {
    let isLiked: Bool
    let id: UUID
}
