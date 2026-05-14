import BRShared
import SwiftUI

@MainActor
@Observable
public final class StoryViewModel: Identifiable {
    public private(set) var story: StoryItem
    let storyStateStore: StoryStateStore
    public let onClose: () -> Void
    
    public init(
        story: StoryItem,
        storyStateStore: StoryStateStore,
        onClose: @escaping () -> Void
    ) {
        self.story = story
        self.storyStateStore = storyStateStore
        self.onClose = onClose
    }
    
    public func onToggleLike() {
        story.isLiked.toggle()
        storyStateStore.setLiked(story.isLiked, for: story.id)
    }
    
    public func onAppear() {
        guard !storyStateStore.seenStoryIDs().contains(story.id) else { return }
        storyStateStore.markSeen(story.id)
    }
}
