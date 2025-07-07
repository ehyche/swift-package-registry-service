import Fluent
import Foundation
import Vapor

final class RepositoryVersion: Model, @unchecked Sendable {
    static let schema = "repository_versions"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "package_scope")
    var packageScope: String

    @Field(key: "package_name")
    var packageName: String

    @Field(key: "package_version")
    var packageVersion: String

    @Field(key: "tag_name")
    var tagName: String

    init() { }

    init(
        id: UUID? = nil,
        packageScope: String,
        packageName: String,
        packageVersion: String,
        tagName: String
    ) {
        self.id = id
        self.packageScope = packageScope
        self.packageName = packageName
        self.packageVersion = packageVersion
        self.tagName = tagName
    }
}
