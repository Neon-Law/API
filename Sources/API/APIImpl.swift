import Foundation
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
