import SwiftUI
import BRShared

public struct StoryListView: View {
    let stories: [StoryListItem]
    let isStoriesLoading: Bool
    let transitionNamespace: Namespace.ID?
    let onStorySelected: (UUID) -> Void
    let onStoryAppeared: (UUID) -> Void
    
    public init(
        stories: [StoryListItem],
        isStoriesLoading: Bool,
        transitionNamespace: Namespace.ID? = nil,
        onStorySelected: @escaping (UUID) -> Void,
        onStoryAppeared: @escaping (UUID) -> Void,
    ) {
        self.stories = stories
        self.isStoriesLoading = isStoriesLoading
        self.transitionNamespace = transitionNamespace
        self.onStorySelected = onStorySelected
        self.onStoryAppeared = onStoryAppeared
    }
    
    public var body: some View {
        ZStack(alignment: .top) {
            LinearGradient.storiesBackground
                .padding(-80)
                .ignoresSafeArea()
            
            storiesStrip
                .padding(.top)
        }
    }
    
    @ViewBuilder
    var storiesStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: ViewMetrics.cellSpacing) {
                ForEach(stories) { story in
                    StoryItemView(
                        story: story,
                        transitionNamespace: transitionNamespace,
                        onStorySelected: onStorySelected
                    )
                    .onAppear(perform: { onStoryAppeared(story.id) })
                    .id(story.id)
                }
                
                if isStoriesLoading {
                    loadingView
                }
            }
            .padding(.horizontal, ViewMetrics.horizontalPadding)
            .frame(height: ViewMetrics.stripHeight)
            .animation(.easeInOut, value: stories)
        }
    }
    
    @ViewBuilder
    var loadingView: some View {
        if stories.isEmpty {
            Color.clear.frame(
                width: UIScreen.main.bounds.width - 2 * ViewMetrics.horizontalPadding
            )
            .overlay {
                ProgressView()
                    .padding(.bottom)
            }
        } else {
            ProgressView()
                .padding(.bottom)
        }
    }
}

private struct StoryItemView: View {
    let story: StoryListItem
    let transitionNamespace: Namespace.ID?
    let onStorySelected: (UUID) -> Void
    
    init(
        story: StoryListItem,
        transitionNamespace: Namespace.ID?,
        onStorySelected: @escaping (UUID) -> Void,
    ) {
        self.story = story
        self.transitionNamespace = transitionNamespace
        self.onStorySelected = onStorySelected
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Circle().fill(.white)
                .frame(width: ViewMetrics.storyImageSize, height: ViewMetrics.storyImageSize)
                .overlay(content: {
                    RemoteImage(source: story.thumbnailURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .allowsHitTesting(false)
                    } placeholder: {
                        Color.gray
                            .aspectRatio(1, contentMode: .fill)
                    } failureView: { _ in
                        Color.gray
                            .aspectRatio(1, contentMode: .fill)
                    }
                    .clipShape(Circle())
                    .padding(.all, 7.0)
                })
                .overlay {
                    Circle()
                        .strokeBorder(
                            story.isSeen
                            ? AnyShapeStyle(Color.black.opacity(0.2))
                            : AnyShapeStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange, .pink, .purple],
                                    startPoint: .bottomLeading,
                                    endPoint: .topTrailing
                                )
                            ),
                            lineWidth: 4.0
                        )
                }
            Spacer(minLength: 0)
            Text(verbatim: story.authorName)
                .lineLimit(1)
                .font(.system(size: ViewMetrics.authorFontSize))
        }
        .frame(width: ViewMetrics.storyItemWidth)
        .contentShape(Rectangle())
        .storyTransitionSource(id: story.id, namespace: transitionNamespace)
        .onTapGesture(perform: { onStorySelected(story.id) })
    }
}

private extension View {
    @ViewBuilder
    func storyTransitionSource(id: UUID, namespace: Namespace.ID?) -> some View {
        if #available(iOS 18.0, *), let namespace {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }
}

private enum ViewMetrics {
    static let storyImageSize = 94.0
    static let cellSpacing = 11.0
    static let horizontalPadding = 12.0
    static let stripHeight = 120.0
    static let authorFontSize = 16.0
    static let storyItemWidth = 100.0
}

extension LinearGradient {
    static var storiesBackground: LinearGradient {
        LinearGradient(
            colors: [
                .storiesBackgroundTop,
                .storiesBackgroundMiddle,
                .storiesBackgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension StoryListItem {
    public static let storyImageSize = ViewMetrics.storyImageSize
    static let previewList: [StoryListItem] = (0..<20).map { index in
        StoryListItem(
            id: UUID(),
            authorName: index == 2 ? "long long long long long long long long name" : "test user \(index)",
            thumbnailURL: URL(
                string: "https://picsum.photos/id/\(100 + index)/\(testImageSize)/\(testImageSize)"
            )!,
            isSeen: index == 1 ? true : false
        )
    }
    static let testImageSize = Int(StoryListItem.storyImageSize)
}

private enum PreviewHelper {
    @MainActor static var view: StoryListView {
        StoryListView(
            stories: StoryListItem.previewList,
            isStoriesLoading: true,
            onStorySelected: { print("onStorySelected: \($0)") },
            onStoryAppeared: { print("onStoryAppeared: \($0)") },
        )
    }
}

#Preview("Light") {
    PreviewHelper.view
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    PreviewHelper.view
        .preferredColorScheme(.dark)
}
