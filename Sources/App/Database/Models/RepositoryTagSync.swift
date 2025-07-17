import Fluent
import Foundation
import Vapor

final class RepositoryTagSync: Model, @unchecked Sendable {
    static let schema = "repository_tag_syncs"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "package_scope")
    var packageScope: String

    @Field(key: "package_name")
    var packageName: String

    @Field(key: "last_sync_date")
    var lastSyncDate: Date

    init() { }

    init(
        id: UUID? = nil,
        packageScope: String,
        packageName: String,
        lastSyncDate: Date
    ) {
        self.id = id
        self.packageScope = packageScope
        self.packageName = packageName
        self.lastSyncDate = lastSyncDate
    }
}
