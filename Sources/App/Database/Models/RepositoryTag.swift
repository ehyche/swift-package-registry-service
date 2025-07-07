import Fluent
import Foundation
import Vapor

final class RepositoryTag: Model, @unchecked Sendable {
    static let schema = "repository_tags"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "package_scope")
    var packageScope: String

    @Field(key: "package_name")
    var packageName: String

    @Field(key: "tag_name")
    var tagName: String

    @Field(key: "zip_ball_url")
    var zipBallURL: String

    init() { }

    init(
        id: UUID? = nil,
        packageScope: String,
        packageName: String,
        tagName: String,
        zipBallURL: String
    ) {
        self.id = id
        self.packageScope = packageScope
        self.packageName = packageName
        self.tagName = tagName
        self.zipBallURL = zipBallURL
    }
}
