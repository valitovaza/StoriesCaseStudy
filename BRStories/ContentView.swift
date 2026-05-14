import BRViewModels
import BRStoriesUI
import BRShared
import SwiftUI

struct ContentView: View {
    @Bindable var store: MainStore
    @Namespace private var transitionNamespace
    
    var body: some View {
        StoryListView(
            stories: store.storiesViewModel.stories,
            isStoriesLoading: store.storiesViewModel.isLoading,
            transitionNamespace: transitionNamespace,
            onStorySelected: store.storiesViewModel.onStorySelected(id:),
            onStoryAppeared: store.storiesViewModel.onStoryAppeared(id:),
        )
        .fullScreenCover(item: $store.storyViewModel) { storyViewModel in
            storyView(storyViewModel)
        }
        .onAppear(perform: store.storiesViewModel.onAppear)
    }
    
    @ViewBuilder
    private func storyView(_ storyViewModel: StoryViewModel) -> some View {
        let view = StoryView(
            story: storyViewModel.story,
            onToggleLike: storyViewModel.onToggleLike,
            onClose: storyViewModel.onClose
        )
        .onAppear(perform: storyViewModel.onAppear)
        
        if #available(iOS 18.0, *) {
            view.navigationTransition(
                .zoom(sourceID: storyViewModel.story.id, in: transitionNamespace)
            )
        } else {
            view
        }
    }
}
