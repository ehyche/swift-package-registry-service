import Foundation
import Vapor

/// This actor accomplishes two purposes:
/// - Holds a memory cache of `PackageTagInfo`, keyed by package id
/// - Ensures that for a specific package id, we only execute one `TagFileLoader` at a time.
///
/// Since `TagFileLoader` may mutate the disk cache, then this eliminates the race condition where two requests to the same package id
/// could be attempting to read and write to the disk cache simultaneously. So if we get two simultaneous requests to
/// `GET /:owner/:repo` with same `owner` and `repo` for both requests, then the second one must
/// will wait on the first one to complete before it completes.
actor TagsActor {
    typealias TagFileLoader = @Sendable (_ owner: String, _ repo: String, _ req: Request) async throws -> PackageTagInfo
    typealias GetDateNow = () -> Date

    private var memoryCache: [String: TagFileState] = [:]
    private let tagFileLoader: TagFileLoader
    private let minimumSyncInterval: TimeInterval
    private let getDateNow: GetDateNow
    static let defaultMinimumSyncInterval: TimeInterval = 60 * 5 // 5 minutes

    init(
        minimumSyncInterval: TimeInterval = defaultMinimumSyncInterval,
        getDateNow: @escaping GetDateNow = { Date.now },
        tagFileLoader: @escaping TagFileLoader
    ) {
        self.minimumSyncInterval = minimumSyncInterval
        self.getDateNow = getDateNow
        self.tagFileLoader = tagFileLoader
    }

    func loadTagInfo(owner: String, repo: String, req: Request) async throws -> PackageTagInfo {
        let cacheKey = Self.makeCacheKey(owner, repo)
        if let state = memoryCache[cacheKey] {
            switch state {
             case let .loaded(tagInfo):
                if getDateNow().timeIntervalSince(tagInfo.lastSyncedAt) < minimumSyncInterval {
                    req.logger.debug("Loaded \(tagInfo.tags.count) tags from memory cache for \(cacheKey)")
                    return tagInfo
                } else {
                    req.logger.debug("Minimum sync interval elapsed for for \(cacheKey). Re-syncing.")
                }
            case .loading(let task):
                req.logger.debug("PackageTagInfo memory cache is loading for \(cacheKey). Awaiting loading task.")
                return try await task.value
            }
        }

        let task = Task {
            try await tagFileLoader(owner, repo, req)
        }

        memoryCache[cacheKey] = .loading(task)

        do {
            let tagInfo = try await task.value
            memoryCache[cacheKey] = .loaded(tagInfo)
            req.logger.debug("Loaded \(tagInfo.tags.count) tags from tagFileLoader for \(cacheKey)")
            return tagInfo
        } catch {
            memoryCache[cacheKey] = nil
            req.logger.error("tagFileLoader threw an error for \(cacheKey): \(error)")
            throw error
        }
    }

    private static func makeCacheKey(_ owner: String, _ repo: String) -> String {
        "\(owner.lowercased()).\(repo.lowercased())"
    }

    private enum TagFileState {
        case loading(Task<PackageTagInfo, Error>)
        case loaded(PackageTagInfo)
    }
}
