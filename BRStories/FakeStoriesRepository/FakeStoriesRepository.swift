import BRViewModels
import Foundation

final class FakeStoriesRepository: StoriesRepository {
    private let pageSize: Int
    private let avatarImageSize: Int
    private let storyImageSize: Int
    
    init(
        pageSize: Int,
        avatarImageSize: Int,
        storyImageSize: Int
    ) {
        self.pageSize = pageSize
        self.avatarImageSize = avatarImageSize
        self.storyImageSize = storyImageSize
    }

    func fetchStories(page: Int) async throws -> StoryPage {
        try await Task.sleep(for: .milliseconds(350))

        let startIndex = page * pageSize

        let stories = (0..<pageSize).map { offset in
            let index = startIndex + offset
            let number = index + 1

            return Story(
                id: Self.makeStableID(number: number),
                authorName: Self.makeAuthorName(number: number),
                authorURL: Self.makeImageURL(
                    imageID: Self.makeAvatarImageID(index: index),
                    width: avatarImageSize,
                    height: avatarImageSize
                ),
                storyURLs: Self.makeStoryURLs(
                    index: index,
                    width: storyImageSize,
                    height: storyImageSize
                )
            )
        }

        return StoryPage(nextPage: page + 1, stories: stories)
    }

    private static func makeStableID(number: Int) -> UUID {
        let suffix = String(format: "%012d", number)
        return UUID(uuidString: "00000000-0000-0000-0000-\(suffix)")!
    }

    private static func makeAuthorName(number: Int) -> String {
        String(format: "user %02d", number)
    }

    private static func makeAvatarImageID(index: Int) -> Int {
        100 + (index % 900)
    }

    private static func makeStoryImageID(index: Int, storyOffset: Int) -> Int {
        200 + ((index * 3 + storyOffset) % 800)
    }

    private static func makeStoryURLs(index: Int, width: Int, height: Int) -> [URL] {
        let storyCount = 1 + (index % 4)
        return (0..<storyCount).map { storyOffset in
            makeImageURL(
                imageID: makeStoryImageID(index: index, storyOffset: storyOffset),
                width: width,
                height: height
            )
        }
    }

    private static func makeImageURL(imageID: Int, width: Int, height: Int) -> URL {
        URL(string: "https://picsum.photos/id/\(imageID)/\(width)/\(height)")!
    }
}
