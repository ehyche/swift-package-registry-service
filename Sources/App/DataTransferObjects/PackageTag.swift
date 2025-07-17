import APIUtilities
import Foundation

struct PackageTag: Equatable, Codable, Sendable {
    var tagName: String
    var zipBallURL: String

    init(tagName: String, zipBallURL: String) {
        self.tagName = tagName
        self.zipBallURL = zipBallURL
    }
}

struct PackageTagInfo: Equatable, Codable, Sendable {
    var lastSyncedAt: Date
    var tags: [PackageTag]
    var versionToTagName: [Version: String]

    init(lastSyncedAt: Date, tags: [PackageTag], versionToTagName: [Version: String]) {
        self.lastSyncedAt = lastSyncedAt
        self.tags = tags
        self.versionToTagName = versionToTagName
    }
}
