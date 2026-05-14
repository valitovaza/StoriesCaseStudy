import BRViewModels
import Foundation

final class UserDefaultsStoryStateStore: StoryStateStore {
    private enum Keys {
        static let seenStoryIDs = "storyState.seenStoryIDs"
        static let likedStoryIDs = "storyState.likedStoryIDs"
    }

    private let suiteName: String?

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    func seenStoryIDs() -> Set<UUID> {
        uuidSet(forKey: Keys.seenStoryIDs)
    }

    func likedStoryIDs() -> Set<UUID> {
        uuidSet(forKey: Keys.likedStoryIDs)
    }

    func markSeen(_ id: UUID) {
        var ids = uuidSet(forKey: Keys.seenStoryIDs)
        ids.insert(id)
        setUUIDSet(ids, forKey: Keys.seenStoryIDs)
    }

    func setLiked(_ isLiked: Bool, for id: UUID) {
        var ids = uuidSet(forKey: Keys.likedStoryIDs)

        if isLiked {
            ids.insert(id)
        } else {
            ids.remove(id)
        }

        setUUIDSet(ids, forKey: Keys.likedStoryIDs)
    }

    private var userDefaults: UserDefaults {
        if let suiteName, let defaults = UserDefaults(suiteName: suiteName) {
            return defaults
        }
        return .standard
    }

    private func uuidSet(forKey key: String) -> Set<UUID> {
        let strings = userDefaults.stringArray(forKey: key) ?? []
        return Set(strings.compactMap(UUID.init(uuidString:)))
    }

    private func setUUIDSet(_ ids: Set<UUID>, forKey key: String) {
        let strings = ids
            .map(\.uuidString)
            .sorted()
        userDefaults.set(strings, forKey: key)
    }
}
