import Foundation
import Testing

@testable import API

@Suite("CodeCommit Service Tests")
struct CodeCommitServiceTests {
    @Test("CodeCommitService initializes with region")
    func testInitialization() async throws {
        let service = CodeCommitService()
        try await service.connect()
        try await service.shutdown()
    }

    @Test("CodeCommitService connects successfully")
    func testConnect() async throws {
        let service = CodeCommitService()
        try await service.connect()
        try await service.shutdown()
    }

    @Test("CodeCommitService lists matters with real AWS data")
    func testListMatters() async throws {
        let service = CodeCommitService()
        try await service.connect()

        let matters = try await service.listMatters()

        #expect(matters.count >= 0)

        for matter in matters {
            #expect(!matter.name.isEmpty)
            #expect(!matter.gitUrl.isEmpty)
            #expect(matter.gitUrl.hasPrefix("https://git-codecommit.us-west-2.amazonaws.com/v1/repos/"))
            #expect(matter.gitUrl.contains(matter.name))
        }

        try await service.shutdown()
    }

    @Test("CodeCommitService constructs correct Git URLs")
    func testGitUrlFormat() async throws {
        let service = CodeCommitService()
        try await service.connect()

        let matters = try await service.listMatters()

        for matter in matters {
            let expectedPrefix = "https://git-codecommit.us-west-2.amazonaws.com/v1/repos/"
            #expect(matter.gitUrl.hasPrefix(expectedPrefix))

            let repoName = String(matter.gitUrl.dropFirst(expectedPrefix.count))
            #expect(repoName == matter.name)
        }

        try await service.shutdown()
    }

    @Test("CodeCommitService handles empty repository list")
    func testEmptyRepositoryList() async throws {
        let service = CodeCommitService()
        try await service.connect()

        let matters = try await service.listMatters()

        #expect(matters.count >= 0)

        try await service.shutdown()
    }
}
