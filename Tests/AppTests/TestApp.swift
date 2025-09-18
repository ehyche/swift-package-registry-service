@testable import App
import Dependencies
import GithubAPIClient
import ChecksumClient
import Vapor
import VaporTesting

func testApp(
    githubAPIClient: GithubAPIClient = .mock,
    checksumClient: ChecksumClient = .mock,
    githubAPIToken: String = "",
    clientSupportsPagination: Bool = false,
    testAction: (Application) async throws -> ()
) async throws {
    let app = try await Application.make(.testing)
    do {
        try await configure(
            app,
            environment: .testing,
            cacheRootDirectory: "",
            githubAPIClient: githubAPIClient,
            checksumClient: checksumClient,
            logger: app.logger,
            githubAPIToken: githubAPIToken,
            sqliteConfiguration: .memory,
            uuidGenerator: .incrementing,
            clientSupportsPagination: clientSupportsPagination
        )
        try await testAction(app)
    }
    catch {
        try await app.asyncShutdown()
        throw error
    }
    try await app.asyncShutdown()
}
