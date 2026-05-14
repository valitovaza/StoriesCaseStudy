import BRStoriesUI
import SwiftUI

@main
struct BRStoriesApp: App {
    let store = MainStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .environment(\.imageLoader, CachingImageLoader.withSimpleCache)
        }
    }
}
