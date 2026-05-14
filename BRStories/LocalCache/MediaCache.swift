import Foundation
import CryptoKit
import BRStoriesUI

extension CachingImageLoader {
    static let withSimpleCache = CachingImageLoader(cache: SimpleImageLoaderCache())
}

actor SimpleImageLoaderCache: ImageLoaderCache {
    private let fileManager = FileManager.default
    private let maxCacheSizeBytes = 50 * 1024 * 1024
    
    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ImageCache", isDirectory: true)
    }
    
    func fetch(_ url: URL) async throws -> Data? {
        try ensureCacheDirectoryExists()

        let fileURL = cacheFileURL(for: url)
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        try? fileManager.setAttributes(
            [.modificationDate: Date()],
            ofItemAtPath: fileURL.path
        )
        return try Data(contentsOf: fileURL)
    }

    func cache(imageData: Data, url: URL) async throws {
        try ensureCacheDirectoryExists()

        let fileURL = cacheFileURL(for: url)
        try imageData.write(to: fileURL, options: [.atomic])

        try purgeIfNeeded()
    }

    private func ensureCacheDirectoryExists() throws {
        guard !fileManager.fileExists(atPath: cacheDirectory.path) else { return }
        
        try fileManager.createDirectory(
            at: cacheDirectory,
            withIntermediateDirectories: true
        )
    }

    private func cacheFileURL(for url: URL) -> URL {
        cacheDirectory.appendingPathComponent(cacheKey(for: url))
    }

    private func cacheKey(for url: URL) -> String {
        let data = Data(url.absoluteString.utf8)
        let digest = SHA256.hash(data: data)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func purgeIfNeeded() throws {
        var cachedFiles = try fileManager
            .contentsOfDirectory(
                at: cacheDirectory,
                includingPropertiesForKeys: [
                    .contentModificationDateKey,
                    .totalFileAllocatedSizeKey,
                    .fileSizeKey
                ]
            )
            .map { fileURL in
                let values = try fileURL.resourceValues(forKeys: [
                    .contentModificationDateKey,
                    .totalFileAllocatedSizeKey,
                    .fileSizeKey
                ])

                return CachedFile(
                    url: fileURL,
                    size: values.totalFileAllocatedSize ?? values.fileSize ?? 0,
                    modificationDate: values.contentModificationDate ?? .distantPast
                )
            }

        var totalSize = cachedFiles.reduce(0) { $0 + $1.size }
        guard totalSize > maxCacheSizeBytes else { return }

        cachedFiles.sort { $0.modificationDate < $1.modificationDate }

        for file in cachedFiles where totalSize > maxCacheSizeBytes {
            try? fileManager.removeItem(at: file.url)
            totalSize -= file.size
        }
    }
}

private struct CachedFile {
    let url: URL
    let size: Int
    let modificationDate: Date
}
