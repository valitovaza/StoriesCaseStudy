import SwiftUI

public protocol ImageLoader: Sendable {
    func get(_ url: URL) async throws -> Data?
    func get(_ request: URLRequest) async throws -> Data?
}

struct ImageLoaderKey: EnvironmentKey {
    static let defaultValue: ImageLoader = CachingImageLoader(cache: NullImageLoaderCache())
}

extension EnvironmentValues {
    public var imageLoader: ImageLoader {
        get { self[ImageLoaderKey.self] }
        set { self[ImageLoaderKey.self ] = newValue}
    }
}

public protocol ImageLoaderCache: Sendable {
    func fetch(_ url: URL) async throws -> Data?
    func cache(imageData: Data, url: URL) async throws
}

@MainActor
private class NullImageLoaderCache: ImageLoaderCache {
    func fetch(_ url: URL) async throws -> Data? {
        warnIfNotPreview()
        return nil
    }
    
    private func warnIfNotPreview() {
        if !isPreview {
            print("❗️❗️❗️Using NullImageLoaderCache❗️❗️❗️")
        }
    }
    
    private var isPreview: Bool {
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    func cache(imageData: Data, url: URL) async throws {
        warnIfNotPreview()
    }
}

public actor CachingImageLoader: ImageLoader {
    private let cache: ImageLoaderCache
    private var tasks: [URLRequest: Task<Data, Error>] = [:]
    private var taskWaitersCount: [URLRequest: Int] = [:]
    
    public init(cache: ImageLoaderCache) {
        self.cache = cache
    }
    
    public func get(_ url: URL) async throws -> Data? {
        try await get(URLRequest(url: url))
    }
    
    public func get(_ request: URLRequest) async throws -> Data? {
        if let inProgressTask = tasks[request], !inProgressTask.isCancelled {
            taskWaitersCount[request, default: 0] += 1
            return try await waitForTask(inProgressTask, request: request)
        }
        
        tasks[request] = nil
        taskWaitersCount[request] = nil
        return try await fetchFromCacheThenGetRemote(request)
    }
    
    private func fetchFromCacheThenGetRemote(_ request: URLRequest) async throws -> Data? {
        guard let url = request.url else { throw URLError(.resourceUnavailable) }
        
        if let cachedImage = try await cache.fetch(url) {
            return cachedImage
        } else {
            return try await getRemote(request)
        }
    }
    
    private func getRemote(_ request: URLRequest) async throws -> Data {
        guard let url = request.url else { throw URLError(.resourceUnavailable) }
        
        let task: Task<Data, Error> = Task {
            let (imageData, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw URLError(.badServerResponse)
            }
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
            if let mimeType = httpResponse.mimeType,
               !mimeType.hasPrefix("image/") {
                throw URLError(.cannotDecodeContentData)
            }
            guard UIImage(data: imageData) != nil else {
                throw URLError(.cannotParseResponse)
            }
            
            do {
                try await cache.cache(imageData: imageData, url: url)
            } catch {
                print(error)
            }
            return imageData
        }
        tasks[request] = task
        taskWaitersCount[request] = 1
        
        return try await waitForTask(task, request: request)
    }
    
    private func waitForTask(_ task: Task<Data, Error>, request: URLRequest) async throws -> Data {
        try await withTaskCancellationHandler {
            do {
                let image = try await task.value
                guard !Task.isCancelled else { throw CancellationError() }
                decrementWaiter(for: request)
                return image
            } catch {
                if !Task.isCancelled {
                    decrementWaiter(for: request)
                }
                throw error
            }
        } onCancel: {
            Task {
                await decrementWaiterAndCancelIfNeeded(for: request)
            }
        }
    }
    
    private func decrementWaiter(for request: URLRequest) {
        guard let count = taskWaitersCount[request] else { return }
        
        if count <= 1 {
            clear(by: request)
        } else {
            taskWaitersCount[request] = count - 1
        }
    }
    
    private func decrementWaiterAndCancelIfNeeded(for request: URLRequest) {
        guard let count = taskWaitersCount[request] else { return }
        
        if count <= 1 {
            tasks[request]?.cancel()
            clear(by: request)
        } else {
            taskWaitersCount[request] = count - 1
        }
    }
    
    private func clear(by request: URLRequest) {
        tasks[request] = nil
        taskWaitersCount[request] = nil
    }
}
