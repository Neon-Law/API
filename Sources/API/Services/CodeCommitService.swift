import Foundation
import SotoCodeCommit
import SotoCore

actor CodeCommitService {
    private var client: AWSClient?
    private var codeCommit: CodeCommit?
    private let region: Region

    init(region: Region = .uswest2) {
        self.region = region
    }

    func connect() async throws {
        guard client == nil else { return }

        let client = AWSClient()
        self.client = client
        self.codeCommit = CodeCommit(
            client: client,
            region: region
        )
    }

    func listMatters() async throws -> [Components.Schemas.Matter] {
        try await connect()

        guard let codeCommit = codeCommit else {
            throw CodeCommitError.notConnected
        }

        let request = CodeCommit.ListRepositoriesInput()
        let response = try await codeCommit.listRepositories(request)

        let repositories = response.repositories ?? []

        return repositories.compactMap { repo in
            guard let name = repo.repositoryName else { return nil }

            let gitUrl =
                "https://git-codecommit.\(region.rawValue).amazonaws.com/v1/repos/\(name)"

            return Components.Schemas.Matter(
                name: name,
                gitUrl: gitUrl
            )
        }
    }

    func shutdown() async throws {
        codeCommit = nil

        if let client = client {
            try await client.shutdown()
            self.client = nil
        }
    }

    deinit {
        // Note: AWSClient requires explicit shutdown
        // In production, ensure shutdown() is called before deallocation
    }
}

enum CodeCommitError: Error, LocalizedError {
    case notConnected
    case listRepositoriesFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "CodeCommit client not connected"
        case .listRepositoriesFailed(let message):
            return "Failed to list repositories: \(message)"
        }
    }
}
