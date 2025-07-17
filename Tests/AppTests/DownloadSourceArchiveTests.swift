@testable import App
import ConcurrencyExtras
import GithubAPIClient
import ChecksumClient
import Testing
import VaporTesting

@Suite("downloadSourceArchive Tests")
struct DownloadSourceArchiveTests {

    @Test func invalidPackageScopeResultsInBadRequest() async throws {
        try await testApp { app in
            // Use 41 characters in the package scope - 1 character too many
            try await app.testing().test(.GET, "1234567890123456789012345678901234567890/swift-clocks/0.5.0.zip") { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func invalidPackageNameResultsInBadRequest() async throws {
        try await testApp { app in
            // Use two successive hyphens in package name
            try await app.testing().test(.GET, "pointfreeco/swift--clocks/0.5.0.zip") { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func invalidContentVersionResultsInBadRequest() async throws {
        try await testApp { app in
            // Send version 3 in the Accept header
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.5.0.zip", headers: ["Accept": "application/vnd.swift.registry.v3+zip"]) { res in
                #expect(res.status == .badRequest)
            }
        }
    }

    @Test func unknownMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send unknown media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.5.0.zip", headers: ["Accept": "application/vnd.swift.registry.v1+foobar"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

    @Test func unexpectedSwiftMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send "swift" media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.5.0.zip", headers: ["Accept": "application/vnd.swift.registry.v1+swift"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }

    @Test func unexpectedJsonMediaTypeResultsInUnsupportedMediaType() async throws {
        try await testApp { app in
            // Send "json" media type
            try await app.testing().test(.GET, "pointfreeco/swift-clocks/0.5.0.zip", headers: ["Accept": "application/vnd.swift.registry.v1+json"]) { res in
                #expect(res.status == .unsupportedMediaType)
            }
        }
    }
}
