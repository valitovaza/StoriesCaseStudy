import SwiftUI

struct RemoteImage<Content: View, Placeholder: View, Failure: View>: View {
    private let request: URLRequest
    private let expectedSize: CGSize?
    private let onSize: ((CGSize) -> Void)?
    @ViewBuilder private let contentView: (Image) -> Content
    @ViewBuilder private let placeholder: () -> Placeholder
    @ViewBuilder private let failureView: (String?) -> Failure
    
    @State private var image: RemoteValue<Image> = .loading
    @Environment(\.imageLoader) private var imageLoader
    @State private var task: Task<Void, Never>?
    
    init(
        source: URL,
        expectedSize: CGSize? = nil,
        onSize: ((CGSize) -> Void)? = nil,
        @ViewBuilder contentView: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failureView: @escaping (String?) -> Failure
    ) {
        self.request = URLRequest(url: source)
        self.expectedSize = expectedSize
        self.onSize = onSize
        self.contentView = contentView
        self.placeholder = placeholder
        self.failureView = failureView
    }
    
    init(
        request: URLRequest,
        expectedSize: CGSize? = nil,
        onSize: ((CGSize) -> Void)? = nil,
        @ViewBuilder contentView: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failureView: @escaping (String?) -> Failure
    ) {
        self.request = request
        self.expectedSize = expectedSize
        self.onSize = onSize
        self.contentView = contentView
        self.placeholder = placeholder
        self.failureView = failureView
    }
    
    var body: some View {
        LoaderView(image) {
            contentView($0)
        } placeholder: {
            placeholder()
        } failureView: {
            failureView($0)
        }
        .onAppear {
            if let cachedImage = InMemoryCache.shared.image(for: request, expectedSize: expectedSize) {
                onSize?(cachedImage.size)
                image = .loaded(Image(uiImage: cachedImage))
            } else {
                if let task {
                    task.cancel()
                }
                task = Task {
                    await loadImage(request)
                }
            }
        }
        .onChange(of: request, { oldValue, newValue in
            if let cachedImage = InMemoryCache.shared.image(
                for: newValue,
                expectedSize: expectedSize
            ) {
                onSize?(cachedImage.size)
                image = .loaded(Image(uiImage: cachedImage))
            } else {
                if let task {
                    task.cancel()
                }
                task = Task {
                    await loadImage(newValue)
                }
            }
        })
        .onDisappear {
            task?.cancel()
        }
    }
    
    @MainActor private func loadImage(_ request: URLRequest) async {
        do {
            image = .loading
            let imgData = try await imageLoader.get(request)
            if let imgData, let img = UIImage(data: imgData) {
                let resultImage: UIImage
                if let expectedSize {
                    resultImage = await Task.detached(priority: .userInitiated) {
                        resize(originalImage: img, expectedSize: expectedSize)
                    }.value
                } else {
                    resultImage = img
                }
                InMemoryCache.shared.set(image: resultImage, for: request, expectedSize: expectedSize)
                onSize?(resultImage.size)
                withAnimation {
                    image = .loaded(Image(uiImage: resultImage))
                }
            } else {
                withAnimation {
                    image = .failure("Invalid image")
                }
            }
        } catch {
            withAnimation {
                image = .failure(error.localizedDescription)
            }
        }
    }
}

private func resize(
    originalImage: UIImage,
    expectedSize: CGSize
) -> UIImage {
    let src = originalImage.size
    guard src.width > 0, src.height > 0 else {
        return originalImage
    }
    let scale = min(expectedSize.width / src.width, expectedSize.height / src.height, 1.0)
    let newSize = CGSize(width: src.width * scale, height: src.height * scale)
    guard newSize != src else {
        return originalImage
    }
    
    let renderer = UIGraphicsImageRenderer(size: newSize)
    let resized = renderer.image { _ in
        originalImage.draw(in: CGRect(origin: .zero, size: newSize))
    }
    return resized
}

@MainActor
private final class InMemoryCache: NSCache<URLRequestWrapper, ImageWrapper> {
    static let shared = InMemoryCache()

    override init() {
        super.init()
        countLimit = 150
        totalCostLimit = 50 * 1024 * 1024
    }

    func image(for request: URLRequest, expectedSize: CGSize? = nil) -> UIImage? {
        object(forKey: .init(request: request, expectedSize: expectedSize))?.image
    }

    func set(image: UIImage, for request: URLRequest, expectedSize: CGSize? = nil) {
        setObject(
            .init(image: image),
            forKey: .init(request: request, expectedSize: expectedSize),
            cost: image.memoryCost
        )
    }

    func clearCache() {
        removeAllObjects()
    }

    func remove(for request: URLRequest, expectedSize: CGSize? = nil) {
        removeObject(forKey: .init(request: request, expectedSize: expectedSize))
    }
}

private extension UIImage {
    var memoryCost: Int {
        guard let cgImage else { return 1 }
        return cgImage.bytesPerRow * cgImage.height
    }
}

@MainActor
public enum InMemoryRemoteImageCache {
    public static func clear() {
        InMemoryCache.shared.clearCache()
    }
    
    public static func remove(for request: URLRequest, expectedSize: CGSize? = nil) {
        InMemoryCache.shared.remove(for: request, expectedSize: expectedSize)
    }
}

private class URLRequestWrapper: NSObject {
    let request: URLRequest
    let expectedSize: CGSize?
    
    init(request: URLRequest, expectedSize: CGSize?) {
        self.request = request
        self.expectedSize = expectedSize
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? URLRequestWrapper else {
            return false
        }
        return request == other.request && expectedSize == other.expectedSize
    }
    
    override var hash: Int {
        if let expectedSize {
            return request.hashValue ^ expectedSize.width.hashValue ^ expectedSize.height.hashValue
        } else {
            return request.hashValue
        }
    }
}

private class ImageWrapper {
    let image: UIImage
    
    init(image: UIImage) {
        self.image = image
    }
}
