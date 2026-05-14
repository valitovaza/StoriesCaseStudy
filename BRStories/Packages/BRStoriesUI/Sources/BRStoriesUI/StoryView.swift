import SwiftUI
import BRShared

public struct StoryView: View {
    let story: StoryItem
    let onToggleLike: () -> Void
    let onClose: () -> Void
    
    @State var currentMediaIndex: Int = 0
    
    public init(
        story: StoryItem,
        onToggleLike: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self.story = story
        self.onToggleLike = onToggleLike
        self.onClose = onClose
    }
    
    public var body: some View {
        ZStack {
            mediaView
            
            HStack(spacing: 0) {
                TapView(onTap: {
                    currentMediaIndex = max(0, currentMediaIndex - 1)
                })
                TapView(onTap: {
                    currentMediaIndex = min(story.mediaURLs.count - 1, currentMediaIndex + 1)
                })
            }
            
            topView
            
            likeView
        }
    }
    
    @ViewBuilder
    var topView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 3) {
                ForEach(story.mediaURLs.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(currentMediaIndex >= index ? .white.opacity(0.7) : .white.opacity(0.3))
                        .frame(height: 4)
                        .shadow(radius: 4)
                }
            }
            .padding(.horizontal, 12)
            
            userInfoAndCloseView
            
            Spacer(minLength: 0)
        }
    }
    
    @ViewBuilder
    var likeView: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                Spacer(minLength: 0)
                Button(action: onToggleLike) {
                    Circle()
                        .fill(.white.opacity(0.3))
                        .frame(width: 64, height: 64)
                        .shadow(radius: 4)
                        .overlay(content: {
                            Image(systemName: story.isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(story.isLiked ? .red : .white)
                                .contentTransition(.symbolEffect(.replace))
                                .symbolEffect(.bounce, value: story.isLiked)
                                .animation(.snappy, value: story.isLiked)
                        })
                        .contentShape(Rectangle())
                }
                .padding(.trailing)
            }
            .padding(.bottom)
        }
    }
    
    @ViewBuilder
    var userInfoAndCloseView: some View {
        HStack(spacing: 12) {
            RemoteImage(source: story.avatarURL) { image in
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
            .frame(
                width: ViewMetrics.authorImageSize,
                height: ViewMetrics.authorImageSize
            )
            .allowsHitTesting(false)
            .clipShape(Circle())
            .shadow(radius: 4)
            Text(verbatim: story.username)
                .lineLimit(1)
                .font(.system(size: ViewMetrics.authorFontSize))
                .foregroundStyle(.white)
                .shadow(radius: 4)
            Spacer(minLength: 0)
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .shadow(radius: 4)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 9)
                    .contentShape(Rectangle())
                    //._printSize()
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 3)
    }
    
    @ViewBuilder
    var mediaView: some View {
        ZStack {
            ForEach(story.mediaURLs.indices, id: \.self) { index in
                let url = story.mediaURLs[index]
                RemoteImage(source: url) { image in
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
                .opacity(currentMediaIndex == index ? 1 : 0)
                .ignoresSafeArea()
            }
        }
        .frame(width: UIScreen.main.bounds.width)
    }
}

private struct TapView: View {
    let onTap: () -> Void
    
    init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }
    
    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .ignoresSafeArea()
            .onTapGesture(perform: onTap)
    }
}

private enum ViewMetrics {
    static let authorImageSize = 40.0
    static let authorFontSize = 20.0
}

private struct PreviewView: View {
    @State var story = StoryItem(
        id: UUID(),
        username: "test name long long long long long long long long long long",
        avatarURL: URL(string: "https://picsum.photos/id/400/60/60")!,
        mediaURLs: [
            URL(string: "https://picsum.photos/id/500/600/800")!,
            URL(string: "https://picsum.photos/id/501/600/800")!,
            URL(string: "https://picsum.photos/id/502/600/800")!
        ],
        isLiked: false
    )
    
    var body: some View {
        StoryView(
            story: story,
            onToggleLike: { story.isLiked.toggle() },
            onClose: { print("onClose") }
        )
    }
}

#Preview("Light") {
    PreviewView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    PreviewView()
        .preferredColorScheme(.dark)
}
