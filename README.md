# Stories Case Study

The project focuses on a small but production-minded slice of functionality: a horizontally scrolling story list, deterministic paginated data, a full-screen story viewer, seen/liked state, and persistence across app launches.

## Features

- Story list with horizontal scrolling.
- Infinite pagination using deterministic generated data.
- Visual seen/unseen state.
- Full-screen story viewer with tap navigation between story media.
- Like/unlike support.
- Persisted seen and liked states.
- Remote image loading with memory and disk caching.
- Light and dark SwiftUI previews for the UI package.

## Architecture

The code is split into focused layers:

- **App target**: composition root, app wiring, routing, concrete repositories, and persistence implementations.
- **UI package**: SwiftUI screens, reusable UI components, image loading UI, and previews.
- **View models package**: presentation state and feature logic that can be tested without running the app target.
- **Shared package**: simple UI-facing value models shared by the UI and view-model layers.

The package split is intentionally lightweight. The goal is to keep dependencies clear:

- UI does not own networking or persistence.
- View models do not import the UI package.
- The app target assembles concrete implementations.
- SwiftUI previews can run against small, focused package targets instead of building the whole app.

`MainStore` acts as the app composition root. It creates repositories, caches, stores, routers, and view models. `ContentView` is kept close to that composition layer: it binds the root store to the first screen and owns presentation wiring.

Communication is intentionally explicit. The project uses callbacks for user actions, a small router for story presentation, and a state-store decorator to keep the list's seen state in sync when a story is opened. These patterns are not presented as the only valid architecture; they show how the feature can keep dependencies clear while remaining adaptable to a team's preferred conventions.

## Data Source

The app uses a deterministic fake repository instead of a live backend.

This keeps the behavior stable for review while still exercising an asynchronous data boundary:

- story IDs are stable UUIDs
- usernames are deterministic
- image URLs point to remote images
- pages can continue indefinitely
- image content can repeat while story identity remains stable

## Image Loading

The UI package includes a small custom remote image pipeline rather than relying directly on `AsyncImage`.

The reasons are:

- explicit cancellation when image views disappear
- controllable cache behavior through dependency injection
- memory cache for decoded/resized images
- disk cache for downloaded image data
- testable composition through `.environment(\.imageLoader, ...)`

The default image loader is injected at the app root. This keeps image loading as a cross-cutting UI concern without hard-wiring storage decisions into views.

## Persistence

Seen and liked states are persisted with a small `StoryStateStore` abstraction backed by `UserDefaults`.

This is intentionally simple because the durable state is only sets of story IDs. The abstraction keeps the view models independent from the storage mechanism, so the implementation could be replaced with a database if the state became more complex.

## Testing

The view-model package has tests that run on macOS for fast feedback.

For this project, the important testability choices are:

- view models are independent from SwiftUI views
- dependencies are passed as protocols
- repository, state store, and cache dependencies can be replaced with test doubles
- async behavior can be tested without launching the simulator

The tests include a small main-serial-executor helper inspired by Point-Free's Swift Concurrency Extras. It makes async view-model tests more deterministic by serializing work onto the main actor during tests.

## Technical Choices

- **SwiftUI** for the UI.
- **MVVM-style feature logic** for testable presentation state.
- **Swift Concurrency** for async loading.
- **Local Swift packages** for clear dependency boundaries.
- **UserDefaults** for lightweight persistence.
- **NSCache + file cache** for remote images.
- **No third-party runtime dependencies** for the core feature.

## Assumptions and Limitations

- The repository is fake but deterministic; it simulates a remote data source.
- Remote images come from a public image service and depend on network availability.
- Story media is image-only in this implementation.
- Persistence is intentionally lightweight because the required state is small.
- The app prioritizes the required story experience over unrelated feed/profile UI.
