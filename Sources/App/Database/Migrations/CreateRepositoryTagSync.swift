import Fluent

struct CreateRepositoryTagSync: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("repository_tag_syncs")
            .id()
            .field("package_scope", .string, .required)
            .field("package_name", .string, .required)
            .field("last_sync_date", .datetime, .required)
            .unique(on: "package_scope", "package_name")
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("repository_tag_syncs").delete()
    }
}
