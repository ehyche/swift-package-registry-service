import Fluent

struct CreateRepositoryVersions: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("repository_versions")
            .id()
            .field("package_scope", .string, .required)
            .field("package_name", .string, .required)
            .field("package_version", .string, .required)
            .field("tag_name", .string, .required)
            .unique(on: "package_scope", "package_name", "package_version")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("repository_versions").delete()
    }
}
