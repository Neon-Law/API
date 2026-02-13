import Foundation
import Hummingbird
import OpenAPIHummingbird
import OpenAPIRuntime

struct APIImpl: APIProtocol {
    let codeCommitService: CodeCommitService

    func getMatters(
        _ input: Operations.getMatters.Input
    ) async throws
        -> Operations.getMatters.Output
    {
        do {
            let matters = try await codeCommitService.listMatters()

            let response = Components.Schemas.MattersResponse(
                matters: matters
            )

            return .ok(.init(body: .json(response)))
        } catch {
            let errorResponse = Components.Schemas.ErrorResponse(
                error: .init(
                    code: .internal_error,
                    message: "An unexpected error occurred: \(error.localizedDescription)"
                )
            )

            return .internalServerError(.init(body: .json(errorResponse)))
        }
    }
}

@main
struct App {
    static func main() async throws {
        let codeCommitService = CodeCommitService()
        try await codeCommitService.connect()

        let api = APIImpl(codeCommitService: codeCommitService)

        let router = Router()
        try api.registerHandlers(on: router, serverURL: try Servers.Server1.url())

        let app = Application(
            router: router,
            configuration: .init(address: .hostname("127.0.0.1", port: 8080)),
            onServerRunning: { _ in
                print("NeonLaw API running on http://127.0.0.1:8080")
            }
        )

        try await app.runService()

        try await codeCommitService.shutdown()
    }
}
