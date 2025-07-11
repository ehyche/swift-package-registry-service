import APIUtilities
import Fluent
import GithubAPIClient
import Vapor

extension PackageRegistryController {
    private static let minimumSyncInterval: TimeInterval = 60 * 5 // 5 minutes

    static func syncTags(
        owner: String,
        repo: String,
        githubAPIClient: GithubAPIClient,
        now: () -> Date,
        req: Request
    ) async throws -> PackageTagInfo {
        // Update the persistent time of the last sync
        let lastSyncDate = now()
        if let tagSync = try await RepositoryTagSync.query(on: req.db)
            .filter(\.$packageScope == owner)
            .filter(\.$packageName == repo)
            .first() {
            req.logger.debug("Updating RepositoryTagSync.last_sync_date for \"\(tagSync.idText)\" to \(lastSyncDate)")
            tagSync.lastSyncDate = lastSyncDate
            try await tagSync.update(on: req.db)
            req.logger.debug("Updated RepositoryTagSync.last_sync_date for \"\(tagSync.idText)\" to \(lastSyncDate)")
        } else {
            let tagSyncToAdd = RepositoryTagSync(
                packageScope: owner,
                packageName: repo,
                lastSyncDate: lastSyncDate
            )
            req.logger.debug("Creating RepositoryTagSync for \"\(tagSyncToAdd.idText)\" with \(lastSyncDate)")
            try await tagSyncToAdd.create(on: req.db)
            req.logger.debug("Created RepositoryTagSync for \"\(tagSyncToAdd.idText)\" with \(lastSyncDate)")
        }

        // Read all of the tags in the DB for this owner/repo
        let repositoryTags = try await RepositoryTag.query(on: req.db)
            .filter(\.$packageScope == owner)
            .filter(\.$packageName == repo)
            .all()
        let tagNameSet = Set(repositoryTags.map(\.tagName))

        // Before we attempt to do a full page-by-page sync, we make an API call
        // to get the most-recent tag. If that tag is already in our set, then
        // we don't bother doing the full page-by-page sync. But if we don't
        // have any tags stored locally, then there's no point fetching the most-recent tag.
        if !tagNameSet.isEmpty {
            // Fetch 1 tag from the Github API.
            let firstTagInput = GithubAPIClient.ListRepositoryTags.Input(owner: owner, repo: repo, perPage: 1, page: 1)
            if let firstTag = try await githubAPIClient.listRepositoryTags(firstTagInput).tags.first, tagNameSet.contains(firstTag.name) {
                // The first tag was already cached.
                // We assume that the Github API returns us tags in newest-to-oldest order.
                // So if the first tag is already cached, then we don't do the full page-by-page sync.
                req.logger.debug("First tag \"\(firstTag.name)\" for \(owner).\(repo) is already cached.  Returning \(repositoryTags.count) cached tags.")
                return PackageTagInfo(lastSyncedAt: lastSyncDate, tags: repositoryTags)
            }
        }

        // Now we must do a full page-by-page sync.
        var tags = [PackageTag]()
        var tagsInput = GithubAPIClient.ListRepositoryTags.Input(owner: owner, repo: repo)
        var tagsOutput = GithubAPIClient.ListRepositoryTags.Output.mock
        var nextPage: APIUtilities.PageInfo? = .init(perPage: 100, page: 1)
        while nextPage != nil {
            tagsInput.updatePageInfo(nextPage!)
            req.logger.debug("Fetching tags page \(tagsInput.page ?? 1) for \(owner).\(repo)")
            tagsOutput = try await githubAPIClient.listRepositoryTags(tagsInput)
            let fetchedTags = try tagsOutput.tags.map(\.asPackageTag)
            req.logger.debug("Fetched \(fetchedTags.count) tags in page \(tagsInput.page ?? 1) for \(owner).\(repo)")
            tags.append(contentsOf: fetchedTags)
            nextPage = tagsOutput.nextPage
        }

        // Persist the tags to the DB. We only need to add the ones that
        // haven't been added to the DB yet. And since existing tags don't change,
        // if we have already persisted a tag, then we don't have to update it.
        // So from our fetched tags, we filter out just the ones that we haven't persisted.
        let unpersistedTags = tags.filter { !tagNameSet.contains($0.tagName) }
        for unpersistedTag in unpersistedTags {
            let tagToAdd = RepositoryTag(
                packageScope: owner,
                packageName: repo,
                tagName: unpersistedTag.tagName,
                zipBallURL: unpersistedTag.zipBallURL
            )
            req.logger.debug("Adding tag \"\(unpersistedTag.tagName)\" for \"\(tagToAdd.idText)\"")
            try await tagToAdd.create(on: req.db)
            req.logger.debug("Added tag \"\(unpersistedTag.tagName)\" for \"\(tagToAdd.idText)\"")
        }

        return PackageTagInfo(lastSyncedAt: lastSyncDate, tags: tags)
    }
}

extension RepositoryTagSync {
    var idText: String {
        "\(packageScope).\(packageName)"
    }
}

extension RepositoryTag {
    var idText: String {
        "\(packageScope).\(packageName)"
    }
}

extension PackageTagInfo {
    init(lastSyncedAt: Date, tags: [RepositoryTag]) {
        self.init(lastSyncedAt: lastSyncedAt, tags: tags.map(\.asPackageTag))
    }

    init(lastSyncedAt: Date, tags: [PackageTag]) {
        self.lastSyncedAt = lastSyncedAt
        self.tags = tags
        self.versionToTagName = Version.versionToTagMap(fromTags: tags.map(\.tagName))
    }
}

extension PackageTag {
    init(repositoryTag: RepositoryTag) {
        tagName = repositoryTag.tagName
        zipBallURL = repositoryTag.zipBallURL
    }
}

extension RepositoryTag {
    var asPackageTag: PackageTag {
        .init(repositoryTag: self)
    }
}

extension GithubAPIClient.ListRepositoryTags.Output {
    var tags: [GithubAPIClient.ListRepositoryTags.OKBody.Tag] {
        get throws {
            switch self {
            case .ok(let okBody):
                return okBody.tags
            case .other(let httpResponse):
                throw Abort(.init(statusCode: httpResponse.status.code))
            }
        }
    }
}

extension GithubAPIClient.ListRepositoryTags.OKBody.Tag {
    var asPackageTag: PackageTag {
        .init(tagName: name, zipBallURL: zipBallURL)
    }
}
