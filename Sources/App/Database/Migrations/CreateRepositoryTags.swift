import Fluent

struct CreateRepositoryTags: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("repository_tags")
            .id()
            .field("package_scope", .string, .required)
            .field("package_name", .string, .required)
            .field("tag_name", .string, .required)
            .field("zip_ball_url", .string, .required)
            .unique(on: "package_scope", "package_name", "tag_name")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("repository_tags").delete()
    }
}
